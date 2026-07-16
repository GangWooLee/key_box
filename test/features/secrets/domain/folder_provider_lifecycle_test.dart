import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

import '../../../helpers/widget_test_helpers.dart';

/// Regression guard for the lock/unlock provider-lifecycle class: family stream
/// providers that read `databaseProvider` must first `watch(authProvider)` and
/// yield an empty stream while locked — exactly like foldersProvider /
/// secretsProvider / folderSecretCountsProvider already do. Without the guard
/// they touch `databaseProvider` (which throws before unlock) and, after a
/// lock→unlock cycle, keep serving the previous CLOSED connection's dead stream.
void main() {
  group('folder providers — lock guard (lifecycle reactivity)', () {
    test('folderChildrenProvider does not error while locked — the auth guard '
        'short-circuits before touching databaseProvider', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthLocked()),
          ),
          // databaseHolderProvider defaults to null → databaseProvider throws
          // 'read before vault unlock' if the provider forgets the guard.
        ],
      );
      addTearDown(container.dispose);

      final value = container.read(folderChildrenProvider(1));
      expect(
        value.hasError,
        isFalse,
        reason: 'a locked read must yield an empty stream, not a StateError',
      );
    });

    test('folderSecretsProvider does not error while locked — the auth guard '
        'short-circuits before touching databaseProvider', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthLocked()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final value = container.read(folderSecretsProvider(1));
      expect(
        value.hasError,
        isFalse,
        reason: 'a locked read must yield an empty stream, not a StateError',
      );
    });

    test(
      'folderSecretsProvider reads the live database when unlocked',
      () async {
        final vault = await createSeededVault(secretCount: 2);
        addTearDown(vault.db.close);

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

        final secrets = await container.read(
          folderSecretsProvider(vault.folderId).future,
        );
        expect(
          secrets.length,
          2,
          reason: 'the guard must not break the unlocked read',
        );
      },
    );
  });
}
