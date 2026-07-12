abstract final class RouteNames {
  static const loading = 'loading';
  static const setup = 'setup';
  static const unlock = 'unlock';
  static const onboarding = 'onboarding';
  static const vaultError = 'vault-error';
  static const dashboard = 'dashboard';
  static const auditLog = 'audit-log';
  static const settings = 'settings';
}

abstract final class RoutePaths {
  static const loading = '/loading';
  static const setup = '/setup';
  static const unlock = '/unlock';
  static const onboarding = '/onboarding';
  static const vaultError = '/vault-error';
  static const dashboard = '/';
  static const auditLog = '/audit-log';
  static const settings = '/settings';

  /// Auth-related routes that an unlocked user should not be on.
  static const authRoutes = {loading, setup, unlock, onboarding, vaultError};
}
