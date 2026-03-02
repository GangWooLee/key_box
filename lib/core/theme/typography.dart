import 'package:flutter/material.dart';

/// Font scale: 12, 14, 16, 18, 20, 24, 48px
/// Primary: SF Pro (system), Mono: SF Mono / JetBrains Mono
abstract final class AppTypography {
  static const _fontFamily = '.AppleSystemUIFont'; // San Francisco on macOS
  static const monoFontFamily = 'SF Mono';

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 1.33,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 1.43,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 1.5,
  );

  static const titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static const titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  static const displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.17,
  );

  /// Monospace for secret values
  static const mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.5,
  );
}
