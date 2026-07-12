import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/constants/crypto_constants.dart';

void main() {
  late SecretEncryptionService service;
  late MasterKeyService mks;

  setUp(() {
    service = SecretEncryptionService();
    mks = MasterKeyService();
  });

  Uint8List makeKey() => mks.generateMasterKey();

  group('SecretEncryptionService', () {
    group('encrypt', () {
      test('produces EncryptedSecret with correct field lengths', () {
        final key = makeKey();
        final result = service.encrypt(value: 'my-secret-api-key', key: key);

        expect(result.iv.length, equals(CryptoConstants.ivLength));
        expect(result.authTag.length, equals(CryptoConstants.authTagLength));
        expect(result.encryptedValue.length, greaterThan(0));
      });

      test('different encryptions of same value produce different output', () {
        final key = makeKey();
        final r1 = service.encrypt(value: 'same-value', key: key);
        final r2 = service.encrypt(value: 'same-value', key: key);

        // Random IVs → different ciphertext
        expect(r1.iv, isNot(equals(r2.iv)));
        expect(r1.encryptedValue, isNot(equals(r2.encryptedValue)));
      });
    });

    group('decrypt', () {
      test('round-trip: encrypt then decrypt returns original value', () {
        final key = makeKey();
        const plaintext = 'my-secret-api-key-12345';

        final encrypted = service.encrypt(value: plaintext, key: key);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );

        expect(decrypted, equals(plaintext));
      });

      test('wrong key returns null', () {
        final correctKey = makeKey();
        final wrongKey = makeKey();

        final encrypted = service.encrypt(value: 'secret', key: correctKey);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: wrongKey,
        );

        expect(decrypted, isNull);
      });

      test('corrupted ciphertext returns null', () {
        final key = makeKey();
        final encrypted = service.encrypt(value: 'secret', key: key);

        // Corrupt a byte
        final corrupted = Uint8List.fromList(encrypted.encryptedValue);
        corrupted[0] ^= 0xFF;

        final decrypted = service.decrypt(
          encryptedValue: corrupted,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );

        expect(decrypted, isNull);
      });

      test('corrupted auth tag returns null', () {
        final key = makeKey();
        final encrypted = service.encrypt(value: 'secret', key: key);

        final badTag = Uint8List.fromList(encrypted.authTag);
        badTag[0] ^= 0xFF;

        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: badTag,
          key: key,
        );

        expect(decrypted, isNull);
      });
    });

    group('edge cases', () {
      test('encrypts empty string', () {
        final key = makeKey();
        final encrypted = service.encrypt(value: '', key: key);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );
        expect(decrypted, equals(''));
      });

      test('encrypts long value (4KB)', () {
        final key = makeKey();
        final longValue = 'A' * 4096;

        final encrypted = service.encrypt(value: longValue, key: key);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );
        expect(decrypted, equals(longValue));
      });

      test('encrypts unicode value', () {
        final key = makeKey();
        const unicode = '한국어 비밀번호 🔐 émojis & spëcîal';

        final encrypted = service.encrypt(value: unicode, key: key);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );
        expect(decrypted, equals(unicode));
      });

      test('encrypts multiline value', () {
        final key = makeKey();
        const multiline = '''-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0Z3VS5JJcds3xfn/ygWop5LMYf
-----END RSA PRIVATE KEY-----''';

        final encrypted = service.encrypt(value: multiline, key: key);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );
        expect(decrypted, equals(multiline));
      });
    });

    group('AAD binding', () {
      test('round-trip with matching AAD returns original value', () {
        final key = makeKey();
        final aad = secretAad(secretId: 7, recordVersion: 1);

        final encrypted = service.encrypt(value: 'bound', key: key, aad: aad);
        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
          aad: aad,
        );

        expect(decrypted, equals('bound'));
      });

      test('mismatched AAD (different secretId) returns null', () {
        final key = makeKey();
        final encrypted = service.encrypt(
          value: 'bound',
          key: key,
          aad: secretAad(secretId: 7, recordVersion: 1),
        );

        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
          aad: secretAad(secretId: 8, recordVersion: 1),
        );

        expect(decrypted, isNull);
      });

      test('mismatched AAD (different recordVersion) returns null', () {
        final key = makeKey();
        final encrypted = service.encrypt(
          value: 'bound',
          key: key,
          aad: secretAad(secretId: 7, recordVersion: 1),
        );

        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
          aad: secretAad(secretId: 7, recordVersion: 2),
        );

        expect(decrypted, isNull);
      });

      test('AAD-bound ciphertext does not decrypt without AAD', () {
        final key = makeKey();
        final encrypted = service.encrypt(
          value: 'bound',
          key: key,
          aad: secretAad(secretId: 7, recordVersion: 1),
        );

        final decrypted = service.decrypt(
          encryptedValue: encrypted.encryptedValue,
          iv: encrypted.iv,
          authTag: encrypted.authTag,
          key: key,
        );

        expect(decrypted, isNull);
      });

      test('omitted AAD is equivalent to explicit empty AAD', () {
        final key = makeKey();

        // encrypt without aad → decrypt with explicit empty aad
        final e1 = service.encrypt(value: 'legacy', key: key);
        expect(
          service.decrypt(
            encryptedValue: e1.encryptedValue,
            iv: e1.iv,
            authTag: e1.authTag,
            key: key,
            aad: Uint8List(0),
          ),
          equals('legacy'),
        );

        // encrypt with explicit empty aad → decrypt without aad
        final e2 = service.encrypt(
          value: 'legacy',
          key: key,
          aad: Uint8List(0),
        );
        expect(
          service.decrypt(
            encryptedValue: e2.encryptedValue,
            iv: e2.iv,
            authTag: e2.authTag,
            key: key,
          ),
          equals('legacy'),
        );
      });

      test('substitution attack: record A ciphertext under record B identity '
          'fails authentication', () {
        final key = makeKey();
        // Record A (id 1) and record B (id 2), both version 1.
        final recordA = service.encrypt(
          value: 'prod-db-password',
          key: key,
          aad: secretAad(secretId: 1, recordVersion: 1),
        );

        // Attacker copies A's (ciphertext, iv, tag) over B's row; the read
        // path decrypts with B's identity.
        final decrypted = service.decrypt(
          encryptedValue: recordA.encryptedValue,
          iv: recordA.iv,
          authTag: recordA.authTag,
          key: key,
          aad: secretAad(secretId: 2, recordVersion: 1),
        );

        expect(decrypted, isNull);
      });

      test(
        'rollback attack: v1 ciphertext under v2 AAD fails authentication',
        () {
          final key = makeKey();
          final v1 = service.encrypt(
            value: 'old-rotated-away-key',
            key: key,
            aad: secretAad(secretId: 5, recordVersion: 1),
          );

          // After rotation the row says recordVersion=2; a restored v1
          // ciphertext must not authenticate.
          final decrypted = service.decrypt(
            encryptedValue: v1.encryptedValue,
            iv: v1.iv,
            authTag: v1.authTag,
            key: key,
            aad: secretAad(secretId: 5, recordVersion: 2),
          );

          expect(decrypted, isNull);
        },
      );
    });

    group('secretAad', () {
      test('is deterministic for the same identity', () {
        expect(
          secretAad(secretId: 42, recordVersion: 3),
          equals(secretAad(secretId: 42, recordVersion: 3)),
        );
      });

      test('distinguishes secretId and recordVersion', () {
        final base = secretAad(secretId: 1, recordVersion: 1);
        expect(secretAad(secretId: 2, recordVersion: 1), isNot(equals(base)));
        expect(secretAad(secretId: 1, recordVersion: 2), isNot(equals(base)));
      });

      test('encodes the domain-separated label', () {
        expect(
          String.fromCharCodes(secretAad(secretId: 42, recordVersion: 3)),
          equals('keybox/v1/secret:42:3'),
        );
      });
    });

    group('integration with MasterKeyService', () {
      test(
        'full flow: derive key → generate MEK → wrap → unwrap → encrypt/decrypt secret',
        () {
          // Simulate the full key hierarchy
          final mek = mks.generateMasterKey();

          // Encrypt a secret with MEK
          const secretValue = 'sk-proj-abc123def456';
          final encrypted = service.encrypt(value: secretValue, key: mek);

          // Decrypt with the same MEK
          final decrypted = service.decrypt(
            encryptedValue: encrypted.encryptedValue,
            iv: encrypted.iv,
            authTag: encrypted.authTag,
            key: mek,
          );

          expect(decrypted, equals(secretValue));
        },
      );
    });
  });
}
