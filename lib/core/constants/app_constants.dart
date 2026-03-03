abstract final class AppConstants {
  static const String appName = 'KeyBox';
  static const String appVersion = '1.0.0';

  // Window
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1440;
  static const double defaultWindowHeight = 900;

  // Layout — 3-Column Dashboard
  static const double sidebarWidth = 200;
  static const double detailPanelWidth = 340;
  static const double navHeight = 56;
  static const double topBarHeight = 38; // macOS standard title bar height
  static const double trafficLightInset = 38; // Traffic light safe area height

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
