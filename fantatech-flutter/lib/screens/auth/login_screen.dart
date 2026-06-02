import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/app_state.dart';
import '../../services/auth/user_service.dart';
import '../../widgets/brand_logo.dart';
import 'household_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final void Function(AppUser user) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePassword  = true;
  bool _isLoading        = false;
  bool _isGoogleLoading  = false;
  bool _isAppleLoading   = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Email / password login ─────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError(context.read<AppState>().strings.errEnterEmail);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await UserService.signInWithEmail('', email);
      if (mounted) widget.onLogin(user);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google ─────────────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await UserService.signInWithGoogle();
      if (mounted) widget.onLogin(user);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      // If Google OAuth isn't configured, offer email-based fallback
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          _GoogleLogo(),
          const SizedBox(width: 10),
          const Text('כניסה עם Google',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'הזן את כתובת ה-Gmail שלך להמשך',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'example@gmail.com',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ביטול',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final email = ctrl.text.trim();
              Navigator.pop(ctx);
              try {
                final user = await UserService.signInWithGoogleEmail(email);
                if (mounted) widget.onLogin(user);
              } catch (e) {
                if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
              }
            },
            child: const Text('כניסה', style: TextStyle(color: Colors.white)),
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

  // ── Household member ───────────────────────────────────────────────────────

  void _handleHouseholdMember() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HouseholdLoginScreen(onLogin: widget.onLogin),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = context.watch<AppState>().strings;

    return Scaffold(
      backgroundColor: const Color(0xFF1D75BD),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image — pinned to top, natural height ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/main.jpg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          // Gradient overlay: blue-tinted — matches illustration colour
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x331D75BD), // 20% top — illustration shows naturally
                  Color(0xCC1D75BD), // 80% mid — illustration blue
                  Color(0xFF1D75BD), // 100% bottom — solid illustration blue
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
          // ── Content ────────────────────────────────────────────────────────
          SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),

                    // ── Logo ─────────────────────────────────────────────────
                    _FantaTechLogo(),
                    const SizedBox(height: 32),

                    // ── Title ────────────────────────────────────────────────
                    Text(
                      s.loginGreeting,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.loginSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // ── Email field ──────────────────────────────────────────
                    _InputField(
                      controller: _emailCtrl,
                      hint: s.authEmailHint,
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    // ── Password field ───────────────────────────────────────
                    _InputField(
                      controller: _passCtrl,
                      hint: s.authPassHint,
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      highlight: true,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ),
                    ),

                    // ── Forgot password ──────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 0),
                        ),
                        child: Text(
                          s.loginForgot,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Login button ─────────────────────────────────────────
                    Opacity(
                      opacity: _isLoading ? 0.7 : 1.0,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2FFF), Color(0xFFFF2D8A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2FFF)
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _isLoading ? null : _handleLogin,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      s.loginButton,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Divider "או" ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            s.authOr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Apple + Google side-by-side ───────────────────────────
                    Row(
                      children: [
                        // Apple
                        Expanded(
                          child: _SsoButton(
                            onTap: _handleAppleSignIn,
                            isLoading: _isAppleLoading,
                            backgroundColor: Colors.white,
                            borderColor: Colors.white.withValues(alpha: 0.15),
                            child: _isAppleLoading
                                ? const _Spinner(color: Color(0xFF3C4043))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _AppleLogo(color: const Color(0xFF3C4043)),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Apple',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3C4043),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Google
                        Expanded(
                          child: _SsoButton(
                            onTap: _handleGoogleSignIn,
                            isLoading: _isGoogleLoading,
                            backgroundColor: Colors.white,
                            borderColor: Colors.white.withValues(alpha: 0.15),
                            child: _isGoogleLoading
                                ? const _Spinner(color: Color(0xFF4285F4))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GoogleLogo(),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Google',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3C4043),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Household member ──────────────────────────────────────
                    _SsoButton(
                      onTap: _handleHouseholdMember,
                      isLoading: false,
                      backgroundColor: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              color: const Color(0xFF3C4043), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            s.loginHousehold,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3C4043),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Register button ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.loginNoAccount,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                onRegister: widget.onLogin,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              s.registerNow,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
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
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
          padding: EdgeInsets.zero,
        ),
        child: child,
      ),
    );
  }
}

class _FantaTechLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const BrandLogo(size: BrandLogoSize.large);
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool highlight;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.highlight = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight
        ? const Color(0xFF1D75BD).withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.25);
    final iconColor = highlight ? const Color(0xFF1D75BD) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: highlight ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: Color(0xFF1A1D27), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
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
    canvas.drawArc(rect, math.pi * 0.60,  math.pi * 0.78, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, math.pi * 1.38,  math.pi * 0.62, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, math.pi * 2.0,   math.pi * 0.55, false, arc(const Color(0xFF34A853)));
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
