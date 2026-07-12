import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/secret_detail.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  late TestVaultData vault;
  late MockSecretOperations mockOps;
  late MockClipboardService mockClipboard;

  setUpAll(() {
    suppressDriftWarning();
    registerFallbackValues();
  });

  setUp(() async {
    vault = await createSeededVault(secretCount: 1);
    mockOps = MockSecretOperations();
    mockClipboard = MockClipboardService();

    when(() => mockClipboard.copyWithAutoClear(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await vault.db.close();
  });

  List<Override> buildOverrides({int? selectedId}) {
    return [
      databaseProvider.overrideWithValue(vault.db),
      authProvider.overrideWith(
        (ref) => FakeAuthNotifier(
          AuthUnlocked(
            masterEncryptionKey: vault.masterKey,
            vaultId: vault.vaultId,
          ),
        ),
      ),
      selectedSecretIdProvider.overrideWith((ref) => selectedId),
      secretOpsProvider.overrideWithValue(mockOps),
      clipboardServiceProvider.overrideWithValue(mockClipboard),
    ];
  }

  group('SecretDetail', () {
    group('empty state', () {
      testWidgets('shows "Select a secret to view details" when no selection', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: null),
        );

        expect(find.text('Select a secret to view details'), findsOneWidget);
      });

      testWidgets('shows key icon', (tester) async {
        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: null),
        );

        expect(find.byIcon(LucideIcons.keyRound), findsOneWidget);
      });
    });

    group('secret display', () {
      testWidgets('shows secret name', (tester) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        expect(find.text(secret.name), findsOneWidget);
      });

      testWidgets('shows masked value (bullet string)', (tester) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        // 20 bullet characters
        expect(
          find.text(
            '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
          ),
          findsOneWidget,
        );
      });
    });

    group('value box interactions', () {
      testWidgets('Reveal button calls ops.reveal and shows decrypted value', (
        tester,
      ) async {
        final secret = vault.secrets.first;
        when(
          () => mockOps.reveal(any()),
        ).thenAnswer((_) async => 'decrypted-value');

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reveal'));
        await tester.pumpAndSettle();

        expect(find.text('decrypted-value'), findsOneWidget);
        expect(find.text('Hide'), findsOneWidget);
        verify(() => mockOps.reveal(any())).called(1);
      });

      testWidgets('Hide button re-masks value', (tester) async {
        final secret = vault.secrets.first;
        when(
          () => mockOps.reveal(any()),
        ).thenAnswer((_) async => 'decrypted-value');

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        // Reveal first
        await tester.tap(find.text('Reveal'));
        await tester.pumpAndSettle();

        // Then hide
        await tester.tap(find.text('Hide'));
        await tester.pumpAndSettle();

        expect(find.text('Reveal'), findsOneWidget);
        expect(find.text('decrypted-value'), findsNothing);
      });

      testWidgets('Copy button calls ops.decrypt and shows "Copied!"', (
        tester,
      ) async {
        final secret = vault.secrets.first;
        when(
          () => mockOps.decrypt(any()),
        ).thenAnswer((_) async => 'decrypted-value');

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        expect(find.text('Copied!'), findsOneWidget);
        verify(() => mockOps.decrypt(any())).called(1);
        verify(
          () => mockClipboard.copyWithAutoClear('decrypted-value'),
        ).called(1);

        // Advance past the 2-second "Copied!" timer to avoid pending timer error
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('collapsible details', () {
      testWidgets('Details section is collapsed by default', (tester) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        expect(find.text('Details'), findsOneWidget);
        // Detail rows should not be visible when collapsed
        expect(find.text('Type'), findsNothing);
      });

      testWidgets('Details expand on tap shows type, created, updated', (
        tester,
      ) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();

        expect(find.text('Type'), findsOneWidget);
        expect(find.text('Created'), findsOneWidget);
        expect(find.text('Updated'), findsOneWidget);
        expect(find.text('Accessed'), findsOneWidget);
      });
    });

    group('footer bar', () {
      testWidgets('Edit and Delete buttons rendered', (tester) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('Delete shows confirmation dialog', (tester) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Secret'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('Delete cancel keeps secret', (tester) async {
        final secret = vault.secrets.first;

        await tester.pumpProviderWidget(
          const SecretDetail(),
          overrides: buildOverrides(selectedId: secret.id),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Secret name should still be visible
        expect(find.text(secret.name), findsOneWidget);
      });
    });
  });
}
