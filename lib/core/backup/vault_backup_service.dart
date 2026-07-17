import 'dart:convert';
import 'dart:typed_data';

import '../constants/crypto_constants.dart';
import '../encryption/key_derivation_service.dart';
import '../encryption/key_hierarchy_service.dart';
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

/// The outcome of parsing + verifying a vault archive, distinguishing the
/// failure modes the restore UI needs to voice (손상 vs 오답, DESIGN.md
/// §restore-from-backup).
sealed class ArchiveImport {
  const ArchiveImport();
}

/// Every record decrypted and re-encrypted under the destination MEK.
final class ArchiveImportSuccess extends ArchiveImport {
  const ArchiveImportSuccess(this.records);
  final List<VaultBackupRecord> records;
}

/// The archive JSON is unparseable, the wrong format/version, carries a
/// divergent KDF, or a record fails GCM authentication — the file is corrupt.
final class ArchiveImportCorrupt extends ArchiveImport {
  const ArchiveImportCorrupt();
}

/// The archive is well-formed but the password cannot unwrap its MEK — the
/// password is wrong (not the file).
final class ArchiveImportWrongPassword extends ArchiveImport {
  const ArchiveImportWrongPassword();
}

/// Backup / recovery net for the vault (PR-A; archive format v3 since Phase 2).
///
/// Provides verifiable integrity checks and export/import round-trips
/// so a user can trust their data survives migration and disk failure.
///
/// v3 closes the "stolen backup leaks the inventory" gap: per-record metadata
/// (name/type/service/env/notes/tags) is MEK-GCM encrypted, so a `.kbx` file
/// carries only ciphertext. v2/v1 archives (plaintext metadata) stay
/// import-only for backward compatibility.
///
/// Archive record canonical form: EMPTY-AAD ciphertext under the MEK.
/// Archives carry no row identity (ids change on restore), so per-record
/// AAD binding does not apply here — producers holding AAD-bound rows (the
/// plaintext→encrypted VaultMigrator) normalize by decrypt→re-encrypt before
/// export, and the restore wiring re-binds AAD when inserting rows.
///
/// MEK wrap semantics by format version:
/// - v3/v2: `wrappedMek` is the MEK wrapped under the HKDF KEK derived from the
///   PDK ([KeyHierarchyService.deriveKek]) — labelled by the `mekWrap` field.
///   v3 (written today) additionally encrypts per-record metadata; v2 is
///   import-only.
/// - v1 (legacy, import only): `wrappedMek` is wrapped under the raw PDK.
class VaultBackupService {
  VaultBackupService({
    SecretEncryptionService? encryptionService,
    KeyDerivationService? keyDerivationService,
    MasterKeyService? masterKeyService,
    KeyHierarchyService? keyHierarchyService,
  }) : _enc = encryptionService ?? SecretEncryptionService(),
       _kdf = keyDerivationService ?? KeyDerivationService(),
       _mks = masterKeyService ?? MasterKeyService(),
       _keyHierarchy = keyHierarchyService ?? KeyHierarchyService();

  final SecretEncryptionService _enc;
  final KeyDerivationService _kdf;
  final MasterKeyService _mks;
  final KeyHierarchyService _keyHierarchy;

  static const String _archiveFormat = 'keybox-vault-archive';
  // v3: per-record metadata (name/type/service/env/notes/tags) is MEK-GCM
  // encrypted so a stolen archive leaks no inventory — only ciphertext. v2
  // (HKDF-KEK wrap) and v1 (raw-PDK wrap) carry plaintext metadata and remain
  // import-only for backward compatibility.
  static const int _archiveFormatVersion = 3;
  static const int _kekWrapVersion = 2;
  static const int _legacyPdkVersion = 1;
  static const String _mekWrapKekV1 = 'hkdf-kek-v1';
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

  /// Serializes [records] into a versioned JSON vault archive (format v3:
  /// encrypted per-record metadata).
  ///
  /// [wrappedMek] MUST be the MEK wrapped under the HKDF KEK
  /// ([KeyHierarchyService.deriveKek]) — v3/v2 semantics; the raw-PDK wrap of
  /// v1 is no longer written.
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
      'mekWrap': _mekWrapKekV1,
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
      'records': records.map((r) => _recordToJson(r, mek)).toList(),
    });
  }

  /// Parses a vault [archive] JSON, unwraps the MEK with [password], and
  /// re-encrypts every record under [destinationMek].
  ///
  /// Format switch: v2 archives unwrap via the HKDF KEK derived from the
  /// PDK; legacy v1 archives unwrap under the raw PDK (backward
  /// compatibility). Unknown versions are rejected.
  ///
  /// Returns null on any failure: malformed JSON, format/version/mekWrap
  /// mismatch, KDF parameters diverging from [CryptoConstants], wrong
  /// password (unwrap null), record-count mismatch, or a record failing GCM
  /// authentication. On success each record is re-encrypted with a fresh IV
  /// under [destinationMek] (plaintext-equivalent; ciphertext may differ
  /// from the original).
  List<VaultBackupRecord>? importArchive({
    required String archive,
    required String password,
    required Uint8List destinationMek,
  }) {
    final result = describeImport(
      archive: archive,
      password: password,
      destinationMek: destinationMek,
    );
    return result is ArchiveImportSuccess ? result.records : null;
  }

  /// Like [importArchive] but reports *why* it failed — malformed/corrupt file
  /// vs wrong password — so the restore UI can voice the right clay reason
  /// (DESIGN.md §restore-from-backup).
  ArchiveImport describeImport({
    required String archive,
    required String password,
    required Uint8List destinationMek,
  }) {
    final json = _parseArchive(archive);
    if (json == null) return const ArchiveImportCorrupt();
    final body = _parseBinaryFields(json);
    if (body == null) return const ArchiveImportCorrupt();
    final (salt, wrappedMek, rawRecords) = body;
    final version = json['formatVersion'] as int;
    final usesKek = version >= _kekWrapVersion; // v2 and v3
    final metaEncrypted = version >= _archiveFormatVersion; // v3 only

    Uint8List? pdk;
    Uint8List? kek;
    Uint8List? sourceMek;
    try {
      pdk = _kdf.deriveKey(password: password, salt: salt);
      final wrappingKey = usesKek ? (kek = _keyHierarchy.deriveKek(pdk)) : pdk;
      sourceMek = _mks.unwrap(wrappedKey: wrappedMek, wrappingKey: wrappingKey);
      // A well-formed archive whose MEK won't unwrap = wrong password.
      if (sourceMek == null) return const ArchiveImportWrongPassword();
      final records = _reencryptRecords(
        rawRecords,
        sourceMek,
        destinationMek,
        metaEncrypted,
      );
      // Unwrap succeeded but a record failed GCM = tampered/corrupt file.
      if (records == null) return const ArchiveImportCorrupt();
      return ArchiveImportSuccess(records);
    } finally {
      // Key material must not linger in memory (project security rule).
      if (pdk != null) _zeroOut(pdk);
      if (kek != null) _zeroOut(kek);
      if (sourceMek != null) _zeroOut(sourceMek);
    }
  }

  /// v3 record JSON: the metadata is a single MEK-GCM envelope
  /// (`encryptedMeta`/`metaIv`/`metaAuthTag`) so the archive carries no
  /// plaintext inventory; the value keeps its existing envelope.
  Map<String, dynamic> _recordToJson(VaultBackupRecord record, Uint8List mek) {
    final meta = _enc.encrypt(
      value: jsonEncode({
        'name': record.name,
        'secretType': record.secretType,
        'serviceName': record.serviceName,
        'environment': record.environment,
        'notes': record.notes,
        'tags': record.tags,
      }),
      key: mek,
    );
    return {
      'encryptedMeta': base64Encode(meta.encryptedValue),
      'metaIv': base64Encode(meta.iv),
      'metaAuthTag': base64Encode(meta.authTag),
      'encryptedValue': base64Encode(record.encrypted.encryptedValue),
      'iv': base64Encode(record.encrypted.iv),
      'authTag': base64Encode(record.encrypted.authTag),
    };
  }

  Map<String, dynamic>? _parseArchive(String archive) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(archive) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    if (json['format'] != _archiveFormat) return null;
    final version = json['formatVersion'];
    if (version != _archiveFormatVersion &&
        version != _kekWrapVersion &&
        version != _legacyPdkVersion) {
      return null;
    }
    // v2/v3 carry the HKDF-KEK wrap; the label must match or the wrap scheme
    // is incompatible (or tampered).
    if ((version == _archiveFormatVersion || version == _kekWrapVersion) &&
        json['mekWrap'] != _mekWrapKekV1) {
      return null;
    }
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
    bool metaEncrypted,
  ) {
    final result = <VaultBackupRecord>[];
    for (final raw in rawRecords) {
      final record = _reencryptRecord(
        raw,
        sourceMek,
        destinationMek,
        metaEncrypted,
      );
      if (record == null) return null;
      result.add(record);
    }
    return result;
  }

  VaultBackupRecord? _reencryptRecord(
    Object? raw,
    Uint8List sourceMek,
    Uint8List destinationMek,
    bool metaEncrypted,
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
      final meta = _readMeta(raw, sourceMek, metaEncrypted);
      if (meta == null) return null;
      return VaultBackupRecord(
        name: meta['name'] as String,
        secretType: meta['secretType'] as String,
        serviceName: meta['serviceName'] as String?,
        environment: meta['environment'] as String?,
        notes: meta['notes'] as String?,
        tags: meta['tags'] as String?,
        // Fresh IV: re-encryption under the destination MEK never reuses
        // IVs carried in the archive.
        encrypted: _enc.encrypt(value: plaintext, key: destinationMek),
      );
    } catch (_) {
      return null;
    }
  }

  /// Recovers a record's metadata map. v3 decrypts the `encryptedMeta` envelope
  /// under [sourceMek] (null if it fails GCM authentication — a tampered file);
  /// v1/v2 read the plaintext fields carried inline.
  Map<String, dynamic>? _readMeta(
    Map raw,
    Uint8List sourceMek,
    bool metaEncrypted,
  ) {
    if (!metaEncrypted) {
      return {
        'name': raw['name'],
        'secretType': raw['secretType'],
        'serviceName': raw['serviceName'],
        'environment': raw['environment'],
        'notes': raw['notes'],
        'tags': raw['tags'],
      };
    }
    final plain = _enc.decrypt(
      encryptedValue: base64Decode(raw['encryptedMeta'] as String),
      iv: base64Decode(raw['metaIv'] as String),
      authTag: base64Decode(raw['metaAuthTag'] as String),
      key: sourceMek,
    );
    if (plain == null) return null;
    return jsonDecode(plain) as Map<String, dynamic>;
  }

  void _zeroOut(Uint8List bytes) => bytes.fillRange(0, bytes.length, 0);
}
