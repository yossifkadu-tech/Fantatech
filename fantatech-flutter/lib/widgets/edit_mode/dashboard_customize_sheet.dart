import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/layout_item.dart';
import '../../providers/layout_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardCustomizeSheet — a single, simple list for showing/hiding and
// reordering dashboard sections. Replaces the per-card "⋮" menu with one
// central place: a switch to show/hide, and up/down arrows to reorder.
// ─────────────────────────────────────────────────────────────────────────────

void showDashboardCustomizeSheet(
  BuildContext context, {
  required String dashboardId,
  required String Function(LayoutItem item) nameResolver,
  required IconData Function(LayoutItem item) iconResolver,
  bool showPageToggle = false,
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
      child: _DashboardCustomizeSheet(
        dashboardId: dashboardId,
        nameResolver: nameResolver,
        iconResolver: iconResolver,
        showPageToggle: showPageToggle,
      ),
    ),
  );
}

class _DashboardCustomizeSheet extends StatelessWidget {
  final String dashboardId;
  final String Function(LayoutItem item) nameResolver;
  final IconData Function(LayoutItem item) iconResolver;
  final bool showPageToggle;

  const _DashboardCustomizeSheet({
    required this.dashboardId,
    required this.nameResolver,
    required this.iconResolver,
    this.showPageToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LayoutProvider>();
    final items = provider.getItems(dashboardId, allItems: true);
    final accent = Theme.of(context).colorScheme.primary;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : AppColors.darkCard;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: (isLight ? Colors.black : Colors.white)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'התאמת מסך הבית',
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Symbols.close, color: context.tTextSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return _CustomizeRow(
                    dashboardId: dashboardId,
                    item: item,
                    name: nameResolver(item),
                    icon: iconResolver(item),
                    accent: accent,
                    canMoveUp: i > 0,
                    canMoveDown: i < items.length - 1,
                    showPageToggle: showPageToggle,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizeRow extends StatelessWidget {
  final String dashboardId;
  final LayoutItem item;
  final String name;
  final IconData icon;
  final Color accent;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool showPageToggle;

  const _CustomizeRow({
    required this.dashboardId,
    required this.item,
    required this.name,
    required this.icon,
    required this.accent,
    required this.canMoveUp,
    required this.canMoveDown,
    this.showPageToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LayoutProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showCustomizeDialog(context, provider, dashboardId, item, name),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      (item.config['label'] as String?)?.isNotEmpty == true
                          ? item.config['label'] as String
                          : name,
                      style: TextStyle(
                        color: item.visible ? context.tText : context.tTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Symbols.edit, size: 13, color: context.tTextSecondary.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Symbols.arrow_upward,
                size: 18,
                color: canMoveUp ? context.tTextSecondary : context.tTextSecondary.withValues(alpha: 0.25)),
            onPressed: canMoveUp
                ? () => provider.moveItem(dashboardId, item.id, up: true)
                : null,
          ),
          IconButton(
            icon: Icon(Symbols.arrow_downward,
                size: 18,
                color: canMoveDown ? context.tTextSecondary : context.tTextSecondary.withValues(alpha: 0.25)),
            onPressed: canMoveDown
                ? () => provider.moveItem(dashboardId, item.id, up: false)
                : null,
          ),
          if (showPageToggle) ...[
            const SizedBox(width: 4),
            _PageToggle(
              page: item.page,
              accent: accent,
              onChanged: (p) => provider.setItemPage(dashboardId, item.id, p),
            ),
          ],
          Switch(
            value: item.visible,
            activeTrackColor: accent,
            onChanged: (_) => provider.toggleVisibility(dashboardId, item.id),
          ),
        ],
      ),
    );
  }
}

// ─── Page toggle (1 / 2) — only shown when the caller supports paging ────────

class _PageToggle extends StatelessWidget {
  final int page;
  final Color accent;
  final ValueChanged<int> onChanged;
  const _PageToggle({required this.page, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget dot(int p) {
      final selected = page == p;
      return GestureDetector(
        onTap: () => onChanged(p),
        child: Container(
          width: 22, height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent : context.tText2(0.08),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${p + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : context.tTextSecondary,
            ),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [dot(0), dot(1)]);
  }
}

// ─── Rename + size dialog ─────────────────────────────────────────────────────

void _showCustomizeDialog(
  BuildContext context,
  LayoutProvider provider,
  String dashboardId,
  LayoutItem item,
  String defaultName,
) {
  final ctrl = TextEditingController(text: item.config['label'] as String? ?? '');
  DashboardItemSize selectedSize = item.size;
  final accent = Theme.of(context).colorScheme.primary;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('התאמת הכרזה', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('שם מותאם אישית', style: TextStyle(fontSize: 12, color: ctx.tTextSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: defaultName,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('גודל', style: TextStyle(fontSize: 12, color: ctx.tTextSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                (DashboardItemSize.sm, 'קטן'),
                (DashboardItemSize.md, 'רגיל'),
                (DashboardItemSize.lg, 'גדול'),
              ].map((e) {
                final (size, label) = e;
                final selected = selectedSize == size;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedSize = size),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? accent.withValues(alpha: 0.12) : ctx.tText2(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? accent : Colors.transparent, width: 1.4),
                      ),
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? accent : ctx.tTextSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () {
              provider.renameItem(dashboardId, item.id, ctrl.text);
              provider.resize(dashboardId, item.id, selectedSize);
              Navigator.pop(ctx);
            },
            child: const Text('שמור', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
