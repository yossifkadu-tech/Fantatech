import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/device.dart';
import '../services/schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ft_nav.dart';

/// Opens the on/off schedule sheet for [device], accented with [color].
Future<void> showScheduleSheet(
  BuildContext context, {
  required Device device,
  required Color color,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ScheduleSheet(
      device: device,
      color: color,
      initial: ScheduleService.instance.scheduleFor(device.id),
    ),
  );
}

class ScheduleSheet extends StatefulWidget {
  final Device device;
  final Color color;
  final DeviceSchedule? initial;
  const ScheduleSheet({super.key, required this.device, required this.color, this.initial});

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
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
    final sched = DeviceSchedule(
        onTime: _onTime, offTime: _offTime, days: Set<int>.from(_days));
    ScheduleService.instance.saveSchedule(widget.device.id, sched);
    Navigator.pop(context);
  }

  void _clear() {
    ScheduleService.instance.clearSchedule(widget.device.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s         = context.read<AppState>().strings;
    final hasSched  = widget.initial?.hasAny == true;
    final dayLabels = ['ב', 'ג', 'ד', 'ה', 'ו', 'ש', 'א']; // Mon-Sun Hebrew
    final activeColor = widget.color;

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
          _ScheduleTimeRow(
            label: s.valOn,
            icon: Symbols.power,
            color: activeColor,
            time: _onTime,
            onTap: () => _pickTime(true),
            onClear: _onTime == null ? null : () => setState(() => _onTime = null),
          ),
          const SizedBox(height: 12),

          // OFF time row
          _ScheduleTimeRow(
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

class _ScheduleTimeRow extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final Color      color;
  final TimeOfDay? time;
  final VoidCallback   onTap;
  final VoidCallback?  onClear;

  const _ScheduleTimeRow({
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
