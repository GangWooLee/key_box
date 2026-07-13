import 'package:flutter/material.dart';

/// V9 «SLAB & BENCH» typography — compiled from `docs/design/DESIGN.md`.
///
/// Single family, two faces (3 families → 1 family 2 faces):
///   IBM Plex Sans — Body/UI (labels, nav, buttons, metadata). 400·500·600.
///   IBM Plex Mono — Display (wordmark, lock, section heads) + Values
///                   (every secret value, timestamp, count, path). 400·500·600.
///
/// Scale (px): caption 10.5 · body-s 12.5 · body 13 · body-l 14 ·
///             title-s 16 · title 20 · display 24–28.
/// Line height: body 1.5 · table 1.35 · display 1.2.
/// Display tracking is in px (Flutter `letterSpacing`), ≈0.14em (14px → 2.0).
///
/// Style *names* are preserved from V8 (118 references keep compiling); only the
/// face/size/weight values are re-cut to V9.
abstract final class AppTypography {
  static const sansFamily = 'IBM Plex Sans';
  static const monoFamily = 'IBM Plex Mono';

  // Legacy family aliases → single Plex family (screen code still references
  // these names). Do not use in new code.
  static const interFamily = sansFamily; // legacy alias → IBM Plex Sans
  static const jetbrainsFamily = monoFamily; // legacy alias → IBM Plex Mono
  static const ibmPlexFamily = monoFamily; // legacy alias → IBM Plex Mono

  // ─── Body / UI (IBM Plex Sans) ───

  /// caption 10.5 — small UI labels / meta.
  static const caption = TextStyle(
    fontFamily: sansFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.35,
    decoration: TextDecoration.none,
  );

  /// body-s 12.5 — table rows, meta, the UI workhorse.
  static const bodySmall = TextStyle(
    fontFamily: sansFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    decoration: TextDecoration.none,
  );

  /// body-l 14 — larger body copy.
  static const bodyMedium = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  // ─── Titles (IBM Plex Sans, heavier) ───

  /// title-s 16 — panel titles.
  static const titleSmall = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  /// title 20 — screen titles.
  static const titleMedium = TextStyle(
    fontFamily: sansFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  /// 24 — large screen title.
  static const titleLarge = TextStyle(
    fontFamily: sansFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );

  // ─── Display / Values (IBM Plex Mono) ───

  /// display 28 — onboarding / empty-state hero. Mono 600 + tracking.
  static const displayLarge = TextStyle(
    fontFamily: monoFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    height: 1.2,
  );

  /// Values (secret values, timestamps, counts, paths). Mono 400, body-l 14.
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  // ─── Semantic styles ───

  /// Secret name in the detail panel — title-s 16, Sans 600.
  static const detailName = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  /// Table header — Mono, caption, +tracking, UPPERCASE (set at call site).
  static const tableHeader = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.35,
    decoration: TextDecoration.none,
  );

  /// Section head (sidebar) — Mono 600, +tracking.
  static const sectionHeader = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.4,
  );

  /// Wordmark `KEY_BOX` — Display, Mono 600 + tracking, UPPERCASE.
  static const logoText = TextStyle(
    fontFamily: monoFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
  );

  // ─── Auth / lock screen (Slab) — Mono ───

  /// Lock/setup heading (e.g. `CREATE MASTER PASSWORD`) — Mono 600 + tracking.
  static const authTitle = TextStyle(
    fontFamily: monoFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.5,
  );

  /// Lock hint line — Mono 400, body 13.
  static const authSubtitle = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Field label above input — Mono 500, caption.
  static const authInputLabel = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.35,
  );
}
