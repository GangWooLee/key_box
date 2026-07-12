import 'package:flutter/material.dart';

/// V8 Design System Typography
///
/// Three-font system:
///   Inter         — UI body text (clean, readable)
///   JetBrains Mono — Titles + secret values (technical identity)
///   IBM Plex Mono  — Auth screens (humanistic mono warmth)
///
/// Scale: 12, 13, 14, 16, 18, 20, 22, 24, 48px
abstract final class AppTypography {
  static const interFamily = 'Inter';
  static const jetbrainsFamily = 'JetBrains Mono';
  static const ibmPlexFamily = 'IBM Plex Mono';

  // ─── Body Text (Inter) ───

  static const caption = TextStyle(
    fontFamily: interFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  static const bodySmall = TextStyle(
    fontFamily: interFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  static const bodyMedium = TextStyle(
    fontFamily: interFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  // ─── Titles (JetBrains Mono) ───

  static const titleSmall = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  static const titleMedium = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const titleLarge = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.33,
  );

  static const displayLarge = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.17,
  );

  // ─── Monospace (JetBrains Mono) ───

  static const mono = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.54,
  );

  // ─── Semantic Styles ───

  static const detailName = TextStyle(
    fontFamily: interFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.375,
  );

  static const tableHeader = TextStyle(
    fontFamily: interFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  static const sectionHeader = TextStyle(
    fontFamily: interFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.4,
  );

  static const logoText = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  // ─── Auth Screen Styles (IBM Plex Mono + JetBrains Mono) ───

  static const authTitle = TextStyle(
    fontFamily: jetbrainsFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const authSubtitle = TextStyle(
    fontFamily: ibmPlexFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const authInputLabel = TextStyle(
    fontFamily: ibmPlexFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
}
