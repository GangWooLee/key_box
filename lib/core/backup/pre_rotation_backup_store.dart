import 'dart:io';

import '../database/vault_paths.dart';

/// Persists the pre-rotation vault snapshot — the recovery net for a password
/// change (see [VaultPaths.preRotationBackupFileName]). [write] runs before any
/// rewrap/rekey; [delete] once the rotation commits. Injectable so
/// [AuthNotifier] stays testable without touching the disk.
abstract interface class PreRotationBackupStore {
  /// Persist [archive] as the pre-rotation snapshot, overwriting any prior one.
  Future<void> write(String archive);

  /// Remove the snapshot if present. Idempotent.
  Future<void> delete();
}

/// Default store: a single `.kbx` file under the vault support directory,
/// written via same-directory tmp + atomic rename (APFS) so a crash never
/// leaves a half-written archive posing as a valid backup.
class FilePreRotationBackupStore implements PreRotationBackupStore {
  const FilePreRotationBackupStore();

  Future<File> _file() async {
    final dir = await VaultPaths.supportDir();
    return File('${dir.path}/${VaultPaths.preRotationBackupFileName}');
  }

  @override
  Future<void> write(String archive) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(archive, flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}

/// In-memory store for tests: exposes the last-written [archive] and whether it
/// was cleared, so rotation tests can assert the net was secured/dropped.
class InMemoryPreRotationBackupStore implements PreRotationBackupStore {
  /// The current snapshot (null once [delete] clears it).
  String? archive;

  /// The last archive ever written, retained across [delete] so tests can
  /// still restore-round-trip it after the rotation drops the net.
  String? lastWritten;
  int writeCount = 0;
  int deleteCount = 0;

  @override
  Future<void> write(String archive) async {
    this.archive = archive;
    lastWritten = archive;
    writeCount++;
  }

  @override
  Future<void> delete() async {
    archive = null;
    deleteCount++;
  }
}
