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

/// Inert migrator: rotation tests never touch the migration path.
class _NoopMigrator extends VaultMigrator {
  @override
  Future<void> recoverInterrupted() async {}
}

void main() {
  const oldPassword = 'rotation-old-pw-1';
  const newPassword = 'rotation-new-pw-2';
  final kds = KeyDerivationService();
  final mks = MasterKeyService();
  final hierarchy = KeyHierarchyService();

  late Directory tempDir;
  late Future<Directory> Function() originalSupportDir;

  late AppDatabase? holderDb;
  late int openCalls;
  late List<Uint8List?> openedWithKeys;
  late AppDatabase Function() dbFactory;

  setUp(() {
    suppressDriftWarning();
    tempDir = Directory.systemTemp.createTempSync('key_rotation_test');
    originalSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tempDir;
    holderDb = null;
    openCalls = 0;
    openedWithKeys = [];
    dbFactory = () => AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await holderDb?.close();
    VaultPaths.supportDir = originalSupportDir;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AuthNotifier makeLazy({required SidecarStore sidecar}) {
    return AuthNotifier.lazy(
      sidecar: sidecar,
      dbFileExists: () async => true,
      openDatabase: ({Uint8List? dbKey}) {
        if (holderDb != null) return holderDb!;
        openCalls++;
        openedWithKeys.add(dbKey == null ? null : Uint8List.fromList(dbKey));
        holderDb = dbFactory();
        return holderDb!;
      },
      releaseDatabase: () async {
        await holderDb?.close();
        holderDb = null;
      },
      migrator: _NoopMigrator(),
    );
  }

  Uint8List salt32(int fill) => Uint8List.fromList(List.filled(32, fill));

  Uint8List kekFor(String password, Uint8List salt) {
    final pdk = kds.deriveKey(password: password, salt: salt);
    return hierarchy.deriveKek(pdk);
  }

  /// Seeds an in-memory vault whose MEK is wrapped under kek(password, salt).
  Future<({AppDatabase db, Uint8List mek})> seedVault({
    required String password,
    required Uint8List wrapSalt,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final mek = mks.generateMasterKey();
    final vault = await db.vaultDao.create(name: 'Personal');
    await db.vaultConfigDao.create(
      vaultId: vault.id,
      masterKeySalt: wrapSalt,
      encryptedMasterKey: mks.wrap(
        masterKey: mek,
        wrappingKey: kekFor(password, wrapSalt),
      ),
    );
    return (db: db, mek: mek);
  }

  group('changePassword — guards and validation', () {
    test('compat (non-lazy) path is unsupported', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final notifier = AuthNotifier(db);

      final error = await notifier.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmation: newPassword,
      );

      expect(error, isNotNull);
    });

    test('requires the vault to be unlocked', () async {
      final notifier = makeLazy(sidecar: InMemorySidecarStore());

      final error = await notifier.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmation: newPassword,
      );

      expect(error, isNotNull);
      expect(error, isNot('Incorrect password'));
    });

    test('rejects mismatched confirmation and short passwords', () async {
      final sidecar = InMemorySidecarStore();
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.setup(password: oldPassword, confirmation: oldPassword);

      expect(
        await notifier.changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
          confirmation: 'different-pw-3',
        ),
        'Passwords do not match',
      );
      expect(
        await notifier.changePassword(
          oldPassword: oldPassword,
          newPassword: 'short',
          confirmation: 'short',
        ),
        contains('at least 12'),
      );
      // Nothing was staged by rejected attempts.
      expect(await sidecar.readStaged(), isA<SidecarMissing>());
    });

    test(
      'rejects a wrong old password cryptographically, with no staging',
      () async {
        final sidecar = InMemorySidecarStore();
        final notifier = makeLazy(sidecar: sidecar);
        await notifier.setup(password: oldPassword, confirmation: oldPassword);
        final saltBefore = (await sidecar.read() as SidecarFound).salt;

        final error = await notifier.changePassword(
          oldPassword: 'not-the-old-pw',
          newPassword: newPassword,
          confirmation: newPassword,
        );

        expect(error, 'Incorrect password');
        expect(await sidecar.readStaged(), isA<SidecarMissing>());
        // Salt unchanged; config still unwraps under the old KEK.
        expect((await sidecar.read() as SidecarFound).salt, equals(saltBefore));
        final config = await holderDb!.vaultConfigDao.getByVaultId(
          (notifier.state as AuthUnlocked).vaultId,
        );
        expect(
          mks.unwrap(
            wrappedKey: Uint8List.fromList(config!.encryptedMasterKey),
            wrappingKey: kekFor(oldPassword, saltBefore),
          ),
          isNotNull,
        );
      },
    );
  });

  group('changePassword — rotation commit', () {
    test('rotates salt + rewraps under the new KEK (mutation: old KEK must '
        'fail), promotes the sidecar, keeps the session MEK intact', () async {
      final sidecar = InMemorySidecarStore();
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.setup(password: oldPassword, confirmation: oldPassword);
      final saltOld = (await sidecar.read() as SidecarFound).salt;
      final sessionMek = (notifier.state as AuthUnlocked).masterEncryptionKey;
      final mekSnapshot = Uint8List.fromList(sessionMek);

      final error = await notifier.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmation: newPassword,
      );

      expect(error, isNull);
      // Session stays unlocked with the SAME MEK (no relock).
      expect(notifier.state, isA<AuthUnlocked>());
      expect(
        sessionMek,
        equals(mekSnapshot),
        reason: 'the session MEK buffer must not be zeroed by rotation',
      );

      // Sidecar: new salt promoted, journal gone.
      final saltNew = (await sidecar.read() as SidecarFound).salt;
      expect(saltNew, isNot(equals(saltOld)));
      expect(await sidecar.readStaged(), isA<SidecarMissing>());

      // Config: rewrapped under kek(new pw, new salt)…
      final config = await holderDb!.vaultConfigDao.getByVaultId(
        (notifier.state as AuthUnlocked).vaultId,
      );
      final stored = Uint8List.fromList(config!.encryptedMasterKey);
      final unwrapped = mks.unwrap(
        wrappedKey: stored,
        wrappingKey: kekFor(newPassword, saltNew),
      );
      expect(unwrapped, isNotNull);
      expect(unwrapped, equals(mekSnapshot), reason: 'same MEK, new wrap');
      // …and the DB salt column matches the promoted sidecar.
      expect(Uint8List.fromList(config.masterKeySalt), equals(saltNew));

      // MUTATION: the old KEK must no longer unwrap.
      expect(
        mks.unwrap(
          wrappedKey: stored,
          wrappingKey: kekFor(oldPassword, saltOld),
        ),
        isNull,
        reason: 'old-KEK unwrap succeeding would mean the rewrap is fake',
      );
    });
  });

  group('unlock — rotation resume (staged journal present)', () {
    test('case A: stale journal (crash before DB commit) is discarded and '
        'unlock proceeds normally', () async {
      final saltOld = salt32(0x01);
      final seeded = await seedVault(password: oldPassword, wrapSalt: saltOld);
      dbFactory = () => seeded.db;
      final sidecar = InMemorySidecarStore();
      await sidecar.write(saltOld);
      await sidecar.writeStaged(salt32(0x02)); // rotation never reached the DB
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.initialize();

      final error = await notifier.unlock(password: oldPassword);

      expect(error, isNull);
      expect(notifier.state, isA<AuthUnlocked>());
      expect(
        await sidecar.readStaged(),
        isA<SidecarMissing>(),
        reason: 'a stale journal must be discarded',
      );
      expect(
        (await sidecar.read() as SidecarFound).salt,
        equals(saltOld),
        reason: 'the main sidecar must not be touched by a stale journal',
      );
    });

    test('case B: DB committed but not rekeyed — new password resumes '
        '(rekey + promote)', () async {
      final saltOld = salt32(0x03);
      final saltNew = salt32(0x04);
      // The DB already holds the NEW wrap (step 4 committed)…
      final seeded = await seedVault(password: newPassword, wrapSalt: saltNew);
      dbFactory = () => seeded.db;
      // …but the sidecar still points at the old salt; journal holds the new.
      final sidecar = InMemorySidecarStore();
      await sidecar.write(saltOld);
      await sidecar.writeStaged(saltNew);
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.initialize();

      final error = await notifier.unlock(password: newPassword);

      expect(error, isNull);
      expect(notifier.state, isA<AuthUnlocked>());
      expect(
        (notifier.state as AuthUnlocked).masterEncryptionKey,
        equals(seeded.mek),
      );
      // Promoted: main sidecar now carries the new salt, journal gone.
      expect((await sidecar.read() as SidecarFound).salt, equals(saltNew));
      expect(await sidecar.readStaged(), isA<SidecarMissing>());
    });

    test('case B with the old password: both unwraps fail → '
        '"Incorrect password", journal kept for the next attempt', () async {
      final saltOld = salt32(0x05);
      final saltNew = salt32(0x06);
      final seeded = await seedVault(password: newPassword, wrapSalt: saltNew);
      dbFactory = () => seeded.db;
      final sidecar = InMemorySidecarStore();
      await sidecar.write(saltOld);
      await sidecar.writeStaged(saltNew);
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.initialize();

      final error = await notifier.unlock(password: oldPassword);

      expect(error, 'Incorrect password');
      expect(
        notifier.state,
        isA<AuthLocked>(),
        reason: 'no mekUnwrapFailed while resume attempts remain',
      );
      expect(
        await sidecar.readStaged(),
        isA<SidecarFound>(),
        reason: 'the journal survives a failed attempt',
      );
    });

    test('case C: DB already rekeyed — reopen with the staged salt, then '
        'promote', () async {
      final saltOld = salt32(0x07);
      final saltNew = salt32(0x08);
      // First open (old-salt dbKey) hits SQLITE_NOTADB — simulated with a
      // connection over a garbage file, exactly the post-rekey behavior.
      final garbagePath = '${tempDir.path}/garbage.bin';
      File(
        garbagePath,
      ).writeAsBytesSync(List.generate(128, (i) => (i * 67 + 5) & 0xFF));
      var attempt = 0;
      late ({AppDatabase db, Uint8List mek}) seeded;
      seeded = await seedVault(password: newPassword, wrapSalt: saltNew);
      dbFactory = () {
        attempt++;
        if (attempt == 1) {
          return AppDatabase.forTesting(
            NativeDatabase.opened(sqlite.sqlite3.open(garbagePath)),
          );
        }
        return seeded.db;
      };
      final sidecar = InMemorySidecarStore();
      await sidecar.write(saltOld);
      await sidecar.writeStaged(saltNew);
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.initialize();

      final error = await notifier.unlock(password: newPassword);

      expect(error, isNull);
      expect(notifier.state, isA<AuthUnlocked>());
      expect(
        (notifier.state as AuthUnlocked).masterEncryptionKey,
        equals(seeded.mek),
      );
      // The reopen used the dbKey derived from the STAGED salt.
      expect(openCalls, 2);
      final expectedDbKey = hierarchy.deriveDbKey(
        kds.deriveKey(password: newPassword, salt: saltNew),
      );
      expect(openedWithKeys.last, equals(expectedDbKey));
      // Promoted and converged.
      expect((await sidecar.read() as SidecarFound).salt, equals(saltNew));
      expect(await sidecar.readStaged(), isA<SidecarMissing>());
    });

    test('case C with a wrong password: both opens fail → '
        '"Incorrect password", journal kept', () async {
      final garbagePath = '${tempDir.path}/garbage.bin';
      File(
        garbagePath,
      ).writeAsBytesSync(List.generate(128, (i) => (i * 29 + 17) & 0xFF));
      dbFactory = () => AppDatabase.forTesting(
        NativeDatabase.opened(sqlite.sqlite3.open(garbagePath)),
      );
      final sidecar = InMemorySidecarStore();
      await sidecar.write(salt32(0x09));
      await sidecar.writeStaged(salt32(0x0A));
      final notifier = makeLazy(sidecar: sidecar);
      await notifier.initialize();

      final error = await notifier.unlock(password: 'wrong-password-x');

      expect(error, 'Incorrect password');
      expect(notifier.state, isA<AuthLocked>());
      expect(await sidecar.readStaged(), isA<SidecarFound>());
      expect(openCalls, 2, reason: 'main open, then staged-salt reopen');
    });
  });
}
