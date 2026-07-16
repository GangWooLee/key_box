import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

import '../../../helpers/widget_test_helpers.dart';

/// folderIdsBySecretProvider is a one-shot getFolderIdsBySecretId cache feeding
/// the detail panel's "Folders" chips. The chip link/unlink callbacks await the
/// op then [ref.invalidate] it, so the chips reflect the new membership instead
/// of a stale one-shot read.
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

  group('folderIdsBySecretProvider — refresh after link/unlink', () {
    test(
      'reflects a link after invalidation (as the chip callback does)',
      () async {
        final vault = await createSeededVault(secretCount: 1);
        addTearDown(vault.db.close);
        final secret = vault.secrets.first;
        final extra = await vault.db.folderDao.create(
          vaultId: vault.vaultId,
          name: 'Extra',
        );
        final container = unlockedContainer(vault);

        final before = await container.read(
          folderIdsBySecretProvider(secret.id).future,
        );
        expect(before, isNot(contains(extra.id)));

        await container
            .read(secretOpsProvider)
            .linkToFolder(secret.id, extra.id);
        container.invalidate(folderIdsBySecretProvider(secret.id));

        final after = await container.read(
          folderIdsBySecretProvider(secret.id).future,
        );
        expect(
          after,
          contains(extra.id),
          reason:
              'the chips must re-fetch the linked folder after invalidation',
        );
      },
    );

    test('reflects an unlink after invalidation', () async {
      final vault = await createSeededVault(secretCount: 1);
      addTearDown(vault.db.close);
      final secret = vault.secrets.first;
      final container = unlockedContainer(vault);

      final before = await container.read(
        folderIdsBySecretProvider(secret.id).future,
      );
      expect(before, isNotEmpty, reason: 'seeded secret starts in a folder');
      final homeFolder = before.first;

      await container
          .read(secretOpsProvider)
          .unlinkFromFolder(secret.id, homeFolder);
      container.invalidate(folderIdsBySecretProvider(secret.id));

      final after = await container.read(
        folderIdsBySecretProvider(secret.id).future,
      );
      expect(after, isNot(contains(homeFolder)));
    });
  });
}
