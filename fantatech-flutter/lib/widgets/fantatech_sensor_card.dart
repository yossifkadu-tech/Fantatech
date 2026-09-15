import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/fantatech_sensor_data.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FantaTechSensorCard — same visual family as FantaTechSwitchCard
// (widgets/fantatech_switch_card.dart): white card, ~170x185dp, 22dp radius,
// subtle shadow, ~80dp central circle. This is a read-only status card, not
// a control — tapping opens the sensor's detail screen via [onTap], nothing
// inside the compact card performs an action.
//
// Config-based architecture: [_configFor] maps FantaTechSensorType → a
// [_SensorTypeConfig] (icon, Hebrew state labels, state → visual category).
// Adding a new sensor type (SMOKE, TEMPERATURE, ...) means adding ONE entry
// to that map — this widget's build() never branches on sensor type by
// name, so nothing here needs to change.
// ─────────────────────────────────────────────────────────────────────────────

enum _StateCategory { idle, activeOrange, warningOrange, activeRed, offline }

class _SensorTypeConfig {
  final IconData icon;
  final Map<String, String> stateLabels;
  final Map<String, _StateCategory> stateCategories;
  final Set<String> pulseStates;
  final bool showsNumericValue;

  const _SensorTypeConfig({
    required this.icon,
    required this.stateLabels,
    required this.stateCategories,
    this.pulseStates = const {},
    this.showsNumericValue = false,
  });

  String labelFor(String state) => stateLabels[state] ?? state;

  _StateCategory categoryFor(String state) =>
      stateCategories[state] ?? _StateCategory.idle;
}

const _kSensorConfigs = <FantaTechSensorType, _SensorTypeConfig>{
  FantaTechSensorType.motion: _SensorTypeConfig(
    icon: Symbols.sensors,
    stateLabels: {'clear': 'אין תנועה', 'motion_detected': 'תנועה זוהתה'},
    stateCategories: {
      'clear': _StateCategory.idle,
      'motion_detected': _StateCategory.activeOrange,
    },
    pulseStates: {'motion_detected'},
  ),
  FantaTechSensorType.gas: _SensorTypeConfig(
    icon: Symbols.propane,
    stateLabels: {'normal': 'תקין', 'warning': 'אזהרה', 'gas_detected': 'זוהה גז'},
    stateCategories: {
      'normal': _StateCategory.idle,
      'warning': _StateCategory.warningOrange,
      'gas_detected': _StateCategory.activeRed,
    },
    pulseStates: {'gas_detected'},
  ),
  FantaTechSensorType.window: _SensorTypeConfig(
    icon: Symbols.window,
    stateLabels: {'closed': 'סגור', 'open': 'פתוח'},
    stateCategories: {
      'closed': _StateCategory.idle,
      'open': _StateCategory.activeOrange,
    },
  ),
  FantaTechSensorType.waterLeak: _SensorTypeConfig(
    icon: Symbols.water_drop,
    stateLabels: {'dry': 'יבש', 'leak_detected': 'נזילה זוהתה'},
    stateCategories: {
      'dry': _StateCategory.idle,
      'leak_detected': _StateCategory.activeRed,
    },
    pulseStates: {'leak_detected'},
  ),
  FantaTechSensorType.co2: _SensorTypeConfig(
    icon: Symbols.co2,
    // Labels/categories here are for whatever state string the caller
    // resolved via Co2Thresholds.resolveState() — the widget never computes
    // ppm thresholds itself.
    stateLabels: {'normal': 'תקין', 'warning': 'אזהרה', 'danger': 'מסוכן'},
    stateCategories: {
      'normal': _StateCategory.idle,
      'warning': _StateCategory.warningOrange,
      'danger': _StateCategory.activeRed,
    },
    pulseStates: {'danger'},
    showsNumericValue: true,
  ),
  FantaTechSensorType.tamper: _SensorTypeConfig(
    icon: Symbols.security,
    stateLabels: {'normal': 'תקין', 'tamper_detected': 'מניפולציה זוהתה'},
    stateCategories: {
      'normal': _StateCategory.idle,
      'tamper_detected': _StateCategory.activeRed,
    },
    pulseStates: {'tamper_detected'},
  ),
  FantaTechSensorType.mail: _SensorTypeConfig(
    icon: Symbols.mail,
    stateLabels: {'no_mail': 'אין דואר', 'mail_present': 'יש דואר'},
    stateCategories: {
      'no_mail': _StateCategory.idle,
      'mail_present': _StateCategory.activeOrange,
    },
  ),
};

/// Generic fallback used for any [FantaTechSensorType] not yet given a real
/// entry above (SMOKE, TEMPERATURE, HUMIDITY, ...) — lets those types be
/// used today without a widget change; a real config can replace this
/// per-type later with zero risk to already-configured sensors.
const _kDefaultConfig = _SensorTypeConfig(
  icon: Symbols.sensors,
  stateLabels: {'normal': 'תקין', 'active': 'פעיל'},
  stateCategories: {
    'normal': _StateCategory.idle,
    'active': _StateCategory.activeOrange,
  },
);

_SensorTypeConfig _configFor(FantaTechSensorType type) =>
    _kSensorConfigs[type] ?? _kDefaultConfig;

class FantaTechSensorCard extends StatefulWidget {
  final FantaTechSensorData data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FantaTechSensorCard({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<FantaTechSensorCard> createState() => _FantaTechSensorCardState();
}

class _FantaTechSensorCardState extends State<FantaTechSensorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  static const _warningColor = Color(0xFFFF9F0A);
  static const _dangerColor = Color(0xFFFF3B30);
  static const _idleGray = Color(0xFFE5E5EA);
  static const _idleIconGray = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _syncPulse();
  }

  @override
  void didUpdateWidget(FantaTechSensorCard old) {
    super.didUpdateWidget(old);
    if (old.data.state != widget.data.state ||
        old.data.isOnline != widget.data.isOnline) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    final config = _configFor(widget.data.sensorType);
    final shouldPulse =
        widget.data.isOnline && config.pulseStates.contains(widget.data.state);
    if (shouldPulse) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, List<BoxShadow> glow}) _visualsFor(_StateCategory cat) {
    switch (cat) {
      case _StateCategory.offline:
        return (bg: _idleGray, fg: _idleIconGray, glow: const []);
      case _StateCategory.idle:
        return (
          bg: _idleGray,
          fg: _idleIconGray,
          glow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        );
      case _StateCategory.activeOrange:
        return (
          bg: AppColors.primary,
          fg: Colors.white,
          glow: const [
            BoxShadow(
                color: Color(0x40FF7A00), blurRadius: 18, spreadRadius: 1),
          ],
        );
      case _StateCategory.warningOrange:
        return (
          bg: _warningColor,
          fg: Colors.white,
          glow: const [
            BoxShadow(
                color: Color(0x40FF9F0A), blurRadius: 14, spreadRadius: 1),
          ],
        );
      case _StateCategory.activeRed:
        return (
          bg: _dangerColor,
          fg: Colors.white,
          glow: const [
            BoxShadow(
                color: Color(0x50FF3B30), blurRadius: 20, spreadRadius: 2),
          ],
        );
    }
  }

  String _relativeLastUpdated(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שע׳';
    return 'לפני ${diff.inDays} ימים';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final config = _configFor(data.sensorType);
    final offline = !data.isOnline;
    final category =
        offline ? _StateCategory.offline : config.categoryFor(data.state);
    final visuals = _visualsFor(category);
    final label = offline ? 'לא מחובר' : config.labelFor(data.state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 170.0;
        final circleSize = (width * 0.46).clamp(64.0, 88.0);

        final semanticParts = [
          data.sensorName,
          if (data.roomName.isNotEmpty) data.roomName,
          offline ? 'לא מחובר' : 'מחובר',
          label,
          if (data.value != null) '${data.value} ${data.unit}',
        ];

        return Semantics(
          label: semanticParts.join(', '),
          button: widget.onTap != null,
          child: GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Opacity(
              opacity: offline ? 0.55 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  children: [
                    Text(
                      data.sensorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E)),
                    ),
                    if (data.roomName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E8E93)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) => Transform.scale(
                        scale: 1.0 + (_pulse.value - 1.0) * _pulseCtrl.value,
                        child: child,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: visuals.bg,
                          border: category == _StateCategory.idle ||
                                  category == _StateCategory.offline
                              ? Border.all(color: Colors.black.withValues(alpha: 0.06))
                              : null,
                          boxShadow: visuals.glow,
                        ),
                        child: Center(
                          child: config.showsNumericValue && data.value != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${data.value}',
                                      style: TextStyle(
                                        fontSize: circleSize * 0.26,
                                        fontWeight: FontWeight.w800,
                                        color: visuals.fg,
                                      ),
                                    ),
                                    if (data.unit.isNotEmpty)
                                      Text(
                                        data.unit,
                                        style: TextStyle(
                                          fontSize: circleSize * 0.13,
                                          fontWeight: FontWeight.w600,
                                          color: visuals.fg.withValues(alpha: 0.85),
                                        ),
                                      ),
                                  ],
                                )
                              : Icon(
                                  offline ? Symbols.wifi_off : config.icon,
                                  size: circleSize * 0.38,
                                  color: visuals.fg,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: switch (category) {
                          _StateCategory.activeRed => _dangerColor,
                          _StateCategory.warningOrange => _warningColor,
                          _StateCategory.activeOrange => AppColors.primary,
                          _StateCategory.idle => const Color(0xFF48484A),
                          _StateCategory.offline => _idleIconGray,
                        },
                      ),
                    ),
                    if (offline && data.lastUpdated != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'עדכון אחרון: ${_relativeLastUpdated(data.lastUpdated!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
