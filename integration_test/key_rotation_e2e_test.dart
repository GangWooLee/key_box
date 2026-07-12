// PR-B (B5): end-to-end master password rotation on the REAL cipher —
// rewrap + PRAGMA rekey + two-file commit protocol, through the real
// providers. The canonical gate for changePassword.
//
// Must run in the real macOS app (plain `flutter test` loads Apple's
// restricted libsqlite3 where PRAGMA key/rekey are silent no-ops):
//   flutter test integration_test/key_rotation_e2e_test.dart -d macos
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/core/vault/sidecar_store.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:path_provider/path_provider.dart';

const _oldPassword = 'rotate-Old-Pw-1!';
const _newPassword = 'rotate-New-Pw-2!';
const _secretValue = 'sk-rotation-survivor-777';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    final base = await getApplicationSupportDirectory();
    tmp = Directory(
      '${base.path}/b5_rotation_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmp;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File mainSidecarFile() => File('${tmp.path}/${VaultPaths.sidecarFileName}');
  File stagedSidecarFile() =>
      File('${tmp.path}/${VaultPaths.sidecarStagedFileName}');

  /// Boots a fresh vault with one secret; returns the container.
  Future<ProviderContainer> bootVaultWithSecret() async {
    final container = ProviderContainer();
    final auth = container.read(authProvider.notifier);
    await auth.initialize();
    expect(container.read(authProvider), isA<AuthFirstRun>());
    expect(
      await auth.setup(password: _oldPassword, confirmation: _oldPassword),
      isNull,
    );
    final state = container.read(authProvider) as AuthUnlocked;
    final db = container.read(databaseProvider);
    final folder = (await db.folderDao.getByVaultId(state.vaultId)).single;
    final created = await container
        .read(secretOpsProvider)
        .create(
          name: 'Rotation Survivor',
          value: _secretValue,
          folderId: folder.id,
        );
    expect(created, isA<Success>());
    return container;
  }

  Future<void> expectSecretDecrypts(ProviderContainer container) async {
    final state = container.read(authProvider) as AuthUnlocked;
    final db = container.read(databaseProvider);
    final secrets = await db.secretDao.getByVaultId(state.vaultId);
    final value = await container
        .read(secretOpsProvider)
        .decrypt(secrets.single);
    expect(value, _secretValue);
  }

  testWidgets(
    'changePassword rekeys the vault: old password is rejected (NOTADB), '
    'new password round-trips, journal converges',
    (tester) async {
      final container = await bootVaultWithSecret();
      addTearDown(container.dispose);
      final auth = container.read(authProvider.notifier);

      final error = await auth.changePassword(
        oldPassword: _oldPassword,
        newPassword: _newPassword,
        confirmation: _newPassword,
      );
      expect(error, isNull);

      // Session survives the rotation with the same MEK — no relock.
      expect(container.read(authProvider), isA<AuthUnlocked>());
      await expectSecretDecrypts(container);
      expect(
        stagedSidecarFile().existsSync(),
        isFalse,
        reason: 'the journal must be promoted away on success',
      );

      await auth.lock();

      // MUTATION GATE: the old password must fail against the rekeyed file
      // (SQLCipher HMAC rejection — reported as a wrong password).
      final oldError = await auth.unlock(password: _oldPassword);
      expect(oldError, 'Incorrect password');
      expect(container.read(authProvider), isA<AuthLocked>());

      // The new password owns the vault now.
      final newError = await auth.unlock(password: _newPassword);
      expect(newError, isNull);
      expect(container.read(authProvider), isA<AuthUnlocked>());
      await expectSecretDecrypts(container);
      expect(stagedSidecarFile().existsSync(), isFalse);

      await auth.lock();
    },
  );

  testWidgets(
    'interrupted rotation (case C: rekeyed but not promoted) resumes on '
    'unlock with the new password',
    (tester) async {
      // Build a completed rotation, then manually reconstruct the state
      // just before the sidecar promotion (crash between ⑤ and ⑥).
      final container = await bootVaultWithSecret();
      final auth = container.read(authProvider.notifier);
      final preRotationSidecarBytes = mainSidecarFile().readAsBytesSync();

      expect(
        await auth.changePassword(
          oldPassword: _oldPassword,
          newPassword: _newPassword,
          confirmation: _newPassword,
        ),
        isNull,
      );
      await auth.lock();
      final promotedSidecarBytes = mainSidecarFile().readAsBytesSync();
      container.dispose();

      // Undo step ⑥ only: journal back in place, main sidecar back to the
      // OLD salt. The DB itself is already rekeyed to the new hierarchy.
      stagedSidecarFile().writeAsBytesSync(promotedSidecarBytes);
      mainSidecarFile().writeAsBytesSync(preRotationSidecarBytes);

      // Fresh boot (new container = new process semantics).
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final auth2 = container2.read(authProvider.notifier);
      await auth2.initialize();
      expect(container2.read(authProvider), isA<AuthLocked>());

      final error = await auth2.unlock(password: _newPassword);

      expect(error, isNull);
      expect(container2.read(authProvider), isA<AuthUnlocked>());
      await expectSecretDecrypts(container2);
      // Converged: journal promoted onto the main sidecar.
      expect(stagedSidecarFile().existsSync(), isFalse);
      final sidecarNow = await FileSidecarStore().read();
      final promotedSalt =
          (await () async {
                // Parse the promoted bytes through a throwaway store for a
                // like-for-like salt comparison.
                final dir = Directory('${tmp.path}/cmp')..createSync();
                File(
                  '${dir.path}/${VaultPaths.sidecarFileName}',
                ).writeAsBytesSync(promotedSidecarBytes);
                return FileSidecarStore(baseDir: () async => dir).read();
              }())
              as SidecarFound;
      expect(
        (sidecarNow as SidecarFound).salt,
        equals(promotedSalt.salt),
        reason: 'the main sidecar must carry the promoted (new) salt',
      );

      await auth2.lock();
    },
  );
}
