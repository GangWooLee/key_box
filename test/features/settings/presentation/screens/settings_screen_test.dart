import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/core/theme/theme_provider.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/settings/domain/backup_export.dart';
import 'package:key_box/features/settings/domain/settings_preferences.dart';
import 'package:key_box/features/settings/presentation/screens/settings_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// Returns a preset [changePassword] result so the Security form can be tested
/// without the real (integration-only) keyed rekey.
class _ChangePasswordFake extends FakeAuthNotifier {
  _ChangePasswordFake(super.initial, this._result);
  final String? _result; // null = success

  @override
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmation,
  }) async => _result;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsScreen', () {
    testWidgets('opens on Appearance with theme options', (tester) async {
      await tester.pumpProviderWidget(const SettingsScreen());

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Backup'), findsOneWidget);
      expect(find.text('Light — the Bench'), findsOneWidget);
      expect(find.text('Dark — the Terminal'), findsOneWidget);
      expect(find.text('Follow the system'), findsOneWidget);
    });

    testWidgets('choosing a theme updates the mode', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                theme: AppTheme.terminal(),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Light — the Bench'));
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    testWidgets('Preferences sets auto-lock time and reveal default', (
      tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                theme: AppTheme.terminal(),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Preferences'));
      await tester.pump();
      expect(find.text('AUTO-LOCK'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);

      await tester.tap(find.text('5m'));
      await tester.pump();
      expect(container.read(autoLockMinutesProvider), 5);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(container.read(revealByDefaultProvider), isTrue);
    });

    testWidgets('the Backup section exports and records the timestamp', (
      tester,
    ) async {
      var savedContents = '';
      await tester.pumpProviderWidget(
        const SettingsScreen(),
        overrides: [
          vaultArchiveBuilderProvider.overrideWithValue(
            () async => '<archive-json>',
          ),
          backupFileSaverProvider.overrideWithValue((contents) async {
            savedContents = contents;
            return true; // saved
          }),
        ],
      );

      await tester.tap(find.text('Backup'));
      await tester.pump();
      expect(find.text('never backed up'), findsOneWidget);

      await tester.tap(find.text('Export backup'));
      await tester.pump(); // busy
      await tester.pump(); // build + save + record resolve
      await tester.pump();

      expect(savedContents, '<archive-json>');
      expect(find.text('backup saved'), findsOneWidget);
    });

    testWidgets('a locked/unreadable vault surfaces a clay reason', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const SettingsScreen(),
        overrides: [
          vaultArchiveBuilderProvider.overrideWithValue(() async => null),
          backupFileSaverProvider.overrideWithValue((_) async => true),
        ],
      );

      await tester.tap(find.text('Backup'));
      await tester.pump();
      await tester.tap(find.text('Export backup'));
      await tester.pump();
      await tester.pump();

      expect(find.text("couldn't read the vault"), findsOneWidget);
    });

    testWidgets('the Security section changes the master password', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const SettingsScreen(),
        overrides: [
          authProvider.overrideWith(
            (ref) => _ChangePasswordFake(
              AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
              null, // success
            ),
          ),
        ],
      );

      await tester.tap(find.text('Security'));
      await tester.pump();
      expect(find.text('CHANGE MASTER PASSWORD'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));

      await tester.enterText(find.byType(TextField).at(0), 'old-password');
      await tester.enterText(find.byType(TextField).at(1), 'new-password-12');
      await tester.enterText(find.byType(TextField).at(2), 'new-password-12');
      await tester.tap(find.text('Change password'));
      await tester.pump();
      await tester.pump();

      expect(find.text('password changed'), findsOneWidget);
    });

    testWidgets('a rejected password change shows the clay reason', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const SettingsScreen(),
        overrides: [
          authProvider.overrideWith(
            (ref) => _ChangePasswordFake(
              AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
              'Incorrect password',
            ),
          ),
        ],
      );

      await tester.tap(find.text('Security'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'wrong');
      await tester.enterText(find.byType(TextField).at(1), 'new-password-12');
      await tester.enterText(find.byType(TextField).at(2), 'new-password-12');
      await tester.tap(find.text('Change password'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Incorrect password'), findsOneWidget);
    });

    testWidgets('cancelling the save leaves the status unchanged', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const SettingsScreen(),
        overrides: [
          vaultArchiveBuilderProvider.overrideWithValue(
            () async => '<archive-json>',
          ),
          backupFileSaverProvider.overrideWithValue((_) async => false),
        ],
      );

      await tester.tap(find.text('Backup'));
      await tester.pump();
      await tester.tap(find.text('Export backup'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Cancelled → no 'backup saved', still 'never backed up'.
      expect(find.text('backup saved'), findsNothing);
      expect(find.text('never backed up'), findsOneWidget);
    });
  });
}
