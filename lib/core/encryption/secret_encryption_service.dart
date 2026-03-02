import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../constants/crypto_constants.dart';
import 'secure_random.dart';

/// Result of encrypting a secret value.
/// Each field stored separately in the database (matching Rails schema).
class EncryptedSecret {
  const EncryptedSecret({
    required this.encryptedValue,
    required this.iv,
    required this.authTag,
  });

  final Uint8List encryptedValue;
  final Uint8List iv;
  final Uint8List authTag;
}

/// AES-256-GCM encryption/decryption for individual secret values.
/// Must produce identical output to Rails Encryption::SecretEncryptionService.
class SecretEncryptionService {
  /// Encrypt a plaintext value using AES-256-GCM.
  ///
  /// Returns separate encrypted_value, iv, and auth_tag (matching Rails columns).
  EncryptedSecret encrypt({
    required String value,
    required Uint8List key,
  }) {
    final iv = secureRandomBytes(CryptoConstants.ivLength);
    final plaintext = Uint8List.fromList(utf8.encode(value));

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(
        KeyParameter(key),
        CryptoConstants.authTagLength * 8,
        iv,
        Uint8List(0), // empty AAD
      ),
    );

    final output = Uint8List(cipher.getOutputSize(plaintext.length));
    var offset = cipher.processBytes(plaintext, 0, plaintext.length, output, 0);
    offset += cipher.doFinal(output, offset);

    // Total output = ciphertext + authTag
    final totalOutput = output.sublist(0, offset);
    final ciphertextLen = totalOutput.length - CryptoConstants.authTagLength;
    final ciphertext = totalOutput.sublist(0, ciphertextLen);
    final authTag = totalOutput.sublist(ciphertextLen);

    return EncryptedSecret(
      encryptedValue: ciphertext,
      iv: iv,
      authTag: authTag,
    );
  }

  /// Decrypt an encrypted value using AES-256-GCM.
  ///
  /// Returns plaintext string on success, or null on authentication failure.
  String? decrypt({
    required Uint8List encryptedValue,
    required Uint8List iv,
    required Uint8List authTag,
    required Uint8List key,
  }) {
    try {
      // GCM expects ciphertext + authTag concatenated
      final gcmInput = Uint8List(encryptedValue.length + authTag.length);
      gcmInput.setRange(0, encryptedValue.length, encryptedValue);
      gcmInput.setRange(encryptedValue.length, gcmInput.length, authTag);

      final cipher = GCMBlockCipher(AESEngine());
      cipher.init(
        false,
        AEADParameters(
          KeyParameter(key),
          CryptoConstants.authTagLength * 8,
          iv,
          Uint8List(0),
        ),
      );

      final output = Uint8List(cipher.getOutputSize(gcmInput.length));
      var offset = cipher.processBytes(gcmInput, 0, gcmInput.length, output, 0);
      offset += cipher.doFinal(output, offset);

      return utf8.decode(output.sublist(0, offset));
    } catch (_) {
      return null;
    }
  }
}
