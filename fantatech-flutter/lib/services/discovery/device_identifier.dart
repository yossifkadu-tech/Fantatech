// ─────────────────────────────────────────────────────────────────────────────
// Device Identifier
// Final classification pass that enriches DiscoveredDevices with:
//  • DiscoveredDeviceType (light / socket / gateway / boiler / …)
//  • Manufacturer name
//  • Model string
//  • Suggested display name
// Runs after all scanners complete. Uses a scoring system so multiple weak
// signals (name, port, banner, MAC OUI) combine into a confident label.
// ─────────────────────────────────────────────────────────────────────────────

import 'discovery_models.dart';

// ── Rule table ────────────────────────────────────────────────────────────────
class _Rule {
  final DiscoveredDeviceType type;
  final String? manufacturer;
  final String? model;
  final int score;

  // Match conditions — any non-null field that matches adds [score].
  final String? nameContains;
  final List<int> portsAll;    // ALL of these ports must be open
  final List<int> portsAny;   // ANY of these ports must be open
  final String? bannerContains;
  // Note: MAC OUI matching is done externally via _macOuiMap, not per-rule.

  const _Rule({
    required this.type,
    required this.score,
    this.manufacturer,
    this.model,
    this.nameContains,
    this.portsAll = const [],
    this.portsAny = const [],
    this.bannerContains,
  });
}

const _rules = [
  // ── Lights ────────────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.light, score: 10,
      nameContains: 'bulb', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.light, score: 10,
      nameContains: 'lamp', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.light, score: 10,
      nameContains: 'light', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.light, score: 15,
      nameContains: 'hue', manufacturer: 'Philips Hue'),
  _Rule(type: DiscoveredDeviceType.light, score: 12,
      nameContains: 'govee', manufacturer: 'Govee'),
  _Rule(type: DiscoveredDeviceType.light, score: 10,
      nameContains: 'yeelight', manufacturer: 'Xiaomi Yeelight'),
  _Rule(type: DiscoveredDeviceType.light, score: 10,
      nameContains: 'tradfri', manufacturer: 'IKEA'),
  // Yeelight uses port 55443
  _Rule(type: DiscoveredDeviceType.light, score: 8,
      portsAny: [55443], manufacturer: 'Xiaomi Yeelight'),

  // ── Smart sockets ─────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.socket, score: 10,
      nameContains: 'plug', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.socket, score: 10,
      nameContains: 'socket', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.socket, score: 10,
      nameContains: 'outlet', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.socket, score: 12,
      nameContains: 'tapo p', manufacturer: 'TP-Link Tapo'),
  _Rule(type: DiscoveredDeviceType.socket, score: 12,
      nameContains: 'meross', manufacturer: 'Meross'),
  _Rule(type: DiscoveredDeviceType.socket, score: 8,
      portsAll: [6668], manufacturer: 'Tuya',
      bannerContains: 'gwId'),

  // ── Motion sensors ────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 20,
      nameContains: 'shmos', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 20,
      nameContains: 'plusmot', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 20,
      nameContains: 's3motion', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 15,
      nameContains: 'motion'),
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 14,
      nameContains: 'occupancy'),
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 12,
      nameContains: 'pir'),
  _Rule(type: DiscoveredDeviceType.motionSensor, score: 10,
      nameContains: 'תנועה'),

  // ── Door / Window sensors ─────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.windowSensor, score: 20,
      nameContains: 'shdw', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.windowSensor, score: 20,
      nameContains: 'plusdw', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.windowSensor, score: 20,
      nameContains: 'sensordw', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.windowSensor, score: 12,
      nameContains: 'window sensor'),
  _Rule(type: DiscoveredDeviceType.windowSensor, score: 12,
      nameContains: 'contact sensor'),
  _Rule(type: DiscoveredDeviceType.doorSensor, score: 14,
      nameContains: 'door sensor'),
  _Rule(type: DiscoveredDeviceType.doorSensor, score: 12,
      nameContains: 'door contact'),

  // ── Smoke sensors ─────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.smokeSensor, score: 20,
      nameContains: 'shsmoke', manufacturer: 'Shelly'),
  _Rule(type: DiscoveredDeviceType.smokeSensor, score: 15,
      nameContains: 'smoke'),

  // ── Thermostats ───────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.thermostat, score: 10,
      nameContains: 'thermo'),
  // NOTE: 'sensor' alone is too generic — removed to avoid false positives
  _Rule(type: DiscoveredDeviceType.thermostat, score: 8,
      nameContains: 'temp sensor'),
  _Rule(type: DiscoveredDeviceType.thermostat, score: 10,
      nameContains: 'nest', manufacturer: 'Google Nest'),
  _Rule(type: DiscoveredDeviceType.thermostat, score: 10,
      nameContains: 'ecobee', manufacturer: 'Ecobee'),
  _Rule(type: DiscoveredDeviceType.thermostat, score: 10,
      nameContains: 'tado', manufacturer: 'Tado'),

  // ── Cameras ───────────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.camera, score: 10,
      nameContains: 'cam', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.camera, score: 10,
      nameContains: 'ipcam'),
  // RTSP port 554 is a strong camera indicator
  _Rule(type: DiscoveredDeviceType.camera, score: 15,
      portsAny: [554], manufacturer: 'IP Camera'),
  _Rule(type: DiscoveredDeviceType.camera, score: 10,
      nameContains: 'tapo c', manufacturer: 'TP-Link Tapo'),
  _Rule(type: DiscoveredDeviceType.camera, score: 10,
      nameContains: 'reolink', manufacturer: 'Reolink'),
  _Rule(type: DiscoveredDeviceType.camera, score: 10,
      nameContains: 'dahua', manufacturer: 'Dahua'),
  _Rule(type: DiscoveredDeviceType.camera, score: 10,
      nameContains: 'hikvision', manufacturer: 'Hikvision'),

  // ── Gateways / bridges ────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.gateway, score: 15,
      nameContains: 'gateway', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.gateway, score: 15,
      nameContains: 'bridge', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.gateway, score: 12,
      nameContains: 'hub', manufacturer: 'Generic'),
  _Rule(type: DiscoveredDeviceType.gateway, score: 15,
      nameContains: 'sonoff', manufacturer: 'Sonoff'),
  _Rule(type: DiscoveredDeviceType.gateway, score: 15,
      nameContains: 'zigbee2mqtt', manufacturer: 'Zigbee2MQTT'),
  _Rule(type: DiscoveredDeviceType.gateway, score: 12,
      nameContains: 'deconz', manufacturer: 'deCONZ'),
  _Rule(type: DiscoveredDeviceType.gateway, score: 12,
      nameContains: 'home assistant', manufacturer: 'Home Assistant'),
  // MQTT broker port
  _Rule(type: DiscoveredDeviceType.gateway, score: 10,
      portsAny: [1883, 8883]),
  // Zigbee2MQTT frontend default port
  _Rule(type: DiscoveredDeviceType.gateway, score: 12,
      portsAny: [8080], bannerContains: 'zigbee'),
  // Hue Bridge
  _Rule(type: DiscoveredDeviceType.gateway, score: 15,
      bannerContains: 'IpBridge', manufacturer: 'Philips Hue',
      model: 'Hue Bridge'),

  // ── Boiler / water heater ─────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.boiler, score: 12,
      nameContains: 'boiler'),
  _Rule(type: DiscoveredDeviceType.boiler, score: 12,
      nameContains: 'water heater'),
  _Rule(type: DiscoveredDeviceType.boiler, score: 10,
      nameContains: 'thermex'),
  _Rule(type: DiscoveredDeviceType.boiler, score: 10,
      nameContains: 'ariston'),

  // ── Solar ─────────────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.solar, score: 12,
      nameContains: 'solar'),
  _Rule(type: DiscoveredDeviceType.solar, score: 12,
      nameContains: 'inverter'),
  _Rule(type: DiscoveredDeviceType.solar, score: 10,
      nameContains: 'enphase', manufacturer: 'Enphase'),
  _Rule(type: DiscoveredDeviceType.solar, score: 10,
      nameContains: 'solarEdge', manufacturer: 'SolarEdge'),
  _Rule(type: DiscoveredDeviceType.solar, score: 8,
      portsAny: [502], // Modbus TCP — common in solar inverters
      manufacturer: 'Solar Inverter'),

  // ── Routers ───────────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.router, score: 12,
      nameContains: 'router'),
  _Rule(type: DiscoveredDeviceType.router, score: 8,
      nameContains: 'openwrt', manufacturer: 'OpenWRT'),
  _Rule(type: DiscoveredDeviceType.router, score: 8,
      portsAll: [80, 443], bannerContains: 'RouterOS',
      manufacturer: 'MikroTik'),

  // ── Speakers ─────────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.speaker, score: 12,
      nameContains: 'echo', manufacturer: 'Amazon'),
  _Rule(type: DiscoveredDeviceType.speaker, score: 12,
      nameContains: 'chromecast', manufacturer: 'Google'),
  _Rule(type: DiscoveredDeviceType.speaker, score: 10,
      nameContains: 'sonos', manufacturer: 'Sonos'),
  _Rule(type: DiscoveredDeviceType.speaker, score: 8,
      portsAny: [1400], manufacturer: 'Sonos'), // Sonos HTTP API

  // ── TV ────────────────────────────────────────────────────────────────────
  _Rule(type: DiscoveredDeviceType.tv, score: 10,
      nameContains: 'samsung tv', manufacturer: 'Samsung'),
  _Rule(type: DiscoveredDeviceType.tv, score: 10,
      nameContains: 'lg tv', manufacturer: 'LG'),
  _Rule(type: DiscoveredDeviceType.tv, score: 8,
      portsAny: [8001, 8002], manufacturer: 'Samsung TV'),  // Samsung WS
  _Rule(type: DiscoveredDeviceType.tv, score: 8,
      portsAny: [3000], manufacturer: 'LG webOS TV'),
];

// ── MAC OUI database (partial, common smart home vendors) ─────────────────────
const _macOuiMap = {
  'E09880': 'Sonoff / ITEAD',
  '84F703': 'Espressif',
  '8CAAB5': 'Espressif',
  'A8032A': 'Espressif',
  '3C71BF': 'Espressif',
  'ACDF48': 'Tuya',
  '549226': 'TP-Link',
  'B0BE76': 'TP-Link Tapo',
  '6C5AB0': 'Philips Hue',
  '001788': 'Philips Hue',
  '000000': 'IKEA Tradfri',   // placeholder; IKEA uses multiple OUIs
  '60A423': 'Shelly',
  'C45BBE': 'Shelly',
  '803F5D': 'Meross',
  '7811DC': 'Govee',
};

// ── Identifier ────────────────────────────────────────────────────────────────
class DeviceIdentifier {
  /// Enrich a [DiscoveredDevice] with manufacturer, model, and precise type.
  DiscoveredDevice identify(DiscoveredDevice device) {
    final scores = <DiscoveredDeviceType, int>{};
    String? bestManufacturer = device.manufacturer;
    String? bestModel = device.model;

    final nameLower =
        (device.displayName + (device.model ?? '')).toLowerCase();
    final banner =
        (device.metadata['httpBanner'] as String? ?? '').toLowerCase();

    // Check MAC OUI
    String? ouiManufacturer;
    if (device.mac != null) {
      final oui = device.mac!.replaceAll(':', '').replaceAll('-', '')
          .toUpperCase()
          .substring(0, device.mac!.replaceAll(':', '').replaceAll('-', '').length.clamp(0, 6));
      ouiManufacturer = _macOuiMap[oui];
    }

    // Score every rule
    for (final rule in _rules) {
      int ruleScore = 0;

      // Name match
      if (rule.nameContains != null &&
          nameLower.contains(rule.nameContains!.toLowerCase())) {
        ruleScore += rule.score;
      }

      // HTTP banner match
      if (rule.bannerContains != null &&
          banner.contains(rule.bannerContains!.toLowerCase())) {
        ruleScore += rule.score;
      }

      // portsAll: all listed ports must be open
      if (rule.portsAll.isNotEmpty &&
          rule.portsAll.every((p) => device.openPorts.contains(p))) {
        ruleScore += rule.score ~/ 2;
      }

      // portsAny: at least one listed port must be open
      if (rule.portsAny.isNotEmpty &&
          rule.portsAny.any((p) => device.openPorts.contains(p))) {
        ruleScore += rule.score ~/ 2;
      }

      // MAC OUI match
      if (rule.manufacturer != null &&
          ouiManufacturer != null &&
          ouiManufacturer.toLowerCase()
              .contains(rule.manufacturer!.toLowerCase())) {
        ruleScore += rule.score;
      }

      if (ruleScore > 0) {
        scores[rule.type] = (scores[rule.type] ?? 0) + ruleScore;
        if (rule.manufacturer != null && bestManufacturer == null) {
          bestManufacturer = rule.manufacturer;
        }
        if (rule.model != null && bestModel == null) {
          bestModel = rule.model;
        }
      }
    }

    // No rules matched — return unchanged
    if (scores.isEmpty) {
      if (ouiManufacturer != null) {
        return device.copyWith(manufacturer: ouiManufacturer);
      }
      return device;
    }

    // Pick the type with the highest total score
    final bestType =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Apply OUI manufacturer if no rule gave us one
    bestManufacturer ??= ouiManufacturer;

    // Build a better display name if we identified the device
    String displayName = device.displayName;
    if (bestType != DiscoveredDeviceType.unknown) {
      if (bestManufacturer != null && bestModel != null) {
        displayName = '$bestManufacturer $bestModel';
      } else if (bestManufacturer != null &&
          !device.displayName
              .toLowerCase()
              .contains(bestManufacturer.toLowerCase())) {
        displayName = '$bestManufacturer ${device.displayName}';
      }
    }

    return device.copyWith(
      type: bestType,
      manufacturer: bestManufacturer,
      model: bestModel,
      displayName: displayName,
    );
  }

  /// Batch-identify a list of devices.
  List<DiscoveredDevice> identifyAll(List<DiscoveredDevice> devices) =>
      devices.map(identify).toList();
}
