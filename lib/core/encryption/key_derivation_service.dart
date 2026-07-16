import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../constants/crypto_constants.dart';
import 'secure_random.dart';

/// PBKDF2-HMAC-SHA256 key derivation.
/// Must produce identical output to Rails Encryption::KeyDerivationService.
class KeyDerivationService {
  /// Creates a PBKDF2-HMAC-SHA256 deriver.
  ///
  /// [iterations] defaults to the production work factor
  /// ([CryptoConstants.pbkdf2Iterations], 600k) and is injectable ONLY so
  /// behavioral test suites can drop it: a single 600k derive is ~3s in
  /// pure-Dart pointycastle, so suites that assert flow (not KDF strength) pay
  /// seconds per unlock. The algorithm and 32-byte output shape are unchanged.
  /// Never lower it in production — the count is a security parameter and is
  /// recorded in the sidecar/backup KDF envelope.
  KeyDerivationService({int? iterations})
    : _iterations = iterations ?? CryptoConstants.pbkdf2Iterations;

  final int _iterations;

  /// Generate a cryptographically secure random salt.
  Uint8List generateSalt() {
    return secureRandomBytes(CryptoConstants.saltLength);
  }

  /// Derive a key from password and salt using PBKDF2-HMAC-SHA256.
  ///
  /// Production parameters (must match Rails exactly):
  /// - iterations: 600,000 (overridable for tests via the constructor)
  /// - key length: 32 bytes
  /// - digest: SHA-256
  Uint8List deriveKey({required String password, required Uint8List salt}) {
    final pbkdf2 = KeyDerivator('SHA-256/HMAC/PBKDF2');
    pbkdf2.init(Pbkdf2Parameters(salt, _iterations, CryptoConstants.keyLength));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
}
