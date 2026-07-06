import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';
import '../theme/device_icons.dart';
import 'status_indicator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeviceCard — premium device tile.
//
// Slots:
//   • Icon            — device-type glyph, glows in accent color when on/alerted
//   • Favorite        — heart icon, top-right, taps toggleFavorite
//   • Quick Toggle    — Material 3 Switch
//   • Device Name     — truncated to 2 lines
//   • Room            — location pin + room label (hidden when room is empty)
//   • Current Status  — status text driven by DeviceStatus + isOn
//   • Online Indicator— animated StatusDot (green / orange / red / gray)
//   • Battery         — colored icon + level % (hidden when battery is null)
//   • Signal Strength — 4-bar graph (hidden when signal is null)
// ─────────────────────────────────────────────────────────────────────────────
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onToggle,
    this.onTap,
    this.onFavoriteToggle,
  });

  IconData get _icon => DeviceIcons.forDevice(device);

  Color get _accentColor => DeviceIcons.color(device.type);

  Color _cardColor(DeviceStatus status) => switch (status) {
    DeviceStatus.offline => AppColors.statusOffline,
    DeviceStatus.warning => AppColors.statusWarning,
    DeviceStatus.alert   => AppColors.statusAlert,
    DeviceStatus.alarm   => AppColors.statusAlarm,
    DeviceStatus.info    => AppColors.statusInfo,
    DeviceStatus.online  => _accentColor,
  };

  @override
  Widget build(BuildContext context) {
    final s = context.select<AppState, dynamic>((st) => st.strings);

    final status    = device.status;
    final isOffline = status.isOffline;
    final isAlerted = status.isWarning || status.isAlarm;
    final isOn      = device.isOn && !isOffline && !isAlerted;
    final showGlow  = isOn || isAlerted || status.isAlert;
    final color     = _cardColor(status);

    final nameColor = isOffline
        ? AppColors.statusOffline
        : (showGlow ? Colors.white : context.tText2(0.80));

    return _TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: showGlow
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.04),
                  ],
                )
              : LinearGradient(colors: [context.tCard, context.tCard]),
          border: Border.all(
            color: showGlow
                ? color.withValues(alpha: 0.42)
                : context.tBorder,
            width: showGlow ? 1.2 : 1.0,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: Icon · Favorite · Quick Toggle ───────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Device icon — glows when on / alerted
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: showGlow
                        ? color.withValues(alpha: 0.20)
                        : context.tCardAlt,
                    boxShadow: showGlow
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ]
                        : const [],
                  ),
                  child: Icon(
                    _icon,
                    color: showGlow ? color : context.tText2(0.35),
                    size: 20,
                  ),
                ),

                const Spacer(),

                // Favorite button
                GestureDetector(
                  onTap: onFavoriteToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
                    child: Icon(
                      Symbols.favorite,
                      size: 17,
                      fill: device.isFavorite ? 1.0 : 0,
                      color: device.isFavorite
                          ? AppColors.statusAlarm
                          : context.tText2(0.22),
                    ),
                  ),
                ),

                // Quick toggle — disabled for offline / alerted devices
                Transform.scale(
                  scale: 0.80,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: isOn,
                    onChanged: status.isControllable && !isAlerted
                        ? (_) => onToggle()
                        : null,
                    activeThumbColor: color,
                    activeTrackColor: color.withValues(alpha: 0.30),
                    inactiveThumbColor: context.tText2(0.25),
                    inactiveTrackColor: context.tCardAlt,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Device name ───────────────────────────────────────
            Text(
              device.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: nameColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Room ──────────────────────────────────────────────
            if (device.room.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Symbols.location_on,
                    size: 10,
                    color: context.tText2(0.28),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      device.room,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: context.tText2(0.35),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 7),

            // ── Bottom row: Online Indicator · Status · Battery · Signal ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Online indicator dot
                StatusDot(status: status, isActive: isOn, size: 6),
                const SizedBox(width: 4),

                // Current status label
                Expanded(
                  child: Text(
                    switch (status) {
                      DeviceStatus.offline => s.offlineLabel,
                      DeviceStatus.warning => 'Warning',
                      DeviceStatus.alert   => 'Alert',
                      DeviceStatus.alarm   => s.alarmTitle,
                      DeviceStatus.info    => 'Info',
                      DeviceStatus.online  => isOn ? s.deviceOn : s.deviceOff,
                    },
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: switch (status) {
                        DeviceStatus.online => isOn
                            ? color.withValues(alpha: 0.85)
                            : context.tText2(0.35),
                        _ => AppStatusColors.dot(status),
                      },
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Battery (if available)
                if (device.battery != null) ...[
                  const SizedBox(width: 5),
                  _BatteryBadge(level: device.battery!),
                ],

                // Signal strength (if available)
                if (device.signal != null) ...[
                  const SizedBox(width: 5),
                  _SignalBars(signal: device.signal!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BatteryBadge — compact icon + level number.
// Green > 50 | Orange 21–50 | Red ≤ 20
// ─────────────────────────────────────────────────────────────────────────────
class _BatteryBadge extends StatelessWidget {
  final int level;
  const _BatteryBadge({required this.level});

  Color get _color {
    if (level <= 20) return AppColors.statusAlarm;
    if (level <= 50) return AppColors.statusWarning;
    return AppColors.statusOnline;
  }

  IconData get _icon => DeviceIcons.batteryIcon(level);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(_icon, size: 12, color: _color),
        const SizedBox(width: 1),
        Text(
          '$level',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: _color,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SignalBars — 4 ascending bars representing 0–100 signal quality.
// ─────────────────────────────────────────────────────────────────────────────
class _SignalBars extends StatelessWidget {
  final int signal; // 0–100
  const _SignalBars({required this.signal});

  @override
  Widget build(BuildContext context) {
    final activeBars = (signal / 25).ceil().clamp(0, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < activeBars;
        return Container(
          width: 3,
          height: 4.0 + i * 3.0, // 4 | 7 | 10 | 13 px
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: active
                ? context.tText2(0.55)
                : context.tText2(0.13),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TapScale — shrinks card slightly on tap for tactile feedback.
// ─────────────────────────────────────────────────────────────────────────────
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TapScale({required this.child, this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.955).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap?.call();
      },
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
