/// Krizot Material 3 theme configuration.
///
/// Implements the design system defined in the UI/UX spec:
/// - Deep Navy primary, Electric Blue accent
/// - Inter font family
/// - Custom text theme
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides the app-wide [ThemeData].
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

  /// Light theme (primary theme for Krizot).
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: AppColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: _fontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: _fontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: _fontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontFamily: _fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontFamily: _fontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: _fontFamily,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          fontFamily: _fontFamily,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
