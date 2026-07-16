import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

import '../../../helpers/widget_test_helpers.dart';

/// secretDetailProvider is a one-shot getById cache; sheet_modal._save
/// [ref.invalidate]s it after an in-place edit so the detail panel re-fetches
/// the fresh row. Without that refresh a just-edited credential would keep
/// showing (and, on the stale object, decrypting) the OLD value.
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

  group('secretDetailProvider — refresh-after-edit contract', () {
    test(
      're-fetches the edited row after invalidation (as _save does)',
      () async {
        final vault = await createSeededVault(secretCount: 1);
        addTearDown(vault.db.close);
        final secret = vault.secrets.first;
        final container = unlockedContainer(vault);

        final before = await container.read(
          secretDetailProvider(secret.id).future,
        );
        expect(before?.name, secret.name);

        // Rename (value:null → no rotation) via the real ops path, then invalidate
        // exactly as sheet_modal._save does after an edit.
        await container
            .read(secretOpsProvider)
            .update(secret.id, name: 'renamed');
        container.invalidate(secretDetailProvider(secret.id));

        final after = await container.read(
          secretDetailProvider(secret.id).future,
        );
        expect(
          after?.name,
          'renamed',
          reason: 'the detail must re-fetch the edited row after invalidation',
        );
      },
    );

    test('without invalidation the one-shot cache stays stale — this is the '
        'staleness _save fixes', () async {
      final vault = await createSeededVault(secretCount: 1);
      addTearDown(vault.db.close);
      final secret = vault.secrets.first;
      final container = unlockedContainer(vault);

      // Hold a subscription so the autoDispose cache persists across reads.
      final sub = container.listen(secretDetailProvider(secret.id), (_, __) {});
      addTearDown(sub.close);

      final before = await container.read(
        secretDetailProvider(secret.id).future,
      );
      expect(before?.name, secret.name);

      await container
          .read(secretOpsProvider)
          .update(secret.id, name: 'changed');
      final cached = await container.read(
        secretDetailProvider(secret.id).future,
      );
      expect(
        cached?.name,
        secret.name,
        reason: 'the un-invalidated one-shot future keeps the pre-edit row',
      );
    });
  });
}
