import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// SensorHubScreen
//
// Two-tab screen:
//   חיישנים  — motion sensors + door/window contacts  (read + refresh)
//   תריסים   — smart covers / roller shutters         (control + position)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/discovery/ha_client.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_types.dart';
import '../../services/sensors/cover_controller.dart';
import '../../services/sensors/sensor_controller.dart';
import '../../services/sensors/sensor_models.dart';
import '../../services/sensors/sensor_scan_engine.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../widgets/device_edit_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────

class SensorHubScreen extends StatelessWidget {
  const SensorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SensorScanEngine(),
      child: const _SensorHubView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SensorHubView extends StatefulWidget {
  const _SensorHubView();
  @override
  State<_SensorHubView> createState() => _SensorHubViewState();
}

class _SensorHubViewState extends State<_SensorHubView>
    with SingleTickerProviderStateMixin {

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    if (!mounted) return;
    final engine = context.read<SensorScanEngine>();

    final haIp    = await HaClient.savedIp();
    final haToken = await HaClient.savedToken();

    String? mqttHost;
    int    mqttPort = 1883;
    String? mqttUser, mqttPass;
    String? aqaraIp, aqaraToken;

    if (mounted) {
      final gm = context.read<GatewayManager>();
      final mqttConn = gm.connections.where((c) =>
          (c.type == GatewayType.mqtt || c.type == GatewayType.zigbee2mqtt) &&
          c.isConnected).firstOrNull;
      if (mqttConn != null) {
        mqttHost = mqttConn.credentials['host'] ?? mqttConn.ip;
        mqttPort = int.tryParse(mqttConn.credentials['port'] ?? '1883') ?? 1883;
        mqttUser = mqttConn.credentials['username'];
        mqttPass = mqttConn.credentials['password'];
      }

      final aqaraConn = gm.connections.where((c) =>
          c.type == GatewayType.aqara && c.isConnected).firstOrNull;
      if (aqaraConn != null) {
        aqaraIp    = aqaraConn.ip;
        aqaraToken = aqaraConn.token;
      }
    }

    if (!mounted) return;
    engine.startScan(
      haIp:       haIp,
      haToken:    haToken,
      mqttHost:   mqttHost,
      mqttPort:   mqttPort,
      mqttUser:   mqttUser,
      mqttPass:   mqttPass,
      aqaraIp:    aqaraIp,
      aqaraToken: aqaraToken,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SensorScanEngine>();

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            _Header(
              isScanning: engine.isScanning,
              sensorsCount: engine.sensors.length,
              coversCount:  engine.covers.length,
              onScan: engine.isScanning ? null : _startScan,
            ),

            // ── Protocol progress chips ───────────────────────────────────────
            if (engine.isScanning || engine.sensors.isNotEmpty || engine.covers.isNotEmpty)
              _ProgressChips(engine: engine),

            // ── Tabs ──────────────────────────────────────────────────────────
            _TabBar(controller: _tabs),

            // ── Tab content ───────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SensorsTab(engine: engine, onScan: _startScan),
                  _CoversTab(engine: engine,  onScan: _startScan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isScanning;
  final int  sensorsCount;
  final int  coversCount;
  final VoidCallback? onScan;

  const _Header({
    required this.isScanning,
    required this.sensorsCount,
    required this.coversCount,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    final total = sensorsCount + coversCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Symbols.arrow_back_ios_new,
                color: context.tText2(0.7), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.sensorHubTitle,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(
                  isScanning
                      ? s.searching
                      : total == 0
                          ? s.noDevicesOnNetwork
                          : s.sensorHubFoundFmt
                              .replaceAll('{sensors}', '$sensorsCount')
                              .replaceAll('{covers}', '$coversCount'),
                  style: TextStyle(color: context.tText2(0.54), fontSize: 12),
                ),
              ],
            ),
          ),
          if (isScanning)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          else
            TextButton.icon(
              onPressed: onScan,
              icon: const Icon(Symbols.radar, size: 16),
              label: Text(s.rescan, style: const TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            ),
        ],
      ),
    );
  }
}

// ── Protocol progress chips ────────────────────────────────────────────────────

class _ProgressChips extends StatelessWidget {
  final SensorScanEngine engine;
  const _ProgressChips({required this.engine});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: engine.scanStates.values.map((s) {
          final scanning = s.status == SensorScanStatus.scanning;
          final hasFound = s.found > 0;
          return Container(
            margin: const EdgeInsetsDirectional.only(end: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasFound
                  ? s.color.withValues(alpha: 0.15)
                  : context.tText2(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: hasFound
                      ? s.color.withValues(alpha: 0.45)
                      : context.tText2(0.10)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (scanning)
                SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: s.color),
                )
              else
                Icon(s.icon, color: s.color, size: 11),
              const SizedBox(width: 5),
              Text(s.key,
                  style: TextStyle(
                      color: hasFound ? s.color : context.tText2(0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              if (hasFound) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${s.found}',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tab bar ────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.tText2(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.primary,
        unselectedLabelColor: context.tText2(0.38),
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: [
          Tab(icon: const Icon(Symbols.sensors, size: 16), text: s.sensorsTab),
          Tab(icon: const Icon(Symbols.window,  size: 16), text: s.shuttersTab),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SENSORS TAB
// ══════════════════════════════════════════════════════════════════════════════

// Device types that count as sensors
const _kSensorDeviceTypes = {
  DeviceType.motionSensor,
  DeviceType.doorSensor,
  DeviceType.windowSensor,
  DeviceType.smokeSensor,
  DeviceType.waterLeakSensor,
  DeviceType.gasSensor,
  DeviceType.glassBreakSensor,
};

class _SensorsTab extends StatelessWidget {
  final SensorScanEngine engine;
  final VoidCallback onScan;
  const _SensorsTab({required this.engine, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;

    // IDs already covered by live scan results (registered from this engine)
    final scannedIds =
        engine.sensors.map((e) => 'sensor-${e.id}').toSet();

    // Saved devices from state that are sensor types and not in the scan list
    final savedDevices = appState.devices
        .where((d) =>
            _kSensorDeviceTypes.contains(d.type) &&
            !scannedIds.contains(d.id))
        .toList();

    final totalItems = engine.sensors.length + savedDevices.length;

    if (totalItems == 0) {
      return _EmptyState(
          isScanning: engine.isScanning,
          icon: Symbols.sensors,
          message: s.noSensorsFound,
          hint: 'Shelly Door/Window · Shelly Motion\n'
              'ESPHome binary_sensor · HA · Zigbee2MQTT',
          onScan: onScan);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: totalItems,
      itemBuilder: (_, i) {
        if (i < engine.sensors.length) {
          return _SensorCard(sensor: engine.sensors[i]);
        }
        return _SavedSensorCard(
            device: savedDevices[i - engine.sensors.length]);
      },
    );
  }
}

// ── Card for a sensor saved in state.devices (no live scan data) ─────────────
class _SavedSensorCard extends StatelessWidget {
  final Device device;
  const _SavedSensorCard({required this.device});

  SensorType get _sensorType => switch (device.type) {
        DeviceType.doorSensor      => SensorType.contact,
        DeviceType.windowSensor    => SensorType.contact,
        DeviceType.smokeSensor     => SensorType.smoke,
        DeviceType.waterLeakSensor => SensorType.water,
        DeviceType.gasSensor       => SensorType.smoke,
        DeviceType.glassBreakSensor=> SensorType.vibration,
        _                          => SensorType.motion,
      };

  @override
  Widget build(BuildContext context) {
    final type    = _sensorType;
    final color   = type.color;
    final online  = device.status == DeviceStatus.online;
    final triggered = device.isOn;

    return GestureDetector(
      onLongPress: () => showDeviceEditSheet(context,
          device: device, state: context.read<AppState>()),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: triggered
            ? color.withValues(alpha: 0.10)
            : context.tText2(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: triggered
              ? color.withValues(alpha: 0.40)
              : context.tText2(0.07),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon + pulse dot
            SizedBox(
              width: 44, height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(type.icon, color: color, size: 22),
                  ),
                  if (triggered)
                    Positioned(
                      right: 2, top: 2,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _Tag(
                      device.attributes['protocol'] as String? ?? 'wifi',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    _Tag(type.displayName, color),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    type.triggeredLabel(triggered),
                    style: TextStyle(
                      color: triggered ? color : context.tText2(0.45),
                      fontSize: 12,
                      fontWeight: triggered
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Online/offline indicator
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: online ? AppColors.secured : AppColors.unsecured,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Sensor card ───────────────────────────────────────────────────────────────

class _SensorCard extends StatefulWidget {
  final SmartSensor sensor;
  const _SensorCard({required this.sensor});
  @override
  State<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<_SensorCard> {
  bool _refreshing = false;
  SmartSensor get s => widget.sensor;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await SensorController.refresh(s);
    if (mounted) setState(() => _refreshing = false);
  }

  void _addToHome() {
    final appState = context.read<AppState>();
    final str = appState.strings;
    appState.upsertDevice(Device(
      id:   'sensor-${s.id}',
      name: s.name,
      type: s.type == SensorType.motion
          ? DeviceType.motionSensor
          : s.type == SensorType.contact
              ? DeviceType.doorSensor
              : DeviceType.motionSensor,
      isOn: s.isTriggered ?? false,
      status: s.isOnline ? DeviceStatus.online : DeviceStatus.offline,
      attributes: {
        'ip':       s.ip ?? '',
        'brand':    s.brand,
        'protocol': s.protocol.name,
        'type':     s.type.name,
        ...s.connectionData,
      },
    ));
    setState(() => s.isRegistered = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(str.switchAddedFmt.replaceAll('{name}', s.name)),
      backgroundColor: AppColors.secured,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final str       = context.select((AppState st) => st.strings);
    final color     = s.type.color;
    final triggered = s.isTriggered;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: triggered == true
            ? color.withValues(alpha: 0.10)
            : context.tText2(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: triggered == true
              ? color.withValues(alpha: 0.40)
              : context.tText2(0.07),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── State dot + type icon ────────────────────────────────────────
            SizedBox(
              width: 44, height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.type.icon, color: color, size: 22),
                  ),
                  // Triggered pulse dot
                  if (triggered == true)
                    Positioned(
                      right: 2, top: 2,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.6),
                                blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _Tag(s.protocol.displayName, s.protocol.color),
                    const SizedBox(width: 5),
                    _Tag(s.type.displayName, s.type.color),
                  ]),
                  const SizedBox(height: 5),
                  // State label
                  Text(
                    s.type.triggeredLabel(triggered),
                    style: TextStyle(
                        color: triggered == true ? color : context.tText2(0.38),
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  // Extra readings
                  if (s.temperature != null || s.humidity != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.temperature != null) ...[
                            Icon(DeviceIcons.forHaDeviceClass('temperature'),
                                size: 12, color: context.tText2(0.54)),
                            const SizedBox(width: 2),
                            Text('${s.temperature!.toStringAsFixed(1)} °C',
                                style: TextStyle(
                                    color: context.tText2(0.54), fontSize: 11)),
                          ],
                          if (s.temperature != null && s.humidity != null)
                            const SizedBox(width: 8),
                          if (s.humidity != null) ...[
                            Icon(DeviceIcons.forHaDeviceClass('humidity'),
                                size: 12, color: context.tText2(0.54)),
                            const SizedBox(width: 2),
                            Text('${s.humidity!.toStringAsFixed(0)} %',
                                style: TextStyle(
                                    color: context.tText2(0.54), fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  if (s.batteryPercent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(DeviceIcons.batteryIcon(s.batteryPercent),
                              size: 12,
                              color: s.batteryPercent! < 20
                                  ? AppColors.statusAlarm
                                  : context.tText2(0.38)),
                          const SizedBox(width: 2),
                          Text('${s.batteryPercent} %',
                              style: TextStyle(
                                  color: s.batteryPercent! < 20
                                      ? AppColors.statusAlarm
                                      : context.tText2(0.38),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Buttons ──────────────────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh
                GestureDetector(
                  onTap: _refresh,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: context.tText2(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _refreshing
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: AppColors.primary))
                        : Icon(Symbols.refresh,
                            color: context.tText2(0.54), size: 18),
                  ),
                ),
                const SizedBox(height: 6),
                // Add to home
                if (!s.isRegistered)
                  GestureDetector(
                    onTap: _addToHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: color.withValues(alpha: 0.40)),
                      ),
                      child: Text(str.add,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  Icon(Symbols.check_circle,
                      color: color, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COVERS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _CoversTab extends StatelessWidget {
  final SensorScanEngine engine;
  final VoidCallback onScan;
  const _CoversTab({required this.engine, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    if (engine.covers.isEmpty) {
      return _EmptyState(
          isScanning: engine.isScanning,
          icon: Symbols.window,
          message: s.noCoversFound,
          hint: 'Shelly 2.5 roller mode · Shelly Plus 2PM cover mode\n'
              'ESPHome cover · Home Assistant cover.* · Zigbee',
          onScan: onScan);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: engine.covers.length,
      itemBuilder: (_, i) => _CoverCard(cover: engine.covers[i]),
    );
  }
}

// ── Cover card ────────────────────────────────────────────────────────────────

class _CoverCard extends StatefulWidget {
  final SmartCover cover;
  const _CoverCard({required this.cover});
  @override
  State<_CoverCard> createState() => _CoverCardState();
}

class _CoverCardState extends State<_CoverCard> {
  bool _busy = false;
  double? _sliderValue; // local slider value while dragging

  SmartCover get c => widget.cover;

  Future<void> _action(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (mounted) {
      if (!ok) _showError();
      // Refresh state after command
      final status = await CoverController.readState(c);
      if (mounted && status != null) {
        setState(() {
          c.state    = status.state;
          c.position = status.position;
          _busy      = false;
        });
      } else if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setPosition(int pos) =>
      _action(() => CoverController.setPosition(c, pos));

  void _showError() {
    final str = context.read<AppState>().strings;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(str.errControlFmt.replaceAll('{name}', c.name)),
      backgroundColor: AppColors.statusAlarm,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _addToHome() {
    final appState = context.read<AppState>();
    final str = appState.strings;
    appState.upsertDevice(Device(
      id:   'cover-${c.id}',
      name: c.name,
      type: DeviceType.smartSwitch,
      isOn: c.state == CoverState.open,
      status: c.isOnline ? DeviceStatus.online : DeviceStatus.offline,
      attributes: {
        'ip':       c.ip ?? '',
        'brand':    c.brand,
        'protocol': c.protocol.name,
        'deviceClass': 'cover',
        ...c.connectionData,
      },
    ));
    setState(() => c.isRegistered = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(str.switchAddedFmt.replaceAll('{name}', c.name)),
      backgroundColor: AppColors.secured,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final str      = context.select((AppState st) => st.strings);
    final color    = c.protocol.color;
    final stateCol = c.state.color;
    final pos      = c.position;
    final sliderVal = _sliderValue ?? pos?.toDouble() ?? 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isRegistered
              ? color.withValues(alpha: 0.35)
              : context.tText2(0.07),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c.protocol.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(
                      [
                        if (c.ip != null) c.ip!,
                        if (c.model != null) c.model!,
                      ].join(' · '),
                      style: TextStyle(
                          color: context.tText2(0.54), fontSize: 11),
                    ),
                  ],
                ),
              ),
              // State badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stateCol.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stateCol.withValues(alpha: 0.40)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (c.state.isMoving)
                    SizedBox(
                      width: 10, height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: stateCol),
                    )
                  else
                    Icon(Symbols.window, color: stateCol, size: 12),
                  const SizedBox(width: 4),
                  Text(c.state.label,
                      style: TextStyle(
                          color: stateCol,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Protocol tag + position ───────────────────────────────────────
            Row(children: [
              _Tag(c.protocol.displayName, color),
              if (pos != null) ...[
                const SizedBox(width: 6),
                _Tag('$pos %', context.tText2(0.54)),
              ],
              const Spacer(),
              if (!c.isRegistered)
                GestureDetector(
                  onTap: _addToHome,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: color.withValues(alpha: 0.40)),
                    ),
                    child: Text(str.add,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                )
              else
                Icon(Symbols.check_circle, color: color, size: 20),
            ]),

            const SizedBox(height: 12),

            // ── Position slider ───────────────────────────────────────────────
            if (c.hasPositionControl && pos != null) ...[
              Row(children: [
                Icon(Symbols.unfold_less,
                    color: context.tText2(0.38), size: 14),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7),
                      activeTrackColor: color,
                      inactiveTrackColor: context.tText2(0.12),
                      thumbColor: color,
                      overlayColor: color.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: sliderVal.clamp(0, 100),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      onChanged: (v) =>
                          setState(() => _sliderValue = v),
                      onChangeEnd: (v) {
                        _sliderValue = null;
                        _setPosition(v.round());
                      },
                    ),
                  ),
                ),
                Icon(Symbols.unfold_more,
                    color: context.tText2(0.38), size: 14),
              ]),
            ],

            // ── Control buttons ───────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: _CtrlButton(
                  label: str.coverOpen,
                  color: AppColors.secured,
                  busy: _busy,
                  onTap: () => _action(() => CoverController.open(c)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CtrlButton(
                  label: str.coverStop,
                  color: AppColors.statusWarning,
                  busy: _busy,
                  onTap: () => _action(() => CoverController.stop(c)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CtrlButton(
                  label: str.coverClose,
                  color: AppColors.statusOffline,
                  busy: _busy,
                  onTap: () => _action(() => CoverController.close(c)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────

class _CtrlButton extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   busy;
  final VoidCallback onTap;

  const _CtrlButton({
    required this.label,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: busy
              ? context.tText2(0.04)
              : color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: busy
                ? context.tText2(0.08)
                : color.withValues(alpha: 0.40),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: busy ? context.tText2(0.24) : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isScanning;
  final IconData icon;
  final String message;
  final String hint;
  final VoidCallback onScan;

  const _EmptyState({
    required this.isScanning,
    required this.icon,
    required this.message,
    required this.hint,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    if (isScanning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
            const SizedBox(height: 16),
            Text(s.searching,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.tText2(0.15), size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  color: context.tText2(0.38),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(hint,
                style: TextStyle(
                    color: context.tText2(0.24), fontSize: 11),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Symbols.radar, size: 16),
            label: Text(s.rescan),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color  color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}
