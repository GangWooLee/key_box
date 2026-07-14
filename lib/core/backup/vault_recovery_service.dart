import 'dart:typed_data';

import '../database/database.dart';
import '../encryption/secret_encryption_service.dart';
import 'vault_backup_service.dart';

/// A secret recovered from an archive, carrying plaintext + metadata ready to
/// insert into a fresh vault. The caller re-binds per-row AAD once the new row
/// id is known (see the AAD-asymmetry note on [VaultBackupService]).
class RestoredSecret {
  const RestoredSecret({
    required this.name,
    required this.secretType,
    this.serviceName,
    this.environment,
    this.notes,
    this.tags,
    required this.value,
  });

  final String name;
  final String secretType;
  final String? serviceName;
  final String? environment;
  final String? notes;
  final String? tags;

  /// Decrypted plaintext.
  final String value;
}

/// Orchestrates vault backup **export** and **restore** across the AAD
/// asymmetry.
///
/// Stored secrets are AAD-bound (`secretAad(id, version)`); archive records are
/// empty-AAD under the MEK ([VaultBackupService]). Export strips the binding
/// (decrypt-with-AAD → re-encrypt empty); restore recovers plaintext so the
/// caller can re-bind AAD when inserting into the new vault.
///
/// Pure orchestration: no DB, no file I/O. The file pick/save and the fresh-
/// vault insert are thin adapters wired in the UI layer (and verified in
/// integration_test, since `flutter test` does not exercise SQLCipher).
class VaultRecoveryService {
  VaultRecoveryService({
    SecretEncryptionService? encryptionService,
    VaultBackupService? backupService,
  }) : _enc = encryptionService ?? SecretEncryptionService(),
       _backup = backupService ?? VaultBackupService();

  final SecretEncryptionService _enc;
  final VaultBackupService _backup;

  /// Builds a portable archive from all stored [secrets] + the vault's key
  /// material ([salt], [wrappedMek]). Returns null if any secret is unreadable
  /// under [mek] — a lossy backup is never produced ([VaultBackupService.
  /// exportArchive] self-guards on the same invariant).
  String? buildArchive({
    required Uint8List salt,
    required Uint8List wrappedMek,
    required List<Secret> secrets,
    required Uint8List mek,
  }) {
    final records = <VaultBackupRecord>[];
    for (final s in secrets) {
      final plaintext = _readStored(s, mek);
      if (plaintext == null) return null;
      records.add(
        VaultBackupRecord(
          name: s.name,
          secretType: s.secretType,
          serviceName: s.serviceName,
          environment: s.environment,
          notes: s.notes,
          tags: s.tags,
          // Canonical archive form: empty-AAD under the MEK with a fresh IV.
          encrypted: _enc.encrypt(value: plaintext, key: mek),
        ),
      );
    }
    return _backup.exportArchive(
      salt: salt,
      wrappedMek: wrappedMek,
      records: records,
      mek: mek,
    );
  }

  /// Parses + verifies [archive] and recovers each secret's plaintext under a
  /// fresh [destinationMek], ready to insert into a new vault. Returns null on
  /// any failure (malformed archive, wrong [password], or a corrupt record).
  ///
  /// Phase 2 (the restore screen) refines the null into a corrupt-vs-wrong-
  /// password distinction for the clay-toned reason line.
  List<RestoredSecret>? restore({
    required String archive,
    required String password,
    required Uint8List destinationMek,
  }) {
    final records = _backup.importArchive(
      archive: archive,
      password: password,
      destinationMek: destinationMek,
    );
    if (records == null) return null;

    final restored = <RestoredSecret>[];
    for (final r in records) {
      // importArchive re-encrypted each record empty-AAD under destinationMek.
      final plaintext = _enc.decrypt(
        encryptedValue: r.encrypted.encryptedValue,
        iv: r.encrypted.iv,
        authTag: r.encrypted.authTag,
        key: destinationMek,
      );
      if (plaintext == null) return null;
      restored.add(
        RestoredSecret(
          name: r.name,
          secretType: r.secretType,
          serviceName: r.serviceName,
          environment: r.environment,
          notes: r.notes,
          tags: r.tags,
          value: plaintext,
        ),
      );
    }
    return restored;
  }

  /// AAD-aware read of a stored secret: the AAD-bound form first (post-B2
  /// writes), then the legacy empty-AAD fallback (pre-B2 rows). Null if neither
  /// authenticates under [mek].
  ///
  /// Twin of `VaultMigrator.classifyRecordCipher` — keep in sync; extract to a
  /// shared helper if a third reader of stored ciphertext appears.
  String? _readStored(Secret s, Uint8List mek) {
    final bound = _enc.decrypt(
      encryptedValue: s.encryptedValue,
      iv: s.encryptedValueIv,
      authTag: s.encryptedValueAuthTag,
      key: mek,
      aad: secretAad(secretId: s.id, recordVersion: s.recordVersion),
    );
    if (bound != null) return bound;
    return _enc.decrypt(
      encryptedValue: s.encryptedValue,
      iv: s.encryptedValueIv,
      authTag: s.encryptedValueAuthTag,
      key: mek,
    );
  }
}
