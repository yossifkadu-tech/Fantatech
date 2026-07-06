import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'press_scale.dart';

// ─── Size ────────────────────────────────────────────────────────────────────

enum FtButtonSize { sm, md, lg }

extension _SizeX on FtButtonSize {
  double get height   => const [36.0, 48.0, 56.0][index];
  double get iconDiam => const [36.0, 44.0, 52.0][index];
  double get fontSize => const [13.0, 15.0, 16.0][index];
  double get iconSize => const [15.0, 18.0, 20.0][index];
  double get hPad     => const [12.0, 20.0, 24.0][index];
  double get gap      => const [ 6.0,  8.0, 10.0][index];
  double get spinner  => const [14.0, 17.0, 19.0][index];
}

// ─── Variant ─────────────────────────────────────────────────────────────────

enum FtButtonVariant {
  primary,     // solid accent fill — main CTA
  secondary,   // accent tint fill + border
  ghost,       // text-only, accent colored
  danger,      // solid red fill
  dangerGhost, // text-only, red colored
  neutral,     // surface fill, subdued — cancel / dismiss
  outline,     // border-only, transparent bg — clean outlined
  floating,    // elevated pill with accent glow — inline FAB style
  ai,          // purple→indigo gradient, auto sparkle icon, AI feature actions
}

// ─── FtButton ─────────────────────────────────────────────────────────────────

/// Unified button for FantaTech screens.
///
/// Three named constructors:
///   FtButton(label: ...)           — text (+ optional icon) button
///   FtButton.iconOnly(icon: ...)   — circular icon button
///   FtButton.tile(...)             → use [FtListTile] instead
///
/// Every variant supports [loading], [expand] (full-width), and
/// [semanticLabel] for accessibility.
class FtButton extends StatelessWidget {
  final String? label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final bool loading;
  final FtButtonVariant variant;
  final FtButtonSize size;
  final bool expand;
  final Color? color;
  final String? semanticLabel;
  final bool _iconOnly;

  /// Standard text button with optional leading / trailing icon.
  const FtButton({
    super.key,
    required String this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onTap,
    this.loading = false,
    this.variant = FtButtonVariant.primary,
    this.size = FtButtonSize.md,
    this.expand = false,
    this.color,
    this.semanticLabel,
  }) : _iconOnly = false;

  /// Circular icon-only button. [icon] is stored in [leadingIcon].
  const FtButton.iconOnly({
    super.key,
    required IconData icon,
    this.onTap,
    this.loading = false,
    this.variant = FtButtonVariant.primary,
    this.size = FtButtonSize.md,
    this.color,
    this.semanticLabel,
  })  : label = null,
        leadingIcon = icon,
        trailingIcon = null,
        expand = false,
        _iconOnly = true;

  bool get _enabled => onTap != null && !loading;

  // ── Color resolution ──────────────────────────────────────────────────────

  _BtnColors _resolve(BuildContext ctx) {
    final accent  = color ?? Theme.of(ctx).colorScheme.primary;
    final isLight = Theme.of(ctx).brightness == Brightness.light;

    switch (variant) {
      case FtButtonVariant.primary:
        return _BtnColors(bg: accent, fg: Colors.white);

      case FtButtonVariant.secondary:
        return _BtnColors(
          bg: accent.withValues(alpha: 0.07),
          fg: accent,
          borderColor: accent,
        );

      case FtButtonVariant.ghost:
        return _BtnColors(bg: Colors.transparent, fg: accent);

      case FtButtonVariant.danger:
        return _BtnColors(bg: AppColors.alert, fg: Colors.white);

      case FtButtonVariant.dangerGhost:
        return _BtnColors(bg: Colors.transparent, fg: AppColors.alert);

      case FtButtonVariant.neutral:
        return _BtnColors(
          bg: isLight ? const Color(0xFFF0F2F5) : const Color(0xFF252D3D),
          fg: isLight
              ? AppColors.textSecondary
              : Colors.white.withValues(alpha: 0.65),
          borderColor:
              isLight ? const Color(0xFFDDE1E7) : const Color(0xFF3A4258),
        );

      case FtButtonVariant.outline:
        return _BtnColors(
          bg: Colors.transparent,
          fg: accent,
          borderColor: accent.withValues(alpha: 0.70),
        );

      case FtButtonVariant.floating:
        return _BtnColors(
          bg: accent,
          fg: Colors.white,
          shadow: AppShadows.glow(accent, intensity: 0.55),
        );

      case FtButtonVariant.ai:
        return _BtnColors(
          bg: const Color(0xFF6366F1),
          fg: Colors.white,
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  // ── Theme radius ───────────────────────────────────────────────────────────

  double _radius(BuildContext ctx) {
    if (variant == FtButtonVariant.floating ||
        variant == FtButtonVariant.ai) return 14.0;
    final shape = Theme.of(ctx)
        .elevatedButtonTheme
        .style
        ?.shape
        ?.resolve(const <WidgetState>{});
    if (shape is RoundedRectangleBorder) {
      final br = shape.borderRadius;
      if (br is BorderRadius) return br.topLeft.x;
    }
    return 12.0;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sz = size;
    final c  = _resolve(context);
    final r  = _iconOnly ? 9999.0 : _radius(context);

    final fg   = _enabled ? c.fg : c.fg.withValues(alpha: 0.45);
    final bg   = _enabled ? c.bg : c.bg.withValues(alpha: 0.50);
    final bc   = _enabled ? c.borderColor : c.borderColor?.withValues(alpha: 0.35);
    final grad = _enabled ? c.gradient : null;
    final shad = _enabled ? c.shadow : null;

    final decoration = BoxDecoration(
      color: grad != null ? null : bg,
      gradient: grad,
      borderRadius: BorderRadius.circular(r),
      border: bc != null ? Border.all(color: bc, width: 1.5) : null,
      boxShadow: shad,
    );

    // AI variant auto-injects a sparkle icon when no leadingIcon provided
    final effectiveLeading = leadingIcon ??
        (variant == FtButtonVariant.ai && !_iconOnly
            ? Symbols.auto_awesome
            : null);

    Widget content;
    if (loading) {
      content = SizedBox(
        width: sz.spinner, height: sz.spinner,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(fg),
        ),
      );
    } else if (_iconOnly) {
      content = Icon(leadingIcon, color: fg, size: sz.iconSize);
    } else {
      final items = <Widget>[];
      if (effectiveLeading != null) {
        items.add(Icon(effectiveLeading, color: fg, size: sz.iconSize));
        items.add(SizedBox(width: sz.gap));
      }
      items.add(Text(
        label!,
        style: TextStyle(
          color: fg,
          fontSize: sz.fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.25,
        ),
      ));
      if (trailingIcon != null) {
        items.add(SizedBox(width: sz.gap));
        items.add(Icon(trailingIcon, color: fg, size: sz.iconSize));
      }
      content = Row(mainAxisSize: MainAxisSize.min, children: items);
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: _enabled,
      child: _BtnInk(
        decoration: decoration,
        width: _iconOnly ? sz.iconDiam : (expand ? double.infinity : null),
        height: _iconOnly ? sz.iconDiam : sz.height,
        padding: _iconOnly
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(horizontal: sz.hPad),
        radius: r,
        splashColor: fg.withValues(alpha: 0.22),
        onTap: _enabled ? onTap : null,
        child: content,
      ),
    );
  }
}

// ── Internal color bundle ─────────────────────────────────────────────────────

class _BtnColors {
  final Color bg;
  final Color fg;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  const _BtnColors({
    required this.bg,
    required this.fg,
    this.borderColor,
    this.gradient,
    this.shadow,
  });
}

// ── Ripple + scale ink wrapper ────────────────────────────────────────────────
//
// Paints a BoxDecoration via Ink so the M3 ripple renders on top, then wraps
// the whole widget in a Transform.scale for the press-down spring feedback.

class _BtnInk extends StatefulWidget {
  final BoxDecoration decoration;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final double radius;
  final Color splashColor;
  final VoidCallback? onTap;
  final Widget child;

  const _BtnInk({
    required this.decoration,
    required this.width,
    required this.height,
    required this.padding,
    required this.radius,
    required this.splashColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_BtnInk> createState() => _BtnInkState();
}

class _BtnInkState extends State<_BtnInk> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: widget.decoration,
              child: InkWell(
                onTap: widget.onTap != null
                    ? () {
                        _ctrl.forward().then((_) => _ctrl.reverse());
                        widget.onTap!();
                      }
                    : null,
                onTapDown: widget.onTap != null
                    ? (_) {
                        Haptics.light();
                        _ctrl.forward();
                      }
                    : null,
                onTapUp: (_) => _ctrl.reverse(),
                onTapCancel: () => _ctrl.reverse(),
                splashColor: widget.splashColor,
                highlightColor: widget.splashColor.withValues(alpha: 0.07),
                child: Padding(
                  padding: widget.padding,
                  child: Center(
                    widthFactor: widget.width == null ? 1.0 : null,
                    child: widget.child,
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

// ─── FtFAB — floating action button ──────────────────────────────────────────
//
// Pill-shaped elevated button for primary screen actions.
// Extended (icon + label) when [label] is provided, circular otherwise.

class FtFAB extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;
  final FtButtonSize size;

  const FtFAB({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.color,
    this.size = FtButtonSize.lg,
  });

  @override
  Widget build(BuildContext context) {
    final accent   = color ?? Theme.of(context).colorScheme.primary;
    final hasLabel = label != null;
    final h        = switch (size) {
      FtButtonSize.sm => 44.0,
      FtButtonSize.md => 52.0,
      FtButtonSize.lg => 60.0,
    };
    final iconSz   = switch (size) {
      FtButtonSize.sm => 18.0,
      FtButtonSize.md => 20.0,
      FtButtonSize.lg => 22.0,
    };
    final fontSize = switch (size) {
      FtButtonSize.sm => 13.0,
      FtButtonSize.md => 14.0,
      FtButtonSize.lg => 15.0,
    };

    return _BtnInk(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: AppShadows.glow(accent, intensity: 0.55),
      ),
      width:   hasLabel ? null : h,
      height:  h,
      padding: hasLabel
          ? EdgeInsets.symmetric(horizontal: h * 0.37)
          : EdgeInsets.zero,
      radius:  h / 2,
      splashColor: Colors.white.withValues(alpha: 0.22),
      onTap:   onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: iconSz),
          if (hasLabel) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FtListTile ───────────────────────────────────────────────────────────────

/// Full-width menu / settings row tile.
///
/// Designed for profile menus, settings sheets, and tappable list rows.
/// Shows a colored icon container, title text, optional subtitle, and an
/// optional trailing widget (defaults to a chevron arrow when [onTap] != null).
class FtListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;
  final String? badgeText;
  final Color? badgeColor;
  final bool destructive;

  const FtListTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showArrow = true,
    this.onTap,
    this.badgeText,
    this.badgeColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = destructive
        ? AppColors.alert
        : (isLight ? AppColors.textPrimary : Colors.white);
    final subColor = isLight
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.50);
    final dividerColor = isLight
        ? AppColors.lightBorder
        : AppColors.darkBorder;

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && showArrow && onTap != null) {
      trailingWidget = Icon(
        Symbols.chevron_right,
        color: subColor,
        size: 20,
      );
    }

    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dividerColor.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Badge
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: badgeColor ?? AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (trailingWidget != null) ...[
            const SizedBox(width: 8),
            trailingWidget,
          ],
        ],
      ),
    );

    if (onTap == null) return tile;

    return Semantics(
      button: true,
      label: title,
      child: PressScale(
        onTap: onTap,
        scale: 0.985,
        child: tile,
      ),
    );
  }
}
