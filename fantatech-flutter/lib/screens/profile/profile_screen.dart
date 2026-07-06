import 'package:material_symbols_icons/symbols.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_version.dart';
import '../../models/app_state.dart';
import '../../models/app_user.dart';
import '../../services/auth/biometric_service.dart';
import '../../services/auth/user_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/ft_button.dart';
import '../calendar/calendar_screen.dart';
import '../mirror/mirror_screen.dart';

// ─── Home management sheet — reusable from outside this screen ───────────────
void showHomeManagementSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.tCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _HomeManagementSheet(),
  );
}

// ─── Subscription sheet — reusable from outside this screen ──────────────────
void _openSubscriptionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SubscriptionSheet(),
  );
}

// ─── Installer mode — tap the badge to enter the code, or to exit ───────────
void _handleInstallerBadgeTap(BuildContext context, AppState state) {
  if (state.installerMode) {
    _confirmExitInstallerMode(context, state);
  } else {
    _promptInstallerCode(context, state);
  }
}

void _confirmExitInstallerMode(BuildContext context, AppState state) {
  final s = state.strings;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.tCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.installerCodeTitle,
          style: TextStyle(color: context.tText, fontWeight: FontWeight.bold)),
      content: Text(s.installerExitConfirm,
          style: TextStyle(color: context.tText2(0.6))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.cancel, style: TextStyle(color: context.tText2(0.4))),
        ),
        TextButton(
          onPressed: () {
            state.exitInstallerMode();
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.installerModeOffMsg)));
          },
          child: Text(s.okButton,
              style: const TextStyle(
                  color: AppColors.alert, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void _promptInstallerCode(BuildContext context, AppState state) {
  final ctrl = TextEditingController();
  String? error;
  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(state.strings.installerCodeTitle,
            style:
                TextStyle(color: context.tText, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: context.tText),
          decoration: InputDecoration(
            hintText: state.strings.installerCodeHint,
            filled: true,
            fillColor: context.tText2(0.06),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            errorText: error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.strings.cancel,
                style: TextStyle(color: context.tText2(0.4))),
          ),
          TextButton(
            onPressed: () {
              if (state.tryUnlockInstallerMode(ctrl.text.trim())) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.strings.installerModeOnMsg)));
              } else {
                setS(() => error = state.strings.installerCodeWrong);
              }
            },
            child: Text(state.strings.okButton,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

// ─── Plan helpers (shared by hero + subscription sheet) ──────────────────────
Color _planAccent(UserPlan p) => switch (p) {
  UserPlan.free         => AppColors.textSecondary,
  UserPlan.basic        => AppColors.primary,
  UserPlan.advanced     => AppColors.acColor,
  UserPlan.advancedPlus => const Color(0xFF9C7AFF),
  UserPlan.unlimited    => const Color(0xFFFFD700),
};

String _planLabel(UserPlan p, dynamic s) => switch (p) {
  UserPlan.free         => s.planFree,
  UserPlan.basic        => s.planBasic,
  UserPlan.advanced     => s.planAdvanced,
  UserPlan.advancedPlus => s.planAdvancedPlus,
  UserPlan.unlimited    => s.planUnlimited,
};

IconData _planIconData(UserPlan p) => switch (p) {
  UserPlan.free         => Symbols.lock_open,
  UserPlan.basic        => Symbols.star_border,
  UserPlan.advanced     => Symbols.workspace_premium,
  UserPlan.advancedPlus => Symbols.auto_awesome,
  UserPlan.unlimited    => Symbols.diamond,
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 860));
    // 5 staggered slots: hero / stats / group-home / group-app / version
    _anims = List.generate(5, (i) {
      final start = i * 0.07;
      final end   = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final userCount = state.homeUsers.length;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 14, AppSpacing.s16, 0),
              child: Row(
                children: [
                  Text(
                    s.myProfile,
                    style: AppTypography.headlineSm.copyWith(color: context.tText),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showEditProfileSheet(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppBorderRadius.r8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Symbols.edit,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            s.editProfile,
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.s16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, 0, AppSpacing.s16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero card ─────────────────────────────────────
                    _FadeSlide(
                      animation: _anims[0],
                      child: _ProfileHero(
                        state: state,
                        onEditProfile: () => _showEditProfileSheet(context, state),
                        onPickImage: () => _pickAvatarImage(context, state),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // ── Statistics ────────────────────────────────────
                    _FadeSlide(
                      animation: _anims[1],
                      child: _StatsGrid(state: state),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    // ── Group: Home ───────────────────────────────────
                    _FadeSlide(
                      animation: _anims[2],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GroupLabel(s.myHome),
                          const SizedBox(height: AppSpacing.s8),
                          _MenuSection(
                            children: [
                              FtListTile(
                                icon: Symbols.home,
                                iconBg: AppColors.primary.withValues(alpha: 0.12),
                                iconColor: AppColors.primary,
                                title: s.myHome,
                                onTap: () => _showHomeManagementSheet(context),
                              ),
                              FtListTile(
                                icon: Symbols.people,
                                iconBg: const Color(0xFF7B6FCD).withValues(alpha: 0.12),
                                iconColor: const Color(0xFF7B6FCD),
                                title: s.usersTitle,
                                trailing: userCount > 0
                                    ? _CountBadge(
                                        count: userCount,
                                        color: const Color(0xFF7B6FCD),
                                      )
                                    : null,
                                onTap: () => _showUsersSheet(context),
                              ),
                              FtListTile(
                                icon: Symbols.credit_card,
                                iconBg: AppColors.success.withValues(alpha: 0.12),
                                iconColor: AppColors.success,
                                title: s.subscriptionTitle,
                                onTap: () => _showSubscriptionSheet(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // ── Group: App preferences ────────────────────────
                    _FadeSlide(
                      animation: _anims[3],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GroupLabel(s.settingsTitle),
                          const SizedBox(height: AppSpacing.s8),
                          _MenuSection(
                            children: [
                              FtListTile(
                                icon: Symbols.settings,
                                iconBg: AppColors.statusOffline.withValues(alpha: 0.12),
                                iconColor: AppColors.statusOffline,
                                title: s.settingsTitle,
                                onTap: () => _showSettingsSheet(context, state),
                              ),
                              FtListTile(
                                icon: Symbols.help,
                                iconBg: AppColors.statusOffline.withValues(alpha: 0.12),
                                iconColor: AppColors.statusOffline,
                                title: s.helpTitle,
                                onTap: () => _showHelpSheet(context),
                              ),
                              FtListTile(
                                icon: Symbols.backup,
                                iconBg: AppColors.networkColor.withValues(alpha: 0.12),
                                iconColor: AppColors.networkColor,
                                title: s.backupSection,
                                onTap: () => _showBackupSheet(context, state, s),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s24),

                    // ── Version chip ──────────────────────────────────
                    _FadeSlide(
                      animation: _anims[4],
                      child: const Center(child: _VersionChip()),
                    ),

                    const SizedBox(height: AppSpacing.s8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(state: state),
    );
  }

  Future<void> _pickAvatarImage(BuildContext context, AppState state) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final s = state.strings;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: context.tText2(0.24),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(s.editProfile,
                  style: TextStyle(color: context.tText,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              FtListTile(
                icon: Symbols.photo_library,
                iconBg: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                title: s.fromGallery,
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              FtListTile(
                icon: Symbols.camera_alt,
                iconBg: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                title: s.fromCamera,
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (state.userImagePath != null) ...[
                const SizedBox(height: 10),
                FtListTile(
                  icon: Symbols.delete,
                  iconBg: AppColors.alert.withValues(alpha: 0.12),
                  iconColor: AppColors.alert,
                  title: s.removePhoto,
                  destructive: true,
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
      await state.setUserImage(picked.path);
    }
  }

  void _showUsersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _UsersSheet(),
    );
  }

  void _showHomeManagementSheet(BuildContext context) =>
      showHomeManagementSheet(context);

  void _showSubscriptionSheet(BuildContext context) =>
      _openSubscriptionSheet(context);

  void _showSettingsSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SettingsSheet(state: state),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HelpSheet(),
    );
  }

  void _showBackupSheet(BuildContext context, AppState state, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BackupSheet(state: state, s: s),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Hero — premium header card with avatar, name, email, plan badge
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final AppState state;
  final VoidCallback onEditProfile;
  final VoidCallback onPickImage;

  const _ProfileHero({
    required this.state,
    required this.onEditProfile,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage   = state.userImagePath != null;
    final planColor  = _planAccent(state.userPlan);
    final planName   = _planLabel(state.userPlan, state.strings);
    final planIcon   = _planIconData(state.userPlan);
    final isPremium  = state.userPlan != UserPlan.free;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isLight
              ? [const Color(0xFF1A1F3A), const Color(0xFF0D1226)]
              : [const Color(0xFF111827), const Color(0xFF0A0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.cardLg,
        boxShadow: AppShadows.glow(AppColors.primary, intensity: 0.35),
      ),
      child: Stack(
        children: [
          // Decorative orange glow orb top-right
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Decorative purple orb bottom-left
          Positioned(
            bottom: -20, left: 10,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B6FCD).withValues(alpha: 0.10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24, AppSpacing.s32, AppSpacing.s24, AppSpacing.s24),
            child: Column(
              children: [
                // ── Avatar ──────────────────────────────────────
                GestureDetector(
                  onTap: onPickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated gradient ring
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF7B6FCD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Avatar content
                      if (hasImage)
                        ClipOval(
                          child: Image.file(
                            File(state.userImagePath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      else ...[
                        Container(
                          width: 100, height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1A2640),
                          ),
                        ),
                        SizedBox(
                          width: 96, height: 96,
                          child: ClipOval(
                            child: CustomPaint(painter: _AvatarPainter()),
                          ),
                        ),
                      ],
                      // Camera badge — bottom right
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0D1226), width: 2.5),
                          ),
                          child: const Icon(Symbols.camera_alt,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s16),

                // ── Name ─────────────────────────────────────────
                GestureDetector(
                  onTap: onEditProfile,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.userName.isEmpty ? 'FantaTech User' : state.userName,
                        style: AppTypography.headlineMd.copyWith(
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Icon(Symbols.edit,
                          color: Colors.white.withValues(alpha: 0.35),
                          size: 15),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s4),

                // ── Email ─────────────────────────────────────────
                Text(
                  state.userEmail.isEmpty ? '—' : state.userEmail,
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),

                const SizedBox(height: AppSpacing.s16),

                // ── Plan badge + Installer badge ─────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _openSubscriptionSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                        decoration: BoxDecoration(
                          color: planColor.withValues(alpha: isPremium ? 0.18 : 0.10),
                          borderRadius: AppBorderRadius.chip,
                          border: Border.all(
                              color: planColor.withValues(alpha: 0.40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(planIcon, color: planColor, size: 14),
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              planName,
                              style: AppTypography.labelMd.copyWith(color: planColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.hasHomeManager) ...[
                      const SizedBox(width: AppSpacing.s8),
                      GestureDetector(
                        onTap: () => _handleInstallerBadgeTap(context, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: state.installerMode
                                  ? const [Color(0xFF2ECC71), Color(0xFF1E8E4E)]
                                  : const [Color(0xFFFF6B35), Color(0xFFE8920A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: AppBorderRadius.chip,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  state.installerMode
                                      ? Symbols.lock_open
                                      : Symbols.verified,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                state.strings.installerBadge,
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistics grid — Homes · Devices · Automations · Cameras
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final AppState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.strings;
    final rooms = state.rooms.length;
    final devices = state.devices.length;
    final automations = state.automations.length;
    final cameras = state.cameras.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.s12,
      mainAxisSpacing: AppSpacing.s12,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          icon: Symbols.home,
          color: AppColors.primary,
          value: '$rooms',
          label: s.statHomesLabel,
        ),
        _StatCard(
          icon: Symbols.devices,
          color: const Color(0xFF06B6D4),
          value: '$devices',
          label: s.navDevices,
        ),
        _StatCard(
          icon: Symbols.bolt,
          color: const Color(0xFF9C7AFF),
          value: '$automations',
          label: s.navAutomations,
        ),
        _StatCard(
          icon: Symbols.videocam,
          color: const Color(0xFF16A34A),
          value: '$cameras',
          label: s.navCameras,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: AppBorderRadius.card,
        boxShadow: context.isLight ? AppShadows.md : AppShadows.dark,
        border: Border.all(
          color: context.isLight
              ? AppColors.lightBorder
              : AppColors.darkBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isLight ? 0.10 : 0.15),
              borderRadius: AppBorderRadius.icon,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.displaySm.copyWith(
                    color: context.tText,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: context.tTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu section — grouped card containing FtListTile items
// ─────────────────────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: AppBorderRadius.card,
        boxShadow: context.isLight ? AppShadows.md : AppShadows.dark,
        border: Border.all(
          color: context.isLight
              ? AppColors.lightBorder
              : AppColors.darkBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 56,
                endIndent: 16,
                color: context.isLight
                    ? AppColors.lightBorder
                    : AppColors.darkBorder.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation helper — fade + slide-up entry
// ─────────────────────────────────────────────────────────────────────────────
class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 18 * (1 - animation.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group label — uppercase section header above a _MenuSection
// ─────────────────────────────────────────────────────────────────────────────
class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: context.tText2(0.35),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count badge — small colored pill used as trailing on list tiles
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Version chip — branded footer pill with app name + version number
// ─────────────────────────────────────────────────────────────────────────────
class _VersionChip extends StatelessWidget {
  const _VersionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tText2(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.bolt, color: AppColors.primary, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'FantaTech Smart Home & Security Solution',
              style: AppTypography.caption.copyWith(
                color: context.tText2(0.55),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 1,
            height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: context.tText2(0.15),
          ),
          Text(
            'v$kAppVersion',
            style: AppTypography.caption.copyWith(
              color: context.tText2(0.35),
            ),
          ),
        ],
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
        labelStyle: TextStyle(color: context.tText2(0.5)),
        prefixIcon: Icon(icon, color: context.tText2(0.38), size: 20),
        filled: true,
        fillColor: context.tText2(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.tText2(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.tText2(0.12)),
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
                color: context.tText2(0.24),
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
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _nameCtrl,
                  style: TextStyle(color: context.tText),
                  textDirection: textDir,
                  decoration: _inputDeco(s.fullName, Symbols.person),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _emailCtrl,
                  style: TextStyle(color: context.tText),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco(s.emailLabel, Symbols.email),
                ),

                const SizedBox(height: 24),

                FtButton(
                  label: s.saveChanges,
                  expand: true,
                  onTap: () {
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
                  color: context.tText2(0.24),
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
                  style: TextStyle(
                    color: context.tText, fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.hasHomeManager)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: context.tCard,
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
                          Icon(Symbols.manage_accounts,
                              color: AppColors.primary, size: 15),
                          const SizedBox(width: 4),
                          Text(s.edit,
                              style: TextStyle(
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
                              color: context.tText2(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Symbols.people,
                                color: context.tText2(0.24), size: 30),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.noHomeUsers,
                            style: TextStyle(
                              color: context.tText2(0.4),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: context.tCard,
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
                                style: TextStyle(
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

class _HomeMemberTile extends StatefulWidget {
  final HomeUser user;
  final S s;
  const _HomeMemberTile({required this.user, required this.s});

  @override
  State<_HomeMemberTile> createState() => _HomeMemberTileState();
}

class _HomeMemberTileState extends State<_HomeMemberTile> {
  final _picker = ImagePicker();

  Future<void> _editName(AppState state) async {
    final ctrl = TextEditingController(text: widget.user.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.s.editUserName,
            style: TextStyle(color: context.tText, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.tText),
          decoration: InputDecoration(
            hintText: widget.user.name,
            hintStyle: TextStyle(color: context.tText2(0.35)),
            filled: true,
            fillColor: context.tText2(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          FtButton(
            label: widget.s.cancel,
            variant: FtButtonVariant.ghost,
            onTap: () => Navigator.pop(ctx, false),
          ),
          FtButton(
            label: widget.s.save,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      await state.renameHomeUser(widget.user.id, ctrl.text.trim());
    }
    ctrl.dispose();
  }

  Future<void> _pickPhoto(AppState state) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FtListTile(
                icon: Symbols.photo_library,
                iconBg: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                title: widget.s.fromGallery,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              FtListTile(
                icon: Symbols.camera_alt,
                iconBg: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                title: widget.s.fromCamera,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              if (widget.user.imagePath != null) ...[
                const SizedBox(height: 10),
                FtListTile(
                  icon: Symbols.delete,
                  iconBg: AppColors.alert.withValues(alpha: 0.12),
                  iconColor: AppColors.alert,
                  title: widget.s.removePhoto,
                  destructive: true,
                  onTap: () => Navigator.pop(context, null),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (source == null && widget.user.imagePath != null) {
      await state.setHomeUserImage(widget.user.id, null);
      return;
    }
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (!mounted || picked == null) return;
    await state.setHomeUserImage(widget.user.id, picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final state     = context.read<AppState>();
    final color     = widget.user.isManager ? AppColors.primary : const Color(0xFF7B6FCD);
    final roleLabel = widget.user.isManager ? widget.s.homeManagerLabel : widget.s.memberLabel;
    final imgPath   = widget.user.imagePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tText2(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.user.isManager
              ? AppColors.primary.withValues(alpha: 0.2)
              : context.tText2(0.08),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickPhoto(state),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  backgroundImage: imgPath != null ? FileImage(File(imgPath)) : null,
                  child: imgPath == null
                      ? Text(
                          widget.user.name.isNotEmpty ? widget.user.name[0] : '?',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Symbols.camera_alt,
                        color: Colors.white, size: 9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name,
                    style: TextStyle(
                        color: context.tText, fontWeight: FontWeight.w600)),
                Text(roleLabel,
                    style: TextStyle(
                        color: context.tText2(0.4),
                        fontSize: 12)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _editName(context.read<AppState>()),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  decoration: BoxDecoration(
                    color: context.tText2(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Symbols.edit,
                      color: context.tText2(0.45), size: 16),
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
  final _memberCtrl      = TextEditingController();
  final _pinCtrl         = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();
  bool _pinVisible       = false;
  bool _showInviteField  = false;

  @override
  void dispose() {
    _memberCtrl.dispose();
    _pinCtrl.dispose();
    _inviteEmailCtrl.dispose();
    super.dispose();
  }

  // ── Pick image for a household member ──────────────────────────
  Future<void> _pickMemberImage(AppState state, HomeUser user) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: context.tText2(0.24),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(state.strings.profilePhotoFmt.replaceAll('{name}', user.name),
                style: TextStyle(color: context.tText, fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            FtListTile(
              icon: Symbols.photo_library,
              iconBg: AppColors.primary.withValues(alpha: 0.12),
              iconColor: AppColors.primary,
              title: state.strings.fromGallery,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            FtListTile(
              icon: Symbols.camera_alt,
              iconBg: AppColors.primary.withValues(alpha: 0.12),
              iconColor: AppColors.primary,
              title: state.strings.fromCamera,
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (user.imagePath != null) ...[
              const SizedBox(height: 10),
              FtListTile(
                icon: Symbols.delete,
                iconBg: AppColors.alert.withValues(alpha: 0.12),
                iconColor: AppColors.alert,
                title: state.strings.removePhoto,
                destructive: true,
                onTap: () => Navigator.pop(ctx, null),
              ),
            ],
          ],
        ),
      ),
    );
    // null from sheet = remove; ImageSource = pick
    if (source == null && user.imagePath != null) {
      await state.setHomeUserImage(user.id, null);
    } else if (source != null) {
      final picked = await ImagePicker().pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (picked != null && mounted) {
        await state.setHomeUserImage(user.id, picked.path);
      }
    }
  }

  // ── Send household invite via email ────────────────────────────
  Future<void> _sendInviteEmail(String email, String code) async {
    final s = context.read<AppState>().strings;
    final subject = Uri.encodeComponent(s.inviteSubject);
    final body    = Uri.encodeComponent(
      s.inviteBodyFmt.replaceAll('{code}', code),
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.noEmailApp),
        backgroundColor: AppColors.statusAlarm,
      ));
    }
  }

  void _registerManager(AppState state) {
    state.registerAsHomeManager();
    // Show confirmation with the household code
    if (!mounted) return;
    final code = state.householdCode ?? '------';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secured.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Symbols.verified,
                  color: AppColors.secured, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              state.strings.regManagerMsg,
              style: TextStyle(
                color: context.tText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.strings.nameFieldFmt.replaceAll(
                  '{name}', state.homeManager?.name ?? state.userName),
              style: TextStyle(color: context.tText2(0.55), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Household code card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    state.strings.homeJoinTitle,
                    style: TextStyle(
                        color: context.tText2(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.strings.shareCodeHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: context.tText2(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FtButton(
            label: state.strings.gotIt,
            expand: true,
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
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
                  color: context.tText2(0.24),
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
                child: Icon(Symbols.home, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(s.myHome,
                  style: TextStyle(
                      color: context.tText, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),

            // ── Section 0: Home style (icon + color) ─────────
            _SectionLabel(state.strings.homeStyleTitle),
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
                      child: Icon(Symbols.person_add,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.registerAsManager,
                              style: TextStyle(
                                  color: context.tText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            state.strings.registerAsFmt.replaceAll('{name}', state.userName),
                            style: TextStyle(
                                color: context.tText2(0.4),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Symbols.chevron_left,
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
                    backgroundImage: state.homeManager!.imagePath != null
                        ? FileImage(File(state.homeManager!.imagePath!))
                        : null,
                    child: state.homeManager!.imagePath == null
                        ? Text(
                            state.homeManager!.name.isNotEmpty
                                ? state.homeManager!.name[0]
                                : '?',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.homeManager!.name,
                            style: TextStyle(
                                color: context.tText, fontWeight: FontWeight.w600)),
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
                    child: Icon(Symbols.verified,
                        color: AppColors.primary, size: 16),
                  ),
                ]),
              ),
              if (state.householdCode != null && state.canManageHousehold) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    final newCode = state.regenerateHouseholdCode();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.strings.newCodeFmt.replaceAll('{code}', newCode)),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Icon(Symbols.key,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        state.strings.joinCodeInline,
                        style: TextStyle(
                            color: context.tText2(0.5), fontSize: 12),
                      ),
                      Text(
                        state.householdCode!,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      Icon(Symbols.refresh,
                          color: context.tText2(0.3), size: 15),
                    ]),
                  ),
                ),
              ],
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
                    color: context.tText2(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.tText2(0.08)),
                  ),
                  child: Row(children: [
                    // Avatar — tap to change photo
                    GestureDetector(
                      onTap: () => _pickMemberImage(state, u),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                const Color(0xFF7B6FCD).withValues(alpha: 0.15),
                            backgroundImage: u.imagePath != null
                                ? FileImage(File(u.imagePath!))
                                : null,
                            child: u.imagePath == null
                                ? Text(
                                    u.name.isNotEmpty ? u.name[0] : '?',
                                    style: const TextStyle(
                                        color: Color(0xFF7B6FCD),
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B6FCD),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: context.tBg, width: 1.5),
                              ),
                              child: const Icon(Symbols.camera_alt,
                                  color: Colors.white, size: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: TextStyle(
                                  color: context.tText,
                                  fontWeight: FontWeight.w500)),
                          Text(s.memberLabel,
                              style: TextStyle(
                                  color: context.tText2(0.35),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    if (state.canManageHousehold)
                      GestureDetector(
                        onTap: () => state.removeHomeUser(u.id),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.unsecured.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Symbols.close,
                              color: AppColors.unsecured, size: 14),
                        ),
                      ),
                  ]),
                )),

            // Add member input — manager-only (Permission.manageUsers)
            if (state.hasHomeManager && state.canManageHousehold) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _memberCtrl,
                    textDirection:
                        state.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(color: context.tText, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: s.memberName,
                      hintStyle: TextStyle(
                          color: context.tText2(0.3)),
                      prefixIcon: Icon(Symbols.person_add,
                          color: context.tText2(0.38), size: 18),
                      filled: true,
                      fillColor: context.tText2(0.05),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: context.tText2(0.10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: context.tText2(0.10)),
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
                FtButton.iconOnly(
                  icon: Symbols.add,
                  variant: FtButtonVariant.secondary,
                  onTap: () => _addMember(state, s),
                ),
              ]),
            ],

            // ── Invite by email ─── manager-only (Permission.manageUsers)
            if (state.hasHomeManager &&
                state.householdCode != null &&
                state.canManageHousehold) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showInviteField = !_showInviteField),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Symbols.email,
                          color: Color(0xFF1A73E8), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.strings.inviteByEmail,
                              style: TextStyle(
                                color: context.tText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )),
                          Text(state.strings.inviteByEmailSub,
                              style: TextStyle(
                                color: context.tText2(0.4),
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                    Icon(
                      _showInviteField
                          ? Symbols.keyboard_arrow_up
                          : Symbols.keyboard_arrow_down,
                      color: const Color(0xFF1A73E8),
                      size: 20,
                    ),
                  ]),
                ),
              ),
              if (_showInviteField) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _inviteEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: context.tText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: TextStyle(color: context.tText2(0.3)),
                        prefixIcon: Icon(Symbols.alternate_email,
                            color: context.tText2(0.38), size: 18),
                        filled: true,
                        fillColor: context.tText2(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.tText2(0.10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.tText2(0.10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1A73E8), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FtButton(
                    label: state.strings.helpSendBtn,
                    color: const Color(0xFF1A73E8),
                    onTap: () {
                      final email = _inviteEmailCtrl.text.trim();
                      final code  = state.householdCode!;
                      if (email.contains('@')) {
                        _sendInviteEmail(email, code);
                        _inviteEmailCtrl.clear();
                        setState(() => _showInviteField = false);
                      }
                    },
                  ),
                ]),
              ],
            ],

            const SizedBox(height: 24),

            // ── Section 3: PIN ────────────────────────────────
            _SectionLabel(s.setPinCode),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.tText2(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: context.tText2(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current PIN status
                  Row(children: [
                    Icon(
                      state.homePin != null
                          ? Symbols.lock
                          : Symbols.lock_open,
                      color: state.homePin != null
                          ? AppColors.secured
                          : context.tText2(0.38),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.homePin != null
                          ? '${s.pinCodeLabel}: ••••'
                          : s.pinCodeLabel,
                      style: TextStyle(
                        color: state.homePin != null
                            ? context.tText
                            : context.tText2(0.4),
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
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 18,
                            letterSpacing: 6),
                        decoration: InputDecoration(
                          hintText: '• • • •',
                          hintStyle: TextStyle(
                              color: context.tText2(0.2),
                              letterSpacing: 6),
                          counterText: '',
                          filled: true,
                          fillColor: context.tText2(0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _pinVisible = !_pinVisible),
                            child: Icon(
                              _pinVisible
                                  ? Symbols.visibility_off
                                  : Symbols.visibility,
                              color: context.tText2(0.38),
                              size: 18,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: context.tText2(0.10)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: context.tText2(0.10)),
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
                    FtButton(
                      label: s.save,
                      variant: FtButtonVariant.secondary,
                      onTap: () => _savePin(state, s),
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
    UserPlan.free         => context.tText2(0.54),
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
    UserPlan.free         => Symbols.lock_open,
    UserPlan.basic        => Symbols.star_border,
    UserPlan.advanced     => Symbols.workspace_premium,
    UserPlan.advancedPlus => Symbols.auto_awesome,
    UserPlan.unlimited    => Symbols.diamond,
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
        decoration: BoxDecoration(
          color: context.tCard,
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
                  color: context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Icon(Symbols.workspace_premium,
                      color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    s.subscriptionTitle,
                    style: TextStyle(
                      color: context.tText,
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
                    FtButton(
                      label: '${s.planUpgradeNow} → ${_planName(_selected, s)}',
                      leadingIcon: _planIcon(_selected),
                      color: _planColor(_selected),
                      expand: true,
                      onTap: () => _applyPlan(context),
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
                            Icon(Symbols.check_circle,
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
              : context.tBg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : context.tText2(0.08),
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
                        color: isSelected ? color : context.tText,
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
                            color: context.tText2(0.35),
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
                    child: Icon(Symbols.check,
                        color: context.tText, size: 14),
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.tText2(0.2)),
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
                      ? Symbols.check_circle
                      : Symbols.remove_circle,
                  color: r.included
                      ? color.withValues(alpha: 0.8)
                      : context.tText2(0.2),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  r.label,
                  style: TextStyle(
                    color: r.included
                        ? context.tText2(0.85)
                        : context.tText2(0.3),
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

  // ── Switch account ─────────────────────────────────────────────────────
  //
  // A real sign-out path exists (unlike the removed Profile logout button),
  // but it's tucked inside Settings and gated behind re-verifying identity —
  // password re-entry for email accounts, biometric for SSO/guest accounts
  // when enabled — so it can't be triggered by an accidental tap.

  Future<void> _confirmSwitchAccount(
      BuildContext context, AppState state, S s) async {
    final user = UserService.currentUser;
    if (user == null) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.switchAccountConfirmTitle,
            style:
                TextStyle(color: context.tText, fontWeight: FontWeight.bold)),
        content: Text(s.switchAccountConfirmBody,
            style: TextStyle(color: context.tText2(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: TextStyle(color: context.tText2(0.4))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.switchAccountConfirmBtn,
                style: const TextStyle(
                    color: AppColors.alert, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    final verified = await _reverifyIdentity(context, user, s);
    if (!verified || !context.mounted) return;

    await UserService.signOut();
    if (!context.mounted) return;
    Navigator.pop(context); // close the settings sheet
    state.requestSignOut();
  }

  /// Confirms the user really is who they say before switching accounts:
  /// password re-entry for email/password accounts, biometric re-auth for
  /// SSO/guest accounts when the device has it enabled.
  Future<bool> _reverifyIdentity(
      BuildContext context, AppUser user, S s) async {
    if (user.authProvider == AuthProvider.member && user.password.isNotEmpty) {
      return _confirmWithPassword(context, user, s);
    }
    if (_bioEnabled && _bioAvailable) {
      return BiometricService.authenticate(s.bioReason);
    }
    return true; // no stronger local factor available (guest / SSO, bio off)
  }

  Future<bool> _confirmWithPassword(
      BuildContext context, AppUser user, S s) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: context.tCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.switchAccountConfirmTitle,
              style: TextStyle(
                  color: context.tText, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.switchAccountPasswordPrompt,
                  style: TextStyle(color: context.tText2(0.6), fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                autofocus: true,
                style: TextStyle(color: context.tText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.tText2(0.06),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Symbols.visibility_off : Symbols.visibility,
                        color: context.tText2(0.4)),
                    onPressed: () => setS(() => obscure = !obscure),
                  ),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text(s.cancel, style: TextStyle(color: context.tText2(0.4))),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await UserService.signInWithEmail(user.email, ctrl.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  setS(() => error = s.switchAccountWrongPassword);
                }
              },
              child: Text(s.switchAccountConfirmBtn,
                  style: const TextStyle(
                      color: AppColors.alert, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    return ok == true;
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
                color: context.tText2(0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            s.settingsTitle,
            style: TextStyle(
                color: context.tText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ── Display ──────────────────────────────────────────
          _SectionLabel(s.displayLabel),
          const SizedBox(height: 10),

          // Theme — Light / Dark / Auto
          _SettingsRow(
            label: s.themeLabel,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'light', icon: Icon(Symbols.light_mode, size: 15)),
                ButtonSegment(value: 'dark',  icon: Icon(Symbols.dark_mode,  size: 15)),
                ButtonSegment(value: 'auto',  icon: Icon(Symbols.auto_mode,  size: 15)),
              ],
              selected: {
                state.autoTheme
                  ? 'auto'
                  : (state.themeMode == ThemeMode.light ? 'light' : 'dark')
              },
              onSelectionChanged: (sel) {
                Navigator.pop(context);
                final appState = context.read<AppState>();
                switch (sel.first) {
                  case 'light': appState.setTheme(ThemeMode.light); break;
                  case 'dark':  appState.setTheme(ThemeMode.dark);  break;
                  case 'auto':  appState.setAutoTheme(true);         break;
                }
              },
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const SizedBox(height: 14),

          // Home layout — classic list vs clean grid
          _SettingsRow(
            label: s.homeLayoutLabel,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Symbols.view_agenda, size: 15)),
                ButtonSegment(value: true,  icon: Icon(Symbols.grid_view,    size: 15)),
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
              dropdownColor: context.tCard,
              underline: const SizedBox(),
              style: TextStyle(color: context.tText, fontSize: 13),
              items: const [
                DropdownMenuItem(value: AppLocale.hebrew,  child: Text('עברית 🇮🇱')),
                DropdownMenuItem(value: AppLocale.english, child: Text('English 🇺🇸')),
                DropdownMenuItem(value: AppLocale.arabic,  child: Text('العربية 🇸🇦')),
                DropdownMenuItem(value: AppLocale.amharic, child: Text('አማርኛ 🇪🇹')),
                DropdownMenuItem(value: AppLocale.spanish, child: Text('Español 🇪🇸')),
                DropdownMenuItem(value: AppLocale.russian, child: Text('Русский 🇷🇺')),
                DropdownMenuItem(value: AppLocale.french,  child: Text('Français 🇫🇷')),
              ],
              onChanged: (v) {
                if (v != null) {
                  final appState = context.read<AppState>();
                  Navigator.pop(context);
                  // Wait for the sheet close animation before switching locale
                  // so the RTL/LTR flip doesn't fight with the dismiss animation.
                  Future.delayed(const Duration(milliseconds: 280), () {
                    appState.setLocale(v);
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Shabbat ───────────────────────────────────────────
          _ToggleRow(
            icon: Symbols.auto_awesome,
            color: const Color(0xFFFFD700),
            label: s.keepShabbatLabel,
            value: state.keepShabbat,
            onChanged: (v) => context.read<AppState>().setKeepShabbat(v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Text(
              s.shabbatCandlesDesc,
              style: TextStyle(color: context.tText2(0.38), fontSize: 11.5, height: 1.45),
            ),
          ),

          const SizedBox(height: 22),

          // ── Notifications ─────────────────────────────────────
          _SectionLabel(s.notifSettings),
          const SizedBox(height: 10),

          _ToggleRow(
            icon: Symbols.sensors,
            color: AppColors.motionColor,
            label: state.strings.motionSensors,
            value: _notifMotion,
            onChanged: (v) => setState(() => _notifMotion = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Symbols.sensor_door,
            color: AppColors.primary,
            label: state.strings.doorSensor,
            value: _notifDoor,
            onChanged: (v) => setState(() => _notifDoor = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Symbols.bolt,
            color: AppColors.lightColor,
            label: state.strings.energyTitle,
            value: _notifEnergy,
            onChanged: (v) => setState(() => _notifEnergy = v),
          ),

          const SizedBox(height: 22),

          // ── Calendar ─────────────────────────────────────────
          FtListTile(
            icon: Symbols.calendar_month,
            iconBg: const Color(0xFFFFD700).withValues(alpha: 0.12),
            iconColor: const Color(0xFFFFD700),
            title: s.calendarTitle,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()));
            },
          ),

          const SizedBox(height: 10),

          // ── Smart Mirror ──────────────────────────────────────
          FtListTile(
            icon: Symbols.auto_awesome,
            iconBg: const Color(0xFF9C27B0).withValues(alpha: 0.12),
            iconColor: const Color(0xFFCE93D8),
            title: s.mirrorScreenTitle,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MirrorScreen()));
            },
          ),

          const SizedBox(height: 22),

          // ── Security ──────────────────────────────────────────
          _SectionLabel(s.secSection),
          const SizedBox(height: 10),
          Opacity(
            opacity: _bioAvailable ? 1.0 : 0.45,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: context.tText2(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.tText2(0.08)),
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
                    child: Icon(Symbols.fingerprint,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.bioLoginLabel,
                            style: TextStyle(
                                color: context.tText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text(
                          _bioAvailable ? s.bioLoginSub : s.bioUnavailable,
                          style: TextStyle(
                              color: context.tText2(0.4),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _bioEnabled,
                    activeThumbColor: context.tText,
                    activeTrackColor: AppColors.primary,
                    onChanged: _bioAvailable ? _toggleBiometric : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ── Account ────────────────────────────────────────────
          _SectionLabel(s.accountSection),
          const SizedBox(height: 10),
          FtListTile(
            icon: Symbols.switch_account,
            iconBg: AppColors.statusOffline.withValues(alpha: 0.12),
            iconColor: AppColors.statusOffline,
            title: s.switchAccountTitle,
            subtitle: s.switchAccountSub,
            onTap: () => _confirmSwitchAccount(context, state, s),
          ),
          const SizedBox(height: 22),

          // ── Legal & Privacy ───────────────────────────────────
          _SectionLabel(s.legalSection),
          const SizedBox(height: 10),
          FtListTile(
            icon: Symbols.description,
            iconBg: AppColors.statusOffline.withValues(alpha: 0.12),
            iconColor: AppColors.statusOffline,
            title: s.termsLabel,
            showArrow: false,
            trailing: Icon(Symbols.open_in_new, color: AppColors.statusOffline.withValues(alpha: 0.6), size: 18),
            onTap: () => _open('/terms'),
          ),
          const SizedBox(height: 10),
          FtListTile(
            icon: Symbols.privacy_tip,
            iconBg: AppColors.statusOffline.withValues(alpha: 0.12),
            iconColor: AppColors.statusOffline,
            title: s.privacyLabel,
            showArrow: false,
            trailing: Icon(Symbols.open_in_new, color: AppColors.statusOffline.withValues(alpha: 0.6), size: 18),
            onTap: () => _open('/privacy'),
          ),

          const SizedBox(height: 22),

          // ── About ─────────────────────────────────────────────
          _SectionLabel(s.aboutApp),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.tText2(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.tText2(0.08)),
            ),
            child: Column(
              children: [
                _AboutRow(label: 'App', value: 'FantaTech'),
                const Divider(height: 20, color: Colors.white12),
                _AboutRow(label: 'Version', value: 'v$kAppVersion'),
                const Divider(height: 20, color: Colors.white12),
                _AboutRow(label: 'Build', value: '2026.07.06'),
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
        color: context.tText2(0.35),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
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
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.07)),
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
                style: TextStyle(color: context.tText, fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
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
        Text(label, style: TextStyle(color: context.tText2(0.45), fontSize: 13)),
        Text(value,  style: TextStyle(color: context.tText, fontSize: 13, fontWeight: FontWeight.w500)),
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
            style: TextStyle(
                color: context.tText2(0.54), fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.select<AppState, S>((st) => st.strings);

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
                    color: context.tText2(0.24),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(s.appearanceTitle,
                style: TextStyle(
                    color: context.tText,
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
                  AppFont.inter     => 'Inter',
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
                          : context.tText2(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel
                              ? _prefs.accent
                              : context.tText2(0.12)),
                    ),
                    child: Text(name,
                        style: TextStyle(
                            color: sel ? _prefs.accent : context.tText2(0.7),
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── Accent Color ──────────────────────────────────────
            _sectionTitle(s.themeAccent.toUpperCase()),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...accentPresets.map((c) {
                  final sel = _prefs.accent == c;
                  final checkColor =
                      c.computeLuminance() > 0.6 ? Colors.black : Colors.white;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _prefs = _prefs.copyWith(accent: c);
                      _apply();
                    }),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        // Always show a hairline so white is visible on light bg.
                        border: Border.all(
                            color: sel ? context.tText : context.tText2(0.2),
                            width: sel ? 2.5 : 1),
                        boxShadow: sel
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                            : [],
                      ),
                      child: sel ? Icon(Symbols.check, color: checkColor, size: 16) : null,
                    ),
                  );
                }),
                // Custom color mixer
                _ColorMixTile(
                  selected: !accentPresets.contains(_prefs.accent),
                  current: _prefs.accent,
                  onPick: (c) => setState(() {
                    _prefs = _prefs.copyWith(accent: c);
                    _apply();
                  }),
                ),
              ],
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
                const SizedBox(height: 8),
                _BgTile(
                  label: s.themeBgLightGray,
                  bg: const Color(0xFFEEF2FA),
                  card: const Color(0xFFFFFFFF),
                  selected: _prefs.bgStyle == AppBgStyle.lightGray,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(bgStyle: AppBgStyle.lightGray);
                    _apply();
                  }),
                  accent: _prefs.accent,
                  isLight: true,
                ),
                const SizedBox(height: 8),
                _BgTile(
                  label: s.themeBgLightWhite,
                  bg: const Color(0xFFFFFFFF),
                  card: const Color(0xFFF3F5F9),
                  selected: _prefs.bgStyle == AppBgStyle.lightWhite,
                  onTap: () => setState(() {
                    _prefs = _prefs.copyWith(bgStyle: AppBgStyle.lightWhite);
                    _apply();
                  }),
                  accent: _prefs.accent,
                  isLight: true,
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
  final bool isLight;  // light-palette tile → use dark text

  const _BgTile({
    required this.label,
    required this.bg,
    required this.card,
    required this.selected,
    required this.onTap,
    required this.accent,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF1A1D27) : context.tText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? accent : (isLight ? const Color(0xFFCDD3E0) : context.tText2(0.12)),
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x22000000), width: 0.5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: textColor, fontSize: 13)),
            ),
            if (selected)
              Icon(Symbols.check_circle, color: accent, size: 18),
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
                : context.tText2(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? accent : context.tText2(0.10)),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 22,
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.3) : context.tText2(0.24),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? accent : context.tText2(0.54),
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
        hintStyle: TextStyle(color: context.tText2(0.30)),
        prefixIcon: Icon(icon, color: context.tText2(0.38), size: 18),
        filled: true,
        fillColor: context.tText2(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.tText2(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.tText2(0.10)),
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
                  color: context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            Text(
              s.helpTitle,
              style: TextStyle(
                color: context.tText,
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
                color: context.tText2(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                dividerColor: Colors.transparent,
                labelColor: context.tText,
                unselectedLabelColor: context.tText2(0.38),
                labelStyle: TextStyle(
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
                                  Icon(Symbols.person_add,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s.helpRegisterTitle,
                                      style: TextStyle(
                                        color: context.tText,
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
                                style: TextStyle(
                                    color: context.tText, fontSize: 14),
                                decoration: _deco(
                                    s.helpNameHint, Symbols.person),
                              ),
                              const SizedBox(height: 12),

                              // Email field
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                    color: context.tText, fontSize: 14),
                                decoration: _deco(
                                    s.helpEmailHint, Symbols.email),
                              ),
                              const SizedBox(height: 12),

                              // Message field
                              TextField(
                                controller: _msgCtrl,
                                maxLines: 3,
                                textDirection: textDir,
                                style: TextStyle(
                                    color: context.tText, fontSize: 14),
                                decoration: _deco(
                                    s.helpMsgHint, Symbols.message),
                              ),
                              const SizedBox(height: 20),

                              // Send button
                              FtButton(
                                label: s.helpSendBtn,
                                leadingIcon: Symbols.save,
                                expand: true,
                                onTap: () {
                                  if (_nameCtrl.text.trim().isNotEmpty &&
                                      _emailCtrl.text.trim().isNotEmpty) {
                                    setState(() => _sent = true);
                                  }
                                },
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
        color: context.tText2(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _open
              ? AppColors.primary.withValues(alpha: 0.35)
              : context.tText2(0.08),
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
                      color: _open ? AppColors.primary : context.tText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _open ? Symbols.expand_less : Symbols.expand_more,
                  color: context.tText2(0.38),
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
                    color: context.tText2(0.65),
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
            child: Icon(Symbols.check_circle,
                color: AppColors.secured, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tText,
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
  (label: 'House',      icon: Symbols.home),
  (label: 'Apartment',  icon: Symbols.apartment),
  (label: 'Villa',      icon: Symbols.villa),
  (label: 'Cottage',    icon: Symbols.cottage),
  (label: 'Cabin',      icon: Symbols.cabin),
  (label: 'Tower',      icon: Symbols.location_city),
  (label: 'Penthouse',  icon: Symbols.roofing),
  (label: 'Farm',       icon: Symbols.agriculture),
  (label: 'Ranch',      icon: Symbols.grass),
  (label: 'Yacht',      icon: Symbols.directions_boat),
];

/// Const map so the icon tree-shaker can statically enumerate home icons.
const _kHomeIconMap = <int, IconData>{
  0xe318: Symbols.home,
  0xe33c: Symbols.apartment,
  0xe57c: Symbols.villa,
  0xe508: Symbols.cottage,
  0xe501: Symbols.cabin,
  0xe3a9: Symbols.location_city,
  0xe4f3: Symbols.roofing,
  0xe011: Symbols.agriculture,
  0xe3b3: Symbols.grass,
  0xe1b1: Symbols.directions_boat,
};

IconData _resolveHomeIcon(int cp) =>
    _kHomeIconMap[cp] ?? Symbols.home;

/// Available palette colors (value, Hebrew label)
const _kHomePalette = [
  (value: 0xFF00B4D8, label: 'Blue'),
  (value: 0xFF7B6FCD, label: 'Purple'),
  (value: 0xFF00C853, label: 'Green'),
  (value: 0xFFFF6B35, label: 'Orange'),
  (value: 0xFFFFD700, label: 'Gold'),
  (value: 0xFFE53935, label: 'Red'),
  (value: 0xFF00BFA5, label: 'Turquoise'),
  (value: 0xFFEC407A, label: 'Pink'),
  (value: 0xFF8D6E63, label: 'Brown'),
  (value: 0xFF90A4AE, label: 'Gray'),
];

class _HomeStylePicker extends StatelessWidget {
  final AppState state;
  const _HomeStylePicker({required this.state});

  @override
  Widget build(BuildContext context) {
    final selIcon  = state.homeIconCode;
    final selColor = state.homeColor;
    final s        = state.strings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tText2(0.08)),
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
                    _resolveHomeIcon(selIcon),
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
            s.homeTypeTitle,
            style: TextStyle(
              color: context.tText2(0.45),
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
                          : context.tText2(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? selColor.withValues(alpha: 0.60)
                            : context.tText2(0.10),
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          ht.icon,
                          color: isSel ? selColor : context.tText2(0.38),
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.homeTypeLabels[i],
                          style: TextStyle(
                            color: isSel
                                ? selColor
                                : context.tText2(0.35),
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
            s.homeColorTitle,
            style: TextStyle(
              color: context.tText2(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kHomePalette.asMap().entries.map((entry) {
              final p      = entry.value;
              final c      = Color(p.value);
              final isSel  = p.value == selColor.value;
              return Tooltip(
                message: s.homeColorLabels[entry.key],
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
                        color: isSel ? context.tText : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSel
                          ? [BoxShadow(color: c.withValues(alpha: 0.5),
                                       blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                    child: isSel
                        ? Icon(Symbols.check, color: context.tText, size: 16)
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
    for (var i = 0; i < _kHomeTypes.length; i++) {
      if (_kHomeTypes[i].icon.codePoint == code) return state.strings.homeTypeLabels[i];
    }
    return state.strings.homeTypeLabels.first;
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
            style: TextStyle(color: context.tText, fontSize: 15)),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom accent color mixer
// ─────────────────────────────────────────────────────────────
class _ColorMixTile extends StatelessWidget {
  final bool selected;
  final Color current;
  final ValueChanged<Color> onPick;
  const _ColorMixTile({
    required this.selected,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<Color>(
          context: context,
          builder: (_) => _ColorMixerDialog(initial: current),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const SweepGradient(colors: [
            Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
            Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ]),
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? context.tText : context.tText2(0.2),
              width: selected ? 2.5 : 1),
        ),
        child: Icon(Symbols.tune,
            color: Colors.white,
            size: 16,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)]),
      ),
    );
  }
}

class _ColorMixerDialog extends StatefulWidget {
  final Color initial;
  const _ColorMixerDialog({required this.initial});

  @override
  State<_ColorMixerDialog> createState() => _ColorMixerDialogState();
}

class _ColorMixerDialogState extends State<_ColorMixerDialog> {
  late double _r, _g, _b;

  @override
  void initState() {
    super.initState();
    _r = (widget.initial.r * 255.0).roundToDouble();
    _g = (widget.initial.g * 255.0).roundToDouble();
    _b = (widget.initial.b * 255.0).roundToDouble();
  }

  Color get _color => Color.fromARGB(255, _r.round(), _g.round(), _b.round());

  @override
  Widget build(BuildContext context) {
    final s = context.select<AppState, S>((st) => st.strings);
    String hex = '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return AlertDialog(
      backgroundColor: context.tCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.colorMix,
          style: TextStyle(color: context.tText, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.tText2(0.2)),
            ),
            alignment: Alignment.center,
            child: Text(hex,
                style: TextStyle(
                    color: _color.computeLuminance() > 0.6
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
          ),
          const SizedBox(height: 12),
          _slider('R', _r, const Color(0xFFE53935), (v) => setState(() => _r = v)),
          _slider('G', _g, const Color(0xFF43A047), (v) => setState(() => _g = v)),
          _slider('B', _b, const Color(0xFF1E88E5), (v) => setState(() => _b = v)),
        ],
      ),
      actions: [
        FtButton(
          label: s.cancel,
          variant: FtButtonVariant.ghost,
          onTap: () => Navigator.pop(context),
        ),
        FtButton(
          label: s.pickLabel,
          color: _color,
          onTap: () => Navigator.pop(context, _color),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, Color color, ValueChanged<double> onCh) {
    return Row(children: [
      SizedBox(width: 16,
          child: Text(label,
              style: TextStyle(color: context.tText, fontWeight: FontWeight.bold))),
      Expanded(
        child: Slider(
          value: value, min: 0, max: 255,
          activeColor: color,
          onChanged: onCh,
        ),
      ),
      SizedBox(width: 30,
          child: Text('${value.round()}',
              textAlign: TextAlign.end,
              style: TextStyle(color: context.tText2(0.7), fontSize: 12))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backup & Restore sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BackupSheet extends StatefulWidget {
  final AppState state;
  final S s;
  const _BackupSheet({required this.state, required this.s});

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  bool _busy = false;

  Future<String?> _backupFilePath() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      return '${dir.path}/fantatech_backup.json';
    } catch (_) {
      return null;
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final path = await _backupFilePath();
      if (path == null) throw Exception('no path');
      final json = jsonEncode(widget.state.exportBackup());
      await File(path).writeAsString(json, flush: true);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.backupExportDone),
          backgroundColor: AppColors.secured,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.backupImportError),
          backgroundColor: AppColors.alert,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final path = await _backupFilePath();
      if (path == null) throw Exception('no path');
      final file = File(path);
      if (!await file.exists()) throw Exception('not found');
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      await widget.state.restoreFromBackup(data);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.backupImportDone),
          backgroundColor: AppColors.secured,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.backupImportError),
          backgroundColor: AppColors.alert,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: context.tText2(0.18),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.backupTitle,
              style: TextStyle(
                  color: context.tText,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Symbols.upload, size: 18),
              label: Text(s.backupExport,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.tText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Symbols.download, size: 18),
              label: Text(s.backupImport,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.tText,
                side: BorderSide(color: context.tText2(0.18)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
