import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/presentation/screens/vault_error_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  setUp(suppressDriftWarning);

  Future<void> pumpScreen(WidgetTester tester, VaultErrorReason reason) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(AuthVaultError(reason: reason)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const VaultErrorScreen(),
        ),
      ),
    );
  }

  group('VaultErrorScreen', () {
    testWidgets('vaultFileMissing shows missing-data-file message', (
      tester,
    ) async {
      await pumpScreen(tester, VaultErrorReason.vaultFileMissing);

      expect(find.text('Vault data file is missing'), findsOneWidget);
      // Data-loss warning must point the user toward backup restore.
      expect(find.textContaining('backup'), findsOneWidget);
      expect(find.text('Reset vault'), findsOneWidget);
    });

    testWidgets('sidecarCorrupted shows corrupted-metadata message', (
      tester,
    ) async {
      await pumpScreen(tester, VaultErrorReason.sidecarCorrupted);

      expect(find.text('Vault metadata is corrupted'), findsOneWidget);
      expect(find.text('Reset vault'), findsOneWidget);
    });

    testWidgets('configMissing shows missing-configuration message', (
      tester,
    ) async {
      await pumpScreen(tester, VaultErrorReason.configMissing);

      expect(find.text('Vault configuration is missing'), findsOneWidget);
      expect(find.text('Reset vault'), findsOneWidget);
    });

    testWidgets('reset button opens a confirmation dialog', (tester) async {
      await pumpScreen(tester, VaultErrorReason.sidecarCorrupted);

      await tester.tap(find.text('Reset vault'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset Vault?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('cancel dismisses the dialog without resetting', (
      tester,
    ) async {
      await pumpScreen(tester, VaultErrorReason.sidecarCorrupted);

      await tester.tap(find.text('Reset vault'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // Still on the error screen.
      expect(find.text('Vault metadata is corrupted'), findsOneWidget);
    });
  });
}
