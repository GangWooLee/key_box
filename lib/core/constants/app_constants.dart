abstract final class AppConstants {
  static const String appName = 'KeyBox';
  static const String appVersion = '1.0.0';

  // Window
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;

  // Layout
  static const double sidebarWidth = 240;
  static const double listPaneWidth = 320;
  static const double navHeight = 56;

  // Clipboard
  static const int clipboardClearSeconds = 30;

  // Auto-lock
  static const int autoLockMinutes = 15;

  // Pagination
  static const int auditPageSize = 50;
  static const int searchResultLimit = 50;

  // Debounce
  static const int searchDebounceMs = 300;
}
