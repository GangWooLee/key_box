import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../constants/crypto_constants.dart';
import 'secure_random.dart';

/// AES-256-GCM wrap/unwrap for Master Encryption Key (MEK).
/// Must produce identical byte layout to Rails Encryption::MasterKeyService.
///
/// Wrapped MEK byte layout:
/// ```
/// [IV (12 bytes)] [AuthTag (16 bytes)] [Ciphertext (32 bytes)]
/// Total: 60 bytes
/// ```
class MasterKeyService {
  /// Generate a cryptographically secure random Master Encryption Key.
  Uint8List generateMasterKey() {
    return secureRandomBytes(CryptoConstants.mekLength);
  }

  /// Wrap (encrypt) a master key using AES-256-GCM.
  ///
  /// Returns: IV(12) + AuthTag(16) + Ciphertext(32) = 60 bytes
  Uint8List wrap({
    required Uint8List masterKey,
    required Uint8List wrappingKey,
  }) {
    final iv = secureRandomBytes(CryptoConstants.ivLength);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true, // encrypt
      AEADParameters(
        KeyParameter(wrappingKey),
        CryptoConstants.authTagLength * 8, // tag length in bits
        iv,
        Uint8List(0), // empty AAD (matches Rails auth_data = "")
      ),
    );

    // GCM output = ciphertext + authTag appended
    final output = Uint8List(cipher.getOutputSize(masterKey.length));
    var offset = cipher.processBytes(masterKey, 0, masterKey.length, output, 0);
    offset += cipher.doFinal(output, offset);

    // Total output = ciphertext(same as input) + authTag(16)
    // Split based on actual data: ciphertext = first (total - tagLen), tag = last tagLen
    final totalOutput = output.sublist(0, offset);
    final ciphertextLen = totalOutput.length - CryptoConstants.authTagLength;
    final ciphertext = totalOutput.sublist(0, ciphertextLen);
    final authTag = totalOutput.sublist(ciphertextLen);

    // Rails layout: IV + AuthTag + Ciphertext
    final result = Uint8List(
      CryptoConstants.ivLength + CryptoConstants.authTagLength + ciphertextLen,
    );
    result.setRange(0, CryptoConstants.ivLength, iv);
    result.setRange(
      CryptoConstants.ivLength,
      CryptoConstants.ivLength + CryptoConstants.authTagLength,
      authTag,
    );
    result.setRange(
      CryptoConstants.ivLength + CryptoConstants.authTagLength,
      result.length,
      ciphertext,
    );
    return result;
  }

  /// Unwrap (decrypt) a master key using AES-256-GCM.
  ///
  /// Returns the MEK on success, or null on authentication failure.
  Uint8List? unwrap({
    required Uint8List wrappedKey,
    required Uint8List wrappingKey,
  }) {
    if (wrappedKey.length != CryptoConstants.wrappedMekLength) return null;

    try {
      // Parse Rails layout: IV(12) + AuthTag(16) + Ciphertext(32)
      final iv = wrappedKey.sublist(0, CryptoConstants.ivLength);
      final authTag = wrappedKey.sublist(
        CryptoConstants.ivLength,
        CryptoConstants.ivLength + CryptoConstants.authTagLength,
      );
      final ciphertext = wrappedKey.sublist(
        CryptoConstants.ivLength + CryptoConstants.authTagLength,
      );

      // GCM expects ciphertext + authTag concatenated for decryption
      final gcmInput = Uint8List(ciphertext.length + authTag.length);
      gcmInput.setRange(0, ciphertext.length, ciphertext);
      gcmInput.setRange(ciphertext.length, gcmInput.length, authTag);

      final cipher = GCMBlockCipher(AESEngine());
      cipher.init(
        false, // decrypt
        AEADParameters(
          KeyParameter(wrappingKey),
          CryptoConstants.authTagLength * 8,
          iv,
          Uint8List(0), // empty AAD
        ),
      );

      final output = Uint8List(cipher.getOutputSize(gcmInput.length));
      var offset = cipher.processBytes(gcmInput, 0, gcmInput.length, output, 0);
      offset += cipher.doFinal(output, offset);

      return output.sublist(0, offset);
    } catch (_) {
      // Authentication failure → return null (matches Rails rescue nil)
      return null;
    }
  }
}
