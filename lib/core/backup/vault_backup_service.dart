import 'dart:convert';
import 'dart:typed_data';

import '../constants/crypto_constants.dart';
import '../encryption/key_derivation_service.dart';
import '../encryption/master_key_service.dart';
import '../encryption/secret_encryption_service.dart';

/// A single secret carried in a vault archive: plaintext metadata +
/// AES-256-GCM encrypted value.
class VaultBackupRecord {
  const VaultBackupRecord({
    required this.name,
    required this.secretType,
    this.serviceName,
    this.environment,
    this.notes,
    this.tags,
    required this.encrypted,
  });
  final String name;
  final String secretType;
  final String? serviceName;
  final String? environment;
  final String? notes;
  final String? tags;
  final EncryptedSecret encrypted;
}

/// Backup / recovery net for the vault (PR-A).
///
/// Provides verifiable integrity checks and export/import round-trips
/// so a user can trust their data survives migration and disk failure.
class VaultBackupService {
  VaultBackupService({
    SecretEncryptionService? encryptionService,
    KeyDerivationService? keyDerivationService,
    MasterKeyService? masterKeyService,
  }) : _enc = encryptionService ?? SecretEncryptionService(),
       _kdf = keyDerivationService ?? KeyDerivationService(),
       _mks = masterKeyService ?? MasterKeyService();

  final SecretEncryptionService _enc;
  final KeyDerivationService _kdf;
  final MasterKeyService _mks;

  static const String _archiveFormat = 'keybox-vault-archive';
  static const int _archiveFormatVersion = 1;
  static const String _kdfAlgorithm = 'PBKDF2-HMAC-SHA256';
  static const String _cipherAlgorithm = 'AES-256-GCM';

  /// Verifies that every [records] entry decrypts and authenticates under [mek].
  ///
  /// Returns true only if all records pass GCM authentication. A single
  /// corrupted record (tampered ciphertext, IV, or auth tag) or the wrong key
  /// returns false — [SecretEncryptionService.decrypt] returns null on any
  /// GCM authentication failure.
  bool verifyIntegrity(List<EncryptedSecret> records, Uint8List mek) {
    for (final record in records) {
      final plaintext = _enc.decrypt(
        encryptedValue: record.encryptedValue,
        iv: record.iv,
        authTag: record.authTag,
        key: mek,
      );
      if (plaintext == null) return false;
    }
    return true;
  }

  /// Serializes [records] into a versioned JSON vault archive (format v1).
  ///
  /// Runs [verifyIntegrity] first and returns null if any record fails to
  /// authenticate under [mek] — a corrupt backup is never produced. On success
  /// returns the archive JSON string (binary fields base64-encoded), carrying
  /// [salt], [wrappedMek], the KDF/cipher parameters, and every record.
  String? exportArchive({
    required Uint8List salt,
    required Uint8List wrappedMek,
    required List<VaultBackupRecord> records,
    required Uint8List mek,
  }) {
    // Refuse to produce a backup whose records cannot authenticate.
    final encrypted = records.map((r) => r.encrypted).toList();
    if (!verifyIntegrity(encrypted, mek)) return null;

    return jsonEncode({
      'format': _archiveFormat,
      'formatVersion': _archiveFormatVersion,
      'kdf': {
        'algorithm': _kdfAlgorithm,
        'iterations': CryptoConstants.pbkdf2Iterations,
        'saltLength': CryptoConstants.saltLength,
        'keyLength': CryptoConstants.keyLength,
      },
      'cipher': {
        'algorithm': _cipherAlgorithm,
        'ivLength': CryptoConstants.ivLength,
        'authTagLength': CryptoConstants.authTagLength,
      },
      'salt': base64Encode(salt),
      'wrappedMek': base64Encode(wrappedMek),
      'recordCount': records.length,
      'records': records.map(_recordToJson).toList(),
    });
  }

  /// Parses a vault [archive] JSON, unwraps the MEK with [password], and
  /// re-encrypts every record under [destinationMek].
  ///
  /// Returns null on any failure: malformed JSON, format/version mismatch, KDF
  /// parameters diverging from [CryptoConstants], wrong password (unwrap null),
  /// record-count mismatch, or a record failing GCM authentication. On success
  /// each record is re-encrypted with a fresh IV under [destinationMek]
  /// (plaintext-equivalent; ciphertext may differ from the original).
  List<VaultBackupRecord>? importArchive({
    required String archive,
    required String password,
    required Uint8List destinationMek,
  }) {
    final json = _parseArchive(archive);
    if (json == null) return null;
    final body = _parseBinaryFields(json);
    if (body == null) return null;
    final (salt, wrappedMek, rawRecords) = body;

    Uint8List? pdk;
    Uint8List? sourceMek;
    try {
      pdk = _kdf.deriveKey(password: password, salt: salt);
      sourceMek = _mks.unwrap(wrappedKey: wrappedMek, wrappingKey: pdk);
      if (sourceMek == null) return null;
      return _reencryptRecords(rawRecords, sourceMek, destinationMek);
    } finally {
      // Key material must not linger in memory (project security rule).
      if (pdk != null) _zeroOut(pdk);
      if (sourceMek != null) _zeroOut(sourceMek);
    }
  }

  Map<String, dynamic> _recordToJson(VaultBackupRecord record) => {
    'name': record.name,
    'secretType': record.secretType,
    'serviceName': record.serviceName,
    'environment': record.environment,
    'notes': record.notes,
    'tags': record.tags,
    'encryptedValue': base64Encode(record.encrypted.encryptedValue),
    'iv': base64Encode(record.encrypted.iv),
    'authTag': base64Encode(record.encrypted.authTag),
  };

  Map<String, dynamic>? _parseArchive(String archive) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(archive) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    if (json['format'] != _archiveFormat) return null;
    if (json['formatVersion'] != _archiveFormatVersion) return null;
    if (!_isValidKdf(json['kdf'])) return null;
    return json;
  }

  /// The archive header is not authenticated, so its KDF parameters are
  /// recorded but never trusted: anything diverging from [CryptoConstants]
  /// (e.g. an iteration-count downgrade) is rejected outright.
  bool _isValidKdf(Object? kdf) {
    if (kdf is! Map) return false;
    return kdf['algorithm'] == _kdfAlgorithm &&
        kdf['iterations'] == CryptoConstants.pbkdf2Iterations &&
        kdf['saltLength'] == CryptoConstants.saltLength &&
        kdf['keyLength'] == CryptoConstants.keyLength;
  }

  (Uint8List, Uint8List, List<dynamic>)? _parseBinaryFields(
    Map<String, dynamic> json,
  ) {
    try {
      final rawRecords = json['records'] as List<dynamic>;
      if (json['recordCount'] != rawRecords.length) return null;
      return (
        base64Decode(json['salt'] as String),
        base64Decode(json['wrappedMek'] as String),
        rawRecords,
      );
    } catch (_) {
      return null;
    }
  }

  List<VaultBackupRecord>? _reencryptRecords(
    List<dynamic> rawRecords,
    Uint8List sourceMek,
    Uint8List destinationMek,
  ) {
    final result = <VaultBackupRecord>[];
    for (final raw in rawRecords) {
      final record = _reencryptRecord(raw, sourceMek, destinationMek);
      if (record == null) return null;
      result.add(record);
    }
    return result;
  }

  VaultBackupRecord? _reencryptRecord(
    Object? raw,
    Uint8List sourceMek,
    Uint8List destinationMek,
  ) {
    if (raw is! Map) return null;
    try {
      final plaintext = _enc.decrypt(
        encryptedValue: base64Decode(raw['encryptedValue'] as String),
        iv: base64Decode(raw['iv'] as String),
        authTag: base64Decode(raw['authTag'] as String),
        key: sourceMek,
      );
      if (plaintext == null) return null;
      return VaultBackupRecord(
        name: raw['name'] as String,
        secretType: raw['secretType'] as String,
        serviceName: raw['serviceName'] as String?,
        environment: raw['environment'] as String?,
        notes: raw['notes'] as String?,
        tags: raw['tags'] as String?,
        // Fresh IV: re-encryption under the destination MEK never reuses
        // IVs carried in the archive.
        encrypted: _enc.encrypt(value: plaintext, key: destinationMek),
      );
    } catch (_) {
      return null;
    }
  }

  void _zeroOut(Uint8List bytes) => bytes.fillRange(0, bytes.length, 0);
}
