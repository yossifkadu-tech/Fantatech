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

// ─── Theme preference enums ───────────────────────────────────────────────────

enum AppFont { heebo, rubik, notoSans, assistant }

enum AppBgStyle { darkBlue, amoled, darkGray }

enum AppRadius { sharp, normal, round }

// ─── Accent color presets ─────────────────────────────────────────────────────

const accentPresets = <Color>[
  Color(0xFF1A73E8), // Blue (default)
  Color(0xFF34A853), // Green
  Color(0xFF7B2FBE), // Purple
  Color(0xFFFF6B35), // Orange
  Color(0xFFE91E8C), // Pink
  Color(0xFF00B4D8), // Teal
];

// ─── AppThemePrefs ────────────────────────────────────────────────────────────

class AppThemePrefs {
  final AppFont font;
  final Color accent;
  final AppBgStyle bgStyle;
  final AppRadius radius;

  const AppThemePrefs({
    this.font = AppFont.heebo,
    this.accent = const Color(0xFF1A73E8),
    this.bgStyle = AppBgStyle.darkBlue,
    this.radius = AppRadius.normal,
  });

  AppThemePrefs copyWith({
    AppFont? font,
    Color? accent,
    AppBgStyle? bgStyle,
    AppRadius? radius,
  }) =>
      AppThemePrefs(
        font: font ?? this.font,
        accent: accent ?? this.accent,
        bgStyle: bgStyle ?? this.bgStyle,
        radius: radius ?? this.radius,
      );

  // Persistence helpers
  Map<String, dynamic> toMap() => {
        'font': font.name,
        'accent': accent.toARGB32(),
        'bgStyle': bgStyle.name,
        'radius': radius.name,
      };

  factory AppThemePrefs.fromMap(Map<String, dynamic> m) => AppThemePrefs(
        font: AppFont.values.firstWhere((e) => e.name == m['font'],
            orElse: () => AppFont.heebo),
        accent: Color(m['accent'] as int? ?? 0xFF1A73E8),
        bgStyle: AppBgStyle.values.firstWhere((e) => e.name == m['bgStyle'],
            orElse: () => AppBgStyle.darkBlue),
        radius: AppRadius.values.firstWhere((e) => e.name == m['radius'],
            orElse: () => AppRadius.normal),
      );
}

// ─── AppTheme ─────────────────────────────────────────────────────────────────

class AppTheme {
  static TextTheme _textTheme(AppFont font, TextTheme base) {
    final TextTheme t;
    switch (font) {
      case AppFont.rubik:
        t = GoogleFonts.rubikTextTheme(base);
      case AppFont.notoSans:
        t = GoogleFonts.notoSansTextTheme(base);
      case AppFont.assistant:
        t = GoogleFonts.assistantTextTheme(base);
      case AppFont.heebo:
        t = GoogleFonts.heeboTextTheme(base);
    }
    return _bolder(t);
  }

  /// Bumps font weights up a notch app-wide for a stronger, more legible look.
  static TextTheme _bolder(TextTheme t) => t.copyWith(
        bodyLarge:   t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium:  t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        bodySmall:   t.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        titleLarge:  t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall:  t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge:  t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      );

  static double _cardRadius(AppRadius r) {
    switch (r) {
      case AppRadius.sharp:  return 6;
      case AppRadius.normal: return 16;
      case AppRadius.round:  return 26;
    }
  }

  static ({Color bg, Color card, Color cardAlt, Color border}) _darkColors(
      AppBgStyle s) {
    switch (s) {
      case AppBgStyle.amoled:
        return (
          bg: const Color(0xFF000000),
          card: const Color(0xFF0D0D0D),
          cardAlt: const Color(0xFF171717),
          border: const Color(0xFF2A2A2A),
        );
      case AppBgStyle.darkGray:
        return (
          bg: const Color(0xFF111318),
          card: const Color(0xFF1C1F26),
          cardAlt: const Color(0xFF252830),
          border: const Color(0xFF353840),
        );
      case AppBgStyle.darkBlue:
        return (
          bg: AppColors.darkBg,
          card: AppColors.darkCard,
          cardAlt: AppColors.darkCardAlt,
          border: AppColors.darkBorder,
        );
    }
  }

  static ThemeData dark([AppThemePrefs prefs = const AppThemePrefs()]) {
    final c = _darkColors(prefs.bgStyle);
    final r = _cardRadius(prefs.radius);
    final accent = prefs.accent;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent.withValues(alpha: 0.7),
        surface: c.card,
        surfaceContainerHighest: c.cardAlt,
        onSurface: Colors.white,
        outline: c.border,
      ),
      scaffoldBackgroundColor: c.bg,
      cardColor: c.card,
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.card,
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.white.withValues(alpha: 0.04),
      textTheme: _textTheme(prefs.font, ThemeData.dark().textTheme),
    );
  }

  static ThemeData light([AppThemePrefs prefs = const AppThemePrefs()]) {
    final r = _cardRadius(prefs.radius);
    final accent = prefs.accent;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent.withValues(alpha: 0.7),
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
          borderRadius: BorderRadius.circular(r),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: Color(0xFF1A1D27),
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.10), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.black.withValues(alpha: 0.04),
      textTheme: _textTheme(prefs.font, ThemeData.light().textTheme),
    );
  }
}

/// Theme-aware colors resolved from the current BuildContext brightness.
/// Use these in screens instead of hardcoded dark colors so that light mode
/// renders correctly. Accent/device colors stay as-is; only surfaces and
/// neutral text should switch.
extension AppThemeColors on BuildContext {
  bool get isLight => Theme.of(this).brightness == Brightness.light;

  /// Page (scaffold) background.
  Color get tBg => Theme.of(this).scaffoldBackgroundColor;

  /// Card / panel surface.
  Color get tCard =>
      isLight ? AppColors.lightCard : AppColors.darkCard;

  /// Slightly raised alternate surface.
  Color get tCardAlt =>
      isLight ? const Color(0xFFEDEFF5) : AppColors.darkCardAlt;

  /// Hairline border / divider.
  Color get tBorder =>
      isLight ? AppColors.lightBorder : AppColors.darkBorder;

  /// Primary neutral text/icon color (high contrast on page & cards).
  Color get tText => isLight ? const Color(0xFF1A1D27) : Colors.white;

  /// Primary neutral text at a given opacity (replaces Colors.white.withValues).
  Color tText2(double a) => tText.withValues(alpha: a);
}
