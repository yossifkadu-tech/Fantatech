import 'package:material_symbols_icons/symbols.dart';
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
  merossLan,    // Meross LAN            — HTTP POST /config + MD5 sign
  broadlinkIr,  // Broadlink IR Blaster  — UDP AES-128-CBC
  goveeLan,     // Govee LAN             — UDP port 4003 JSON
  yeelightLan,  // Yeelight LAN          — TCP 55443 JSON-RPC
  wizLan,       // WiZ LAN               — UDP port 38899 JSON
  lifxCloud,    // LIFX Cloud API        — HTTPS api.lifx.com
  nanoleaf,     // Nanoleaf REST         — HTTP port 16021
  aqaraHub,     // Aqara Hub M2/E1       — HTTP local API
  unknown,
}

extension SwitchProtocolX on SwitchProtocol {
  String get displayName => switch (this) {
        SwitchProtocol.shellyGen1  => 'Shelly Gen1',
        SwitchProtocol.shellyGen2  => 'Shelly Gen2',
        SwitchProtocol.shellyGen3  => 'Shelly Gen3',
        SwitchProtocol.sonoffLan   => 'Sonoff LAN',
        SwitchProtocol.tuyaLocal   => 'Tuya Local',
        SwitchProtocol.kasaLocal   => 'Kasa',
        SwitchProtocol.tapoLocal   => 'Tapo',
        SwitchProtocol.esphome     => 'ESPHome',
        SwitchProtocol.haRest      => 'Home Assistant',
        SwitchProtocol.z2mMqtt     => 'Zigbee2MQTT',
        SwitchProtocol.merossLan   => 'Meross LAN',
        SwitchProtocol.broadlinkIr => 'Broadlink IR',
        SwitchProtocol.goveeLan    => 'Govee LAN',
        SwitchProtocol.yeelightLan => 'Yeelight',
        SwitchProtocol.wizLan      => 'WiZ',
        SwitchProtocol.lifxCloud   => 'LIFX Cloud',
        SwitchProtocol.nanoleaf    => 'Nanoleaf',
        SwitchProtocol.aqaraHub    => 'Aqara Hub',
        SwitchProtocol.unknown     => 'Unknown',
      };

  String get brand => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3  => 'Shelly',
        SwitchProtocol.sonoffLan   => 'Sonoff',
        SwitchProtocol.tuyaLocal   => 'Tuya',
        SwitchProtocol.kasaLocal ||
        SwitchProtocol.tapoLocal   => 'TP-Link',
        SwitchProtocol.esphome     => 'ESPHome',
        SwitchProtocol.haRest      => 'Home Assistant',
        SwitchProtocol.z2mMqtt     => 'Zigbee',
        SwitchProtocol.merossLan   => 'Meross',
        SwitchProtocol.broadlinkIr => 'Broadlink',
        SwitchProtocol.goveeLan    => 'Govee',
        SwitchProtocol.yeelightLan => 'Yeelight',
        SwitchProtocol.wizLan      => 'WiZ',
        SwitchProtocol.lifxCloud   => 'LIFX',
        SwitchProtocol.nanoleaf    => 'Nanoleaf',
        SwitchProtocol.aqaraHub    => 'Aqara',
        SwitchProtocol.unknown     => 'Unknown',
      };

  Color get color => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3  => const Color(0xFF00B4D8),
        SwitchProtocol.sonoffLan   => const Color(0xFFFF6B00),
        SwitchProtocol.tuyaLocal   => const Color(0xFF00C896),
        SwitchProtocol.kasaLocal ||
        SwitchProtocol.tapoLocal   => const Color(0xFF00A86B),
        SwitchProtocol.esphome     => const Color(0xFF4895EF),
        SwitchProtocol.haRest      => const Color(0xFF18BFFF),
        SwitchProtocol.z2mMqtt     => const Color(0xFFBA68C8),
        SwitchProtocol.merossLan   => const Color(0xFF00BFA5),
        SwitchProtocol.broadlinkIr => const Color(0xFFFF5722),
        SwitchProtocol.goveeLan    => const Color(0xFF9C27B0),
        SwitchProtocol.yeelightLan => const Color(0xFFFFB300),
        SwitchProtocol.wizLan      => const Color(0xFF2196F3),
        SwitchProtocol.lifxCloud   => const Color(0xFFE91E63),
        SwitchProtocol.nanoleaf    => const Color(0xFF4CAF50),
        SwitchProtocol.aqaraHub    => const Color(0xFF3F51B5),
        SwitchProtocol.unknown     => Colors.white38,
      };

  IconData get icon => switch (this) {
        SwitchProtocol.shellyGen1 ||
        SwitchProtocol.shellyGen2 ||
        SwitchProtocol.shellyGen3  => Symbols.power_settings_new,
        SwitchProtocol.sonoffLan   => Symbols.toggle_on,
        SwitchProtocol.tuyaLocal   => Symbols.electrical_services,
        SwitchProtocol.kasaLocal ||
        SwitchProtocol.tapoLocal   => Symbols.outlet,
        SwitchProtocol.esphome     => Symbols.memory,
        SwitchProtocol.haRest      => Symbols.home,
        SwitchProtocol.z2mMqtt     => Symbols.hub,
        SwitchProtocol.merossLan   => Symbols.power,
        SwitchProtocol.broadlinkIr => Symbols.settings_remote,
        SwitchProtocol.goveeLan    => Symbols.lightbulb,
        SwitchProtocol.yeelightLan => Symbols.wb_incandescent,
        SwitchProtocol.wizLan      => Symbols.flare,
        SwitchProtocol.lifxCloud   => Symbols.wb_iridescent,
        SwitchProtocol.nanoleaf    => Symbols.hexagon,
        SwitchProtocol.aqaraHub    => Symbols.device_hub,
        SwitchProtocol.unknown     => Symbols.device_unknown,
      };

  /// True when the app can attempt to toggle this device.
  /// Tuya: needs Local Key — handled in UI (shows key dialog if missing).
  bool get canControl => switch (this) {
        SwitchProtocol.shellyGen1  ||
        SwitchProtocol.shellyGen2  ||
        SwitchProtocol.shellyGen3  ||
        SwitchProtocol.sonoffLan   ||
        SwitchProtocol.kasaLocal   ||
        SwitchProtocol.esphome     ||
        SwitchProtocol.haRest      ||
        SwitchProtocol.z2mMqtt     ||
        SwitchProtocol.tuyaLocal   ||   // Tuya:  key dialog in UI
        SwitchProtocol.tapoLocal   ||   // Tapo:  credentials dialog in UI
        SwitchProtocol.merossLan   ||
        SwitchProtocol.broadlinkIr ||
        SwitchProtocol.goveeLan    ||
        SwitchProtocol.yeelightLan ||
        SwitchProtocol.wizLan      ||
        SwitchProtocol.lifxCloud   ||   // LIFX:  token needed
        SwitchProtocol.nanoleaf    ||   // Nanoleaf: token needed
        SwitchProtocol.aqaraHub    =>   // Aqara: access token needed
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
