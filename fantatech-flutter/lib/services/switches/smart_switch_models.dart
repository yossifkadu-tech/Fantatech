// ─────────────────────────────────────────────────────────────────────────────
// SmartSwitch Models
// Unified data layer for every smart-switch protocol in the app.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ── Protocol enum ─────────────────────────────────────────────────────────────

enum SwitchProtocol {
  shellyGen1,   // Shelly 1/1PM/2.5/EM  — REST /relay/N
  shellyGen2,   // Shelly Plus/Pro       — RPC  /rpc/Switch.*
  shellyGen3,   // Shelly Gen3           — same RPC as Gen2
  sonoffLan,    // Sonoff DIY v2         — POST /zeroconf/switch  port 8081
  tuyaLocal,    // Tuya LAN API          — TCP 6668 (encrypted, detect-only)
  kasaLocal,    // TP-Link Kasa old-gen  — TCP 9999 XOR cipher
  tapoLocal,    // TP-Link Tapo new-gen  — HTTPS RSA (detect + show info)
  esphome,      // ESPHome REST          — POST /switch/<id>/turn_on|off
  haRest,       // Home Assistant REST   — POST /api/services/switch/turn_on
  z2mMqtt,      // Zigbee2MQTT MQTT      — publish zigbee2mqtt/<name>/set
  unknown,
}

extension SwitchProtocolX on SwitchProtocol {
  String get displayName => switch (this) {
        SwitchProtocol.shellyGen1 => 'Shelly Gen1',
        SwitchProtocol.shellyGen2 => 'Shelly Gen2',
        SwitchProtocol.shellyGen3 => 'Shelly Gen3',
        SwitchProtocol.sonoffLan  => 'Sonoff LAN',
        SwitchProtocol.tuyaLocal  => 'Tuya Local',
        SwitchProtocol.kasaLocal  => 'Kasa',
        SwitchProtocol.tapoLocal  => 'Tapo',
        SwitchProtocol.esphome    => 'ESPHome',
        SwitchProtocol.haRest     => 'Home Assistant',
        SwitchProtocol.z2mMqtt    => 'Zigbee2MQTT',
        SwitchProtocol.unknown    => 'Unknown',
      };

  String get brand => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3 =>
          'Shelly',
        SwitchProtocol.sonoffLan  => 'Sonoff',
        SwitchProtocol.tuyaLocal  => 'Tuya',
        SwitchProtocol.kasaLocal ||
        SwitchProtocol.tapoLocal  =>
          'TP-Link',
        SwitchProtocol.esphome    => 'ESPHome',
        SwitchProtocol.haRest     => 'Home Assistant',
        SwitchProtocol.z2mMqtt    => 'Zigbee',
        SwitchProtocol.unknown    => 'Unknown',
      };

  Color get color => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3 =>
          const Color(0xFF00B4D8),
        SwitchProtocol.sonoffLan  => const Color(0xFFFF6B00),
        SwitchProtocol.tuyaLocal  => const Color(0xFF00C896),
        SwitchProtocol.kasaLocal ||
        SwitchProtocol.tapoLocal  =>
          const Color(0xFF00A86B),
        SwitchProtocol.esphome    => const Color(0xFF4895EF),
        SwitchProtocol.haRest     => const Color(0xFF18BFFF),
        SwitchProtocol.z2mMqtt    => const Color(0xFFBA68C8),
        SwitchProtocol.unknown    => Colors.white38,
      };

  IconData get icon => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3 =>
          Icons.power_settings_new_rounded,
        SwitchProtocol.sonoffLan  => Icons.toggle_on_outlined,
        SwitchProtocol.tuyaLocal  => Icons.electrical_services_outlined,
        SwitchProtocol.kasaLocal ||
        SwitchProtocol.tapoLocal  =>
          Icons.outlet_outlined,
        SwitchProtocol.esphome    => Icons.memory_outlined,
        SwitchProtocol.haRest     => Icons.home_outlined,
        SwitchProtocol.z2mMqtt    => Icons.hub_outlined,
        SwitchProtocol.unknown    => Icons.device_unknown_outlined,
      };

  /// True when the app can attempt to toggle this device.
  /// Tuya: needs Local Key — handled in UI (shows key dialog if missing).
  bool get canControl => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3 ||
        SwitchProtocol.sonoffLan  ||
        SwitchProtocol.kasaLocal  ||
        SwitchProtocol.esphome    ||
        SwitchProtocol.haRest     ||
        SwitchProtocol.z2mMqtt    ||
        SwitchProtocol.tuyaLocal  ||   // Tuya:  key dialog in UI
        SwitchProtocol.tapoLocal  =>   // Tapo:  credentials dialog in UI
          true,
        _ => false,
      };
}

// ── Per-relay channel ─────────────────────────────────────────────────────────

class SwitchChannel {
  final int index;
  String name;
  bool isOn;
  double? powerWatts; // live wattage (energy-monitor devices)
  double? energyKwh;  // cumulative kWh

  SwitchChannel({
    required this.index,
    required this.name,
    required this.isOn,
    this.powerWatts,
    this.energyKwh,
  });

  SwitchChannel copyWith({bool? isOn, double? powerWatts}) => SwitchChannel(
        index: index,
        name: name,
        isOn: isOn ?? this.isOn,
        powerWatts: powerWatts ?? this.powerWatts,
        energyKwh: energyKwh,
      );
}

// ── Unified smart-switch device ───────────────────────────────────────────────

class SmartSwitchDevice {
  final String id;
  String name;
  final String? ip;
  final SwitchProtocol protocol;
  final String? model;
  final String? mac;
  final String? firmwareVersion;
  bool isOnline;
  bool isRegistered; // user added to their home
  List<SwitchChannel> channels;

  /// Protocol-specific extras:
  ///   Shelly:   nothing extra
  ///   Sonoff:   'deviceId'
  ///   ESPHome:  'entityId' per channel
  ///   HA:       'haIp', 'haToken', 'entityId'
  ///   Z2M:      'mqttHost', 'mqttPort', 'mqttUser', 'mqttPass', 'deviceName'
  ///   Kasa:     nothing (XOR protocol needs no stored key)
  ///   Tuya/Tapo: 'localKey' (optional, user-supplied later)
  Map<String, dynamic> connectionData;

  final DateTime discoveredAt;

  SmartSwitchDevice({
    required this.id,
    required this.name,
    this.ip,
    required this.protocol,
    this.model,
    this.mac,
    this.firmwareVersion,
    this.isOnline = true,
    this.isRegistered = false,
    required this.channels,
    this.connectionData = const {},
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get brand => protocol.brand;

  bool get hasPowerMonitor => channels.any((c) => c.powerWatts != null);

  double get totalPowerWatts =>
      channels.fold(0.0, (s, c) => s + (c.powerWatts ?? 0.0));
}

// ── Per-protocol scan progress ────────────────────────────────────────────────

enum ProtocolScanStatus { idle, scanning, done, error }

class ProtocolScanState {
  final SwitchProtocol protocol;
  ProtocolScanStatus status;
  int found;
  double progress; // 0..1 (only meaningful during wifi scan)
  String message;

  ProtocolScanState({
    required this.protocol,
    this.status   = ProtocolScanStatus.idle,
    this.found    = 0,
    this.progress = 0,
    this.message  = '',
  });
}
