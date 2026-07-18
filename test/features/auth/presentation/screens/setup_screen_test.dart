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

      testWidgets('shows a "Restore from backup" entry point', (tester) async {
        // Confirmed UX defect: a new machine (AuthFirstRun) had no path to
        // restore from a .kbx — restore was only reachable from vault-error.
        // Setup must offer it so backup/restore round-trip works on onboarding.
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        expect(find.text('Restore from backup'), findsOneWidget);
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

        // Enter short password (below the 12-char minimum)
        await tester.enterText(find.byType(TextField).first, 'short');
        await tester.enterText(find.byType(TextField).last, 'short');

        // Tap create vault
        await tester.tap(find.text('Create Vault'));
        await tester.pumpAndSettle();

        // The validator renders "At least 12 characters" — plus the hint text.
        // There may be 2+ instances (hint + error); check at least one shows.
        expect(find.textContaining('At least'), findsWidgets);
      });

      testWidgets('weak-strength hint band shows for 12–15, gone at 16', (
        tester,
      ) async {
        // Guards the hint band (setup_screen _strongLength=16 vs
        // minPasswordLength=12): raising the minimum without raising
        // _strongLength collapses this band to empty — a silent UX loss.
        await tester.pumpProviderWidget(
          const SetupScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthFirstRun()),
            ),
          ],
        );

        // 13 chars — inside the weak band (12..15): the non-blocking hint shows.
        await tester.enterText(find.byType(TextField).first, 'thirteenchars');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('a longer password is stronger'),
          findsOneWidget,
        );

        // 16 chars — strong: the weak hint is gone.
        await tester.enterText(
          find.byType(TextField).first,
          'sixteencharslong',
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('a longer password is stronger'),
          findsNothing,
        );
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
