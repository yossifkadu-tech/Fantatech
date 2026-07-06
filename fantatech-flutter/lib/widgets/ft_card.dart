// ─────────────────────────────────────────────────────────────────────────────
// FtCard — FantaTech universal card system.
//
// Components:
//   FtCard        — base card: rounded corners, soft shadow, consistent padding
//   FtStatusCard  — card with coloured left-edge status strip
//   FtMetricCard  — card for large KPI values (temp, energy, %)
//   FtIconCard    — compact square icon tile (device categories, shortcuts)
//   FtListCard    — full-width row card (devices list, sensor list)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'press_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FtCard — Base card
// ─────────────────────────────────────────────────────────────────────────────

class FtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  /// When true, applies a coloured glow shadow (use for active/on devices).
  final Color? glowColor;

  const FtCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.elevation,
    this.borderRadius,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? Theme.of(context).cardColor;
    final br = borderRadius ?? AppBorderRadius.card;

    final shadows = glowColor != null
        ? AppShadows.glow(glowColor!)
        : (isDark ? AppShadows.dark : AppShadows.md);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: padding ?? AppSpacing.card,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        boxShadow: shadows,
        border: Border.all(
          color: glowColor != null
              ? glowColor!.withValues(alpha: 0.30)
              : (isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.6)
                  : AppColors.lightBorder),
          width: glowColor != null ? 1.2 : 1.0,
        ),
      ),
      child: child,
    );

    if (onTap == null && onLongPress == null) return card;

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtStatusCard — coloured left-edge status strip
// Used for: alerts, sensor cards, device status
// ─────────────────────────────────────────────────────────────────────────────

enum FtStatus { active, inactive, warning, danger, offline }

class FtStatusCard extends StatelessWidget {
  final Widget child;
  final FtStatus status;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FtStatusCard({
    super.key,
    required this.child,
    this.status = FtStatus.inactive,
    this.padding,
    this.onTap,
    this.onLongPress,
  });

  Color _stripColor() {
    switch (status) {
      case FtStatus.active:   return AppColors.success;
      case FtStatus.warning:  return AppColors.warning;
      case FtStatus.danger:   return AppColors.alert;
      case FtStatus.offline:  return AppColors.textTertiary;
      case FtStatus.inactive: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strip = _stripColor();

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppBorderRadius.card,
        boxShadow: isDark ? AppShadows.dark : AppShadows.md,
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 4,
            color: strip,
          ),
          Expanded(
            child: Padding(
              padding: padding ?? AppSpacing.card,
              child: child,
            ),
          ),
        ],
      ),
    );

    if (onTap == null && onLongPress == null) return card;

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtMetricCard — large KPI display card
// Used for: temperature, energy, humidity, percentage
// ─────────────────────────────────────────────────────────────────────────────

class FtMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const FtMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.unit,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondary;

    return FtCard(
      padding: AppSpacing.card,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + label row
          Row(
            children: [
              FtIconBadge(icon: icon, color: accentColor, size: 36),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleSm.copyWith(color: subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          // Big value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.displaySm.copyWith(color: textColor),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpacing.s4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit!,
                    style: AppTypography.titleMd.copyWith(color: subColor),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(color: subColor),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtIconCard — compact square category/shortcut tile
// ─────────────────────────────────────────────────────────────────────────────

class FtIconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? badge;

  const FtIconCard({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondary;

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: AppSpacing.p12,
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: isDark ? 0.18 : 0.10)
              : Theme.of(context).cardColor,
          borderRadius: AppBorderRadius.card,
          boxShadow: isActive
              ? AppShadows.glow(accentColor, intensity: 0.7)
              : (isDark ? AppShadows.dark : AppShadows.sm),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.35)
                : (isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.6)
                    : AppColors.lightBorder),
            width: isActive ? 1.2 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FtIconBadge(
                  icon: icon,
                  color: accentColor,
                  size: 40,
                  active: isActive,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  label,
                  style: AppTypography.titleSm.copyWith(
                    color: isActive ? textColor : subColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: _FtBadge(label: badge!),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtListCard — full-width horizontal row card
// Used for: device lists, sensor lists, activity items
// ─────────────────────────────────────────────────────────────────────────────

class FtListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isActive;

  const FtListCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondary;

    return FtCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      glowColor: isActive ? iconColor : null,
      child: Row(
        children: [
          FtIconBadge(icon: icon, color: iconColor, size: 44, active: isActive),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMd.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(color: subColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtSectionHeader — consistent section heading with optional action
// ─────────────────────────────────────────────────────────────────────────────

class FtSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  const FtSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSm.copyWith(color: context.tText),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              label: actionLabel,
              button: true,
              child: GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary),
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
// FtStatusDot — animated pulsing dot indicator
// ─────────────────────────────────────────────────────────────────────────────

class FtStatusDot extends StatefulWidget {
  final FtStatus status;
  final double size;

  const FtStatusDot({
    super.key,
    required this.status,
    this.size = 8,
  });

  @override
  State<FtStatusDot> createState() => _FtStatusDotState();
}

class _FtStatusDotState extends State<FtStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _sync();
  }

  @override
  void didUpdateWidget(FtStatusDot old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _sync();
  }

  void _sync() {
    if (widget.status == FtStatus.active) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0.6;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _color() {
    switch (widget.status) {
      case FtStatus.active:   return AppColors.success;
      case FtStatus.warning:  return AppColors.warning;
      case FtStatus.danger:   return AppColors.alert;
      case FtStatus.offline:  return AppColors.textTertiary;
      case FtStatus.inactive: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: _anim.value),
          boxShadow: widget.status == FtStatus.active
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: _anim.value * 0.6),
                    blurRadius: widget.size,
                    spreadRadius: widget.size * 0.25,
                  ),
                ]
              : const [],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtChip — small status/label chip
// ─────────────────────────────────────────────────────────────────────────────

class FtChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const FtChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadius.chip,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 11),
            const SizedBox(width: AppSpacing.s4),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FtIconBadge — coloured icon container
// ─────────────────────────────────────────────────────────────────────────────

/// Public icon badge — coloured icon container used on cards and list rows.
/// [active] adds a glow shadow and full-opacity icon tint.
class FtIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool active;

  const FtIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.icon,
        color: active
            ? color.withValues(alpha: isDark ? 0.22 : 0.14)
            : (isDark
                ? AppColors.darkCardAlt
                : AppColors.lightSurface),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : const [],
      ),
      child: Icon(
        icon,
        color: active ? color : color.withValues(alpha: isDark ? 0.55 : 0.60),
        size: size * 0.48,
      ),
    );
  }
}

class _FtBadge extends StatelessWidget {
  final String label;

  const _FtBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.alert,
        borderRadius: BorderRadius.circular(AppBorderRadius.r24),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: Colors.white,
          fontSize: 9,
        ),
      ),
    );
  }
}
