import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/presentation/screens/setup_screen.dart';
import '../../features/auth/presentation/screens/unlock_screen.dart';
import 'route_names.dart';

/// Placeholder dashboard — will be replaced in Phase 3.
class _DashboardPlaceholder extends ConsumerWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final vaultId = authState is AuthUnlocked ? authState.vaultId : 0;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('KeyBox Unlocked', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Vault ID: $vaultId', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).lock(),
              icon: const Icon(Icons.lock),
              label: const Text('Lock'),
            ),
          ],
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    redirect: (context, state) {
      final path = state.uri.path;

      return switch (authState) {
        AuthInitial() => null, // stay wherever we are during init
        AuthFirstRun() => path == RoutePaths.setup ? null : RoutePaths.setup,
        AuthLocked() => path == RoutePaths.unlock ? null : RoutePaths.unlock,
        AuthUnlocked() =>
          (path == RoutePaths.setup || path == RoutePaths.unlock)
              ? RoutePaths.dashboard
              : null,
      };
    },
    routes: [
      GoRoute(
        path: RoutePaths.setup,
        name: RouteNames.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.unlock,
        name: RouteNames.unlock,
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const _DashboardPlaceholder(),
      ),
    ],
  );
});
