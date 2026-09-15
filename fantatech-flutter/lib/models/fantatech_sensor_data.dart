// ─────────────────────────────────────────────────────────────────────────────
// FantaTechSensorData — the generic, protocol-independent sensor model that
// FantaTechSensorCard (widgets/fantatech_sensor_card.dart) consumes.
//
// Every protocol/manufacturer integration (Tuya, Zigbee, Matter, MQTT, Home
// Assistant, Wi-Fi, ...) is expected to map its own sensor representation
// into this model before it ever reaches the widget — the widget itself
// never sees a brand-specific shape.
//
// [state] is an already-resolved semantic string (e.g. 'clear',
// 'motion_detected', 'gas_detected', 'open', 'leak_detected') — the widget
// only renders it via FantaTechSensorConfig, it never computes it. This is
// what keeps thresholds (e.g. "what CO2 ppm counts as a warning") entirely
// out of the UI: see [Co2Thresholds] below for where that logic belongs.
// ─────────────────────────────────────────────────────────────────────────────

/// Extensible on purpose — new types are added here with zero changes to
/// FantaTechSensorCard as long as a [FantaTechSensorConfig] entry exists for
/// them (untyped/new types fall back to a generic config automatically).
enum FantaTechSensorType {
  motion,
  gas,
  window,
  waterLeak,
  co2,
  tamper,
  mail,
  // Reserved for future sensor types — the architecture already supports
  // them via the same config-map mechanism, no widget changes needed.
  smoke,
  temperature,
  humidity,
  door,
  vibration,
  light,
  sound,
  airQuality,
  energy,
  flood,
  presence,
}

class FantaTechSensorData {
  final String sensorId;
  final FantaTechSensorType sensorType;
  final String sensorName;
  final String roomName;
  final String state;
  final num? value;
  final String unit;
  final bool isOnline;
  final int? batteryLevel;
  final DateTime? lastUpdated;
  final List<String> capabilities;

  const FantaTechSensorData({
    required this.sensorId,
    required this.sensorType,
    required this.sensorName,
    required this.roomName,
    required this.state,
    this.value,
    this.unit = '',
    this.isOnline = true,
    this.batteryLevel,
    this.lastUpdated,
    this.capabilities = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Co2Thresholds — configurable, NOT hard-coded into the widget. A caller
// (or a future capability-layer mapper) resolves a raw ppm reading into the
// 'normal'/'warning'/'gas_detected'-style state string this model expects,
// using whatever thresholds make sense for the deployment — the widget
// never does this math itself.
// ─────────────────────────────────────────────────────────────────────────────

class Co2Thresholds {
  final num normalMaxPpm;
  final num warningMaxPpm;

  const Co2Thresholds({this.normalMaxPpm = 1000, this.warningMaxPpm = 2000});

  /// 'normal' | 'warning' | 'danger' — a state string a caller can feed
  /// into [FantaTechSensorData.state] for a CO2 sensor.
  String resolveState(num ppm) {
    if (ppm <= normalMaxPpm) return 'normal';
    if (ppm <= warningMaxPpm) return 'warning';
    return 'danger';
  }
}
