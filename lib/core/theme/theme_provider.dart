import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import 'app_theme.dart';

const _themePrefKey = 'theme_mode';

/// The user's chosen mode for the *unlocked* surface: light ⇒ Bench,
/// dark ⇒ Terminal, system ⇒ follow the OS brightness.
///
/// (V9 restored `system` support — the old "system → dark" normalization is
/// gone.) This only matters once unlocked; the sealed Slab ignores it.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    unawaited(_load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themePrefKey);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      state = ThemeMode.values[index];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, mode.index);
  }

  /// Toggle between dark (Terminal) and light (Bench).
  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}

/// The single [ThemeData] the app renders with.
///
/// Auth state is the primary decider: anything other than [AuthUnlocked] shows
/// the sealed Slab (locked = the weight of a shut vault). Once unlocked, the
/// user's [themeModeProvider] selects Bench (light) / Terminal (dark), with
/// `system` resolved against the current OS brightness.
///
/// The unlock "lights come on" sweep motion is Phase B; here the switch is
/// immediate.
final surfaceThemeProvider = Provider<ThemeData>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) {
    return AppTheme.sealed();
  }

  final mode = ref.watch(themeModeProvider);
  final wantsDark = switch (mode) {
    ThemeMode.light => false,
    ThemeMode.dark => true,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };
  return wantsDark ? AppTheme.terminal() : AppTheme.bench();
});
