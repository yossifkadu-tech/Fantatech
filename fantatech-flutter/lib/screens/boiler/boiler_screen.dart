import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Data model for a boiler unit
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// Gateway models
// ─────────────────────────────────────────────────────────────
class _GatewayDevice {
  final String id;
  final String name;
  final String protocol; // 'wifi' | 'zigbee'
  final String ip;
  final String model;
  bool driverInstalled;
  bool driverDownloading;

  _GatewayDevice({
    required this.id,
    required this.name,
    required this.protocol,
    required this.ip,
    required this.model,
    this.driverInstalled = false,
    this.driverDownloading = false,
  });
}

class _BoilerUnit {
  final String deviceId;
  final String name;
  final String room;
  bool isOn;
  double currentTemp;
  double targetTemp;
  String protocol; // 'wifi' | 'zigbee'
  bool isConnected;
  int timerMinutes; // 0 = off
  String mode; // 'eco' | 'full'
  int powerW;

  _BoilerUnit({
    required this.deviceId,
    required this.name,
    required this.room,
    required this.isOn,
    required this.currentTemp,
    required this.targetTemp,
    required this.protocol,
    required this.isConnected,
    required this.timerMinutes,
    required this.mode,
    required this.powerW,
  });

  factory _BoilerUnit.fromDevice(Device d) => _BoilerUnit(
    deviceId: d.id,
    name: d.name,
    room: d.room,
    isOn: d.isOn,
    currentTemp: (d.attributes['temperature'] as int? ?? 55).toDouble(),
    targetTemp: (d.attributes['targetTemp'] as int? ?? 60).toDouble(),
    protocol: d.attributes['protocol'] as String? ?? 'wifi',
    isConnected: d.status == DeviceStatus.online,
    timerMinutes: d.attributes['timer'] as int? ?? 0,
    mode: d.attributes['mode'] as String? ?? 'eco',
    powerW: d.attributes['power'] as int? ?? 2000,
  );
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class BoilerScreen extends StatefulWidget {
  const BoilerScreen({super.key});

  @override
  State<BoilerScreen> createState() => _BoilerScreenState();
}

class _BoilerScreenState extends State<BoilerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heatCtrl;
  late Animation<double> _heatAnim;

  late List<_BoilerUnit> _units;

  void _showGatewaySheet(int unitIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GatewayDiscoverySheet(
        unit: _units[unitIndex],
        onConnected: () {
          setState(() => _units[unitIndex].isConnected = true);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<AppState>().strings.boilerReconnect),
              backgroundColor: AppColors.secured,
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _heatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _heatAnim =
        CurvedAnimation(parent: _heatCtrl, curve: Curves.easeInOut);
    _loadUnits();
  }

  void _loadUnits() {
    final state = context.read<AppState>();
    _units = state.devices
        .where((d) => d.type == DeviceType.waterHeater)
        .map((d) => _BoilerUnit.fromDevice(d))
        .toList();
    // If no real devices, show demo units
    if (_units.isEmpty) {
      _units = [
        _BoilerUnit(
          deviceId: 'demo1',
          name: 'דוד מים - ראשי',
          room: 'מטבח',
          isOn: false,
          currentTemp: 40,
          targetTemp: 60,
          protocol: 'wifi',
          isConnected: false, // simulates not-responding device
          timerMinutes: 0,
          mode: 'eco',
          powerW: 2000,
        ),
        _BoilerUnit(
          deviceId: 'demo2',
          name: 'דוד מים - אמבטיה',
          room: 'חדר אמבטיה',
          isOn: true,
          currentTemp: 55,
          targetTemp: 65,
          protocol: 'zigbee',
          isConnected: true,
          timerMinutes: 30,
          mode: 'full',
          powerW: 1800,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _heatCtrl.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    setState(() => _units[i].isOn = !_units[i].isOn);
    final state = context.read<AppState>();
    try {
      state.toggleDevice(_units[i].deviceId);
    } catch (_) {}
  }

  void _setMode(int i, String mode) =>
      setState(() => _units[i].mode = mode);

  void _setProtocol(int i, String proto) =>
      setState(() => _units[i].protocol = proto);

  void _setTimer(int i, int minutes) =>
      setState(() => _units[i].timerMinutes = minutes);

  void _setTargetTemp(int i, double temp) =>
      setState(() => _units[i].targetTemp = temp);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.boilerTitle),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _units.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  if (i == _units.length + 1) {
                    return const _SmartSwitchesSection();
                  }
                  if (i == _units.length) {
                    return _AddBoilerCard(label: s.boilerAddDevice);
                  }
                  return _BoilerCard(
                    unit: _units[i],
                    index: i,
                    heatAnim: _heatAnim,
                    onToggle: () => _toggle(i),
                    onModeChange: (m) => _setMode(i, m),
                    onProtocolChange: (p) => _setProtocol(i, p),
                    onTimerChange: (t) => _setTimer(i, t),
                    onTempChange: (t) => _setTargetTemp(i, t),
                    onFindGateway: () => _showGatewaySheet(i),
                    strings: s,
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
// Boiler card
// ─────────────────────────────────────────────────────────────
class _BoilerCard extends StatelessWidget {
  final _BoilerUnit unit;
  final int index;
  final Animation<double> heatAnim;
  final VoidCallback onToggle;
  final ValueChanged<String> onModeChange;
  final ValueChanged<String> onProtocolChange;
  final ValueChanged<int> onTimerChange;
  final ValueChanged<double> onTempChange;
  final VoidCallback onFindGateway;
  final dynamic strings;

  const _BoilerCard({
    required this.unit,
    required this.index,
    required this.heatAnim,
    required this.onToggle,
    required this.onModeChange,
    required this.onProtocolChange,
    required this.onTimerChange,
    required this.onTempChange,
    required this.onFindGateway,
    required this.strings,
  });

  Color get _mainColor =>
      unit.isOn ? AppColors.acColor : Colors.white24;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final color = _mainColor;
    final heating = unit.isOn && unit.currentTemp < unit.targetTemp;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Not-responding banner ─────────────────────────────
          if (!unit.isConnected) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Color(0xFFFF5252), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.boilerNotResponding,
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onFindGateway,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                const Color(0xFFFF5252).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        s.boilerFindGateway,
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Header row ───────────────────────────────────────
          Row(
            children: [
              // Animated boiler icon
              AnimatedBuilder(
                animation: heatAnim,
                builder: (_, child) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: unit.isOn
                        ? AppColors.acColor
                            .withValues(alpha: 0.1 + 0.08 * heatAnim.value)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: unit.isOn
                          ? AppColors.acColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: _BoilerIcon(isOn: unit.isOn, anim: heatAnim),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit.room,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 30,
                  decoration: BoxDecoration(
                    color: unit.isOn
                        ? AppColors.acColor
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: unit.isOn
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Temperature gauge ─────────────────────────────────
          _TempGauge(
            current: unit.currentTemp,
            target: unit.targetTemp,
            isOn: unit.isOn,
            heating: heating,
            heatAnim: heatAnim,
            onChanged: onTempChange,
            tempLabel: s.boilerTempLabel,
          ),

          const SizedBox(height: 16),

          // ── Mode selector ─────────────────────────────────────
          Row(
            children: [
              Text(
                '${s.boilerMode}:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              _ModeChip(
                label: s.boilerModeEco,
                icon: Icons.eco,
                selected: unit.mode == 'eco',
                color: AppColors.secured,
                onTap: () => onModeChange('eco'),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: s.boilerModeFull,
                icon: Icons.local_fire_department,
                selected: unit.mode == 'full',
                color: const Color(0xFFFF6B35),
                onTap: () => onModeChange('full'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Timer ────────────────────────────────────────────
          _TimerRow(
            minutes: unit.timerMinutes,
            timerLabel: s.boilerTimer,
            onChanged: onTimerChange,
          ),

          const SizedBox(height: 12),

          // ── Protocol + power ─────────────────────────────────
          Row(
            children: [
              _ProtocolToggle(
                current: unit.protocol,
                wifiLabel: s.boilerWifi,
                zigbeeLabel: s.boilerZigbee,
                onChanged: onProtocolChange,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${unit.powerW}W',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Heating indicator
          if (heating) ...[
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: heatAnim,
              builder: (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.acColor
                      .withValues(alpha: 0.08 + 0.05 * heatAnim.value),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.acColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department,
                        color: AppColors.acColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${unit.currentTemp.toInt()}° → ${unit.targetTemp.toInt()}°',
                      style: const TextStyle(
                        color: AppColors.acColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Temperature gauge
// ─────────────────────────────────────────────────────────────
class _TempGauge extends StatelessWidget {
  final double current;
  final double target;
  final bool isOn;
  final bool heating;
  final Animation<double> heatAnim;
  final ValueChanged<double> onChanged;
  final String tempLabel;

  const _TempGauge({
    required this.current,
    required this.target,
    required this.isOn,
    required this.heating,
    required this.heatAnim,
    required this.onChanged,
    required this.tempLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Current temp
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${current.toInt()}°C',
                  style: TextStyle(
                    color: isOn ? AppColors.acColor : Colors.white54,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  tempLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Target temp
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '→ ${target.toInt()}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Target',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar (current vs target)
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (current / 80).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(
                isOn ? AppColors.acColor : Colors.white24),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 10),
        // Target temp slider
        Row(
          children: [
            const Text('30°',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            Expanded(
              child: Slider(
                value: target,
                min: 30,
                max: 80,
                divisions: 10,
                activeColor: isOn ? AppColors.acColor : Colors.white38,
                inactiveColor: Colors.white.withValues(alpha: 0.1),
                onChanged: isOn ? onChanged : null,
              ),
            ),
            const Text('80°',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mode chip
// ─────────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? color : Colors.white38, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Timer row
// ─────────────────────────────────────────────────────────────
class _TimerRow extends StatelessWidget {
  final int minutes;
  final String timerLabel;
  final ValueChanged<int> onChanged;

  const _TimerRow({
    required this.minutes,
    required this.timerLabel,
    required this.onChanged,
  });

  static const _presets = [0, 15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer_outlined,
            color: Colors.white.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 6),
        Text(
          '$timerLabel:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presets.map((t) {
                final selected = t == minutes;
                return GestureDetector(
                  onTap: () => onChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      t == 0 ? 'Off' : '${t}m',
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : Colors.white38,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Protocol toggle
// ─────────────────────────────────────────────────────────────
class _ProtocolToggle extends StatelessWidget {
  final String current;
  final String wifiLabel;
  final String zigbeeLabel;
  final ValueChanged<String> onChanged;

  const _ProtocolToggle({
    required this.current,
    required this.wifiLabel,
    required this.zigbeeLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProtoBtn(
            label: wifiLabel,
            icon: Icons.wifi,
            selected: current == 'wifi',
            onTap: () => onChanged('wifi'),
          ),
          _ProtoBtn(
            label: zigbeeLabel,
            icon: Icons.hub_outlined,
            selected: current == 'zigbee',
            onTap: () => onChanged('zigbee'),
          ),
        ],
      ),
    );
  }
}

class _ProtoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProtoBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7BB8FF).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(
                  color: const Color(0xFF7BB8FF).withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF7BB8FF)
                    : Colors.white38,
                size: 11),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF7BB8FF)
                    : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Boiler icon painter
// ─────────────────────────────────────────────────────────────
class _BoilerIcon extends StatelessWidget {
  final bool isOn;
  final Animation<double> anim;

  const _BoilerIcon({required this.isOn, required this.anim});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoilerPainter(isOn: isOn, anim: anim.value),
    );
  }
}

class _BoilerPainter extends CustomPainter {
  final bool isOn;
  final double anim;

  const _BoilerPainter({required this.isOn, required this.anim});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final color = isOn ? AppColors.acColor : Colors.white38;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Tank body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: size.width * 0.55,
            height: size.height * 0.65),
        Radius.circular(size.width * 0.1),
      ),
      paint,
    );

    // Inlet pipe (top)
    canvas.drawLine(Offset(cx - size.width * 0.1, cy - size.height * 0.33),
        Offset(cx - size.width * 0.1, cy - size.height * 0.46), paint);

    // Outlet pipe (top right)
    canvas.drawLine(Offset(cx + size.width * 0.1, cy - size.height * 0.33),
        Offset(cx + size.width * 0.1, cy - size.height * 0.46), paint);

    if (isOn) {
      // Heat waves inside (animated)
      final wavePaint = Paint()
        ..color = AppColors.acColor.withValues(alpha: 0.5 + 0.4 * anim)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 3; i++) {
        final y = cy + (i - 1) * size.height * 0.12;
        final path = Path();
        path.moveTo(cx - size.width * 0.12, y);
        path.quadraticBezierTo(
          cx,
          y - size.height * (0.04 + 0.02 * anim),
          cx + size.width * 0.12,
          y,
        );
        canvas.drawPath(path, wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BoilerPainter old) =>
      old.isOn != isOn || old.anim != anim;
}

// ─────────────────────────────────────────────────────────────
// Gateway discovery sheet
// ─────────────────────────────────────────────────────────────
class _GatewayDiscoverySheet extends StatefulWidget {
  final _BoilerUnit unit;
  final VoidCallback onConnected;

  const _GatewayDiscoverySheet({
    required this.unit,
    required this.onConnected,
  });

  @override
  State<_GatewayDiscoverySheet> createState() => _GatewayDiscoverySheetState();
}

class _GatewayDiscoverySheetState extends State<_GatewayDiscoverySheet> {
  bool _scanning = true;
  List<_GatewayDevice> _found = [];
  _GatewayDevice? _installing;
  _GatewayDevice? _ready;

  static final _demoGateways = [
    _GatewayDevice(
      id: 'gw1',
      name: 'Zigbee Gateway 3.0',
      protocol: 'zigbee',
      ip: '192.168.1.12',
      model: 'Sonoff Zigbee Bridge Pro',
    ),
    _GatewayDevice(
      id: 'gw2',
      name: 'WiFi Smart Hub',
      protocol: 'wifi',
      ip: '192.168.1.18',
      model: 'TP-Link Tapo H200',
    ),
    _GatewayDevice(
      id: 'gw3',
      name: 'Zigbee Coordinator',
      protocol: 'zigbee',
      ip: '192.168.1.31',
      model: 'HUSBZB-1 USB Stick',
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _scanning = false;
          _found = List.from(_demoGateways);
        });
      }
    });
  }

  void _downloadDriver(_GatewayDevice gw) {
    setState(() {
      gw.driverDownloading = true;
      _installing = gw;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          gw.driverDownloading = false;
          gw.driverInstalled = true;
          _installing = null;
          _ready = gw;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.router_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.boilerSelectGateway,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.unit.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),

            // Content
            Expanded(
              child: _scanning
                  ? _ScanningView(label: s.boilerScanning)
                  : ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Found count header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${s.boilerGatewayFound} (${_found.length})',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        for (final gw in _found) ...[
                          _GatewayTile(
                            gateway: gw,
                            isInstalling: _installing == gw,
                            onDownload: gw.driverInstalled
                                ? null
                                : () => _downloadDriver(gw),
                            onConnect: gw.driverInstalled
                                ? widget.onConnected
                                : null,
                            labels: (
                              download: s.boilerDownloadDriver,
                              downloading: s.boilerDriverDownloading,
                              ready: s.boilerDriverReady,
                              connect: s.boilerReconnect,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        if (_ready != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: widget.onConnected,
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 18),
                              label: Text(s.boilerReconnect),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secured,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Scanning animation view
// ─────────────────────────────────────────────────────────────
class _ScanningView extends StatelessWidget {
  final String label;
  const _ScanningView({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                    AppColors.primary.withValues(alpha: 0.4)),
              ),
            ),
            const Icon(Icons.router_outlined,
                color: AppColors.primary, size: 32),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gateway tile
// ─────────────────────────────────────────────────────────────
typedef _GwLabels = ({
  String download,
  String downloading,
  String ready,
  String connect,
});

class _GatewayTile extends StatelessWidget {
  final _GatewayDevice gateway;
  final bool isInstalling;
  final VoidCallback? onDownload;
  final VoidCallback? onConnect;
  final _GwLabels labels;

  const _GatewayTile({
    required this.gateway,
    required this.isInstalling,
    required this.onDownload,
    required this.onConnect,
    required this.labels,
  });

  Color get _protoColor => gateway.protocol == 'zigbee'
      ? const Color(0xFFFFB300)
      : const Color(0xFF7BB8FF);

  IconData get _protoIcon =>
      gateway.protocol == 'zigbee' ? Icons.hub_outlined : Icons.wifi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gateway.driverInstalled
              ? AppColors.secured.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Protocol icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _protoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_protoIcon, color: _protoColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gateway.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${gateway.model}  •  ${gateway.ip}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action button
          if (gateway.driverInstalled)
            GestureDetector(
              onTap: onConnect,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secured.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.secured.withValues(alpha: 0.4)),
                ),
                child: Text(
                  labels.ready,
                  style: const TextStyle(
                    color: AppColors.secured,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (isInstalling)
            SizedBox(
              width: 70,
              child: Column(
                children: [
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(
                          AppColors.primary.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels.downloading,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  labels.download,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add boiler card
// ─────────────────────────────────────────────────────────────
class _AddBoilerCard extends StatelessWidget {
  final String label;
  const _AddBoilerCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Protocol badge row
          Row(
            children: [
              _ProtoBadge(icon: Icons.wifi, label: 'WiFi'),
              const SizedBox(width: 6),
              _ProtoBadge(icon: Icons.hub_outlined, label: 'Zigbee'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProtoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7BB8FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF7BB8FF).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BB8FF), size: 10),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF7BB8FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Smart switches section — shown under the boilers.
// Lists all DeviceType.smartSwitch devices with on/off toggles.
// ─────────────────────────────────────────────────────────────
class _SmartSwitchesSection extends StatelessWidget {
  const _SmartSwitchesSection();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final switches = state.devices
        .where((d) => d.type == DeviceType.smartSwitch)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.toggle_on_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              s.switchesCategory,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (switches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Center(
              child: Text(
                s.noDevicesConnected,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
              ),
            ),
          )
        else
          ...switches.map((d) => _SwitchRow(device: d, state: state)),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final Device device;
  final AppState state;
  const _SwitchRow({required this.device, required this.state});

  @override
  Widget build(BuildContext context) {
    final on = device.isOn;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (on ? AppColors.primary : Colors.white)
                  .withValues(alpha: on ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.toggle_on_outlined,
                color: on ? AppColors.primary : Colors.white38, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (device.room.isNotEmpty)
                  Text(device.room,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: on,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (_) => state.toggleDevice(device.id),
          ),
        ],
      ),
    );
  }
}
