import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_notifier.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/settings/domain/settings_preferences.dart';

final autoLockProvider = Provider<AutoLockService>((ref) {
  final service = AutoLockService(ref);

  // Only track when unlocked
  ref.listen(authProvider, (prev, next) {
    if (next is AuthUnlocked) {
      service.start();
    } else {
      service.stop();
    }
  });

  ref.onDispose(() => service.stop());
  return service;
});

class AutoLockService {
  AutoLockService(this._ref);

  final Ref _ref;
  Timer? _timer;

  void start() {
    _resetTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Call this on any user activity (mouse move, key press, etc.)
  void recordActivity() {
    if (_timer != null) _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    // Read the configured timeout each reset, so a settings change takes
    // effect on the next activity without restarting the service.
    final minutes = _ref.read(autoLockMinutesProvider);
    _timer = Timer(Duration(minutes: minutes), _onTimeout);
  }

  void _onTimeout() {
    // Fire-and-forget: lock() zeroes the MEK and flips the state
    // synchronously; only the connection close is awaited internally.
    unawaited(_ref.read(authProvider.notifier).lock());
  }
}
