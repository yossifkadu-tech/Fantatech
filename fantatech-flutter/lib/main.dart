import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_state.dart';
import 'models/app_user.dart';
import 'services/auth/user_service.dart';
import 'services/auth/biometric_service.dart';
import 'services/discovery/real_discovery_engine.dart';
import 'services/gateways/gateway_manager.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/ai/fanta_ai_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/devices/devices_screen.dart';
import 'screens/security/security_screen.dart';
import 'screens/cameras/cameras_screen.dart';
import 'screens/cyber/cyber_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/store/store_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await UserService.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => RealDiscoveryEngine()),
        ChangeNotifierProvider(create: (_) => GatewayManager()),
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: state.flutterLocale,
      supportedLocales: const [
        Locale('he'),
        Locale('en'),
        Locale('ar'),
        Locale('am'),
        Locale('es'),
        Locale('ru'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootGate(),
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

  // While true, show a lock splash and run biometric unlock.
  bool _checkingBiometric = true;

  @override
  void initState() {
    super.initState();
    _maybeUnlock();
  }

  /// On launch: if a session exists and biometric login is enabled, require
  /// fingerprint/face before showing the app.
  Future<void> _maybeUnlock() async {
    if (_loggedIn &&
        await BiometricService.isEnabled() &&
        await BiometricService.isAvailable()) {
      final reason = context.mounted
          ? context.read<AppState>().strings.bioReason
          : 'Authenticate to sign in';
      final ok = await BiometricService.authenticate(reason);
      if (!ok) {
        // Failed / cancelled → fall back to manual login.
        if (mounted) {
          setState(() {
            _loggedIn = false;
            _checkingBiometric = false;
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _checkingBiometric = false);
  }

  Future<void> _handleLogin(AppUser user) async {
    // Sync name/email to AppState so the rest of the app reflects the user.
    final state = context.read<AppState>();
    state.setUserName(user.name);
    if (user.email.isNotEmpty && !user.email.startsWith('apple_')) {
      state.setUserEmail(user.email);
    }
    setState(() => _loggedIn = true);

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
            const Icon(Icons.fingerprint, color: AppColors.primary, size: 24),
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

  void _handleSignOut() {
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingBiometric) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B2044),
        body: Center(
          child: Icon(Icons.fingerprint, color: Colors.white24, size: 64),
        ),
      );
    }
    if (!_loggedIn) {
      return LoginScreen(onLogin: _handleLogin);
    }
    return MainShell(onSignOut: _handleSignOut);
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onSignOut;
  const MainShell({super.key, required this.onSignOut});

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
      const DashboardScreen(),
      const DevicesScreen(),
      const CamerasScreen(),
      const FantaAIScreen(),
      const SecurityScreen(),
      const CyberScreen(),
      const StoreScreen(),
      ProfileScreen(onSignOut: widget.onSignOut),
    ];
  }

  List<BottomNavigationBarItem> _navItems(AppState state) {
    final s = state.strings;
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: s.navHome,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.devices_outlined),
        activeIcon: const Icon(Icons.devices),
        label: s.navDevices,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.videocam_outlined),
        activeIcon: const Icon(Icons.videocam),
        label: s.navCameras,
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_outlined),
        activeIcon: Icon(Icons.auto_awesome),
        label: 'AI',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.shield_outlined),
        activeIcon: const Icon(Icons.shield),
        label: s.navSecurity,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.security_outlined),
        activeIcon: const Icon(Icons.security),
        label: s.cyberNavLabel,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.store_outlined),
        activeIcon: const Icon(Icons.store),
        label: s.storeNavLabel,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: s.navProfile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Directionality(
      textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: _navItems(state),
            selectedFontSize: 10,
            unselectedFontSize: 10,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.white38,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
