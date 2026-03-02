import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/presentation/screens/setup_screen.dart';
import '../../features/auth/presentation/screens/unlock_screen.dart';
import '../../features/secrets/presentation/screens/dashboard_screen.dart';
import 'route_names.dart';

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
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
