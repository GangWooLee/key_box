import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Idle minutes before the vault auto-locks. Persisted; read by the auto-lock
/// service so a change takes effect on the next activity reset.
final autoLockMinutesProvider =
    StateNotifierProvider<AutoLockMinutesNotifier, int>((ref) {
      return AutoLockMinutesNotifier();
    });

/// The auto-lock timeouts offered in settings (minutes).
const autoLockOptions = [1, 5, 15, 30];

class AutoLockMinutesNotifier extends StateNotifier<int> {
  AutoLockMinutesNotifier() : super(AppConstants.autoLockMinutes) {
    _load();
  }

  static const _key = 'auto_lock_minutes';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_key);
    if (v != null) state = v;
  }

  Future<void> set(int minutes) async {
    state = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, minutes);
  }
}

/// Whether opening a secret reveals its value immediately (vs masked). Off by
/// default — masking is the safer posture.
final revealByDefaultProvider =
    StateNotifierProvider<RevealByDefaultNotifier, bool>((ref) {
      return RevealByDefaultNotifier();
    });

class RevealByDefaultNotifier extends StateNotifier<bool> {
  RevealByDefaultNotifier() : super(false) {
    _load();
  }

  static const _key = 'reveal_by_default';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
