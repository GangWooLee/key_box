import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand700,
        onPrimary: AppColors.brand100,
        secondary: AppColors.brand600,
        onSecondary: Colors.white,
        surface: AppColors.lightSurfacePrimary,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.lightBorderPrimary,
        outlineVariant: AppColors.lightBorderSubtle,
      ),
      scaffoldBackgroundColor: AppColors.lightSurfaceSecondary,
      cardColor: AppColors.lightSurfaceCard,
      dividerColor: AppColors.lightBorderSubtle,
      textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary, size: 20),
      inputDecorationTheme: _inputTheme(Brightness.light),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurfacePrimary,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand400,
        onPrimary: AppColors.brand950,
        secondary: AppColors.brand600,
        onSecondary: AppColors.darkTextPrimary,
        surface: AppColors.darkSurfacePrimary,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkBorderPrimary,
        outlineVariant: AppColors.darkBorderSubtle,
      ),
      scaffoldBackgroundColor: AppColors.darkSurfaceSecondary,
      cardColor: AppColors.darkSurfaceCard,
      dividerColor: AppColors.darkBorderSubtle,
      textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary, size: 20),
      inputDecorationTheme: _inputTheme(Brightness.dark),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurfacePrimary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: primary),
      titleLarge: AppTypography.titleLarge.copyWith(color: primary),
      titleMedium: AppTypography.titleMedium.copyWith(color: primary),
      titleSmall: AppTypography.titleSmall.copyWith(color: primary),
      bodyLarge: AppTypography.bodyMedium.copyWith(color: primary),
      bodyMedium: AppTypography.bodySmall.copyWith(color: primary),
      bodySmall: AppTypography.caption.copyWith(color: secondary),
      labelLarge: AppTypography.bodySmall.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return InputDecorationTheme(
      filled: true,
      fillColor: isLight ? AppColors.lightSurfacePrimary : AppColors.darkSurfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isLight ? AppColors.lightBorderPrimary : AppColors.darkBorderStrong,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isLight ? AppColors.lightBorderPrimary : AppColors.darkBorderPrimary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isLight ? AppColors.brand700 : AppColors.brand400,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand600,
        foregroundColor: AppColors.brand100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(44, 44), // Accessibility: min touch target
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
