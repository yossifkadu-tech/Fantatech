import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/app_state.dart';
import '../../services/auth/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/ft_button.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(AppUser user) onRegister;

  const RegisterScreen({super.key, required this.onRegister});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMsg = null);
    final s = context.read<AppState>().strings;

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = s.errEnterName);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = s.errEnterEmail);
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _errorMsg = s.errPassShort);
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMsg = s.errPassMismatch);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await UserService.registerWithEmail(
        name:     _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) widget.onRegister(user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.statusAlarm,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = context.select((AppState st) => st.strings);

    return Scaffold(
      backgroundColor: const Color(0xFF1D75BD),
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Back + Logo row
                    Row(
                      children: [
                        FtButton.iconOnly(
                          icon: Symbols.arrow_back_ios_new,
                          variant: FtButtonVariant.neutral,
                          size: FtButtonSize.sm,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Logo
                    _RegisterLogo(),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      s.registerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.registerSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Full name
                    _InputField(
                      controller: _nameCtrl,
                      hint: s.fullName,
                      icon: Symbols.badge,
                      keyboardType: TextInputType.name,
                    ),

                    const SizedBox(height: 12),

                    // Email / Phone
                    _InputField(
                      controller: _emailCtrl,
                      hint: s.authEmailHint,
                      icon: Symbols.person,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 12),

                    // Password
                    _InputField(
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
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Confirm password
                    _InputField(
                      controller: _confirmPassCtrl,
                      hint: s.confirmPassHint,
                      icon: Symbols.lock,
                      obscureText: _obscureConfirm,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
                              ? Symbols.visibility_off
                              : Symbols.visibility,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                    ),

                    // Error message
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.statusAlarm.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.statusAlarm.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Symbols.error,
                                color: AppColors.statusAlarm, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: TextStyle(
                                  color: AppColors.statusAlarm,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Register button
                    FtButton(
                      label: s.registerButton,
                      loading: _isLoading,
                      expand: true,
                      size: FtButtonSize.lg,
                      onTap: _isLoading ? null : _handleRegister,
                    ),

                    const SizedBox(height: 28),

                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.haveAccount,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 14,
                          ),
                        ),
                        FtButton(
                          label: s.loginButton,
                          variant: FtButtonVariant.ghost,
                          size: FtButtonSize.sm,
                          color: Colors.white,
                          onTap: () => Navigator.pop(context),
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
    ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────

class _RegisterLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        Symbols.person_add,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _InputField({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.10),
          width: 1,
        ),
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
        textDirection: context.select((AppState st) => st.isRtl)
            ? TextDirection.rtl
            : TextDirection.ltr,
        style: const TextStyle(color: Color(0xFF1A1D27), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
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
