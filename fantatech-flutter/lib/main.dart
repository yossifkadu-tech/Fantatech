import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_state.dart';
import 'providers/layout_provider.dart';
import 'models/app_user.dart';
import 'services/auth/user_service.dart';
import 'services/ha/ha_config.dart';
import 'services/ha/ha_provider.dart';
import 'services/ha/ha_token_receiver.dart';
import 'services/storage/secure_cred_service.dart';
import 'backend/backend_service.dart';
import 'services/auth/biometric_service.dart';
import 'services/discovery/real_discovery_engine.dart';
import 'services/gateways/gateway_manager.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/security/security_screen.dart';
import 'screens/cameras/cameras_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/smarthome/smarthome_screen.dart';
import 'screens/automations/automations_screen.dart';
import 'services/push/ha_push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) MediaKit.ensureInitialized();
  await BackendService.init(); // no-op until SUPABASE_URL/ANON_KEY are provided
  await UserService.init();

  // Push notifications — init early so Firebase background handler is registered
  if (!kIsWeb) unawaited(HaPushService.instance.init());
  // Allow the screen to rotate freely (portrait + landscape).
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final gateways      = GatewayManager();
  final appState      = AppState()..attachGateways(gateways);
  final haProvider    = HaProvider();
  final layoutProvider = LayoutProvider();
  await layoutProvider.init(); // load persisted layouts before first frame

  // Wire AppState to receive live entity updates from HaProvider.
  appState.attachHaProvider(haProvider);

  // Attach push service to HaProvider so it can subscribe to WS events.
  HaPushService.instance.attachHaProvider(haProvider);

  // Auto-connect HA from credentials saved in the previous session.
  final savedIp    = await SecureCredService.readHaIp();
  final savedToken = await SecureCredService.readHaToken();
  if (savedIp != null && savedIp.isNotEmpty &&
      savedToken != null && savedToken.isNotEmpty) {
    final haUrl = savedIp.startsWith('http') ? savedIp : 'http://$savedIp:8123';
    unawaited(haProvider.connect(HaConfig(baseUrl: haUrl, token: savedToken)));
  }

  // כשרץ כ-Flutter Web בתוך HA iframe — קבל token אוטומטית
  if (kIsWeb) {
    HaTokenReceiver.init();
    HaTokenReceiver.onToken.listen((data) {
      final baseUrl = data['hassUrl'] as String? ?? '';
      final token   = data['token']   as String? ?? '';
      if (baseUrl.isEmpty || token.isEmpty) return;
      haProvider.connect(HaConfig(baseUrl: baseUrl, token: token));
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: layoutProvider),
        ChangeNotifierProvider(create: (_) => RealDiscoveryEngine()),
        ChangeNotifierProvider.value(value: gateways),
        ChangeNotifierProvider.value(value: haProvider),
        ChangeNotifierProvider.value(value: HaPushService.instance),
      ],
      child: const FantaTechApp(),
    ),
  );
}

class FantaTechApp extends StatelessWidget {
  const FantaTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'FantaTech',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: AppTheme.light(state.themePrefs),
      darkTheme: AppTheme.dark(state.themePrefs),
      locale: state.flutterLocale,
      supportedLocales: const [
        Locale('he'),
        Locale('en'),
        Locale('ar'),
        Locale('am'),
        Locale('es'),
        Locale('ru'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Sits between the Navigator and every route it displays — this is
      // the only place a single fade mask can cover ALL screens (including
      // ones reached via Navigator.push, like RegisterScreen) rather than
      // just whichever screen happens to own the AnimationController.
      builder: (context, child) => _LocaleFadeMask(child: child!),
      home: const RootGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocaleFadeMask — briefly covers the whole app (any screen, any route)
// with the scaffold background color and fades it out whenever the locale
// changes, hiding the instant text/direction flip. Lives above the
// Navigator (via MaterialApp.builder) so it protects every route uniformly,
// not just the main shell.
// ─────────────────────────────────────────────────────────────────────────────
class _LocaleFadeMask extends StatefulWidget {
  final Widget child;
  const _LocaleFadeMask({required this.child});

  @override
  State<_LocaleFadeMask> createState() => _LocaleFadeMaskState();
}

class _LocaleFadeMaskState extends State<_LocaleFadeMask>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  AppLocale? _prevLocale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select((AppState st) => st.locale);

    if (_prevLocale != null && _prevLocale != locale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ctrl.value = 1.0;
          _ctrl.reverse();
        }
      });
    }
    _prevLocale = locale;

    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, _) => _ctrl.value > 0
                ? Opacity(
                    opacity: _ctrl.value,
                    child: ColoredBox(
                      color: Theme.of(ctx).scaffoldBackgroundColor,
                      child: const SizedBox.expand(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RootGate — orchestrates first-run experience:
//   Splash  →  Onboarding (first launch only)  →  AuthGate
// ─────────────────────────────────────────────────────────────────────────────
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  static const _seenKey = 'onboarding_seen';

  // 0 = splash, 1 = onboarding, 2 = app
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final started = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_seenKey) ?? false;

    // Keep the splash visible for at least 1.4s so it doesn't flash.
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed < 1400) {
      await Future.delayed(Duration(milliseconds: 1400 - elapsed));
    }
    if (!mounted) return;
    setState(() => _phase = seen ? 2 : 1);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    if (mounted) setState(() => _phase = 2);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case 0:
        return const SplashScreen();
      case 1:
        return OnboardingScreen(onDone: _finishOnboarding);
      default:
        return const AuthGate();
    }
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Start logged-in if UserService already has a session from a previous run.
  bool _loggedIn = UserService.isLoggedIn;

  // While true, show the biometric splash and run biometric unlock.
  bool _checkingBiometric = true;

  // True when bio is both enabled by the user and available on this device.
  // Passed to LoginScreen so it can show the fingerprint shortcut button.
  bool _bioReady = false;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().onSignOutRequested = _handleSignOut;
    _maybeUnlock();
  }

  void _handleSignOut() {
    if (mounted) setState(() => _loggedIn = false);
  }

  /// On launch: if biometric is available and there is at least one
  /// registered account, immediately trigger the OS biometric prompt.
  ///
  /// • Session active   + bio OK  → bio gates entry into the app.
  /// • Session expired  + bio OK  → bio restores the last user automatically.
  /// • Bio fails/cancel           → fall back to the manual login screen.
  Future<void> _maybeUnlock() async {
    final bioEnabled   = await BiometricService.isEnabled();
    final bioAvailable = await BiometricService.isAvailable();
    final hasUsers     = UserService.hasBiometricCandidate;

    // Show the fingerprint button whenever the device supports biometrics + users exist.
    // Auto-prompt on launch only when the user explicitly enabled it.
    final bioReady = bioAvailable && hasUsers;
    if (mounted) setState(() => _bioReady = bioReady);

    if (bioEnabled && bioReady) {
      final reason = context.mounted
          ? context.read<AppState>().strings.bioReason
          : 'Authenticate to sign in';
      final ok = await BiometricService.authenticate(reason);
      if (ok) {
        if (!_loggedIn) {
          // No active session — restore last user via biometric.
          final user = await UserService.signInWithBiometric();
          if (user != null && mounted) await _handleLogin(user);
        }
        if (mounted) setState(() => _checkingBiometric = false);
      } else {
        // Prompt dismissed / failed → fall back to manual login.
        if (mounted) {
          setState(() {
            _loggedIn          = false;
            _checkingBiometric = false;
          });
        }
      }
    } else {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  /// Called from the fingerprint button on the login screen.
  Future<void> _handleBiometricLogin() async {
    final reason = context.read<AppState>().strings.bioReason;
    final ok = await BiometricService.authenticate(reason);
    if (!ok || !mounted) return;
    // Auto-enable biometric for future logins (first tap = implicit opt-in).
    await BiometricService.setEnabled(true);
    await BiometricService.markAsked();
    final user = await UserService.signInWithBiometric();
    if (user != null && mounted) await _handleLogin(user);
  }

  Future<void> _handleLogin(AppUser user) async {
    // Sync name/email to AppState so the rest of the app reflects the user.
    final state = context.read<AppState>();
    state.setUserName(user.name);
    if (user.email.isNotEmpty && !user.email.startsWith('apple_')) {
      state.setUserEmail(user.email);
    }
    setState(() => _loggedIn = true);

    // Sync dashboard layouts from the cloud (non-blocking — local layout
    // is already loaded; cloud data merges in when it arrives).
    if (user.id.isNotEmpty) {
      unawaited(context.read<LayoutProvider>().loadCloud(user.id));
    }

    // First time only: offer to enable biometric login for next time.
    if (!await BiometricService.wasAsked() &&
        await BiometricService.isAvailable()) {
      await BiometricService.markAsked();
      if (!mounted) return;
      final s = context.read<AppState>().strings;
      final enable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Symbols.fingerprint, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.bioTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 17)),
            ),
          ]),
          content: Text(s.bioPrompt,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.bioSkip,
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.bioEnable,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (enable == true) await BiometricService.setEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingBiometric) {
      return const _BiometricSplash();
    }
    if (!_loggedIn) {
      return LoginScreen(
        onLogin: _handleLogin,
        onBiometricTap: _bioReady ? _handleBiometricLogin : null,
      );
    }
    return const MainShell();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash shown while the biometric prompt is being evaluated.
// ─────────────────────────────────────────────────────────────────────────────
class _BiometricSplash extends StatefulWidget {
  const _BiometricSplash();

  @override
  State<_BiometricSplash> createState() => _BiometricSplashState();
}

class _BiometricSplashState extends State<_BiometricSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Icon(
                Symbols.fingerprint,
                color: Colors.white.withValues(alpha: _pulse.value),
                size: 80,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.read<AppState>().strings.biometricSplashLabel,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const CamerasScreen(),
      const SecurityScreen(),
      const SmartHomeScreen(),
      const AutomationsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    void onNavTap(int i) {
      context.read<LayoutProvider>().exitEditMode();
      setState(() => _index = i);
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final Widget scaffold;
    if (isLandscape) {
      // Landscape: side rail replaces the bottom bar so content gets full height.
      scaffold = Scaffold(
        body: Row(
          children: [
            _SideNav(
              index: _index,
              onTap: onNavTap,
              isRtl: state.isRtl,
              navHome: s.navHome,
              navCameras: s.navCameras,
              navSecurity: s.navSecurity,
              navDevices: s.navDevices,
              navAutomations: s.navAutomations,
              navProfile: s.navProfile,
            ),
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: _BottomNav(
          index: _index,
          onTap: onNavTap,
          navHome: s.navHome,
          navCameras: s.navCameras,
          navSecurity: s.navSecurity,
          navDevices: s.navDevices,
          navAutomations: s.navAutomations,
          navProfile: s.navProfile,
        ),
      );
    }

    return Directionality(
      textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: scaffold,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Side navigation rail — shown in landscape instead of the bottom bar.
// ─────────────────────────────────────────────────────────────────────────────
class _SideNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool isRtl;
  final String navHome;
  final String navCameras;
  final String navSecurity;
  final String navDevices;
  final String navAutomations;
  final String navProfile;

  const _SideNav({
    required this.index,
    required this.onTap,
    required this.isRtl,
    required this.navHome,
    required this.navCameras,
    required this.navSecurity,
    required this.navDevices,
    required this.navAutomations,
    required this.navProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isLight   = Theme.of(context).brightness == Brightness.light;
    final accent    = Theme.of(context).colorScheme.primary;
    final kUnsel    = isLight ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280);
    final bgColor   = isLight ? Colors.white : Theme.of(context).colorScheme.surface;

    final labels = [navHome, navCameras, navSecurity, navDevices, navAutomations, navProfile];
    final icons  = [
      Symbols.home,      Symbols.videocam,     Symbols.shield,
      Symbols.devices,   Symbols.auto_awesome,  Symbols.person,
    ];
    final activeIcons = [
      Symbols.home,       Symbols.videocam,      Symbols.shield,
      Symbols.devices,    Symbols.auto_awesome,   Symbols.person,
    ];

    final railBorder = isRtl
        ? Border(left: BorderSide(
            color: isLight ? const Color(0xFFE8E8E8) : Colors.white.withValues(alpha: 0.07)))
        : Border(right: BorderSide(
            color: isLight ? const Color(0xFFE8E8E8) : Colors.white.withValues(alpha: 0.07)));

    return Container(
      decoration: BoxDecoration(color: bgColor, border: railBorder),
      child: SafeArea(
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(labels.length, (i) {
              final selected = i == index;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(
                                  alpha: isLight ? 0.12 : 0.20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.75, end: 1.0)
                                  .animate(anim),
                              child: child,
                            ),
                          ),
                          child: Icon(
                            selected ? activeIcons[i] : icons[i],
                            key: ValueKey<bool>(selected),
                            color: selected ? accent : kUnsel,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: selected ? accent : kUnsel,
                          fontSize: 9,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Material 3 bottom navigation bar — animated pill indicator, ripple, scale.
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final String navHome;
  final String navCameras;
  final String navSecurity;
  final String navDevices;
  final String navAutomations;
  final String navProfile;

  const _BottomNav({
    required this.index,
    required this.onTap,
    required this.navHome,
    required this.navCameras,
    required this.navSecurity,
    required this.navDevices,
    required this.navAutomations,
    required this.navProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent  = Theme.of(context).colorScheme.primary;
    final bg      = isLight ? Colors.white : Theme.of(context).colorScheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isLight
                ? const Color(0xFFE8E8E8)
                : Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.30),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onTap,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: isLight ? 0.12 : 0.20),
        elevation: 0,
        height: 66,
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          _dest(Symbols.home,        Symbols.home,        navHome),
          _dest(Symbols.videocam,    Symbols.videocam,    navCameras),
          _dest(Symbols.shield,      Symbols.shield,      navSecurity),
          _dest(Symbols.devices,     Symbols.devices,     navDevices),
          _dest(Symbols.auto_awesome,Symbols.auto_awesome,navAutomations),
          _dest(Symbols.person,Symbols.person,     navProfile),
        ],
      ),
    );
  }

  static NavigationDestination _dest(
    IconData icon,
    IconData activeIcon,
    String label,
  ) =>
      NavigationDestination(
        icon: Icon(icon),
        selectedIcon: Icon(activeIcon),
        label: label,
      );
}
