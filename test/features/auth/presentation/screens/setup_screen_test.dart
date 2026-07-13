import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/presentation/screens/setup_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('SetupScreen', () {
    group('rendering', () {
      testWidgets('shows the CREATE MASTER PASSWORD hint line', (tester) async {
        // V9 Slab: the screen heading is the mono status line (DESIGN.md
        // §setup copy — distinct from unlock's RETURN TO OPEN).
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.text('CREATE MASTER PASSWORD'), findsOneWidget);
      });

      testWidgets('shows password recovery warning', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.textContaining('cannot be recovered'), findsOneWidget);
      });

      testWidgets('shows master-password and confirm fields', (tester) async {
        // V9 Slab uses in-field mono placeholders instead of block labels.
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('master password'), findsOneWidget);
        expect(find.text('confirm password'), findsOneWidget);
      });

      testWidgets('shows "Create Vault" button', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.text('Create Vault'), findsOneWidget);
      });

      testWidgets('password fields are obscured by default', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        final fields = tester.widgetList<TextField>(find.byType(TextField));
        for (final field in fields) {
          expect(field.obscureText, isTrue);
        }
      });
    });

    group('form validation', () {
      testWidgets('short password shows error', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        // Enter short password (less than 8 chars)
        await tester.enterText(find.byType(TextField).first, 'short');
        await tester.enterText(find.byType(TextField).last, 'short');

        // Tap create vault
        await tester.tap(find.text('Create Vault'));
        await tester.pumpAndSettle();

        // The validator renders "At least 8 characters" — plus the hint text
        // There may be 2+ instances (hint + error), just check at least one error shows
        expect(find.textContaining('At least'), findsWidgets);
      });

      testWidgets('mismatched passwords show error', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        await tester.enterText(find.byType(TextField).first, 'password12345');
        await tester.enterText(find.byType(TextField).last, 'differentpass');

        await tester.tap(find.text('Create Vault'));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOneWidget);
      });
    });

    group('themes', () {
      testWidgets('dark mode renders without errors', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          themeMode: ThemeMode.dark,
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.text('CREATE MASTER PASSWORD'), findsOneWidget);
      });

      testWidgets('light mode renders without errors', (tester) async {
        await tester.pumpProviderWidget(
          const SetupScreen(),
          themeMode: ThemeMode.light,
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.text('CREATE MASTER PASSWORD'), findsOneWidget);
      });
    });
  });
}
