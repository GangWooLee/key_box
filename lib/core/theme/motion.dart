/// V9 motion tokens — compiled from docs/design/DESIGN.md §Motion.
///
/// Three durations, no more: hover feedback, everything else, and the one
/// signature moment. Easing: enter `easeOut`, exit `easeIn`, move `easeInOut`.
library;

abstract final class AppMotion {
  /// 80ms — hover, pilot-light state changes.
  static const micro = Duration(milliseconds: 80);

  /// 160ms — panel expands, overlays, transitions. The default.
  static const short = Duration(milliseconds: 160);

  /// 320ms — the unlock "lights come on" sweep ONLY.
  static const signature = Duration(milliseconds: 320);
}
