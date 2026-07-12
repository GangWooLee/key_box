import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/vault_paths.dart';
import '../../../core/encryption/key_derivation_service.dart';
import '../../../core/encryption/key_hierarchy_service.dart';
import '../../../core/encryption/master_key_service.dart';
import '../../../core/constants/crypto_constants.dart';
import '../../../core/vault/sidecar_store.dart';
import '../../../core/vault/vault_migrator.dart';
import 'auth_state.dart';

final sidecarStoreProvider = Provider<SidecarStore>(
  (ref) => FileSidecarStore(),
);

/// Holds the database once the vault flow opens it. Null until then.
final databaseHolderProvider = StateProvider<AppDatabase?>((ref) {
  ref.onDispose(() => ref.controller.state?.close());
  return null;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = ref.watch(databaseHolderProvider);
  // watch: the moment the holder is set this recomputes, so the pre-unlock
  // StateError is NEVER cached. Do not "simplify" to a plain field.
  if (db == null) {
    throw StateError('databaseProvider read before vault unlock');
  }
  return db;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier.lazy(
    sidecar: ref.read(sidecarStoreProvider),
    dbFileExists: VaultPaths.dbFileExists,
    openDatabase: ({Uint8List? dbKey}) {
      // Closure keeps Ref out of the notifier. Reuse is key-blind by
      // design: lock() closes and clears the holder, so an existing
      // instance can only come from earlier in the SAME unlocked session —
      // never a stale connection under a different key.
      final existing = ref.read(databaseHolderProvider);
      if (existing != null) return existing;
      final db = AppDatabase(dbKey: dbKey);
      ref.read(databaseHolderProvider.notifier).state = db;
      return db;
    },
    releaseDatabase: () async {
      // Reset closes the DB; the holder must drop the stale instance or the
      // openDatabase closure would hand it back to the next setup.
      final db = ref.read(databaseHolderProvider);
      if (db != null) {
        await db.close();
        ref.read(databaseHolderProvider.notifier).state = null;
      }
    },
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  /// Backward-compatible constructor: eager DB, in-memory sidecar by default.
  ///
  /// Kept generative — FakeAuthNotifier and existing tests construct/extend
  /// through this. DB-file existence is judged by `vaultConfigDao.exists()`,
  /// which maps the legacy scenarios onto the boot matrix naturally.
  AuthNotifier(AppDatabase db, {SidecarStore? sidecar})
    : _db = db,
      _sidecar = sidecar ?? InMemorySidecarStore(),
      _openDatabase = null,
      _dbFileExists = null,
      _releaseDatabase = null,
      _migrator = VaultMigrator(),
      super(const AuthInitial());

  /// Production constructor: zero IO until needed. The database is opened
  /// lazily via [openDatabase] only when the boot matrix requires it —
  /// keyed (SQLCipher) when a [dbKey] is passed, plaintext otherwise.
  /// [releaseDatabase] closes the shared instance AND clears its external
  /// registration (the Riverpod holder) — reset uses it so a later setup
  /// cannot receive a closed database. [migrator] is injectable for tests.
  AuthNotifier.lazy({
    required SidecarStore sidecar,
    required AppDatabase Function({Uint8List? dbKey}) openDatabase,
    required Future<bool> Function() dbFileExists,
    Future<void> Function()? releaseDatabase,
    VaultMigrator? migrator,
  }) : _db = null,
       _sidecar = sidecar,
       _openDatabase = openDatabase,
       _dbFileExists = dbFileExists,
       _releaseDatabase = releaseDatabase,
       _migrator = migrator ?? VaultMigrator(),
       super(const AuthInitial());

  AppDatabase? _db;
  final SidecarStore _sidecar;
  final AppDatabase Function({Uint8List? dbKey})? _openDatabase;
  final Future<bool> Function()? _dbFileExists;
  final Future<void> Function()? _releaseDatabase;
  final VaultMigrator _migrator;
  final _kds = KeyDerivationService();
  final _mks = MasterKeyService();
  final _keyHierarchy = KeyHierarchyService();

  AppDatabase _ensureDb({Uint8List? dbKey}) =>
      _db ??= _openDatabase!(dbKey: dbKey);

  /// Closes the shared connection and clears every registration (field +
  /// external holder). A close failure must never mask the caller's own
  /// error handling, so it is logged and swallowed.
  Future<void> _releaseDb() async {
    try {
      if (_releaseDatabase != null) {
        await _releaseDatabase();
      } else {
        await _db?.close();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] database release failed: $e');
    }
    _db = null;
  }

  /// Boot matrix: decide the initial state from sidecar + DB-file presence.
  ///
  /// | sidecar   | db file               | state                            |
  /// |-----------|-----------------------|----------------------------------|
  /// | missing   | absent                | FirstRun                         |
  /// | found     | present               | Locked                           |
  /// | missing   | present, plaintext    | heal salt into sidecar, Locked   |
  /// | missing   | present, encrypted    | VaultError(sidecarMissing)       |
  /// | missing   | plaintext, no config  | FirstRun (setup crash debris)    |
  /// | found     | absent                | VaultError(vaultFileMissing)     |
  /// | corrupted | —                     | VaultError(sidecarCorrupted)     |
  Future<void> initialize() async {
    // Re-entry guard: a second call (router refresh, timer) must not stomp
    // an already-resolved state.
    if (state is! AuthInitial) return;

    if (_openDatabase != null) {
      // Interrupted-migration repair (idempotent): roll a parked
      // .pre-encryption source back if the swap crashed, drop .migrating
      // debris. Must run before anything touches the vault files.
      await _migrator.recoverInterrupted();
    }

    final sidecarResult = await _sidecar.read();
    final dbExists = _dbFileExists != null
        ? await _dbFileExists()
        : await _db!.vaultConfigDao.exists();

    switch (sidecarResult) {
      case SidecarCorrupted():
        state = const AuthVaultError(reason: VaultErrorReason.sidecarCorrupted);
      case SidecarFound():
        // A sidecar without its DB is a data-loss alarm, never a silent
        // first run.
        state = dbExists
            ? const AuthLocked()
            : const AuthVaultError(reason: VaultErrorReason.vaultFileMissing);
      case SidecarMissing():
        if (!dbExists) {
          state = const AuthFirstRun();
        } else if (_openDatabase == null) {
          // Backward-compat path (in-memory DB): always readable.
          await _healFromLegacyDb();
        } else if (await VaultMigrator.isPlaintextDb(
          await VaultPaths.dbFile(),
        )) {
          // Legacy plaintext vault: the salt is readable from the DB.
          await _healFromLegacyDb();
        } else {
          // Encrypted DB without its sidecar: the KDF salt is gone and the
          // DB cannot be read without it — no self-heal exists. Backup
          // restore (or reset) is the only exit.
          state = const AuthVaultError(reason: VaultErrorReason.sidecarMissing);
        }
    }
  }

  /// Legacy self-heal: a plaintext DB predating the sidecar carries the salt
  /// in vault_configs — copy it out so subsequent boots are sidecar-first.
  Future<void> _healFromLegacyDb() async {
    final db = _ensureDb();
    final vault = await db.vaultDao.getFirst();
    final config = vault == null
        ? null
        : await db.vaultConfigDao.getByVaultId(vault.id);

    if (config == null) {
      // DB file exists but setup never committed (crash debris) — safe to
      // treat as first run.
      state = const AuthFirstRun();
      return;
    }

    final salt = Uint8List.fromList(config.masterKeySalt);
    if (salt.length != CryptoConstants.saltLength) {
      state = const AuthVaultError(reason: VaultErrorReason.configMissing);
      return;
    }
    try {
      await _sidecar.write(salt);
    } catch (e) {
      // Non-fatal: the salt is still in the DB, the next boot heals again.
      if (kDebugMode) debugPrint('[Auth:heal] sidecar write failed: $e');
    }
    state = const AuthLocked();
  }

  /// First-time setup: derive the key hierarchy, open the database keyed
  /// (encrypted from birth on the lazy path), and wrap the MEK under the
  /// HKDF KEK — never the raw PDK.
  Future<String?> setup({
    required String password,
    required String confirmation,
  }) async {
    // Validate
    if (password != confirmation) return 'Passwords do not match';
    if (password.length < CryptoConstants.minPasswordLength) {
      return 'Password must be at least ${CryptoConstants.minPasswordLength} characters';
    }

    // Generate cryptographic materials.
    final salt = _kds.generateSalt();
    final pdk = _kds.deriveKey(password: password, salt: salt);
    // dbKey is deliberately NOT zeroed: the keyed connection's setup
    // callback re-executes PRAGMA key from it for the connection lifetime.
    final dbKey = _keyHierarchy.deriveDbKey(pdk);
    final kek = _keyHierarchy.deriveKek(pdk);
    final mek = _mks.generateMasterKey();
    final wrappedMek = _mks.wrap(masterKey: mek, wrappingKey: kek);

    try {
      // Idempotency guard: a second setup over a committed vault would
      // orphan the existing MEK.
      if (await _ensureDb(dbKey: dbKey).vaultConfigDao.exists()) {
        _zeroOut(mek);
        return 'Vault already exists';
      }

      if (kDebugMode) {
        debugPrint(
          '[Auth:setup] salt(${salt.length}B) wrappedMek(${wrappedMek.length}B)',
        );
      }

      // Create vault + config + default folder atomically.
      final db = _ensureDb(dbKey: dbKey);
      late int vaultId;
      await db.transaction(() async {
        final vault = await db.vaultDao.create(name: 'Personal');
        vaultId = vault.id;
        await db.vaultConfigDao.create(
          vaultId: vault.id,
          masterKeySalt: salt,
          encryptedMasterKey: wrappedMek,
        );
        await db.folderDao.create(
          vaultId: vault.id,
          name: 'General',
          icon: 'folder',
          position: 0,
        );
        await db.auditEventDao.create(vaultId: vault.id, action: 'vault.setup');
      });

      if (kDebugMode) debugPrint('[Auth:setup] vault $vaultId created');

      // Sidecar write AFTER the commit: a crash in between leaves the
      // healable missing-sidecar/db-present cell. A write failure is
      // non-fatal — the salt is committed in the DB and the next boot heals.
      try {
        await _sidecar.write(salt);
      } catch (e) {
        if (kDebugMode) debugPrint('[Auth:setup] sidecar write failed: $e');
      }

      // Transition to unlocked (first setup → onboarding)
      state = AuthUnlocked(
        masterEncryptionKey: mek,
        vaultId: vaultId,
        isFirstSetup: true,
      );
      return null; // success
    } finally {
      _zeroOut(pdk);
      _zeroOut(kek);
      _zeroOut(salt);
      _zeroOut(wrappedMek);
    }
  }

  /// Unlock the vault with [password].
  ///
  /// Lazy (production) path — password verification IS the keyed database
  /// open: SQLCipher's per-page HMAC rejects every read under a wrong key
  /// with SQLITE_NOTADB ("file is not a database"). This is by design
  /// indistinguishable from real file corruption; we accept reporting
  /// corruption as a wrong password (설계 확정). A legacy plaintext vault is
  /// migrated in place before the keyed open.
  Future<String?> unlock({required String password}) async {
    if (_openDatabase == null) {
      return _unlockCompat(password: password);
    }

    // Sidecar is the SOLE salt source post-flip: the DB copy is unreadable
    // before the keyed open, so the PR-A DB-salt fallback/self-heal is gone.
    final sidecarResult = await _sidecar.read();
    if (sidecarResult is! SidecarFound) {
      state = AuthVaultError(
        reason: sidecarResult is SidecarCorrupted
            ? VaultErrorReason.sidecarCorrupted
            : VaultErrorReason.sidecarMissing,
      );
      return 'Vault metadata unavailable — recovery required';
    }
    final salt = sidecarResult.salt;
    final pdk = _kds.deriveKey(password: password, salt: salt);
    Uint8List? kek;

    try {
      // dbKey is deliberately NOT zeroed: the keyed connection's setup
      // callback re-executes PRAGMA key from it for the connection lifetime.
      final dbKey = _keyHierarchy.deriveDbKey(pdk);
      kek = _keyHierarchy.deriveKek(pdk);

      if (await VaultMigrator.isPlaintextDb(await VaultPaths.dbFile())) {
        final migrationError = await _migratePlaintextVault(
          pdk: pdk,
          dbKey: dbKey,
          kek: kek,
        );
        if (migrationError != null) return migrationError;
      }

      final db = _ensureDb(dbKey: dbKey);
      final Vault? vault;
      final VaultConfig? config;
      try {
        vault = await db.vaultDao.getFirst();
        config = vault == null
            ? null
            : await db.vaultConfigDao.getByVaultId(vault.id);
      } catch (e) {
        if (!_isNotADatabase(e)) rethrow;
        // Wrong dbKey → SQLITE_NOTADB on the first read. Release the
        // wrong-key instance so it cannot linger in the holder and poison
        // the retry (the next attempt must open fresh with its own key).
        await _releaseDb();
        if (kDebugMode) debugPrint('[Auth:unlock] keyed open rejected');
        return 'Incorrect password';
      }

      if (config == null) {
        // Open succeeded (password right) but the vault has no config —
        // unrecoverable by retyping the password.
        state = const AuthVaultError(reason: VaultErrorReason.configMissing);
        return 'Vault configuration missing — recovery required';
      }

      final mek = _mks.unwrap(
        wrappedKey: Uint8List.fromList(config.encryptedMasterKey),
        wrappingKey: kek,
      );
      if (mek == null) {
        // The keyed open already proved the password, so a failed KEK
        // unwrap means the stored wrapped MEK is corrupted — not a
        // password problem.
        state = const AuthVaultError(reason: VaultErrorReason.mekUnwrapFailed);
        return 'Master key is corrupted — restore from a backup';
      }
      state = AuthUnlocked(masterEncryptionKey: mek, vaultId: vault!.id);
      return null; // success
    } finally {
      _zeroOut(pdk);
      if (kek != null) _zeroOut(kek);
      _zeroOut(salt);
    }
  }

  /// Runs the one-shot plaintext→SQLCipher migration. Returns null on
  /// success, or the error string to surface. Non-password failures
  /// transition to [VaultErrorReason.migrationFailed]; the migrator
  /// preserves the original plaintext vault in every failure mode.
  Future<String?> _migratePlaintextVault({
    required Uint8List pdk,
    required Uint8List dbKey,
    required Uint8List kek,
  }) async {
    // The migrator renames/replaces the DB file — any open connection
    // (e.g. from the legacy sidecar heal) must be released first.
    await _releaseDb();

    MigrationResult result;
    try {
      result = await _migrator.migrate(legacyPdk: pdk, dbKey: dbKey, kek: kek);
    } catch (e) {
      // Unexpected exceptions rank as verification failures: the source is
      // preserved by the migrator's design, so surface a recoverable error.
      if (kDebugMode) debugPrint('[Auth:migrate] unexpected failure: $e');
      result = const MigrationFailure(
        MigrationFailureReason.verificationFailed,
      );
    }

    switch (result) {
      case MigrationSuccess():
        return null;
      case MigrationFailure(reason: MigrationFailureReason.wrongPassword):
        // Nothing was modified — a retype can still succeed.
        return 'Incorrect password';
      case MigrationFailure(:final reason):
        state = const AuthVaultError(reason: VaultErrorReason.migrationFailed);
        return 'Vault encryption upgrade failed (${reason.name}) — '
            'original data preserved';
    }
  }

  /// SQLITE_NOTADB (code 26) detection by message: drift may surface the
  /// SqliteException directly or wrapped (background isolate), but the
  /// "file is not a database" text survives both.
  bool _isNotADatabase(Object error) =>
      error.toString().contains('not a database');

  /// Backward-compat unlock (in-memory DB, keyless): the DB open cannot
  /// verify the password here, so the KEK unwrap is the check instead.
  Future<String?> _unlockCompat({required String password}) async {
    final db = _ensureDb();
    final vault = await db.vaultDao.getFirst();
    final config = vault == null
        ? null
        : await db.vaultConfigDao.getByVaultId(vault.id);

    if (config == null) {
      // A missing vault/config is unrecoverable by retyping the password —
      // transition so the router shows the recovery screen.
      state = const AuthVaultError(reason: VaultErrorReason.configMissing);
      return 'Vault configuration missing — recovery required';
    }

    final dbSalt = Uint8List.fromList(config.masterKeySalt);
    final storedEmk = Uint8List.fromList(config.encryptedMasterKey);

    // Salt source: sidecar when available, DB config otherwise (in-memory
    // DBs are always readable, so the legacy fallback stays valid here).
    final sidecarResult = await _sidecar.read();
    final Uint8List salt;
    var saltFromSidecar = false;
    if (sidecarResult is SidecarFound) {
      salt = sidecarResult.salt;
      saltFromSidecar = true;
    } else {
      salt = dbSalt;
    }

    final pdk = _kds.deriveKey(password: password, salt: salt);
    Uint8List? kek;

    try {
      kek = _keyHierarchy.deriveKek(pdk);
      final mek = _mks.unwrap(wrappedKey: storedEmk, wrappingKey: kek);
      if (mek == null) {
        if (kDebugMode) debugPrint('[Auth:unlock] unwrap failed');
        return 'Incorrect password';
      }
      state = AuthUnlocked(masterEncryptionKey: mek, vaultId: vault!.id);
      return null; // success
    } finally {
      _zeroOut(pdk);
      if (kek != null) _zeroOut(kek);
      if (saltFromSidecar) _zeroOut(salt);
      _zeroOut(dbSalt);
      _zeroOut(storedEmk);
    }
  }

  /// Finish onboarding — transition from first-setup to normal unlocked.
  void completeOnboarding() {
    final current = state;
    if (current is AuthUnlocked && current.isFirstSetup) {
      state = AuthUnlocked(
        masterEncryptionKey: current.masterEncryptionKey,
        vaultId: current.vaultId,
      );
    }
  }

  /// Lock the vault — clear MEK from memory and close the encrypted
  /// connection.
  ///
  /// Guarded: an auto-lock timer firing while the app sits in FirstRun or
  /// VaultError must not mask that state as Locked.
  ///
  /// Zeroes the master key buffer before dropping the reference: Dart's GC does
  /// not guarantee prompt reclamation, so an un-zeroed MEK can linger in memory
  /// (or swap) and be recovered by a memory-dump attack after locking.
  ///
  /// Lazy path: the keyed connection must not outlive the lock (its page
  /// cache and key material die with it); the next unlock reopens with a
  /// freshly derived key. The backward-compat path keeps its in-memory DB
  /// open — closing would destroy its data.
  Future<void> lock() async {
    final current = state;
    if (current is! AuthUnlocked) return;
    _zeroOut(current.masterEncryptionKey);
    state = const AuthLocked();
    if (_openDatabase != null) {
      await _releaseDb();
    }
  }

  /// Wipe all vault data and return to first-run state.
  ///
  /// Crash-safe order (lazy path): sidecar first, so a crash mid-reset never
  /// raises the false data-loss alarm (sidecar-present/db-missing). Post-flip
  /// the leftover encrypted DB lands in VaultError(sidecarMissing), whose
  /// only exit is this same reset — consistent with the user's intent.
  Future<void> resetAndReinitialize() async {
    if (_openDatabase != null) {
      await _sidecar.delete();
      if (_releaseDatabase != null) {
        await _releaseDatabase();
      } else {
        await _db?.close();
      }
      _db = null;
      await VaultPaths.deleteDatabaseFiles();
    } else {
      // Backward-compat path: in-memory DBs have no files to delete.
      await _db!.resetVault();
      await _sidecar.delete();
    }
    state = const AuthFirstRun();
  }

  /// Zero-fill sensitive Uint8List data to prevent memory-dump extraction.
  void _zeroOut(Uint8List data) {
    for (var i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }
}
