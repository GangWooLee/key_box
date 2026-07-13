import 'package:flutter/material.dart';

/// V9 «SLAB & BENCH» color tokens — compiled from `docs/design/DESIGN.md`.
///
/// Three surfaces, one temperature: warm always (human/trust), only weight
/// (luminance) changes (safe/sealed). No cold hues. One phosphor green
/// (`#5FB84E`) threads all three surfaces.
///
///   SEALED  — "The Slab"     (locked: unlock, loading, vault-error)
///   OPEN·L  — "The Bench"     (unlocked, light mode)
///   OPEN·D  — "The Terminal"  (unlocked, dark mode)
///
/// rgba tokens are annotated with their source (DESIGN.md) opacity for audit.
/// The V9 tokens below are canonical; the legacy V8 aliases at the bottom exist
/// only so the 426 existing `AppColors.<name>` screen references keep compiling
/// during Phase A. **New screen code must use the V9 tokens (or the `KbSurface`
/// theme extension), never the legacy aliases.**
abstract final class AppColors {
  // ══════════════════════════════════════════════════════════════════════
  //  V9 CANONICAL TOKENS
  // ══════════════════════════════════════════════════════════════════════

  // ─── SEALED — Slab palette ───
  static const slabBg = Color(0xFF0B0D08); // background — dense single billet
  static const slabSurface = Color(0xFF12160E); // input fields · cards
  static const slabElevated = Color(0xFF1B2113); // focus/hover rise surface
  static const slabText = Color(0xFFE4E7DC); // primary text (~15:1)
  static const slabMuted = Color(0xFF79826C); // secondary text (4.8:1)
  static const slabAccent = Color(0xFF3E6B3A); // pilot light (dormant)
  static const slabLive = Color(0xFF5FB84E); // ignited (focus brightens pilot)
  static const slabError = Color(0xFFB87050); // wrong answer — warm clay, calm
  static const slabHairline = Color(0x14E4E7DC); // rgba(228,231,220,0.08)
  static const slabOnAccent = Color(0xFFE4E7DC); // label on accent fill
  static const slabScrim = Color(0x8C040503); // modal dim (shared warm-dark)

  // ─── OPEN·Light — Bench palette ───
  static const benchCanvas = Color(0xFFEDE9DE); // table canvas — warm paper
  static const benchTray = Color(0xFFE3DECF); // sidebar — most sunken face
  static const benchLamp = Color(0xFFF6F3EA); // detail panel · selected row
  static const benchHover = Color(0xFFF2EEE4); // row hover (half step < select)
  static const benchInk = Color(0xFF1A1D14); // primary text (ink)
  static const benchMuted = Color(0xFF5E6454); // secondary text
  static const benchAccent = Color(
    0xFF336E2C,
  ); // accent (text-safe) — links etc
  static const benchLive = Color(0xFF5FB84E); // live glow — copied · active dot
  static const benchOnAccent = Color(0xFFF6F3EA); // label on benchAccent fill
  static const benchError = Color(0xFF9A4A34); // error — oxidised clay
  static const benchHairline = Color(0x1A1A1D14); // rgba(26,29,20,0.10)
  static const benchScrim = Color(0x661A1D14); // rgba(26,29,20,0.40) modal dim

  // ─── OPEN·Dark — Terminal palette ───
  static const termCanvas = Color(0xFF12140E); // table canvas
  static const termTray = Color(0xFF0E100A); // sidebar — most sunken face
  static const termLamp = Color(0xFF22261A); // detail panel · selected row
  static const termHover = Color(0xFF191C12); // row hover (half step < select)
  static const termText = Color(0xFFE4E7DC); // primary text (shared w/ slab)
  static const termMuted = Color(0xFF909A80); // secondary (brighter than slab)
  static const termAccent = Color(0xFF5FB84E); // accent == live phosphor
  static const termOnAccent = Color(
    0xFF0B0D08,
  ); // label on termAccent = dark ink
  static const termError = Color(0xFFB87050); // error (shared w/ slab)
  static const termHairline = Color(0x14E4E7DC); // rgba(228,231,220,0.08)
  static const termScrim = Color(0x8C040503); // rgba(4,5,3,0.55) modal dim

  // ─── Phosphor green luminance scale (brand ramp, lightest → darkest) ───
  // Rebuilt around the live phosphor `#5FB84E` (brand400). No cold hues.
  static const phosphor50 = Color(0xFFEBF4E7);
  static const phosphor100 = Color(0xFFD8EACF);
  static const phosphor200 = Color(0xFFB4D6A6);
  static const phosphor300 = Color(0xFF8FC47D);
  static const phosphor400 = Color(0xFF5FB84E); // live phosphor — the signature
  static const phosphor500 = Color(0xFF4C9A3E);
  static const phosphor600 = Color(0xFF3E7B32);
  static const phosphor700 = Color(
    0xFF336E2C,
  ); // primary accent (== benchAccent)
  static const phosphor800 = Color(0xFF2A5825);
  static const phosphor900 = Color(0xFF1E3F1B);
  static const phosphor950 = Color(0xFF0B0D08); // darkest (== slabBg)

  // ─── Service dot presets (8) — phosphor · clay · warm-neutral, no cold ───
  static const serviceDotColors = [
    Color(0xFF5FB84E), // phosphor green
    Color(0xFFB87050), // clay / terracotta
    Color(0xFFC9A227), // warm amber / ochre
    Color(0xFF8FA76B), // sage olive
    Color(0xFF9A4A34), // deep clay / rust
    Color(0xFF6B9E35), // bright olive
    Color(0xFF79826C), // warm gray-olive
    Color(0xFFD98E5A), // warm tan / apricot
  ];

  // ══════════════════════════════════════════════════════════════════════
  //  LEGACY V8 ALIASES  →  V9 tokens
  //  Kept only so existing screen code compiles in Phase A. Do NOT use in
  //  new code — reference the V9 tokens above or the KbSurface extension.
  // ══════════════════════════════════════════════════════════════════════

  // ─── Brand scale → phosphor ramp ───
  static const brand50 = phosphor50; // legacy alias → phosphor50
  static const brand100 = phosphor100; // legacy alias → phosphor100
  static const brand200 = phosphor200; // legacy alias → phosphor200
  static const brand300 = phosphor300; // legacy alias → phosphor300
  static const brand400 = phosphor400; // legacy alias → phosphor400
  static const brand500 = phosphor500; // legacy alias → phosphor500
  static const brand600 = phosphor600; // legacy alias → phosphor600
  static const brand700 = phosphor700; // legacy alias → phosphor700
  static const brand800 = phosphor800; // legacy alias → phosphor800
  static const brand900 = phosphor900; // legacy alias → phosphor900
  static const brand950 = phosphor950; // legacy alias → phosphor950

  // ─── Light theme → bench ───
  static const lightSurfacePrimary = benchLamp; // legacy alias → benchLamp
  static const lightSurfaceSecondary =
      benchCanvas; // legacy alias → benchCanvas
  static const lightSurfaceSidebar = benchTray; // legacy alias → benchTray
  static const lightSurfaceCard = benchLamp; // legacy alias → benchLamp
  static const lightTextPrimary = benchInk; // legacy alias → benchInk
  static const lightTextSecondary = benchMuted; // legacy alias → benchMuted
  static const lightTextTertiary = benchMuted; // legacy alias → benchMuted
  static const lightBorderPrimary =
      benchHairline; // legacy alias → benchHairline
  static const lightBorderSubtle =
      benchHairline; // legacy alias → benchHairline
  static const lightBorderStrong =
      benchHairline; // legacy alias → benchHairline

  // ─── Dark theme base → terminal ───
  static const darkSurfacePrimary = termCanvas; // legacy alias → termCanvas
  static const darkSurfaceSecondary = termTray; // legacy alias → termTray
  static const darkSurfaceSidebar = termTray; // legacy alias → termTray
  static const darkSurfaceCard = termLamp; // legacy alias → termLamp
  static const darkTextPrimary = termText; // legacy alias → termText
  static const darkTextSecondary = termMuted; // legacy alias → termMuted
  static const darkTextTertiary = termMuted; // legacy alias → termMuted
  static const darkTextQuaternary = termMuted; // legacy alias → termMuted
  static const darkBorderPrimary = termHairline; // legacy alias → termHairline
  static const darkBorderSubtle = termHairline; // legacy alias → termHairline
  static const darkBorderStrong = termHairline; // legacy alias → termHairline
  static const darkGlassBg =
      termLamp; // legacy alias → termLamp (glass removed)
  static const darkGlassBorder = termHairline; // legacy alias → termHairline

  // ─── Dark tonal depth → terminal (light direction flips vs V8) ───
  static const darkSurfaceSidebarTonal = termTray; // legacy alias → termTray
  static const darkSurfaceListTonal = termCanvas; // legacy alias → termCanvas
  static const darkSurfaceDetailTonal = termLamp; // legacy alias → termLamp

  // ─── Table → terminal ───
  static const darkTableHeaderBg = termHairline; // legacy alias → termHairline
  static const darkTableHeaderStroke =
      termHairline; // legacy alias → termHairline
  static const darkTableRowSelected = termLamp; // legacy alias → termLamp
  static const darkTableRowSeparator =
      termHairline; // legacy alias → termHairline

  // ─── Sidebar → terminal ───
  static const darkSidebarSearchBg =
      termHairline; // legacy alias → termHairline
  static const darkSidebarSearchStroke =
      termHairline; // legacy alias → termHairline
  static const darkCategoryActive = termHover; // legacy alias → termHover
  static const darkCategoryActiveBorder =
      termAccent; // legacy alias → termAccent

  // ─── Detail panel (glassmorphism removed → solid lamp) ───
  static const darkDetailGradientStart = termLamp; // legacy alias → termLamp
  static const darkDetailGradientEnd = termLamp; // legacy alias → termLamp
  static const darkDetailLeftBorder =
      termHairline; // legacy alias → termHairline

  // ─── Value box → terminal (recessed field) ───
  static const darkValueBoxBg = termTray; // legacy alias → termTray
  static const darkValueBoxStroke = termHairline; // legacy alias → termHairline

  // ─── Environment badges → weight, not color (no bg/border; ink vs muted) ───
  static const envProdBg = Color(0x00000000); // legacy alias → transparent
  static const envProdStroke = Color(0x00000000); // legacy alias → transparent
  static const envProdText = termText; // legacy alias → ink (PROD = ink + 600)
  static const envDevBg = Color(0x00000000); // legacy alias → transparent
  static const envDevStroke = Color(0x00000000); // legacy alias → transparent
  static const envDevText = termMuted; // legacy alias → muted (DEV = muted 400)
  static const envStagingBg = Color(0x00000000); // legacy alias → transparent
  static const envStagingStroke = Color(
    0x00000000,
  ); // legacy alias → transparent
  static const envStagingText =
      termMuted; // legacy alias → muted (STG = muted 400)

  // ─── Row attenuation → terminal ───
  static const darkRowText1 = termText; // legacy alias → termText
  static const darkRowText2 = termText; // legacy alias → termText
  static const darkRowText3 = termMuted; // legacy alias → termMuted
  static const darkRowText4 = termMuted; // legacy alias → termMuted

  // ─── Auth screen → slab ───
  static const authCardBg = slabSurface; // legacy alias → slabSurface
  static const authCardStroke = slabHairline; // legacy alias → slabHairline
  static const authInputBg = slabBg; // legacy alias → slabBg (recessed input)

  // ─── Buttons → accent / onAccent ───
  static const buttonPrimary = benchAccent; // legacy alias → benchAccent
  static const buttonPrimaryText =
      benchOnAccent; // legacy alias → benchOnAccent

  // ─── Footer / bottom bar → terminal ───
  static const darkBottomBarBg = termTray; // legacy alias → termTray
  static const darkBottomBarStroke =
      termHairline; // legacy alias → termHairline

  // ─── Dividers → terminal ───
  static const darkDividerSubtle = termHairline; // legacy alias → termHairline
  static const darkDividerMedium = termHairline; // legacy alias → termHairline
  static const darkDividerStrong = termHairline; // legacy alias → termHairline

  // ─── Warning box (auth) → slab (warning color removed; neutral rise) ───
  static const warningBoxBg = slabElevated; // legacy alias → slabElevated
  static const warningBoxStroke = slabHairline; // legacy alias → slabHairline

  // ─── Semantic → DESIGN.md rules (success=phosphor, error=clay, no warning) ───
  static const success = phosphor400; // legacy alias → phosphor live (#5FB84E)
  static const error = slabError; // legacy alias → clay (#B87050)
  static const errorText = slabError; // legacy alias → clay (#B87050)
  static const warning =
      slabError; // legacy alias → error clay (no warning color)
  static const info = termMuted; // legacy alias → muted (#909A80)

  /// Get a service dot color by hashing the service name.
  static Color serviceDotColor(String serviceName) {
    return serviceDotColors[serviceName.hashCode.abs() %
        serviceDotColors.length];
  }
}
