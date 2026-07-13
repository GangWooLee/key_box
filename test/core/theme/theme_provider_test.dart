import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:key_box/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier', () {
    late ThemeModeNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = ThemeModeNotifier();
    });

    test('defaults to dark theme', () {
      expect(notifier.state, ThemeMode.dark);
    });

    test('toggle switches between dark and light', () {
      // dark -> light
      notifier.toggle();
      expect(notifier.state, ThemeMode.light);

      // light -> dark
      notifier.toggle();
      expect(notifier.state, ThemeMode.dark);
    });

    test('setThemeMode changes state', () async {
      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
    });

    test('setThemeMode accepts system mode (V9 OS-follow)', () async {
      // V9 restored system support (the old "system → dark" normalization is
      // gone); surfaceThemeProvider resolves it against OS brightness.
      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
    });

    test('persisted system mode loads as system (V9)', () async {
      // Simulate a persisted system mode (index 0).
      SharedPreferences.setMockInitialValues({'theme_mode': 0});
      final notifier2 = ThemeModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier2.state, ThemeMode.system);
    });

    test('persists and restores theme mode', () async {
      await notifier.setThemeMode(ThemeMode.light);

      // Create new notifier — should load from SharedPreferences
      final notifier2 = ThemeModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier2.state, ThemeMode.light);
    });
  });
}
