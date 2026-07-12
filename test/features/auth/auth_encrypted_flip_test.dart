import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/key_hierarchy_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/vault/sidecar_store.dart';
import 'package:key_box/core/vault/vault_migrator.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../helpers/widget_test_helpers.dart';

/// Records calls and returns a scripted result — no real file work.
class _FakeMigrator extends VaultMigrator {
  _FakeMigrator({this.result = const MigrationSuccess()});

  MigrationResult result;
  Object? throwOnMigrate;
  bool recoverCalled = false;
  int migrateCalls = 0;
  Uint8List? capturedLegacyPdk;
  Uint8List? capturedDbKey;
  Uint8List? capturedKek;

  @override
  Future<void> recoverInterrupted() async {
    recoverCalled = true;
  }

  @override
  Future<MigrationResult> migrate({
    required Uint8List legacyPdk,
    required Uint8List dbKey,
    required Uint8List kek,
  }) async {
    migrateCalls++;
    // Copies: the notifier zeroes its buffers after use.
    capturedLegacyPdk = Uint8List.fromList(legacyPdk);
    capturedDbKey = Uint8List.fromList(dbKey);
    capturedKek = Uint8List.fromList(kek);
    if (throwOnMigrate != null) throw throwOnMigrate!;
    return result;
  }
}

void main() {
  const password = 'flip-test-passw0rd';
  final kds = KeyDerivationService();
  final mks = MasterKeyService();
  final hierarchy = KeyHierarchyService();

  late Directory tempDir;
  late Future<Directory> Function() originalSupportDir;

  // openDatabase closure state.
  late AppDatabase? holderDb;
  late int openCalls;
  late int releaseCalls;
  late List<Uint8List?> openedWithKeys;
  late AppDatabase Function() dbFactory;

  setUp(() {
    suppressDriftWarning();
    tempDir = Directory.systemTemp.createTempSync('auth_flip_test');
    originalSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tempDir;
    holderDb = null;
    openCalls = 0;
    releaseCalls = 0;
    openedWithKeys = [];
    dbFactory = () => AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await holderDb?.close();
    VaultPaths.supportDir = originalSupportDir;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AuthNotifier makeLazy({
    required SidecarStore sidecar,
    required bool dbExists,
    VaultMigrator? migrator,
  }) {
    return AuthNotifier.lazy(
      sidecar: sidecar,
      dbFileExists: () async => dbExists,
      openDatabase: ({Uint8List? dbKey}) {
        if (holderDb != null) return holderDb!;
        openCalls++;
        openedWithKeys.add(dbKey == null ? null : Uint8List.fromList(dbKey));
        holderDb = dbFactory();
        return holderDb!;
      },
      releaseDatabase: () async {
        releaseCalls++;
        await holderDb?.close();
        holderDb = null;
      },
      migrator: migrator,
    );
  }

  Uint8List salt32(int fill) => Uint8List.fromList(List.filled(32, fill));

  Future<SidecarStore> sidecarWith(Uint8List salt) async {
    final store = InMemorySidecarStore();
    await store.write(salt);
    return store;
  }

  void writePlaintextDbFile() {
    final db = sqlite.sqlite3.open('${tempDir.path}/${VaultPaths.dbFileName}');
    db.execute('CREATE TABLE IF NOT EXISTS marker (v TEXT);');
    db.dispose();
  }

  void writeEncryptedLookingDbFile() {
    File(
      '${tempDir.path}/${VaultPaths.dbFileName}',
    ).writeAsBytesSync(List.generate(128, (i) => (i * 41 + 7) & 0xFF));
  }

  /// In-memory vault whose MEK is wrapped under the HKDF KEK for
  /// [password] + [salt] — what a post-flip vault looks like.
  Future<AppDatabase> seedKekVault(Uint8List salt) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final pdk = kds.deriveKey(password: password, salt: salt);
    final kek = hierarchy.deriveKek(pdk);
    final mek = mks.generateMasterKey();
    final vault = await db.vaultDao.create(name: 'Personal');
    await db.vaultConfigDao.create(
      vaultId: vault.id,
      masterKeySalt: salt,
      encryptedMasterKey: mks.wrap(masterKey: mek, wrappingKey: kek),
    );
    return db;
  }

  group('initialize — migration recovery + sidecar-missing matrix', () {
    test('lazy initialize runs recoverInterrupted first', () async {
      final migrator = _FakeMigrator();
      final notifier = makeLazy(
        sidecar: await sidecarWith(salt32(1)),
        dbExists: true,
        migrator: migrator,
      );

      await notifier.initialize();

      expect(migrator.recoverCalled, isTrue);
      expect(notifier.state, isA<AuthLocked>());
    });

    test(
      'sidecar missing + ENCRYPTED db file → VaultError(sidecarMissing)',
      () async {
        writeEncryptedLookingDbFile();
        final notifier = makeLazy(
          sidecar: InMemorySidecarStore(),
          dbExists: true,
          migrator: _FakeMigrator(),
        );

        await notifier.initialize();

        expect(notifier.state, isA<AuthVaultError>());
        expect(
          (notifier.state as AuthVaultError).reason,
          VaultErrorReason.sidecarMissing,
        );
      },
    );

    test(
      'sidecar missing + PLAINTEXT db file → legacy heal still works',
      () async {
        writePlaintextDbFile();
        final salt = salt32(2);
        dbFactory = () {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          return db;
        };
        final sidecar = InMemorySidecarStore();
        final notifier = makeLazy(
          sidecar: sidecar,
          dbExists: true,
          migrator: _FakeMigrator(),
        );
        // Seed the healable config into the (lazily opened) fake DB by
        // pre-opening it through the same closure path.
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final vault = await db.vaultDao.create(name: 'P');
        await db.vaultConfigDao.create(
          vaultId: vault.id,
          masterKeySalt: salt,
          encryptedMasterKey: Uint8List.fromList(List.filled(60, 0xAA)),
        );
        dbFactory = () => db;

        await notifier.initialize();

        expect(notifier.state, isA<AuthLocked>());
        expect((await sidecar.read() as SidecarFound).salt, equals(salt));
        // Heal path opens the DB without a key (plaintext read).
        expect(openedWithKeys, [null]);
      },
    );
  });

  group('unlock — plaintext migration path', () {
    test(
      'detects plaintext and calls migrate with HKDF-derived keys',
      () async {
        writePlaintextDbFile();
        final salt = salt32(3);
        final migrator = _FakeMigrator();
        dbFactory = () {
          throw StateError('unused'); // replaced after seeding below
        };
        final seeded = await seedKekVault(salt);
        dbFactory = () => seeded;
        final notifier = makeLazy(
          sidecar: await sidecarWith(salt),
          dbExists: true,
          migrator: migrator,
        );
        await notifier.initialize();

        final error = await notifier.unlock(password: password);

        expect(error, isNull);
        expect(notifier.state, isA<AuthUnlocked>());
        expect(migrator.migrateCalls, 1);
        // The captured keys must be exactly the HKDF hierarchy of the PDK.
        final expectedPdk = kds.deriveKey(password: password, salt: salt);
        expect(migrator.capturedLegacyPdk, equals(expectedPdk));
        expect(
          migrator.capturedDbKey,
          equals(hierarchy.deriveDbKey(expectedPdk)),
        );
        expect(migrator.capturedKek, equals(hierarchy.deriveKek(expectedPdk)));
        // The keyed open after migration received the same dbKey.
        expect(openedWithKeys.last, equals(migrator.capturedDbKey));
      },
    );

    test(
      'migration wrongPassword → "Incorrect password", still Locked',
      () async {
        writePlaintextDbFile();
        final migrator = _FakeMigrator(
          result: const MigrationFailure(MigrationFailureReason.wrongPassword),
        );
        final notifier = makeLazy(
          sidecar: await sidecarWith(salt32(4)),
          dbExists: true,
          migrator: migrator,
        );
        await notifier.initialize();

        final error = await notifier.unlock(password: 'wrong-password-1');

        expect(error, 'Incorrect password');
        expect(notifier.state, isA<AuthLocked>());
        expect(openCalls, 0, reason: 'no keyed open after a failed migration');
      },
    );

    test(
      'non-password migration failures → VaultError(migrationFailed)',
      () async {
        for (final reason in [
          MigrationFailureReason.integrityCheckFailed,
          MigrationFailureReason.exportFailed,
          MigrationFailureReason.verificationFailed,
          MigrationFailureReason.diskSpace,
        ]) {
          writePlaintextDbFile();
          final notifier = makeLazy(
            sidecar: await sidecarWith(salt32(5)),
            dbExists: true,
            migrator: _FakeMigrator(result: MigrationFailure(reason)),
          );
          await notifier.initialize();

          final error = await notifier.unlock(password: password);

          expect(error, isNotNull, reason: '$reason must surface an error');
          expect(notifier.state, isA<AuthVaultError>(), reason: '$reason');
          expect(
            (notifier.state as AuthVaultError).reason,
            VaultErrorReason.migrationFailed,
            reason: '$reason',
          );
        }
      },
    );

    test('unexpected migrate exception ranks as migrationFailed', () async {
      writePlaintextDbFile();
      final migrator = _FakeMigrator()
        ..throwOnMigrate = StateError('boom mid-migration');
      final notifier = makeLazy(
        sidecar: await sidecarWith(salt32(6)),
        dbExists: true,
        migrator: migrator,
      );
      await notifier.initialize();

      final error = await notifier.unlock(password: password);

      expect(error, isNotNull);
      expect(notifier.state, isA<AuthVaultError>());
      expect(
        (notifier.state as AuthVaultError).reason,
        VaultErrorReason.migrationFailed,
      );
    });
  });

  group('unlock — keyed open as the password check', () {
    test('wrong-key SqliteException → release → "Incorrect password" → clean '
        'retry succeeds', () async {
      // An already-encrypted vault file (no migration branch).
      writeEncryptedLookingDbFile();
      final salt = salt32(7);
      // First open: a connection whose every query fails with
      // SQLITE_NOTADB — exactly what a wrong dbKey produces under
      // SQLCipher HMAC rejection.
      final garbagePath = '${tempDir.path}/garbage.bin';
      File(
        garbagePath,
      ).writeAsBytesSync(List.generate(128, (i) => (i * 73 + 11) & 0xFF));
      dbFactory = () => AppDatabase.forTesting(
        NativeDatabase.opened(sqlite.sqlite3.open(garbagePath)),
      );
      final notifier = makeLazy(
        sidecar: await sidecarWith(salt),
        dbExists: true,
        migrator: _FakeMigrator(),
      );
      await notifier.initialize();

      final error = await notifier.unlock(password: 'not-the-password');

      expect(error, 'Incorrect password');
      expect(notifier.state, isA<AuthLocked>());
      expect(
        releaseCalls,
        1,
        reason:
            'the wrong-key instance must be '
            'released so it cannot poison the retry',
      );
      expect(holderDb, isNull);

      // Retry with a healthy connection: not poisoned by the failed one.
      final seeded = await seedKekVault(salt);
      dbFactory = () => seeded;
      final retryError = await notifier.unlock(password: password);

      expect(retryError, isNull);
      expect(notifier.state, isA<AuthUnlocked>());
      expect(openCalls, 2);
    });

    test(
      'KEK unwrap failure after successful open → mekUnwrapFailed',
      () async {
        writeEncryptedLookingDbFile();
        final salt = salt32(8);
        // Open succeeds but the stored wrapped MEK is garbage → corruption,
        // not a wrong password.
        dbFactory = () {
          throw StateError('replaced below');
        };
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final vault = await db.vaultDao.create(name: 'P');
        await db.vaultConfigDao.create(
          vaultId: vault.id,
          masterKeySalt: salt,
          encryptedMasterKey: Uint8List.fromList(List.filled(60, 0xEE)),
        );
        dbFactory = () => db;
        final notifier = makeLazy(
          sidecar: await sidecarWith(salt),
          dbExists: true,
          migrator: _FakeMigrator(),
        );
        await notifier.initialize();

        final error = await notifier.unlock(password: password);

        expect(error, isNotNull);
        expect(notifier.state, isA<AuthVaultError>());
        expect(
          (notifier.state as AuthVaultError).reason,
          VaultErrorReason.mekUnwrapFailed,
        );
      },
    );
  });

  group('setup — encrypted from birth', () {
    test('passes a dbKey to openDatabase and wraps the MEK under the KEK '
        '(mutation: raw-PDK unwrap must fail)', () async {
      final sidecar = InMemorySidecarStore();
      final notifier = makeLazy(
        sidecar: sidecar,
        dbExists: false,
        migrator: _FakeMigrator(),
      );

      final error = await notifier.setup(
        password: password,
        confirmation: password,
      );

      expect(error, isNull);
      expect(notifier.state, isA<AuthUnlocked>());

      // The connection was opened keyed.
      expect(openedWithKeys.single, isNotNull);
      expect(openedWithKeys.single!.length, 32);

      // Recompute the hierarchy from the sidecar salt.
      final salt = (await sidecar.read() as SidecarFound).salt;
      final pdk = kds.deriveKey(password: password, salt: salt);
      expect(openedWithKeys.single, equals(hierarchy.deriveDbKey(pdk)));

      // KEK wrap proof + mutation: raw-PDK unwrap must NOT work.
      final config = await holderDb!.vaultConfigDao.getByVaultId(
        (notifier.state as AuthUnlocked).vaultId,
      );
      final storedEmk = Uint8List.fromList(config!.encryptedMasterKey);
      expect(
        mks.unwrap(
          wrappedKey: storedEmk,
          wrappingKey: hierarchy.deriveKek(pdk),
        ),
        isNotNull,
        reason: 'MEK must unwrap under the HKDF KEK',
      );
      expect(
        mks.unwrap(wrappedKey: storedEmk, wrappingKey: pdk),
        isNull,
        reason: 'raw-PDK wrapping is forbidden post-flip',
      );
    });
  });

  group('lock — encrypted connection lifecycle', () {
    test(
      'lazy lock zeroes the MEK, releases the holder, closes the DB',
      () async {
        final notifier = makeLazy(
          sidecar: InMemorySidecarStore(),
          dbExists: false,
          migrator: _FakeMigrator(),
        );
        await notifier.setup(password: password, confirmation: password);
        final probeDb = holderDb!;
        final mekRef = (notifier.state as AuthUnlocked).masterEncryptionKey;

        await notifier.lock();

        expect(notifier.state, isA<AuthLocked>());
        expect(mekRef.every((b) => b == 0), isTrue);
        expect(releaseCalls, 1);
        expect(holderDb, isNull);
        // The released connection is really closed.
        await expectLater(probeDb.vaultDao.getFirst(), throwsStateError);
      },
    );
  });
}
