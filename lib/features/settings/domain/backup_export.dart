import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/vault_recovery_service.dart';
import '../../../core/database/vault_paths.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/auth_state.dart';

/// Builds the current vault's backup archive, or null when the vault is locked
/// or has no config. Gathers the vault key material + all secrets and hands
/// them to [VaultRecoveryService.buildArchive] (which strips per-row AAD to the
/// archive's canonical form). Injected so the settings screen is testable.
final vaultArchiveBuilderProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    final auth = ref.read(authProvider);
    if (auth is! AuthUnlocked) return null;
    final db = ref.read(databaseProvider);
    final config = await db.vaultConfigDao.getByVaultId(auth.vaultId);
    if (config == null) return null;
    final secrets = await db.secretDao.getByVaultId(auth.vaultId);
    return VaultRecoveryService().buildArchive(
      salt: Uint8List.fromList(config.masterKeySalt),
      wrappedMek: Uint8List.fromList(config.encryptedMasterKey),
      secrets: secrets,
      mek: auth.masterEncryptionKey,
    );
  };
});

/// Writes [contents] to a user-chosen `.kbx` path via the native save panel.
/// Returns true on save, false on cancel. Injected boundary — the native panel
/// itself is not exercised by `flutter test`.
typedef BackupFileSaver = Future<bool> Function(String contents);

final backupFileSaverProvider = Provider<BackupFileSaver>((ref) {
  return (contents) async {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final name =
        '${VaultPaths.backupFilePrefix}$epoch${VaultPaths.backupFileSuffix}';
    const group = XTypeGroup(label: 'KeyBox backup', extensions: ['kbx']);
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: [group],
    );
    if (location == null) return false;
    await File(location.path).writeAsString(contents, flush: true);
    return true;
  };
});
