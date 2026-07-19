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
  // An explicit selection outranks the first-run hero (DESIGN.md §Motion):
  // picking a mode mid-hero-session must change the render, not just the
  // checkmark. Wired here (not via ref.listen on state) so the async prefs
  // _load() — a programmatic change — cannot disarm the hero.
  return ThemeModeNotifier(
    onExplicitChange: () =>
        ref.read(firstRunHeroProvider.notifier).state = false,
  );
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({VoidCallback? onExplicitChange})
    : _onExplicitChange = onExplicitChange,
      super(ThemeMode.dark) {
    unawaited(_load());
  }

  final VoidCallback? _onExplicitChange;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themePrefKey);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      state = ThemeMode.values[index];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _onExplicitChange?.call();
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

/// First-run hero flag (DESIGN.md §Motion 첫 실행 히어로 규칙): the very first
/// sweep after setup lands on the Bench (light) regardless of OS/user mode —
/// the first impression IS the product metaphor. Cleared on the next lock or
/// by an explicit theme selection (the hero beats defaults, never the user);
/// afterwards the user's mode is followed.
final firstRunHeroProvider = StateProvider<bool>((ref) => false);

/// Watches auth transitions to arm/disarm [firstRunHeroProvider]. Kept alive
/// by [surfaceThemeProvider] watching it.
final heroWatcherProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (prev, next) {
    if (prev is AuthFirstRun && next is AuthUnlocked) {
      ref.read(firstRunHeroProvider.notifier).state = true;
    } else if (next is! AuthUnlocked) {
      ref.read(firstRunHeroProvider.notifier).state = false;
    }
  });
});

/// The single [ThemeData] the app renders with.
///
/// Auth state is the primary decider: anything other than [AuthUnlocked] shows
/// the sealed Slab (locked = the weight of a shut vault). Once unlocked, the
/// first-run hero forces the Bench once (see [firstRunHeroProvider]); after
/// that the user's [themeModeProvider] selects Bench (light) / Terminal
/// (dark), with `system` resolved against the current OS brightness.
///
/// The 320ms "lights come on" sweep itself is rendered by `UnlockSweep`
/// (mounted via the app builder) — this provider only decides the target
/// surface the sweep reveals.
final surfaceThemeProvider = Provider<ThemeData>((ref) {
  ref.watch(heroWatcherProvider); // keep the hero transition watcher alive
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) {
    return AppTheme.sealed();
  }

  // First-run hero: the first open is always the dramatic luminance flip.
  if (ref.watch(firstRunHeroProvider)) {
    return AppTheme.bench();
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
