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

  /// Native bridge to the macOS pasteboard. The handler tags the item
  /// `org.nspasteboard.ConcealedType` so clipboard managers (Paste, Maccy…)
  /// skip persisting/syncing the secret (보안 — CSO F6 위협 완화). Best-effort:
  /// on any platform that lacks the handler (widget tests, other OSes) we fall
  /// back to the plain system clipboard.
  static const _secureChannel = MethodChannel('keybox/secure_clipboard');

  Timer? _clearTimer;

  /// Copy value to clipboard and auto-clear after 30 seconds.
  Future<void> copyWithAutoClear(String value) async {
    await _writeConcealed(value);
    _clearTimer?.cancel();
    onCopy?.call();
    _clearTimer = Timer(
      const Duration(seconds: AppConstants.clipboardClearSeconds),
      _clearClipboard,
    );
  }

  /// Write via the concealed-pasteboard channel; fall back to the plain
  /// clipboard when the native handler is unavailable so a copy never fails.
  Future<void> _writeConcealed(String value) async {
    try {
      await _secureChannel.invokeMethod<void>('copyConcealed', {
        'value': value,
      });
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: value));
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: value));
    }
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
