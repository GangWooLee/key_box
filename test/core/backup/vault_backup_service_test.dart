import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/backup/vault_backup_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';

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
}
