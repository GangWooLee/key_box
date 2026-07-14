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

  // Cancel only the timer on disposal. stop() reads autoLockDeadlineProvider,
  // which throws during container teardown (disposal order isn't guaranteed);
  // dispose() touches no other provider, so it's teardown-safe.
  ref.onDispose(service.dispose);
  return service;
});

/// The wall-clock instant the vault will auto-lock, or null when idle tracking
/// is off (locked). The status strip reads this to show the quiet auto-lock
/// countdown (보안 UX #3); it resets to a fresh deadline on every activity.
final autoLockDeadlineProvider = StateProvider<DateTime?>((ref) => null);

class AutoLockService {
  AutoLockService(this._ref);

  final Ref _ref;
  Timer? _timer;

  void start() {
    _resetTimer();
  }

  void stop() {
    _cancelTimer();
    _ref.read(autoLockDeadlineProvider.notifier).state = null;
  }

  /// Cancel the idle timer without touching any other provider. Safe to call
  /// during container disposal, where reading a provider would throw.
  void dispose() {
    _cancelTimer();
  }

  void _cancelTimer() {
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
    _ref.read(autoLockDeadlineProvider.notifier).state = DateTime.now().add(
      Duration(minutes: minutes),
    );
  }

  void _onTimeout() {
    // Fire-and-forget: lock() zeroes the MEK and flips the state
    // synchronously; only the connection close is awaited internally.
    unawaited(_ref.read(authProvider.notifier).lock());
  }
}
