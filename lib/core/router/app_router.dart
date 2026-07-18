import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/presentation/screens/loading_screen.dart';
import '../../features/auth/presentation/screens/setup_screen.dart';
import '../../features/auth/presentation/screens/restore_screen.dart';
import '../../features/auth/presentation/screens/unlock_screen.dart';
import '../../features/auth/presentation/screens/vault_error_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/secrets/presentation/screens/dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

/// Pure redirect policy — extracted so it is tested directly (no mirror copy).
/// Returns the path to redirect to, or null to stay.
///
/// `/restore` is reachable from the two pre-vault states where a user with a
/// `.kbx` but no usable vault actually lands: **AuthFirstRun** (a new machine
/// has no vault → the backup-restore migration path) and **AuthVaultError**
/// (the recovery screen pushes it). It stays bounced under AuthLocked (the
/// vault is intact — restoring over it would need a reset-first flow) and under
/// AuthUnlocked (restore is in `authRoutes`).
String? authRedirect(AuthState authState, String path) {
  return switch (authState) {
    // Initializing → loading screen
    AuthInitial() => path != RoutePaths.loading ? RoutePaths.loading : null,

    // First run → setup, but allow the restore path (new-machine restore)
    AuthFirstRun() =>
      (path == RoutePaths.setup || path == RoutePaths.restore)
          ? null
          : RoutePaths.setup,

    // Vault locked → unlock screen
    AuthLocked() => path != RoutePaths.unlock ? RoutePaths.unlock : null,

    // Vault files inconsistent/corrupted → recovery, but allow restore so the
    // recovery screen's "Restore from backup" push actually renders.
    AuthVaultError() =>
      (path == RoutePaths.vaultError || path == RoutePaths.restore)
          ? null
          : RoutePaths.vaultError,

    // First setup complete → onboarding
    AuthUnlocked(isFirstSetup: true) =>
      path != RoutePaths.onboarding ? RoutePaths.onboarding : null,

    // Normal unlocked → redirect away from auth routes
    AuthUnlocked() =>
      RoutePaths.authRoutes.contains(path) ? RoutePaths.dashboard : null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use ValueNotifier + refreshListenable instead of ref.watch to avoid
  // recreating the entire GoRouter on auth state changes.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refreshNotifier.value++);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: RoutePaths.loading,
    refreshListenable: refreshNotifier,
    redirect: (context, state) =>
        authRedirect(ref.read(authProvider), state.uri.path),
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
        path: RoutePaths.vaultError,
        name: RouteNames.vaultError,
        builder: (context, state) => const VaultErrorScreen(),
      ),
      GoRoute(
        path: RoutePaths.restore,
        name: RouteNames.restore,
        builder: (context, state) => const RestoreScreen(),
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
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
