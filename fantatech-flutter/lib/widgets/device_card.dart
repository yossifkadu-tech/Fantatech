import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../models/device_capabilities.dart';
import '../services/control/device_commander.dart';
import '../theme/app_theme.dart';
import '../theme/device_icons.dart';
import 'device_edit_sheet.dart';
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

  /// Shows a capability-driven quick control (brightness slider / temp
  /// stepper / cover buttons) directly on the card. Off by default because
  /// several callers place [DeviceCard] in a fixed-aspect-ratio grid tile
  /// that has no room for the extra content — only turn this on in a
  /// full-width, height-unconstrained list.
  final bool showInlineControl;

  /// Long-press opens the shared rename/delete sheet. Set false only when
  /// the caller already provides its own edit affordance for this card.
  final bool enableEditSheet;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onToggle,
    this.onTap,
    this.onFavoriteToggle,
    this.showInlineControl = false,
    this.enableEditSheet = true,
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
      onLongPress: enableEditSheet
          ? () => showDeviceEditSheet(context,
              device: device, state: context.read<AppState>())
          : null,
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

                // Quick toggle — locked for offline / alerted devices. A
                // locked switch used to just silently ignore taps, which is
                // indistinguishable from "the app is broken" — now tapping
                // it while offline explains why nothing happened instead.
                Transform.scale(
                  scale: 0.80,
                  alignment: Alignment.centerRight,
                  child: (status.isControllable && !isAlerted)
                      ? Switch(
                          value: isOn,
                          onChanged: (_) => onToggle(),
                          activeThumbColor: color,
                          activeTrackColor: color.withValues(alpha: 0.30),
                          inactiveThumbColor: context.tText2(0.25),
                          inactiveTrackColor: context.tCardAlt,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: isOffline
                              ? () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(s.deviceOfflineHint as String),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  )
                              : null,
                          child: IgnorePointer(
                            child: Switch(
                              value: isOn,
                              onChanged: (_) {},
                              activeThumbColor: color,
                              activeTrackColor: color.withValues(alpha: 0.30),
                              inactiveThumbColor: context.tText2(0.25),
                              inactiveTrackColor: context.tCardAlt,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
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

            // ── Inline quick control — capability-driven, no tap needed ──
            if (showInlineControl)
              _InlineQuickControl(device: device, accent: color, enabled: isOn),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InlineQuickControl — renders the single most relevant control for a
// device directly on its card (brightness slider / temperature stepper /
// open-stop-close), driven by DeviceCapabilities so it adapts to whatever
// the device actually reports instead of a hardcoded per-type list.
// ─────────────────────────────────────────────────────────────────────────────
class _InlineQuickControl extends StatelessWidget {
  final Device device;
  final Color accent;
  final bool enabled;

  const _InlineQuickControl({
    required this.device,
    required this.accent,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final caps = DeviceCapabilities.of(device);

    if (caps.contains(DeviceCapability.climateControl)) {
      return _TempStepper(device: device, accent: accent, enabled: enabled);
    }
    if (caps.contains(DeviceCapability.position)) {
      return _CoverButtons(device: device, accent: accent);
    }
    if (caps.contains(DeviceCapability.vacuumControl)) {
      return _VacuumButtons(device: device, accent: accent);
    }
    if (caps.contains(DeviceCapability.brightness)) {
      return _BrightnessSlider(device: device, accent: accent, enabled: enabled);
    }
    return const SizedBox.shrink();
  }
}

class _BrightnessSlider extends StatefulWidget {
  final Device device;
  final Color accent;
  final bool enabled;
  const _BrightnessSlider({
    required this.device,
    required this.accent,
    required this.enabled,
  });

  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<_BrightnessSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final stored = (widget.device.attributes['brightness'] as num?)?.toInt() ?? 80;
    final value = _dragValue ?? stored.toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.35,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value.clamp(0, 100),
            min: 0,
            max: 100,
            activeColor: widget.accent,
            inactiveColor: widget.accent.withValues(alpha: 0.15),
            onChanged: widget.enabled
                ? (v) => setState(() => _dragValue = v)
                : null,
            onChangeEnd: widget.enabled
                ? (v) {
                    context
                        .read<AppState>()
                        .setDeviceAttribute(widget.device.id, 'brightness', v.toInt());
                    setState(() => _dragValue = null);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _TempStepper extends StatelessWidget {
  final Device device;
  final Color accent;
  final bool enabled;
  const _TempStepper({
    required this.device,
    required this.accent,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final temp = (device.attributes['temperature'] as num?)?.toInt() ?? 22;

    void step(int delta) {
      final next = (temp + delta).clamp(16, 30);
      context.read<AppState>().setDeviceAttribute(device.id, 'temperature', next);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StepperButton(
              icon: Symbols.remove,
              color: accent,
              onTap: enabled ? () => step(-1) : null,
            ),
            Text(
              '$temp°C',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.tText2(0.85),
              ),
            ),
            _StepperButton(
              icon: Symbols.add,
              color: accent,
              onTap: enabled ? () => step(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _CoverButtons extends StatelessWidget {
  final Device device;
  final Color accent;
  const _CoverButtons({required this.device, required this.accent});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StepperButton(
            icon: Symbols.expand_less,
            color: accent,
            onTap: () {
              state.toggleDevice(device.id);
              state.setCoverPosition(device.id, 100);
            },
          ),
          _StepperButton(
            icon: Symbols.stop,
            color: accent,
            onTap: () => state.stopCover(device.id),
          ),
          _StepperButton(
            icon: Symbols.expand_more,
            color: accent,
            onTap: () {
              state.toggleDevice(device.id);
              state.setCoverPosition(device.id, 0);
            },
          ),
        ],
      ),
    );
  }
}

class _VacuumButtons extends StatelessWidget {
  final Device device;
  final Color accent;
  const _VacuumButtons({required this.device, required this.accent});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StepperButton(
            icon: Symbols.play_arrow,
            color: accent,
            onTap: () => state.vacuumCommand(device.id, VacuumAction.start),
          ),
          _StepperButton(
            icon: Symbols.pause,
            color: accent,
            onTap: () => state.vacuumCommand(device.id, VacuumAction.pause),
          ),
          _StepperButton(
            icon: Symbols.home_pin,
            color: accent,
            onTap: () => state.vacuumCommand(device.id, VacuumAction.dock),
          ),
        ],
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
  final VoidCallback? onLongPress;
  const _TapScale({required this.child, this.onTap, this.onLongPress});

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
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
