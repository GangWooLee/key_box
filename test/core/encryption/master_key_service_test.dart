import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/constants/crypto_constants.dart';

void main() {
  late MasterKeyService service;
  late KeyDerivationService kds;

  setUp(() {
    service = MasterKeyService();
    kds = KeyDerivationService();
  });

  group('MasterKeyService', () {
    group('generateMasterKey', () {
      test('generates key of correct length', () {
        final mek = service.generateMasterKey();
        expect(mek.length, equals(CryptoConstants.mekLength));
      });

      test('generates unique keys', () {
        final mek1 = service.generateMasterKey();
        final mek2 = service.generateMasterKey();
        expect(mek1, isNot(equals(mek2)));
      });
    });

    group('wrap', () {
      test('produces wrapped key of correct length (60 bytes)', () {
        final mek = service.generateMasterKey();
        final wrappingKey = kds.deriveKey(
          password: 'testpassword',
          salt: kds.generateSalt(),
        );

        final wrapped = service.wrap(masterKey: mek, wrappingKey: wrappingKey);

        // IV(12) + AuthTag(16) + Ciphertext(32) = 60
        expect(wrapped.length, equals(CryptoConstants.wrappedMekLength));
        expect(wrapped.length, equals(60));
      });

      test(
        'different wraps of same key produce different output (random IV)',
        () {
          final mek = service.generateMasterKey();
          final wrappingKey = kds.deriveKey(
            password: 'testpassword',
            salt: kds.generateSalt(),
          );

          final wrapped1 = service.wrap(
            masterKey: mek,
            wrappingKey: wrappingKey,
          );
          final wrapped2 = service.wrap(
            masterKey: mek,
            wrappingKey: wrappingKey,
          );

          // Different IVs → different wrapped outputs
          expect(wrapped1, isNot(equals(wrapped2)));
        },
      );
    });

    group('unwrap', () {
      test('round-trip: wrap then unwrap returns original MEK', () {
        final mek = service.generateMasterKey();
        final wrappingKey = kds.deriveKey(
          password: 'testpassword',
          salt: kds.generateSalt(),
        );

        final wrapped = service.wrap(masterKey: mek, wrappingKey: wrappingKey);
        final unwrapped = service.unwrap(
          wrappedKey: wrapped,
          wrappingKey: wrappingKey,
        );

        expect(unwrapped, isNotNull);
        expect(unwrapped, equals(mek));
      });

      test('wrong wrapping key returns null', () {
        final mek = service.generateMasterKey();
        final salt = kds.generateSalt();
        final correctKey = kds.deriveKey(password: 'correct', salt: salt);
        final wrongKey = kds.deriveKey(password: 'wrong', salt: salt);

        final wrapped = service.wrap(masterKey: mek, wrappingKey: correctKey);
        final unwrapped = service.unwrap(
          wrappedKey: wrapped,
          wrappingKey: wrongKey,
        );

        expect(unwrapped, isNull);
      });

      test('corrupted wrapped key returns null', () {
        final mek = service.generateMasterKey();
        final wrappingKey = kds.deriveKey(
          password: 'testpassword',
          salt: kds.generateSalt(),
        );

        final wrapped = service.wrap(masterKey: mek, wrappingKey: wrappingKey);
        // Corrupt a byte in the ciphertext portion
        wrapped[wrapped.length - 1] ^= 0xFF;

        final unwrapped = service.unwrap(
          wrappedKey: wrapped,
          wrappingKey: wrappingKey,
        );

        expect(unwrapped, isNull);
      });

      test('invalid length returns null', () {
        final wrappingKey = kds.deriveKey(
          password: 'testpassword',
          salt: kds.generateSalt(),
        );

        final tooShort = Uint8List.fromList(List.filled(30, 0));
        expect(
          service.unwrap(wrappedKey: tooShort, wrappingKey: wrappingKey),
          isNull,
        );
      });
    });

    group('byte layout compatibility', () {
      test(
        'wrapped MEK has correct structure: IV(12) + AuthTag(16) + Ciphertext(32)',
        () {
          final mek = service.generateMasterKey();
          final wrappingKey = kds.deriveKey(
            password: 'testpassword',
            salt: kds.generateSalt(),
          );

          final wrapped = service.wrap(
            masterKey: mek,
            wrappingKey: wrappingKey,
          );

          // Verify we can decompose the structure
          final iv = wrapped.sublist(0, 12);
          final authTag = wrapped.sublist(12, 28);
          final ciphertext = wrapped.sublist(28, 60);

          expect(iv.length, equals(12));
          expect(authTag.length, equals(16));
          expect(ciphertext.length, equals(32));
        },
      );
    });

    group('full flow integration', () {
      test('setup → lock → unlock flow', () {
        // Setup: generate MEK, derive wrapping key, wrap
        final salt = kds.generateSalt();
        const password = 'mypassword123';
        final wrappingKey = kds.deriveKey(password: password, salt: salt);
        final mek = service.generateMasterKey();
        final wrappedMek = service.wrap(
          masterKey: mek,
          wrappingKey: wrappingKey,
        );

        // Simulate app restart (only salt + wrappedMek persisted)
        // Unlock: re-derive wrapping key, unwrap
        final unlockKey = kds.deriveKey(password: password, salt: salt);
        final recoveredMek = service.unwrap(
          wrappedKey: wrappedMek,
          wrappingKey: unlockKey,
        );

        expect(recoveredMek, equals(mek));
      });

      test('wrong password during unlock fails', () {
        final salt = kds.generateSalt();
        final wrappingKey = kds.deriveKey(password: 'correct', salt: salt);
        final mek = service.generateMasterKey();
        final wrappedMek = service.wrap(
          masterKey: mek,
          wrappingKey: wrappingKey,
        );

        // Try to unlock with wrong password
        final wrongKey = kds.deriveKey(password: 'wrongpass', salt: salt);
        final result = service.unwrap(
          wrappedKey: wrappedMek,
          wrappingKey: wrongKey,
        );

        expect(result, isNull);
      });
    });
  });
}
