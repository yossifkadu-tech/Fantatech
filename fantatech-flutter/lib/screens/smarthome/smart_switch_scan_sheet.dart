import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// SmartSwitchScanSheet
// Bottom-sheet: סריקת רשת למפסקים חכמים — Shelly / Sonoff / Tuya
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/discovery/smart_switch_scanner.dart';
import '../../services/discovery/discovery_models.dart';
import '../../theme/app_theme.dart';

void showSmartSwitchScanSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const SmartSwitchScanSheet(),
  );
}

class SmartSwitchScanSheet extends StatefulWidget {
  const SmartSwitchScanSheet({super.key});

  @override
  State<SmartSwitchScanSheet> createState() => _SmartSwitchScanSheetState();
}

class _SmartSwitchScanSheetState extends State<SmartSwitchScanSheet> {
  bool _scanning = false;
  bool _done     = false;
  double _progress = 0.0;
  final List<DiscoveredSwitch> _found = [];
  final Set<String> _added = {};
  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _done     = false;
      _progress = 0.0;
      _found.clear();
      _added.clear();
    });

    String? localIp;
    try { localIp = await NetworkInfo().getWifiIP(); } catch (_) {}

    if (localIp == null) {
      // fallback
      try {
        final ifaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: false);
        for (final i in ifaces) {
          for (final a in i.addresses) {
            if (!a.isLoopback) { localIp = a.address; break; }
          }
          if (localIp != null) break;
        }
      } catch (_) {}
    }

    if (localIp == null) {
      if (mounted) setState(() { _scanning = false; _done = true; });
      return;
    }

    final prefix = localIp.split('.').take(3).join('.');

    _sub = SmartSwitchScanner.scanSubnet(
      prefix,
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = done / total);
      },
    ).listen(
      (sw) {
        if (mounted) setState(() => _found.add(sw));
      },
      onDone: () {
        if (mounted) setState(() { _scanning = false; _done = true; _progress = 1.0; });
      },
    );
  }

  void _addDevice(BuildContext context, DiscoveredSwitch sw) {
    final appState = context.read<AppState>();

    final device = Device(
      id:     sw.id,
      name:   sw.name,
      type:   _toAppType(sw.deviceType),
      isOn:   false,
      status: DeviceStatus.online,
      attributes: {
        'ip':           sw.ip,
        'brand':        sw.brand.name,
        if (sw.model        != null) 'model':     sw.model!,
        if (sw.mac          != null) 'mac':        sw.mac!,
        if (sw.firmwareVersion != null) 'fw':     sw.firmwareVersion!,
        if (sw.channels     != null) 'channels':  sw.channels!.toString(),
        'hasPowerMeter':  sw.hasPowerMeter.toString(),
        'protocol':      'wifi',
        if (sw.apiBaseUrl   != null) 'apiUrl':    sw.apiBaseUrl!,
      },
    );

    appState.upsertDevice(device);
    setState(() => _added.add(sw.id));

    final s = context.read<AppState>().strings;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.switchAddedFmt.replaceAll('{name}', sw.name)),
      backgroundColor: AppColors.secured,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  DeviceType _toAppType(DiscoveredDeviceType t) => switch (t) {
    DiscoveredDeviceType.socket       => DeviceType.smartPlug,
    DiscoveredDeviceType.energyMeter  => DeviceType.smartPlug,
    DiscoveredDeviceType.thermostat   => DeviceType.airConditioner,
    DiscoveredDeviceType.boiler       => DeviceType.waterHeater,
    DiscoveredDeviceType.motionSensor => DeviceType.motionSensor,
    DiscoveredDeviceType.smokeSensor  => DeviceType.motionSensor,
    _                                 => DeviceType.smartPlug,
  };

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2)),
              )),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  // Brand icons row
                  _BrandChip(brand: SwitchBrand.shelly,  label: 'Shelly',  color: const Color(0xFF00B4D8)),
                  const SizedBox(width: 6),
                  _BrandChip(brand: SwitchBrand.sonoff,  label: 'Sonoff',  color: const Color(0xFFFF6B00)),
                  const SizedBox(width: 6),
                  _BrandChip(brand: SwitchBrand.tuya,    label: 'Tuya',    color: const Color(0xFF00C896)),
                  const Spacer(),
                  if (_done)
                    Text(s.scanFoundFmt.replaceAll('{n}', '${_found.length}'),
                        style: TextStyle(
                            color: context.tText2(0.54), fontSize: 12)),
                ],
              ),
            ),

            // Progress bar
            if (_scanning || _done)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: context.tText2(0.12),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00B4D8)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scanning
                          ? s.switchScanProgressFmt.replaceAll('{n}', '${(_progress * 254).toInt()}')
                          : _found.isEmpty
                              ? s.switchNoDevicesHint
                              : s.scanDoneFmt.replaceAll('{n}', '${_found.length}'),
                      style: TextStyle(
                          color: context.tText2(0.40),
                          fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // Scan button
            if (!_scanning && !_done)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _startScan,
                    icon: Icon(Symbols.radar, size: 18),
                    label: Text(s.scanWifi,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4D8),
                      foregroundColor: context.tText,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),

            if (!_scanning && _done)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: OutlinedButton.icon(
                  onPressed: _startScan,
                  icon: Icon(Symbols.refresh, size: 16),
                  label: Text(s.rescan),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B4D8),
                      side: const BorderSide(color: Color(0xFF00B4D8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),

            // Results list
            Expanded(
              child: _found.isEmpty && _done
                  ? _EmptyState()
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _found.length,
                      itemBuilder: (ctx, i) {
                        final sw = _found[i];
                        final added = _added.contains(sw.id);
                        return _SwitchTile(
                          sw: sw,
                          added: added,
                          onAdd: added ? null : () => _addDevice(ctx, sw),
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

// ── Widgets ───────────────────────────────────────────────────────────────────

class _BrandChip extends StatelessWidget {
  final SwitchBrand brand;
  final String label;
  final Color color;
  const _BrandChip({required this.brand, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final DiscoveredSwitch sw;
  final bool added;
  final VoidCallback? onAdd;
  const _SwitchTile({required this.sw, required this.added, this.onAdd});

  Color get _brandColor => switch (sw.brand) {
    SwitchBrand.shelly  => const Color(0xFF00B4D8),
    SwitchBrand.sonoff  => const Color(0xFFFF6B00),
    SwitchBrand.tuya    => const Color(0xFF00C896),
    SwitchBrand.unknown => Colors.white.withValues(alpha: 0.38),
  };

  IconData get _brandIcon => switch (sw.brand) {
    SwitchBrand.shelly  => Symbols.power_settings_new,
    SwitchBrand.sonoff  => Symbols.toggle_on,
    SwitchBrand.tuya    => Symbols.electrical_services,
    SwitchBrand.unknown => Symbols.device_unknown,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: added
            ? _brandColor.withValues(alpha: 0.08)
            : context.tText2(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: added
              ? _brandColor.withValues(alpha: 0.40)
              : context.tText2(0.07),
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _brandColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(_brandIcon, color: _brandColor, size: 20),
        ),
        title: Text(
          sw.name,
          style: TextStyle(
              color: added ? context.tText : context.tText2(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${sw.ip}${sw.model != null ? " · ${sw.model}" : ""}',
              style: TextStyle(color: context.tText2(0.54), fontSize: 11),
            ),
            Row(
              children: [
                if (sw.hasPowerMeter)
                  _Tag('⚡ Energy', Colors.amber),
                if ((sw.channels ?? 1) > 1)
                  _Tag('${sw.channels}ch', _brandColor),
                if (sw.openPorts.contains(6668))
                  _Tag('LAN API', const Color(0xFF00C896)),
              ],
            ),
          ],
        ),
        trailing: added
            ? Icon(Symbols.check_circle, color: _brandColor, size: 22)
            : TextButton(
                onPressed: onAdd,
                child: Text(context.select((AppState st) => st.strings).add,
                    style: TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.search_off,
              color: context.tText2(0.15), size: 48),
          const SizedBox(height: 12),
          Text(s.switchNoFound,
              style: TextStyle(color: context.tText2(0.38), fontSize: 14)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              s.switchHint,
              style: TextStyle(color: context.tText2(0.24), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
