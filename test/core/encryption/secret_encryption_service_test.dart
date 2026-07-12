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
