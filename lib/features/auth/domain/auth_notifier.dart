import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/vault_paths.dart';
import '../../../core/encryption/key_derivation_service.dart';
import '../../../core/encryption/master_key_service.dart';
import '../../../core/constants/crypto_constants.dart';
import '../../../core/vault/sidecar_store.dart';
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
    openDatabase: () {
      // Closure keeps Ref out of the notifier. Reuse an already-open DB
      // (relock→unlock) and register new ones in the holder so healing and
      // unlock share one instance (no WAL contention).
      final existing = ref.read(databaseHolderProvider);
      if (existing != null) return existing;
      final db = AppDatabase();
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
      super(const AuthInitial());

  /// Production constructor: zero IO until needed. The database is opened
  /// lazily via [openDatabase] only when the boot matrix requires it.
  /// [releaseDatabase] closes the shared instance AND clears its external
  /// registration (the Riverpod holder) — reset uses it so a later setup
  /// cannot receive a closed database.
  AuthNotifier.lazy({
    required SidecarStore sidecar,
    required AppDatabase Function() openDatabase,
    required Future<bool> Function() dbFileExists,
    Future<void> Function()? releaseDatabase,
  }) : _db = null,
       _sidecar = sidecar,
       _openDatabase = openDatabase,
       _dbFileExists = dbFileExists,
       _releaseDatabase = releaseDatabase,
       super(const AuthInitial());

  AppDatabase? _db;
  final SidecarStore _sidecar;
  final AppDatabase Function()? _openDatabase;
  final Future<bool> Function()? _dbFileExists;
  final Future<void> Function()? _releaseDatabase;
  final _kds = KeyDerivationService();
  final _mks = MasterKeyService();

  AppDatabase _ensureDb() => _db ??= _openDatabase!();

  /// Boot matrix: decide the initial state from sidecar + DB-file presence.
  ///
  /// | sidecar   | db file             | state                              |
  /// |-----------|---------------------|------------------------------------|
  /// | missing   | absent              | FirstRun                           |
  /// | found     | present             | Locked                             |
  /// | missing   | present, config     | heal salt into sidecar, Locked     |
  /// | missing   | present, no config  | FirstRun (setup crash debris)      |
  /// | found     | absent              | VaultError(vaultFileMissing)       |
  /// | corrupted | —                   | VaultError(sidecarCorrupted)       |
  Future<void> initialize() async {
    // Re-entry guard: a second call (router refresh, timer) must not stomp
    // an already-resolved state.
    if (state is! AuthInitial) return;

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
        } else {
          await _healFromLegacyDb();
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

  /// First-time setup: create vault, derive keys, wrap MEK.
  Future<String?> setup({
    required String password,
    required String confirmation,
  }) async {
    // Validate
    if (password != confirmation) return 'Passwords do not match';
    if (password.length < CryptoConstants.minPasswordLength) {
      return 'Password must be at least ${CryptoConstants.minPasswordLength} characters';
    }

    // Idempotency guard: a second setup over a committed vault would orphan
    // the existing MEK.
    if (await _ensureDb().vaultConfigDao.exists()) {
      return 'Vault already exists';
    }

    // Generate cryptographic materials
    final salt = _kds.generateSalt();
    final pdk = _kds.deriveKey(password: password, salt: salt);
    final mek = _mks.generateMasterKey();
    final wrappedMek = _mks.wrap(masterKey: mek, wrappingKey: pdk);

    try {
      if (kDebugMode) {
        debugPrint(
          '[Auth:setup] salt(${salt.length}B) wrappedMek(${wrappedMek.length}B)',
        );
      }

      // Create vault + config + default folder atomically.
      // Salt is dual-written to vault_configs and the sidecar during PR-A;
      // PR-B single migration drops this column.
      final db = _ensureDb();
      late int vaultId;
      await db.transaction(() async {
        final vault = await db.vaultDao.create(name: 'Personal');
        vaultId = vault.id;
        await db.vaultConfigDao.create(
          vaultId: vault.id,
          masterKeySalt: salt,
          encryptedMasterKey: wrappedMek,
          masterPasswordDigest:
              '', // No BCrypt in Flutter — we verify via unwrap
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
      _zeroOut(salt);
      _zeroOut(wrappedMek);
    }
  }

  /// Unlock vault with password.
  ///
  /// PR-B: password verification becomes "DB open succeeds" — this unwrap
  /// check is the PR-A placeholder.
  Future<String?> unlock({required String password}) async {
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

    // Salt source: sidecar when available, DB config otherwise (legacy
    // callers may unlock without initialize()) — heal the sidecar in passing.
    final sidecarResult = await _sidecar.read();
    final Uint8List salt;
    var saltFromSidecar = false;
    if (sidecarResult is SidecarFound) {
      salt = sidecarResult.salt;
      saltFromSidecar = true;
    } else {
      salt = dbSalt;
      try {
        await _sidecar.write(dbSalt);
      } catch (e) {
        if (kDebugMode) debugPrint('[Auth:unlock] sidecar heal failed: $e');
      }
    }

    final pdk = _kds.deriveKey(password: password, salt: salt);
    Uint8List? retryPdk;

    try {
      var mek = _mks.unwrap(wrappedKey: storedEmk, wrappingKey: pdk);

      // Salt-mismatch self-heal: a partial restore or manual file copy can
      // leave sidecar and DB salts from different generations, which would
      // reject the correct password forever. Retry with the DB salt.
      // PR-B removes this fallback (DB salt unreadable pre-open).
      if (mek == null && saltFromSidecar && !listEquals(salt, dbSalt)) {
        retryPdk = _kds.deriveKey(password: password, salt: dbSalt);
        mek = _mks.unwrap(wrappedKey: storedEmk, wrappingKey: retryPdk);
        if (mek != null) {
          try {
            await _sidecar.write(dbSalt);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[Auth:unlock] sidecar rewrite failed: $e');
            }
          }
        }
      }

      if (mek == null) {
        if (kDebugMode) debugPrint('[Auth:unlock] unwrap failed');
        return 'Incorrect password';
      }
      state = AuthUnlocked(masterEncryptionKey: mek, vaultId: vault!.id);
      return null; // success
    } finally {
      _zeroOut(pdk);
      if (retryPdk != null) _zeroOut(retryPdk);
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

  /// Lock the vault — clear MEK from memory.
  ///
  /// Guarded: an auto-lock timer firing while the app sits in FirstRun or
  /// VaultError must not mask that state as Locked.
  ///
  /// Zeroes the master key buffer before dropping the reference: Dart's GC does
  /// not guarantee prompt reclamation, so an un-zeroed MEK can linger in memory
  /// (or swap) and be recovered by a memory-dump attack after locking.
  void lock() {
    final current = state;
    if (current is! AuthUnlocked) return;
    _zeroOut(current.masterEncryptionKey);
    state = const AuthLocked();
  }

  /// Wipe all vault data and return to first-run state.
  ///
  /// Crash-safe order (lazy path): sidecar first, so a crash mid-reset lands
  /// in the healable missing-sidecar/db-present cell instead of raising a
  /// false data-loss alarm (sidecar-present/db-missing).
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
