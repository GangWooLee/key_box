import 'dart:typed_data';

import '../encryption/secret_encryption_service.dart';

/// Backup / recovery net for the vault (PR-A).
///
/// Provides verifiable integrity checks and (later) export/import round-trips
/// so a user can trust their data survives migration and disk failure.
class VaultBackupService {
  VaultBackupService({SecretEncryptionService? encryptionService})
    : _enc = encryptionService ?? SecretEncryptionService();

  final SecretEncryptionService _enc;

  /// Verifies that every [records] entry decrypts and authenticates under [mek].
  ///
  /// Returns true only if all records pass GCM authentication. A single
  /// corrupted record (tampered ciphertext, IV, or auth tag) or the wrong key
  /// returns false — [SecretEncryptionService.decrypt] returns null on any
  /// GCM authentication failure.
  bool verifyIntegrity(List<EncryptedSecret> records, Uint8List mek) {
    for (final record in records) {
      final plaintext = _enc.decrypt(
        encryptedValue: record.encryptedValue,
        iv: record.iv,
        authTag: record.authTag,
        key: mek,
      );
      if (plaintext == null) return false;
    }
    return true;
  }
}
