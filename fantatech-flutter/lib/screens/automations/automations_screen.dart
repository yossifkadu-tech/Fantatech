import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  int _tabIndex = 0; // 0 = all, 1 = recommendations

  // Recommended automations — resolved in the current language.
  List<_AutomationMeta> _recommendationsFor(S s) => [
    _AutomationMeta(
      icon: Icons.wb_sunny_outlined,
      iconBg: const Color(0xFF2A1F00),
      iconColor: const Color(0xFFFFB300),
      name: s.recPeakName,
      description: s.recPeakDesc,
    ),
    _AutomationMeta(
      icon: Icons.security_outlined,
      iconBg: const Color(0xFF0A1A2A),
      iconColor: AppColors.primary,
      name: s.recTravelName,
      description: s.recTravelDesc,
    ),
    _AutomationMeta(
      icon: Icons.thermostat_outlined,
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
                  : _RecommendationsList(items: _recommendationsFor(s)),
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
                Icons.chevron_right,
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
          const SizedBox(width: 38),
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
    if (name.contains('לילה')) return Icons.nightlight_round;
    if (name.contains('בוקר')) return Icons.wb_sunny_outlined;
    if (name.contains('יציאה')) return Icons.exit_to_app_outlined;
    if (name.contains('כניסה') || name.contains('חזרה')) return Icons.home_outlined;
    if (name.contains('חיסכון') || name.contains('חשמל')) return Icons.bolt_outlined;
    return Icons.auto_awesome_outlined;
  }

  static Color _colorForName(String name) {
    if (name.contains('לילה')) return const Color(0xFF9C7AFF);
    if (name.contains('בוקר')) return const Color(0xFFFFB300);
    if (name.contains('יציאה')) return AppColors.primary;
    if (name.contains('כניסה') || name.contains('חזרה')) return AppColors.secured;
    if (name.contains('חיסכון') || name.contains('חשמל')) return const Color(0xFF00B4D8);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final automations = state.automations;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      itemCount: automations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final auto = automations[i];
        final color = _colorForName(auto.name);
        return _AutomationCard(
          icon: _iconForName(auto.name),
          iconColor: color,
          iconBg: color.withValues(alpha: 0.12),
          name: auto.name,
          description: '${auto.condition} — ${auto.action}',
          enabled: auto.isEnabled,
          onToggle: () => state.toggleAutomation(auto.id),
          onEdit: () => _showEditSheet(ctx, state, auto),
          onDelete: () => _confirmDelete(ctx, state, auto),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, AppState state, Automation auto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditAutomationSheet(state: state, automation: auto),
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
          '"${auto.name}"?',
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
// Recommendations list (static)
// ─────────────────────────────────────────────────────────────
class _RecommendationsList extends StatelessWidget {
  final List<_AutomationMeta> items;
  const _RecommendationsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = items[i];
        return _AutomationCard(
          icon: item.icon,
          iconColor: item.iconColor,
          iconBg: item.iconBg,
          name: item.name,
          description: item.description,
          enabled: false,
          isRecommendation: true,
          onToggle: () {},
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Automation card
// ─────────────────────────────────────────────────────────────
class _AutomationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String name;
  final String description;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isRecommendation;

  const _AutomationCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.name,
    required this.description,
    required this.enabled,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.isRecommendation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.2)
              : context.tText2(0.07),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 23),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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

            // Action buttons or Add
            if (isRecommendation)
              _AddButton(onTap: onToggle)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: context.tText2(0.06),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(Icons.edit_outlined,
                            color: context.tText2(0.38), size: 15),
                      ),
                    ),
                  // Delete button
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: AppColors.unsecured.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(Icons.delete_outline,
                            color: AppColors.unsecured, size: 15),
                      ),
                    ),
                  // Toggle switch
                  Switch(
                    value: enabled,
                    onChanged: (_) => onToggle(),
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
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          s.add,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            Icon(Icons.add, color: context.tText, size: 20),
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
class _AddAutomationSheet extends StatefulWidget {
  final AppState state;
  const _AddAutomationSheet({required this.state});

  @override
  State<_AddAutomationSheet> createState() => _AddAutomationSheetState();
}

class _AddAutomationSheetState extends State<_AddAutomationSheet> {
  final _nameCtrl = TextEditingController();
  final _condCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();

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
        left: 24,
        right: 24,
        top: 24,
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
            final state = ctx.watch<AppState>();
            final s = state.strings;
            final textDir = state.isRtl ? TextDirection.rtl : TextDirection.ltr;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.addAutomation,
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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

                const SizedBox(height: 12),

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
                        widget.state.addAutomation(Automation(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _nameCtrl.text,
                          condition: _condCtrl.text,
                          action: _actionCtrl.text,
                        ));
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.save,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                const SizedBox(height: 10),
                _HebrewCalendarConditions(controller: _condCtrl),
                const SizedBox(height: 12),

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

  Future<void> _pickHebrewDate(BuildContext context) async {
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
              const Center(
                child: Text('בחר תאריך עברי',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 18),
              Row(children: [
                // Day
                Expanded(
                  child: _wheelBox(
                    label: 'יום',
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
                    label: 'חודש',
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
                      'תאריך עברי: ${_gematriaDay(day)} ב${_hebrewMonths[monthIdx]}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  child: Text('אישור',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.calendar_month_outlined,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('לוח עברי',
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
            _chip('תאריך עברי…', () => _pickHebrewDate(context), outlined: true),
          ],
        ),
      ],
    );
  }
}
