import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../smarthome/scan_discovery_screen.dart';

const _kOrange = Color(0xFFFF6B00);
const _kBg     = Color(0xFFF0F2F5);
const _kDark   = Color(0xFF1A1A2E);
const _kGrey   = Color(0xFF8E8E93);

/// One unified search result row.
class _Hit {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Hit(this.icon, this.title, this.subtitle);
}

/// App-wide search over devices, cameras and rooms.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(BuildContext ctx, String label) async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      if (mounted) openAppSettings();
      return;
    }
    final ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
    bool popped = false;

    final result = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SizedBox(
        height: 360,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _kDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child: const Icon(Symbols.close, color: _kGrey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: ctrl,
                  onDetect: (capture) {
                    if (popped) return;
                    final code = capture.barcodes.firstOrNull?.rawValue ?? '';
                    if (code.isNotEmpty) {
                      popped = true;
                      Navigator.pop(sheetCtx, code);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    await ctrl.stop();
    ctrl.dispose();
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _q = result;
        _ctrl.text = result;
      });
    }
  }

  List<_Hit> _results(AppState state) {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final s = state.strings;
    final hits = <_Hit>[];

    for (final r in state.rooms) {
      final raw = r['name'] as String? ?? '';
      final name = s.translateRoomKey(raw);
      if (name.toLowerCase().contains(q)) {
        hits.add(_Hit(Symbols.meeting_room, name, s.roomsHeader));
      }
    }
    // Products only — cameras are searched from the Cameras action instead.
    for (final d in state.devices) {
      if (d.type == DeviceType.camera) continue;
      if (d.name.toLowerCase().contains(q)) {
        hits.add(_Hit(_iconFor(d.type), d.name, s.translateRoomKey(d.room)));
      }
    }
    return hits;
  }

  IconData _iconFor(DeviceType t) => switch (t) {
        DeviceType.light          => Symbols.lightbulb,
        DeviceType.airConditioner => Symbols.ac_unit,
        DeviceType.blind          => Symbols.blinds,
        DeviceType.camera         => Symbols.videocam,
        DeviceType.waterHeater    => Symbols.water_drop,
        DeviceType.smartPlug      => Symbols.power,
        DeviceType.motionSensor   => Symbols.sensors,
        DeviceType.doorSensor     => Symbols.sensor_door,
        DeviceType.smartTv        => Symbols.tv,
        DeviceType.smartLock      => Symbols.lock,
        DeviceType.gateway        => Symbols.router,
        _                         => Symbols.devices_other,
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final hits = _results(state);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Symbols.arrow_back, color: _kDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _kOrange, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Symbols.search, color: _kOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              onChanged: (v) => setState(() => _q = v),
                              style: const TextStyle(color: _kDark, fontSize: 15),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: s.searchHint,
                                hintStyle: const TextStyle(color: _kGrey, fontSize: 14),
                              ),
                            ),
                          ),
                          if (_q.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() {
                                _q = '';
                                _ctrl.clear();
                              }),
                              child: const Icon(Symbols.close, color: _kGrey, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Scan for new products (switches, sensors… not cameras) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const ScanDiscoveryScreen(excludeCameras: true)),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kOrange, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.wifi_find, color: _kOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(state.strings.searchScanProducts,
                          style: const TextStyle(
                              color: _kOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            // ── Barcode / QR scan ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () => _scanBarcode(context, state.strings.scanBarcode),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.55), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.qr_code_scanner, color: _kOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(state.strings.scanBarcode,
                          style: const TextStyle(
                              color: _kOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            // ── Results ─────────────────────────────────────────────
            Expanded(
              child: hits.isEmpty
                  ? Center(
                      child: Text(
                        _q.isEmpty ? s.searchHint : '—',
                        style: const TextStyle(color: _kGrey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: hits.length,
                      itemBuilder: (_, i) {
                        final h = hits[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _kOrange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(h.icon, color: _kOrange, size: 21),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h.title,
                                        style: const TextStyle(
                                            color: _kDark,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                    Text(h.subtitle,
                                        style: const TextStyle(color: _kGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
