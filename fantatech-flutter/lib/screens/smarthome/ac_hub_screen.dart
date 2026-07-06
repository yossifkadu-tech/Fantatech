import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_nav.dart';

class ACHubScreen extends StatelessWidget {
  const ACHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ACHubView();
  }
}

class _ACHubView extends StatefulWidget {
  const _ACHubView();

  @override
  State<_ACHubView> createState() => _ACHubViewState();
}

class _ACHubViewState extends State<_ACHubView> {
  // Local temp cache
  final Map<String, int> _temp = {};

  List<Device> _units(AppState state) =>
      state.devices.where((d) => d.type == DeviceType.airConditioner).toList();

  void _setTemp(Device d, int t, AppState state) {
    setState(() => _temp[d.id] = t);
    state.setDeviceAttribute(d.id, 'temperature', t);
  }

  void _setMode(Device d, String mode, AppState state) {
    state.setDeviceAttribute(d.id, 'mode', mode);
  }

  void _setFan(Device d, String fan, AppState state) {
    state.setDeviceAttribute(d.id, 'fan', fan);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s     = state.strings;
    final units = _units(state);
    final onCount = units.where((d) => d.isOn).length;

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
                    child: Text(s.acHubTitle,
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

            if (units.isNotEmpty) ...[
              // ── Status banner ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: onCount > 0
                          ? [AppColors.acColor.withValues(alpha: 0.15), AppColors.acColor.withValues(alpha: 0.04)]
                          : [context.tText2(0.05), context.tText2(0.02)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: onCount > 0
                            ? AppColors.acColor.withValues(alpha: 0.3)
                            : context.tText2(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.hvac,
                          color: onCount > 0 ? AppColors.acColor : context.tText2(0.3),
                          size: 22),
                      const SizedBox(width: 12),
                      Text(
                        '$onCount / ${units.length}  ${s.acCategory.toLowerCase()}',
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: units.isEmpty
                  ? _ACEmptyState(s: s)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      addAutomaticKeepAlives: false,
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final d = units[i];
                        final t = _temp[d.id] ??
                            (d.attributes['temperature'] as int? ?? 22);
                        return _ACCard(
                          device: d,
                          temp: t,
                          s: s,
                          onToggle: () {
                            HapticFeedback.lightImpact();
                            state.toggleDevice(d.id);
                          },
                          onTempDown: () => _setTemp(d, (t - 1).clamp(16, 30), state),
                          onTempUp:   () => _setTemp(d, (t + 1).clamp(16, 30), state),
                          onMode: (m) => _setMode(d, m, state),
                          onFan:  (f) => _setFan(d, f, state),
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
// AC card
// ─────────────────────────────────────────────────────────────
class _ACCard extends StatelessWidget {
  final Device device;
  final int temp;
  final dynamic s;
  final VoidCallback onToggle;
  final VoidCallback onTempDown;
  final VoidCallback onTempUp;
  final ValueChanged<String> onMode;
  final ValueChanged<String> onFan;

  const _ACCard({
    required this.device,
    required this.temp,
    required this.s,
    required this.onToggle,
    required this.onTempDown,
    required this.onTempUp,
    required this.onMode,
    required this.onFan,
  });

  static const _kBlue = Color(0xFF2196F3);

  String get _currentMode => device.attributes['mode'] as String? ?? 'cool';
  String get _currentFan  => device.attributes['fan']  as String? ?? 'auto';

  @override
  Widget build(BuildContext context) {
    final on = device.isOn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: on ? _kBlue.withValues(alpha: 0.3) : context.tText2(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: on
                      ? _kBlue.withValues(alpha: 0.12)
                      : context.tText2(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Symbols.hvac,
                    color: on ? _kBlue : context.tText2(0.3), size: 22),
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
                    if (device.room.isNotEmpty)
                      Text(device.room,
                          style: TextStyle(
                              color: context.tText2(0.4), fontSize: 12)),
                  ],
                ),
              ),
              // Toggle
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 46, height: 26,
                  decoration: BoxDecoration(
                    color: on ? _kBlue : context.tText2(0.12),
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

          if (on) ...[
            const SizedBox(height: 16),

            // ── Temperature control ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TempBtn(icon: Symbols.remove, onTap: onTempDown, color: _kBlue),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text('$temp°C',
                        style: TextStyle(
                            color: _kBlue,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    Text(s.acMode,
                        style: TextStyle(
                            color: context.tText2(0.4), fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 20),
                _TempBtn(icon: Symbols.add, onTap: onTempUp, color: _kBlue),
              ],
            ),

            const SizedBox(height: 16),

            // ── Mode chips ───────────────────────────────────
            Text(s.acMode,
                style: TextStyle(
                    color: context.tText2(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _ModeChip(label: s.modeCool, icon: Symbols.ac_unit,           value: 'cool',  current: _currentMode, color: _kBlue,                onTap: onMode),
                _ModeChip(label: s.modeHeat, icon: Symbols.local_fire_department, value: 'heat', current: _currentMode, color: AppColors.statusWarning,  onTap: onMode),
                _ModeChip(label: s.modeFan,  icon: Symbols.air,               value: 'fan',   current: _currentMode, color: Colors.teal,              onTap: onMode),
                _ModeChip(label: s.modeDry,  icon: Symbols.water_drop, value: 'dry', current: _currentMode, color: Colors.purple,            onTap: onMode),
                _ModeChip(label: s.modeAuto, icon: Symbols.autorenew,         value: 'auto',  current: _currentMode, color: AppColors.secured,        onTap: onMode),
              ],
            ),

            const SizedBox(height: 14),

            // ── Fan speed ────────────────────────────────────
            Text(s.acFanSpeed,
                style: TextStyle(
                    color: context.tText2(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _FanChip(label: s.fanLow,  value: 'low',  current: _currentFan, onTap: onFan),
                const SizedBox(width: 8),
                _FanChip(label: s.fanMed,  value: 'med',  current: _currentFan, onTap: onFan),
                const SizedBox(width: 8),
                _FanChip(label: s.fanHigh, value: 'high', current: _currentFan, onTap: onFan),
                const SizedBox(width: 8),
                _FanChip(label: 'Auto',    value: 'auto', current: _currentFan, onTap: onFan),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TempBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _TempBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String current;
  final Color color;
  final ValueChanged<String> onTap;
  const _ModeChip({
    required this.label, required this.icon, required this.value,
    required this.current, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : context.tText2(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color.withValues(alpha: 0.5) : context.tText2(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : context.tText2(0.4)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: selected ? color : context.tText2(0.5),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _FanChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _FanChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    const color = Color(0xFF2196F3);
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : context.tText2(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : context.tText2(0.08)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : context.tText2(0.45),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ),
    );
  }
}

class _ACEmptyState extends StatelessWidget {
  final dynamic s;
  const _ACEmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.hvac, size: 64, color: context.tText2(0.18)),
            const SizedBox(height: 20),
            Text(s.acNoUnits,
                style: TextStyle(
                    color: context.tText, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.lightsHint.replaceAll('lights', 'AC units'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.tText2(0.45), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
