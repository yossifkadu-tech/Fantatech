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
    '78779B': 'Broadlink', '34EA34': 'Broadlink',
    // Tado (smart thermostat, common in Israel)
    '28FBA7': 'Tado',      '7C70BC': 'Tado',
    // Yeelight / Xiaomi Light (A4C138 is already covered by Xiaomi entry above)
    '64090C': 'Yeelight',
    // WiZ (Signify / Philips)
    'ACBCB7': 'WiZ',
    // LIFX (D073D5 is the official LIFX OUI)
    'D073D5': 'LIFX',
    // Nanoleaf
    '00551A': 'Nanoleaf',  'C4DD57': 'Nanoleaf',
    // Aqara (Lumi United / Xiaomi) — 04CF8C is already used by IKEA entry above
    '286C07': 'Aqara',     '54EF44': 'Aqara',
    // Eufy (Anker)
    'C4EDBA': 'Eufy',      '30A2E2': 'Eufy',
    // Ring (Amazon)
    'B4A5EF': 'Ring',      'CC4367': 'Ring',       '98AAFC': 'Ring',
    // Nest (Google)
    '18B430': 'Nest',      '641666': 'Nest',       '64A516': 'Nest',
    // Arlo (Netgear)
    '20F0D1': 'Arlo',      '60045A': 'Arlo',
    // Roborock
    '28D203': 'Roborock',  '9863ED': 'Roborock',
    // Zigbee coordinators
    '00124B': 'Texas Instruments', // CC2531 / CC2652
    '047F0E': 'Silicon Labs',      // ConBee / RaspBee
    // ── AC / HVAC WiFi adapters ──────────────────────────────────────────────
    // Daikin WiFi adapter (BRP069B41 / BRP069A41)
    '00CBAD': 'Daikin',  'D0A7EB': 'Daikin',  '2C78F0': 'Daikin',
    // Mitsubishi Electric MELCloud (MAC-IFTSL-WF)
    '7C8B8B': 'Mitsubishi Electric', 'F0A5C8': 'Mitsubishi Electric',
    // Panasonic Comfort Cloud (CZ-TACG1)
    '9CEBE8': 'Panasonic', '48A905': 'Panasonic',
    // LG HVAC (ThinQ)
    'AC4B1E': 'LG',  'C80E14': 'LG',
    // Gree (and white-labels: Cooper&Hunter, AUX, Midea compatible)
    'A8C645': 'Gree',  '00E048': 'Gree',  'CC36A8': 'Gree',
    // Haier
    '703840': 'Haier',  'D0C8DC': 'Haier',
    // Hisense
    '90CAF3': 'Hisense', 'E4E0C5': 'Hisense',
    // Toshiba Smart Manager
    '009099': 'Toshiba',
    // Fujitsu General (Watanabe WiFi)
    '003065': 'Fujitsu',  '28B2BD': 'Fujitsu',
    // Samsung (ACs + TVs share OUI range)
    '8C7712': 'Samsung',  'A44F29': 'Samsung',
    // Sensibo (Israeli startup)
    'F0038C': 'Sensibo',
    // Tadiran Smart Connect (Tuya OEM — often Espressif chip)
    // Electra Smart (Tuya OEM)
    // Both fall under Tuya/Espressif OUIs already listed above
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
                      'termosmart', 'atlantic'])) {
      return DiscoveredDeviceType.boiler;
    }

    // 5. Sensors
    if (_any(lower, ['water leak', 'leak', 'flood', 'shflood', 'נזיל',
                      'water sensor', 'badring', 'fibaro flood',
                      'neo coolcam water', 'heiman water', 'aqara flood'])) {
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
    if (openPorts.contains(8443)) return DiscoveredDeviceType.gateway; // IKEA DIRIGERA
    if (_any(lower, ['home assistant', 'homeassistant', 'zigbee2mqtt', 'deconz',
                      'dirigera', 'ikea dirigera', 'hue bridge', 'smartthings',
                      'hubitat', 'gateway', 'coordinator', 'zigbee coordinator'])) {
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

    // 8b. Smart bulbs / light controllers
    if (openPorts.contains(5683) ||
        _any(lower, ['tradfri', 'trådfri', 'ikea bulb', 'ikea light',
                      'ikea lamp', 'led1', 'led2'])) {
      return DiscoveredDeviceType.light;
    }
    // Govee LAN (UDP 4003 — won't appear in TCP scan, detect by OUI/name)
    if (_any(lower, ['govee', 'govee-h', 'govee_h'])) {
      return DiscoveredDeviceType.light;
    }
    // Yeelight (TCP 55443)
    if (openPorts.contains(55443) ||
        _any(lower, ['yeelight', 'yeelink', 'milight'])) {
      return DiscoveredDeviceType.light;
    }
    // WiZ (UDP 38899 — won't appear in TCP, detect by name/OUI)
    if (_any(lower, ['wiz ', 'wizlight', 'wiz-', 'phillips wiz', 'philips wiz'])) {
      return DiscoveredDeviceType.light;
    }
    // Nanoleaf (HTTP 16021)
    if (openPorts.contains(16021) ||
        _any(lower, ['nanoleaf', 'aurora', 'shapes', 'elements', 'lines'])) {
      return DiscoveredDeviceType.light;
    }
    // LIFX (UDP 56700 — won't appear in TCP, detect by name)
    if (_any(lower, ['lifx', 'lifx-', 'lifx_'])) {
      return DiscoveredDeviceType.light;
    }
    // Broadlink IR blaster
    if (_any(lower, ['broadlink', 'rm pro', 'rm mini', 'rm4', 'bl-rm',
                      'bestcon', 'rm3'])) {
      return DiscoveredDeviceType.smartSwitch; // IR blaster acts as switch
    }
    // Meross
    if (_any(lower, ['meross', 'msg10', 'mss', 'msl', 'msh'])) {
      return DiscoveredDeviceType.socket;
    }
    // Aqara hub
    if (_any(lower, ['aqara', 'lumi', 'aqara-hub', 'aqara hub'])) {
      return DiscoveredDeviceType.gateway;
    }

    // 9. Camera
    if (openPorts.contains(554)) return DiscoveredDeviceType.camera; // RTSP
    if (_any(lower, ['hikvision', 'dahua', 'reolink', 'ipcam', 'nvr', 'dvr',
                      'amcrest', 'eufy', 'ring', 'arlo', 'nest cam', 'wyze',
                      'camera', 'cam-', '-cam'])) {
      return DiscoveredDeviceType.camera;
    }

    // 10. Router
    if (_any(lower, ['router', 'openwrt', 'routeros', 'mikrotik', 'ubiquiti',
                      'unifi', 'asus router', 'tplink router'])) {
      return DiscoveredDeviceType.router;
    }

    // 11. Air conditioner / HVAC (WiFi adapters, cloud bridges, IR blasters)
    //
    // Israeli brands
    if (_any(lower, ['tadiran', 'tadi', 'ta-', 'tadiran-ac', 'tadiran smart',
                      'תדיראן'])) {
      return DiscoveredDeviceType.thermostat; // mapped → airConditioner
    }
    if (_any(lower, ['electra', 'אלקטרה', 'electra-ac', 'electra smart'])) {
      return DiscoveredDeviceType.thermostat;
    }
    if (_any(lower, ['elite', 'אלייט', 'elite-ac', 'elite smart'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Daikin — BRP069 WiFi adapter; responds on port 80 at /aircon/
    if (openPorts.contains(80) && _any(lower, ['/aircon/', 'daikin', 'brp069',
                                                 'x-daikin', 'daikinap'])) {
      return DiscoveredDeviceType.thermostat;
    }
    if (_any(lower, ['daikin', 'brp069', 'daikin-ap', 'daikinap'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Mitsubishi Electric — MELCloud; mDNS _mitsubishi_wf._tcp
    if (_any(lower, ['mitsubishi', 'melcloud', 'mac-ift', 'mel-', 'pac-uif',
                      'kumo cloud', 'mac-wifi', 'wifi-ap', 'מיצובישי'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // LG ThinQ ACs — port 6444
    if (openPorts.contains(6444) || _any(lower, ['lg-hvac', 'lgexp',
                                                    'lg ac', 'lg-rac',
                                                    'lg-smart-device'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Panasonic Comfort Cloud — CZ-TACG1 WiFi adapter
    if (_any(lower, ['panasonic', 'comfort cloud', 'cz-tacg', 'cz-t',
                      'panasonic-wlan', 'panasonic ac', 'פנסוניק'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Fujitsu — Watanabe WiFi adapter; mDNS _fujitsu_ac._tcp
    if (_any(lower, ['fujitsu', 'watanabe', 'general fujitsu', 'fujitsu-ac',
                      'fujitsu_ac'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Gree / Carrier / AUX / Cooper&Hunter — port 7000
    if (openPorts.contains(7000) || _any(lower, ['gree', 'greeh', 'gree-ac',
                                                    'carrier ac', 'aux ac',
                                                    'cooper hunter',
                                                    'ch-', 'c&h-'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Midea / Haier / TCL / Comfortstar — port 6444
    if (_any(lower, ['midea', 'haier', 'tcl ac', 'comfortstar', 'msmarthome',
                      'midea-ac', 'haier-ac', 'mideaair', 'midea_ac'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Hisense — port 36669
    if (openPorts.contains(36669) || _any(lower, ['hisense', 'hisense-ac',
                                                     'hisense smart'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Toshiba Smart Manager
    if (_any(lower, ['toshiba ac', 'toshiba-ac', 'toshibasmartac',
                      'toshiba smart'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Samsung Wind-Free ACs — port 8888 / mDNS _samsung-ac._tcp
    if (openPorts.contains(8888) || _any(lower, ['samsung ac', 'samsung-ac',
                                                    'wind-free', 'windfree',
                                                    'samsung wind'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Intesis — protocol bridge for Mitsubishi/Daikin/Panasonic
    if (_any(lower, ['intesis', 'intesisbox', 'intesis box'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Sensibo (Israeli startup) — usually cloud, but BLE name contains "Sensibo"
    if (_any(lower, ['sensibo', 'sensibo sky', 'sensibo air',
                      'sensibo elements', 'sensibo pure'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Cielo Breez / Ambi Climate / Tado v2 — cloud IR blasters
    if (_any(lower, ['cielo breez', 'ambi climate', 'ambicli',
                      'ambi-climate'])) {
      return DiscoveredDeviceType.thermostat;
    }
    // Generic AC keywords
    if (_any(lower, ['מזגן', 'aircon', 'air-con', ' hvac', 'heat pump',
                      'minisplit', 'mini-split', 'split ac', 'split unit',
                      'שמונה', ' ac ', '-ac-'])) {
      return DiscoveredDeviceType.thermostat;
    }

    // 12. Thermostat (non-AC)
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
    // Gateways / hubs
    if (s.contains('home-assistant')) return DiscoveredDeviceType.gateway;
    if (s.contains('hue'))            return DiscoveredDeviceType.gateway;
    if (s.contains('dirigera'))       return DiscoveredDeviceType.gateway;
    if (s.contains('ihsp'))           return DiscoveredDeviceType.gateway;
    if (s.contains('hap'))            return DiscoveredDeviceType.gateway;
    if (s.contains('mqtt'))           return DiscoveredDeviceType.gateway;
    // Speakers / displays
    if (s.contains('googlecast'))     return DiscoveredDeviceType.speaker;
    // Smart switches
    if (s.contains('shelly'))         return DiscoveredDeviceType.smartSwitch;
    if (s.contains('esphome'))        return DiscoveredDeviceType.smartSwitch;
    if (s.contains('matter'))         return DiscoveredDeviceType.smartSwitch;
    // ── Air conditioner WiFi adapters ────────────────────────────────────────
    if (s.contains('daikin'))         return DiscoveredDeviceType.thermostat;
    if (s.contains('mitsubishi_wf'))  return DiscoveredDeviceType.thermostat;
    if (s.contains('melview'))        return DiscoveredDeviceType.thermostat;
    if (s.contains('kumo'))           return DiscoveredDeviceType.thermostat;
    if (s.contains('fujitsu_ac'))     return DiscoveredDeviceType.thermostat;
    if (s.contains('samsung-ac'))     return DiscoveredDeviceType.thermostat;
    if (s.contains('panasonic-wlan')) return DiscoveredDeviceType.thermostat;
    if (s.contains('toshibasmartac')) return DiscoveredDeviceType.thermostat;
    if (s.contains('hisense-smart'))  return DiscoveredDeviceType.thermostat;
    if (s.contains('aircon'))         return DiscoveredDeviceType.thermostat;
    if (s.contains('hvac'))           return DiscoveredDeviceType.thermostat;
    if (s.contains('tadiran'))        return DiscoveredDeviceType.thermostat;
    if (s.contains('electra'))        return DiscoveredDeviceType.thermostat;
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
