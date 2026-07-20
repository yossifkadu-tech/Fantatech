import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/control/device_commander.dart';
import '../../theme/app_theme.dart';
import '../../widgets/device_edit_sheet.dart';
import '../../widgets/ft_nav.dart';

class RobotVacuumHubScreen extends StatelessWidget {
  const RobotVacuumHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s     = state.strings;
    final units = state.devices
        .where((d) => d.type == DeviceType.robotVacuum)
        .toList();

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  const FtBackButton(),
                  Expanded(
                    child: Text(s.vacuumCategory,
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
            Expanded(
              child: units.isEmpty
                  ? _VacuumEmptyState(s: s)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      addAutomaticKeepAlives: false,
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _VacuumCard(device: units[i], s: s),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VacuumCard extends StatelessWidget {
  final Device device;
  final dynamic s;
  const _VacuumCard({required this.device, required this.s});

  static const _kAccent = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final on    = device.isOn;
    final docked = device.attributes['docked'] as bool? ?? false;

    void run(VacuumAction action) {
      HapticFeedback.lightImpact();
      state.vacuumCommand(device.id, action);
    }

    return GestureDetector(
      onLongPress: () => showDeviceEditSheet(context, device: device, state: state),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: on ? _kAccent.withValues(alpha: 0.3) : context.tText2(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: on ? _kAccent.withValues(alpha: 0.12) : context.tText2(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Symbols.robot_2,
                    color: on ? _kAccent : context.tText2(0.3), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(
                      docked ? s.vacuumDocked : (on ? s.vacuumCleaning : s.deviceOff),
                      style: TextStyle(color: context.tText2(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (device.battery != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.battery_full, size: 16,
                        color: context.tText2(0.4)),
                    const SizedBox(width: 2),
                    Text('${device.battery}%',
                        style: TextStyle(color: context.tText2(0.5), fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _VacuumBtn(
                icon: Symbols.play_arrow,
                label: s.vacuumStart,
                color: _kAccent,
                onTap: () => run(VacuumAction.start),
              ),
              _VacuumBtn(
                icon: Symbols.pause,
                label: s.vacuumPause,
                color: _kAccent,
                onTap: () => run(VacuumAction.pause),
              ),
              _VacuumBtn(
                icon: Symbols.home_pin,
                label: s.vacuumDock,
                color: _kAccent,
                onTap: () => run(VacuumAction.dock),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _VacuumBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _VacuumBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: context.tText2(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VacuumEmptyState extends StatelessWidget {
  final dynamic s;
  const _VacuumEmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.robot_2, size: 64, color: context.tText2(0.18)),
            const SizedBox(height: 20),
            Text(s.vacuumNoDevices,
                style: TextStyle(
                    color: context.tText, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.vacuumHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.tText2(0.45), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
