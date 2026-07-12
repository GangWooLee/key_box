import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/constants/app_constants.dart';
import 'services/window_state_service.dart';
import 'app.dart';

final _windowState = WindowStateService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for macOS
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(
      AppConstants.defaultWindowWidth,
      AppConstants.defaultWindowHeight,
    ),
    minimumSize: Size(
      AppConstants.minWindowWidth,
      AppConstants.minWindowHeight,
    ),
    center: true,
    title: AppConstants.appName,
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Restore saved position if available
    final saved = await _windowState.restore();
    if (saved != null) {
      await windowManager.setBounds(saved);
    }
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    const ProviderScope(child: _WindowListenerWrapper(child: KeyBoxApp())),
  );
}

/// Listens for window move/resize events and persists bounds.
class _WindowListenerWrapper extends StatefulWidget {
  const _WindowListenerWrapper({required this.child});
  final Widget child;

  @override
  State<_WindowListenerWrapper> createState() => _WindowListenerWrapperState();
}

class _WindowListenerWrapperState extends State<_WindowListenerWrapper>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMoved() => _saveBounds();

  @override
  void onWindowResized() => _saveBounds();

  Future<void> _saveBounds() async {
    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    _windowState.save(
      ui.Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
