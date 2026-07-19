import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:key_box/core/theme/colors.dart';
import 'package:key_box/core/theme/theme_provider.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

import '../../helpers/widget_test_helpers.dart';

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

  group('surfaceThemeProvider — first-run hero (DESIGN.md §Motion)', () {
    setUp(() {
      suppressDriftWarning();
      SharedPreferences.setMockInitialValues({});
    });

    AuthUnlocked unlocked() =>
        AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1);

    test('FirstRun→Unlocked lands on bench even in dark mode; '
        'relock → next unlock follows the user mode (terminal)', () async {
      final fake = FakeAuthNotifier(const AuthFirstRun());
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);

      // Activate the provider chain (hero watcher included).
      container.listen(surfaceThemeProvider, (_, __) {});

      // User mode is dark by default — but sealed while not unlocked.
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.slabBg,
      );

      // First-run hero: the first sweep target is ALWAYS the bench.
      fake.setAuthState(unlocked());
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.benchCanvas,
      );

      // Relock clears the hero flag — back to the slab.
      fake.setAuthState(const AuthLocked());
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.slabBg,
      );

      // Subsequent unlocks follow the user's mode (dark ⇒ terminal).
      fake.setAuthState(unlocked());
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.termCanvas,
      );
    });

    test('explicit setThemeMode(dark) during the hero session disarms the '
        'hero and renders the terminal immediately', () async {
      final fake = FakeAuthNotifier(const AuthFirstRun());
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);
      container.listen(surfaceThemeProvider, (_, __) {});

      fake.setAuthState(unlocked());
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.benchCanvas,
      );

      // QA repro: mode already reads dark (default) — re-selecting Dark in
      // Settings must still flip the render, not just the checkmark.
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(container.read(firstRunHeroProvider), isFalse);
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.termCanvas,
      );
    });

    test('toggle() during the hero session disarms the hero and follows '
        'the chosen mode', () async {
      final fake = FakeAuthNotifier(const AuthFirstRun());
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);
      container.listen(surfaceThemeProvider, (_, __) {});

      fake.setAuthState(unlocked());

      // dark → light: still the bench, but now by explicit choice.
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(firstRunHeroProvider), isFalse);
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.benchCanvas,
      );

      // light → dark: render must follow.
      container.read(themeModeProvider.notifier).toggle();
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.termCanvas,
      );
    });

    test('programmatic prefs load does NOT disarm the hero', () async {
      // A persisted mode loading in the background is not a user action —
      // the first-run reveal must survive it.
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.index,
      });
      final fake = FakeAuthNotifier(const AuthFirstRun());
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);
      container.listen(surfaceThemeProvider, (_, __) {});

      fake.setAuthState(unlocked());
      // Instantiate the notifier and let its async _load() complete.
      container.read(themeModeProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(firstRunHeroProvider), isTrue);
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.benchCanvas,
      );
    });

    test('regular Locked→Unlocked never sets the hero flag', () async {
      final fake = FakeAuthNotifier(const AuthLocked());
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);
      container.listen(surfaceThemeProvider, (_, __) {});

      fake.setAuthState(unlocked());
      expect(container.read(firstRunHeroProvider), isFalse);
      expect(
        container.read(surfaceThemeProvider).scaffoldBackgroundColor,
        AppColors.termCanvas,
      );
    });
  });
}
