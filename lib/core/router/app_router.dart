import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Placeholder screens — will be replaced in Phase 2/3.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    routes: [
      GoRoute(
        path: RoutePaths.setup,
        name: RouteNames.setup,
        builder: (context, state) => const _PlaceholderScreen('Setup'),
      ),
      GoRoute(
        path: RoutePaths.unlock,
        name: RouteNames.unlock,
        builder: (context, state) => const _PlaceholderScreen('Unlock'),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const _PlaceholderScreen('Dashboard'),
      ),
      GoRoute(
        path: RoutePaths.auditLog,
        name: RouteNames.auditLog,
        builder: (context, state) => const _PlaceholderScreen('Audit Log'),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const _PlaceholderScreen('Settings'),
      ),
    ],
  );
}
