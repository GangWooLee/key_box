import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/core/theme/theme_provider.dart';
import 'package:key_box/features/settings/domain/backup_export.dart';
import 'package:key_box/features/settings/presentation/screens/settings_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

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
