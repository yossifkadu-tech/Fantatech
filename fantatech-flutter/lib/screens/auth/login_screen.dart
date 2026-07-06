import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/app_user.dart';
import '../../models/app_state.dart';
import '../../services/auth/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_button.dart';
import 'register_screen.dart';
import 'household_login_screen.dart';

// Light theme tokens for the (white-background) login screen.
const Color _kInk    = Color(0xFF1A1D27);
const Color _kSub    = Color(0xFF6B7280);
const Color _kField  = Color(0xFFF3F4F6);
const Color _kBorder = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen
//
// Single screen that handles the full entry flow:
//   • Main panel  — Sign-in options (Google, Apple, Email, Guest, Household)
//   • Email panel — Inline email/password form (AnimatedSwitcher, same BG)
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final void Function(AppUser user) onLogin;
  final Future<void> Function()? onBiometricTap;

  const LoginScreen({
    super.key,
    required this.onLogin,
    this.onBiometricTap,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Panel state ────────────────────────────────────────────────────────────
  bool _showEmailForm = false;

  // ── Email form ─────────────────────────────────────────────────────────────
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  bool  _obscurePassword = true;
  bool  _isLoginLoading  = false;
  bool  _isBioLoading    = false;
  bool  _rememberMe      = true;

  // ── SSO / guest loading ────────────────────────────────────────────────────
  bool _isGoogleLoading = false;
  bool _isAppleLoading  = false;
  bool _isGuestLoading  = false;

  // ── Entrance animation ─────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    if (UserService.lastEmail != null) {
      _emailCtrl.text = UserService.lastEmail!;
    }
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Google ─────────────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await UserService.signInWithGoogle();
      if (mounted) widget.onLogin(user);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('google-services.json') || msg.contains('אינה מוגדרת')) {
        if (mounted) _showGoogleEmailFallback();
      } else if (msg != 'הכניסה בוטלה') {
        if (mounted) _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showGoogleEmailFallback() {
    final ctrl = TextEditingController();
    final s = context.read<AppState>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          _GoogleLogo(),
          const SizedBox(width: 10),
          const Text('Google',
              style: TextStyle(color: Color(0xFF1A1D27), fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s.loginGoogleEmailPrompt,
              style:
                  const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'example@gmail.com',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final email = ctrl.text.trim();
              Navigator.pop(ctx);
              try {
                final user =
                    await UserService.signInWithGoogleEmail(email);
                if (mounted) widget.onLogin(user);
              } catch (e) {
                if (mounted) {
                  _showError(
                      e.toString().replaceFirst('Exception: ', ''));
                }
              }
            },
            child: Text(s.loginButton,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Apple ──────────────────────────────────────────────────────────────────

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    try {
      final user = await UserService.signInWithApple();
      if (mounted) widget.onLogin(user);
    } catch (e) {
      _showError('Apple: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  // ── Guest ──────────────────────────────────────────────────────────────────

  Future<void> _handleGuest() async {
    setState(() => _isGuestLoading = true);
    try {
      final user = await UserService.signInAsGuest();
      if (mounted) widget.onLogin(user);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  // ── Email login ────────────────────────────────────────────────────────────

  Future<void> _handleEmailLogin() async {
    final s     = context.read<AppState>().strings;
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (!UserService.isValidEmail(email)) { _showError(s.errInvalidEmail); return; }
    if (!UserService.isValidPassword(pass)) { _showError(s.errPassShort); return; }
    setState(() => _isLoginLoading = true);
    try {
      final user = await UserService.signInWithEmail(email, pass);
      if (!_rememberMe) await UserService.forgetEmail();
      if (mounted) widget.onLogin(user);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  Future<void> _handleBiometric() async {
    if (widget.onBiometricTap == null) return;
    setState(() => _isBioLoading = true);
    try {
      await widget.onBiometricTap!();
    } finally {
      if (mounted) setState(() => _isBioLoading = false);
    }
  }

  void _showForgotPassword() {
    final s    = context.read<AppState>().strings;
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sent  = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(s.loginForgot,
              style: const TextStyle(
                  color: Color(0xFF1A1D27), fontWeight: FontWeight.bold)),
          content: sent
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Symbols.mark_email_read,
                      color: Color(0xFF4CAF50), size: 48),
                  const SizedBox(height: 12),
                  Text(s.resetEmailSent,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 14)),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.resetEmailHint,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: s.authEmailHint,
                      hintStyle:
                          const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ]),
          actions: sent
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(s.okButton,
                        style: const TextStyle(
                            color: Color(0xFF6B7280))),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(s.cancelButton,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF))),
                  ),
                  TextButton(
                    onPressed: () async {
                      final email = ctrl.text.trim();
                      if (!UserService.isValidEmail(email)) return;
                      try {
                        await UserService.sendPasswordResetEmail(email);
                      } catch (_) {}
                      if (ctx.mounted) setS(() => sent = true);
                    },
                    child: Text(s.sendButton,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
        ),
      ),
    );
  }

  // ── Language picker ────────────────────────────────────────────────────────

  void _showLanguagePicker() {
    HapticFeedback.lightImpact();
    final state = context.read<AppState>();
    final locales = [
      (AppLocale.hebrew,  'עברית',    '🇮🇱'),
      (AppLocale.english, 'English',  '🇺🇸'),
      (AppLocale.arabic,  'العربية',  '🇸🇦'),
      (AppLocale.amharic, 'አማርኛ',    '🇪🇹'),
      (AppLocale.spanish, 'Español',  '🇪🇸'),
      (AppLocale.russian, 'Русский',  '🇷🇺'),
      (AppLocale.french,  'Français', '🇫🇷'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) {
          final current = state.locale;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Symbols.language, color: _kSub, size: 18),
                  const SizedBox(width: 8),
                  const Text('בחר שפה',
                      style: TextStyle(
                          color: _kInk,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: locales.map((loc) {
                    final (locale, name, flag) = loc;
                    final selected = current == locale;
                    return GestureDetector(
                      onTap: () {
                        state.setLocale(locale);
                        setSt(() {});
                        Future.delayed(
                            const Duration(milliseconds: 180),
                            () { if (ctx2.mounted) Navigator.pop(ctx2); });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : _kField,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? AppColors.primary : _kBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(name,
                              style: TextStyle(
                                color: selected ? AppColors.primary : _kInk,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Icon(Symbols.check,
                                color: AppColors.primary, size: 15),
                          ],
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.statusAlarm,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s     = context.select((AppState st) => st.strings);
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                const SizedBox(height: 28),
                // ── Brand header ────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 84, height: 84, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('FantaTech',
                    style: TextStyle(
                        color: _kInk,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(s.appTagline,
                    style: const TextStyle(color: _kSub, fontSize: 13)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _showEmailForm
                      ? _buildEmailPanel(s, state)
                      : _buildMainPanel(s, state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main panel ─────────────────────────────────────────────────────────────

  Widget _buildMainPanel(S s, AppState state) {
    return Padding(
      key: const ValueKey('main'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Primary: Sign In with email ───────────────────────────────────
          FtButton(
            label: s.loginButton,
            leadingIcon: Symbols.login,
            expand: true,
            size: FtButtonSize.lg,
            onTap: () => setState(() => _showEmailForm = true),
          ),

          const SizedBox(height: 10),

          // ── SSO: Google + Apple ───────────────────────────────────────────
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: _SsoButton(
                    onTap: _handleGoogleSignIn,
                    isLoading: _isGoogleLoading,
                    backgroundColor: Colors.white,
                    borderColor: Colors.grey.shade300,
                    child: _isGoogleLoading
                        ? const _Spinner(color: Color(0xFF4285F4))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleLogo(),
                              const SizedBox(width: 8),
                              const Text('Google',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3C4043))),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SsoButton(
                    onTap: _handleAppleSignIn,
                    isLoading: _isAppleLoading,
                    backgroundColor: Colors.white,
                    borderColor: Colors.grey.shade300,
                    child: _isAppleLoading
                        ? const _Spinner(color: Color(0xFF3C4043))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AppleLogo(color: const Color(0xFF3C4043)),
                              const SizedBox(width: 8),
                              const Text('Apple',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3C4043))),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Secondary row: Register · Guest · Household ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GhostLink(
                icon: Symbols.person_add,
                label: s.registerNow,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RegisterScreen(onRegister: widget.onLogin))),
              ),
              _Dot(),
              _GhostLink(
                icon: Symbols.person,
                label: s.continueAsGuest,
                color: const Color(0xFF1E88E5),
                loading: _isGuestLoading,
                onTap: _isGuestLoading ? null : _handleGuest,
              ),
              _Dot(),
              _GhostLink(
                icon: Symbols.home,
                label: s.loginHousehold,
                color: const Color(0xFFEF6C00),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => HouseholdLoginScreen(
                            onLogin: widget.onLogin))),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Language button ───────────────────────────────────────────────
          _LanguageButton(
            locale: state.locale,
            onTap: _showLanguagePicker,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Email panel ────────────────────────────────────────────────────────────

  Widget _buildEmailPanel(S s, AppState state) {
    return Padding(
      key: const ValueKey('email'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back + title row
          Row(children: [
            GestureDetector(
              onTap: () => setState(() {
                _showEmailForm = false;
                _passCtrl.clear();
              }),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _kField,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.arrow_back_ios_new,
                    color: _kInk, size: 17),
              ),
            ),
            const SizedBox(width: 14),
            Text(s.loginGreeting,
                style: const TextStyle(
                    color: _kInk,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),

          const SizedBox(height: 16),

          // Email field
          _LightInputField(
            controller: _emailCtrl,
            hint: s.authEmailHint,
            icon: Symbols.person,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 10),

          // Password field
          _LightInputField(
            controller: _passCtrl,
            hint: s.authPassHint,
            icon: Symbols.lock,
            obscureText: _obscurePassword,
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Symbols.visibility_off
                    : Symbols.visibility,
                color: _kSub,
                size: 20,
              ),
            ),
          ),

          // Remember me + Forgot password
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => _rememberMe = !_rememberMe),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(s.rememberMe,
                        style: const TextStyle(color: _kSub, fontSize: 13)),
                  ]),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showForgotPassword,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                ),
                child: Text(s.loginForgot,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Sign In button
          FtButton(
            label: s.loginButton,
            loading: _isLoginLoading,
            expand: true,
            size: FtButtonSize.lg,
            onTap: _isLoginLoading ? null : _handleEmailLogin,
          ),

          // Biometric
          if (widget.onBiometricTap != null) ...[
            const SizedBox(height: 10),
            FtButton(
              label: s.loginBiometric,
              leadingIcon: Symbols.fingerprint,
              variant: FtButtonVariant.neutral,
              size: FtButtonSize.lg,
              loading: _isBioLoading,
              expand: true,
              onTap: _isBioLoading ? null : _handleBiometric,
            ),
          ],

          const SizedBox(height: 12),

          // Register CTA
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.loginNoAccount,
                style: const TextStyle(color: _kSub, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RegisterScreen(onRegister: widget.onLogin))),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              child: Text(s.registerNow,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ]),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language button — shows current locale flag + name, opens picker on tap
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageButton extends StatelessWidget {
  final AppLocale locale;
  final VoidCallback onTap;
  const _LanguageButton({required this.locale, required this.onTap});

  static const _info = <AppLocale, (String, String)>{
    AppLocale.hebrew:  ('עברית',    '🇮🇱'),
    AppLocale.english: ('English',  '🇺🇸'),
    AppLocale.arabic:  ('العربية',  '🇸🇦'),
    AppLocale.amharic: ('አማርኛ',    '🇪🇹'),
    AppLocale.spanish: ('Español',  '🇪🇸'),
    AppLocale.russian: ('Русский',  '🇷🇺'),
    AppLocale.french:  ('Français', '🇫🇷'),
  };

  @override
  Widget build(BuildContext context) {
    final (name, flag) = _info[locale] ?? ('עברית', '🇮🇱');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _kField,
          border: Border.all(color: _kBorder, width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.language, size: 15, color: _kSub),
            const SizedBox(width: 6),
            Text(flag, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(name, style: const TextStyle(color: _kInk, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Symbols.expand_more, size: 16, color: _kSub),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ghost link button (Register / Guest / Household)
// ─────────────────────────────────────────────────────────────────────────────
class _GhostLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const _GhostLink({
    required this.icon,
    required this.label,
    this.color = _kInk,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            SizedBox(
              width: 13, height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: color),
            )
          else
            Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('·',
      style: TextStyle(color: Color(0x4D1A1D27), fontSize: 16));
}

// ─────────────────────────────────────────────────────────────────────────────
// Light input field (used in email panel — matches white background)
// ─────────────────────────────────────────────────────────────────────────────
class _LightInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _LightInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: _kInk, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kSub, fontSize: 14),
          prefixIcon: Icon(icon, color: _kSub, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SsoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _SsoButton({
    required this.onTap,
    required this.isLoading,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          padding: EdgeInsets.zero,
        ),
        child: child,
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  final Color color;
  const _Spinner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
    );
  }
}

// ── Apple Logo ────────────────────────────────────────────────────────────────
class _AppleLogo extends StatelessWidget {
  final Color color;
  const _AppleLogo({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _AppleLogoPainter(color: color)),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  final Color color;
  const _AppleLogoPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.50, h * 0.17)
      ..cubicTo(w * 0.56, h * 0.00, w * 0.78, h * 0.02, w * 0.78, h * 0.28)
      ..cubicTo(w * 0.78, h * 0.40, w * 0.72, h * 0.48, w * 0.66, h * 0.54)
      ..cubicTo(w * 0.88, h * 0.62, w * 0.95, h * 0.86, w * 0.82, h * 0.96)
      ..cubicTo(w * 0.74, h * 1.02, w * 0.63, h * 0.95, w * 0.50, h * 0.95)
      ..cubicTo(w * 0.37, h * 0.95, w * 0.26, h * 1.02, w * 0.18, h * 0.96)
      ..cubicTo(w * 0.05, h * 0.86, w * 0.12, h * 0.62, w * 0.34, h * 0.54)
      ..cubicTo(w * 0.28, h * 0.48, w * 0.22, h * 0.40, w * 0.22, h * 0.28)
      ..cubicTo(w * 0.22, h * 0.02, w * 0.44, h * 0.00, w * 0.50, h * 0.17)
      ..close();
    canvas.drawPath(path, paint);
    final stalk = Path()
      ..moveTo(w * 0.50, h * 0.17)
      ..cubicTo(w * 0.50, h * 0.05, w * 0.62, h * 0.00, w * 0.62, h * 0.00)
      ..cubicTo(w * 0.56, h * 0.10, w * 0.54, h * 0.15, w * 0.50, h * 0.17)
      ..close();
    canvas.drawPath(stalk, paint);
  }

  @override
  bool shouldRepaint(_AppleLogoPainter old) => old.color != color;
}

// ── Google Logo ───────────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.21;
    final r  = (size.width - sw) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect,  math.pi * 0.60, math.pi * 0.78, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect,  math.pi * 1.38, math.pi * 0.62, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect,  math.pi * 2.0,  math.pi * 0.55, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, -math.pi * 0.45, math.pi * 1.05, false, arc(const Color(0xFF4285F4)));
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r - sw * 0.05, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
