import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FantaTechSwitchCard — compact, premium, Apple-Home-inspired switch card for
// a 2-per-row mobile dashboard grid. Deliberately separate from
// widgets/smart_switch_card.dart (SmartSwitchCard), which is a larger,
// full-width single-device detail card used in the devices sheet/detail
// screen — different use case, different proportions, not a replacement.
//
// Pure UI: this widget knows nothing about Tuya/Zigbee/Matter or any
// gateway/protocol. It receives a fully generic device description and a
// single [onToggle] callback that returns a Future<bool> (true once the
// backend actually confirmed the new state) — the widget awaits that future
// to drive its own loading/disabled state, and never claims success on its
// own. Communication logic (DeviceCommander/sendDeviceCommand/gateway) lives
// entirely in whatever the caller passes as [onToggle].
// ─────────────────────────────────────────────────────────────────────────────

class FantaTechSwitchCard extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String roomName;
  final bool isOn;
  final bool isOnline;
  final String deviceType;
  final List<String> capabilities;
  final String protocol;

  /// Icon shown inside the circle — lets a plug/switch/heater read as
  /// visually distinct at a glance in a grid, instead of every card
  /// carrying the same generic power glyph.
  final IconData icon;

  /// Called with (deviceId, desiredState) on tap. Must resolve to true only
  /// once the backend confirmed the change — the card awaits this future
  /// for its loading state and never assumes success while it's pending.
  final Future<bool> Function(String deviceId, bool desiredState) onToggle;

  const FantaTechSwitchCard({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.roomName,
    required this.isOn,
    required this.isOnline,
    required this.onToggle,
    this.deviceType = '',
    this.capabilities = const [],
    this.protocol = '',
    this.icon = Symbols.power_settings_new,
  });

  @override
  State<FantaTechSwitchCard> createState() => _FantaTechSwitchCardState();
}

class _FantaTechSwitchCardState extends State<FantaTechSwitchCard> {
  bool _loading = false;
  bool _pressed = false;

  static const _onGlow = Color(0x40FF7A00); // AppColors.primary @ 25%
  static const _offGray = Color(0xFFE5E5EA);
  static const _offIconGray = Color(0xFF8E8E93);

  // Per user request: reversed LED meaning — the orange/glow treatment
  // shows when the device is OFF, gray shows when it's ON.
  bool get _ledActive => !widget.isOn;

  Future<void> _handleTap() async {
    if (_loading || !widget.isOnline) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await widget.onToggle(widget.deviceId, !widget.isOn);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.isOnline;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 170.0;
        final buttonSize = (width * 0.46).clamp(64.0, 88.0);

        return Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.deviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (widget.roomName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.roomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E8E93)),
                  ),
                ],
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  enabled: !disabled && !_loading,
                  label: '${widget.deviceName} ${widget.isOn ? 'on' : 'off'}',
                  child: GestureDetector(
                    onTap: _handleTap,
                    onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
                    onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
                    onTapCancel: disabled ? null : () => setState(() => _pressed = false),
                    child: AnimatedScale(
                      scale: _pressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Per user request: LED color meaning reversed —
                          // orange = OFF, gray = ON (opposite of the usual
                          // "orange = active" convention).
                          color: _ledActive ? AppColors.primary : _offGray,
                          border: _ledActive
                              ? null
                              : Border.all(color: Colors.black.withValues(alpha: 0.06)),
                          boxShadow: _ledActive
                              ? const [
                                  BoxShadow(
                                    color: _onGlow,
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _loading
                              ? SizedBox(
                                  width: buttonSize * 0.3,
                                  height: buttonSize * 0.3,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: _ledActive ? Colors.white : _offIconGray,
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      disabled ? Symbols.wifi_off : widget.icon,
                                      size: buttonSize * 0.34,
                                      color: _ledActive ? Colors.white : _offIconGray,
                                    ),
                                    SizedBox(height: buttonSize * 0.05),
                                    Text(
                                      // Label still reflects the real on/off
                                      // state — only the LED color meaning
                                      // is reversed, not what "ON"/"OFF" says.
                                      disabled ? 'Offline' : (widget.isOn ? 'ON' : 'OFF'),
                                      style: TextStyle(
                                        fontSize: buttonSize * 0.13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: _ledActive ? Colors.white : _offIconGray,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
