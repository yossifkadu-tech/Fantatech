import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HaAutomationsScreen — live list of HA automations
//
// • List        — reads from HaProvider.automations (WS real-time, no manual fetch)
// • הפעלה       — "ON"  pill button enables the automation   (turn_on)
// • כיבוי       — "OFF" pill button disables the automation  (turn_off)
// • ▶ Trigger   — fires the automation once immediately
// • Search bar  — filter by name
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/layout_item.dart';
import '../../services/ha/ha_entity.dart';
import '../../services/ha/ha_provider.dart';
import '../../widgets/edit_mode/edit_toolbar.dart';
import '../../widgets/edit_mode/reorderable_dashboard.dart';

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _card    = Color(0xFF21262D);
const _border  = Color(0xFF30363D);
const _orange  = Color(0xFFFF6B00);
const _green   = Color(0xFF3FB950);
const _red     = Color(0xFFF85149);
const _text1   = Color(0xFFE6EDF3);
const _text2   = Color(0xFF8B949E);

class HaAutomationsScreen extends StatefulWidget {
  const HaAutomationsScreen({super.key});

  @override
  State<HaAutomationsScreen> createState() => _HaAutomationsScreenState();
}

class _HaAutomationsScreenState extends State<HaAutomationsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ha   = context.watch<HaProvider>();
    final list = ha.automations;

    final filtered = (_query.isEmpty
        ? List<HaEntity>.from(list)
        : list.where((e) =>
            e.friendlyName.toLowerCase().contains(_query.toLowerCase()) ||
            e.entityId.toLowerCase().contains(_query.toLowerCase())).toList())
      ..sort((a, b) {
        // on automations float to top
        if (a.isOn == b.isOn) {
          return a.friendlyName.compareTo(b.friendlyName);
        }
        return a.isOn ? -1 : 1;
      });

    // Build default layout items from the current (filtered) automation list.
    final defaultItems = filtered.asMap().entries.map((e) => LayoutItem(
          id: 'auto_${e.value.entityId}',
          type: 'automation',
          config: {
            'entityId': e.value.entityId,
            'label': e.value.friendlyName,
          },
          order: e.key,
        )).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Search bar + edit mode button ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _SearchBar(controller: _search, onChanged: (v) {
                    setState(() => _query = v);
                  }),
                ),
                const SizedBox(width: 8),
                const EditModeButton(dashboardId: 'ha_automations'),
              ],
            ),
          ),

          // ── Summary chip ───────────────────────────────────────────
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _SummaryChip(
                    label: '${list.where((e) => e.isOn).length} פעילות',
                    color: _green,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: '${list.where((e) => !e.isOn).length} מושבתות',
                    color: _text2,
                  ),
                ],
              ),
            ),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: list.isEmpty
                ? _emptyState(ha.isConnected)
                : filtered.isEmpty
                    ? const Center(
                        child: Text('אין תוצאות',
                            style: TextStyle(color: _text2)))
                    : ReorderableDashboard(
                        dashboardId: 'ha_automations',
                        defaultItems: defaultItems,
                        nameResolver: (item) =>
                            item.config['label'] as String? ?? item.type,
                        iconResolver: (_) => Symbols.auto_awesome,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemBuilder: (ctx, item) {
                          final entityId =
                              item.config['entityId'] as String?;
                          final auto = filtered.firstWhere(
                            (a) => a.entityId == entityId,
                            orElse: () => filtered.first,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AutomationRow(auto: auto),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool connected) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected
                ? Symbols.auto_awesome
                : Symbols.wifi_off,
            color: _text2, size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            connected
                ? 'אין אוטומציות ב-Home Assistant'
                : 'לא מחובר ל-Home Assistant',
            style: const TextStyle(color: _text2),
          ),
        ],
      ),
    );
  }
}

// ── Automation row ────────────────────────────────────────────────────────────

class _AutomationRow extends StatelessWidget {
  final HaEntity auto;
  const _AutomationRow({required this.auto});

  @override
  Widget build(BuildContext context) {
    final ha     = context.read<HaProvider>();
    final isOn   = auto.state == 'on';
    final last   = auto.attributes['last_triggered'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn
              ? _green.withValues(alpha: 0.28)
              : _border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + name + trigger btn ─────────────────────
          Row(
            children: [
              // Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isOn
                      ? _orange.withValues(alpha: 0.12)
                      : _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Symbols.auto_awesome,
                  color: isOn ? _orange : _text2,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Name + last triggered
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auto.friendlyName,
                      style: const TextStyle(
                          color: _text1,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (last != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'הופעל לאחרונה: ${_fmt(last)}',
                        style: const TextStyle(
                            color: _text2, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              // ▶ Trigger button
              _TriggerBtn(
                onTap: () => ha.automationTrigger(auto.entityId),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── ON / OFF action buttons ─────────────────────────────────
          Row(
            children: [
              // הפעלה — Turn On
              Expanded(
                child: _ActionBtn(
                  label: 'הפעלה',
                  icon: Symbols.power_settings_new,
                  active: isOn,
                  activeColor: _green,
                  onTap: isOn ? null : () => ha.automationEnable(auto.entityId),
                ),
              ),
              const SizedBox(width: 8),

              // כיבוי — Turn Off
              Expanded(
                child: _ActionBtn(
                  label: 'כיבוי',
                  icon: Symbols.power_off,
                  active: !isOn,
                  activeColor: _red,
                  onTap: !isOn ? null : () => ha.automationDisable(auto.entityId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'לפני רגע';
      if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק\'';
      if (diff.inHours   < 24) return 'לפני ${diff.inHours} שע\'';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Action button (ON / OFF pill) ─────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     active;
  final Color    activeColor;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = onTap == null; // already in this state

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.15)
              : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.45)
                : _border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active
                  ? activeColor
                  : dimmed
                      ? _text2.withValues(alpha: 0.4)
                      : _text2,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active
                    ? activeColor
                    : dimmed
                        ? _text2.withValues(alpha: 0.4)
                        : _text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trigger button ────────────────────────────────────────────────────────────

class _TriggerBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _TriggerBtn({required this.onTap});

  @override
  State<_TriggerBtn> createState() => _TriggerBtnState();
}

class _TriggerBtnState extends State<_TriggerBtn> {
  bool _flashing = false;

  void _tap() {
    widget.onTap();
    setState(() => _flashing = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _flashing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: _flashing
              ? _orange.withValues(alpha: 0.3)
              : _orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: _flashing
                ? _orange
                : _orange.withValues(alpha: 0.35),
          ),
        ),
        child: const Icon(
          Symbols.play_arrow,
          color: _orange,
          size: 18,
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Symbols.search, color: _text2, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: _text1, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'חפש אוטומציה…',
                hintStyle: TextStyle(color: _text2, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Symbols.close, color: _text2, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
