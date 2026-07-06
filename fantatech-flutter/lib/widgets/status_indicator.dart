import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StatusDot — animated dot that reflects device status:
//
//   online  (active)  : green, slow pulse  (1 800 ms)
//   alarm             : red,   fast pulse  (  700 ms)
//   warning           : orange, mid pulse  (1 200 ms)
//   offline / online (inactive) : static gray / green dot
// ─────────────────────────────────────────────────────────────────────────────
class StatusDot extends StatefulWidget {
  final DeviceStatus status;

  /// For [DeviceStatus.online]: true = device is switched on (pulses),
  /// false = device is switched off (static dot).
  final bool isActive;

  final double size;

  const StatusDot({
    super.key,
    required this.status,
    this.isActive = false,
    this.size = 7,
  });

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    _anim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _sync();
  }

  @override
  void didUpdateWidget(StatusDot old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status || old.isActive != widget.isActive) {
      _ctrl.duration = _duration;
      _sync();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Duration get _duration => switch (widget.status) {
    DeviceStatus.alarm   => const Duration(milliseconds: 700),
    DeviceStatus.warning => const Duration(milliseconds: 1200),
    DeviceStatus.alert   => const Duration(milliseconds: 1500),
    _                    => const Duration(milliseconds: 1800),
  };

  bool get _shouldPulse =>
      widget.status == DeviceStatus.alarm ||
      widget.status == DeviceStatus.warning ||
      widget.status == DeviceStatus.alert ||
      (widget.status == DeviceStatus.online && widget.isActive);

  void _sync() {
    if (_shouldPulse) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl
        ..stop()
        ..value = 0.6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppStatusColors.dot(widget.status);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final alpha = _shouldPulse ? _anim.value : 0.9;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
            boxShadow: _shouldPulse
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: _anim.value * 0.55),
                      blurRadius: widget.size,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusChip — pill badge: [icon] label
//
// Adapts automatically to light / dark theme.
//
// Example:
//   StatusChip(status: device.status)
//   StatusChip(status: DeviceStatus.alarm, label: 'Leak detected')
//   StatusChip.info(label: 'Firmware update available')
// ─────────────────────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final Color _dotColor;
  final Color _surfaceLight;
  final Color _surfaceDark;
  final IconData _icon;
  final String label;

  const StatusChip._({
    super.key,
    required Color dotColor,
    required Color surfaceLight,
    required Color surfaceDark,
    required IconData icon,
    required this.label,
  })  : _dotColor = dotColor,
        _surfaceLight = surfaceLight,
        _surfaceDark = surfaceDark,
        _icon = icon;

  factory StatusChip({
    Key? key,
    required DeviceStatus status,
    String? label,
  }) {
    return StatusChip._(
      key: key,
      dotColor: AppStatusColors.dot(status),
      surfaceLight: AppStatusColors.surface(status),
      surfaceDark: AppStatusColors.darkSurface(status),
      icon: AppStatusColors.icon(status),
      label: label ?? _defaultLabel(status),
    );
  }

  factory StatusChip.info({Key? key, required String label}) {
    return StatusChip._(
      key: key,
      dotColor: AppColors.statusInfo,
      surfaceLight: AppColors.statusInfoSurface,
      surfaceDark: AppColors.statusInfo.withValues(alpha: 0.14),
      icon: Symbols.info,
      label: label,
    );
  }

  static String _defaultLabel(DeviceStatus s) => switch (s) {
    DeviceStatus.online  => 'Online',
    DeviceStatus.offline => 'Offline',
    DeviceStatus.warning => 'Warning',
    DeviceStatus.alert   => 'Alert',
    DeviceStatus.alarm   => 'Alarm',
    DeviceStatus.info    => 'Info',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _surfaceDark : _surfaceLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _dotColor.withValues(alpha: isDark ? 0.30 : 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _dotColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _dotColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
