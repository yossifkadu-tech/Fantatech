import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../widgets/device_edit_sheet.dart';
import '../../widgets/smart_switch_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SwitchDetailScreen — single-device control page opened by tapping a
// registered switch card in SmartSwitchHubScreen. Looks the device up by id
// on every build (rather than holding a Device reference) so it stays live
// through toggles coming from anywhere — manual tap, a schedule, or an
// automation — and pops gracefully if the device gets deleted while open.
// ─────────────────────────────────────────────────────────────────────────────
const _switchOnGradient = [Color(0xFFFFC266), Color(0xFFFF7A00)];
const _switchOnGlow = Color(0xFFFF7A00);

class SwitchDetailScreen extends StatelessWidget {
  final String deviceId;
  const SwitchDetailScreen({super.key, required this.deviceId});

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

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar (back / edit only — the card below carries the
            // name, room, and connection status) ───────────────────────
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
                  const Spacer(),
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

            // ── Switch card ────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SmartSwitchCard(
                    deviceName: device.name,
                    roomName: device.room.isEmpty ? '' : s.translateRoomKey(device.room),
                    isOn: device.isOn,
                    isConnected: device.online,
                    icon: DeviceIcons.forDevice(device),
                    onChanged: (_) => state.toggleDevice(device!.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SwitchGlowToggle — the circular gradient/glow on-off button, reused at full
// size on [SwitchDetailScreen] and at a smaller size on each switch card in
// SmartSwitchHubScreen's list.
// ─────────────────────────────────────────────────────────────────────────────
class SwitchGlowToggle extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;
  final double size;

  const SwitchGlowToggle({
    super.key,
    required this.on,
    required this.label,
    required this.onTap,
    this.size = 220,
  });

  // Below this diameter the "ON"/"OFF" text becomes too small to read, so
  // it's dropped and the icon alone (scaled up a bit to compensate) carries
  // the state — the status text next to the toggle already says the rest.
  static const _labelMinSize = 90.0;

  @override
  Widget build(BuildContext context) {
    final showLabel = size >= _labelMinSize;
    final iconSize = size * (showLabel ? 0.25 : 0.4);
    final labelSize = size * 0.09;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: on
                ? _switchOnGradient
                : [context.tText2(0.10), context.tText2(0.05)],
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: _switchOnGlow.withValues(alpha: 0.45),
                    blurRadius: size * 0.27,
                    spreadRadius: size * 0.036,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.power_settings_new,
                  color: on ? Colors.white : context.tText2(0.35), size: iconSize),
              if (showLabel) ...[
                SizedBox(height: size * 0.036),
                Text(
                  label,
                  style: TextStyle(
                    color: on ? Colors.white : context.tText2(0.4),
                    fontSize: labelSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
