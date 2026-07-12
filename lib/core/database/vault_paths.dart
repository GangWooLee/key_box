import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Central authority for vault file locations (DB + sidecar).
///
/// Every component that needs the on-disk vault paths (database connection,
/// sidecar store, reset flow) resolves them here so the directory and file
/// names live in exactly one place.
abstract final class VaultPaths {
  static const dbFileName = 'key_box.db';
  static const dbWalFileName = 'key_box.db-wal';
  static const dbShmFileName = 'key_box.db-shm';
  static const sidecarFileName = 'key_box.vault.json';

  /// Staged rotation salt (changePassword journal): holds the NEW salt from
  /// staging until the DB rewrap+rekey commits, then is promoted onto
  /// [sidecarFileName]. Its presence at unlock signals an interrupted
  /// rotation to resume.
  static const sidecarStagedFileName = 'key_box.vault.json.new';

  // Plaintext→encrypted migration artifacts (VaultMigrator).
  /// In-flight encrypted copy — incomplete or already swapped in, so always
  /// safe to delete during interrupted-migration recovery.
  static const dbMigratingFileName = 'key_box.db.migrating';

  /// Plaintext source parked during the atomic swap — the rollback anchor
  /// until final verification passes.
  static const dbPreEncryptionFileName = 'key_box.db.pre-encryption';

  /// Automatic pre-migration backup archive:
  /// `key_box.backup-<epochSeconds>.kbx`.
  static const backupFilePrefix = 'key_box.backup-';
  static const backupFileSuffix = '.kbx';

  /// Injectable for tests; defaults to [getApplicationSupportDirectory].
  static Future<Directory> Function() supportDir = _defaultSupportDir;

  static Future<Directory> _defaultSupportDir() =>
      getApplicationSupportDirectory();

  /// Whether the plaintext database file exists on disk.
  static Future<bool> dbFileExists() async => (await dbFile()).exists();

  /// Deletes the database and its WAL/SHM sidecars. Idempotent — only the
  /// files that exist are removed.
  static Future<void> deleteDatabaseFiles() async {
    final dir = await supportDir();
    for (final name in const [dbFileName, dbWalFileName, dbShmFileName]) {
      final file = File('${dir.path}/$name');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// The database file handle under the support directory.
  static Future<File> dbFile() async =>
      File('${(await supportDir()).path}/$dbFileName');

  /// The salt sidecar file handle under the support directory.
  static Future<File> sidecarFile() async =>
      File('${(await supportDir()).path}/$sidecarFileName');
}
