import 'package:flutter/material.dart';

/// Color palette mapped 1:1 from application.css semantic tokens.
/// See docs/rails-reference/application.css for source of truth.
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

  // ─── Dark Theme (from [data-theme="dark"]) ───
  static const darkSurfacePrimary = Color(0xFF0C1108);
  static const darkSurfaceSecondary = Color(0xFF080C05);
  static const darkSurfaceSidebar = Color(0x40111A0B); // rgba(17,26,11,0.25)
  static const darkSurfaceCard = Color(0xFF1A2712);
  static const darkTextPrimary = Color(0xFFE8EDE3);
  static const darkTextSecondary = Color(0xFF9CAF88);
  static const darkTextTertiary = Color(0xFF7A8C6A);
  static const darkBorderPrimary = Color(0x1AB4C8A0); // rgba(180,200,160,0.1)
  static const darkBorderSubtle = Color(0x0FB4C8A0); // rgba(180,200,160,0.06)
  static const darkBorderStrong = Color(0x40B4C8A0); // rgba(180,200,160,0.25)
  static const darkGlassBg = Color(0x8C1A2712); // rgba(26,39,18,0.55)
  static const darkGlassBorder = Color(0x33B4C8A0); // rgba(180,200,160,0.2)

  // ─── Semantic (status) ───
  static const success = Color(0xFF4A7A24);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
}
