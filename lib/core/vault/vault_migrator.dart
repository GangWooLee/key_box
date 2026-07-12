import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../backup/vault_backup_service.dart';
import '../database/cipher_params.dart';
import '../database/vault_paths.dart';
import '../encryption/master_key_service.dart';
import '../encryption/secret_encryption_service.dart';

/// Outcome of a plaintext→encrypted vault migration attempt.
sealed class MigrationResult {
  const MigrationResult();
}

final class MigrationSuccess extends MigrationResult {
  const MigrationSuccess();
}

enum MigrationFailureReason {
  /// The legacy PDK failed to unwrap the MEK — mistyped password. Nothing
  /// was modified.
  wrongPassword,

  /// The source vault is not in a migratable shape (missing/unreadable
  /// config, or a secret that authenticates under neither AAD form).
  integrityCheckFailed,

  /// The forced pre-migration backup archive could not be produced.
  exportFailed,

  /// The encrypted copy failed verification (row counts, re-encryption, or
  /// the final keyed reopen). The plaintext source is preserved.
  verificationFailed,

  /// Free disk space is confirmed to be below the required headroom.
  diskSpace,
}

final class MigrationFailure extends MigrationResult {
  const MigrationFailure(this.reason);
  final MigrationFailureReason reason;
}

/// How a stored secret ciphertext authenticated during a mixed-AAD read.
enum RecordCipherBinding {
  /// Authenticates under `secretAad(id, recordVersion)` — post-B2 write.
  aadBound,

  /// Authenticates only under the empty AAD — pre-B2 legacy write.
  legacyUnbound,

  /// Authenticates under neither form — corrupted or foreign ciphertext.
  unreadable,
}

/// Internal control-flow signal carrying the failure reason out of the
/// migration steps.
class _MigrationAbort implements Exception {
  const _MigrationAbort(this.reason);
  final MigrationFailureReason reason;
}

/// One-shot plaintext→SQLCipher migration of the vault database.
///
/// Operates on raw `sqlite3` connections (drift's connection is pinned to
/// [VaultPaths.dbFile] and cannot address the temporary copies). Touches no
/// providers or notifiers — boot wiring happens in B4b.
///
/// Crash-safety model (see [migrate] step comments):
/// - The plaintext source is never modified in place; it survives as
///   `.pre-encryption` until the encrypted replacement passes final
///   verification.
/// - [recoverInterrupted] repairs every crash window on the next boot:
///   a missing main with a surviving `.pre-encryption` is rolled back, and
///   `.migrating` debris is deleted.
class VaultMigrator {
  VaultMigrator({
    SecretEncryptionService? encryptionService,
    MasterKeyService? masterKeyService,
    VaultBackupService? backupService,
    Future<Directory> Function()? baseDir,
  }) : _enc = encryptionService ?? SecretEncryptionService(),
       _mks = masterKeyService ?? MasterKeyService(),
       _backup = backupService ?? VaultBackupService(),
       _baseDir = baseDir ?? VaultPaths.supportDir;

  final SecretEncryptionService _enc;
  final MasterKeyService _mks;
  final VaultBackupService _backup;
  final Future<Directory> Function() _baseDir;

  static const _tables = [
    'vaults',
    'vault_configs',
    'folders',
    'secrets',
    'folder_secrets',
    'audit_events',
  ];

  static const _plaintextHeader = 'SQLite format 3\x00';

  /// Whether [file] is a plaintext SQLite database (classic 16-byte magic).
  ///
  /// Encrypted SQLCipher files have an indistinguishable-from-random header,
  /// so this doubles as the "migration needed?" probe. Missing or truncated
  /// files return false.
  static Future<bool> isPlaintextDb(File file) async {
    if (!await file.exists()) return false;
    final raf = await file.open();
    try {
      final header = await raf.read(16);
      if (header.length < 16) return false;
      for (var i = 0; i < 16; i++) {
        if (header[i] != _plaintextHeader.codeUnitAt(i)) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  /// Repairs the on-disk layout after an interrupted migration. Idempotent —
  /// intended to run early on every boot (wired in B4b).
  ///
  /// - main missing + `.pre-encryption` present: the crash hit between the
  ///   two swap renames — roll the plaintext source back.
  /// - `.migrating` present: an incomplete (or already swapped-in) encrypted
  ///   copy — always garbage, delete it with its WAL/SHM.
  ///
  /// The main-present + `.pre-encryption`-present case (crash after the swap
  /// but before final verification) is intentionally left to the boot flow:
  /// whether main is trustworthy is only decidable by a keyed open.
  Future<void> recoverInterrupted() async {
    final dir = (await _baseDir()).path;
    final main = File('$dir/${VaultPaths.dbFileName}');
    final pre = File('$dir/${VaultPaths.dbPreEncryptionFileName}');

    if (!await main.exists() && await pre.exists()) {
      await pre.rename(main.path);
    }

    for (final name in [
      VaultPaths.dbMigratingFileName,
      '${VaultPaths.dbMigratingFileName}-wal',
      '${VaultPaths.dbMigratingFileName}-shm',
    ]) {
      final file = File('$dir/$name');
      if (await file.exists()) await file.delete();
    }
  }

  /// Migrates the plaintext vault at [VaultPaths.dbFileName] into a SQLCipher
  /// database keyed with [dbKey], re-wrapping the MEK under [kek] and
  /// AAD-binding every legacy secret record.
  ///
  /// [legacyPdk] is the raw PDK (pre-key-hierarchy semantics) used by the
  /// plaintext-era vault to wrap the MEK; it gates the migration — a failed
  /// unwrap aborts before any irreversible work.
  ///
  /// The caller owns all three key buffers (it needs [dbKey] to reopen the
  /// vault right after); this method never zeroes its inputs.
  Future<MigrationResult> migrate({
    required Uint8List legacyPdk,
    required Uint8List dbKey,
    required Uint8List kek,
  }) async {
    final dir = (await _baseDir()).path;
    final mainPath = '$dir/${VaultPaths.dbFileName}';
    final migratingPath = '$dir/${VaultPaths.dbMigratingFileName}';
    final prePath = '$dir/${VaultPaths.dbPreEncryptionFileName}';

    Uint8List? mek;
    Uint8List? salt;
    try {
      // Guard: the source must exist and be plaintext — anything else means
      // the caller misjudged the vault state.
      if (!await isPlaintextDb(File(mainPath))) {
        throw const _MigrationAbort(
          MigrationFailureReason.integrityCheckFailed,
        );
      }

      // 1+2. Password gate (legacy raw-PDK unwrap), then make the source
      // self-contained (checkpoint WAL into the main file).
      final config = _unwrapConfigAndCheckpoint(mainPath, legacyPdk);
      mek = config.mek;
      salt = config.salt;
      _deleteIfExists('$mainPath-wal');
      _deleteIfExists('$mainPath-shm');

      // 3. Preflight: the migration briefly holds source + encrypted copy +
      // backup archive, so require ~3x the source size.
      await _ensureDiskHeadroom(dir, File(mainPath).lengthSync());

      // 4. Forced automatic backup (archive v2 — MEK wrapped under the KEK).
      final kekWrappedMek = _mks.wrap(masterKey: mek, wrappingKey: kek);
      final backupPath = _writeBackupArchive(
        dir: dir,
        mainPath: mainPath,
        mek: mek,
        salt: salt,
        kekWrappedMek: kekWrappedMek,
      );

      // 5. Encrypted copy via sqlcipher_export into `.migrating`.
      final sourceCounts = _createEncryptedCopy(mainPath, migratingPath, dbKey);

      // 6. Verify the copy, re-wrap the MEK, AAD-bind legacy records.
      _verifyAndFinalizeCopy(
        migratingPath: migratingPath,
        dbKey: dbKey,
        mek: mek,
        kekWrappedMek: kekWrappedMek,
        sourceCounts: sourceCounts,
      );

      // 7. Atomic swap. A crash between the renames leaves main missing and
      // `.pre-encryption` present — exactly what recoverInterrupted repairs.
      File(mainPath).renameSync(prePath);
      File(migratingPath).renameSync(mainPath);

      // 8. Final verification, then plaintext-remnant cleanup.
      _finalVerifyAndCleanup(
        mainPath: mainPath,
        prePath: prePath,
        backupPath: backupPath,
        dbKey: dbKey,
        kek: kek,
      );
      return const MigrationSuccess();
    } on _MigrationAbort catch (abort) {
      _cleanupAbortedCopy(mainPath, migratingPath);
      return MigrationFailure(abort.reason);
    } finally {
      if (mek != null) _zeroOut(mek);
      if (salt != null) _zeroOut(salt);
    }
  }

  /// Classifies how a stored ciphertext authenticates under [mek]: the
  /// AAD-bound form first (post-B2 writes), then the legacy empty-AAD
  /// fallback. Both failing means the record is unreadable.
  @visibleForTesting
  ({RecordCipherBinding binding, String? plaintext}) classifyRecordCipher({
    required Uint8List encryptedValue,
    required Uint8List iv,
    required Uint8List authTag,
    required Uint8List mek,
    required int secretId,
    required int recordVersion,
  }) {
    final bound = _enc.decrypt(
      encryptedValue: encryptedValue,
      iv: iv,
      authTag: authTag,
      key: mek,
      aad: secretAad(secretId: secretId, recordVersion: recordVersion),
    );
    if (bound != null) {
      return (binding: RecordCipherBinding.aadBound, plaintext: bound);
    }
    final legacy = _enc.decrypt(
      encryptedValue: encryptedValue,
      iv: iv,
      authTag: authTag,
      key: mek,
    );
    if (legacy != null) {
      return (binding: RecordCipherBinding.legacyUnbound, plaintext: legacy);
    }
    return (binding: RecordCipherBinding.unreadable, plaintext: null);
  }

  /// Extracts the Available column (KB) from `df -k` output; null when the
  /// output does not look like a df table.
  @visibleForTesting
  static int? parseDfAvailableKb(String dfOutput) {
    final lines = dfOutput.trim().split('\n');
    if (lines.length < 2) return null;
    final columns = lines[1].split(RegExp(r'\s+'));
    if (columns.length < 4) return null;
    return int.tryParse(columns[3]);
  }

  // ─── migrate steps ───

  ({Uint8List mek, Uint8List salt}) _unwrapConfigAndCheckpoint(
    String mainPath,
    Uint8List legacyPdk,
  ) {
    final db = sqlite.sqlite3.open(mainPath);
    try {
      final sqlite.ResultSet rows;
      try {
        rows = db.select(
          'SELECT master_key_salt, encrypted_master_key '
          'FROM vault_configs LIMIT 1;',
        );
      } on sqlite.SqliteException {
        // No vault_configs table — not a vault database.
        throw const _MigrationAbort(
          MigrationFailureReason.integrityCheckFailed,
        );
      }
      if (rows.isEmpty) {
        throw const _MigrationAbort(
          MigrationFailureReason.integrityCheckFailed,
        );
      }
      final salt = Uint8List.fromList(
        rows.first['master_key_salt'] as List<int>,
      );
      final wrapped = Uint8List.fromList(
        rows.first['encrypted_master_key'] as List<int>,
      );
      // Refusing to start on unwrap failure prevents an irreversible
      // migration keyed off a mistyped password.
      final mek = _mks.unwrap(wrappedKey: wrapped, wrappingKey: legacyPdk);
      if (mek == null) {
        throw const _MigrationAbort(MigrationFailureReason.wrongPassword);
      }
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      return (mek: mek, salt: salt);
    } finally {
      db.dispose();
    }
  }

  Future<void> _ensureDiskHeadroom(String dir, int sourceBytes) async {
    int? availableKb;
    try {
      final result = await Process.run('df', ['-k', dir]);
      if (result.exitCode == 0) {
        availableKb = parseDfAvailableKb(result.stdout as String);
      }
    } catch (_) {
      // Sandbox denial or missing binary — handled by the fail-open below.
    }
    if (availableKb == null) {
      // Fail-open: the source is never destroyed before the swap, so an
      // unavailable preflight is a warning, not a stop.
      if (kDebugMode) {
        debugPrint('[VaultMigrator] disk preflight unavailable — proceeding');
      }
      return;
    }
    if (availableKb * 1024 < 3 * sourceBytes) {
      throw const _MigrationAbort(MigrationFailureReason.diskSpace);
    }
  }

  String _writeBackupArchive({
    required String dir,
    required String mainPath,
    required Uint8List mek,
    required Uint8List salt,
    required Uint8List kekWrappedMek,
  }) {
    final records = _loadRecordsForBackup(mainPath, mek);
    final archive = _backup.exportArchive(
      salt: salt,
      wrappedMek: kekWrappedMek,
      records: records,
      mek: mek,
    );
    if (archive == null) {
      throw const _MigrationAbort(MigrationFailureReason.exportFailed);
    }
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final path =
        '$dir/${VaultPaths.backupFilePrefix}$epoch'
        '${VaultPaths.backupFileSuffix}';
    // Same-directory tmp + rename: APFS rename atomicity, so a crash never
    // leaves a half-written archive posing as a valid backup.
    final tmp = File('$path.tmp');
    tmp.writeAsStringSync(archive, flush: true);
    tmp.renameSync(path);
    return path;
  }

  List<VaultBackupRecord> _loadRecordsForBackup(
    String mainPath,
    Uint8List mek,
  ) {
    final db = sqlite.sqlite3.open(mainPath);
    try {
      final rows = db.select(
        'SELECT id, name, secret_type, service_name, environment, notes, '
        'tags, record_version, encrypted_value, encrypted_value_iv, '
        'encrypted_value_auth_tag FROM secrets;',
      );
      return [for (final row in rows) _toBackupRecord(row, mek)];
    } finally {
      db.dispose();
    }
  }

  VaultBackupRecord _toBackupRecord(sqlite.Row row, Uint8List mek) {
    final result = classifyRecordCipher(
      encryptedValue: Uint8List.fromList(row['encrypted_value'] as List<int>),
      iv: Uint8List.fromList(row['encrypted_value_iv'] as List<int>),
      authTag: Uint8List.fromList(row['encrypted_value_auth_tag'] as List<int>),
      mek: mek,
      secretId: row['id'] as int,
      recordVersion: row['record_version'] as int,
    );
    if (result.binding == RecordCipherBinding.unreadable) {
      throw const _MigrationAbort(MigrationFailureReason.integrityCheckFailed);
    }
    // Canonical archive form: empty-AAD under the MEK with a fresh IV (see
    // VaultBackupService). The plaintext String cannot be zeroed — Dart
    // strings are immutable (same accepted gap as TODO(PR-B/F5)).
    return VaultBackupRecord(
      name: row['name'] as String,
      secretType: row['secret_type'] as String,
      serviceName: row['service_name'] as String?,
      environment: row['environment'] as String?,
      notes: row['notes'] as String?,
      tags: row['tags'] as String?,
      encrypted: _enc.encrypt(value: result.plaintext!, key: mek),
    );
  }

  Map<String, int> _createEncryptedCopy(
    String mainPath,
    String migratingPath,
    Uint8List dbKey,
  ) {
    // A stale target from a previously crashed attempt would corrupt the
    // export — start clean.
    _deleteIfExists(migratingPath);
    _deleteIfExists('$migratingPath-wal');
    _deleteIfExists('$migratingPath-shm');

    final db = sqlite.sqlite3.open(mainPath);
    try {
      final counts = {
        for (final table in _tables)
          table:
              db.select('SELECT COUNT(*) AS c FROM $table;').first['c'] as int,
      };
      final hexKey = sqlcipherRawKeyHex(dbKey);
      db.execute("ATTACH '$migratingPath' AS encrypted KEY \"x'$hexKey'\";");
      // Hard-pin the cipher parameters on the target schema BEFORE any page
      // is written (shared contract with database.dart).
      for (final pragma in cipherHardPinPragmas(schema: 'encrypted')) {
        db.execute(pragma);
      }
      db.select("SELECT sqlcipher_export('encrypted');");
      // sqlcipher_export does NOT copy user_version. Without this, drift
      // would see schema 0 and re-run onCreate over the migrated data.
      final userVersion =
          db.select('PRAGMA user_version;').first.values.first as int;
      db.execute('PRAGMA encrypted.user_version = $userVersion;');
      db.execute('DETACH encrypted;');
      return counts;
    } finally {
      db.dispose();
    }
  }

  void _verifyAndFinalizeCopy({
    required String migratingPath,
    required Uint8List dbKey,
    required Uint8List mek,
    required Uint8List kekWrappedMek,
    required Map<String, int> sourceCounts,
  }) {
    final db = _openKeyed(migratingPath, dbKey);
    try {
      for (final entry in sourceCounts.entries) {
        final copied =
            db.select('SELECT COUNT(*) AS c FROM ${entry.key};').first['c']
                as int;
        if (copied != entry.value) {
          throw const _MigrationAbort(
            MigrationFailureReason.verificationFailed,
          );
        }
      }
      // Key hierarchy flip: the MEK is now wrapped under the HKDF KEK, never
      // the raw PDK.
      db.execute('UPDATE vault_configs SET encrypted_master_key = ?;', [
        kekWrappedMek,
      ]);
      _rebindSecretsAad(db, mek);
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    } finally {
      db.dispose();
    }
    _deleteIfExists('$migratingPath-wal');
    _deleteIfExists('$migratingPath-shm');
  }

  void _rebindSecretsAad(sqlite.Database db, Uint8List mek) {
    final rows = db.select(
      'SELECT id, record_version, encrypted_value, encrypted_value_iv, '
      'encrypted_value_auth_tag FROM secrets;',
    );
    for (final row in rows) {
      final id = row['id'] as int;
      final version = row['record_version'] as int;
      final result = classifyRecordCipher(
        encryptedValue: Uint8List.fromList(row['encrypted_value'] as List<int>),
        iv: Uint8List.fromList(row['encrypted_value_iv'] as List<int>),
        authTag: Uint8List.fromList(
          row['encrypted_value_auth_tag'] as List<int>,
        ),
        mek: mek,
        secretId: id,
        recordVersion: version,
      );
      switch (result.binding) {
        case RecordCipherBinding.aadBound:
          break; // Already bound — leave untouched.
        case RecordCipherBinding.legacyUnbound:
          // Bind to (id, recordVersion). The version is preserved: binding
          // is not a value rotation.
          final rebound = _enc.encrypt(
            value: result.plaintext!,
            key: mek,
            aad: secretAad(secretId: id, recordVersion: version),
          );
          db.execute(
            'UPDATE secrets SET encrypted_value = ?, '
            'encrypted_value_iv = ?, encrypted_value_auth_tag = ? '
            'WHERE id = ?;',
            [rebound.encryptedValue, rebound.iv, rebound.authTag, id],
          );
        case RecordCipherBinding.unreadable:
          throw const _MigrationAbort(
            MigrationFailureReason.verificationFailed,
          );
      }
    }
  }

  void _finalVerifyAndCleanup({
    required String mainPath,
    required String prePath,
    required String backupPath,
    required Uint8List dbKey,
    required Uint8List kek,
  }) {
    if (_finalVerifyPasses(mainPath, dbKey, kek)) {
      // Success: remove every plaintext remnant. `.pre-encryption` is the
      // whole plaintext vault, and the .kbx archive carries plaintext
      // metadata (names, services, notes) — keeping either after a
      // successful migration would defeat the at-rest encryption goal.
      _deleteIfExists(prePath);
      _deleteIfExists(backupPath);
      return;
    }
    // The swapped-in main failed verification: drop it and roll the
    // plaintext source back immediately (the same repair recoverInterrupted
    // would perform on the next boot).
    _deleteIfExists(mainPath);
    final pre = File(prePath);
    if (pre.existsSync()) pre.renameSync(mainPath);
    throw const _MigrationAbort(MigrationFailureReason.verificationFailed);
  }

  bool _finalVerifyPasses(String mainPath, Uint8List dbKey, Uint8List kek) {
    Uint8List? verifiedMek;
    try {
      final db = _openKeyed(mainPath, dbKey);
      try {
        final config = db.select(
          'SELECT encrypted_master_key FROM vault_configs LIMIT 1;',
        );
        if (config.isEmpty) return false;
        verifiedMek = _mks.unwrap(
          wrappedKey: Uint8List.fromList(
            config.first['encrypted_master_key'] as List<int>,
          ),
          wrappingKey: kek,
        );
        if (verifiedMek == null) return false;
        return _firstSecretDecrypts(db, verifiedMek);
      } finally {
        db.dispose();
      }
    } on sqlite.SqliteException {
      return false;
    } finally {
      if (verifiedMek != null) _zeroOut(verifiedMek);
    }
  }

  bool _firstSecretDecrypts(sqlite.Database db, Uint8List mek) {
    final secrets = db.select(
      'SELECT id, record_version, encrypted_value, encrypted_value_iv, '
      'encrypted_value_auth_tag FROM secrets LIMIT 1;',
    );
    if (secrets.isEmpty) return true; // Empty vault — nothing to prove.
    final row = secrets.first;
    final plaintext = _enc.decrypt(
      encryptedValue: Uint8List.fromList(row['encrypted_value'] as List<int>),
      iv: Uint8List.fromList(row['encrypted_value_iv'] as List<int>),
      authTag: Uint8List.fromList(row['encrypted_value_auth_tag'] as List<int>),
      key: mek,
      aad: secretAad(
        secretId: row['id'] as int,
        recordVersion: row['record_version'] as int,
      ),
    );
    return plaintext != null;
  }

  // ─── helpers ───

  sqlite.Database _openKeyed(String path, Uint8List dbKey) {
    final db = sqlite.sqlite3.open(path);
    db.execute("PRAGMA key = \"x'${sqlcipherRawKeyHex(dbKey)}'\";");
    for (final pragma in cipherHardPinPragmas()) {
      db.execute(pragma);
    }
    return db;
  }

  /// After a pre-swap abort the main file is still in place; a partially
  /// written `.migrating` copy is garbage and must not survive.
  void _cleanupAbortedCopy(String mainPath, String migratingPath) {
    if (!File(mainPath).existsSync()) return;
    _deleteIfExists(migratingPath);
    _deleteIfExists('$migratingPath-wal');
    _deleteIfExists('$migratingPath-shm');
  }

  void _deleteIfExists(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  void _zeroOut(Uint8List bytes) => bytes.fillRange(0, bytes.length, 0);
}
