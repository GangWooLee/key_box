import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

class ClipboardService {
  /// [onCopy] fires the instant a secret is copied; [onClear] when the
  /// auto-clear timer wipes it. The detail panel uses [onCopy] to (re)start
  /// the quiet auto-clear countdown ring (보안 UX #3 — 조용한 가시화).
  ClipboardService({this.onCopy, this.onClear});

  final VoidCallback? onCopy;
  final VoidCallback? onClear;

  Timer? _clearTimer;

  /// Copy value to clipboard and auto-clear after 30 seconds.
  Future<void> copyWithAutoClear(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _clearTimer?.cancel();
    onCopy?.call();
    _clearTimer = Timer(
      const Duration(seconds: AppConstants.clipboardClearSeconds),
      _clearClipboard,
    );
  }

  void _clearClipboard() {
    Clipboard.setData(const ClipboardData(text: ''));
    onClear?.call();
  }

  void dispose() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
