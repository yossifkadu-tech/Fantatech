// ─────────────────────────────────────────────────────────────────────────────
// ScanDiscoveryScreen
//
// Real multi-protocol network scanner:
//   • WiFi  — parallel TCP probe of the /24 LAN subnet
//   • BLE   — Bluetooth Low Energy advertisement window
//   • Matter— mDNS queries (_matter._tcp, _esphomelib._tcp, …)
//   • Zigbee— gateway fingerprinting (Zigbee2MQTT, ZHA, Hue, IKEA, Sonoff)
//
// Uses DiscoveryManager (ChangeNotifier) for scan orchestration.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/discovery/device_classifier.dart';
import '../../services/discovery/discovery_manager.dart';
import '../../theme/app_theme.dart';
import 'sensor_hub_screen.dart';
import 'smart_switch_hub_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Protocol tabs
// ─────────────────────────────────────────────────────────────────────────────
enum _Protocol { all, wifi, ble, matter, zigbee }

extension _ProtocolX on _Protocol {
  String get label => switch (this) {
    _Protocol.all    => 'הכל',
    _Protocol.wifi   => 'WiFi',
    _Protocol.ble    => 'BLE',
    _Protocol.matter => 'Matter',
    _Protocol.zigbee => 'Zigbee',
  };

  Color get color => switch (this) {
    _Protocol.all    => AppColors.primary,
    _Protocol.wifi   => const Color(0xFF18BCEC),
    _Protocol.ble    => const Color(0xFF7B68EE),
    _Protocol.matter => const Color(0xFF00C896),
    _Protocol.zigbee => const Color(0xFFFF9D00),
  };

  IconData get icon => switch (this) {
    _Protocol.all    => Icons.all_inclusive,
    _Protocol.wifi   => Icons.wifi_rounded,
    _Protocol.ble    => Icons.bluetooth_rounded,
    _Protocol.matter => Icons.hub_outlined,
    _Protocol.zigbee => Icons.settings_input_antenna,
  };

  bool matches(DiscoveryProtocol p) => switch (this) {
    _Protocol.all    => true,
    _Protocol.wifi   => p == DiscoveryProtocol.wifi,
    _Protocol.ble    => p == DiscoveryProtocol.ble,
    _Protocol.matter => p == DiscoveryProtocol.matter,
    _Protocol.zigbee => p == DiscoveryProtocol.zigbee,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ScanDiscoveryScreen extends StatefulWidget {
  const ScanDiscoveryScreen({super.key});

  @override
  State<ScanDiscoveryScreen> createState() => _ScanDiscoveryScreenState();
}

class _ScanDiscoveryScreenState extends State<ScanDiscoveryScreen>
    with TickerProviderStateMixin {

  final DiscoveryManager _manager = DiscoveryManager();
  _Protocol _filter = _Protocol.all;
  final Set<String> _addedIds = {};

  late final AnimationController _radarCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _manager.addListener(_onManagerUpdate);
    _requestAndScan();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _manager.removeListener(_onManagerUpdate);
    _manager.cancelScan();
    _manager.dispose();
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  // ── Permissions + start ───────────────────────────────────────────────────
  Future<void> _requestAndScan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    _startScan();
  }

  void _startScan() {
    _addedIds.clear();
    _manager.setStrings(context.read<AppState>().strings);
    _manager.startScan();
  }

  // ── Add device to AppState ────────────────────────────────────────────────
  void _addDevice(DiscoveredDevice d) {
    final appState = context.read<AppState>();
    final device = Device(
      id: d.id,
      name: d.displayName,
      type: DeviceClassifier.toAppType(d.type),
      status: DeviceStatus.online,
      isOn: d.type != DiscoveredDeviceType.gateway &&
            d.type != DiscoveredDeviceType.router,
      attributes: {
        if (d.ip != null) 'ip': d.ip,
        if (d.mac != null) 'mac': d.mac,
        if (d.manufacturer != null) 'manufacturer': d.manufacturer,
        if (d.model != null) 'model': d.model,
        'protocol': d.protocol.name,
      },
    );
    appState.addDevice(device);
    _manager.registerDevice(d.id);
    setState(() => _addedIds.add(d.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${d.displayName} — ${appState.strings.added}'),
        backgroundColor: AppColors.secured,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Filtered list ─────────────────────────────────────────────────────────
  List<DiscoveredDevice> get _filtered =>
      _manager.devices.where((d) => _filter.matches(d.protocol)).toList();

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final isScanning = _manager.isScanning;

    return Scaffold(
      backgroundColor: context.tBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Smart switches
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'smart_switch',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SmartSwitchHubScreen())),
                backgroundColor: const Color(0xFF00B4D8),
                icon: Icon(Icons.power_settings_new, size: 18),
                label: Text('מפסקים',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            // Sensors & shutters
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'sensor_hub',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SensorHubScreen())),
                backgroundColor: const Color(0xFFFF6B35),
                icon: Icon(Icons.sensors_rounded, size: 18),
                label: Text('חיישנים · תריסים',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────
            _TopBar(
              isScanning: isScanning,
              onStop:  isScanning ? _manager.cancelScan : null,
              onRescan: (!isScanning && _manager.status == DiscoveryStatus.done)
                  ? _startScan
                  : null,
            ),

            // ── Scan progress ──────────────────────────────────
            _ScanProgress(
              manager: _manager,
              radarCtrl: _radarCtrl,
              pulseCtrl: _pulseCtrl,
            ),

            // ── Protocol filter chips ──────────────────────────
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                children: _Protocol.values.map((p) {
                  final active = _filter == p;
                  final count = p == _Protocol.all
                      ? _manager.devices.length
                      : _manager.devices
                          .where((d) => p.matches(d.protocol))
                          .length;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? p.color.withValues(alpha: 0.18)
                            : context.tText2(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? p.color.withValues(alpha: 0.6)
                              : context.tText2(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(p.icon,
                              size: 14,
                              color: active
                                  ? p.color
                                  : context.tText2(0.45)),
                          const SizedBox(width: 5),
                          Text(p.label,
                              style: TextStyle(
                                color: active
                                    ? p.color
                                    : context.tText2(0.45),
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              )),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$count',
                                  style: TextStyle(
                                      color: p.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // ── Results ────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(isScanning: isScanning, filter: _filter)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final d = filtered[i];
                        final added = _addedIds.contains(d.id) ||
                            d.isRegistered;
                        return _DeviceResultCard(
                          device: d,
                          added: added,
                          onAdd: added ? null : () => _addDevice(d),
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

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isScanning;
  final VoidCallback? onStop;
  final VoidCallback? onRescan;

  const _TopBar({
    required this.isScanning,
    this.onStop,
    this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: context.tText, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('סריקת רשת',
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(
                  isScanning ? 'מחפש מכשירים...' : 'בחר מכשיר להוספה',
                  style: TextStyle(
                      color: context.tText2(0.45),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (onRescan != null)
            GestureDetector(
              onTap: onRescan,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: AppColors.primary, size: 16),
                    SizedBox(width: 5),
                    Text('סרוק שוב',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          if (onStop != null)
            GestureDetector(
              onTap: onStop,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.unsecured.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.unsecured.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop_rounded,
                        color: AppColors.unsecured, size: 16),
                    SizedBox(width: 5),
                    Text('עצור',
                        style: TextStyle(
                            color: AppColors.unsecured,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan progress + radar + protocol indicators
// ─────────────────────────────────────────────────────────────────────────────
class _ScanProgress extends StatelessWidget {
  final DiscoveryManager manager;
  final AnimationController radarCtrl;
  final AnimationController pulseCtrl;

  const _ScanProgress({
    required this.manager,
    required this.radarCtrl,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isScanning = manager.isScanning;
    final progress = manager.progress.clamp(0.0, 1.0);
    final found = manager.devices.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isScanning
              ? AppColors.primary.withValues(alpha: 0.25)
              : context.tText2(0.07),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Radar animation
              SizedBox(
                width: 52,
                height: 52,
                child: isScanning
                    ? AnimatedBuilder(
                        animation: radarCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _RadarPainter(
                            angle: radarCtrl.value * 2 * math.pi,
                            pulse: pulseCtrl.value,
                          ),
                        ),
                      )
                    : Center(
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: found > 0
                                ? AppColors.secured.withValues(alpha: 0.15)
                                : context.tText2(0.05),
                          ),
                          child: Icon(
                            found > 0
                                ? Icons.check_rounded
                                : Icons.wifi_find_outlined,
                            color: found > 0
                                ? AppColors.secured
                                : context.tText2(0.38),
                            size: 20,
                          ),
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status text
                    Text(
                      isScanning
                          ? (manager.progressMessage.isNotEmpty
                              ? manager.progressMessage
                              : 'סורק...')
                          : (found > 0
                              ? '$found מכשירים נמצאו'
                              : 'לא נמצאו מכשירים'),
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isScanning ? (progress > 0 ? progress : null) : 1.0,
                        backgroundColor: context.tText2(0.07),
                        valueColor: AlwaysStoppedAnimation(
                          found > 0 ? AppColors.secured : AppColors.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Protocol activity indicators
          Row(
            children: [
              _ProtoChip(
                  label: 'WiFi',
                  icon: Icons.wifi_rounded,
                  color: const Color(0xFF18BCEC),
                  active: manager.wifiRunning),
              const SizedBox(width: 6),
              _ProtoChip(
                  label: 'BLE',
                  icon: Icons.bluetooth_rounded,
                  color: const Color(0xFF7B68EE),
                  active: manager.bleRunning),
              const SizedBox(width: 6),
              _ProtoChip(
                  label: 'Matter',
                  icon: Icons.hub_outlined,
                  color: const Color(0xFF00C896),
                  active: manager.matterRunning),
              const SizedBox(width: 6),
              _ProtoChip(
                  label: 'Zigbee',
                  icon: Icons.settings_input_antenna,
                  color: const Color(0xFFFF9D00),
                  active: manager.gatewayRunning),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;

  const _ProtoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.15)
            : context.tText2(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.45)
              : context.tText2(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: active ? color : context.tText2(0.25)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? color : context.tText2(0.25))),
          if (active) ...[
            const SizedBox(width: 4),
            _PulseDot(color: color),
          ],
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: 5, height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar custom painter
// ─────────────────────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double angle;
  final double pulse;

  const _RadarPainter({required this.angle, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 1;

    // Background rings
    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final frac in [0.35, 0.65, 1.0]) {
      canvas.drawCircle(Offset(cx, cy), r * frac, ringPaint);
    }

    // Sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.4,
        endAngle: angle,
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.35),
        ],
        transform: GradientRotation(angle - 1.4),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, sweepPaint);

    // Sweep line
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
      linePaint,
    );

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy), 3,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.angle != angle || old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// Device result card
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceResultCard extends StatelessWidget {
  final DiscoveredDevice device;
  final bool added;
  final VoidCallback? onAdd;

  const _DeviceResultCard({
    required this.device,
    required this.added,
    this.onAdd,
  });

  static IconData _icon(DiscoveredDeviceType t) => switch (t) {
    DiscoveredDeviceType.light         => Icons.lightbulb_outlined,
    DiscoveredDeviceType.socket        => Icons.power_outlined,
    DiscoveredDeviceType.smartSwitch   => Icons.toggle_on_outlined,
    DiscoveredDeviceType.thermostat    => Icons.thermostat_outlined,
    DiscoveredDeviceType.camera        => Icons.videocam_outlined,
    DiscoveredDeviceType.gateway       => Icons.hub_outlined,
    DiscoveredDeviceType.boiler        => Icons.water_drop_outlined,
    DiscoveredDeviceType.solar         => Icons.wb_sunny_outlined,
    DiscoveredDeviceType.circuitBreaker=> Icons.electrical_services,
    DiscoveredDeviceType.energyMeter   => Icons.bolt_outlined,
    DiscoveredDeviceType.smokeSensor   => Icons.local_fire_department_outlined,
    DiscoveredDeviceType.motionSensor  => Icons.sensors_outlined,
    DiscoveredDeviceType.windowSensor  => Icons.window_outlined,
    DiscoveredDeviceType.doorSensor    => Icons.sensor_door_outlined,
    DiscoveredDeviceType.router        => Icons.router_outlined,
    DiscoveredDeviceType.speaker       => Icons.speaker_outlined,
    DiscoveredDeviceType.tv            => Icons.tv_outlined,
    _                                  => Icons.devices_outlined,
  };

  static Color _color(DiscoveredDeviceType t) => switch (t) {
    DiscoveredDeviceType.light         => AppColors.lightColor,
    DiscoveredDeviceType.socket        => AppColors.plugColor,
    DiscoveredDeviceType.smartSwitch   => AppColors.plugColor,
    DiscoveredDeviceType.thermostat    => AppColors.acColor,
    DiscoveredDeviceType.camera        => AppColors.cameraColor,
    DiscoveredDeviceType.gateway       => const Color(0xFF18BCEC),
    DiscoveredDeviceType.boiler        => AppColors.acColor,
    DiscoveredDeviceType.solar         => const Color(0xFFFFB300),
    DiscoveredDeviceType.energyMeter   => const Color(0xFFFFD600),
    DiscoveredDeviceType.smokeSensor   => AppColors.unsecured,
    DiscoveredDeviceType.motionSensor  => AppColors.motionColor,
    DiscoveredDeviceType.router        => const Color(0xFF18BCEC),
    _                                  => AppColors.primary,
  };

  static Color _protocolColor(DiscoveryProtocol p) => switch (p) {
    DiscoveryProtocol.wifi   => const Color(0xFF18BCEC),
    DiscoveryProtocol.ble    => const Color(0xFF7B68EE),
    DiscoveryProtocol.matter => const Color(0xFF00C896),
    DiscoveryProtocol.zigbee => const Color(0xFFFF9D00),
    DiscoveryProtocol.zwave  => const Color(0xFFFF6B6B),
    _                        => Colors.white.withValues(alpha: 0.38),
  };

  static String _protocolLabel(DiscoveryProtocol p) => switch (p) {
    DiscoveryProtocol.wifi   => 'WiFi',
    DiscoveryProtocol.ble    => 'BLE',
    DiscoveryProtocol.matter => 'Matter',
    DiscoveryProtocol.zigbee => 'Zigbee',
    DiscoveryProtocol.zwave  => 'Z-Wave',
    _                        => 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    final iconData  = _icon(device.type);
    final iconColor = _color(device.type);
    final protoClr  = _protocolColor(device.protocol);
    final address   = device.ip ?? device.mac ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: added
              ? AppColors.secured.withValues(alpha: 0.3)
              : context.tText2(0.07),
        ),
      ),
      child: Row(
        children: [
          // ── Device icon ───────────────────────────────────
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),

          const SizedBox(width: 12),

          // ── Name + details ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.displayName,
                        style: TextStyle(
                          color: context.tText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Protocol badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: protoClr.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: protoClr.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        _protocolLabel(device.protocol),
                        style: TextStyle(
                          color: protoClr,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (device.manufacturer != null) ...[
                      Text(
                        device.manufacturer!,
                        style: TextStyle(
                          color: context.tText2(0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(' · ',
                          style: TextStyle(
                              color: context.tText2(0.25),
                              fontSize: 11)),
                    ],
                    Flexible(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: context.tText2(0.35),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Add button ────────────────────────────────────
          GestureDetector(
            onTap: onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: added
                    ? AppColors.secured.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: added
                      ? AppColors.secured.withValues(alpha: 0.5)
                      : AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                added ? Icons.check_rounded : Icons.add_rounded,
                color: added ? AppColors.secured : AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isScanning;
  final _Protocol filter;

  const _EmptyState({required this.isScanning, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScanning ? Icons.radar : Icons.wifi_find_outlined,
            size: 56,
            color: context.tText2(0.15),
          ),
          const SizedBox(height: 14),
          Text(
            isScanning
                ? 'מחפש מכשירים ${filter == _Protocol.all ? "" : "(${filter.label})"}'
                : 'לא נמצאו מכשירים',
            style: TextStyle(
              color: context.tText2(0.35),
              fontSize: 15,
            ),
          ),
          if (!isScanning) ...[
            const SizedBox(height: 6),
            Text(
              'ודא שהמכשיר מחובר לאותה רשת WiFi',
              style: TextStyle(
                color: context.tText2(0.22),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
