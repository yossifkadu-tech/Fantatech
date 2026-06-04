// ─────────────────────────────────────────────────────────────────────────────
// DeviceClassifier
// Pure static classification — no state, no Flutter dependency.
//
// Three signal sources, in priority order:
//   1. Shelly model code  (most precise — direct from /shelly endpoint)
//   2. OUI prefix         (MAC prefix → manufacturer)
//   3. Ports + banner     (open TCP ports + HTTP body keywords)
//   4. mDNS service type  (service name string)
//   5. HA entity domain   (domain.entity_id + device_class attribute)
// ─────────────────────────────────────────────────────────────────────────────
import 'discovery_models.dart';
import '../../models/device.dart';

class DeviceClassifier {
  // ── OUI Database ────────────────────────────────────────────────────────────
  // Key: 6 uppercase hex chars (no separators). Value: brand display name.
  static const _oui = <String, String>{
    // Espressif — base chip for Sonoff, Shelly, Tuya, ESPHome devices
    '10521C': 'Espressif', '18FE34': 'Espressif', '240AC4': 'Espressif',
    '2CF432': 'Espressif', '3C71BF': 'Espressif', '5CCF7F': 'Espressif',
    '84F703': 'Espressif', 'A020A6': 'Espressif', 'A4CF12': 'Espressif',
    'E89F6D': 'Espressif', 'CC50E3': 'Espressif', '4CEBD6': 'Espressif',
    '48E7DA': 'Espressif', '60019F': 'Espressif', '7C9EBD': 'Espressif',
    // Shelly (Allterco Robotics)
    '3C6105': 'Shelly',    '60A423': 'Shelly',    '84CCA8': 'Shelly',
    'C45BBE': 'Shelly',    'E465B8': 'Shelly',    '34987A': 'Shelly',
    // Sonoff / ITEAD
    'E09880': 'Sonoff',    'A0205A': 'Sonoff',    '680AE2': 'Sonoff',
    '2462AB': 'Sonoff',
    // Tuya (200+ white-label brands)
    'ACDF48': 'Tuya',      '386B1C': 'Tuya',      '6055F9': 'Tuya',
    '7CF666': 'Tuya',      'D4A651': 'Tuya',
    // TP-Link / Tapo
    '14CC20': 'TP-Link',   '1C3BF3': 'TP-Link',   '50C7BF': 'TP-Link',
    '549226': 'TP-Link',   '60A4B7': 'TP-Link',   'F8D111': 'TP-Link',
    '70AF24': 'TP-Link',   '788A20': 'TP-Link',   '90F652': 'TP-Link',
    'B0BE76': 'TP-Link',   'E894F6': 'TP-Link',   'F81A67': 'TP-Link',
    // Xiaomi / Aqara
    'A4C138': 'Xiaomi',    '34CE00': 'Xiaomi',    '4C49E3': 'Xiaomi',
    '58DDFC': 'Xiaomi',    '7CF8F4': 'Xiaomi',    'F0B429': 'Xiaomi',
    '00EC0A': 'Xiaomi',    'B0E235': 'Xiaomi',    'F04F7C': 'Xiaomi',
    // Philips Hue (Signify)
    '001788': 'Philips Hue', '6C5AB0': 'Philips Hue', 'ECB5FA': 'Philips Hue',
    // IKEA
    '000B57': 'IKEA',      '5C02B2': 'IKEA',      '80197B': 'IKEA',
    '90FD9F': 'IKEA',      '04CF8C': 'IKEA',      '30BEFF': 'IKEA',
    // Amazon Echo / Ring
    '44650D': 'Amazon',    '74C246': 'Amazon',    '84D6D0': 'Amazon',
    'F0272D': 'Amazon',    'A002DC': 'Amazon',    '0023CD': 'Amazon',
    // Google Nest / Chromecast
    '1C62B8': 'Google',    '48D6D5': 'Google',    '54207E': 'Google',
    'F88FCA': 'Google',    '94EB2C': 'Google',    '3C5AB4': 'Google',
    // Raspberry Pi — DIY gateways (Home Assistant, Zigbee2MQTT, Node-RED)
    'B827EB': 'Raspberry Pi', 'DCA632': 'Raspberry Pi', 'E45F01': 'Raspberry Pi',
    // Govee
    '7811DC': 'Govee',     'E04CF4': 'Govee',
    // Meross
    '48E1E9': 'Meross',    '803F5D': 'Meross',
    // Broadlink
    '3492F1': 'Broadlink', 'B4430D': 'Broadlink', 'C4EECC': 'Broadlink',
    // Tado (smart thermostat, common in Israel)
    '28FBA7': 'Tado',      '7C70BC': 'Tado',
    // Roborock
    '28D203': 'Roborock',  '9863ED': 'Roborock',
    // Zigbee coordinators
    '00124B': 'Texas Instruments', // CC2531 / CC2652
    '047F0E': 'Silicon Labs',      // ConBee / RaspBee
  };

  /// MAC → manufacturer. Accepts any separator format.
  static String? manufacturerFromMac(String mac) {
    final clean = mac.replaceAll(RegExp(r'[:\-\.\s]'), '').toUpperCase();
    return clean.length >= 6 ? _oui[clean.substring(0, 6)] : null;
  }

  // ── WiFi / LAN classification ────────────────────────────────────────────────

  /// Classify from TCP scan data: open ports, HTTP banner, hostname, manufacturer.
  static DiscoveredDeviceType classifyFromWifi({
    required String name,
    required List<int> openPorts,
    String? banner,
    String? manufacturer,
    String? shellyModel,
  }) {
    // 1. Shelly model code is the most precise signal
    if (shellyModel != null && shellyModel.isNotEmpty) {
      return classifyShellyModel(shellyModel);
    }

    final lower = [
      name.toLowerCase(),
      (banner ?? '').toLowerCase(),
      (manufacturer ?? '').toLowerCase(),
    ].join(' ');

    // 2. Energy meter (check before switch/plug — Shelly EM is an energy meter)
    if (openPorts.contains(502)) return DiscoveredDeviceType.energyMeter; // Modbus
    if (_any(lower, ['shem', 'shelly em', 'energy meter', 'power meter',
                      'kwh meter', 'emp', ' em '])) {
      return DiscoveredDeviceType.energyMeter;
    }

    // 3. Smoke / fire detectors
    if (_any(lower, ['smoke', 'עשן', 'fire alarm', 'shsmoke', 'גלאי עשן'])) {
      return DiscoveredDeviceType.smokeSensor;
    }

    // 4. Boiler / water heater
    if (_any(lower, ['boiler', 'דוד', 'shbduo', 'water heat', 'tado',
                      'tadiran', 'termosmart', 'atlantic'])) {
      return DiscoveredDeviceType.boiler;
    }

    // 5. Sensors
    if (_any(lower, ['water leak', 'leak', 'flood', 'shflood', 'נזיל',
                      'water sensor', 'badring'])) {
      return DiscoveredDeviceType.waterLeak;
    }
    if (_any(lower, ['motion', 'pir', 'תנועה', 'shmos', 'occupancy'])) {
      return DiscoveredDeviceType.motionSensor;
    }
    if (_any(lower, ['window', 'חלון', 'shdw', 'dw-', 'contact'])) {
      return DiscoveredDeviceType.windowSensor;
    }
    if (_any(lower, ['door sensor', 'חיישן דלת', 'door contact'])) {
      return DiscoveredDeviceType.doorSensor;
    }

    // 6. Gateways / hubs
    if (openPorts.contains(8123)) return DiscoveredDeviceType.gateway; // Home Assistant
    if (openPorts.contains(1883)) return DiscoveredDeviceType.gateway; // MQTT broker
    if (openPorts.contains(4343)) return DiscoveredDeviceType.gateway; // deCONZ
    if (_any(lower, ['home assistant', 'homeassistant', 'zigbee2mqtt', 'deconz',
                      'dirigera', 'hue bridge', 'smartthings', 'hubitat',
                      'gateway', 'coordinator', 'zigbee coordinator'])) {
      return DiscoveredDeviceType.gateway;
    }
    if (_any(lower, ['hub']) && !_any(lower, ['github', 'docker'])) {
      return DiscoveredDeviceType.gateway;
    }

    // 7. Smart plug / socket (before switch)
    if (openPorts.contains(6668)) return DiscoveredDeviceType.socket; // Tuya LAN
    if (_any(lower, ['shplg', 'plug', 'socket', 'outlet', 'tapo p', 'שקע',
                      'smart plug', 'pm mini', 'pm1'])) {
      return DiscoveredDeviceType.socket;
    }

    // 8. Smart switch / relay
    if (_any(lower, ['shsw', 'shuni', 'switch', 'relay', 'מתג', 'sonoff',
                      'esphome', 'esp8266', 'esp32', 'ewelink', 'zbminil'])) {
      return DiscoveredDeviceType.smartSwitch;
    }

    // 9. Camera
    if (openPorts.contains(554)) return DiscoveredDeviceType.camera; // RTSP
    if (_any(lower, ['hikvision', 'dahua', 'reolink', 'ipcam', 'nvr', 'dvr',
                      'camera', 'cam-', '-cam'])) {
      return DiscoveredDeviceType.camera;
    }

    // 10. Router
    if (_any(lower, ['router', 'openwrt', 'routeros', 'mikrotik', 'ubiquiti',
                      'unifi', 'asus router', 'tplink router'])) {
      return DiscoveredDeviceType.router;
    }

    // 11. Thermostat
    if (_any(lower, ['therm', 'ecobee', 'nest therm', 'שנאי חום', 'climate'])) {
      return DiscoveredDeviceType.thermostat;
    }

    return DiscoveredDeviceType.unknown;
  }

  // ── Shelly model classification ──────────────────────────────────────────────

  /// Classify a Shelly device by its firmware model code.
  /// Examples: SHSW-1, SHPLG-S, SHEM-3, SHBDUO-1, SHSMOKE-01, SHDW-2
  static DiscoveredDeviceType classifyShellyModel(String model) {
    final m = model.toUpperCase();
    if (m.contains('SHEM'))    return DiscoveredDeviceType.energyMeter;
    if (m.contains('SHPLG'))   return DiscoveredDeviceType.socket;
    if (m.contains('SHBDUO'))  return DiscoveredDeviceType.boiler;
    if (m.contains('SHTRV'))   return DiscoveredDeviceType.thermostat;
    if (m.contains('SHHT'))    return DiscoveredDeviceType.sensor;
    if (m.contains('SHSMOKE')) return DiscoveredDeviceType.smokeSensor;
    if (m.contains('SHDW'))    return DiscoveredDeviceType.windowSensor;
    if (m.contains('SHMOS'))   return DiscoveredDeviceType.motionSensor;
    if (m.contains('SHFLOOD')) return DiscoveredDeviceType.waterLeak;
    if (m.contains('SHSW') || m.contains('SHUNI') || m.contains('SHIX3')) {
      return DiscoveredDeviceType.smartSwitch;
    }
    return DiscoveredDeviceType.smartSwitch; // default Shelly = switch
  }

  // ── mDNS classification ──────────────────────────────────────────────────────

  /// Classify by mDNS service type string (e.g. "_shelly._tcp").
  static DiscoveredDeviceType classifyFromMdns(String serviceType) {
    final s = serviceType.toLowerCase();
    if (s.contains('home-assistant')) return DiscoveredDeviceType.gateway;
    if (s.contains('hue'))            return DiscoveredDeviceType.gateway;
    if (s.contains('dirigera'))       return DiscoveredDeviceType.gateway;
    if (s.contains('ihsp'))           return DiscoveredDeviceType.gateway; // IKEA DIRIGERA
    if (s.contains('hap'))            return DiscoveredDeviceType.gateway;
    if (s.contains('mqtt'))           return DiscoveredDeviceType.gateway;
    if (s.contains('googlecast'))     return DiscoveredDeviceType.speaker;
    if (s.contains('shelly'))         return DiscoveredDeviceType.smartSwitch;
    if (s.contains('esphome'))        return DiscoveredDeviceType.smartSwitch;
    if (s.contains('matter'))         return DiscoveredDeviceType.smartSwitch;
    return DiscoveredDeviceType.unknown;
  }

  // ── Home Assistant entity classification ─────────────────────────────────────

  /// Map a HA entity_id + device_class + friendly_name to a device type.
  static DiscoveredDeviceType classifyHaEntity({
    required String entityId,
    String? deviceClass,
    required String friendlyName,
  }) {
    final domain = entityId.split('.').first;
    final dc    = (deviceClass ?? '').toLowerCase();
    final name  = friendlyName.toLowerCase();

    switch (domain) {
      case 'light':        return DiscoveredDeviceType.light;
      case 'switch':       return DiscoveredDeviceType.smartSwitch;
      case 'water_heater': return DiscoveredDeviceType.boiler;
      case 'climate':      return DiscoveredDeviceType.thermostat;
      case 'camera':       return DiscoveredDeviceType.camera;
      case 'cover':        return DiscoveredDeviceType.smartSwitch; // blinds/covers
      case 'sensor':
        if (dc == 'smoke'  || _any(name, ['smoke', 'עשן']))
          return DiscoveredDeviceType.smokeSensor;
        if (dc == 'energy' || dc == 'power' || _any(name, ['kwh', 'watt', 'energy', 'power']))
          return DiscoveredDeviceType.energyMeter;
        if (_any(name, ['boiler', 'דוד', 'water heat']))
          return DiscoveredDeviceType.boiler;
        return DiscoveredDeviceType.sensor;
      case 'binary_sensor':
        if (dc == 'motion'  || _any(name, ['motion', 'תנועה', 'pir', 'occupancy']))
          return DiscoveredDeviceType.motionSensor;
        if (dc == 'window'  || _any(name, ['window', 'חלון']))
          return DiscoveredDeviceType.windowSensor;
        if (dc == 'door' || dc == 'opening' || _any(name, ['door', 'דלת']))
          return DiscoveredDeviceType.doorSensor;
        if (dc == 'smoke'   || _any(name, ['smoke', 'fire']))
          return DiscoveredDeviceType.smokeSensor;
        if (dc == 'gas'     || _any(name, ['gas', 'co2', 'carbon']))
          return DiscoveredDeviceType.smokeSensor;
        return DiscoveredDeviceType.sensor;
      case 'input_boolean':
        return DiscoveredDeviceType.smartSwitch;
      default:
        return DiscoveredDeviceType.unknown;
    }
  }

  // ── Type conversion ──────────────────────────────────────────────────────────

  /// Map discovery type → app DeviceType for adding to AppState.
  static DeviceType toAppType(DiscoveredDeviceType t) => switch (t) {
    DiscoveredDeviceType.light         => DeviceType.light,
    DiscoveredDeviceType.socket        => DeviceType.smartPlug,
    DiscoveredDeviceType.smartSwitch   => DeviceType.smartSwitch,
    DiscoveredDeviceType.thermostat    => DeviceType.airConditioner,
    DiscoveredDeviceType.camera        => DeviceType.camera,
    DiscoveredDeviceType.gateway       => DeviceType.gateway,
    DiscoveredDeviceType.boiler        => DeviceType.waterHeater,
    DiscoveredDeviceType.solar         => DeviceType.solar,
    DiscoveredDeviceType.circuitBreaker => DeviceType.circuitBreaker,
    DiscoveredDeviceType.energyMeter   => DeviceType.energyMeter,
    DiscoveredDeviceType.smokeSensor   => DeviceType.smokeSensor,
    DiscoveredDeviceType.motionSensor  => DeviceType.motionSensor,
    DiscoveredDeviceType.windowSensor  => DeviceType.windowSensor,
    DiscoveredDeviceType.doorSensor    => DeviceType.doorSensor,
    DiscoveredDeviceType.waterLeak     => DeviceType.waterLeakSensor,
    DiscoveredDeviceType.router        => DeviceType.router,
    _                                  => DeviceType.gateway,
  };

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static bool _any(String haystack, List<String> needles) =>
      needles.any((n) => haystack.contains(n));
}
