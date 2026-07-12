import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/vault/sidecar_store.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../helpers/widget_test_helpers.dart';

/// A sidecar whose write always fails — simulates a full disk / permission
/// error so setup must still commit and unlock.
class _ThrowingSidecarStore extends InMemorySidecarStore {
  @override
  Future<void> write(Uint8List salt) async {
    throw const FileSystemException('sidecar write failed');
  }
}

/// A sidecar that always reads as corrupted.
class _CorruptedSidecarStore extends InMemorySidecarStore {
  @override
  Future<SidecarReadResult> read() async => SidecarCorrupted('test corruption');
}

void main() {
  late Directory tempDir;
  late Future<Directory> Function() originalSupportDir;

  setUp(() {
    suppressDriftWarning();
    tempDir = Directory.systemTemp.createTempSync('auth_boot_matrix_test');
    originalSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tempDir;
  });

  tearDown(() {
    VaultPaths.supportDir = originalSupportDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  AppDatabase makeDb() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    return db;
  }

  Uint8List salt32(int fill) => Uint8List.fromList(List.filled(32, fill));

  /// Seeds a vault + config directly (no KDF) and returns the stored salt.
  Future<Uint8List> seedConfig(AppDatabase db) async {
    final salt = Uint8List.fromList(List.generate(32, (i) => i + 1));
    final vault = await db.vaultDao.create(name: 'Personal');
    await db.vaultConfigDao.create(
      vaultId: vault.id,
      masterKeySalt: salt,
      encryptedMasterKey: Uint8List.fromList(List.filled(60, 0xAA)),
    );
    return salt;
  }

  AuthNotifier makeLazy({
    required SidecarStore sidecar,
    required bool dbExists,
    required AppDatabase db,
  }) {
    return AuthNotifier.lazy(
      sidecar: sidecar,
      dbFileExists: () async => dbExists,
      openDatabase: ({Uint8List? dbKey}) => db,
    );
  }

  /// Creates a real plaintext SQLite file at the vault path — post-flip
  /// initialize() probes it to decide between legacy heal and the
  /// unhealable encrypted-without-sidecar cell.
  void writePlaintextDbFile() {
    final raw = sqlite.sqlite3.open('${tempDir.path}/${VaultPaths.dbFileName}');
    raw.execute('CREATE TABLE IF NOT EXISTS marker (v TEXT);');
    raw.dispose();
  }

  group('boot matrix — initialize()', () {
    test('1. no sidecar + no db file → FirstRun', () async {
      final notifier = makeLazy(
        sidecar: InMemorySidecarStore(),
        dbExists: false,
        db: makeDb(),
      );
      await notifier.initialize();
      expect(notifier.state, isA<AuthFirstRun>());
    });

    test('2. sidecar + db file → Locked', () async {
      final sidecar = InMemorySidecarStore();
      await sidecar.write(salt32(0x11));
      final notifier = makeLazy(sidecar: sidecar, dbExists: true, db: makeDb());
      await notifier.initialize();
      expect(notifier.state, isA<AuthLocked>());
    });

    test('3. no sidecar + PLAINTEXT db with config → legacy heal writes '
        'sidecar, Locked', () async {
      writePlaintextDbFile();
      final db = makeDb();
      final dbSalt = await seedConfig(db);
      final sidecar = InMemorySidecarStore();

      final notifier = makeLazy(sidecar: sidecar, dbExists: true, db: db);
      await notifier.initialize();

      expect(notifier.state, isA<AuthLocked>());
      final healed = await sidecar.read();
      expect(healed, isA<SidecarFound>());
      expect((healed as SidecarFound).salt, equals(dbSalt));
    });

    test('4. no sidecar + PLAINTEXT db file without config → FirstRun '
        '(setup debris)', () async {
      writePlaintextDbFile();
      final notifier = makeLazy(
        sidecar: InMemorySidecarStore(),
        dbExists: true,
        db: makeDb(), // empty: crash between file creation and setup commit
      );
      await notifier.initialize();
      expect(notifier.state, isA<AuthFirstRun>());
    });

    test('4b. no sidecar + ENCRYPTED db file → VaultError(sidecarMissing) — '
        'the salt is unrecoverable', () async {
      File(
        '${tempDir.path}/${VaultPaths.dbFileName}',
      ).writeAsBytesSync(List.generate(128, (i) => (i * 59 + 3) & 0xFF));
      final notifier = makeLazy(
        sidecar: InMemorySidecarStore(),
        dbExists: true,
        db: makeDb(),
      );
      await notifier.initialize();

      expect(notifier.state, isA<AuthVaultError>());
      expect(
        (notifier.state as AuthVaultError).reason,
        VaultErrorReason.sidecarMissing,
      );
    });

    test('5. sidecar + no db file → VaultError(vaultFileMissing)', () async {
      final sidecar = InMemorySidecarStore();
      await sidecar.write(salt32(0x22));
      final notifier = makeLazy(
        sidecar: sidecar,
        dbExists: false,
        db: makeDb(),
      );
      await notifier.initialize();

      expect(notifier.state, isA<AuthVaultError>());
      expect(
        (notifier.state as AuthVaultError).reason,
        VaultErrorReason.vaultFileMissing,
      );
    });

    test('6. corrupted sidecar → VaultError(sidecarCorrupted)', () async {
      final notifier = makeLazy(
        sidecar: _CorruptedSidecarStore(),
        dbExists: true,
        db: makeDb(),
      );
      await notifier.initialize();

      expect(notifier.state, isA<AuthVaultError>());
      expect(
        (notifier.state as AuthVaultError).reason,
        VaultErrorReason.sidecarCorrupted,
      );
    });

    test('7. heal is idempotent across boots and re-entry guarded', () async {
      writePlaintextDbFile();
      final db = makeDb();
      final dbSalt = await seedConfig(db);
      final sidecar = InMemorySidecarStore();

      final first = makeLazy(sidecar: sidecar, dbExists: true, db: db);
      await first.initialize();
      expect(first.state, isA<AuthLocked>());

      // Re-entry on the same notifier is a no-op.
      await first.initialize();
      expect(first.state, isA<AuthLocked>());

      // A second boot (sidecar now present) reaches the same state and
      // leaves the sidecar salt untouched.
      final second = makeLazy(sidecar: sidecar, dbExists: true, db: db);
      await second.initialize();
      expect(second.state, isA<AuthLocked>());
      expect((await sidecar.read() as SidecarFound).salt, equals(dbSalt));
    });
  });

  group('unlock — salt sources and recovery', () {
    // (Former test 8 — sidecar/db salt-mismatch fallback — was removed with
    // the encryption flip: the DB salt is unreadable before the keyed open,
    // so the sidecar is the sole salt source. PR-B design decision.)

    test('10. db without config → unlock transitions to '
        'VaultError(configMissing)', () async {
      final sidecar = InMemorySidecarStore();
      await sidecar.write(salt32(0x33));
      final notifier = makeLazy(
        sidecar: sidecar,
        dbExists: true,
        db: makeDb(), // no vault/config rows
      );
      await notifier.initialize();
      expect(notifier.state, isA<AuthLocked>());

      final error = await notifier.unlock(password: 'whatever123');
      expect(error, isNotNull);
      expect(notifier.state, isA<AuthVaultError>());
      expect(
        (notifier.state as AuthVaultError).reason,
        VaultErrorReason.configMissing,
      );
    });
  });

  group('setup — sidecar write failure is non-fatal', () {
    test('9. sidecar write throws → setup still commits and unlocks', () async {
      final notifier = makeLazy(
        sidecar: _ThrowingSidecarStore(),
        dbExists: false,
        db: makeDb(),
      );

      final error = await notifier.setup(
        password: 'testpass1',
        confirmation: 'testpass1',
      );

      expect(error, isNull);
      expect(notifier.state, isA<AuthUnlocked>());
    });
  });

  group('lock — guard', () {
    test('11. lock() from AuthVaultError is a no-op', () async {
      final sidecar = InMemorySidecarStore();
      await sidecar.write(salt32(0x44));
      final notifier = makeLazy(
        sidecar: sidecar,
        dbExists: false,
        db: makeDb(),
      );
      await notifier.initialize();
      expect(notifier.state, isA<AuthVaultError>());

      notifier.lock();

      expect(
        notifier.state,
        isA<AuthVaultError>(),
        reason: 'an auto-lock timer must not mask a vault error as Locked',
      );
    });
  });

  group('reset — crash-safe order', () {
    test('12. lazy reset deletes sidecar + db files → FirstRun', () async {
      // Real files under the injected support dir.
      final dbFile = File('${tempDir.path}/${VaultPaths.dbFileName}')
        ..writeAsStringSync('db');
      final walFile = File('${tempDir.path}/${VaultPaths.dbWalFileName}')
        ..writeAsStringSync('wal');

      final sidecar = InMemorySidecarStore();
      await sidecar.write(salt32(0x55));
      final notifier = makeLazy(sidecar: sidecar, dbExists: true, db: makeDb());
      await notifier.initialize();
      expect(notifier.state, isA<AuthLocked>());

      await notifier.resetAndReinitialize();

      expect(notifier.state, isA<AuthFirstRun>());
      expect(await sidecar.read(), isA<SidecarMissing>());
      expect(dbFile.existsSync(), isFalse);
      expect(walFile.existsSync(), isFalse);
    });
  });
}
