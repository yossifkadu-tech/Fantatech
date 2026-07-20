import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/device_edit_sheet.dart';
import '../../widgets/ft_nav.dart';

// ─────────────────────────────────────────────────────────────
// Plug schedule model
// ─────────────────────────────────────────────────────────────

class _PlugSchedule {
  final TimeOfDay? onTime;
  final TimeOfDay? offTime;
  final Set<int> days; // 1=Mon..7=Sun; empty = every day

  const _PlugSchedule({this.onTime, this.offTime, this.days = const {}});

  bool get hasAny => onTime != null || offTime != null;

  Map<String, dynamic> toJson() => {
        if (onTime != null) 'onH': onTime!.hour,
        if (onTime != null) 'onM': onTime!.minute,
        if (offTime != null) 'offH': offTime!.hour,
        if (offTime != null) 'offM': offTime!.minute,
        'days': days.toList(),
      };

  factory _PlugSchedule.fromJson(Map<String, dynamic> json) => _PlugSchedule(
        onTime: json.containsKey('onH')
            ? TimeOfDay(hour: json['onH'] as int, minute: json['onM'] as int)
            : null,
        offTime: json.containsKey('offH')
            ? TimeOfDay(hour: json['offH'] as int, minute: json['offM'] as int)
            : null,
        days: Set<int>.from(
            (json['days'] as List?)?.cast<int>() ?? const <int>[]),
      );
}

// ─────────────────────────────────────────────────────────────
// Schedule service — singleton; persists to SharedPreferences
// and executes schedules every minute while app is in foreground.
// ─────────────────────────────────────────────────────────────

class _ScheduleService extends ChangeNotifier {
  static final _ScheduleService instance = _ScheduleService._();
  _ScheduleService._();

  static const _prefKey = 'plug_schedules_v1';

  final Map<String, _PlugSchedule> _schedules = {};
  Timer? _timer;
  AppState? _appState;

  _PlugSchedule? scheduleFor(String deviceId) => _schedules[deviceId];

  /// Attach to AppState and start periodic execution.
  void attach(AppState appState) {
    _appState = appState;
    _timer ??= Timer.periodic(const Duration(minutes: 1), _tick);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _schedules.clear();
      for (final e in map.entries) {
        _schedules[e.key] =
            _PlugSchedule.fromJson(e.value as Map<String, dynamic>);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveSchedule(String deviceId, _PlugSchedule schedule) async {
    if (schedule.hasAny) {
      _schedules[deviceId] = schedule;
    } else {
      _schedules.remove(deviceId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey,
        jsonEncode({
          for (final e in _schedules.entries) e.key: e.value.toJson(),
        }));
  }

  Future<void> clearSchedule(String deviceId) async {
    _schedules.remove(deviceId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey,
        jsonEncode({
          for (final e in _schedules.entries) e.key: e.value.toJson(),
        }));
  }

  void _tick(Timer _) {
    final state = _appState;
    if (state == null) return;
    final now = DateTime.now();
    final plugs = state.devices
        .where((d) => d.type == DeviceType.smartPlug)
        .toList(growable: false);

    for (final plug in plugs) {
      final sched = _schedules[plug.id];
      if (sched == null || !sched.hasAny) continue;
      if (sched.days.isNotEmpty && !sched.days.contains(now.weekday)) continue;

      if (sched.onTime != null &&
          now.hour == sched.onTime!.hour &&
          now.minute == sched.onTime!.minute &&
          !plug.isOn) {
        state.toggleDevice(plug.id);
      }
      if (sched.offTime != null &&
          now.hour == sched.offTime!.hour &&
          now.minute == sched.offTime!.minute &&
          plug.isOn) {
        state.toggleDevice(plug.id);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class PlugsHubScreen extends StatelessWidget {
  const PlugsHubScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PlugsHubView();
}

class _PlugsHubView extends StatefulWidget {
  const _PlugsHubView();
  @override
  State<_PlugsHubView> createState() => _PlugsHubViewState();
}

class _PlugsHubViewState extends State<_PlugsHubView> {
  @override
  void initState() {
    super.initState();
    _ScheduleService.instance.addListener(_onScheduleChanged);
    // Attach service after first frame (context available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ScheduleService.instance.attach(context.read<AppState>());
    });
  }

  void _onScheduleChanged() => setState(() {});

  @override
  void dispose() {
    _ScheduleService.instance.removeListener(_onScheduleChanged);
    super.dispose();
  }

  List<Device> _plugs(AppState state) =>
      state.devices.where((d) => d.type == DeviceType.smartPlug).toList();

  void _allOn(List<Device> plugs, AppState state) {
    HapticFeedback.mediumImpact();
    for (final d in plugs) {
      if (!d.isOn) state.toggleDevice(d.id);
    }
  }

  void _allOff(List<Device> plugs, AppState state) {
    HapticFeedback.mediumImpact();
    for (final d in plugs) {
      if (d.isOn) state.toggleDevice(d.id);
    }
  }

  double _totalWatts(List<Device> plugs) => plugs
      .where((d) => d.isOn)
      .fold(0.0, (s, d) => s + (d.attributes['power'] as num? ?? 0).toDouble());

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final s       = state.strings;
    final plugs   = _plugs(state);
    final onCount = plugs.where((d) => d.isOn).length;
    final totalW  = _totalWatts(plugs);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  const FtBackButton(),
                  Expanded(
                    child: Text(s.plugsHubTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            if (plugs.isNotEmpty) ...[
              // ── Status + power banner ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: onCount > 0
                          ? [AppColors.plugColor.withValues(alpha: 0.15), AppColors.plugColor.withValues(alpha: 0.04)]
                          : [context.tText2(0.05), context.tText2(0.02)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: onCount > 0
                            ? AppColors.plugColor.withValues(alpha: 0.3)
                            : context.tText2(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.power,
                          color: onCount > 0 ? AppColors.plugColor : context.tText2(0.3),
                          size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$onCount / ${plugs.length}  ${s.plugsCategory.toLowerCase()}',
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (totalW > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.plugColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            totalW >= 1000
                                ? '${(totalW / 1000).toStringAsFixed(1)} kW'
                                : '${totalW.round()} W',
                            style: TextStyle(
                                color: AppColors.plugColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Global buttons ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: s.plugsAllOn,
                        icon: Symbols.power,
                        color: AppColors.plugColor,
                        onTap: () => _allOn(plugs, state),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        label: s.plugsAllOff,
                        icon: Symbols.power_off,
                        color: context.tText2(0.55),
                        onTap: () => _allOff(plugs, state),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: plugs.isEmpty
                  ? _EmptyState(s: s)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      addAutomaticKeepAlives: false,
                      itemCount: plugs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final d = plugs[i];
                        final sched = _ScheduleService.instance.scheduleFor(d.id);
                        return _PlugCard(
                          device: d,
                          schedule: sched,
                          onToggle: () {
                            HapticFeedback.lightImpact();
                            state.toggleDevice(d.id);
                          },
                          onRename: () =>
                              showDeviceEditSheet(context, device: d, state: state),
                          onSchedule: () => _showScheduleSheet(context, d, sched),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }


  // ── Schedule sheet ──────────────────────────────────────────
  void _showScheduleSheet(
      BuildContext context, Device device, _PlugSchedule? current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(device: device, initial: current),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Schedule bottom sheet
// ─────────────────────────────────────────────────────────────

class _ScheduleSheet extends StatefulWidget {
  final Device device;
  final _PlugSchedule? initial;
  const _ScheduleSheet({required this.device, this.initial});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  TimeOfDay? _onTime;
  TimeOfDay? _offTime;
  Set<int>   _days = {};

  @override
  void initState() {
    super.initState();
    _onTime  = widget.initial?.onTime;
    _offTime = widget.initial?.offTime;
    _days    = Set<int>.from(widget.initial?.days ?? const <int>{});
  }

  Future<void> _pickTime(bool isOn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOn
          ? (_onTime  ?? TimeOfDay.now())
          : (_offTime ?? TimeOfDay.now()),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isOn) _onTime  = picked;
      else      _offTime = picked;
    });
  }

  void _toggleDay(int day) =>
      setState(() => _days.contains(day) ? _days.remove(day) : _days.add(day));

  void _save() {
    final sched = _PlugSchedule(
        onTime: _onTime, offTime: _offTime, days: Set<int>.from(_days));
    _ScheduleService.instance.saveSchedule(widget.device.id, sched);
    Navigator.pop(context);
  }

  void _clear() {
    _ScheduleService.instance.clearSchedule(widget.device.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s         = context.read<AppState>().strings;
    final hasSched  = widget.initial?.hasAny == true;
    final dayLabels = ['ב', 'ג', 'ד', 'ה', 'ו', 'ש', 'א']; // Mon-Sun Hebrew
    final activeColor = AppColors.plugColor;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          const FtModalHandle(),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Icon(Symbols.schedule, color: activeColor, size: 20),
              const SizedBox(width: 8),
              Text(s.boilerSchedule,
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.device.name,
                    style: TextStyle(color: context.tText2(0.5), fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              if (hasSched)
                TextButton(
                  onPressed: _clear,
                  child: Text(s.cancelButton,
                      style: TextStyle(color: context.tText2(0.4), fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ON time row
          _TimeRow(
            label: s.valOn,
            icon: Symbols.power,
            color: activeColor,
            time: _onTime,
            onTap: () => _pickTime(true),
            onClear: _onTime == null ? null : () => setState(() => _onTime = null),
          ),
          const SizedBox(height: 12),

          // OFF time row
          _TimeRow(
            label: s.valOff,
            icon: Symbols.power_off,
            color: context.tText2(0.5),
            time: _offTime,
            onTap: () => _pickTime(false),
            onClear: _offTime == null ? null : () => setState(() => _offTime = null),
          ),
          const SizedBox(height: 20),

          // Days of week
          Text('ימים',
              style: TextStyle(
                  color: context.tText2(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day      = i + 1; // 1=Mon..7=Sun
              final selected = _days.contains(day);
              return GestureDetector(
                onTap: () => _toggleDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? activeColor.withValues(alpha: 0.18)
                        : context.tText2(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? activeColor.withValues(alpha: 0.5)
                          : context.tText2(0.08),
                    ),
                  ),
                  child: Center(
                    child: Text(dayLabels[i],
                        style: TextStyle(
                            color: selected ? activeColor : context.tText2(0.4),
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('ריק = כל יום',
              style: TextStyle(color: context.tText2(0.3), fontSize: 11)),
          const SizedBox(height: 24),

          // Save button
          GestureDetector(
            onTap: (_onTime != null || _offTime != null) ? _save : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: (_onTime != null || _offTime != null)
                    ? activeColor
                    : context.tText2(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(s.okButton,
                    style: TextStyle(
                        color: (_onTime != null || _offTime != null)
                            ? Colors.white
                            : context.tText2(0.3),
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final Color      color;
  final TimeOfDay? time;
  final VoidCallback   onTap;
  final VoidCallback?  onClear;

  const _TimeRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.time,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime = time != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasTime ? color.withValues(alpha: 0.08) : context.tText2(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: hasTime ? color.withValues(alpha: 0.3) : context.tText2(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasTime ? color : context.tText2(0.3), size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: hasTime ? color : context.tText2(0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (hasTime) ...[
              Text(
                '${time!.hour.toString().padLeft(2, '0')}:'
                '${time!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Symbols.close,
                    color: context.tText2(0.3), size: 16),
              ),
            ] else
              Icon(Symbols.add_circle,
                  color: context.tText2(0.3), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Plug card
// ─────────────────────────────────────────────────────────────
class _PlugCard extends StatelessWidget {
  final Device         device;
  final _PlugSchedule? schedule;
  final VoidCallback   onToggle;
  final VoidCallback   onRename;
  final VoidCallback   onSchedule;

  const _PlugCard({
    required this.device,
    required this.onToggle,
    required this.onRename,
    required this.onSchedule,
    this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final on          = device.isOn;
    final powerW      = device.attributes['power'] as num?;
    final energyKwh   = device.attributes['energy'] as num?;
    final hasSchedule = schedule?.hasAny == true;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onRename();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: on
                  ? AppColors.plugColor.withValues(alpha: 0.35)
                  : context.tText2(0.07)),
        ),
        child: Row(
          children: [
            // Icon — tap to toggle on/off
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: on
                      ? AppColors.plugColor.withValues(alpha: 0.13)
                      : context.tText2(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  on ? Symbols.power : Symbols.power_off,
                  color: on ? AppColors.plugColor : context.tText2(0.3),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name,
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (device.room.isNotEmpty)
                    Text(device.room,
                        style: TextStyle(
                            color: context.tText2(0.4), fontSize: 12)),
                  if (hasSchedule) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Symbols.schedule,
                            color: AppColors.plugColor, size: 11),
                        const SizedBox(width: 3),
                        if (schedule!.onTime != null)
                          Text(
                            'הדלקה '
                            '${schedule!.onTime!.hour.toString().padLeft(2, '0')}:'
                            '${schedule!.onTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                color: AppColors.plugColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        if (schedule!.onTime != null && schedule!.offTime != null)
                          Text('  ',
                              style: TextStyle(color: context.tText2(0.3))),
                        if (schedule!.offTime != null)
                          Text(
                            'כיבוי '
                            '${schedule!.offTime!.hour.toString().padLeft(2, '0')}:'
                            '${schedule!.offTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                color: context.tText2(0.5),
                                fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                  if (on && (powerW != null || energyKwh != null)) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (powerW != null && powerW > 0) ...[
                          Icon(Symbols.bolt,
                              color: AppColors.plugColor, size: 12),
                          Text('${powerW.round()} W',
                              style: TextStyle(
                                  color: AppColors.plugColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                        ],
                        if (energyKwh != null && energyKwh > 0)
                          Text('${energyKwh.toStringAsFixed(2)} kWh',
                              style: TextStyle(
                                  color: context.tText2(0.4), fontSize: 11)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Schedule button
            GestureDetector(
              onTap: onSchedule,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  hasSchedule ? Symbols.schedule : Symbols.schedule,
                  color: hasSchedule ? AppColors.plugColor : context.tText2(0.22),
                  size: 20,
                ),
              ),
            ),

            // Toggle
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46, height: 26,
                decoration: BoxDecoration(
                  color: on ? AppColors.plugColor : context.tText2(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20, height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared
// ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _ActionBtn(
      {required this.label, required this.icon, required this.color,
       required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : context.tText2(0.22);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveColor, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: effectiveColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.power_off,
                size: 64, color: context.tText2(0.18)),
            const SizedBox(height: 20),
            Text(s.noPlugsFound,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.plugsHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.tText2(0.45), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
