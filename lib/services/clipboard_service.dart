import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

class ClipboardService {
  Timer? _clearTimer;

  /// Copy value to clipboard and auto-clear after 30 seconds.
  Future<void> copyWithAutoClear(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _clearTimer?.cancel();
    _clearTimer = Timer(
      const Duration(seconds: AppConstants.clipboardClearSeconds),
      _clearClipboard,
    );
  }

  void _clearClipboard() {
    Clipboard.setData(const ClipboardData(text: ''));
  }

  void dispose() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
