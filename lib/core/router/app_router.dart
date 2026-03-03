import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/presentation/screens/loading_screen.dart';
import '../../features/auth/presentation/screens/setup_screen.dart';
import '../../features/auth/presentation/screens/unlock_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/secrets/presentation/screens/dashboard_screen.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use ValueNotifier + refreshListenable instead of ref.watch to avoid
  // recreating the entire GoRouter on auth state changes.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refreshNotifier.value++);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: RoutePaths.loading,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final path = state.uri.path;

      return switch (authState) {
        // Initializing → loading screen
        AuthInitial() =>
          path != RoutePaths.loading ? RoutePaths.loading : null,

        // First run → setup screen
        AuthFirstRun() =>
          path != RoutePaths.setup ? RoutePaths.setup : null,

        // Vault locked → unlock screen
        AuthLocked() =>
          path != RoutePaths.unlock ? RoutePaths.unlock : null,

        // First setup complete → onboarding
        AuthUnlocked(isFirstSetup: true) =>
          path != RoutePaths.onboarding ? RoutePaths.onboarding : null,

        // Normal unlocked → redirect away from auth routes
        AuthUnlocked() =>
          RoutePaths.authRoutes.contains(path) ? RoutePaths.dashboard : null,
      };
    },
    routes: [
      GoRoute(
        path: RoutePaths.loading,
        name: RouteNames.loading,
        builder: (context, state) => const LoadingScreen(),
      ),
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
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.auditLog,
        name: RouteNames.auditLog,
        builder: (context, state) => const AuditLogScreen(),
      ),
    ],
  );
});
