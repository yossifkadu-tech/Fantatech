import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Reusable state views: EmptyState, ErrorState, and skeleton loaders.
// Fully theme-aware — works in both light and dark mode.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Friendly empty-state placeholder.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textSecondary;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.lightSurface;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : AppColors.textTertiary;

    return Center(
      child: Padding(
        padding: AppSpacing.p32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(color: textColor),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: subColor, height: 1.6),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.button,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s24,
                    vertical: AppSpacing.s12,
                  ),
                  textStyle: AppTypography.labelLg,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error placeholder with a retry button.
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String retryLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    required this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: AppSpacing.p32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.cloud_off,
                color: AppColors.alert.withValues(alpha: 0.75),
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(color: textColor),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: subColor, height: 1.6),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Symbols.refresh, size: 18),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.lightBorder,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.button,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s24,
                    vertical: AppSpacing.s12,
                  ),
                  textStyle: AppTypography.labelLg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated shimmer box — building block for skeleton loaders.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base  = isDark ? 0.04 : 0.06;
    final shine = isDark ? 0.12 : 0.14;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * _ctrl.value, 0),
              end: Alignment(1 - 2 * _ctrl.value, 0),
              colors: [
                Colors.black.withValues(alpha: base),
                Colors.black.withValues(alpha: shine),
                Colors.black.withValues(alpha: base),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton card placeholder shaped like a device/list tile.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder,
        ),
        boxShadow: isDark ? AppShadows.dark : AppShadows.sm,
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 44, height: 44, radius: 12),
          SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 13),
                SizedBox(height: AppSpacing.s8),
                SkeletonBox(width: 80, height: 10),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s12),
          SkeletonBox(width: 40, height: 22, radius: 11),
        ],
      ),
    );
  }
}

/// A column of skeleton tiles — drop-in loading list.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screen,
      children: List.generate(count, (_) => const SkeletonTile()),
    );
  }
}

/// Skeleton grid for device cards.
class SkeletonGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const SkeletonGrid({super.key, this.count = 6, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: AppSpacing.screen,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.s8,
        crossAxisSpacing: AppSpacing.s8,
        childAspectRatio: 1.0,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppBorderRadius.card,
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder,
          ),
          boxShadow: isDark ? AppShadows.dark : AppShadows.sm,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 40, height: 40, radius: 12),
                SkeletonBox(width: 36, height: 22, radius: 11),
              ],
            ),
            Spacer(),
            SkeletonBox(height: 13),
            SizedBox(height: 6),
            SkeletonBox(width: 60, height: 10),
          ],
        ),
      ),
    );
  }
}
