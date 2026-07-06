import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// WizSetupScreen — real, end-to-end "add a physical bulb" flow.
//
// Proof of feasibility for the control stack:
//   discover / enter IP  →  blink-test (real UDP)  →  add as a `wiz_<ip>` Device
//   →  toggling it anywhere routes through DeviceCommander → WizController → UDP.
//
// WiZ bulbs speak plain UDP JSON on :38899 with no pairing token, so this is the
// shortest path from "mock" to a genuinely controllable device on the LAN.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../services/lights/wiz_controller.dart';

class WizSetupScreen extends StatefulWidget {
  const WizSetupScreen({super.key});

  @override
  State<WizSetupScreen> createState() => _WizSetupScreenState();
}

class _WizSetupScreenState extends State<WizSetupScreen> {
  static const _kOrange = Color(0xFFFF6B00);

  final _ipCtrl = TextEditingController();
  final _found = <String>[];
  String? _subnet;
  bool _scanning = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _autoScan();
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoScan() async {
    final s = context.read<AppState>().strings;
    setState(() {
      _scanning = true;
      _status = s.wizIdentifyingWifi;
      _found.clear();
    });
    try {
      final ip = await NetworkInfo().getWifiIP();
      if (ip == null || !ip.contains('.')) {
        setState(() => _status = s.wizNoWifi);
        return;
      }
      final prefix = ip.substring(0, ip.lastIndexOf('.'));
      _subnet = prefix;
      setState(() => _status = s.wizBroadcastingFmt.replaceAll('{prefix}', prefix));
      final ips = await WizController.discover(prefix);
      if (!mounted) return;
      setState(() {
        _found
          ..clear()
          ..addAll(ips);
        _status = ips.isEmpty
            ? s.wizNoFound
            : s.wizFoundFmt.replaceAll('{n}', '${ips.length}');
      });
    } catch (_) {
      if (mounted) setState(() => _status = s.wizScanFailed);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _blink(String ip) async {
    final s = context.read<AppState>().strings;
    setState(() => _status = s.wizBlinkingFmt.replaceAll('{ip}', ip));
    final ok = await WizController.setOnOff(ip, true);
    await Future.delayed(const Duration(milliseconds: 600));
    await WizController.setOnOff(ip, false);
    await Future.delayed(const Duration(milliseconds: 600));
    await WizController.setOnOff(ip, true);
    if (mounted) {
      setState(() => _status = ok
          ? s.wizBlinkSentFmt.replaceAll('{ip}', ip)
          : s.wizNoResponseFmt.replaceAll('{ip}', ip));
    }
  }

  void _add(String ip) {
    final state = context.read<AppState>();
    final device = Device(
      id: 'wiz_$ip',
      name: 'WiZ $ip',
      type: DeviceType.light,
      status: DeviceStatus.online,
      isOn: false,
      attributes: {'ip': ip, 'protocol': 'wiz'},
    );
    state.addDevice(device);
    final s = context.read<AppState>().strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.wizDeviceAddedFmt.replaceAll('{name}', device.name)),
        backgroundColor: AppColors.secured,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    final manualIp = _ipCtrl.text.trim();
    final manualValid = manualIp.split('.').length == 4;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.chevron_right,
                          color: context.tText2(0.7), size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(s.addWizBulb,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status + rescan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_scanning)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange),
                    )
                  else
                    const Icon(Symbols.wifi_tethering, color: _kOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_status,
                        style: TextStyle(color: context.tText2(0.7), fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _scanning ? null : _autoScan,
                    child: Text(s.rescan,
                        style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Discovered list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final ip in _found)
                    _BulbRow(
                      ip: ip,
                      onBlink: () => _blink(ip),
                      onAdd: () => _add(ip),
                    ),

                  const SizedBox(height: 12),
                  // Manual add
                  Text(s.wizManualAdd,
                      style: TextStyle(
                          color: context.tText2(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(color: context.tText),
                          decoration: InputDecoration(
                            hintText: _subnet != null ? '$_subnet.42' : '192.168.1.42',
                            hintStyle: TextStyle(color: context.tText2(0.35)),
                            filled: true,
                            fillColor: context.tCard,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.tText2(0.12)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.tText2(0.12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: manualValid ? () => _blink(manualIp) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.tCard,
                          foregroundColor: _kOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _kOrange)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        child: Text(s.wizTest),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: manualValid ? () => _add(manualIp) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: Text(s.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulbRow extends StatelessWidget {
  final String ip;
  final VoidCallback onBlink;
  final VoidCallback onAdd;
  const _BulbRow({required this.ip, required this.onBlink, required this.onAdd});

  static const _kOrange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Symbols.lightbulb, color: _kOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WiZ Bulb',
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(ip,
                    style: TextStyle(color: context.tText2(0.5), fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onBlink,
            child: Text(s.wizTest,
                style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(s.add),
          ),
        ],
      ),
    );
  }
}
