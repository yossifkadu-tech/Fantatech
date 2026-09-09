import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../widgets/device_edit_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SwitchDetailScreen — single-device control page opened by tapping a
// registered switch card in SmartSwitchHubScreen. Looks the device up by id
// on every build (rather than holding a Device reference) so it stays live
// through toggles coming from anywhere — manual tap, a schedule, or an
// automation — and pops gracefully if the device gets deleted while open.
// ─────────────────────────────────────────────────────────────────────────────
class SwitchDetailScreen extends StatelessWidget {
  final String deviceId;
  const SwitchDetailScreen({super.key, required this.deviceId});

  static const _onGradient = [Color(0xFFFFC266), Color(0xFFFF7A00)];
  static const _onGlow = Color(0xFFFF7A00);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    Device? device;
    for (final d in state.devices) {
      if (d.id == deviceId) {
        device = d;
        break;
      }
    }

    if (device == null) {
      // Deleted (e.g. from the edit sheet) while this screen was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return Scaffold(backgroundColor: context.tBg);
    }

    final on = device.isOn;
    final accent = DeviceIcons.color(device.type);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.tText2(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Symbols.arrow_back_ios_new,
                          color: context.tText2(0.6), size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(DeviceIcons.forDevice(device), color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name,
                            style: TextStyle(
                                color: context.tText,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        if (device.room.isNotEmpty)
                          Text(s.translateRoomKey(device.room),
                              style: TextStyle(color: context.tText2(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showDeviceEditSheet(context, device: device!, state: state),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.tText2(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Symbols.more_horiz, color: context.tText2(0.6), size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Big toggle ───────────────────────────────────────────
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    state.toggleDevice(device!.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: on
                            ? _onGradient
                            : [context.tText2(0.10), context.tText2(0.05)],
                      ),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                color: _onGlow.withValues(alpha: 0.45),
                                blurRadius: 60,
                                spreadRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.power_settings_new,
                              color: on ? Colors.white : context.tText2(0.35), size: 56),
                          const SizedBox(height: 8),
                          Text(
                            (on ? s.deviceOn : s.deviceOff).toUpperCase(),
                            style: TextStyle(
                              color: on ? Colors.white : context.tText2(0.4),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Status line ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                '${device.name} — ${on ? s.deviceOn : s.deviceOff}',
                style: TextStyle(
                  color: on ? _onGlow : context.tText2(0.45),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
