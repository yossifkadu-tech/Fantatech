// ─────────────────────────────────────────────────────────────────────────────
// DeviceCommander
//
// Routes a high-level command (on/off, brightness, color) on a Device to the
// correct underlying protocol/gateway based on the device's id prefix and
// attributes.
//
// Device ID conventions used elsewhere in the app:
//   dirigera_<id>          → IKEA DIRIGERA REST
//   deconz_light_<id>      → deCONZ REST
//   z2m_<ieee>             → Zigbee2MQTT (MQTT publish)
//   hue_light_<id>         → Philips Hue REST
//
// For LAN-direct devices (Shelly / Sonoff / Tuya / Kasa / Tapo / ESPHome) the
// attributes map carries the protocol details (ip, protocol marker, etc.) and
// we dispatch via the existing SwitchController.
//
// All methods are best-effort and never throw.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

import '../../models/device.dart';
import '../gateways/gateway_manager.dart';
import '../gateways/gateway_model.dart';
import '../gateways/gateway_types.dart';
import '../gateways/clients/dirigera_client.dart';
import '../gateways/clients/deconz_client.dart';
import '../gateways/clients/z2m_client.dart';
import '../gateways/clients/hue_client.dart';
import '../gateways/clients/ha_gateway_client.dart';
import '../gateways/clients/aqara_hub_client.dart';
import '../switches/switch_controller.dart';
import '../switches/smart_switch_models.dart';
import '../lights/govee_lan_controller.dart';
import '../lights/yeelight_controller.dart';
import '../lights/wiz_controller.dart';
import '../lights/lifx_controller.dart';
import '../lights/nanoleaf_controller.dart';
import '../switches/meross_controller.dart';
import '../live/mqtt_connection_pool.dart';

enum VacuumAction { start, pause, dock }

class DeviceCommander {
  /// Turn a device on or off. Returns true if the command was sent
  /// successfully (does not guarantee the physical device responded).
  static Future<bool> setOnOff(
    Device device,
    bool on, {
    required GatewayManager gateways,
  }) async {
    final id = device.id;

    // ── IKEA DIRIGERA ──────────────────────────────────────────────────────────
    if (id.startsWith('dirigera_')) {
      final gw = _gateway(gateways, GatewayType.dirigera);
      if (gw == null) return false;
      final ip    = gw.credentials['ip'];
      final token = gw.credentials['token'];
      if (ip == null || token == null) return false;
      return DIRIGERAGatewayClient.setOnOff(ip, token, id, on);
    }

    // ── deCONZ / Phoscon ───────────────────────────────────────────────────────
    if (id.startsWith('deconz_light_')) {
      final gw = _gateway(gateways, GatewayType.deconz);
      if (gw == null) return false;
      final ip     = gw.credentials['ip'];
      final port   = int.tryParse(gw.credentials['port'] ?? '80') ?? 80;
      final apiKey = gw.credentials['apiKey'];
      if (ip == null || apiKey == null) return false;
      return DeCONZGatewayClient.setOnOff(ip, port, apiKey, id, on);
    }

    // ── Zigbee2MQTT ────────────────────────────────────────────────────────────
    if (id.startsWith('z2m_')) {
      final gw = _gateway(gateways, GatewayType.zigbee2mqtt);
      if (gw == null) return false;
      final friendly = device.attributes['friendlyName'] as String?;
      if (friendly == null) return false;

      // Z2M control goes over MQTT. Use the gateway IP as broker host by
      // default; explicit broker credentials can override via attributes.
      final mqttHost = device.attributes['mqttHost'] as String?
          ?? gw.credentials['mqttHost']
          ?? gw.credentials['ip'];
      if (mqttHost == null) return false;
      final mqttPort = int.tryParse(
              gw.credentials['mqttPort'] ?? '') ?? 1883;
      return Z2MGatewayClient.setOnOff(
        mqttHost:     mqttHost,
        mqttPort:     mqttPort,
        mqttUser:     gw.credentials['mqttUser'],
        mqttPass:     gw.credentials['mqttPass'],
        friendlyName: friendly,
        isOn:         on,
      );
    }

    // ── Philips Hue ────────────────────────────────────────────────────────────
    if (id.startsWith('hue_light_')) {
      final gw = _gateway(gateways, GatewayType.hue);
      if (gw == null) return false;
      final ip   = gw.credentials['ip'];
      final user = gw.credentials['username'];
      if (ip == null || user == null) return false;
      final lightId = id.substring('hue_light_'.length);
      return HueGatewayClient.setOnOff(ip, user, lightId, on);
    }

    // ── Home Assistant (REST API) ──────────────────────────────────────────────
    if (id.startsWith('ha_')) {
      final gw = _gateway(gateways, GatewayType.homeAssistant);
      if (gw == null) return false;
      final ip       = gw.credentials['ip'];
      final token    = gw.credentials['token'];
      final entityId = device.attributes['entityId'] as String?;
      if (ip == null || token == null || entityId == null) return false;
      return HaGatewayClient.setOnOff(ip, token, entityId, on);
    }

    // ── Govee LAN ──────────────────────────────────────────────────────────────
    if (id.startsWith('govee_')) {
      final ip = device.attributes['ip'] as String?;
      if (ip == null) return false;
      return GoveeLanController.setOnOff(ip, on);
    }

    // ── Yeelight LAN ──────────────────────────────────────────────────────────
    if (id.startsWith('yeelight_')) {
      final ip = device.attributes['ip'] as String?;
      if (ip == null) return false;
      return YeelightController.setOnOff(ip, on);
    }

    // ── WiZ LAN ───────────────────────────────────────────────────────────────
    if (id.startsWith('wiz_')) {
      final ip = device.attributes['ip'] as String?;
      if (ip == null) return false;
      return WizController.setOnOff(ip, on);
    }

    // ── LIFX Cloud ────────────────────────────────────────────────────────────
    if (id.startsWith('lifx_')) {
      final token    = device.attributes['lifxToken'] as String?;
      final selector = device.attributes['lifxSelector'] as String? ?? 'id:${id.substring(5)}';
      if (token == null) return false;
      return LifxController(apiToken: token).setOnOff(selector, on);
    }

    // ── Nanoleaf ──────────────────────────────────────────────────────────────
    if (id.startsWith('nanoleaf_')) {
      final ip    = device.attributes['ip'] as String?;
      final token = device.attributes['nanoleafToken'] as String?;
      if (ip == null || token == null) return false;
      return NanoleafController(ip: ip, authToken: token).setOnOff(on);
    }

    // ── Meross LAN ────────────────────────────────────────────────────────────
    if (id.startsWith('meross_')) {
      final ip      = device.attributes['ip'] as String?;
      final channel = (device.attributes['channel'] as int?) ?? 0;
      if (ip == null) return false;
      return MerossController.setOnOff(ip, on, channel: channel);
    }

    // ── Aqara Hub ─────────────────────────────────────────────────────────────
    if (id.startsWith('aqara_')) {
      final ip    = device.attributes['ip'] as String?;
      final token = device.attributes['aqaraToken'] as String?;
      final did   = device.attributes['did'] as String? ?? id.substring(6);
      if (ip == null || token == null) return false;
      return AqaraHubClient(ip: ip, accessToken: token).setOnOff(did, on);
    }

    // ── Generic MQTT (HA-discovery devices with mqtt_ prefix) ─────────────────
    if (id.startsWith('mqtt_')) {
      return _mqttSetOnOff(device, on, gateways);
    }

    // ── LAN-direct (Shelly / Sonoff / Tuya / Kasa / Tapo / ESPHome) ────────────
    final ssd = _asSmartSwitch(device);
    if (ssd != null) {
      final ch = (device.attributes['channel'] as int?) ?? 0;
      return SwitchController.setOn(ssd, ch, on);
    }

    return false;
  }

  /// Send a climate control change to the physical AC. HA only for now —
  /// pass exactly one of the named parameters per call.
  static Future<bool> setClimate(
    Device device, {
    String? hvacMode,
    double? temperature,
    String? fanMode,
    String? swingMode,
    String? presetMode,
    required GatewayManager gateways,
  }) async {
    if (!device.id.startsWith('ha_')) return false;
    final gw = _gateway(gateways, GatewayType.homeAssistant);
    if (gw == null) return false;
    final ip       = gw.credentials['ip'];
    final token    = gw.credentials['token'];
    final entityId = device.attributes['entityId'] as String?;
    if (ip == null || token == null || entityId == null) return false;

    if (hvacMode != null) {
      return HaGatewayClient.setHvacMode(ip, token, entityId, hvacMode);
    }
    if (temperature != null) {
      return HaGatewayClient.setClimateTemperature(ip, token, entityId, temperature);
    }
    if (fanMode != null) {
      return HaGatewayClient.setFanMode(ip, token, entityId, fanMode);
    }
    if (swingMode != null) {
      return HaGatewayClient.setSwingMode(ip, token, entityId, swingMode);
    }
    if (presetMode != null) {
      return HaGatewayClient.setPresetMode(ip, token, entityId, presetMode);
    }
    return false;
  }

  /// Set cover/blind/valve position 0–100 (100 = fully open). HA only for
  /// now. A [DeviceType.blind] can back either a real cover or an HA `valve`
  /// entity (smart water/gas valve) — routed by the entity's own domain
  /// attribute, since HA exposes them as separate service families.
  static Future<bool> setCoverPosition(
    Device device,
    int position, {
    required GatewayManager gateways,
  }) async {
    if (device.id.startsWith('ha_')) {
      final gw = _gateway(gateways, GatewayType.homeAssistant);
      if (gw == null) return false;
      final ip       = gw.credentials['ip'];
      final token    = gw.credentials['token'];
      final entityId = device.attributes['entityId'] as String?;
      if (ip == null || token == null || entityId == null) return false;
      if (device.attributes['domain'] == 'valve') {
        return HaGatewayClient.setValvePosition(ip, token, entityId, position);
      }
      return HaGatewayClient.setCoverPosition(ip, token, entityId, position);
    }
    return false;
  }

  /// Stop a moving cover/blind/valve.
  static Future<bool> stopCover(
    Device device, {
    required GatewayManager gateways,
  }) async {
    if (device.id.startsWith('ha_')) {
      final gw = _gateway(gateways, GatewayType.homeAssistant);
      if (gw == null) return false;
      final ip       = gw.credentials['ip'];
      final token    = gw.credentials['token'];
      final entityId = device.attributes['entityId'] as String?;
      if (ip == null || token == null || entityId == null) return false;
      if (device.attributes['domain'] == 'valve') {
        return HaGatewayClient.stopValve(ip, token, entityId);
      }
      return HaGatewayClient.callService(ip, token, 'cover', 'stop_cover', entityId);
    }
    return false;
  }

  /// Send a robot-vacuum command (start / pause / return to dock). HA only —
  /// vacuums are synced in via the `vacuum` domain, no local pairing flow.
  static Future<bool> vacuumCommand(
    Device device,
    VacuumAction action, {
    required GatewayManager gateways,
  }) async {
    if (!device.id.startsWith('ha_')) return false;
    final gw = _gateway(gateways, GatewayType.homeAssistant);
    if (gw == null) return false;
    final ip       = gw.credentials['ip'];
    final token    = gw.credentials['token'];
    final entityId = device.attributes['entityId'] as String?;
    if (ip == null || token == null || entityId == null) return false;

    final service = switch (action) {
      VacuumAction.start => 'start',
      VacuumAction.pause => 'pause',
      VacuumAction.dock  => 'return_to_base',
    };
    return HaGatewayClient.callService(ip, token, 'vacuum', service, entityId);
  }

  /// Set brightness 0..100 for a dimmable light. Returns true on success.
  static Future<bool> setBrightness(
    Device device,
    int level, {
    required GatewayManager gateways,
  }) async {
    final id = device.id;

    if (id.startsWith('dirigera_')) {
      final gw = _gateway(gateways, GatewayType.dirigera);
      if (gw == null) return false;
      final ip    = gw.credentials['ip'];
      final token = gw.credentials['token'];
      if (ip == null || token == null) return false;
      return DIRIGERAGatewayClient.setBrightness(ip, token, id, level);
    }

    if (id.startsWith('deconz_light_')) {
      final gw = _gateway(gateways, GatewayType.deconz);
      if (gw == null) return false;
      final ip     = gw.credentials['ip'];
      final port   = int.tryParse(gw.credentials['port'] ?? '80') ?? 80;
      final apiKey = gw.credentials['apiKey'];
      if (ip == null || apiKey == null) return false;
      return DeCONZGatewayClient.setBrightness(ip, port, apiKey, id, level);
    }

    if (id.startsWith('z2m_')) {
      final gw = _gateway(gateways, GatewayType.zigbee2mqtt);
      if (gw == null) return false;
      final friendly = device.attributes['friendlyName'] as String?;
      final mqttHost = device.attributes['mqttHost'] as String?
          ?? gw.credentials['mqttHost']
          ?? gw.credentials['ip'];
      if (friendly == null || mqttHost == null) return false;
      return Z2MGatewayClient.setBrightness(
        mqttHost:     mqttHost,
        mqttPort:     int.tryParse(gw.credentials['mqttPort'] ?? '') ?? 1883,
        mqttUser:     gw.credentials['mqttUser'],
        mqttPass:     gw.credentials['mqttPass'],
        friendlyName: friendly,
        level:        level,
      );
    }

    if (id.startsWith('hue_light_')) {
      final gw = _gateway(gateways, GatewayType.hue);
      if (gw == null) return false;
      final ip   = gw.credentials['ip'];
      final user = gw.credentials['username'];
      if (ip == null || user == null) return false;
      final lightId = id.substring('hue_light_'.length);
      return HueGatewayClient.setBrightness(ip, user, lightId, level);
    }

    if (id.startsWith('ha_')) {
      final gw = _gateway(gateways, GatewayType.homeAssistant);
      if (gw == null) return false;
      final ip       = gw.credentials['ip'];
      final token    = gw.credentials['token'];
      final entityId = device.attributes['entityId'] as String?;
      if (ip == null || token == null || entityId == null) return false;
      return HaGatewayClient.setBrightness(ip, token, entityId, level);
    }

    // ── Govee LAN brightness ──────────────────────────────────────────────────
    if (id.startsWith('govee_')) {
      final ip = device.attributes['ip'] as String?;
      if (ip == null) return false;
      return GoveeLanController.setBrightness(ip, level);
    }

    // ── Yeelight brightness ───────────────────────────────────────────────────
    if (id.startsWith('yeelight_')) {
      final ip = device.attributes['ip'] as String?;
      if (ip == null) return false;
      return YeelightController.setBrightness(ip, level);
    }

    // ── WiZ brightness ────────────────────────────────────────────────────────
    if (id.startsWith('wiz_')) {
      final ip = device.attributes['ip'] as String?;
      if (ip == null) return false;
      return WizController.setBrightness(ip, level);
    }

    // ── LIFX Cloud brightness ─────────────────────────────────────────────────
    if (id.startsWith('lifx_')) {
      final token    = device.attributes['lifxToken'] as String?;
      final selector = device.attributes['lifxSelector'] as String? ?? 'id:${id.substring(5)}';
      if (token == null) return false;
      return LifxController(apiToken: token).setBrightness(selector, level / 100.0);
    }

    // ── Nanoleaf brightness ───────────────────────────────────────────────────
    if (id.startsWith('nanoleaf_')) {
      final ip    = device.attributes['ip'] as String?;
      final token = device.attributes['nanoleafToken'] as String?;
      if (ip == null || token == null) return false;
      return NanoleafController(ip: ip, authToken: token).setBrightness(level);
    }

    // ── Aqara Hub brightness ──────────────────────────────────────────────────
    if (id.startsWith('aqara_')) {
      final ip    = device.attributes['ip'] as String?;
      final token = device.attributes['aqaraToken'] as String?;
      final did   = device.attributes['did'] as String? ?? id.substring(6);
      if (ip == null || token == null) return false;
      return AqaraHubClient(ip: ip, accessToken: token).setBrightness(did, level);
    }

    // ── Generic MQTT brightness ───────────────────────────────────────────────
    if (id.startsWith('mqtt_')) {
      return _mqttSetBrightness(device, level, gateways);
    }

    return false;
  }

  // ── MQTT helpers ───────────────────────────────────────────────────────────

  static Future<bool> _mqttSetOnOff(
    Device device,
    bool on,
    GatewayManager gateways,
  ) async {
    final svc = await _mqttService(device, gateways);
    if (svc == null) return false;
    final cmdTopic = device.attributes['cmdTopic'] as String?;
    if (cmdTopic == null || cmdTopic.isEmpty) {
      if (kDebugMode) debugPrint('[DeviceCommander] mqtt_ device ${device.id} has no cmdTopic');
      return false;
    }
    try {
      await svc.publishJson(cmdTopic, {'state': on ? 'ON' : 'OFF'});
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[DeviceCommander] mqtt publish error: $e');
      return false;
    }
  }

  static Future<bool> _mqttSetBrightness(
    Device device,
    int level,
    GatewayManager gateways,
  ) async {
    final svc = await _mqttService(device, gateways);
    if (svc == null) return false;
    final cmdTopic = device.attributes['cmdTopic'] as String?;
    if (cmdTopic == null || cmdTopic.isEmpty) return false;
    try {
      // HA-discovery lights expect brightness as 0–255 integer.
      await svc.publishJson(cmdTopic, {
        'state':      'ON',
        'brightness': (level * 2.55).round().clamp(0, 255),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[DeviceCommander] mqtt brightness error: $e');
      return false;
    }
  }

  /// Resolves the [MqttService] for an mqtt_ device via the connection pool.
  /// Looks up broker credentials from the [GatewayType.mqtt] gateway.
  static Future<dynamic> _mqttService(
    Device device,
    GatewayManager gateways,
  ) async {
    final gw = _gateway(gateways, GatewayType.mqtt);
    if (gw == null) {
      if (kDebugMode) debugPrint('[DeviceCommander] no MQTT gateway configured');
      return null;
    }
    final host = gw.credentials['host'] ?? '';
    final port = int.tryParse(gw.credentials['port'] ?? '1883') ?? 1883;
    if (host.isEmpty) return null;

    return MqttConnectionPool.acquire(
      host:     host,
      port:     port,
      username: gw.credentials['username']?.isEmpty == true
          ? null
          : gw.credentials['username'],
      password: gw.credentials['password']?.isEmpty == true
          ? null
          : gw.credentials['password'],
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Find the first connected gateway of the requested type.
  static GatewayConnection? _gateway(GatewayManager m, GatewayType type) {
    for (final c in m.connections) {
      if (c.type == type && c.isConnected) return c;
    }
    return null;
  }

  /// Build a `SmartSwitchDevice` from a `Device`'s attributes, if the device
  /// looks like a LAN-direct switch / outlet / smart bulb.
  static SmartSwitchDevice? _asSmartSwitch(Device d) {
    final ip = d.attributes['ip'] as String?;
    if (ip == null) return null;

    final protoStr = (d.attributes['protocol'] as String?)?.toLowerCase() ?? '';
    final manufacturer = (d.attributes['manufacturer'] as String?)?.toLowerCase() ?? '';

    SwitchProtocol? proto;
    if (protoStr.contains('shelly')) {
      final gen = d.attributes['shellyGen'] as int? ?? 2;
      proto = switch (gen) {
        1     => SwitchProtocol.shellyGen1,
        2     => SwitchProtocol.shellyGen2,
        3     => SwitchProtocol.shellyGen3,
        _     => SwitchProtocol.shellyGen2,
      };
    } else if (manufacturer.contains('shelly')) {
      proto = SwitchProtocol.shellyGen2;
    } else if (protoStr.contains('sonoff') || manufacturer.contains('sonoff')) {
      proto = SwitchProtocol.sonoffLan;
    } else if (protoStr.contains('esphome')) {
      proto = SwitchProtocol.esphome;
    } else if (protoStr.contains('tuya') || manufacturer.contains('tuya')) {
      proto = SwitchProtocol.tuyaLocal;
    } else if (protoStr.contains('kasa') || manufacturer.contains('tp-link')) {
      proto = SwitchProtocol.kasaLocal;
    } else if (protoStr.contains('tapo')) {
      proto = SwitchProtocol.tapoLocal;
    } else {
      return null;
    }

    return SmartSwitchDevice(
      id:             d.id,
      name:           d.name,
      ip:             ip,
      mac:            d.attributes['mac'] as String?,
      protocol:       proto,
      channels:       [SwitchChannel(index: 0, name: d.name, isOn: d.isOn)],
      connectionData: _connectionDataFor(d),
    );
  }

  static Map<String, dynamic> _connectionDataFor(Device d) {
    final out = <String, dynamic>{};
    for (final key in const [
      'deviceId', 'entityId', 'entityIds',
      'localKey', 'devId', 'dpsIndex',
      'tapoEmail', 'tapoPassword',
      'haIp', 'haToken',
    ]) {
      final v = d.attributes[key];
      if (v != null) out[key] = v;
    }
    return out;
  }
}
