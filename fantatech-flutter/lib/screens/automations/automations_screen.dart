import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../models/device_capabilities.dart';
import '../../models/layout_item.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/edit_mode/edit_toolbar.dart';
import '../../widgets/edit_mode/reorderable_dashboard.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  int _tabIndex = 0; // 0 = all, 1 = recommendations

  // Shabbat automations — resolved in the current language.
  List<_AutomationMeta> _shabbatAutomationsFor(S s) => [
    _AutomationMeta(
      icon: Symbols.wb_twilight,
      iconBg: const Color(0xFF2A2000),
      iconColor: const Color(0xFFFFD700),
      name: s.shabbatCandles,
      description: s.shabbatCandlesDesc,
    ),
    _AutomationMeta(
      icon: Symbols.nights_stay,
      iconBg: const Color(0xFF1A0A2A),
      iconColor: const Color(0xFF9B8CF5),
      name: s.shabbatHavdalah,
      description: s.shabbatHavdalahDesc,
    ),
  ];

  // Recommended automations — resolved in the current language.
  List<_AutomationMeta> _recommendationsFor(S s) => [
    _AutomationMeta(
      icon: Symbols.wb_sunny,
      iconBg: const Color(0xFF2A1F00),
      iconColor: const Color(0xFFFFB300),
      name: s.recPeakName,
      description: s.recPeakDesc,
    ),
    _AutomationMeta(
      icon: Symbols.security,
      iconBg: const Color(0xFF0A1A2A),
      iconColor: AppColors.primary,
      name: s.recTravelName,
      description: s.recTravelDesc,
    ),
    _AutomationMeta(
      icon: Symbols.thermostat,
      iconBg: const Color(0xFF1A0A0A),
      iconColor: const Color(0xFFEA4335),
      name: s.recTempName,
      description: s.recTempDesc,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.automationsTitle),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _SegmentedTabs(
                index: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
                labelAll: s.automationsAll,
                labelRec: s.automationsRec,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _tabIndex == 0
                  ? _AllAutomationsList(state: state)
                  : _RecommendationsList(
                      items: _recommendationsFor(s),
                      shabbatItems: state.keepShabbat
                          ? _shabbatAutomationsFor(s)
                          : null,
                      shabbatLabel: s.shabbatSection,
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: _tabIndex == 0
          ? _AddFab(label: s.addAutomation, onTap: () => _showAddSheet(context, state))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAddSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddAutomationSheet(state: state),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Symbols.chevron_right,
                color: context.tText,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const EditModeButton(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Segmented tabs
// ─────────────────────────────────────────────────────────────
class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final String labelAll;
  final String labelRec;

  const _SegmentedTabs({
    required this.index,
    required this.onChanged,
    required this.labelAll,
    required this.labelRec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Row(
        children: [
          _Tab(
            label: labelAll,
            active: index == 0,
            onTap: () => onChanged(0),
            first: true,
          ),
          _Tab(
            label: labelRec,
            active: index == 1,
            onTap: () => onChanged(1),
            first: false,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool first;

  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.first,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? context.tText : context.tText2(0.54),
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// All automations list (from AppState)
// ─────────────────────────────────────────────────────────────
class _AllAutomationsList extends StatelessWidget {
  final AppState state;
  const _AllAutomationsList({required this.state});

  static IconData _iconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('לילה')  || n.contains('night'))   return Symbols.nightlight_round;
    if (n.contains('בוקר')  || n.contains('morning')) return Symbols.wb_sunny;
    if (n.contains('יציאה') || n.contains('leav'))    return Symbols.exit_to_app;
    if (n.contains('כניסה') || n.contains('חזרה') || n.contains('arriv') || n.contains('home')) return Symbols.home;
    if (n.contains('חיסכון')|| n.contains('חשמל') || n.contains('energy') || n.contains('power')) return Symbols.bolt;
    if (n.contains('motion') || n.contains('תנועה'))  return Symbols.directions_run;
    if (n.contains('light')  || n.contains('אור'))    return Symbols.lightbulb;
    if (n.contains('lock')   || n.contains('נעל'))    return Symbols.lock;
    if (n.contains('smoke')  || n.contains('עשן'))    return Symbols.smoke_free;
    if (n.contains('water')  || n.contains('מים'))    return Symbols.water_drop;
    return Symbols.auto_awesome;
  }

  static Color _colorForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('לילה')  || n.contains('night'))   return const Color(0xFF6366F1);
    if (n.contains('בוקר')  || n.contains('morning')) return const Color(0xFFFFB300);
    if (n.contains('יציאה') || n.contains('leav'))    return AppColors.primary;
    if (n.contains('כניסה') || n.contains('חזרה') || n.contains('arriv') || n.contains('home')) return AppColors.secured;
    if (n.contains('חיסכון')|| n.contains('חשמל') || n.contains('energy') || n.contains('power')) return AppColors.networkColor;
    if (n.contains('motion') || n.contains('תנועה'))  return const Color(0xFFF59E0B);
    if (n.contains('light')  || n.contains('אור'))    return const Color(0xFFF59E0B);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    // Watch AppState directly so this widget rebuilds whenever locale changes.
    final liveState   = context.watch<AppState>();
    final automations = liveState.automations;
    final strings     = liveState.strings;

    // Build default layout items from the live automation list.
    final defaultItems = automations.asMap().entries.map((e) => LayoutItem(
          id: 'local_auto_${e.value.id}',
          type: 'local_automation',
          config: {'autoId': e.value.id},
          order: e.key,
        )).toList();

    return ReorderableDashboard(
          dashboardId: DashboardId.automations,
          defaultItems: defaultItems,
          nameResolver: (item) {
            final autoId = item.config['autoId'] as String?;
            final auto = automations.firstWhere(
              (a) => a.id == autoId,
              orElse: () => automations.isNotEmpty ? automations.first : Automation(id: '', name: item.type, condition: '', action: ''),
            );
            return strings.translateAutomation(auto.name);
          },
          iconResolver: (item) {
            final autoId = item.config['autoId'] as String?;
            final auto = automations.firstWhere(
              (a) => a.id == autoId,
              orElse: () => automations.isNotEmpty ? automations.first : Automation(id: '', name: '', condition: '', action: ''),
            );
            return _iconForName(auto.name);
          },
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          itemBuilder: (ctx, item) {
            final autoId = item.config['autoId'] as String?;
            final matchIdx = automations.indexWhere((a) => a.id == autoId);
            if (matchIdx == -1) return const SizedBox.shrink();
            final auto  = automations[matchIdx];
            final color = _colorForName(auto.name);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AutomationCard(
                icon: _iconForName(auto.name),
                iconColor: color,
                iconBg: color.withValues(alpha: 0.12),
                name: strings.translateAutomation(auto.name),
                description:
                    '${strings.translateAutomation(auto.condition)} — ${strings.translateAutomation(auto.action)}',
                enabled: auto.isEnabled,
                rawName: strings.translateAutomation(auto.name),
                rawCondition: strings.translateAutomation(auto.condition),
                rawAction: strings.translateAutomation(auto.action),
                onToggle: () => liveState.toggleAutomation(auto.id),
                onSave: (n, c, a) =>
                    liveState.updateAutomation(auto.id, name: n, condition: c, action: a),
                onDelete: () => _confirmDelete(ctx, liveState, auto),
              ),
            );
          },
        );
  }

  void _confirmDelete(BuildContext context, AppState state, Automation auto) {
    final s = state.strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${s.delete} ${s.automationsTitle}',
          style: TextStyle(color: context.tText),
        ),
        content: Text(
          '"${s.translateAutomation(auto.name)}"?',
          style: TextStyle(color: context.tText2(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: TextStyle(color: context.tText2(0.54))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.deleteAutomation(auto.id);
            },
            child: Text(
              s.delete,
              style: TextStyle(color: AppColors.unsecured),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recommendations list — tappable icon adds automation inline
// ─────────────────────────────────────────────────────────────
class _RecommendationsList extends StatelessWidget {
  final List<_AutomationMeta> items;
  final List<_AutomationMeta>? shabbatItems;
  final String shabbatLabel;
  const _RecommendationsList({
    required this.items,
    this.shabbatItems,
    this.shabbatLabel = 'Shabbat',
  });

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Row(
          children: [
            const Icon(Symbols.auto_awesome,
                color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      );

  Widget _cardFor(_AutomationMeta item, AppState state) => _AutomationCard(
        icon: item.icon,
        iconColor: item.iconColor,
        iconBg: item.iconBg,
        name: item.name,
        description: item.description,
        enabled: false,
        rawName: item.name,
        rawCondition: '',
        rawAction: item.description,
        onToggle: () {},
        onSave: (name, cond, action) {
          state.addAutomation(Automation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name.isEmpty ? item.name : name,
            condition: cond,
            action: action,
          ));
        },
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasShabbat = shabbatItems != null && shabbatItems!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      children: [
        if (hasShabbat) ...[
          _sectionHeader(shabbatLabel),
          ...shabbatItems!.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _cardFor(item, state),
              )),
          const SizedBox(height: 8),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 16),
        ],
        ...items.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: e.key < items.length - 1 ? 12 : 0),
              child: Builder(builder: (ctx) {
                final item = e.value;
                return _AutomationCard(
          icon: item.icon,
          iconColor: item.iconColor,
          iconBg: item.iconBg,
          name: item.name,
          description: item.description,
          enabled: false,
          rawName: item.name,
          rawCondition: '',
          rawAction: item.description,
          onToggle: () {},
          onSave: (name, cond, action) {
            state.addAutomation(Automation(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name.isEmpty ? item.name : name,
              condition: cond,
              action: action,
            ));
          },
        );
              }),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Automation card — tappable icon expands inline editor
// ─────────────────────────────────────────────────────────────
class _AutomationCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String name;
  final String description;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final bool isRecommendation = false;
  final String rawName;
  final String rawCondition;
  final String rawAction;
  final void Function(String name, String cond, String action)? onSave;

  const _AutomationCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.name,
    required this.description,
    required this.enabled,
    required this.onToggle,
    this.onDelete,
    this.rawName = '',
    this.rawCondition = '',
    this.rawAction = '',
    this.onSave,
  });

  @override
  State<_AutomationCard> createState() => _AutomationCardState();
}

class _AutomationCardState extends State<_AutomationCard> {
  bool _expanded = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _condCtrl;
  late final TextEditingController _actionCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.rawName);
    _condCtrl = TextEditingController(text: widget.rawCondition);
    _actionCtrl = TextEditingController(text: widget.rawAction);
  }

  @override
  void didUpdateWidget(_AutomationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers when locale changes (rawName/rawCondition/rawAction update)
    if (oldWidget.rawName != widget.rawName) {
      _nameCtrl.text = widget.rawName;
    }
    if (oldWidget.rawCondition != widget.rawCondition) {
      _condCtrl.text = widget.rawCondition;
    }
    if (oldWidget.rawAction != widget.rawAction) {
      _actionCtrl.text = widget.rawAction;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _condCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isHebrew = state.locale == AppLocale.hebrew;
    final textDir = state.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.45)
              : widget.enabled
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : context.tText2(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Tappable icon
                GestureDetector(
                  onTap: widget.onSave == null
                      ? null
                      : () => setState(() => _expanded = !_expanded),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : widget.iconBg,
                      borderRadius: BorderRadius.circular(13),
                      border: _expanded
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      _expanded ? Symbols.close : widget.icon,
                      color: _expanded ? AppColors.primary : widget.iconColor,
                      size: 23,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          color: context.tText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: context.tText2(0.45),
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action buttons
                if (!widget.isRecommendation)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onDelete != null)
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            width: 32, height: 32,
                            margin: const EdgeInsetsDirectional.only(start: 4),
                            decoration: BoxDecoration(
                              color: AppColors.unsecured.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(Symbols.delete,
                                color: AppColors.unsecured, size: 15),
                          ),
                        ),
                      Switch(
                        value: widget.enabled,
                        onChanged: (_) => widget.onToggle(),
                        activeColor: context.tText,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: context.tText2(0.1),
                        inactiveThumbColor: context.tText2(0.38),
                        trackOutlineColor:
                            WidgetStateProperty.all(Colors.transparent),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Inline editor (animated expand) ───────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _expanded
                ? _InlineEditor(
                    nameCtrl: _nameCtrl,
                    condCtrl: _condCtrl,
                    actionCtrl: _actionCtrl,
                    s: state.strings,
                    isHebrew: isHebrew,
                    textDir: textDir,
                    onSave: () {
                      widget.onSave?.call(
                          _nameCtrl.text, _condCtrl.text, _actionCtrl.text);
                      setState(() => _expanded = false);
                    },
                    onCancel: () => setState(() => _expanded = false),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inline editor panel
// ─────────────────────────────────────────────────────────────
class _InlineEditor extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController condCtrl;
  final TextEditingController actionCtrl;
  final S s;
  final bool isHebrew;
  final TextDirection textDir;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _InlineEditor({
    required this.nameCtrl,
    required this.condCtrl,
    required this.actionCtrl,
    required this.s,
    required this.isHebrew,
    required this.textDir,
    required this.onSave,
    required this.onCancel,
  });

  InputDecoration _deco(BuildContext ctx, String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ctx.tText2(0.5), fontSize: 12),
        filled: true,
        fillColor: ctx.tText2(0.05),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ctx.tText2(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ctx.tText2(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameCtrl,
            textDirection: textDir,
            style: TextStyle(color: context.tText, fontSize: 13),
            decoration: _deco(context, s.autoName),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: condCtrl,
            textDirection: textDir,
            style: TextStyle(color: context.tText, fontSize: 13),
            decoration: _deco(context, s.autoCondition),
          ),
          if (isHebrew) ...[
            const SizedBox(height: 8),
            _HebrewCalendarConditions(controller: condCtrl),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: actionCtrl,
            textDirection: textDir,
            style: TextStyle(color: context.tText, fontSize: 13),
            decoration: _deco(context, s.autoAction),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.tText2(0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(s.cancel,
                      style: TextStyle(
                          color: context.tText2(0.6), fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(s.save,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
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
// FAB
// ─────────────────────────────────────────────────────────────
class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _AddFab({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.add, color: context.tText, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: context.tText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add automation bottom sheet
// ─────────────────────────────────────────────────────────────
// ─── Trigger types ──────────────────────────────────────────────────────────
enum _TriggerType { device, sensor, time, arrival }
enum _ActionType  { turnOn, turnOff, lock, unlock, openBlind, closeBlind, allLightsOff }

class _AddAutomationSheet extends StatefulWidget {
  final AppState state;
  const _AddAutomationSheet({required this.state});

  @override
  State<_AddAutomationSheet> createState() => _AddAutomationSheetState();
}

class _AddAutomationSheetState extends State<_AddAutomationSheet> {
  // ── Trigger ──────────────────────────────────────────────────────────────
  _TriggerType _triggerType = _TriggerType.sensor;
  Device?       _triggerDevice;   // for device/sensor triggers
  String        _triggerEvent  = '';   // "opened", "motion", "leak" etc.
  TimeOfDay     _triggerTime   = const TimeOfDay(hour: 22, minute: 0);

  // ── Action ───────────────────────────────────────────────────────────────
  _ActionType   _actionType    = _ActionType.allLightsOff;
  Device?       _actionDevice;

  // ── Name (auto-generated or manual) ──────────────────────────────────────
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  String _buildCondition(S s) {
    switch (_triggerType) {
      case _TriggerType.sensor:
        final d = _triggerDevice;
        if (d == null) return s.autoCondition;
        final evt = _triggerEvent.isNotEmpty ? _triggerEvent : 'triggered';
        return '${d.name} — $evt';
      case _TriggerType.device:
        final d = _triggerDevice;
        if (d == null) return s.autoCondition;
        return '${d.name} — ${_triggerEvent.isNotEmpty ? _triggerEvent : "on"}';
      case _TriggerType.time:
        return '${_triggerTime.hour.toString().padLeft(2,'0')}:${_triggerTime.minute.toString().padLeft(2,'0')}';
      case _TriggerType.arrival:
        return s.condArrive;
    }
  }

  String _buildAction(S s) {
    switch (_actionType) {
      case _ActionType.allLightsOff:  return s.actOffLightsAc;
      case _ActionType.turnOn:
        return _actionDevice != null ? '${s.actAllLightsOn.split(' ').first} ${_actionDevice!.name}' : s.actAllLightsOn;
      case _ActionType.turnOff:
        return _actionDevice != null ? '${s.actOffLightsAc.split(' ').first} ${_actionDevice!.name}' : s.actOffLightsAc;
      case _ActionType.lock:          return s.actOffLock;
      case _ActionType.unlock:        return s.unlockAll;
      case _ActionType.openBlind:     return s.openAll;
      case _ActionType.closeBlind:    return s.closeAll;
    }
  }

  String _buildName(S s) {
    if (_nameCtrl.text.trim().isNotEmpty) return _nameCtrl.text.trim();
    return '${_buildCondition(s)} → ${_buildAction(s)}';
  }

  void _save(S s) {
    final name      = _buildName(s);
    final condition = _buildCondition(s);
    final action    = _buildAction(s);
    context.read<AppState>().addAutomation(Automation(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      name:      name,
      condition: condition,
      action:    action,
    ));
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s     = state.strings;

    // Capability-driven: anything that senses can trigger, anything
    // controllable can be an action target — new device types (gas sensors,
    // Matter devices, garage doors…) appear here automatically.
    final sensors =
        state.devices.where(DeviceCapabilities.canTrigger).toList();

    final controllable =
        state.devices.where(DeviceCapabilities.canAct).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.tText2(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(s.addAutomation,
              style: TextStyle(color: context.tText, fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          // ── WHEN section ─────────────────────────────────────────────────
          _SectionHeader(label: s.autoCondition, color: AppColors.primary),
          const SizedBox(height: 10),

          // Trigger type chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _TypeChip(
                label: s.sensorsCategory,
                icon: Symbols.sensors,
                selected: _triggerType == _TriggerType.sensor,
                onTap: () => setState(() { _triggerType = _TriggerType.sensor; _triggerDevice = null; }),
              ),
              _TypeChip(
                label: s.devicesUnit,
                icon: Symbols.devices,
                selected: _triggerType == _TriggerType.device,
                onTap: () => setState(() { _triggerType = _TriggerType.device; _triggerDevice = null; }),
              ),
              _TypeChip(
                label: s.pickDay,
                icon: Symbols.schedule,
                selected: _triggerType == _TriggerType.time,
                onTap: () => setState(() => _triggerType = _TriggerType.time),
              ),
              _TypeChip(
                label: s.condArrive,
                icon: Symbols.home,
                selected: _triggerType == _TriggerType.arrival,
                onTap: () => setState(() => _triggerType = _TriggerType.arrival),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Trigger detail
          if (_triggerType == _TriggerType.sensor && sensors.isNotEmpty)
            _DeviceDropdown(
              label: s.sensorsCategory,
              devices: sensors,
              selected: _triggerDevice,
              onChanged: (d) => setState(() {
                _triggerDevice = d;
                _triggerEvent = _defaultSensorEvent(d);
              }),
            ),

          if (_triggerType == _TriggerType.device && controllable.isNotEmpty)
            _DeviceDropdown(
              label: s.devicesUnit,
              devices: controllable,
              selected: _triggerDevice,
              onChanged: (d) => setState(() {
                _triggerDevice = d;
                _triggerEvent  = 'turned on';
              }),
            ),

          if (_triggerType == _TriggerType.time) ...[
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _triggerTime,
                );
                if (t != null) setState(() => _triggerTime = t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.tText2(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.tText2(0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.schedule, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_triggerTime.hour.toString().padLeft(2,'0')}:${_triggerTime.minute.toString().padLeft(2,'0')}',
                      style: TextStyle(color: context.tText, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── THEN section ─────────────────────────────────────────────────
          _SectionHeader(label: s.autoAction, color: const Color(0xFF8E63CE)),
          const SizedBox(height: 10),

          // Action type chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _TypeChip(
                label: s.actOffLightsAc,
                icon: Symbols.power_off,
                selected: _actionType == _ActionType.allLightsOff,
                onTap: () => setState(() => _actionType = _ActionType.allLightsOff),
                color: const Color(0xFF555555),
              ),
              _TypeChip(
                label: s.coverOpen.replaceAll('▲  ', ''),
                icon: Symbols.lightbulb,
                selected: _actionType == _ActionType.turnOn,
                onTap: () => setState(() => _actionType = _ActionType.turnOn),
                color: const Color(0xFFFFB300),
              ),
              _TypeChip(
                label: s.actOffLock,
                icon: Symbols.lock,
                selected: _actionType == _ActionType.lock,
                onTap: () => setState(() { _actionType = _ActionType.lock; _actionDevice = null; }),
                color: AppColors.secured,
              ),
              _TypeChip(
                label: s.openAll,
                icon: Symbols.blinds,
                selected: _actionType == _ActionType.openBlind,
                onTap: () => setState(() { _actionType = _ActionType.openBlind; _actionDevice = null; }),
                color: const Color(0xFF8E63CE),
              ),
              _TypeChip(
                label: s.closeAll,
                icon: Symbols.blinds_closed,
                selected: _actionType == _ActionType.closeBlind,
                onTap: () => setState(() { _actionType = _ActionType.closeBlind; _actionDevice = null; }),
                color: context.tText2(0.5),
              ),
            ],
          ),

          if ((_actionType == _ActionType.turnOn || _actionType == _ActionType.turnOff) &&
              controllable.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DeviceDropdown(
              label: s.devicesUnit,
              devices: controllable,
              selected: _actionDevice,
              onChanged: (d) => setState(() => _actionDevice = d),
            ),
          ],

          const SizedBox(height: 20),

          // ── Optional name ─────────────────────────────────────────────────
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: context.tText),
            decoration: InputDecoration(
              hintText: s.autoName,
              hintStyle: TextStyle(color: context.tText2(0.35)),
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
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Save button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _save(s),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(s.save,
                  style: TextStyle(color: context.tText, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultSensorEvent(Device? d) {
    if (d == null) return 'triggered';
    switch (d.type) {
      case DeviceType.doorSensor:    return 'door opened';
      case DeviceType.windowSensor:  return 'window opened';
      case DeviceType.motionSensor:  return 'motion detected';
      case DeviceType.waterLeakSensor: return 'water detected';
      case DeviceType.smokeSensor:   return 'smoke detected';
      default:                       return 'triggered';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable section header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Type chip
// ─────────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : context.tText2(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : context.tText2(0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? c : context.tText2(0.45)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? c : context.tText2(0.6),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Device dropdown picker
// ─────────────────────────────────────────────────────────────
class _DeviceDropdown extends StatelessWidget {
  final String label;
  final List<Device> devices;
  final Device? selected;
  final ValueChanged<Device?> onChanged;

  const _DeviceDropdown({
    required this.label,
    required this.devices,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.tText2(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.12)),
      ),
      child: DropdownButton<Device>(
        value: selected,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: context.tCard,
        hint: Text(label, style: TextStyle(color: context.tText2(0.4), fontSize: 14)),
        style: TextStyle(color: context.tText, fontSize: 14),
        items: devices.map((d) => DropdownMenuItem(
          value: d,
          child: Text(d.name, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Edit automation bottom sheet
// ─────────────────────────────────────────────────────────────
class _EditAutomationSheet extends StatefulWidget {
  final AppState state;
  final Automation automation;
  const _EditAutomationSheet({required this.state, required this.automation});

  @override
  State<_EditAutomationSheet> createState() => _EditAutomationSheetState();
}

class _EditAutomationSheetState extends State<_EditAutomationSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _condCtrl;
  late final TextEditingController _actionCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.automation.name);
    _condCtrl   = TextEditingController(text: widget.automation.condition);
    _actionCtrl = TextEditingController(text: widget.automation.action);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _condCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.tText2(0.5)),
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),

          Builder(builder: (ctx) {
            final state = ctx.watch<AppState>();
            final s = state.strings;
            final textDir = state.isRtl ? TextDirection.rtl : TextDirection.ltr;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.edit,
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _nameCtrl,
                  textDirection: textDir,
                  style: TextStyle(color: context.tText),
                  decoration: _inputDeco(s.autoName),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _condCtrl,
                  textDirection: textDir,
                  style: TextStyle(color: context.tText),
                  decoration: _inputDeco(s.autoCondition),
                ),
                if (state.locale == AppLocale.hebrew) ...[
                  const SizedBox(height: 10),
                  _HebrewCalendarConditions(controller: _condCtrl),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _actionCtrl,
                  textDirection: textDir,
                  style: TextStyle(color: context.tText),
                  decoration: _inputDeco(s.autoAction),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameCtrl.text.isNotEmpty) {
                        widget.state.updateAutomation(
                          widget.automation.id,
                          name: _nameCtrl.text,
                          condition: _condCtrl.text,
                          action: _actionCtrl.text,
                        );
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      s.save,
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
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
// Data model for recommendations
// ─────────────────────────────────────────────────────────────
class _AutomationMeta {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String name;
  final String description;

  const _AutomationMeta({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.name,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────
// Hebrew-calendar condition picker
//
// Descriptive quick-picks that fill the automation's condition field with a
// Hebrew-calendar trigger (Shabbat, holidays, Rosh Chodesh, a specific Hebrew
// date, etc.). No scheduling engine yet — these describe the intended trigger,
// matching how every other condition in the app works today.
// ─────────────────────────────────────────────────────────────
class _HebrewCalendarConditions extends StatelessWidget {
  final TextEditingController controller;
  const _HebrewCalendarConditions({required this.controller});

  static const _presets = <String>[
    'כניסת שבת',
    'צאת שבת',
    'ערב חג',
    'חג / יום טוב',
    'ראש חודש',
    'חול המועד',
  ];

  static const _hebrewMonths = <String>[
    'תשרי', 'חשוון', 'כסלו', 'טבת', 'שבט', 'אדר', 'אדר א׳', 'אדר ב׳',
    'ניסן', 'אייר', 'סיוון', 'תמוז', 'אב', 'אלול',
  ];

  /// Hebrew gematria label for a day 1..30.
  static String _gematriaDay(int d) {
    const ones = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
    const tens = ['', 'י', 'כ', 'ל'];
    if (d == 15) return 'ט״ו';
    if (d == 16) return 'ט״ז';
    final t = d ~/ 10, o = d % 10;
    final letters = '${tens[t]}${ones[o]}';
    if (letters.length == 1) return '$letters׳';
    return '${letters.substring(0, letters.length - 1)}״${letters.substring(letters.length - 1)}';
  }

  Future<void> _pickHebrewDate(BuildContext context, S s) async {
    int day = 15;
    int monthIdx = 5; // אדר
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(s.pickHebrewDate,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 18),
              Row(children: [
                // Day
                Expanded(
                  child: _wheelBox(
                    label: s.pickDay,
                    child: DropdownButton<int>(
                      value: day,
                      isExpanded: true,
                      dropdownColor: context.tCardAlt,
                      underline: const SizedBox(),
                      style: TextStyle(color: context.tText, fontSize: 15),
                      items: [
                        for (var d = 1; d <= 30; d++)
                          DropdownMenuItem(value: d, child: Text(_gematriaDay(d))),
                      ],
                      onChanged: (v) => setSheet(() => day = v ?? day),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Month
                Expanded(
                  flex: 2,
                  child: _wheelBox(
                    label: s.pickMonth,
                    child: DropdownButton<int>(
                      value: monthIdx,
                      isExpanded: true,
                      dropdownColor: context.tCardAlt,
                      underline: const SizedBox(),
                      style: TextStyle(color: context.tText, fontSize: 15),
                      items: [
                        for (var i = 0; i < _hebrewMonths.length; i++)
                          DropdownMenuItem(value: i, child: Text(_hebrewMonths[i])),
                      ],
                      onChanged: (v) => setSheet(() => monthIdx = v ?? monthIdx),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx,
                      s.hebrewDateFmt.replaceAll('{date}', '${_gematriaDay(day)} ב${_hebrewMonths[monthIdx]}')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  child: Text(s.confirm,
                      style: TextStyle(
                          color: context.tText, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) controller.text = result;
  }

  static Widget _wheelBox({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _chip(String label, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: outlined ? 0.0 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45), width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Symbols.calendar_month,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(s.calendarHebrew,
              style: TextStyle(
                  color: context.tText2(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _presets) _chip(p, () => controller.text = p),
            _chip(s.hebrewCalendarChip, () => _pickHebrewDate(context, s), outlined: true),
          ],
        ),
      ],
    );
  }
}
