import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/backup/vault_backup_service.dart';
import 'package:key_box/core/constants/crypto_constants.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:pointycastle/export.dart';

/// Fast, deterministic KDF stand-in for tests: SHA-256(utf8(password) + salt).
///
/// Avoids the ~600k-iteration PBKDF2 cost while preserving deriveKey's
/// contract (32-byte key, dependent on both password and salt). Only the
/// real-PBKDF2 round-trip test uses the production [KeyDerivationService].
class _FakeKeyDerivationService extends KeyDerivationService {
  @override
  Uint8List deriveKey({required String password, required Uint8List salt}) {
    final input = Uint8List.fromList([...utf8.encode(password), ...salt]);
    return SHA256Digest().process(input); // 32 bytes
  }
}

/// Builds a [VaultBackupRecord] whose value is encrypted under [mek].
VaultBackupRecord _record(
  SecretEncryptionService enc,
  Uint8List mek, {
  required String name,
  required String secretType,
  String? serviceName,
  String? environment,
  String? notes,
  String? tags,
  required String plaintext,
}) {
  return VaultBackupRecord(
    name: name,
    secretType: secretType,
    serviceName: serviceName,
    environment: environment,
    notes: notes,
    tags: tags,
    encrypted: enc.encrypt(value: plaintext, key: mek),
  );
}

/// Wraps [mek] under a KDF-derived key and exports the [records] archive.
String _buildArchive({
  required VaultBackupService service,
  required KeyDerivationService kdf,
  required MasterKeyService mks,
  required String password,
  required Uint8List mek,
  required List<VaultBackupRecord> records,
}) {
  final salt = Uint8List(32)..fillRange(0, 32, 3);
  final pdk = kdf.deriveKey(password: password, salt: salt);
  final wrappedMek = mks.wrap(masterKey: mek, wrappingKey: pdk);
  final archive = service.exportArchive(
    salt: salt,
    wrappedMek: wrappedMek,
    records: records,
    mek: mek,
  );
  return archive!;
}

void main() {
  late VaultBackupService service;
  late SecretEncryptionService enc;
  late Uint8List mek;

  setUp(() {
    service = VaultBackupService();
    enc = SecretEncryptionService();
    // Deterministic 32-byte test key.
    mek = Uint8List(32)..fillRange(0, 32, 7);
  });

  group('VaultBackupService.verifyIntegrity', () {
    test('returns true when every record decrypts under the key', () {
      final records = [
        enc.encrypt(value: 'api-key-1', key: mek),
        enc.encrypt(value: 'password-2', key: mek),
      ];

      expect(service.verifyIntegrity(records, mek), isTrue);
    });

    test('returns false when a record auth tag is corrupted', () {
      final good = enc.encrypt(value: 'secret', key: mek);
      final tamperedTag = Uint8List.fromList(good.authTag);
      tamperedTag[0] ^= 0xFF; // flip a byte -> GCM auth must fail
      final tampered = EncryptedSecret(
        encryptedValue: good.encryptedValue,
        iv: good.iv,
        authTag: tamperedTag,
      );

      expect(service.verifyIntegrity([tampered], mek), isFalse);
    });

    test('returns false when decrypted under the wrong key', () {
      final records = [enc.encrypt(value: 'secret', key: mek)];
      final wrongKey = Uint8List(32)..fillRange(0, 32, 9);

      expect(service.verifyIntegrity(records, wrongKey), isFalse);
    });
  });

  group('VaultBackupService.exportArchive', () {
    test('returns archive JSON matching the v1 contract', () {
      final mks = MasterKeyService();
      final salt = Uint8List(32)..fillRange(0, 32, 3);
      final pdk = Uint8List(32)..fillRange(0, 32, 5);
      final wrappedMek = mks.wrap(masterKey: mek, wrappingKey: pdk);
      final records = [
        _record(
          enc,
          mek,
          name: 'GitHub',
          secretType: 'apiKey',
          plaintext: 'ghp_abc123',
        ),
      ];

      final archive = service.exportArchive(
        salt: salt,
        wrappedMek: wrappedMek,
        records: records,
        mek: mek,
      );

      expect(archive, isNotNull);
      final json = jsonDecode(archive!) as Map<String, dynamic>;
      expect(json['format'], 'keybox-vault-archive');
      expect(json['formatVersion'], 1);
      expect(json['recordCount'], 1);
      expect(
        (json['kdf'] as Map)['iterations'],
        CryptoConstants.pbkdf2Iterations,
      );
    });

    test('returns null when a record auth tag is corrupted (rejects corrupt '
        'backup)', () {
      final mks = MasterKeyService();
      final salt = Uint8List(32)..fillRange(0, 32, 3);
      final pdk = Uint8List(32)..fillRange(0, 32, 5);
      final wrappedMek = mks.wrap(masterKey: mek, wrappingKey: pdk);

      final good = enc.encrypt(value: 'secret', key: mek);
      final tamperedTag = Uint8List.fromList(good.authTag);
      tamperedTag[0] ^= 0xFF;
      final corrupt = VaultBackupRecord(
        name: 'x',
        secretType: 'apiKey',
        encrypted: EncryptedSecret(
          encryptedValue: good.encryptedValue,
          iv: good.iv,
          authTag: tamperedTag,
        ),
      );

      final archive = service.exportArchive(
        salt: salt,
        wrappedMek: wrappedMek,
        records: [corrupt],
        mek: mek,
      );

      expect(archive, isNull);
    });
  });

  group('VaultBackupService.importArchive (fake KDF)', () {
    late _FakeKeyDerivationService fakeKdf;
    late VaultBackupService fakeService;
    late MasterKeyService mks;
    late Uint8List destMek;
    const password = 'correct horse battery staple';

    setUp(() {
      fakeKdf = _FakeKeyDerivationService();
      mks = MasterKeyService();
      fakeService = VaultBackupService(keyDerivationService: fakeKdf);
      destMek = Uint8List(32)..fillRange(0, 32, 11);
    });

    test('round-trips records: plaintext + metadata survive re-encryption '
        'under a new destination MEK', () {
      final records = [
        _record(
          enc,
          mek,
          name: 'GitHub',
          secretType: 'apiKey',
          serviceName: 'github.com',
          plaintext: 'ghp_value_1',
        ),
        _record(
          enc,
          mek,
          name: 'Postgres',
          secretType: 'password',
          serviceName: 'db-prod',
          plaintext: 'pw_value_2',
        ),
      ];
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: records,
      );

      final imported = fakeService.importArchive(
        archive: archive,
        password: password,
        destinationMek: destMek,
      );

      expect(imported, isNotNull);
      expect(imported!.length, records.length);
      // Plaintext equivalence: decrypt under the NEW destination MEK.
      expect(
        enc.decrypt(
          encryptedValue: imported[0].encrypted.encryptedValue,
          iv: imported[0].encrypted.iv,
          authTag: imported[0].encrypted.authTag,
          key: destMek,
        ),
        'ghp_value_1',
      );
      expect(
        enc.decrypt(
          encryptedValue: imported[1].encrypted.encryptedValue,
          iv: imported[1].encrypted.iv,
          authTag: imported[1].encrypted.authTag,
          key: destMek,
        ),
        'pw_value_2',
      );
      // Metadata equivalence.
      expect(imported[0].name, 'GitHub');
      expect(imported[0].secretType, 'apiKey');
      expect(imported[0].serviceName, 'github.com');
      expect(imported[1].name, 'Postgres');
      expect(imported[1].secretType, 'password');
      expect(imported[1].serviceName, 'db-prod');
    });

    test('returns null on wrong password', () {
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: [
          _record(enc, mek, name: 'x', secretType: 'apiKey', plaintext: 'v'),
        ],
      );

      final imported = fakeService.importArchive(
        archive: archive,
        password: 'wrong password',
        destinationMek: destMek,
      );

      expect(imported, isNull);
    });

    test('returns null when a record auth tag in the archive is corrupted', () {
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: [
          _record(enc, mek, name: 'x', secretType: 'apiKey', plaintext: 'v'),
        ],
      );
      final map = jsonDecode(archive) as Map<String, dynamic>;
      final rec0 = (map['records'] as List)[0] as Map<String, dynamic>;
      final tag = base64Decode(rec0['authTag'] as String);
      tag[0] ^= 0xFF;
      rec0['authTag'] = base64Encode(tag);
      final tampered = jsonEncode(map);

      expect(
        fakeService.importArchive(
          archive: tampered,
          password: password,
          destinationMek: destMek,
        ),
        isNull,
      );
    });

    test('returns null when wrappedMek is corrupted', () {
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: [
          _record(enc, mek, name: 'x', secretType: 'apiKey', plaintext: 'v'),
        ],
      );
      final map = jsonDecode(archive) as Map<String, dynamic>;
      final wrapped = base64Decode(map['wrappedMek'] as String);
      wrapped[0] ^= 0xFF;
      map['wrappedMek'] = base64Encode(wrapped);
      final tampered = jsonEncode(map);

      expect(
        fakeService.importArchive(
          archive: tampered,
          password: password,
          destinationMek: destMek,
        ),
        isNull,
      );
    });

    test('returns null when recordCount does not match records length', () {
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: [
          _record(enc, mek, name: 'x', secretType: 'apiKey', plaintext: 'v'),
        ],
      );
      final map = jsonDecode(archive) as Map<String, dynamic>;
      map['recordCount'] = 99;
      final tampered = jsonEncode(map);

      expect(
        fakeService.importArchive(
          archive: tampered,
          password: password,
          destinationMek: destMek,
        ),
        isNull,
      );
    });

    test('returns null on unsupported formatVersion (2)', () {
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: [
          _record(enc, mek, name: 'x', secretType: 'apiKey', plaintext: 'v'),
        ],
      );
      final map = jsonDecode(archive) as Map<String, dynamic>;
      map['formatVersion'] = 2;
      final tampered = jsonEncode(map);

      expect(
        fakeService.importArchive(
          archive: tampered,
          password: password,
          destinationMek: destMek,
        ),
        isNull,
      );
    });

    test('returns null on KDF iteration downgrade (1000)', () {
      final archive = _buildArchive(
        service: fakeService,
        kdf: fakeKdf,
        mks: mks,
        password: password,
        mek: mek,
        records: [
          _record(enc, mek, name: 'x', secretType: 'apiKey', plaintext: 'v'),
        ],
      );
      final map = jsonDecode(archive) as Map<String, dynamic>;
      (map['kdf'] as Map)['iterations'] = 1000;
      final tampered = jsonEncode(map);

      expect(
        fakeService.importArchive(
          archive: tampered,
          password: password,
          destinationMek: destMek,
        ),
        isNull,
      );
    });

    test('returns null on non-JSON input', () {
      expect(
        fakeService.importArchive(
          archive: 'not json',
          password: password,
          destinationMek: destMek,
        ),
        isNull,
      );
    });
  });

  group('VaultBackupService.importArchive (real PBKDF2)', () {
    test('round-trips a single record with the real KDF', () {
      final realService = VaultBackupService();
      final kdf = KeyDerivationService();
      final mks = MasterKeyService();
      const password = 'real-pbkdf2-password';
      final destMek = Uint8List(32)..fillRange(0, 32, 11);
      final records = [
        _record(
          enc,
          mek,
          name: 'one',
          secretType: 'apiKey',
          plaintext: 'value-1',
        ),
      ];

      final archive = _buildArchive(
        service: realService,
        kdf: kdf,
        mks: mks,
        password: password,
        mek: mek,
        records: records,
      );

      final imported = realService.importArchive(
        archive: archive,
        password: password,
        destinationMek: destMek,
      );

      expect(imported, isNotNull);
      expect(imported!.length, 1);
      expect(
        enc.decrypt(
          encryptedValue: imported[0].encrypted.encryptedValue,
          iv: imported[0].encrypted.iv,
          authTag: imported[0].encrypted.authTag,
          key: destMek,
        ),
        'value-1',
      );
    });
  });
}
