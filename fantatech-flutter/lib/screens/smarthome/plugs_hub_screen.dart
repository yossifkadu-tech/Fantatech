import 'package:material_symbols_icons/symbols.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/device_edit_sheet.dart';
import '../../widgets/ft_nav.dart';
import '../../widgets/schedule_sheet.dart';
import '../../widgets/state_views.dart';

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
    ScheduleService.instance.addListener(_onScheduleChanged);
    // Attach service after first frame (context available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScheduleService.instance.attach(context.read<AppState>());
    });
  }

  void _onScheduleChanged() => setState(() {});

  @override
  void dispose() {
    ScheduleService.instance.removeListener(_onScheduleChanged);
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
                  ? EmptyState(icon: Symbols.power_off, title: s.noPlugsFound, subtitle: s.plugsHint)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      addAutomaticKeepAlives: false,
                      itemCount: plugs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final d = plugs[i];
                        final sched = ScheduleService.instance.scheduleFor(d.id);
                        return _PlugCard(
                          device: d,
                          schedule: sched,
                          onToggle: () {
                            HapticFeedback.lightImpact();
                            state.toggleDevice(d.id);
                          },
                          onRename: () =>
                              showDeviceEditSheet(context, device: d, state: state),
                          onSchedule: () => showScheduleSheet(
                              context, device: d, color: AppColors.plugColor),
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


// ─────────────────────────────────────────────────────────────
// Plug card
// ─────────────────────────────────────────────────────────────
class _PlugCard extends StatelessWidget {
  final Device         device;
  final DeviceSchedule? schedule;
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
