// ─────────────────────────────────────────────────────────────────────────────
// SmartSwitchHubScreen
//
// Full-screen multi-protocol smart-switch manager.
// Discovers and controls: Shelly Gen1/2/3 · Sonoff LAN · ESPHome ·
//   TP-Link Kasa · TP-Link Tapo · Tuya · Home Assistant · Zigbee2MQTT
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/discovery/ha_client.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_types.dart';
import '../../services/switches/smart_switch_models.dart';
import '../../services/switches/switch_controller.dart';
import '../../services/switches/switch_scan_engine.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────

class SmartSwitchHubScreen extends StatelessWidget {
  const SmartSwitchHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SwitchScanEngine(),
      child: const _SmartSwitchHubView(),
    );
  }
}

class _SmartSwitchHubView extends StatefulWidget {
  const _SmartSwitchHubView();

  @override
  State<_SmartSwitchHubView> createState() => _SmartSwitchHubViewState();
}

class _SmartSwitchHubViewState extends State<_SmartSwitchHubView> {
  String? _filter; // null = All

  @override
  void initState() {
    super.initState();
    // Auto-start scan after the engine is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  // ── Start scan ─────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    if (!mounted) return;
    final engine = context.read<SwitchScanEngine>();

    // Load HA credentials (saved from HA gateway)
    final haIp    = await HaClient.savedIp();
    final haToken = await HaClient.savedToken();

    // Load MQTT credentials from GatewayManager
    String? mqttHost;
    int    mqttPort = 1883;
    String? mqttUser;
    String? mqttPass;

    if (mounted) {
      final gm = context.read<GatewayManager>();
      final mqttConn = gm.connections.where((c) =>
          (c.type == GatewayType.mqtt ||
              c.type == GatewayType.zigbee2mqtt) &&
          c.isConnected).firstOrNull;
      if (mqttConn != null) {
        mqttHost = mqttConn.credentials['host'] ?? mqttConn.ip;
        mqttPort = int.tryParse(mqttConn.credentials['port'] ?? '1883') ?? 1883;
        mqttUser = mqttConn.credentials['username'];
        mqttPass = mqttConn.credentials['password'];
      }
    }

    if (!mounted) return;
    engine.startScan(
      haIp:      haIp,
      haToken:   haToken,
      mqttHost:  mqttHost,
      mqttPort:  mqttPort,
      mqttUser:  mqttUser,
      mqttPass:  mqttPass,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SwitchScanEngine>();
    final theme  = Theme.of(context);

    // Build filtered list
    final allDevices  = engine.devices;
    final filtered    = _filter == null
        ? allDevices
        : allDevices
            .where((d) => d.protocol.brand == _filter)
            .toList();

    // Build brand filter options
    final brands = allDevices
        .map((d) => d.protocol.brand)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            _Header(
              isScanning: engine.isScanning,
              foundCount: allDevices.length,
              onScan:     engine.isScanning ? null : _startScan,
            ),

            // ── Protocol progress row ─────────────────────────────────────────
            if (engine.isScanning || allDevices.isNotEmpty)
              _ProtocolProgressBar(engine: engine),

            // ── Brand filter chips ────────────────────────────────────────────
            if (brands.length > 1)
              _FilterChips(
                brands:   brands,
                selected: _filter,
                onSelect: (b) => setState(
                    () => _filter = _filter == b ? null : b),
              ),

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      isScanning: engine.isScanning,
                      onScan:     _startScan)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _SwitchCard(
                            device: filtered[i],
                            onAdded: () => setState(() {}),
                          ),
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
  final int  foundCount;
  final VoidCallback? onScan;

  const _Header({
    required this.isScanning,
    required this.foundCount,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.tText2(0.7), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('מפסקים חכמים',
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(
                  isScanning
                      ? 'סורק את כל הפרוטוקולים…'
                      : foundCount == 0
                          ? 'לא נמצאו מכשירים'
                          : '$foundCount מכשירים נמצאו',
                  style: TextStyle(
                      color: context.tText2(0.54), fontSize: 12),
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
              icon: Icon(Icons.radar_rounded, size: 16),
              label: Text('סרוק', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6)),
            ),
        ],
      ),
    );
  }
}

// ── Protocol progress row ─────────────────────────────────────────────────────

class _ProtocolProgressBar extends StatelessWidget {
  final SwitchScanEngine engine;
  const _ProtocolProgressBar({required this.engine});

  static const _show = [
    SwitchProtocol.shellyGen1,
    SwitchProtocol.sonoffLan,
    SwitchProtocol.esphome,
    SwitchProtocol.kasaLocal,
    SwitchProtocol.tuyaLocal,
    SwitchProtocol.tapoLocal,
    SwitchProtocol.haRest,
    SwitchProtocol.z2mMqtt,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: _show.map((p) {
          final st = engine.protocolStates[p];
          if (st == null) return const SizedBox.shrink();
          return _ProtocolChip(state: st);
        }).toList(),
      ),
    );
  }
}

class _ProtocolChip extends StatelessWidget {
  final ProtocolScanState state;
  const _ProtocolChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final p     = state.protocol;
    final color = p.color;
    final scanning = state.status == ProtocolScanStatus.scanning;
    final done     = state.status == ProtocolScanStatus.done;
    final error    = state.status == ProtocolScanStatus.error;
    final hasFound = state.found > 0;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasFound
            ? color.withValues(alpha: 0.15)
            : context.tText2(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: hasFound
                ? color.withValues(alpha: 0.45)
                : context.tText2(0.10),
            width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scanning)
            SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: color),
            )
          else if (error)
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 11)
          else
            Icon(p.icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(p.brand,
              style: TextStyle(
                  color: hasFound ? color : context.tText2(0.38),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          if (hasFound) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${state.found}',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final List<String> brands;
  final String?      selected;
  final void Function(String) onSelect;

  const _FilterChips({
    required this.brands,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FilterChip(
            label: 'הכל',
            active: selected == null,
            color: AppColors.primary,
            onTap: () => onSelect(''),
          ),
          ...brands.map((b) {
            final proto = SwitchProtocol.values
                .firstWhere((p) => p.brand == b,
                    orElse: () => SwitchProtocol.unknown);
            return _FilterChip(
              label: b,
              active: selected == b,
              color: proto.color,
              onTap: () => onSelect(b),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String    label;
  final bool      active;
  final Color     color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.55)
                  : context.tText2(0.15),
              width: 1.2),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? color : context.tText2(0.54),
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

// ── Switch card ───────────────────────────────────────────────────────────────

class _SwitchCard extends StatefulWidget {
  final SmartSwitchDevice device;
  final VoidCallback onAdded;

  const _SwitchCard({required this.device, required this.onAdded});

  @override
  State<_SwitchCard> createState() => _SwitchCardState();
}

class _SwitchCardState extends State<_SwitchCard> {
  final Set<int> _toggling = {};

  SmartSwitchDevice get dev => widget.device;
  Color get brandColor => dev.protocol.color;

  Future<void> _toggle(int channelIdx) async {
    // Tuya — needs Local Key first
    if (dev.protocol == SwitchProtocol.tuyaLocal) {
      final hasKey =
          (dev.connectionData['localKey'] as String?)?.isNotEmpty == true;
      if (!hasKey) { _showTuyaKeyDialog(); return; }
    }

    // Tapo — needs TP-Link account credentials first
    if (dev.protocol == SwitchProtocol.tapoLocal) {
      final hasCreds =
          (dev.connectionData['tapoEmail'] as String?)?.isNotEmpty == true;
      if (!hasCreds) { _showTapoCredentialsDialog(); return; }
    }

    if (!dev.protocol.canControl) return;
    if (_toggling.contains(channelIdx)) return;

    setState(() => _toggling.add(channelIdx));

    final ok = await SwitchController.toggle(dev, channelIdx);

    if (mounted) {
      if (ok) {
        final ch = dev.channels[channelIdx];
        setState(() {
          dev.channels[channelIdx] = ch.copyWith(isOn: !ch.isOn);
          _toggling.remove(channelIdx);
        });
      } else {
        setState(() => _toggling.remove(channelIdx));
        _showError();
      }
    }
  }

  void _addToHome() {
    final appState = context.read<AppState>();

    for (int i = 0; i < dev.channels.length; i++) {
      final ch = dev.channels[i];
      final deviceName = dev.channels.length == 1
          ? dev.name
          : '${dev.name} — ${ch.name}';

      appState.addDevice(Device(
        id:   '${dev.id}_ch$i',
        name: deviceName,
        type: DeviceType.smartSwitch,
        isOn: ch.isOn,
        status: DeviceStatus.online,
        attributes: {
          'ip':       dev.ip ?? '',
          'brand':    dev.brand,
          'model':    dev.model ?? '',
          'protocol': dev.protocol.name,
          'channel':  i.toString(),
          if (dev.mac != null) 'mac': dev.mac!,
          ...dev.connectionData,
        },
      ));
    }

    setState(() => dev.isRegistered = true);
    widget.onAdded();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✓ ${dev.name} נוסף לבית'),
      backgroundColor: AppColors.secured,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Tuya Local Key dialog ─────────────────────────────────────────────────

  void _showTuyaKeyDialog() {
    final keyCtrl   = TextEditingController(
        text: dev.connectionData['localKey'] as String? ?? '');
    final devIdCtrl = TextEditingController(
        text: dev.connectionData['devId'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.electrical_services_outlined,
                color: SwitchProtocol.tuyaLocal.color, size: 20),
            const SizedBox(width: 10),
            Text('Tuya Local Key',
                style: TextStyle(
                    color: context.tText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'קבל את הפרטים מ-platform.tuya.com\n'
              '(Cloud → Devices → Device Details)',
              style: TextStyle(color: context.tText2(0.54), fontSize: 12),
            ),
            const SizedBox(height: 16),
            // Device ID field
            _TuyaField(
              controller: devIdCtrl,
              label: 'Device ID',
              hint: 'bfa123abc456def789...',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 10),
            // Local Key field
            _TuyaField(
              controller: keyCtrl,
              label: 'Local Key',
              hint: 'abc123def456...',
              icon: Icons.key_outlined,
              isKey: true,
            ),
            const SizedBox(height: 8),
            Text(
              'המפתח נשמר רק במכשיר שלך.',
              style: TextStyle(
                  color: context.tText2(0.3), fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ביטול',
                style: TextStyle(color: context.tText2(0.38))),
          ),
          ElevatedButton(
            onPressed: () {
              final key   = keyCtrl.text.trim();
              final devId = devIdCtrl.text.trim();
              if (key.isNotEmpty && devId.isNotEmpty) {
                setState(() {
                  dev.connectionData = {
                    ...dev.connectionData,
                    'localKey': key,
                    'devId':    devId,
                  };
                });
                Navigator.pop(ctx);
                // Re-attempt toggle now that key is set
                _toggle(0);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SwitchProtocol.tuyaLocal.color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('שמור ושלוט',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Tapo credentials dialog ───────────────────────────────────────────────

  void _showTapoCredentialsDialog() {
    final emailCtrl = TextEditingController(
        text: dev.connectionData['tapoEmail'] as String? ?? '');
    final passCtrl  = TextEditingController(
        text: dev.connectionData['tapoPassword'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Icon(Icons.outlet_outlined,
              color: SwitchProtocol.tapoLocal.color, size: 20),
          const SizedBox(width: 10),
          Text('Tapo — כניסה',
              style: TextStyle(
                  color: context.tText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'אותם פרטי חשבון שבאפליקציית TP-Link Tapo.',
              style: TextStyle(color: context.tText2(0.54), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _TuyaField(
              controller: emailCtrl,
              label: 'אימייל',
              hint: 'user@example.com',
              icon: Icons.email_outlined,
              color: SwitchProtocol.tapoLocal.color,
            ),
            const SizedBox(height: 10),
            _TuyaField(
              controller: passCtrl,
              label: 'סיסמה',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              color: SwitchProtocol.tapoLocal.color,
              isKey: true,
            ),
            const SizedBox(height: 8),
            Text(
              'הפרטים נשמרים רק במכשיר שלך.',
              style:
                  TextStyle(color: context.tText2(0.3), fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ביטול',
                style: TextStyle(color: context.tText2(0.38))),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              final pass  = passCtrl.text;
              if (email.isNotEmpty && pass.isNotEmpty) {
                setState(() {
                  dev.connectionData = {
                    ...dev.connectionData,
                    'tapoEmail':    email,
                    'tapoPassword': pass,
                  };
                });
                Navigator.pop(ctx);
                _toggle(0); // retry with credentials now set
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SwitchProtocol.tapoLocal.color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('התחבר ושלוט',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('שגיאה בשליטה על ${dev.name}'),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dev.isRegistered
            ? brandColor.withValues(alpha: 0.07)
            : context.tText2(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dev.isRegistered
              ? brandColor.withValues(alpha: 0.35)
              : context.tText2(0.07),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ─────────────────────────────────────────────────
            Row(
              children: [
                // Brand icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(dev.protocol.icon,
                      color: brandColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dev.name,
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(
                        [
                          if (dev.ip != null) dev.ip!,
                          if (dev.model != null) dev.model!,
                        ].join(' · '),
                        style: TextStyle(
                            color: context.tText2(0.54), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Add / registered button
                if (dev.isRegistered)
                  Icon(Icons.check_circle_rounded,
                      color: brandColor, size: 22)
                else
                  GestureDetector(
                    onTap: _addToHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: brandColor.withValues(alpha: 0.40)),
                      ),
                      child: Text('הוסף',
                          style: TextStyle(
                              color: brandColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Tags row ────────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              children: [
                _Tag(dev.protocol.displayName, brandColor),
                if (dev.channels.length > 1)
                  _Tag('${dev.channels.length}ch', context.tText2(0.54)),
                if (dev.hasPowerMonitor)
                  _Tag(
                    '⚡ ${dev.totalPowerWatts.toStringAsFixed(1)} W',
                    Colors.amber,
                  ),
                if (dev.firmwareVersion != null)
                  _Tag('fw ${dev.firmwareVersion}', context.tText2(0.3)),
                // Show setup hint when credentials not yet supplied
                if (dev.protocol == SwitchProtocol.tuyaLocal &&
                    (dev.connectionData['localKey'] as String?)?.isEmpty != false)
                  _Tag('🔑 Tuya key', Colors.orange),
                if (dev.protocol == SwitchProtocol.tapoLocal &&
                    (dev.connectionData['tapoEmail'] as String?)?.isEmpty != false)
                  _Tag('🔑 TP-Link login', Colors.orange),
              ],
            ),

            const SizedBox(height: 12),

            // ── Channel toggles ─────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dev.channels.asMap().entries.map((entry) {
                final i   = entry.key;
                final ch  = entry.value;
                final tog = _toggling.contains(i);

                return _ChannelToggle(
                  channel:    ch,
                  toggling:   tog,
                  canControl: dev.protocol.canControl,
                  color:      brandColor,
                  onTap:      () => _toggle(i),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Channel toggle button ─────────────────────────────────────────────────────

class _ChannelToggle extends StatelessWidget {
  final SwitchChannel channel;
  final bool          toggling;
  final bool          canControl;
  final Color         color;
  final VoidCallback  onTap;

  const _ChannelToggle({
    required this.channel,
    required this.toggling,
    required this.canControl,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = channel.isOn;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isOn
              ? color.withValues(alpha: 0.18)
              : context.tText2(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn
                ? color.withValues(alpha: 0.55)
                : context.tText2(0.12),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (toggling)
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: color),
              )
            else
              Icon(
                isOn
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                color: isOn ? color : context.tText2(0.38),
                size: 18,
              ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(channel.name,
                    style: TextStyle(
                        color: isOn ? context.tText : context.tText2(0.54),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (channel.powerWatts != null)
                  Text(
                    '${channel.powerWatts!.toStringAsFixed(1)} W',
                    style: TextStyle(
                        color: Colors.amber.withValues(alpha: 0.8),
                        fontSize: 10),
                  )
                else
                  Text(
                    isOn ? 'פועל' : 'כבוי',
                    style: TextStyle(
                        color: isOn
                            ? color.withValues(alpha: 0.8)
                            : context.tText2(0.3),
                        fontSize: 10),
                  ),
              ],
            ),
            if (!canControl) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_outline_rounded,
                  color: Colors.orange.withValues(alpha: 0.6), size: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;
  const _EmptyState({required this.isScanning, required this.onScan});

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            SizedBox(height: 16),
            Text('מחפש מפסקים חכמים בכל הפרוטוקולים…',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: context.tText2(0.15), size: 52),
          const SizedBox(height: 16),
          Text('לא נמצאו מפסקים חכמים',
              style: TextStyle(
                  color: context.tText2(0.38),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'ודא שהמפסקים מחוברים לאותה רשת WiFi.\n'
              'Shelly/ESPHome — ב-STA mode\n'
              'Sonoff — ב-DIY mode (firmware 3.6+)\n'
              'Home Assistant / Zigbee2MQTT — חבר בהגדרות',
              style: TextStyle(color: Colors.white24, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: Icon(Icons.radar_rounded, size: 16),
            label: Text('סרוק שוב'),
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

// ── Tuya Key input field ──────────────────────────────────────────────────────

class _TuyaField extends StatefulWidget {
  final TextEditingController controller;
  final String   label;
  final String   hint;
  final IconData icon;
  final bool     isKey;
  final Color?   color; // accent color; defaults to Tuya color
  const _TuyaField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isKey = false,
    this.color,
  });

  @override
  State<_TuyaField> createState() => _TuyaFieldState();
}

class _TuyaFieldState extends State<_TuyaField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? SwitchProtocol.tuyaLocal.color;
    return TextField(
      controller: widget.controller,
      obscureText: widget.isKey && _obscure,
      style: TextStyle(
          color: context.tText, fontSize: 13, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: context.tText2(0.54), fontSize: 12),
        hintText: widget.hint,
        hintStyle: TextStyle(color: context.tText2(0.24), fontSize: 11),
        prefixIcon: Icon(widget.icon, color: accent, size: 18),
        suffixIcon: widget.isKey
            ? IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: context.tText2(0.38),
                    size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent),
        ),
        filled: true,
        fillColor: context.tText2(0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ── Tag ───────────────────────────────────────────────────────────────────────

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
