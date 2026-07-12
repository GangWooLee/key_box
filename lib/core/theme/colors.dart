import 'package:flutter/material.dart';

/// V8 Warm-Dark Olive color palette.
/// All rgba values are annotated in comments for auditability.
abstract final class AppColors {
  // ─── Brand (Olive/Moss Green) ───
  static const brand50 = Color(0xFFF0F4E8);
  static const brand100 = Color(0xFFE8F0DE);
  static const brand200 = Color(0xFFD0E0BC);
  static const brand300 = Color(0xFFB4C89A);
  static const brand400 = Color(0xFF7DB844);
  static const brand500 = Color(0xFF4A7A24);
  static const brand600 = Color(0xFF3A5A1C);
  static const brand700 = Color(0xFF283618); // Primary brand
  static const brand800 = Color(0xFF1E2A12);
  static const brand900 = Color(0xFF162212);
  static const brand950 = Color(0xFF0C1108);

  // ─── Light Theme (from :root) ───
  static const lightSurfacePrimary = Color(0xFFFFFFFF);
  static const lightSurfaceSecondary = Color(0xFFF7FAF4);
  static const lightSurfaceSidebar = Color(0xB3F0F4E8); // rgba(240,244,232,0.7)
  static const lightSurfaceCard = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF1A2712);
  static const lightTextSecondary = Color(0xFF5A6B4C);
  static const lightTextTertiary = Color(0xFF7A8C6A);
  static const lightBorderPrimary = Color(0xFFD0E0BC);
  static const lightBorderSubtle = Color(0xFFE8F0DE);
  static const lightBorderStrong = Color(0xFFB4C89A);

  // ─── Dark Theme Base ───
  static const darkSurfacePrimary = Color(0xFF0C1108);
  static const darkSurfaceSecondary = Color(0xFF080C05);
  static const darkSurfaceSidebar = Color(0x40111A0B); // rgba(17,26,11,0.25)
  static const darkSurfaceCard = Color(0xFF1A2712);
  static const darkTextPrimary = Color(0xFFE8EDE3);
  static const darkTextSecondary = Color(0xFF9CAF88);
  static const darkTextTertiary = Color(0xFF7A8C6A);
  static const darkTextQuaternary = Color(0xFF5A6B4C);
  static const darkBorderPrimary = Color(0x1AB4C8A0); // rgba(180,200,160,0.1)
  static const darkBorderSubtle = Color(0x0FB4C8A0); // rgba(180,200,160,0.06)
  static const darkBorderStrong = Color(0x40B4C8A0); // rgba(180,200,160,0.25)
  static const darkGlassBg = Color(0x8C1A2712); // rgba(26,39,18,0.55)
  static const darkGlassBorder = Color(0x33B4C8A0); // rgba(180,200,160,0.2)

  // ─── Dark Tonal Depth (sidebar lightest → detail darkest) ───
  static const darkSurfaceSidebarTonal = Color(0xFF111A0B);
  static const darkSurfaceListTonal = Color(0xFF0C1108);
  static const darkSurfaceDetailTonal = Color(0xFF080C05);

  // ─── Table ───
  static const darkTableHeaderBg = Color(0x0AB4C8A0); // rgba(180,200,160,0.04)
  static const darkTableHeaderStroke = Color(
    0x14B4C8A0,
  ); // rgba(180,200,160,0.08)
  static const darkTableRowSelected = Color(0x2E283618); // rgba(40,54,24,0.18)
  static const darkTableRowSeparator = Color(
    0x0DB4C8A0,
  ); // rgba(180,200,160,0.05)

  // ─── Sidebar ───
  static const darkSidebarSearchBg = Color(
    0x0FB4C8A0,
  ); // rgba(180,200,160,0.06)
  static const darkSidebarSearchStroke = Color(
    0x24B4C8A0,
  ); // rgba(180,200,160,0.14)
  static const darkCategoryActive = Color(0x14283618); // rgba(40,54,24,0.08)
  static const darkCategoryActiveBorder = Color(0xFF4A7A24);

  // ─── Detail Panel Glassmorphism ───
  static const darkDetailGradientStart = Color(
    0x1FC8DCB4,
  ); // rgba(200,220,180,0.12)
  static const darkDetailGradientEnd = Color(
    0x05C8DCB4,
  ); // rgba(200,220,180,0.02)
  static const darkDetailLeftBorder = Color(
    0x40B4C8A0,
  ); // rgba(180,200,160,0.25)

  // ─── Value Box ───
  static const darkValueBoxBg = Color(0x40283618); // rgba(40,54,24,0.25)
  static const darkValueBoxStroke = Color(0x26B4C8A0); // rgba(180,200,160,0.15)

  // ─── Environment Badges ───
  static const envProdBg = Color(0x1AEF4444); // rgba(239,68,68,0.1)
  static const envProdStroke = Color(0x4DEF4444); // rgba(239,68,68,0.3)
  static const envProdText = Color(0xFFFCA5A5);

  static const envDevBg = Color(0x1A10B981); // rgba(16,185,129,0.1)
  static const envDevStroke = Color(0x4D10B981); // rgba(16,185,129,0.3)
  static const envDevText = Color(0xFF6EE7B7);

  static const envStagingBg = Color(0x1AF59E0B); // rgba(245,158,11,0.1)
  static const envStagingStroke = Color(0x4DF59E0B); // rgba(245,158,11,0.3)
  static const envStagingText = Color(0xFFFCD34D);

  // ─── Row Attenuation (progressive text dimming) ───
  static const darkRowText1 = Color(0xFFE8EDE3); // Selected / first row
  static const darkRowText2 = Color(0xFFC4CEBC); // 2nd row
  static const darkRowText3 = Color(0xFFBCC7B4); // 3rd row
  static const darkRowText4 = Color(0xFFB4BFAC); // 4th+ row

  // ─── Service Dot Preset Colors (8) ───
  static const serviceDotColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Pink
    Color(0xFF0EA5E9), // Sky
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF43F5E), // Rose
  ];

  // ─── Auth Screen ───
  static const authCardBg = Color(0xFF141E0E);
  static const authCardStroke = Color(0x40B4C8A0); // rgba(180,200,160,0.25)
  static const authInputBg = Color(0xFF0C1108);

  // ─── Buttons ───
  static const buttonPrimary = Color(0xFF3A5A1C);
  static const buttonPrimaryText = Color(0xFFE8F0DE);

  // ─── Footer / Bottom Bar ───
  static const darkBottomBarBg = Color(0x800C1108); // rgba(12,17,8,0.5)
  static const darkBottomBarStroke = Color(
    0x14B4C8A0,
  ); // rgba(180,200,160,0.08)

  // ─── Dividers ───
  static const darkDividerSubtle = Color(0x0AB4C8A0); // rgba(180,200,160,0.04)
  static const darkDividerMedium = Color(0x14B4C8A0); // rgba(180,200,160,0.08)
  static const darkDividerStrong = Color(0x24B4C8A0); // rgba(180,200,160,0.14)

  // ─── Warning Box (auth) ───
  static const warningBoxBg = Color(0xFF1A1508);
  static const warningBoxStroke = Color(0x33F59E0B); // rgba(245,158,11,0.2)

  // ─── Semantic (status) ───
  static const success = Color(0xFF4A7A24);
  static const error = Color(0xFFDC2626);
  static const errorText = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  /// Get a service dot color by hashing the service name.
  static Color serviceDotColor(String serviceName) {
    return serviceDotColors[serviceName.hashCode.abs() %
        serviceDotColors.length];
  }
}
