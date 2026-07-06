import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Z2M Connect Sheet — quick Zigbee2MQTT gateway connection
// Enter IP (+ optional token) → fetch devices → add to AppState
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../services/gateways/clients/z2m_client.dart';
import '../../theme/app_theme.dart';

class Z2MConnectSheet extends StatefulWidget {
  const Z2MConnectSheet({super.key});

  @override
  State<Z2MConnectSheet> createState() => _Z2MConnectSheetState();
}

class _Z2MConnectSheetState extends State<Z2MConnectSheet> {
  final _ipCtrl    = TextEditingController();
  final _portCtrl  = TextEditingController(text: '8080');
  final _tokenCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _devicesFound = 0;

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final s     = context.read<AppState>().strings;
    final ip    = _ipCtrl.text.trim();
    final port  = int.tryParse(_portCtrl.text.trim()) ?? 8080;
    final token = _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim();

    if (ip.isEmpty) {
      setState(() => _error = s.z2mEnterIp);
      return;
    }

    setState(() { _loading = true; _error = null; });

    // Health check
    final healthy = await Z2MGatewayClient.isHealthy(ip, port, token: token);
    if (!healthy) {
      if (mounted) setState(() {
        _loading = false;
        _error = s.z2mUnreachableFmt
            .replaceAll('{ip}', ip)
            .replaceAll('{port}', '$port');
      });
      return;
    }

    // Fetch devices
    final result = await Z2MGatewayClient.fetchDevices(ip, port, token: token);
    if (!mounted) return;

    if (result.isSuccess) {
      final appState = context.read<AppState>();
      int added = 0;
      for (final device in result.devices) {
        appState.addDevice(device);
        added++;
      }
      setState(() {
        _loading = false;
        _devicesFound = added;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error ?? s.z2mUnknownError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.tText2(0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9D00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Symbols.settings_input_antenna,
                    color: Color(0xFFFF9D00), size: 18),
              ),
              const SizedBox(width: 12),
              Text('Zigbee2MQTT',
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.z2mSubtitle,
              style: TextStyle(
                  color: context.tText2(0.45), fontSize: 12)),
          const SizedBox(height: 20),

          // IP field
          _Field(
            controller: _ipCtrl,
            label: s.z2mIpLabel,
            hint: s.z2mIpHint,
            icon: Symbols.router,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // Port + token row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Field(
                  controller: _portCtrl,
                  label: s.z2mPortLabel,
                  hint: '8080',
                  icon: Symbols.numbers,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _Field(
                  controller: _tokenCtrl,
                  label: s.z2mTokenLabel,
                  hint: s.z2mTokenHint,
                  icon: Symbols.key,
                  obscure: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusAlarm.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusAlarm.withValues(alpha: 0.30)),
              ),
              child: Text(_error!,
                  style: TextStyle(color: AppColors.statusAlarm, fontSize: 12)),
            ),

          // Success
          if (_devicesFound > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secured.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.secured.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Icon(Symbols.check_circle,
                      color: AppColors.secured, size: 18),
                  const SizedBox(width: 8),
                  Text(s.z2mFoundFmt.replaceAll('{n}', '$_devicesFound'),
                      style: TextStyle(
                          color: AppColors.secured, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          // Connect button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : (_devicesFound > 0
                  ? () => Navigator.pop(context)
                  : _connect),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9D00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(
                      _devicesFound > 0 ? s.close : s.z2mConnectImport,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),

          // Help text
          const SizedBox(height: 10),
          Text(
            s.z2mFrontendHelp,
            style: TextStyle(
                color: context.tText2(0.25),
                fontSize: 10,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: context.tText, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
            color: context.tText2(0.45), fontSize: 12),
        hintStyle: TextStyle(
            color: context.tText2(0.25), fontSize: 12),
        prefixIcon: Icon(icon, color: context.tText2(0.38), size: 18),
        filled: true,
        fillColor: context.tText2(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: context.tText2(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: context.tText2(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFFF9D00), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
