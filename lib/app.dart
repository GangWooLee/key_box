import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/motion.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'features/auth/domain/auth_notifier.dart';
import 'features/auth/presentation/widgets/unlock_sweep.dart';

class KeyBoxApp extends ConsumerStatefulWidget {
  const KeyBoxApp({super.key});

  @override
  ConsumerState<KeyBoxApp> createState() => _KeyBoxAppState();
}

class _KeyBoxAppState extends ConsumerState<KeyBoxApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state on app start
    Future.microtask(() => ref.read(authProvider.notifier).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Single source of truth: auth state (locked ⇒ Slab) then user mode
    // (Bench/Terminal). No darkTheme/themeMode — surfaceThemeProvider decides.
    final theme = ref.watch(surfaceThemeProvider);

    return MaterialApp.router(
      title: 'KeyBox',
      debugShowCheckedModeBanner: false,
      theme: theme,
      // Locking is immediate (DESIGN.md: 잠금은 즉각) — the implicit
      // AnimatedTheme would otherwise ease over its 200ms default.
      themeAnimationDuration: AppMotion.snap,
      // The signature unlock sweep paints above the whole app.
      builder: (context, child) =>
          UnlockSweep(child: child ?? const SizedBox.shrink()),
      routerConfig: router,
    );
  }
}
