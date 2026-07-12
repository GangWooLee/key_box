import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/presentation/screens/unlock_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('UnlockScreen', () {
    group('rendering', () {
      testWidgets('shows "Unlock Your Vault" title', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        expect(find.text('Unlock Your Vault'), findsOneWidget);
      });

      testWidgets('shows password field and Unlock button', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Unlock'), findsOneWidget);
      });

      testWidgets('shows password recovery warning', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        expect(find.textContaining('cannot be recovered'), findsOneWidget);
      });
    });

    group('visibility toggle', () {
      testWidgets('eye icon toggles password visibility', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        // Initially obscured
        final initialField = tester.widget<TextField>(find.byType(TextField));
        expect(initialField.obscureText, isTrue);

        // Tap eye icon to toggle
        await tester.tap(find.byType(IconButton));
        await tester.pump();

        final toggledField = tester.widget<TextField>(find.byType(TextField));
        expect(toggledField.obscureText, isFalse);
      });
    });

    group('submission', () {
      testWidgets('empty password does nothing on Unlock tap', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        // Don't enter any text, just tap Unlock
        await tester.tap(find.text('Unlock'));
        await tester.pumpAndSettle();

        // Should still be on unlock screen
        expect(find.text('Unlock Your Vault'), findsOneWidget);
      });
    });

    group('themes', () {
      testWidgets('dark mode renders without errors', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          themeMode: ThemeMode.dark,
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        expect(find.text('Unlock Your Vault'), findsOneWidget);
      });

      testWidgets('light mode renders without errors', (tester) async {
        await tester.pumpProviderWidget(
          const UnlockScreen(),
          themeMode: ThemeMode.light,
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
          ],
        );

        expect(find.text('Unlock Your Vault'), findsOneWidget);
      });
    });
  });
}
