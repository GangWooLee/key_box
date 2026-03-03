import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefKey = 'theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    unawaited(_load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themePrefKey);
    if (index != null && index < ThemeMode.values.length) {
      final loaded = ThemeMode.values[index];
      // Normalize legacy system mode to dark
      state = loaded == ThemeMode.system ? ThemeMode.dark : loaded;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Guard: system mode is no longer supported
    if (mode == ThemeMode.system) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, mode.index);
  }

  /// Toggle between dark and light.
  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}
