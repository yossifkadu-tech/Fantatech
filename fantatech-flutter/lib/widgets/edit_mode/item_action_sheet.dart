import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/layout_item.dart';
import '../../providers/layout_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ItemActionSheet — bottom sheet for editing a single layout item.
//
// Actions: Resize (S/M/L), Toggle visibility, Toggle pin,
//          Duplicate, Delete (with confirmation dialog).
// ─────────────────────────────────────────────────────────────────────────────

void showItemActionSheet(
  BuildContext context, {
  required String dashboardId,
  required LayoutItem item,
  String? displayName,
  IconData? icon,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<LayoutProvider>(),
      child: _ItemActionSheet(
        dashboardId: dashboardId,
        item: item,
        displayName: displayName ?? item.type,
        icon: icon ?? Symbols.widgets,
      ),
    ),
  );
}

class _ItemActionSheet extends StatelessWidget {
  final String dashboardId;
  final LayoutItem item;
  final String displayName;
  final IconData icon;

  const _ItemActionSheet({
    required this.dashboardId,
    required this.item,
    required this.displayName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LayoutProvider>();
    // Reload item from provider to get live state
    final live = provider
            .getItems(dashboardId, allItems: true)
            .cast<LayoutItem?>()
            .firstWhere((i) => i?.id == item.id, orElse: () => null) ??
        item;

    final accent  = Theme.of(context).colorScheme.primary;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : AppColors.darkCard;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: (isLight ? Colors.black : Colors.white)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Item header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      live.visible ? 'גלוי' : 'מוסתר',
                      style: TextStyle(
                        color: live.visible
                            ? AppColors.success
                            : context.tTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Close
              IconButton(
                icon: Icon(Symbols.close,
                    color: context.tTextSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Resize section ─────────────────────────────────────────────
          _SectionLabel(context: context, label: 'גודל'),
          const SizedBox(height: 10),
          _SizePicker(
            current: live.size,
            onSelect: (s) {
              provider.resize(dashboardId, live.id, s);
            },
          ),

          const SizedBox(height: 20),
          Divider(color: context.tBorder.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),

          // ── Actions ────────────────────────────────────────────────────
          _ActionRow(
            icon: Symbols.arrow_upward,
            label: 'הזז למעלה',
            onTap: () => provider.moveItem(dashboardId, live.id, up: true),
          ),
          _ActionRow(
            icon: Symbols.arrow_downward,
            label: 'הזז למטה',
            onTap: () => provider.moveItem(dashboardId, live.id, up: false),
          ),
          _ActionRow(
            icon: live.visible
                ? Symbols.visibility_off
                : Symbols.visibility,
            label: live.visible ? 'הסתר ווידג\'ט' : 'הצג ווידג\'ט',
            onTap: () {
              provider.toggleVisibility(dashboardId, live.id);
              Navigator.pop(context);
            },
          ),
          _ActionRow(
            icon: live.pinned
                ? Symbols.push_pin
                : Symbols.push_pin,
            label: live.pinned ? 'בטל הצמדה' : 'הצמד לראש',
            iconColor: live.pinned ? accent : null,
            onTap: () {
              provider.togglePin(dashboardId, live.id);
              Navigator.pop(context);
            },
          ),
          _ActionRow(
            icon: Symbols.content_copy,
            label: 'שכפל ווידג\'ט',
            onTap: () {
              provider.duplicate(dashboardId, live.id);
              Navigator.pop(context);
            },
          ),
          _ActionRow(
            icon: Symbols.delete,
            label: 'מחק ווידג\'ט',
            iconColor: AppColors.alert,
            labelColor: AppColors.alert,
            onTap: () => _confirmDelete(context, provider, live),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, LayoutProvider provider, LayoutItem live) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('מחיקת ווידג\'ט?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '"$displayName" יוסר מהלוח. ניתן לשחזר על ידי איפוס ברירת המחדל.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close sheet
              provider.deleteItem(dashboardId, live.id);
            },
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Size picker ──────────────────────────────────────────────────────────────

class _SizePicker extends StatelessWidget {
  final DashboardItemSize current;
  final ValueChanged<DashboardItemSize> onSelect;

  const _SizePicker({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    const sizes = [
      (DashboardItemSize.sm, 'קטן', Symbols.crop_portrait),
      (DashboardItemSize.md, 'בינוני', Symbols.crop_landscape),
      (DashboardItemSize.lg, 'גדול', Symbols.crop_free),
    ];
    return Row(
      children: sizes.map((s) {
        final (size, label, icon) = s;
        final selected = current == size;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.12)
                    : (Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFF5F7FA)
                        : AppColors.darkCardAlt),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 20,
                      color: selected ? accent : context.tTextSecondary),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? accent : context.tTextSecondary,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final BuildContext context;
  final String label;
  const _SectionLabel({required this.context, required this.label});

  @override
  Widget build(BuildContext _) => Text(
        label,
        style: TextStyle(
          color: context.tTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = labelColor ?? context.tText;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: iconColor ?? context.tTextSecondary),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
