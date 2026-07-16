import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/constants/crypto_constants.dart';

void main() {
  late KeyDerivationService service;

  setUp(() {
    service = KeyDerivationService();
  });

  group('KeyDerivationService', () {
    group('generateSalt', () {
      test('generates salt of correct length', () {
        final salt = service.generateSalt();
        expect(salt.length, equals(CryptoConstants.saltLength));
      });

      test('generates unique salts', () {
        final salt1 = service.generateSalt();
        final salt2 = service.generateSalt();
        expect(salt1, isNot(equals(salt2)));
      });
    });

    group('deriveKey', () {
      test('derives key of correct length', () {
        final salt = service.generateSalt();
        final key = service.deriveKey(password: 'testpassword', salt: salt);
        expect(key.length, equals(CryptoConstants.keyLength));
      });

      test('same password and salt produces same key (deterministic)', () {
        final salt = Uint8List.fromList(List.filled(32, 0x42));
        final key1 = service.deriveKey(password: 'testpassword', salt: salt);
        final key2 = service.deriveKey(password: 'testpassword', salt: salt);
        expect(key1, equals(key2));
      });

      test('different passwords produce different keys', () {
        final salt = service.generateSalt();
        final key1 = service.deriveKey(password: 'password1', salt: salt);
        final key2 = service.deriveKey(password: 'password2', salt: salt);
        expect(key1, isNot(equals(key2)));
      });

      test('different salts produce different keys', () {
        final salt1 = service.generateSalt();
        final salt2 = service.generateSalt();
        final key1 = service.deriveKey(password: 'testpassword', salt: salt1);
        final key2 = service.deriveKey(password: 'testpassword', salt: salt2);
        expect(key1, isNot(equals(key2)));
      });

      test('handles empty password', () {
        final salt = service.generateSalt();
        final key = service.deriveKey(password: '', salt: salt);
        expect(key.length, equals(CryptoConstants.keyLength));
      });

      test('handles unicode password', () {
        final salt = service.generateSalt();
        final key = service.deriveKey(password: '한국어패스워드', salt: salt);
        expect(key.length, equals(CryptoConstants.keyLength));
      });
    });

    // Known-answer tests: pin the ALGORITHM to published PBKDF2-HMAC-SHA256
    // vectors (IETF draft josefsson-pbkdf2-test-vectors, 32-byte dkLen).
    // Behavioral tests above prove shape/determinism; only a KAT catches a
    // silently swapped digest, wrong salt/password order, or drifted params.
    // Load-bearing now that [iterations] is constructor-injectable.
    group('known-answer vectors (algorithm pin)', () {
      Uint8List saltOf(String s) => Uint8List.fromList(s.codeUnits);
      String hex(Uint8List b) =>
          b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

      test('P="password", S="salt", c=1 matches the published vector', () {
        final key = KeyDerivationService(
          iterations: 1,
        ).deriveKey(password: 'password', salt: saltOf('salt'));
        expect(
          hex(key),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
        );
      });

      test('P="password", S="salt", c=2 matches the published vector', () {
        final key = KeyDerivationService(
          iterations: 2,
        ).deriveKey(password: 'password', salt: saltOf('salt'));
        expect(
          hex(key),
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
        );
      });

      test('iteration count is load-bearing (c=2 must NOT match the c=1 '
          'vector) — guards the injectable parameter', () {
        final key = KeyDerivationService(
          iterations: 2,
        ).deriveKey(password: 'password', salt: saltOf('salt'));
        expect(
          hex(key),
          isNot(
            '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
          ),
        );
      });
    });

    // Production pin: the default constructor must derive with EXACTLY the
    // 600k constant — if either the default wiring or the constant drifts,
    // this goes red. (Two 600k derives ≈ a few seconds — the price of the pin.)
    group('production work factor pin', () {
      test('default constructor == explicit pbkdf2Iterations (600k)', () {
        expect(CryptoConstants.pbkdf2Iterations, 600000);
        final salt = Uint8List.fromList(List.filled(32, 0x42));
        final byDefault = KeyDerivationService().deriveKey(
          password: 'pin-check',
          salt: salt,
        );
        final byConstant = KeyDerivationService(
          iterations: CryptoConstants.pbkdf2Iterations,
        ).deriveKey(password: 'pin-check', salt: salt);
        expect(byDefault, equals(byConstant));
      });
    });
  });
}
