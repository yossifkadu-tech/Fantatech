import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// DiscoverySheet
//
// Full-screen bottom sheet that drives the RealDiscoveryEngine:
//   • Scan button → startScan()
//   • Linear progress bar + status text
//   • "Home Assistant נמצא!" banner when haIp != null && !haConnected
//     └─ "חבר" opens inline token field → connectHA(ip, token)
//   • Real-time list of discovered devices, one card per device
//     └─ "הוסף" button → appState.upsertDevice + engine.markRegistered
//   • "הוסף הכל" button adds every un-registered device at once
//
// Open with:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => const DiscoverySheet(),
//   );
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/discovery/real_discovery_engine.dart';
import '../../services/discovery/discovery_models.dart';
import '../../services/discovery/device_classifier.dart';
import '../../services/gateways/gateway_types.dart';
import '../gateways/gateway_connect_sheet.dart';
import '../../theme/app_theme.dart';

class DiscoverySheet extends StatefulWidget {
  const DiscoverySheet({super.key});

  @override
  State<DiscoverySheet> createState() => _DiscoverySheetState();
}

class _DiscoverySheetState extends State<DiscoverySheet> {
  // HA connect form
  bool _showHaForm   = false;
  bool _haConnecting = false;
  String? _haError;
  final _tokenCtrl = TextEditingController();
  final _ipCtrl    = TextEditingController();

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// If a discovered device is a gateway we can pair with directly (currently
  /// IKEA DIRIGERA), returns its GatewayType — otherwise null.
  GatewayType? _pairableGateway(DiscoveredDevice d) {
    final svc  = (d.metadata['serviceType'] ?? '').toString().toLowerCase();
    final name = d.displayName.toLowerCase();
    final mfr  = (d.manufacturer ?? '').toLowerCase();
    final isDirigera = svc.contains('ihsp') ||
        svc.contains('dirigera') ||
        name.contains('dirigera') ||
        (mfr.contains('ikea') && d.type == DiscoveredDeviceType.gateway);
    if (isDirigera) return GatewayType.dirigera;
    return null;
  }

  /// Opens the gateway pairing sheet with the IP pre-filled and the connection
  /// started automatically — the user only has to press the physical button.
  void _connectGateway(
    BuildContext context,
    GatewayType type,
    DiscoveredDevice d,
  ) {
    final meta = GatewayRegistry.forType(type);
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => GatewayConnectSheet(
        meta:          meta,
        initialFields: {if (d.ip != null) 'ip': d.ip!},
        autoConnect:   d.ip != null,
      ),
    );
  }

  /// Explains how to bring a Matter device into the app (via a Matter hub).
  void _showMatterHelp(BuildContext context) {
    final s = context.read<AppState>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          const Icon(Symbols.hexagon, color: Color(0xFF7B6FCD), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(s.matterDeviceTitle,
                style: TextStyle(
                    color: context.tText, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Text(
          s.matterDeviceHelp,
          style: TextStyle(color: context.tText2(0.7), fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.understood),
          ),
        ],
      ),
    );
  }

  /// Add one discovered device to AppState and mark it as registered.
  void _addDevice(
    BuildContext context,
    DiscoveredDevice d,
    RealDiscoveryEngine engine,
    AppState state,
  ) {
    // Pairable gateways (DIRIGERA) route to the OAuth pairing flow instead of
    // being added as a plain device.
    final gw = _pairableGateway(d);
    if (gw != null) {
      _connectGateway(context, gw, d);
      return;
    }

    // Matter devices can't be commissioned in-app — guide the user to pair
    // them through a Matter hub (DIRIGERA / Apple / Google) and import.
    final svc = (d.metadata['serviceType'] ?? '').toString().toLowerCase();
    if (d.protocol == DiscoveryProtocol.matter || svc.contains('matter')) {
      _showMatterHelp(context);
      return;
    }

    final appType = DeviceClassifier.toAppType(d.type);
    final room    = state.rooms.isNotEmpty
        ? (state.rooms.first['name'] as String)
        : '';

    state.upsertDevice(Device(
      id:   d.id,
      name: d.displayName,
      type: appType,
      room: room,
      attributes: {
        if (d.ip != null) 'ip': d.ip,
        if (d.manufacturer != null) 'manufacturer': d.manufacturer,
        if (d.model != null) 'model': d.model,
        ...d.metadata,
      },
    ));
    engine.markRegistered(d.id);
  }

  /// Add all un-registered devices at once.
  void _addAll(
    BuildContext context,
    RealDiscoveryEngine engine,
    AppState state,
  ) {
    // Gateways that need interactive pairing (button press) are skipped here —
    // they must be connected individually via their "הוסף" button.
    final pending = engine.found
        .where((d) => !d.isRegistered && _pairableGateway(d) == null)
        .toList();
    for (final d in pending) {
      _addDevice(context, d, engine, state);
    }
    final s = context.read<AppState>().strings;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.devicesAddedFmt.replaceAll('{n}', '${pending.length}')),
      backgroundColor: AppColors.secured,
      duration: const Duration(seconds: 2),
    ));
  }

  /// Attempt to connect to HA with the entered credentials.
  Future<void> _connectHa(
    RealDiscoveryEngine engine, {
    required String ip,
    required String token,
  }) async {
    if (ip.isEmpty || token.isEmpty) return;
    setState(() {
      _haConnecting = true;
      _haError      = null;
    });
    final err = await engine.connectHA(ip, token);
    if (!mounted) return;
    setState(() {
      _haConnecting = false;
      if (err != null) {
        _haError = err;
      } else {
        _showHaForm = false;
      }
    });
  }

  // ── Icon / colour maps ─────────────────────────────────────────────────────

  Color _typeColor(DiscoveredDeviceType t) => switch (t) {
    DiscoveredDeviceType.light         => AppColors.lightColor,
    DiscoveredDeviceType.boiler        => AppColors.acColor,
    DiscoveredDeviceType.thermostat    => AppColors.acColor,
    DiscoveredDeviceType.camera        => AppColors.cameraColor,
    DiscoveredDeviceType.motionSensor  => AppColors.motionColor,
    DiscoveredDeviceType.windowSensor  => AppColors.motionColor,
    DiscoveredDeviceType.doorSensor    => AppColors.motionColor,
    DiscoveredDeviceType.waterLeak     => AppColors.networkColor,
    DiscoveredDeviceType.smokeSensor   => AppColors.smokeColor,
    DiscoveredDeviceType.energyMeter   => AppColors.energyColor,
    DiscoveredDeviceType.gateway       => AppColors.networkColor,
    DiscoveredDeviceType.router        => AppColors.networkColor,
    _                                  => AppColors.plugColor,
  };

  IconData _typeIcon(DiscoveredDeviceType t) => switch (t) {
    DiscoveredDeviceType.light         => Symbols.lightbulb,
    DiscoveredDeviceType.socket        => Symbols.power,
    DiscoveredDeviceType.smartSwitch   => Symbols.toggle_on,
    DiscoveredDeviceType.thermostat    => Symbols.hvac,
    DiscoveredDeviceType.camera        => Symbols.videocam,
    DiscoveredDeviceType.gateway       => Symbols.hub,
    DiscoveredDeviceType.boiler        => Symbols.water_drop,
    DiscoveredDeviceType.solar         => Symbols.wb_sunny,
    DiscoveredDeviceType.circuitBreaker => Symbols.electrical_services,
    DiscoveredDeviceType.energyMeter   => Symbols.bolt,
    DiscoveredDeviceType.smokeSensor   => Symbols.local_fire_department,
    DiscoveredDeviceType.motionSensor  => Symbols.sensors,
    DiscoveredDeviceType.windowSensor  => Symbols.window,
    DiscoveredDeviceType.doorSensor    => Symbols.sensor_door,
    DiscoveredDeviceType.waterLeak     => Symbols.water_damage,
    DiscoveredDeviceType.router        => Symbols.router,
    DiscoveredDeviceType.speaker       => Symbols.speaker,
    DiscoveredDeviceType.tv            => Symbols.tv,
    _                                  => Symbols.device_unknown,
  };

  String _protocolLabel(DiscoveryProtocol p) => switch (p) {
    DiscoveryProtocol.zigbee  => 'Zigbee',
    DiscoveryProtocol.zwave   => 'Z-Wave',
    DiscoveryProtocol.matter  => 'Matter',
    DiscoveryProtocol.ble     => 'BLE',
    _                         => 'WiFi',
  };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<RealDiscoveryEngine>();
    final state  = context.watch<AppState>();
    final s      = state.strings;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize:     0.5,
      maxChildSize:     0.96,
      expand:           false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color:        context.tCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Symbols.radar, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.discoveryTitle,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Scan / stop button
                  _ScanButton(
                    isScanning: engine.isScanning,
                    onScan:     () => engine.startScan(),
                    onStop:     () => engine.stopScan(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Progress bar + status ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height:   engine.isScanning || engine.progress > 0 ? 4 : 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value:            engine.isScanning ? engine.progress : 1.0,
                        backgroundColor:  context.tText2(0.12),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  if (engine.status.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      engine.status,
                      style: TextStyle(
                        color:    context.tText2(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── HA detected banner ─────────────────────────────────────────
            if (engine.haIp != null)
              _HaBanner(
                ip:           engine.haIp!,
                connected:    engine.haConnected,
                deviceCount:  engine.haDeviceCount,
                showForm:     _showHaForm,
                connecting:   _haConnecting,
                error:        _haError,
                tokenCtrl:    _tokenCtrl,
                ipCtrl:       _ipCtrl,
                onToggleForm: () {
                  setState(() {
                    _showHaForm = !_showHaForm;
                    _haError    = null;
                    if (_showHaForm) _ipCtrl.text = engine.haIp!;
                  });
                },
                onConnect: () => _connectHa(
                  engine,
                  ip:    _ipCtrl.text.trim(),
                  token: _tokenCtrl.text.trim(),
                ),
              ),

            // ── Device list ────────────────────────────────────────────────
            Expanded(
              child: engine.found.isEmpty
                  ? _EmptyHint(isScanning: engine.isScanning)
                  : ListView.builder(
                      controller:  scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount:   engine.found.length,
                      itemBuilder: (_, i) {
                        final d = engine.found[i];
                        return _DeviceRow(
                          device:    d,
                          color:     _typeColor(d.type),
                          icon:      _typeIcon(d.type),
                          protocol:  _protocolLabel(d.protocol),
                          onAdd:     d.isRegistered
                              ? null
                              : () => _addDevice(context, d, engine, state),
                        );
                      },
                    ),
            ),

            // ── Add all button ─────────────────────────────────────────────
            if (engine.found.any((d) => !d.isRegistered))
              _AddAllBar(
                count:  engine.found.where((d) => !d.isRegistered).length,
                onTap:  () => _addAll(context, engine, state),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Scan / Stop button
// ─────────────────────────────────────────────────────────────
class _ScanButton extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;
  final VoidCallback onStop;

  const _ScanButton({
    required this.isScanning,
    required this.onScan,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return GestureDetector(
      onTap: isScanning ? onStop : onScan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color:        isScanning
              ? context.tText2(0.07)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border:       isScanning
              ? Border.all(color: context.tText2(0.15))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScanning ? Symbols.stop : Symbols.radar,
              color: isScanning
                  ? context.tText2(0.6)
                  : context.tText,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              isScanning ? s.stop : s.scan,
              style: TextStyle(
                color:      isScanning
                    ? context.tText2(0.6)
                    : context.tText,
                fontSize:   13,
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
// Home Assistant banner
// ─────────────────────────────────────────────────────────────
class _HaBanner extends StatelessWidget {
  final String ip;
  final bool connected;
  final int deviceCount;
  final bool showForm;
  final bool connecting;
  final String? error;
  final TextEditingController tokenCtrl;
  final TextEditingController ipCtrl;
  final VoidCallback onToggleForm;
  final VoidCallback onConnect;

  const _HaBanner({
    required this.ip,
    required this.connected,
    required this.deviceCount,
    required this.showForm,
    required this.connecting,
    required this.error,
    required this.tokenCtrl,
    required this.ipCtrl,
    required this.onToggleForm,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    final haColor = AppColors.networkColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color:        haColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: connected
              ? AppColors.secured.withValues(alpha: 0.4)
              : haColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Symbols.home,
                    color: connected ? AppColors.secured : haColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.haFound,
                        style: TextStyle(
                          color:      connected ? AppColors.secured : haColor,
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        connected
                            ? s.haConnectedFmt.replaceAll('{n}', '$deviceCount')
                            : ip,
                        style: TextStyle(
                          color:    context.tText2(0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!connected)
                  GestureDetector(
                    onTap: onToggleForm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color:        haColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                        border:       Border.all(
                            color: haColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        showForm ? s.cancel : s.haConnect,
                        style: TextStyle(
                          color:      haColor,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(Symbols.check_circle,
                      color: AppColors.secured, size: 20),
              ],
            ),
          ),

          // Expandable connect form
          if (showForm && !connected)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IP field
                  _HaField(
                    ctrl:        ipCtrl,
                    label:       s.ipAddressLabel,
                    hint:        '192.168.x.x',
                    icon:        Symbols.wifi,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),

                  // Token field
                  _HaField(
                    ctrl:   tokenCtrl,
                    label:  'Long-Lived Access Token',
                    hint:   'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...',
                    icon:   Symbols.key,
                    obscure: false,
                    small:   true,
                  ),

                  const SizedBox(height: 6),
                  Text(
                    s.haTokenHint,
                    style: TextStyle(
                      color:    context.tText2(0.35),
                      fontSize: 10,
                    ),
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:        AppColors.unsecured.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:       Border.all(
                            color: AppColors.unsecured.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color:    AppColors.unsecured,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  SizedBox(
                    width:  double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: connecting ? null : onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: haColor,
                        foregroundColor: context.tText,
                        disabledBackgroundColor:
                            haColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: connecting
                          ? const SizedBox(
                              width:  18,
                              height: 18,
                              child:  CircularProgressIndicator(
                                color:       Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              s.importFromHa,
                              style: const TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Small text field used inside the HA form
class _HaField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool small;
  final TextInputType? keyboardType;

  const _HaField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.small   = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   ctrl,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        color:    context.tText,
        fontSize: small ? 11 : 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:    context.tText2(0.45),
          fontSize: 11,
        ),
        hintText:  hint,
        hintStyle: TextStyle(
          color:    context.tText2(0.2),
          fontSize: small ? 10 : 12,
        ),
        prefixIcon: Icon(icon,
            color: context.tText2(0.35), size: 16),
        filled:        true,
        fillColor:     context.tText2(0.05),
        border:        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.networkColor.withValues(alpha: 0.5)),
        ),
        isDense:       true,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Device row card
// ─────────────────────────────────────────────────────────────
class _DeviceRow extends StatelessWidget {
  final DiscoveredDevice device;
  final Color    color;
  final IconData icon;
  final String   protocol;
  final VoidCallback? onAdd;

  const _DeviceRow({
    required this.device,
    required this.color,
    required this.icon,
    required this.protocol,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final s     = context.select((AppState st) => st.strings);
    final added = device.isRegistered;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        context.tBg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: added
              ? AppColors.secured.withValues(alpha: 0.3)
              : context.tText2(0.07),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width:  40,
            height: 40,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Name + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: TextStyle(
                    color:      context.tText,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // IP address
                    if (device.ip != null) ...[
                      Text(
                        device.ip!,
                        style: TextStyle(
                          color:    context.tText2(0.35),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width:  3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.tText2(0.2),
                        ),
                      ),
                    ],
                    // Protocol chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:        color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        protocol,
                        style: TextStyle(
                          color:    color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Manufacturer
                    if (device.manufacturer != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        device.manufacturer!,
                        style: TextStyle(
                          color:    context.tText2(0.3),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Add / Added button
          GestureDetector(
            onTap: onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color:        added
                    ? AppColors.secured.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
                border:       Border.all(
                  color: added
                      ? AppColors.secured.withValues(alpha: 0.35)
                      : AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    added ? Symbols.check : Symbols.add,
                    color:  added ? AppColors.secured : AppColors.primary,
                    size:   13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    added ? s.added : s.add,
                    style: TextStyle(
                      color:      added ? AppColors.secured : AppColors.primary,
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty hint — shown before first scan
// ─────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final bool isScanning;
  const _EmptyHint({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScanning ? Symbols.radar : Symbols.wifi_find,
              color: context.tText2(0.15),
              size:  56,
            ),
            const SizedBox(height: 16),
            Text(
              isScanning ? s.scanningDevices : s.scanHint,
              style: TextStyle(
                color:    context.tText2(0.3),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add-all bottom bar
// ─────────────────────────────────────────────────────────────
class _AddAllBar extends StatelessWidget {
  final int          count;
  final VoidCallback onTap;
  const _AddAllBar({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color:  context.tCard,
        border: Border(
          top: BorderSide(color: context.tText2(0.07)),
        ),
      ),
      child: SizedBox(
        width:  double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          icon:  const Icon(Symbols.add_circle, size: 18),
          label: Text(
            s.addAllFmt.replaceAll('{n}', '$count'),
            style: const TextStyle(
              fontSize:   14,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: context.tText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
