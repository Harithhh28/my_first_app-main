import 'package:flutter/material.dart';

/// Central design token file for Rehab Ai.
/// Import this anywhere you need a shared color or style.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF090C14); // Primary dark canvas (home, plan, etc.)
  static const Color bgDark    = Color(0xFF0B0F19); // Welcome / auth screens
  static const Color bgCard    = Color(0xFF111827); // Card / input surfaces
  static const Color bgElevated= Color(0xFF131A2E); // Slightly raised surfaces (circles, chips)
  static const Color bgBorder  = Color(0xFF1E293B); // Dividers / inactive elements

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF4353FF); // Main accent blue (buttons, links)
  static const Color success   = Color(0xFF4ADE80); // Green (recovery, good form)
  static const Color warning   = Color(0xFFFACC15); // Yellow (AI plan, active plan label)
  static const Color danger    = Color(0xFFE50914); // Red (finish button, critical)
  static const Color orange    = Colors.orangeAccent; // Streak, fire icon

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // blueGrey[400] equivalent
  static const Color textMuted     = Color(0xFF64748B); // blueGrey[600] equivalent
}

/// The single ThemeData used across the whole app.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDeep,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.primary,
      secondary: AppColors.success,
      surface:   AppColors.bgCard,
      error:     AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.bgBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.bgBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall:  TextStyle(color: AppColors.textMuted),
    ),
  );
}
