/// V9 «SLAB & BENCH» spacing + radius tokens.
///
/// Compiled from `docs/design/DESIGN.md` (§Spacing, §Layout, §Components).
/// The 8pt base scale; radii follow the macOS "결" (sm/md/lg only — no pill).
/// Inline `EdgeInsets` in screen code are progressively reclaimed onto these.
abstract final class AppSpacing {
  /// 4 — tightest gaps (icon↔label, badge padding).
  static const double xs = 4;

  /// 8 — compact rows, chip padding.
  static const double sm = 8;

  /// 16 — default component padding.
  static const double md = 16;

  /// 24 — section gaps, panel padding.
  static const double lg = 24;

  /// 32 — large blocks.
  static const double xl = 32;

  /// 48 — hero / empty-state breathing room.
  static const double xxl = 48;
}

/// Corner radii — macOS grain. Pills/bubbles are forbidden; `full` is reserved
/// for status dots only (DESIGN.md §Layout).
abstract final class AppRadii {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 10;
}

/// Minimum interactive hit area, in logical pixels.
///
/// 32×32 — the macOS desktop-pointer target (DESIGN.md §Components review).
/// 44 is the *touch* rule and does not apply to this cursor-driven app.
const double kMinHitTarget = 32.0;
