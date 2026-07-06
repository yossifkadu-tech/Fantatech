import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/device.dart';

// ─── Custom page transition ───────────────────────────────────────────────────
// Replaces the default Android slide with a subtle fade + upward drift.
// Feels closer to iOS / macOS than the default lateral push.
class _FadeSlideBuilder implements PageTransitionsBuilder {
  const _FadeSlideBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  DelegatedTransitionBuilder? get delegatedTransition => null;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class AppColors {
  // ── FantaTech brand identity ───────────────────────────────────
  static const primary      = Color(0xFFFF6B00); // signature orange
  static const primaryDark  = Color(0xFFCC6200); // pressed / dark variant
  static const primaryLight = Color(0xFFFF9533); // hover / light variant
  static const secondary    = Color(0xFF003399); // dark blue (accent / CTA)
  static const secondaryLight = Color(0xFF0052CC); // lighter dark blue

  // ── Semantic status colors ─────────────────────────────────────
  static const success   = Color(0xFF16A34A); // green-700
  static const successLight = Color(0xFFDCFCE7); // green-100 surface
  static const warning   = Color(0xFFD97706); // amber-600
  static const warningLight = Color(0xFFFEF3C7); // amber-100 surface
  static const alert     = Color(0xFFDC2626); // red-600
  static const alertLight  = Color(0xFFFEE2E2); // red-100 surface
  static const danger    = alert;
  // Security aliases map onto the semantic palette.
  static const secured   = success;
  static const unsecured = alert;

  // ── Text ──────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0F172A); // slate-900
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const textTertiary  = Color(0xFF94A3B8); // slate-400

  // ── Dark theme — DEEP NAVY ────────────────────────────────────
  static const darkBlue    = Color(0xFF0A0F1E); // deepest navy
  static const darkBg      = darkBlue;
  static const darkSurface = Color(0xFF0F172A); // slate-900
  static const darkCard    = Color(0xFF1E293B); // slate-800
  static const darkCardAlt = Color(0xFF263348); // mid-lift
  static const darkBorder  = Color(0xFF334155); // slate-700

  // ── Light theme — spec: #F7F8FC background ────────────────────
  static const background  = Color(0xFFF7F8FC); // design spec
  static const lightBg     = background;
  static const lightSurface = Color(0xFFF0F2F8); // slightly deeper
  static const lightCard   = Color(0xFFFFFFFF); // pure-white cards
  static const lightBorder = Color(0xFFE2E8F0); // slate-200

  // ── Device-type accent colors ─────────────────────────────────
  static const lightColor  = Color(0xFFF59E0B); // warm amber lights
  static const acColor     = Color(0xFF06B6D4); // cyan climate
  static const plugColor   = Color(0xFF8B5CF6); // violet plugs
  static const motionColor = Color(0xFFF97316); // orange motion
  static const doorColor   = Color(0xFF38BDF8); // sky door/window
  static const cameraColor = Color(0xFF6366F1); // indigo cameras
  static const solarColor         = Color(0xFFEAB308); // yellow solar
  static const lockColor          = Color(0xFF14B8A6); // teal lock
  static const networkColor       = Color(0xFF00B4D8); // cyan  — network/IoT/water
  static const smokeColor         = Color(0xFFFF6B35); // orange-red — smoke/fire/glass
  static const energyColor        = Color(0xFFFFD600); // yellow — energy meters
  static const circuitBreakerColor = Color(0xFF7BB8FF); // light-blue — breakers
  static const matterColor        = Color(0xFF7B6FCD); // medium-purple — Matter
  static const networkDeviceColor = Color(0xFF5C6BC0); // indigo — phones/tablets
  static const printerColor       = Color(0xFF78909C); // blue-gray — printers
  static const garageColor        = Color(0xFF546E7A); // dark-blue-gray — garages
  static const cyberColor         = Color(0xFF00E5FF); // vivid-cyan — cyber/network monitor

  // ── Six-state status palette ──────────────────────────────────
  // Dot / icon colors (vivid, readable on any bg)
  static const statusOnline  = Color(0xFF26A69A); // turquoise  — Normal
  static const statusWarning = Color(0xFFFB8C00); // orange     — Warning
  static const statusAlert   = Color(0xFFFFD54F); // yellow     — Alert
  static const statusAlarm   = Color(0xFFE53935); // red        — Danger
  static const statusInfo    = Color(0xFF1E88E5); // blue       — Information
  static const statusOffline = Color(0xFF757575); // gray       — Inactive

  // Surface / chip bg colors (light theme — pastel washes)
  static const statusOnlineSurface  = Color(0xFFE0F2F1); // teal-50
  static const statusWarningSurface = Color(0xFFFFF3E0); // orange-50
  static const statusAlertSurface   = Color(0xFFFFFDE7); // yellow-50
  static const statusAlarmSurface   = Color(0xFFFFEBEE); // red-50
  static const statusInfoSurface    = Color(0xFFE3F2FD); // blue-50
  static const statusOfflineSurface = Color(0xFFFAFAFA); // gray-50
}

// ─── Status Color Utility ────────────────────────────────────────────────────

/// Maps the six semantic status states to their color tokens.
///
/// Usage:
///   AppStatusColors.dot(device.status)       → primary dot/icon color
///   AppStatusColors.surface(device.status)   → light-theme chip/badge bg
///   AppStatusColors.darkSurface(device.status) → dark-theme chip/badge bg
///   AppStatusColors.icon(device.status)      → representative Symbols icon
class AppStatusColors {
  AppStatusColors._();

  // Primary dot / icon color per status.
  static Color dot(DeviceStatus s) => switch (s) {
    DeviceStatus.online  => AppColors.statusOnline,
    DeviceStatus.offline => AppColors.statusOffline,
    DeviceStatus.warning => AppColors.statusWarning,
    DeviceStatus.alert   => AppColors.statusAlert,
    DeviceStatus.alarm   => AppColors.statusAlarm,
    DeviceStatus.info    => AppColors.statusInfo,
  };

  // Pastel surface for light-theme chips / banners.
  static Color surface(DeviceStatus s) => switch (s) {
    DeviceStatus.online  => AppColors.statusOnlineSurface,
    DeviceStatus.offline => AppColors.statusOfflineSurface,
    DeviceStatus.warning => AppColors.statusWarningSurface,
    DeviceStatus.alert   => AppColors.statusAlertSurface,
    DeviceStatus.alarm   => AppColors.statusAlarmSurface,
    DeviceStatus.info    => AppColors.statusInfoSurface,
  };

  // Translucent surface for dark-theme chips / banners.
  static Color darkSurface(DeviceStatus s) =>
      dot(s).withValues(alpha: 0.14);

  // Context-aware surface (picks light vs dark automatically).
  static Color adaptiveSurface(DeviceStatus s, BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface(s)
          : surface(s);

  // Representative icon for each status (uses Material Symbols Rounded).
  static IconData icon(DeviceStatus s) => switch (s) {
    DeviceStatus.online  => Symbols.check_circle,
    DeviceStatus.offline => Symbols.wifi_off,
    DeviceStatus.warning => Symbols.warning,
    DeviceStatus.alert   => Symbols.notifications_active,
    DeviceStatus.alarm   => Symbols.crisis_alert,
    DeviceStatus.info    => Symbols.info,
  };

  // "Information" blue — also accessible as a standalone constant.
  static const info        = AppColors.statusInfo;
  static const infoSurface = AppColors.statusInfoSurface;
  static Color infoDarkSurface() =>
      AppColors.statusInfo.withValues(alpha: 0.14);
}

// ─── Design Tokens ────────────────────────────────────────────────────────────

/// Spacing scale — ONLY these values should be used throughout the app.
/// Never use arbitrary numbers.
class AppSpacing {
  const AppSpacing._();

  static const double s4  = 4;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  // Common edge insets
  static const EdgeInsets p4  = EdgeInsets.all(4);
  static const EdgeInsets p8  = EdgeInsets.all(8);
  static const EdgeInsets p12 = EdgeInsets.all(12);
  static const EdgeInsets p16 = EdgeInsets.all(16);
  static const EdgeInsets p24 = EdgeInsets.all(24);
  static const EdgeInsets p32 = EdgeInsets.all(32);

  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets v8  = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: 16);

  static const EdgeInsets card = EdgeInsets.all(16);
  static const EdgeInsets cardLg = EdgeInsets.all(24);
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
}

/// Typography scale — Display → Caption.
/// Always prefer these over raw TextStyle literals.
class AppTypography {
  const AppTypography._();

  // ── Display — hero numbers, bento tiles ───────────────────────
  static const TextStyle displayLg = TextStyle(
    fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2.0, height: 1.1,
  );
  static const TextStyle displayMd = TextStyle(
    fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.15,
  );
  static const TextStyle displaySm = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.2,
  );

  // ── Headline — screen titles ───────────────────────────────────
  static const TextStyle headlineLg = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.25,
  );
  static const TextStyle headlineMd = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.3,
  );
  static const TextStyle headlineSm = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.35,
  );

  // ── Title — card titles, section headers ───────────────────────
  static const TextStyle titleLg = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.4,
  );
  static const TextStyle titleMd = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.4,
  );
  static const TextStyle titleSm = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4,
  );

  // ── Subtitle ──────────────────────────────────────────────────
  static const TextStyle subtitleLg = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0, height: 1.5,
  );
  static const TextStyle subtitleMd = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0, height: 1.5,
  );

  // ── Body ──────────────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.6,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.6,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.6,
  );

  // ── Caption / Label ───────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3, height: 1.5,
  );
  static const TextStyle labelLg = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.4,
  );
  static const TextStyle labelMd = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, height: 1.4,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6, height: 1.4,
  );
}

/// Shadow presets — use these instead of inline BoxShadow lists.
class AppShadows {
  const AppShadows._();

  /// Barely-there lift — for cards on light bg.
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Standard card elevation.
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8,  offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Elevated card / modal.
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 32, offset: Offset(0, 8)),
  ];

  /// Hero panel / bottom sheet.
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 48, offset: Offset(0, 16)),
  ];

  /// Coloured glow for active devices.
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.22 * intensity),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.10 * intensity),
      blurRadius: 36,
      spreadRadius: 4,
    ),
  ];

  /// Dark mode card shadow (subtle — dark surfaces absorb light).
  static const List<BoxShadow> dark = [
    BoxShadow(color: Color(0x28000000), blurRadius: 12, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 6)),
  ];
}

/// Border-radius constants aligned to the card-radius system.
class AppBorderRadius {
  const AppBorderRadius._();

  static const double r4  = 4;
  static const double r8  = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;

  static const BorderRadius card    = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius cardLg  = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius chip    = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius button  = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius icon    = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius input   = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius sheet   = BorderRadius.only(
    topLeft:  Radius.circular(r24),
    topRight: Radius.circular(r24),
  );
}

// ─── Theme preference enums ───────────────────────────────────────────────────

enum AppFont { inter, heebo, rubik, notoSans, assistant }

enum AppBgStyle { darkBlue, amoled, darkGray, lightGray, lightWhite }

extension AppBgStyleExt on AppBgStyle {
  bool get isLight => this == AppBgStyle.lightGray || this == AppBgStyle.lightWhite;
}

enum AppRadius { sharp, normal, round }

// ─── Accent color presets ─────────────────────────────────────────────────────

const accentPresets = <Color>[
  Color(0xFFFF6B00), // Orange (FantaTech default)
  Color(0xFF0066FF), // Deep Blue
  Color(0xFF3B82F6), // Vivid blue
  Color(0xFF10B981), // Emerald
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFF06B6D4), // Cyan
];

// ─── AppThemePrefs ────────────────────────────────────────────────────────────

class AppThemePrefs {
  final AppFont font;
  final Color accent;
  final AppBgStyle bgStyle;
  final AppRadius radius;

  const AppThemePrefs({
    this.font   = AppFont.inter,
    this.accent = AppColors.primary,        // #FF7A00 signature orange
    this.bgStyle = AppBgStyle.darkBlue,      // soft-charcoal single look
    this.radius  = AppRadius.normal,
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
            orElse: () => AppFont.inter),
        accent: Color(m['accent'] as int? ?? 0xFF0066FF),
        bgStyle: AppBgStyle.values.firstWhere((e) => e.name == m['bgStyle'],
            orElse: () => AppBgStyle.darkBlue),
        radius: AppRadius.values.firstWhere((e) => e.name == m['radius'],
            orElse: () => AppRadius.normal),
      );
}

// ─── AppTheme ─────────────────────────────────────────────────────────────────

class AppTheme {
  /// Builds the TextTheme for a given font selection.
  ///
  /// For [AppFont.inter] we use Inter as the primary face for Latin/numbers
  /// and add Heebo as an automatic fallback for Hebrew glyphs — giving the
  /// crisp modern number rendering Inter is known for while keeping full
  /// Hebrew support.  All other fonts include the same Heebo fallback so
  /// Hebrew characters always render correctly.
  /// Script-coverage fallback chain. The Latin fonts (Inter/Rubik/…) and
  /// Heebo (Hebrew) carry no Arabic or Ge'ez (Amharic) glyphs, so without
  /// these Noto fallbacks those scripts render as tofu boxes / question marks.
  /// Computed once and reused for every font option.
  static const List<String> _scriptFallback = <String>[
    'Heebo',            // Hebrew (via GoogleFonts cache)
    'NotoSansArabic',   // Arabic — bundled asset (offline-safe)
    'NotoSansEthiopic', // Amharic / Ge'ez — bundled asset (offline-safe)
  ];

  static TextTheme _textTheme(AppFont font, TextTheme base) {
    final TextTheme t;
    switch (font) {
      case AppFont.inter:
        t = GoogleFonts.interTextTheme(base);
      case AppFont.rubik:
        t = GoogleFonts.rubikTextTheme(base);
      case AppFont.notoSans:
        t = GoogleFonts.notoSansTextTheme(base);
      case AppFont.assistant:
        t = GoogleFonts.assistantTextTheme(base);
      case AppFont.heebo:
        t = GoogleFonts.heeboTextTheme(base);
    }
    // Apply universal script fallbacks so Arabic + Amharic always have glyphs.
    return _bolder(t.apply(fontFamilyFallback: _scriptFallback));
  }

  /// Bumps font weights and tightens letter-spacing on headings for a
  /// modern premium feel. Inter's optical metrics need slightly more
  /// negative tracking than Heebo/Rubik at display sizes.
  static TextTheme _bolder(TextTheme t) {
    // Detect Inter by checking the primary font family name
    final isInter = (t.bodyMedium?.fontFamily ?? '').toLowerCase().contains('inter');
    final titleLargeSpacing  = isInter ? -1.2 : -0.8;
    final titleMediumSpacing = isInter ? -0.6 : -0.4;
    final titleSmallSpacing  = isInter ? -0.3 : -0.2;

    return t.copyWith(
      bodyLarge:   t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium:  t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall:   t.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      titleLarge:  t.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: titleLargeSpacing,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: titleMediumSpacing,
      ),
      titleSmall:  t.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: titleSmallSpacing,
      ),
      // Display styles — used for bento tile numbers
      displayLarge:  t.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: isInter ? -2.0 : -1.0,
      ),
      displayMedium: t.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: isInter ? -1.5 : -0.8,
      ),
      displaySmall:  t.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: isInter ? -1.0 : -0.5,
      ),
      labelLarge:  t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static double _cardRadius(AppRadius r) {
    switch (r) {
      case AppRadius.sharp:  return 6;
      case AppRadius.normal: return 16;
      case AppRadius.round:  return 26;
    }
  }

  static ({Color bg, Color card, Color cardAlt, Color border}) _lightColors(
      AppBgStyle s) {
    switch (s) {
      case AppBgStyle.lightWhite:
        return (
          bg:      const Color(0xFFFFFFFF),   // pure white
          card:    const Color(0xFFF5F7FA),   // subtle gray cards
          cardAlt: const Color(0xFFEDF1F6),
          border:  const Color(0xFFEAEDF2),
        );
      case AppBgStyle.lightGray:
      default:
        return (
          bg:      AppColors.background,       // #F7F8FC design spec
          card:    AppColors.lightCard,         // pure-white cards
          cardAlt: AppColors.lightSurface,      // #F0F2F8
          border:  AppColors.lightBorder,       // slate-200
        );
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
      // Light styles selected while dark theme is active → fall back to darkBlue
      case AppBgStyle.lightGray:
      case AppBgStyle.lightWhite:
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        height: 66,
        indicatorColor: accent.withValues(alpha: 0.20),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.2,
            height: 1.2,
            color: sel ? accent : const Color(0xFF6B7280),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? accent : const Color(0xFF6B7280),
            size: 22,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: accent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.white.withValues(alpha: 0.04),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _FadeSlideBuilder(),
        TargetPlatform.iOS:     _FadeSlideBuilder(),
        TargetPlatform.fuchsia: _FadeSlideBuilder(),
      }),
      textTheme: _textTheme(prefs.font, ThemeData.dark().textTheme),
    );
  }

  static ThemeData light([AppThemePrefs prefs = const AppThemePrefs()]) {
    final r  = _cardRadius(prefs.radius);
    final accent = prefs.accent;
    // Choose light palette based on bgStyle (fallback for dark styles → lightGray)
    final c  = _lightColors(prefs.bgStyle.isLight ? prefs.bgStyle : AppBgStyle.lightGray);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent.withValues(alpha: 0.7),
        surface: c.card,
        onSurface: AppColors.textPrimary,
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
        foregroundColor: AppColors.textPrimary,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        height: 66,
        indicatorColor: accent.withValues(alpha: 0.12),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.2,
            height: 1.2,
            color: sel ? accent : const Color(0xFF6B7280),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? accent : const Color(0xFF6B7280),
            size: 22,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: const Duration(milliseconds: 60),
          splashFactory: InkRipple.splashFactory,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: accent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.black.withValues(alpha: 0.04),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _FadeSlideBuilder(),
        TargetPlatform.iOS:     _FadeSlideBuilder(),
        TargetPlatform.fuchsia: _FadeSlideBuilder(),
      }),
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
  Color get tCard => Theme.of(this).cardColor;

  /// Slightly raised alternate surface.
  Color get tCardAlt => Theme.of(this).colorScheme.surfaceContainerHighest;

  /// Hairline border / divider.
  Color get tBorder => Theme.of(this).colorScheme.outline;

  /// Primary neutral text/icon color (high contrast on page & cards).
  Color get tText => isLight ? AppColors.textPrimary : Colors.white;

  /// Secondary neutral text — captions, subtitles, metadata.
  Color get tTextSecondary =>
      isLight ? AppColors.textSecondary : Colors.white.withValues(alpha: 0.60);

  /// Primary neutral text at a given opacity (replaces Colors.white.withValues).
  Color tText2(double a) => tText.withValues(alpha: a);
}
