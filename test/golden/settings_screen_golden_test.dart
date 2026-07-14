@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/features/settings/domain/backup_export.dart';
import 'package:key_box/features/settings/presentation/screens/settings_screen.dart';

import 'golden_helpers.dart';

/// The settings screen (DESIGN.md §settings) — left section rail + right form,
/// on both working surfaces.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final overrides = [
    vaultArchiveBuilderProvider.overrideWithValue(() async => '{}'),
    backupFileSaverProvider.overrideWithValue((_) async => true),
  ];

  testWidgets('settings_screen — Appearance (Terminal)', (tester) async {
    await pumpGolden(
      tester,
      child: const SettingsScreen(),
      size: const Size(760, 520),
      surface: GoldenSurface.terminal,
      overrides: overrides,
    );
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_screen_appearance.png'),
    );
  });

  testWidgets('settings_screen — Backup (Bench)', (tester) async {
    await pumpGolden(
      tester,
      child: const SettingsScreen(),
      size: const Size(760, 520),
      surface: GoldenSurface.bench,
      overrides: overrides,
    );
    await tester.tap(find.text('Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_screen_backup.png'),
    );
  });
}
