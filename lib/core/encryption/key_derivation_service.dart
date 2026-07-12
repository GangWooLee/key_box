import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../constants/crypto_constants.dart';
import 'secure_random.dart';

/// PBKDF2-HMAC-SHA256 key derivation.
/// Must produce identical output to Rails Encryption::KeyDerivationService.
class KeyDerivationService {
  /// Generate a cryptographically secure random salt.
  Uint8List generateSalt() {
    return secureRandomBytes(CryptoConstants.saltLength);
  }

  /// Derive a key from password and salt using PBKDF2-HMAC-SHA256.
  ///
  /// Parameters must match Rails exactly:
  /// - iterations: 600,000
  /// - key length: 32 bytes
  /// - digest: SHA-256
  Uint8List deriveKey({required String password, required Uint8List salt}) {
    final pbkdf2 = KeyDerivator('SHA-256/HMAC/PBKDF2');
    pbkdf2.init(
      Pbkdf2Parameters(
        salt,
        CryptoConstants.pbkdf2Iterations,
        CryptoConstants.keyLength,
      ),
    );

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
}
