import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// The active surface's V9 token set, carried on [ThemeData] as a
/// [ThemeExtension]. Read it in widgets with
/// `Theme.of(context).extension<KbSurface>()!`.
///
/// Twelve fields cover the whole V9 palette per surface so screen code never
/// hardcodes hues (esp. `onAccent`: the terminal's `#F6F3EA` on `#5FB84E`
/// fails WCAG at 2.24:1 — always use [onAccent]).
@immutable
class KbSurface extends ThemeExtension<KbSurface> {
  const KbSurface({
    required this.canvas,
    required this.tray,
    required this.lamp,
    required this.hover,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.live,
    required this.onAccent,
    required this.error,
    required this.hairline,
    required this.scrim,
  });

  /// Main table / content surface.
  final Color canvas;

  /// Most-sunken face (sidebar / recessed fields).
  final Color tray;

  /// "Under the lamp" — brightest face (detail panel, selected row).
  final Color lamp;

  /// Row hover (a half-step below selection).
  final Color hover;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Accent — links, active, primary button fill.
  final Color accent;

  /// Live phosphor glow — copied, active dot, selection edge.
  final Color live;

  /// Label color on an [accent] fill.
  final Color onAccent;

  /// Error — warm clay (never an alarm red).
  final Color error;

  /// Hairline separators.
  final Color hairline;

  /// Modal dim — always the opposite luminance direction of the card.
  final Color scrim;

  @override
  KbSurface copyWith({
    Color? canvas,
    Color? tray,
    Color? lamp,
    Color? hover,
    Color? ink,
    Color? muted,
    Color? accent,
    Color? live,
    Color? onAccent,
    Color? error,
    Color? hairline,
    Color? scrim,
  }) {
    return KbSurface(
      canvas: canvas ?? this.canvas,
      tray: tray ?? this.tray,
      lamp: lamp ?? this.lamp,
      hover: hover ?? this.hover,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      live: live ?? this.live,
      onAccent: onAccent ?? this.onAccent,
      error: error ?? this.error,
      hairline: hairline ?? this.hairline,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  KbSurface lerp(ThemeExtension<KbSurface>? other, double t) {
    if (other is! KbSurface) return this;
    return KbSurface(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      tray: Color.lerp(tray, other.tray, t)!,
      lamp: Color.lerp(lamp, other.lamp, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      live: Color.lerp(live, other.live, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      error: Color.lerp(error, other.error, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// V9 surface themes. Auth state is the primary decider (locked ⇒ [sealed]);
/// when unlocked, `theme_provider` picks [bench] (light) or [terminal] (dark).
abstract final class AppTheme {
  // ─── Surface token sets ───

  /// SEALED — Slab. canvas=bg, tray=surface, lamp=elevated (DESIGN.md mapping).
  static const _slab = KbSurface(
    canvas: AppColors.slabBg,
    tray: AppColors.slabSurface,
    lamp: AppColors.slabElevated,
    hover: AppColors.slabElevated,
    ink: AppColors.slabText,
    muted: AppColors.slabMuted,
    accent: AppColors.slabAccent,
    live: AppColors.slabLive,
    onAccent: AppColors.slabOnAccent,
    error: AppColors.slabError,
    hairline: AppColors.slabHairline,
    scrim: AppColors.slabScrim,
  );

  /// OPEN·Light — Bench.
  static const _bench = KbSurface(
    canvas: AppColors.benchCanvas,
    tray: AppColors.benchTray,
    lamp: AppColors.benchLamp,
    hover: AppColors.benchHover,
    ink: AppColors.benchInk,
    muted: AppColors.benchMuted,
    accent: AppColors.benchAccent,
    live: AppColors.benchLive,
    onAccent: AppColors.benchOnAccent,
    error: AppColors.benchError,
    hairline: AppColors.benchHairline,
    scrim: AppColors.benchScrim,
  );

  /// OPEN·Dark — Terminal. accent == live (one phosphor).
  static const _terminal = KbSurface(
    canvas: AppColors.termCanvas,
    tray: AppColors.termTray,
    lamp: AppColors.termLamp,
    hover: AppColors.termHover,
    ink: AppColors.termText,
    muted: AppColors.termMuted,
    accent: AppColors.termAccent,
    live: AppColors.termAccent,
    onAccent: AppColors.termOnAccent,
    error: AppColors.termError,
    hairline: AppColors.termHairline,
    scrim: AppColors.termScrim,
  );

  // ─── Public surface constructors ───

  static ThemeData sealed() => _themeFor(Brightness.dark, _slab);

  static ThemeData bench() => _themeFor(Brightness.light, _bench);

  static ThemeData terminal() => _themeFor(Brightness.dark, _terminal);

  /// Legacy aliases (V8 two-theme API). `light` ⇒ bench, `dark` ⇒ terminal.
  static ThemeData light() => bench();
  static ThemeData dark() => terminal();

  // ─── Builder ───

  static ThemeData _themeFor(Brightness brightness, KbSurface s) {
    final scheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: s.accent,
            onPrimary: s.onAccent,
            secondary: s.live,
            onSecondary: s.onAccent,
            surface: s.canvas,
            onSurface: s.ink,
            error: s.error,
            onError: s.onAccent,
            outline: s.muted,
            outlineVariant: s.hairline,
          )
        : ColorScheme.light(
            primary: s.accent,
            onPrimary: s.onAccent,
            secondary: s.live,
            onSecondary: s.onAccent,
            surface: s.canvas,
            onSurface: s.ink,
            error: s.error,
            onError: s.onAccent,
            outline: s.muted,
            outlineVariant: s.hairline,
          );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: s.canvas,
      cardColor: s.lamp,
      dividerColor: s.hairline,
      textTheme: _textTheme(s.ink, s.muted),
      iconTheme: IconThemeData(color: s.muted, size: 20),
      inputDecorationTheme: _inputTheme(s),
      elevatedButtonTheme: _elevatedButtonTheme(s),
      outlinedButtonTheme: _outlinedButtonTheme(s),
      appBarTheme: AppBarTheme(
        backgroundColor: s.canvas,
        foregroundColor: s.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: [s],
    );
  }

  static TextTheme _textTheme(Color ink, Color muted) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: ink),
      titleLarge: AppTypography.titleLarge.copyWith(color: ink),
      titleMedium: AppTypography.titleMedium.copyWith(color: ink),
      titleSmall: AppTypography.titleSmall.copyWith(color: ink),
      bodyLarge: AppTypography.bodyMedium.copyWith(color: ink),
      bodyMedium: AppTypography.bodySmall.copyWith(color: ink),
      bodySmall: AppTypography.caption.copyWith(color: muted),
      labelLarge: AppTypography.bodySmall.copyWith(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(KbSurface s) {
    return InputDecorationTheme(
      filled: true,
      fillColor: s.tray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: s.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: s.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: s.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      hintStyle: TextStyle(
        fontFamily: AppTypography.sansFamily,
        fontSize: 14,
        color: s.muted,
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.sansFamily,
        fontSize: 14,
        color: s.muted,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(KbSurface s) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: s.accent,
        // CRITICAL (DESIGN.md): label uses the surface's onAccent, never a
        // hardcoded light. Terminal onAccent is dark ink.
        foregroundColor: s.onAccent,
        disabledBackgroundColor: s.accent.withValues(alpha: 0.4),
        disabledForegroundColor: s.onAccent.withValues(alpha: 0.4),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        minimumSize: const Size(kMinHitTarget, kMinHitTarget),
        textStyle: const TextStyle(
          fontFamily: AppTypography.sansFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(KbSurface s) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: s.accent,
        side: BorderSide(color: s.hairline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        minimumSize: const Size(kMinHitTarget, kMinHitTarget),
        textStyle: const TextStyle(
          fontFamily: AppTypography.sansFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
