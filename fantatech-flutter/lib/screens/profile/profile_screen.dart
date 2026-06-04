import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_state.dart';
import '../../services/auth/user_service.dart';
import '../../services/auth/biometric_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../calendar/calendar_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onSignOut;
  const ProfileScreen({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Center(
                child: Text(
                  s.myProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    // ── Avatar ───────────────────────────────
                    _AvatarSection(),

                    const SizedBox(height: 32),

                    // ── Menu items ───────────────────────────
                    _MenuItem(
                      icon: Icons.home_outlined,
                      label: s.myHome,
                      color: AppColors.primary,
                      onTap: () => _showHomeManagementSheet(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.people_outline,
                      label: s.usersTitle,
                      color: const Color(0xFF7B6FCD),
                      onTap: () => _showUsersSheet(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.credit_card_outlined,
                      label: s.subscriptionTitle,
                      color: AppColors.acColor,
                      onTap: () => _showSubscriptionSheet(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.palette_outlined,
                      label: s.appearanceTitle,
                      color: AppColors.cameraColor,
                      onTap: () => _showAppearanceSheet(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      label: s.settingsTitle,
                      color: Colors.white70,
                      onTap: () => _showSettingsSheet(context, state),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.help_outline,
                      label: s.helpTitle,
                      color: AppColors.lightColor,
                      onTap: () => _showHelpSheet(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.logout,
                      label: s.signOut,
                      color: AppColors.unsecured,
                      onTap: () => _confirmSignOut(context, s, onSignOut),
                      isDestructive: true,
                    ),

                    const SizedBox(height: 32),

                    // ── Version ──────────────────────────────
                    Text(
                      'FantaTech v2.6.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUsersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _UsersSheet(),
    );
  }

  void _showHomeManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HomeManagementSheet(),
    );
  }

  void _showSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SubscriptionSheet(),
    );
  }

  void _showSettingsSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SettingsSheet(state: state),
    );
  }

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AppearanceSheet(),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HelpSheet(),
    );
  }

  void _confirmSignOut(BuildContext context, S s, VoidCallback onSignOut) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'יציאה מהאפליקציה',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'בחר כיצד ברצונך לצאת',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
          textAlign: TextAlign.center,
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          // Option 1 — Return to main (no sign out)
          _ExitOption(
            icon: Icons.home_outlined,
            color: AppColors.primary,
            label: 'חזור לתפריט הראשי',
            subtitle: 'נשאר מחובר, לא נדרשת כניסה מחדש',
            onTap: () {
              Navigator.pop(ctx); // close dialog
              onSignOut(); // show login screen (session kept, no sign-out)
            },
          ),
          const SizedBox(height: 10),
          // Option 2 — Full exit (sign out + close app)
          _ExitOption(
            icon: Icons.logout,
            color: AppColors.unsecured,
            label: 'יציאה מלאה',
            subtitle: 'מנתק חשבון — כניסה מחדש תידרש',
            onTap: () async {
              Navigator.pop(ctx); // close dialog
              await UserService.signOut();
              onSignOut();        // → back to login screen
              SystemNavigator.pop(); // close app
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar section
// ─────────────────────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  void _showEditProfile(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(state: state),
    );
  }

  Future<void> _pickImage(BuildContext context, AppState state) async {
    final picker = ImagePicker();
    // Show source chooser
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final s = state.strings;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(s.editProfile,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: s.fromGallery,
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.camera_alt_outlined,
                label: s.fromCamera,
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (state.userImagePath != null) ...[
                const SizedBox(height: 10),
                _SourceTile(
                  icon: Icons.delete_outline,
                  label: s.removePhoto,
                  color: AppColors.unsecured,
                  onTap: () {
                    Navigator.pop(ctx);
                    state.setUserImage(null);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final picked = await picker.pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked != null) {
      state.setUserImage(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasImage = state.userImagePath != null;

    return Column(
      children: [
        // Avatar with gradient ring — tap to change photo
        GestureDetector(
          onTap: () => _pickImage(context, state),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gradient ring
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF7B6FCD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Avatar background / photo
              if (hasImage)
                ClipOval(
                  child: Image.file(
                    File(state.userImagePath!),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                )
              else ...[
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkBg,
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: const [Color(0xFF2A3A5C), Color(0xFF1A2640)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: CustomPaint(painter: _AvatarPainter()),
                ),
              ],
              // Camera icon overlay (bottom-left)
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkBg, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ),
              // Edit pencil (bottom-right)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showEditProfile(context, state),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B6FCD),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkBg, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Name — tappable
        GestureDetector(
          onTap: () => _showEditProfile(context, state),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.edit_outlined,
                color: Colors.white.withValues(alpha: 0.3),
                size: 15,
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Text(
          state.userEmail,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _SourceTile({required this.icon, required this.label,
      required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color, fontSize: 15,
              fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Skin tone
    final skinPaint = Paint()..color = const Color(0xFFD4956A);

    // Head
    canvas.drawCircle(Offset(cx, cy * 0.75), size.width * 0.22, skinPaint);

    // Body (shoulders)
    final bodyPaint = Paint()..color = const Color(0xFF3A4A6A);
    final bodyPath = Path()
      ..moveTo(cx - size.width * 0.38, size.height)
      ..quadraticBezierTo(
        cx - size.width * 0.25, cy * 1.2,
        cx, cy * 1.15,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.25, cy * 1.2,
        cx + size.width * 0.38, size.height,
      )
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF3D2B1F);
    canvas.drawCircle(
        Offset(cx, cy * 0.68), size.width * 0.24, hairPaint);

    // Re-draw lower part of face over hair
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy * 0.79),
        width: size.width * 0.42,
        height: size.width * 0.36,
      ),
      skinPaint,
    );

    // Beard/stubble
    final beardPaint = Paint()
      ..color = const Color(0xFF3D2B1F).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy * 0.9),
        width: size.width * 0.3,
        height: size.width * 0.15,
      ),
      beardPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Edit profile bottom sheet
// ─────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final AppState state;
  const _EditProfileSheet({required this.state});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.userName);
    _emailCtrl = TextEditingController(text: widget.state.userEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Builder(builder: (ctx) {
            final s = widget.state.strings;
            final textDir = widget.state.isRtl
                ? TextDirection.rtl : TextDirection.ltr;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.editProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  textDirection: textDir,
                  decoration: _inputDeco(s.fullName, Icons.person_outline),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco(s.emailLabel, Icons.email_outlined),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.state.setUserName(_nameCtrl.text);
                      widget.state.setUserEmail(_emailCtrl.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            s.profileUpdated,
                            textDirection: textDir,
                          ),
                          backgroundColor: AppColors.secured,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.saveChanges,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Menu item
// ─────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? AppColors.unsecured.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),

            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDestructive
                      ? AppColors.unsecured
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_left,
              color: isDestructive
                  ? AppColors.unsecured.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.25),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Users sheet — shows real registered home users
// ─────────────────────────────────────────────────────────────
class _UsersSheet extends StatelessWidget {
  const _UsersSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final users = state.homeUsers;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.usersTitle,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.hasHomeManager)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.darkCard,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (_) => const _HomeManagementSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.manage_accounts_outlined,
                              color: AppColors.primary, size: 15),
                          const SizedBox(width: 4),
                          Text(s.edit,
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // User list or empty state
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people_outline,
                                color: Colors.white24, size: 30),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.noHomeUsers,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.darkCard,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24))),
                                builder: (_) => const _HomeManagementSheet(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                s.registerAsManager,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scroll,
                      children: users.map((u) => _HomeMemberTile(user: u, s: s)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMemberTile extends StatelessWidget {
  final HomeUser user;
  final S s;
  const _HomeMemberTile({required this.user, required this.s});

  @override
  Widget build(BuildContext context) {
    final color = user.isManager ? AppColors.primary : const Color(0xFF7B6FCD);
    final roleLabel = user.isManager ? s.homeManagerLabel : s.memberLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isManager
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0] : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(roleLabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home Management sheet — manager registration, members, PIN
// ─────────────────────────────────────────────────────────────
class _HomeManagementSheet extends StatefulWidget {
  const _HomeManagementSheet();

  @override
  State<_HomeManagementSheet> createState() => _HomeManagementSheetState();
}

class _HomeManagementSheetState extends State<_HomeManagementSheet> {
  final _memberCtrl = TextEditingController();
  final _pinCtrl    = TextEditingController();
  bool _pinVisible  = false;

  @override
  void dispose() {
    _memberCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _registerManager(AppState state) {
    state.registerAsHomeManager();
  }

  void _addMember(AppState state, S s) {
    final name = _memberCtrl.text.trim();
    if (name.isNotEmpty) {
      state.addHouseholdMember(name);
      _memberCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${s.addMember}: $name'),
        backgroundColor: AppColors.secured,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _savePin(AppState state, S s) {
    final pin = _pinCtrl.text.trim();
    if (pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin)) {
      state.setHomePin(pin);
      _pinCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.pinSaved),
        backgroundColor: AppColors.secured,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _removePin(AppState state, S s) {
    state.setHomePin(null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.pinRemoved),
      backgroundColor: AppColors.unsecured,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 20,
        ),
        child: ListView(
          controller: scroll,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(s.myHome,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),

            // ── Section 0: Home style (icon + color) ─────────
            _SectionLabel('סגנון הבית'),
            const SizedBox(height: 12),
            _HomeStylePicker(state: state),
            const SizedBox(height: 24),

            // ── Section 1: Manager ────────────────────────────
            _SectionLabel(s.homeManagerLabel),
            const SizedBox(height: 10),
            if (!state.hasHomeManager) ...[
              // Register CTA
              GestureDetector(
                onTap: () => _registerManager(state),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.registerAsManager,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(state.userName,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left,
                        color: AppColors.primary, size: 20),
                  ]),
                ),
              ),
            ] else ...[
              // Manager tile
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      state.homeManager!.name.isNotEmpty
                          ? state.homeManager!.name[0]
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.homeManager!.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(s.homeManagerLabel,
                            style: TextStyle(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_outlined,
                        color: AppColors.primary, size: 16),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // ── Section 2: Household Members ──────────────────
            _SectionLabel(s.usersTitle),
            const SizedBox(height: 10),

            // Existing members
            ...state.homeUsers
                .where((u) => !u.isManager)
                .map((u) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          const Color(0xFF7B6FCD).withValues(alpha: 0.15),
                      child: Text(
                        u.name.isNotEmpty ? u.name[0] : '?',
                        style: const TextStyle(
                            color: Color(0xFF7B6FCD),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          Text(s.memberLabel,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => state.removeHomeUser(u.id),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.unsecured.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.unsecured, size: 14),
                      ),
                    ),
                  ]),
                )),

            // Add member input
            if (state.hasHomeManager) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _memberCtrl,
                    textDirection:
                        state.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: s.memberName,
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3)),
                      prefixIcon: const Icon(Icons.person_add_outlined,
                          color: Colors.white38, size: 18),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _addMember(state, s),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _addMember(state, s),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.add,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 24),

            // ── Section 3: PIN ────────────────────────────────
            _SectionLabel(s.setPinCode),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current PIN status
                  Row(children: [
                    Icon(
                      state.homePin != null
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                      color: state.homePin != null
                          ? AppColors.secured
                          : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.homePin != null
                          ? '${s.pinCodeLabel}: ••••'
                          : s.pinCodeLabel,
                      style: TextStyle(
                        color: state.homePin != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                    if (state.homePin != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _removePin(state, s),
                        child: Text(s.remove,
                            style: TextStyle(
                                color: AppColors.unsecured.withValues(
                                    alpha: 0.8),
                                fontSize: 12)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _pinCtrl,
                        obscureText: !_pinVisible,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 6),
                        decoration: InputDecoration(
                          hintText: '• • • •',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              letterSpacing: 6),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _pinVisible = !_pinVisible),
                            child: Icon(
                              _pinVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _savePin(state, s),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.secured.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.secured.withValues(
                                  alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(s.save,
                              style: const TextStyle(
                                  color: AppColors.secured,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Subscription sheet — 4-tier plan selector
// ─────────────────────────────────────────────────────────────
class _SubscriptionSheet extends StatefulWidget {
  const _SubscriptionSheet();

  @override
  State<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<_SubscriptionSheet> {
  late UserPlan _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<AppState>().userPlan;
  }

  void _applyPlan(BuildContext ctx) {
    ctx.read<AppState>().setUserPlan(_selected);
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(_planName(_selected,
          ctx.read<AppState>().strings)),
      backgroundColor: _planColor(_selected),
      duration: const Duration(seconds: 2),
    ));
  }

  Color _planColor(UserPlan p) => switch (p) {
    UserPlan.free         => Colors.white54,
    UserPlan.basic        => AppColors.primary,
    UserPlan.advanced     => AppColors.acColor,
    UserPlan.advancedPlus => const Color(0xFF9C7AFF),
    UserPlan.unlimited    => const Color(0xFFFFD700),
  };

  String _planName(UserPlan p, dynamic s) => switch (p) {
    UserPlan.free         => s.planFree,
    UserPlan.basic        => s.planBasic,
    UserPlan.advanced     => s.planAdvanced,
    UserPlan.advancedPlus => s.planAdvancedPlus,
    UserPlan.unlimited    => s.planUnlimited,
  };

  String _planPrice(UserPlan p, dynamic s) => switch (p) {
    UserPlan.free         => s.planFreePrice,
    UserPlan.basic        => s.planBasicPrice,
    UserPlan.advanced     => s.planAdvancedPrice,
    UserPlan.advancedPlus => s.planAdvancedPlusPrice,
    UserPlan.unlimited    => s.planUnlimitedPrice,
  };

  IconData _planIcon(UserPlan p) => switch (p) {
    UserPlan.free         => Icons.lock_open_outlined,
    UserPlan.basic        => Icons.star_border,
    UserPlan.advanced     => Icons.workspace_premium_outlined,
    UserPlan.advancedPlus => Icons.auto_awesome_outlined,
    UserPlan.unlimited    => Icons.diamond_outlined,
  };

  List<_PlanRow> _buildRows(UserPlan p, dynamic s) => switch (p) {
    UserPlan.free => [
      _PlanRow(s.planViewOnly,             true),
      _PlanRow('7 ${s.planDevicesLabel}',  true),
      _PlanRow('3 ${s.planRoomsLabel}',    true),
      _PlanRow(s.planAutoLabel,            false),
      _PlanRow(s.planCamerasLabel,         false),
    ],
    UserPlan.basic => [
      _PlanRow(s.planViewOnly,             true),
      _PlanRow('10 ${s.planDevicesLabel}', true),
      _PlanRow('3 ${s.planRoomsLabel}',    true),
      _PlanRow('3 ${s.planAutoLabel}',     true),
      _PlanRow(s.planCamerasLabel,         false),
    ],
    UserPlan.advanced => [
      _PlanRow('15 ${s.planDevicesLabel}', true),
      _PlanRow('5 ${s.planRoomsLabel}',    true),
      _PlanRow('5 ${s.planAutoLabel}',     true),
      _PlanRow('3 ${s.planCamerasLabel}',  true),
      _PlanRow(s.planAiLabel,              false),
    ],
    UserPlan.advancedPlus => [
      _PlanRow('20 ${s.planDevicesLabel}',               true),
      _PlanRow('${s.planUnlimitedLabel} ${s.planRoomsLabel}', true),
      _PlanRow('10 ${s.planAutoLabel}',                  true),
      _PlanRow('5 ${s.planCamerasLabel}',                true),
      _PlanRow(s.planAiLabel,                            true),
      _PlanRow(s.planIntercomLabel,                      true),
    ],
    UserPlan.unlimited => [
      _PlanRow('${s.planUnlimitedLabel} ${s.planDevicesLabel}', true),
      _PlanRow('${s.planUnlimitedLabel} ${s.planAutoLabel}',    true),
      _PlanRow('5 ${s.planCamerasLabel}',                       true),
      _PlanRow(s.planAiLabel,                                   true),
      _PlanRow(s.planIntercomLabel,                             true),
      _PlanRow('${s.planSupportLabel} 24/7',                    true),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final currentPlan = state.userPlan;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    s.subscriptionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Current plan badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _planColor(currentPlan)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _planColor(currentPlan)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${s.planCurrentBadge}: ${_planName(currentPlan, s)}',
                      style: TextStyle(
                        color: _planColor(currentPlan),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Plan cards
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final plan in UserPlan.values) ...[
                    _PlanCard(
                      plan: plan,
                      name: _planName(plan, s),
                      price: _planPrice(plan, s),
                      monthlyLabel: s.planMonthly,
                      icon: _planIcon(plan),
                      color: _planColor(plan),
                      rows: _buildRows(plan, s),
                      isCurrentPlan: plan == currentPlan,
                      isSelected: plan == _selected,
                      currentBadge: s.planCurrentBadge,
                      onSelect: () => setState(() => _selected = plan),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Apply button
                  if (_selected != currentPlan) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: Icon(_planIcon(_selected), size: 18),
                        label: Text(
                          '${s.planUpgradeNow} → ${_planName(_selected, s)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () => _applyPlan(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _planColor(_selected),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _planColor(currentPlan)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _planColor(currentPlan)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: _planColor(currentPlan), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_planName(currentPlan, s)} ${s.planSelected}',
                              style: TextStyle(
                                color: _planColor(currentPlan),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow {
  final String label;
  final bool included;
  const _PlanRow(this.label, this.included);
}

class _PlanCard extends StatelessWidget {
  final UserPlan plan;
  final String name;
  final String price;
  final String monthlyLabel;
  final IconData icon;
  final Color color;
  final List<_PlanRow> rows;
  final bool isCurrentPlan;
  final bool isSelected;
  final String currentBadge;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.name,
    required this.price,
    required this.monthlyLabel,
    required this.icon,
    required this.color,
    required this.rows,
    required this.isCurrentPlan,
    required this.isSelected,
    required this.currentBadge,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.darkBg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? color : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          monthlyLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      currentBadge,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (isSelected)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Icon(
                  r.included
                      ? Icons.check_circle_outline
                      : Icons.remove_circle_outline,
                  color: r.included
                      ? color.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.2),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  r.label,
                  style: TextStyle(
                    color: r.included
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                    decoration: r.included
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Settings sheet
// ─────────────────────────────────────────────────────────────
class _SettingsSheet extends StatefulWidget {
  final AppState state;
  const _SettingsSheet({required this.state});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _notifMotion = true;
  bool _notifDoor = true;
  bool _notifEnergy = false;

  bool _bioAvailable = false;
  bool _bioEnabled = false;

  static const _baseUrl = 'https://www.fantatech.co.il';

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) {
      setState(() {
        _bioAvailable = available;
        _bioEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Confirm identity before enabling.
      final ok = await BiometricService.authenticate(
          widget.state.strings.bioReason);
      if (!ok) return;
    }
    await BiometricService.setEnabled(value);
    await BiometricService.markAsked();
    if (mounted) setState(() => _bioEnabled = value);
  }

  Future<void> _open(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            s.settingsTitle,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ── Display ──────────────────────────────────────────
          _SectionLabel(s.displayLabel),
          const SizedBox(height: 10),

          // Theme
          _SettingsRow(
            label: s.themeLabel,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark,   icon: Icon(Icons.dark_mode,  size: 15)),
                ButtonSegment(value: ThemeMode.light,  icon: Icon(Icons.light_mode, size: 15)),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode,  size: 15)),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (sel) {
                // Pop first, then change state — avoids rebuild on a dismissing widget
                Navigator.pop(context);
                context.read<AppState>().setTheme(sel.first);
              },
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const SizedBox(height: 14),

          // Home layout — classic list vs clean grid
          _SettingsRow(
            label: 'פריסת מסך הבית',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.view_agenda_outlined, size: 15)),
                ButtonSegment(value: true,  icon: Icon(Icons.grid_view_rounded,    size: 15)),
              ],
              selected: {state.gridLayout},
              onSelectionChanged: (sel) =>
                  context.read<AppState>().setGridLayout(sel.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const SizedBox(height: 14),

          // Language
          _SettingsRow(
            label: s.languageLabel,
            child: DropdownButton<AppLocale>(
              value: state.locale,
              dropdownColor: AppColors.darkCard,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: const [
                DropdownMenuItem(value: AppLocale.hebrew,  child: Text('עברית 🇮🇱')),
                DropdownMenuItem(value: AppLocale.english, child: Text('English 🇺🇸')),
                DropdownMenuItem(value: AppLocale.arabic,  child: Text('العربية 🇸🇦')),
                DropdownMenuItem(value: AppLocale.amharic, child: Text('አማርኛ 🇪🇹')),
                DropdownMenuItem(value: AppLocale.spanish, child: Text('Español 🇪🇸')),
                DropdownMenuItem(value: AppLocale.russian, child: Text('Русский 🇷🇺')),
              ],
              onChanged: (v) {
                if (v != null) {
                  // Pop first — sheet is dismissed BEFORE the locale rebuild fires
                  Navigator.pop(context);
                  context.read<AppState>().setLocale(v);
                }
              },
            ),
          ),

          const SizedBox(height: 22),

          // ── Notifications ─────────────────────────────────────
          _SectionLabel(s.notifSettings),
          const SizedBox(height: 10),

          _ToggleRow(
            icon: Icons.sensors_outlined,
            color: AppColors.motionColor,
            label: state.strings.motionSensors,
            value: _notifMotion,
            onChanged: (v) => setState(() => _notifMotion = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.sensor_door_outlined,
            color: AppColors.primary,
            label: state.strings.doorSensor,
            value: _notifDoor,
            onChanged: (v) => setState(() => _notifDoor = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.bolt_outlined,
            color: AppColors.lightColor,
            label: state.strings.energyTitle,
            value: _notifEnergy,
            onChanged: (v) => setState(() => _notifEnergy = v),
          ),

          const SizedBox(height: 22),

          // ── Calendar ─────────────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Color(0xFFFFD700), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.calendarTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_left,
                      color: Colors.white.withValues(alpha: 0.3), size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── Security ──────────────────────────────────────────
          if (_bioAvailable) ...[
            _SectionLabel(s.secSection),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.bioLoginLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text(s.bioLoginSub,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _bioEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    onChanged: _toggleBiometric,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],

          // ── Legal & Privacy ───────────────────────────────────
          _SectionLabel(s.legalSection),
          const SizedBox(height: 10),
          _LinkRow(
            icon: Icons.description_outlined,
            label: s.termsLabel,
            onTap: () => _open('/terms'),
          ),
          const SizedBox(height: 10),
          _LinkRow(
            icon: Icons.privacy_tip_outlined,
            label: s.privacyLabel,
            onTap: () => _open('/privacy'),
          ),

          const SizedBox(height: 22),

          // ── About ─────────────────────────────────────────────
          _SectionLabel(s.aboutApp),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _AboutRow(label: 'App', value: 'FantaTech'),
                const Divider(height: 20, color: Colors.white12),
                _AboutRow(label: 'Version', value: 'v2.6.0'),
                const Divider(height: 20, color: Colors.white12),
                _AboutRow(label: 'Build', value: '2026.05.27'),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// Tappable settings row that opens an external link.
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.open_in_new,
                color: Colors.white.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
        Text(value,  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ─── Appearance Sheet ─────────────────────────────────────────────────────────

class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet();
  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  late AppThemePrefs _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = context.read<AppState>().themePrefs;
  }

  void _apply() {
    context.read<AppState>().setThemePrefs(_prefs);
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(s.appearanceTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // ── Font ─────────────────────────────────────────────
            _sectionTitle(s.themeFont.toUpperCase()),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppFont.values.map((f) {
                final name = switch (f) {
                  AppFont.heebo     => 'Heebo',
                  AppFont.rubik     => 'Rubik',
                  AppFont.notoSans  => 'Noto Sans',
                  AppFont.assistant => 'Assistant',
                };
                final sel = _prefs.font == f;
                return GestureDetector(
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(font: f);
                    _apply();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? _prefs.accent.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel
                              ? _prefs.accent
                              : Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Text(name,
                        style: TextStyle(
                            color: sel ? _prefs.accent : Colors.white70,
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── Accent Color ──────────────────────────────────────
            _sectionTitle(s.themeAccent.toUpperCase()),
            Row(
              children: accentPresets.map((c) {
                final sel = _prefs.accent == c;
                return GestureDetector(
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(accent: c);
                    _apply();
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
                          width: 2.5),
                      boxShadow: sel
                          ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                          : [],
                    ),
                    child: sel
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── Background ────────────────────────────────────────
            _sectionTitle(s.themeBg.toUpperCase()),
            Column(
              children: [
                _BgTile(
                  label: s.themeBgDarkBlue,
                  bg: const Color(0xFF0B2044),
                  card: const Color(0xFF153060),
                  selected: _prefs.bgStyle == AppBgStyle.darkBlue,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(bgStyle: AppBgStyle.darkBlue);
                    _apply();
                  }),
                  accent: _prefs.accent,
                ),
                const SizedBox(height: 8),
                _BgTile(
                  label: s.themeBgAmoled,
                  bg: const Color(0xFF000000),
                  card: const Color(0xFF0D0D0D),
                  selected: _prefs.bgStyle == AppBgStyle.amoled,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(bgStyle: AppBgStyle.amoled);
                    _apply();
                  }),
                  accent: _prefs.accent,
                ),
                const SizedBox(height: 8),
                _BgTile(
                  label: s.themeBgDarkGray,
                  bg: const Color(0xFF111318),
                  card: const Color(0xFF1C1F26),
                  selected: _prefs.bgStyle == AppBgStyle.darkGray,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(bgStyle: AppBgStyle.darkGray);
                    _apply();
                  }),
                  accent: _prefs.accent,
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Radius ────────────────────────────────────────────
            _sectionTitle(s.themeRadius.toUpperCase()),
            Row(
              children: [
                _RadiusTile(
                  label: s.themeRadiusSharp,
                  radius: 4,
                  selected: _prefs.radius == AppRadius.sharp,
                  accent: _prefs.accent,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(radius: AppRadius.sharp);
                    _apply();
                  }),
                ),
                const SizedBox(width: 8),
                _RadiusTile(
                  label: s.themeRadiusNormal,
                  radius: 14,
                  selected: _prefs.radius == AppRadius.normal,
                  accent: _prefs.accent,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(radius: AppRadius.normal);
                    _apply();
                  }),
                ),
                const SizedBox(width: 8),
                _RadiusTile(
                  label: s.themeRadiusRound,
                  radius: 24,
                  selected: _prefs.radius == AppRadius.round,
                  accent: _prefs.accent,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(radius: AppRadius.round);
                    _apply();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BgTile extends StatelessWidget {
  final String label;
  final Color bg;
  final Color card;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  const _BgTile({
    required this.label,
    required this.bg,
    required this.card,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.12),
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: card, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            if (selected)
              Icon(Icons.check_circle, color: accent, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RadiusTile extends StatelessWidget {
  final String label;
  final double radius;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _RadiusTile({
    required this.label,
    required this.radius,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? accent : Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 22,
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.3) : Colors.white24,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? accent : Colors.white54,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// Help & Support sheet — FAQ + registration/contact form
// ─────────────────────────────────────────────────────────────
class _HelpSheet extends StatefulWidget {
  const _HelpSheet();

  @override
  State<_HelpSheet> createState() => _HelpSheetState();
}

class _HelpSheetState extends State<_HelpSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.30)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final textDir = state.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            Text(
              s.helpTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ── Tabs ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: s.helpFaq),
                  Tab(text: s.helpContact),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── Tab views ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // ── FAQ tab ────────────────────────────────
                  Builder(builder: (ctx) {
                    final faqs = [
                      (s.faq1Q, s.faq1A),
                      (s.faq2Q, s.faq2A),
                      (s.faq3Q, s.faq3A),
                      (s.faq4Q, s.faq4A),
                    ];
                    return ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: faqs.length,
                      itemBuilder: (ctx, i) {
                        final (q, a) = faqs[i];
                        return _FaqTile(question: q, answer: a);
                      },
                    );
                  }),

                  // ── Contact / Register tab ─────────────────
                  SingleChildScrollView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: _sent
                        ? _SentSuccess(message: s.helpSentSuccess)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.15),
                                      AppColors.primary.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.20)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.person_add_outlined,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s.helpRegisterTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 16),

                              // Name field
                              TextField(
                                controller: _nameCtrl,
                                textDirection: textDir,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: _deco(
                                    s.helpNameHint, Icons.person_outline),
                              ),
                              const SizedBox(height: 12),

                              // Email field
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: _deco(
                                    s.helpEmailHint, Icons.email_outlined),
                              ),
                              const SizedBox(height: 12),

                              // Message field
                              TextField(
                                controller: _msgCtrl,
                                maxLines: 3,
                                textDirection: textDir,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: _deco(
                                    s.helpMsgHint, Icons.message_outlined),
                              ),
                              const SizedBox(height: 20),

                              // Send button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save_outlined, size: 18),
                                  label: Text(
                                    s.helpSendBtn,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_nameCtrl.text.trim().isNotEmpty &&
                                        _emailCtrl.text.trim().isNotEmpty) {
                                      setState(() => _sent = true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _open
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      color: _open ? AppColors.primary : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38,
                  size: 18,
                ),
              ]),
              if (_open) ...[
                const SizedBox(height: 8),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                Text(
                  widget.answer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SentSuccess extends StatelessWidget {
  final String message;
  const _SentSuccess({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: AppColors.secured.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.secured, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home style picker — house type + color
// ─────────────────────────────────────────────────────────────────────────────

/// All available house types
const _kHomeTypes = [
  (label: 'בית',        icon: Icons.home_rounded),
  (label: 'דירה',       icon: Icons.apartment_rounded),
  (label: 'וילה',       icon: Icons.villa),
  (label: 'קוטג׳',      icon: Icons.cottage),
  (label: 'קאבין',      icon: Icons.cabin),
  (label: 'מגדל',       icon: Icons.location_city),
  (label: 'פנטהאוס',    icon: Icons.roofing),
  (label: 'חווה',       icon: Icons.agriculture),
  (label: 'משק',        icon: Icons.grass),
  (label: 'יאכטה',      icon: Icons.directions_boat_rounded),
];

/// Available palette colors (value, Hebrew label)
const _kHomePalette = [
  (value: 0xFF00B4D8, label: 'כחול'),
  (value: 0xFF7B6FCD, label: 'סגול'),
  (value: 0xFF00C853, label: 'ירוק'),
  (value: 0xFFFF6B35, label: 'כתום'),
  (value: 0xFFFFD700, label: 'זהב'),
  (value: 0xFFE53935, label: 'אדום'),
  (value: 0xFF00BFA5, label: 'טורקיז'),
  (value: 0xFFEC407A, label: 'ורוד'),
  (value: 0xFF8D6E63, label: 'חום'),
  (value: 0xFF90A4AE, label: 'אפור'),
];

class _HomeStylePicker extends StatelessWidget {
  final AppState state;
  const _HomeStylePicker({required this.state});

  @override
  Widget build(BuildContext context) {
    final selIcon  = state.homeIconCode;
    final selColor = state.homeColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Preview badge ─────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: selColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selColor.withValues(alpha: 0.40), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: selColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    IconData(selIcon, fontFamily: 'MaterialIcons'),
                    color: selColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _labelForIcon(selIcon),
                  style: TextStyle(
                    color: selColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── House type grid ───────────────────────────────────
          Text(
            'סוג הבית',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kHomeTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final ht    = _kHomeTypes[i];
                final code  = ht.icon.codePoint;
                final isSel = code == selIcon;
                return GestureDetector(
                  onTap: () => state.setHomeIcon(code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 62,
                    decoration: BoxDecoration(
                      color: isSel
                          ? selColor.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? selColor.withValues(alpha: 0.60)
                            : Colors.white.withValues(alpha: 0.10),
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          ht.icon,
                          color: isSel ? selColor : Colors.white38,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ht.label,
                          style: TextStyle(
                            color: isSel
                                ? selColor
                                : Colors.white.withValues(alpha: 0.35),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ── Color palette ─────────────────────────────────────
          Text(
            'צבע',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kHomePalette.map((p) {
              final c      = Color(p.value);
              final isSel  = p.value == selColor.value;
              return Tooltip(
                message: p.label,
                child: GestureDetector(
                  onTap: () => state.setHomeColor(p.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSel
                          ? [BoxShadow(color: c.withValues(alpha: 0.5),
                                       blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                    child: isSel
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _labelForIcon(int code) {
    for (final ht in _kHomeTypes) {
      if (ht.icon.codePoint == code) return ht.label;
    }
    return 'בית';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exit option tile (used inside the sign-out dialog)
// ─────────────────────────────────────────────────────────────────────────────
class _ExitOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ExitOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.38),
                          fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_left,
                color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingsRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        child,
      ],
    );
  }
}
