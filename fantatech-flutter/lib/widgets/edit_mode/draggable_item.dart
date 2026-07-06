import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/layout_item.dart';
import '../../providers/layout_provider.dart';
import '../../theme/app_theme.dart';
import 'item_action_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DraggableItem — wraps any widget to become editable in Edit Mode.
//
// In normal mode: renders [child] transparently.
// In edit mode:
//   • Subtle ±1° wiggle animation (iOS home-screen style)
//   • Left: drag handle (≡) — works with ReorderableListView
//   • Right: ⋮ action button — opens ItemActionSheet
//   • Hidden items appear as 35% opacity with an eye-slash overlay
//   • Pinned items show an accent pin badge in the top corner
//
// Usage inside ReorderableListView:
//   ReorderableDragStartListener(
//     index: i,
//     key: ValueKey(item.id),
//     child: DraggableItem(
//       dashboardId: dashboardId,
//       item: item,
//       displayName: 'Weather',
//       icon: Symbols.cloud,
//       child: WeatherWidget(),
//     ),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class DraggableItem extends StatefulWidget {
  final String dashboardId;
  final LayoutItem item;
  final Widget child;
  final String? displayName;
  final IconData? icon;

  const DraggableItem({
    super.key,
    required this.dashboardId,
    required this.item,
    required this.child,
    this.displayName,
    this.icon,
  });

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleCtrl;
  late final Animation<double> _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _wiggle = Tween<double>(begin: -0.018, end: 0.018).animate(
      CurvedAnimation(parent: _wiggleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DraggableItem old) {
    super.didUpdateWidget(old);
    final editMode = context.read<LayoutProvider>().editMode;
    _updateWiggle(editMode);
  }

  void _updateWiggle(bool editMode) {
    if (editMode && !_wiggleCtrl.isAnimating) {
      _wiggleCtrl.repeat(reverse: true);
    } else if (!editMode && _wiggleCtrl.isAnimating) {
      _wiggleCtrl.stop();
      _wiggleCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _wiggleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<LayoutProvider>();
    final editMode  = provider.editMode;
    final item      = widget.item;
    final accent    = Theme.of(context).colorScheme.primary;
    final isLight   = Theme.of(context).brightness == Brightness.light;

    _updateWiggle(editMode);

    if (!editMode) return widget.child;

    // ── Hidden item overlay ───────────────────────────────────────
    Widget content = widget.child;
    if (!item.visible) {
      content = Stack(
        children: [
          Opacity(opacity: 0.30, child: widget.child),
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.visibility_off,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('מוסתר',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ── Edit mode chrome ──────────────────────────────────────────
    Widget editChrome = Stack(
      children: [
        // Item with edit border
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.visible
                  ? accent.withValues(alpha: 0.45)
                  : Colors.grey.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.5),
            child: content,
          ),
        ),

        // ── Drag handle (left / leading) ─────────────────────────
        Positioned(
          top: 0, bottom: 0,
          left: 12,
          child: Center(
            child: Icon(
              Symbols.drag_indicator,
              size: 22,
              color: isLight
                  ? Colors.black.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),

        // ── Action button (right / trailing) ─────────────────────
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () => showItemActionSheet(
              context,
              dashboardId: widget.dashboardId,
              item: item,
              displayName: widget.displayName,
              icon: widget.icon,
            ),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.darkCard.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Symbols.more_horiz,
                size: 16,
                color: isLight ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
        ),

        // ── Pinned badge ──────────────────────────────────────────
        if (item.pinned)
          Positioned(
            top: 8, left: 12,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: accent.withValues(alpha: 0.5), width: 1),
              ),
              child: Icon(Symbols.push_pin,
                  size: 11, color: accent),
            ),
          ),
      ],
    );

    // ── Wiggle ────────────────────────────────────────────────────
    return AnimatedBuilder(
      animation: _wiggle,
      builder: (_, child) => Transform.rotate(
        angle: _wiggle.value,
        child: child,
      ),
      child: editChrome,
    );
  }
}
