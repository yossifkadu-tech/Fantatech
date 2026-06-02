// ─────────────────────────────────────────────────────────────────────────────
// Sensor & Cover Models
// Unified data layer for motion sensors, door/window contacts, and smart covers.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SENSORS
// ══════════════════════════════════════════════════════════════════════════════

enum SensorType {
  motion,     // PIR / radar (occupancy)
  contact,    // door / window reed switch
  temperature,
  humidity,
  smoke,
  water,
  vibration,
  button,
  unknown,
}

extension SensorTypeX on SensorType {
  String get displayName => switch (this) {
        SensorType.motion      => 'תנועה',
        SensorType.contact     => 'חלון/דלת',
        SensorType.temperature => 'טמפרטורה',
        SensorType.humidity    => 'לחות',
        SensorType.smoke       => 'עשן',
        SensorType.water       => 'מים',
        SensorType.vibration   => 'רטט',
        SensorType.button      => 'כפתור',
        SensorType.unknown     => 'חיישן',
      };

  IconData get icon => switch (this) {
        SensorType.motion      => Icons.sensors_rounded,
        SensorType.contact     => Icons.door_front_door_outlined,
        SensorType.temperature => Icons.thermostat_outlined,
        SensorType.humidity    => Icons.water_drop_outlined,
        SensorType.smoke       => Icons.local_fire_department_outlined,
        SensorType.water       => Icons.water_damage_outlined,
        SensorType.vibration   => Icons.vibration_rounded,
        SensorType.button      => Icons.radio_button_checked,
        SensorType.unknown     => Icons.device_unknown_outlined,
      };

  Color get color => switch (this) {
        SensorType.motion      => const Color(0xFFFF6B35),
        SensorType.contact     => const Color(0xFF4CAF50),
        SensorType.temperature => const Color(0xFFFF5722),
        SensorType.humidity    => const Color(0xFF2196F3),
        SensorType.smoke       => const Color(0xFF78909C),
        SensorType.water       => const Color(0xFF03A9F4),
        SensorType.vibration   => const Color(0xFF9C27B0),
        SensorType.button      => const Color(0xFFFF9800),
        SensorType.unknown     => Colors.white38,
      };

  /// Label when triggered vs. clear
  String triggeredLabel(bool? v) {
    if (v == null) return '—';
    return switch (this) {
      SensorType.motion  => v ? 'זוהתה תנועה' : 'נקי',
      SensorType.contact => v ? 'פתוח' : 'סגור',
      SensorType.smoke   => v ? 'עשן!' : 'תקין',
      SensorType.water   => v ? 'הצפה!' : 'יבש',
      _                  => v ? 'פעיל' : 'לא פעיל',
    };
  }
}

// ── SensorProtocol ─────────────────────────────────────────────────────────────

enum SensorProtocol {
  shellyGen1,  // Shelly Door/Window 2, Shelly Motion  (REST /status)
  shellyGen2,  // Shelly Plus Motion / DW (RPC)
  esphome,     // binary_sensor.<id>
  haRest,      // binary_sensor.* via HA REST API
  z2mMqtt,     // Zigbee device via Zigbee2MQTT
  unknown,
}

extension SensorProtocolX on SensorProtocol {
  String get displayName => switch (this) {
        SensorProtocol.shellyGen1 => 'Shelly Gen1',
        SensorProtocol.shellyGen2 => 'Shelly Gen2/3',
        SensorProtocol.esphome    => 'ESPHome',
        SensorProtocol.haRest     => 'Home Assistant',
        SensorProtocol.z2mMqtt    => 'Zigbee2MQTT',
        SensorProtocol.unknown    => 'Unknown',
      };

  String get brand => switch (this) {
        SensorProtocol.shellyGen1 ||
        SensorProtocol.shellyGen2 =>
          'Shelly',
        SensorProtocol.esphome    => 'ESPHome',
        SensorProtocol.haRest     => 'Home Assistant',
        SensorProtocol.z2mMqtt    => 'Zigbee',
        SensorProtocol.unknown    => 'Unknown',
      };

  Color get color => switch (this) {
        SensorProtocol.shellyGen1 ||
        SensorProtocol.shellyGen2 =>
          const Color(0xFF00B4D8),
        SensorProtocol.esphome    => const Color(0xFF4895EF),
        SensorProtocol.haRest     => const Color(0xFF18BFFF),
        SensorProtocol.z2mMqtt    => const Color(0xFFBA68C8),
        SensorProtocol.unknown    => Colors.white38,
      };

  IconData get icon => switch (this) {
        SensorProtocol.shellyGen1 ||
        SensorProtocol.shellyGen2 =>
          Icons.sensors_rounded,
        SensorProtocol.esphome    => Icons.memory_outlined,
        SensorProtocol.haRest     => Icons.home_outlined,
        SensorProtocol.z2mMqtt    => Icons.hub_outlined,
        SensorProtocol.unknown    => Icons.device_unknown_outlined,
      };
}

// ── SmartSensor ────────────────────────────────────────────────────────────────

class SmartSensor {
  final String id;
  String name;
  final String? ip;
  final SensorProtocol protocol;
  final SensorType type;

  bool? isTriggered;       // true = motion/open/alarm, false = clear/closed
  int?  batteryPercent;
  double? temperature;
  double? humidity;

  bool isOnline;
  bool isRegistered;
  Map<String, dynamic> connectionData;
  final DateTime discoveredAt;
  DateTime? lastSeen;

  SmartSensor({
    required this.id,
    required this.name,
    this.ip,
    required this.protocol,
    required this.type,
    this.isTriggered,
    this.batteryPercent,
    this.temperature,
    this.humidity,
    this.isOnline = true,
    this.isRegistered = false,
    this.connectionData = const {},
    DateTime? discoveredAt,
    this.lastSeen,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get brand => protocol.brand;
}

// ══════════════════════════════════════════════════════════════════════════════
// COVERS (SHUTTERS / BLINDS)
// ══════════════════════════════════════════════════════════════════════════════

enum CoverProtocol {
  shellyGen1Roller,   // Shelly 2.5 in roller mode   — GET /roller/0?go=open
  shellyGen2Cover,    // Shelly Plus 2PM cover mode   — POST /rpc/Cover.*
  shellyGen3Cover,    // same RPC as Gen2
  esphome,            // POST /cover/<id>/open|close|stop
  haRest,             // POST /api/services/cover/open_cover|…
  z2mMqtt,            // MQTT  zigbee2mqtt/<name>/set  {"state":"OPEN"}
  unknown,
}

extension CoverProtocolX on CoverProtocol {
  String get displayName => switch (this) {
        CoverProtocol.shellyGen1Roller => 'Shelly 2.5 Roller',
        CoverProtocol.shellyGen2Cover  => 'Shelly Plus Cover',
        CoverProtocol.shellyGen3Cover  => 'Shelly Gen3 Cover',
        CoverProtocol.esphome          => 'ESPHome',
        CoverProtocol.haRest           => 'Home Assistant',
        CoverProtocol.z2mMqtt          => 'Zigbee2MQTT',
        CoverProtocol.unknown          => 'Unknown',
      };

  String get brand => switch (this) {
        CoverProtocol.shellyGen1Roller ||
        CoverProtocol.shellyGen2Cover  ||
        CoverProtocol.shellyGen3Cover  =>
          'Shelly',
        CoverProtocol.esphome          => 'ESPHome',
        CoverProtocol.haRest           => 'Home Assistant',
        CoverProtocol.z2mMqtt          => 'Zigbee',
        CoverProtocol.unknown          => 'Unknown',
      };

  Color get color => switch (this) {
        CoverProtocol.shellyGen1Roller ||
        CoverProtocol.shellyGen2Cover  ||
        CoverProtocol.shellyGen3Cover  =>
          const Color(0xFF00B4D8),
        CoverProtocol.esphome          => const Color(0xFF4895EF),
        CoverProtocol.haRest           => const Color(0xFF18BFFF),
        CoverProtocol.z2mMqtt          => const Color(0xFFBA68C8),
        CoverProtocol.unknown          => Colors.white38,
      };

  IconData get icon => switch (this) {
        CoverProtocol.shellyGen1Roller ||
        CoverProtocol.shellyGen2Cover  ||
        CoverProtocol.shellyGen3Cover  =>
          Icons.window_outlined,
        CoverProtocol.esphome          => Icons.memory_outlined,
        CoverProtocol.haRest           => Icons.home_outlined,
        CoverProtocol.z2mMqtt          => Icons.hub_outlined,
        CoverProtocol.unknown          => Icons.device_unknown_outlined,
      };
}

// ── CoverState ────────────────────────────────────────────────────────────────

enum CoverState {
  open,
  closed,
  stopped,
  opening,
  closing,
  unknown;

  String get heLabel => switch (this) {
        CoverState.open    => 'פתוח',
        CoverState.closed  => 'סגור',
        CoverState.stopped => 'עצור',
        CoverState.opening => 'נפתח…',
        CoverState.closing => 'נסגר…',
        CoverState.unknown => '—',
      };

  Color get color => switch (this) {
        CoverState.open    => const Color(0xFF4CAF50),
        CoverState.closed  => const Color(0xFF9E9E9E),
        CoverState.stopped => const Color(0xFFFF9800),
        CoverState.opening => const Color(0xFF81C784),
        CoverState.closing => const Color(0xFFBDBDBD),
        CoverState.unknown => Colors.white38,
      };

  bool get isMoving => this == CoverState.opening || this == CoverState.closing;
}

// ── SmartCover ────────────────────────────────────────────────────────────────

class SmartCover {
  final String id;
  String name;
  final String? ip;
  final CoverProtocol protocol;
  final String? model;

  CoverState state;
  int? position;             // 0 = fully closed, 100 = fully open
  bool hasPositionControl;   // supports GoToPosition

  bool isOnline;
  bool isRegistered;
  Map<String, dynamic> connectionData;
  final DateTime discoveredAt;

  SmartCover({
    required this.id,
    required this.name,
    this.ip,
    required this.protocol,
    this.model,
    this.state = CoverState.unknown,
    this.position,
    this.hasPositionControl = false,
    this.isOnline = true,
    this.isRegistered = false,
    this.connectionData = const {},
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get brand => protocol.brand;
}

// ── Scan progress ─────────────────────────────────────────────────────────────

enum SensorScanStatus { idle, scanning, done, error }

class SensorScanState {
  final String key;          // protocol key for display
  final Color  color;
  final IconData icon;
  SensorScanStatus status;
  int foundSensors;
  int foundCovers;
  String message;

  SensorScanState({
    required this.key,
    required this.color,
    required this.icon,
    this.status       = SensorScanStatus.idle,
    this.foundSensors = 0,
    this.foundCovers  = 0,
    this.message      = '',
  });

  int get found => foundSensors + foundCovers;
}
