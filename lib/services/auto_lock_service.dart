import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/domain/auth_notifier.dart';
import '../features/auth/domain/auth_state.dart';

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
    _timer = Timer(
      const Duration(minutes: AppConstants.autoLockMinutes),
      _onTimeout,
    );
  }

  void _onTimeout() {
    _ref.read(authProvider.notifier).lock();
  }
}
