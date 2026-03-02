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
  });
}
