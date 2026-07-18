import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

import '../../../helpers/widget_test_helpers.dart';

/// [SecretOperations.removeFromFolder] is the ONLY path that can change a
/// secret's home folder (secrets.folderId). The create-time folder is otherwise
/// immutable through the app — there is no folder picker in edit, no drag, no
/// context menu. This method lets the detail-panel chip remove ANY folder
/// (including home) while guaranteeing the secret stays in >= 1 folder: removing
/// the home folder promotes a remaining linked folder to home so the pointer
/// never dangles.
void main() {
  ProviderContainer unlockedContainer(TestVaultData vault) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(vault.db),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            AuthUnlocked(
              masterEncryptionKey: vault.masterKey,
              vaultId: vault.vaultId,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SecretOperations.removeFromFolder', () {
    test(
      'removing the HOME folder promotes the remaining folder to home',
      () async {
        final vault = await createSeededVault(secretCount: 1);
        addTearDown(vault.db.close);
        final secret = vault.secrets.first;
        expect(
          secret.folderId,
          vault.folderId,
          reason: 'seeded secret home is the default folder',
        );
        final toss = await vault.db.folderDao.create(
          vaultId: vault.vaultId,
          name: 'toss',
        );
        final ops = unlockedContainer(vault).read(secretOpsProvider);

        // Now in {General(home), toss}.
        await ops.linkToFolder(secret.id, toss.id);

        final result = await ops.removeFromFolder(secret.id, vault.folderId);
        expect(result, isA<Success<void>>());

        // Home pointer moved to toss — the "move to toss only" outcome.
        final updated = await vault.db.secretDao.getById(secret.id);
        expect(
          updated!.folderId,
          toss.id,
          reason: 'home reassigned to the remaining folder',
        );

        // M:N membership is toss only; General is gone.
        final links = await vault.db.folderSecretsDao.getFolderIdsBySecretId(
          secret.id,
        );
        expect(links, [toss.id]);
      },
    );

    test('removing a NON-home folder leaves home intact', () async {
      final vault = await createSeededVault(secretCount: 1);
      addTearDown(vault.db.close);
      final secret = vault.secrets.first;
      final toss = await vault.db.folderDao.create(
        vaultId: vault.vaultId,
        name: 'toss',
      );
      final ops = unlockedContainer(vault).read(secretOpsProvider);
      await ops.linkToFolder(secret.id, toss.id);

      final result = await ops.removeFromFolder(secret.id, toss.id);
      expect(result, isA<Success<void>>());

      final updated = await vault.db.secretDao.getById(secret.id);
      expect(
        updated!.folderId,
        vault.folderId,
        reason: 'home unchanged when a non-home folder is removed',
      );
      final links = await vault.db.folderSecretsDao.getFolderIdsBySecretId(
        secret.id,
      );
      expect(links, [vault.folderId]);
    });

    test(
      'refuses to remove the ONLY folder (a secret must stay in >= 1)',
      () async {
        final vault = await createSeededVault(secretCount: 1);
        addTearDown(vault.db.close);
        final secret = vault.secrets.first;
        final ops = unlockedContainer(vault).read(secretOpsProvider);

        final result = await ops.removeFromFolder(secret.id, vault.folderId);
        expect(result, isA<Failure<void>>());

        // Nothing changed — still in home, home unchanged.
        final updated = await vault.db.secretDao.getById(secret.id);
        expect(updated!.folderId, vault.folderId);
        final links = await vault.db.folderSecretsDao.getFolderIdsBySecretId(
          secret.id,
        );
        expect(links, [vault.folderId]);
      },
    );
  });
}
