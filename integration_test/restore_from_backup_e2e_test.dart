// PR-A (recovery-net): end-to-end restore-from-backup through the REAL
// providers and the REAL cipher. Exports a keyed vault to an archive, wipes the
// vault, restores from the archive, and proves the restored vault is encrypted
// on disk and reopens with the password. This is the cipher gate that plain
// `flutter test` cannot cover: pure crypto + UNKEYED in-memory inserts are
// exercised in test/features/auth/restore_from_backup_test.dart, but the keyed
// SQLCipher round-trip and the sidecar-salt reopen live only here.
//
// Must run in the real macOS app (plain `flutter test` loads Apple's restricted
// libsqlite3 which silently ignores PRAGMA key):
//   flutter test integration_test/restore_from_backup_e2e_test.dart -d macos
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/backup/vault_recovery_service.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/settings/domain/backup_export.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const _password = 'restore-e2e-Passw0rd!7';
const _secretA = 'sk-restore-alpha-11111';
const _secretB = 'pg-restore-beta-22222';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    final base = await getApplicationSupportDirectory();
    tmp = Directory(
      '${base.path}/restore_e2e_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmp;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> expectEncryptedOnDisk() async {
    final bytes = (await VaultPaths.dbFile()).readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
    Object? keylessError;
    try {
      final raw = sqlite3.open((await VaultPaths.dbFile()).path);
      try {
        raw.select('SELECT * FROM vaults;');
      } finally {
        raw.dispose();
      }
    } catch (e) {
      keylessError = e;
    }
    expect(
      keylessError,
      isA<SqliteException>(),
      reason: 'a keyless read of the restored vault file must fail',
    );
  }

  /// Boots a fresh keyed vault, stores two secrets through the real ops path,
  /// and returns its backup archive (built while unlocked).
  Future<String> buildSourceVaultArchive() async {
    final container = ProviderContainer();
    final auth = container.read(authProvider.notifier);
    await auth.initialize();
    expect(container.read(authProvider), isA<AuthFirstRun>());
    expect(
      await auth.setup(password: _password, confirmation: _password),
      isNull,
    );

    final state = container.read(authProvider) as AuthUnlocked;
    final db = container.read(databaseProvider);
    final folder = (await db.folderDao.getByVaultId(state.vaultId)).single;
    final ops = container.read(secretOpsProvider);
    expect(
      await ops.create(name: 'Alpha', value: _secretA, folderId: folder.id),
      isA<Success<Secret>>(),
    );
    expect(
      await ops.create(name: 'Beta', value: _secretB, folderId: folder.id),
      isA<Success<Secret>>(),
    );

    final archive = await container.read(vaultArchiveBuilderProvider)();
    expect(
      archive,
      isNotNull,
      reason: 'a lossy archive must never be produced',
    );
    await auth.lock();
    container.dispose();
    return archive!;
  }

  Future<void> wipeVaultFiles() async {
    await VaultPaths.deleteDatabaseFiles();
    final sidecar = File('${tmp.path}/${VaultPaths.sidecarFileName}');
    if (sidecar.existsSync()) sidecar.deleteSync();
  }

  testWidgets(
    'restore rebuilds an encrypted vault that reopens with the password',
    (tester) async {
      final archive = await buildSourceVaultArchive();
      await wipeVaultFiles();
      expect(
        (await VaultPaths.dbFile()).existsSync(),
        isFalse,
        reason: 'fixture sanity: the source vault is wiped before restore',
      );

      // Restore into a fresh app boot.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final auth = container.read(authProvider.notifier);
      await auth.initialize();

      final outcome = await auth.restoreFromBackup(
        archive: archive,
        password: _password,
      );
      expect(outcome, isA<RestoreSuccess>());
      expect(container.read(authProvider), isA<AuthUnlocked>());

      // The restored vault is really encrypted on disk.
      await expectEncryptedOnDisk();

      // Secrets survived the restore (re-bound to fresh AAD under the new MEK).
      final state = container.read(authProvider) as AuthUnlocked;
      final db = container.read(databaseProvider);
      final secrets = await db.secretDao.getByVaultId(state.vaultId);
      expect(secrets, hasLength(2));
      final ops = container.read(secretOpsProvider);
      final values = <String?>{};
      for (final s in secrets) {
        expect(s.recordVersion, 1, reason: 'a restore is not a rotation');
        values.add(await ops.decrypt(s));
      }
      expect(values, {_secretA, _secretB});

      // ④ lock → ⑤ wrong password → correct password reopen (via sidecar salt).
      await auth.lock();
      expect(container.read(authProvider), isA<AuthLocked>());
      expect(
        await auth.unlock(password: 'wrong-restore-pw-0'),
        'Incorrect password',
      );
      await expectEncryptedOnDisk();

      expect(await auth.unlock(password: _password), isNull);
      expect(container.read(authProvider), isA<AuthUnlocked>());
      final reopened = container.read(databaseProvider);
      final after = await reopened.secretDao.getByVaultId(
        (container.read(authProvider) as AuthUnlocked).vaultId,
      );
      final opsAfter = container.read(secretOpsProvider);
      final reopenedValues = <String?>{};
      for (final s in after) {
        reopenedValues.add(await opsAfter.decrypt(s));
      }
      expect(reopenedValues, {_secretA, _secretB});
      await auth.lock();
    },
  );

  testWidgets('a wrong password is rejected as 오답 with no vault created', (
    tester,
  ) async {
    final archive = await buildSourceVaultArchive();
    await wipeVaultFiles();

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier);
    await auth.initialize();

    final outcome = await auth.restoreFromBackup(
      archive: archive,
      password: 'not-the-backup-pw-9',
    );
    expect(outcome, isA<RestoreWrongPassword>());
    // describeRestore runs BEFORE any DB touch — a failed restore leaves no
    // vault behind, so the user isn't locked into a half-built vault.
    expect((await VaultPaths.dbFile()).existsSync(), isFalse);
    expect(container.read(authProvider), isNot(isA<AuthUnlocked>()));
  });
}
