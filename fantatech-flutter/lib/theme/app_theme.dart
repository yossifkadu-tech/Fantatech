import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary brand
  static const primary = Color(0xFF1A73E8);
  static const primaryDark = Color(0xFF1557B0);
  static const primaryLight = Color(0xFF4A90E2);

  // Status
  static const secured = Color(0xFF34A853);
  static const unsecured = Color(0xFFEA4335);
  static const warning = Color(0xFFFBBC04);

  // Dark theme — blue tones matching brand illustration (#1D75BD)
  static const darkBg = Color(0xFF0B2044);
  static const darkCard = Color(0xFF153060);
  static const darkCardAlt = Color(0xFF1E3D72);
  static const darkBorder = Color(0xFF2A5090);

  // Light theme
  static const lightBg = Color(0xFFF5F6FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE0E3EF);

  // Device type colors
  static const lightColor = Color(0xFFFFD60A);
  static const acColor = Color(0xFF00B4D8);
  static const plugColor = Color(0xFF7B2FBE);
  static const motionColor = Color(0xFFFF6B35);
  static const doorColor = Color(0xFF2D9CDB);
  static const cameraColor = Color(0xFF6C63FF);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkCard,
        surfaceContainerHighest: AppColors.darkCardAlt,
        onSurface: Colors.white,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // ── Fast button response ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      // ── Fast InkWell / ListTile taps ──────────────────────────────────────
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.white.withValues(alpha: 0.04),
      textTheme: GoogleFonts.heeboTextTheme(ThemeData.dark().textTheme),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.lightCard,
        onSurface: const Color(0xFF1A1D27),
        outline: AppColors.lightBorder,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: Color(0xFF1A1D27),
        elevation: 0,
        centerTitle: false,
      ),
      // ── Fast button response ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.black.withValues(alpha: 0.04),
      textTheme: GoogleFonts.heeboTextTheme(ThemeData.light().textTheme),
    );
  }
}
