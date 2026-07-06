import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/layout_item.dart';
import '../../providers/layout_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditToolbar — slides down from the top when edit mode is active.
//
// Shows:
//   [↩ Restore Default]      Edit Layout ✎      [Done ✓]
//
// Usage:
//   Stack(children: [
//     YourContent(),
//     Positioned(top: 0, left: 0, right: 0,
//       child: EditToolbar(
//         dashboardId: DashboardId.home,
//         defaultItems: _defaultItems,
//       ),
//     ),
//   ])
// ─────────────────────────────────────────────────────────────────────────────

class EditToolbar extends StatelessWidget {
  final String dashboardId;
  final List<LayoutItem> defaultItems;

  const EditToolbar({
    super.key,
    required this.dashboardId,
    required this.defaultItems,
  });

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<LayoutProvider>();
    final isEditMode = provider.editMode;
    final accent    = Theme.of(context).colorScheme.primary;
    final isLight   = Theme.of(context).brightness == Brightness.light;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: isEditMode ? Curves.easeOutCubic : Curves.easeInCubic,
      offset: isEditMode ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEditMode ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !isEditMode,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isLight
                    ? accent.withValues(alpha: 0.10)
                    : accent.withValues(alpha: 0.18),
                border: Border(
                  bottom: BorderSide(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // ── Restore Default ───────────────────────────────────
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Symbols.refresh, size: 15),
                    label: const Text('ברירת מחדל'),
                    onPressed: () => _confirmRestore(context, provider),
                  ),

                  // ── Center title ──────────────────────────────────────
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.edit,
                            size: 14,
                            color: accent.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          'עריכת לוח',
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Done ─────────────────────────────────────────────
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Symbols.check, size: 15),
                    label: const Text('סיום'),
                    onPressed: () => provider.exitEditMode(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context, LayoutProvider provider) {
    final accent = Theme.of(context).colorScheme.primary;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Symbols.restore, color: accent, size: 22),
          const SizedBox(width: 10),
          const Text('שחזור לברירת מחדל?', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text(
          'פעולה זו תאפס את סידור הלוח לברירת המחדל. לא ניתן לבטל.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () {
              Navigator.pop(ctx);
              provider.restoreDefaults(dashboardId, defaultItems);
            },
            child: const Text('שחזר',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EditModeButton — small icon button to toggle edit mode.
// Place in the AppBar actions or the screen's header row.
// ─────────────────────────────────────────────────────────────────────────────

class EditModeButton extends StatelessWidget {
  const EditModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<LayoutProvider>();
    final isEditMode = provider.editMode;
    final accent     = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isEditMode
            ? accent.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: child,
          ),
          child: Icon(
            isEditMode ? Symbols.check : Symbols.edit,
            key: ValueKey(isEditMode),
            color: isEditMode ? accent : null,
            size: 20,
          ),
        ),
        tooltip: isEditMode ? 'סיום עריכה' : 'ערוך לוח',
        onPressed: provider.toggleEditMode,
      ),
    );
  }
}
