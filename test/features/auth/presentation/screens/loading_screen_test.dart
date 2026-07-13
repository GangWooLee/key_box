import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/presentation/screens/loading_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('LoadingScreen', () {
    testWidgets('shows the KEY_BOX wordmark', (tester) async {
      await tester.pumpProviderWidget(
        const LoadingScreen(),
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthInitial()),
          ),
        ],
      );

      expect(find.text('KEY_BOX'), findsOneWidget);
    });

    testWidgets('dev reset asks for confirmation before wiping', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const LoadingScreen(),
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthInitial()),
          ),
        ],
      );

      await tester.tap(find.text('dev: reset vault'));
      await tester.pump();

      // Destructive friction (DESIGN.md security UX #2): a confirm dialog
      // gates the wipe; Cancel dismisses without resetting.
      expect(find.text('Reset Vault?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Reset Vault?'), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator', (tester) async {
      await tester.pumpProviderWidget(
        const LoadingScreen(),
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthInitial()),
          ),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dark theme renders correctly', (tester) async {
      await tester.pumpProviderWidget(
        const LoadingScreen(),
        themeMode: ThemeMode.dark,
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthInitial()),
          ),
        ],
      );

      expect(find.text('KEY_BOX'), findsOneWidget);
    });

    testWidgets('light theme renders correctly', (tester) async {
      await tester.pumpProviderWidget(
        const LoadingScreen(),
        themeMode: ThemeMode.light,
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthInitial()),
          ),
        ],
      );

      expect(find.text('KEY_BOX'), findsOneWidget);
    });
  });
}
