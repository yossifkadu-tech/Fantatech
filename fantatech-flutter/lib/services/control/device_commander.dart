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
import '../gateways/clients/tuya_cloud_client.dart';
import '../hub/hub_config.dart';
import '../hub/hub_rest_client.dart';
import '../gateways/clients/aqara_hub_client.dart';
import '../gateways/clients/irobot_client.dart';
import '../gateways/clients/xiaomi_vacuum_client.dart';
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
    // Aqara devices are created with a dash prefix ('aqara-...') and store
    // credentials as 'aqaraIp'/'aqaraToken', not 'ip'/'token' — see
    // gateway_manager.dart and sensor_scan_engine.dart's Aqara import paths.
    if (id.startsWith('aqara-')) {
      final ip    = device.attributes['aqaraIp'] as String?;
      final token = device.attributes['aqaraToken'] as String?;
      final did   = device.attributes['did'] as String? ?? id.substring(6);
      if (ip == null || token == null) return false;
      return AqaraHubClient(ip: ip, accessToken: token).setOnOff(did, on);
    }

    // ── Generic MQTT (HA-discovery devices with mqtt_ prefix) ─────────────────
    if (id.startsWith('mqtt_')) {
      return _mqttSetOnOff(device, on, gateways);
    }

    // ── Tuya Cloud (devices imported via Devices → Link App Account, not
    // the LAN-scan Tuya-local path below) ──────────────────────────────────
    // Import (TuyaCloudClient.fetchDevices) added these to AppState but
    // never wired a command path back to them — toggling silently did
    // nothing. This used to always send 'switch_1' — wrong for a gang
    // other than the first on a multi-gang device (TuyaCloudClient now
    // imports each gang as its own Device, id suffixed '_chN' — see its
    // channelStates handling) and wrong for the small number of older
    // devices whose single on/off DP is the legacy bare 'switch' or
    // 'switch_led' code instead of 'switch_1'. Resolve the real code
    // instead of assuming it.
    if (id.startsWith('tuya_')) {
      final gw = _gateway(gateways, GatewayType.tuyaSmart) ??
          _gateway(gateways, GatewayType.smartLife);
      if (gw == null) return false;
      final clientId     = gw.credentials['clientId'];
      final clientSecret = gw.credentials['clientSecret'];
      if (clientId == null || clientSecret == null) return false;
      final region = TuyaRegionHost.fromName(gw.credentials['region']);
      final client = TuyaCloudClient(
          clientId: clientId, clientSecret: clientSecret, region: region);
      final token = await client.getToken();
      if (token == null) return false;

      final chMatch = RegExp(r'^tuya_(.+)_ch(\d+)$').firstMatch(id);
      final String tuyaDeviceId;
      final String dpCode;
      if (chMatch != null) {
        tuyaDeviceId = chMatch.group(1)!;
        dpCode = 'switch_${chMatch.group(2)}';
      } else {
        tuyaDeviceId = id.substring('tuya_'.length);
        // A single (non-multi-gang) device's actual on/off DP — read back
        // from the raw DP dump TuyaCloudClient.fetchDevices already
        // stashed at import time, so this targets whichever code the
        // device really reports instead of guessing 'switch_1' for
        // everything.
        final knownDps =
            (device.attributes['tuyaDps'] as Map?)?.cast<String, dynamic>() ?? const {};
        dpCode = knownDps.containsKey('switch_1')
            ? 'switch_1'
            : knownDps.containsKey('switch')
                ? 'switch'
                : knownDps.containsKey('switch_led')
                    ? 'switch_led'
                    : 'switch_1';
      }

      final ok = await client.sendCommands(
        token: token,
        tuyaDeviceId: tuyaDeviceId,
        commands: [
          {'code': dpCode, 'value': on},
        ],
      );
      if (!ok) {
        // sendCommands only ever returned a bare bool — a rejected command
        // (wrong DP code for this device, Tuya project not authorized for
        // the command endpoint, device actually offline, ...) was
        // indistinguishable from "nothing happened, no idea why". Log
        // Tuya's real response so a failure like this is diagnosable
        // instead of a silent dead end.
        debugPrint('[Tuya] command failed for $id (dpCode=$dpCode): '
            '${TuyaCloudClient.lastCommandRawResponse}');
      }
      return ok;
    }

    // ── Tuya via a self-hosted FantaTech Hub (local-first + cloud fallback,
    // TuyaManager — see the hub's own /api/tuya/manager/control/{id}) ───────
    // Distinct id prefix from the direct-cloud 'tuya_' path above — a
    // GatewayType.localHub import (gateway_manager.dart) creates these, and
    // routes through the hub's own connection-mode/retry/fallback logic
    // instead of always hitting Tuya Cloud directly.
    if (id.startsWith('tuyahub_')) {
      final gw = _gateway(gateways, GatewayType.localHub);
      if (gw == null) return false;
      final ip     = gw.credentials['ip'];
      final port   = gw.credentials['port'] ?? '8080';
      final apiKey = gw.credentials['apiKey'];
      if (ip == null) return false;
      final hubDeviceId = id.substring('tuyahub_'.length);
      final client = HubRestClient(HubConfig(
        baseUrl: 'http://$ip:$port',
        apiKey:  (apiKey == null || apiKey.isEmpty) ? null : apiKey,
      ));
      final result = await client.post<Map<String, dynamic>>(
        '/api/tuya/manager/control/$hubDeviceId',
        {'payload': {'state': on ? 'ON' : 'OFF'}},
      );
      if (result is HubErr<Map<String, dynamic>>) {
        debugPrint('[TuyaHub] command failed for $id: ${result.error.message}');
        return false;
      }
      return true;
    }

    // ── LAN-direct (Shelly / Sonoff / Tuya / Kasa / Tapo / ESPHome) ────────────
    final ssd = _asSmartSwitch(device);
    if (ssd != null) {
      final ch = (device.attributes['channel'] as int?) ?? 0;
      return SwitchController.setOn(ssd, ch, on);
    }

    return false;
  }

  /// Set a single raw Tuya DP (data point) by code — e.g. a PIR sensor's
  /// vendor-specific sensitivity/delay/detection-range config, which has no
  /// normalized FantaTech capability (see [Device.attributes]'s 'tuyaDps'
  /// map, populated by [TuyaCloudClient.fetchDevices], for what a given
  /// device actually reports). Only works for Tuya Cloud devices (id prefix
  /// 'tuya_'); returns false for anything else. [value] must already be the
  /// correct type for that DP (bool/num/String) — Tuya rejects a mismatched
  /// command instead of coercing it.
  static Future<bool> setTuyaDp(
    Device device,
    String code,
    dynamic value, {
    required GatewayManager gateways,
  }) async {
    final auth = await _tuyaAuth(device.id, gateways);
    if (auth == null) return false;
    return auth.client.sendCommands(
      token: auth.token,
      tuyaDeviceId: auth.deviceId,
      commands: [
        {'code': code, 'value': value},
      ],
    );
  }

  /// Re-fetches every DP Tuya currently has for [device]. Tries the
  /// single-device status endpoint first (more reliable than the bulk list
  /// for most categories) — but that endpoint needs a Tuya API subscription
  /// some projects don't have (`code 28841105 "No permissions"` — a
  /// project-level authorization gap on iot.tuya.com, not fixable from the
  /// app). Falls back to [TuyaCloudClient.fetchDevices] — the same bulk
  /// associated-users/devices call already used for import, which needs no
  /// extra permission — and pulls this device's 'tuyaDps' back out of that
  /// result, so a project stuck on that permission gap can still populate
  /// the advanced-settings section instead of being blocked entirely. Used
  /// by the edit sheet's "advanced settings" refresh action. Returns null
  /// on total failure (no credentials, not a Tuya device, both paths
  /// erroring).
  static Future<Map<String, dynamic>?> refreshTuyaDps(
    Device device, {
    required GatewayManager gateways,
  }) async {
    final auth = await _tuyaAuth(device.id, gateways);
    if (auth == null) return null;

    final direct = await auth.client.fetchDeviceStatus(
        token: auth.token, tuyaDeviceId: auth.deviceId);
    if (direct != null && direct.isNotEmpty) return direct;

    final bulk = await TuyaCloudClient.fetchDevices(
      clientId: auth.client.clientId,
      clientSecret: auth.client.clientSecret,
      region: auth.client.region,
    );
    if (!bulk.isSuccess) return direct; // keep the direct-call diagnostic
    final matches = bulk.devices.where((d) => d.id == device.id);
    final match = matches.isEmpty ? null : matches.first;
    final dps = (match?.attributes['tuyaDps'] as Map?)?.cast<String, dynamic>();
    return dps ?? direct;
  }

  /// Shared credential/token lookup for the Tuya Cloud methods above.
  static Future<
      ({TuyaCloudClient client, String token, String deviceId})?> _tuyaAuth(
    String deviceId,
    GatewayManager gateways,
  ) async {
    if (!deviceId.startsWith('tuya_')) return null;
    final gw = _gateway(gateways, GatewayType.tuyaSmart) ??
        _gateway(gateways, GatewayType.smartLife);
    if (gw == null) return null;
    final clientId     = gw.credentials['clientId'];
    final clientSecret = gw.credentials['clientSecret'];
    if (clientId == null || clientSecret == null) return null;
    final region = TuyaRegionHost.fromName(gw.credentials['region']);
    final client = TuyaCloudClient(
        clientId: clientId, clientSecret: clientSecret, region: region);
    final token = await client.getToken();
    if (token == null) return null;
    // Strip a multi-gang channel suffix ('_chN') if present — every gang
    // of a multi-gang device is imported as its own Device
    // (tuya_<realId>_chN, see TuyaCloudClient's channelStates handling)
    // but they all share one underlying physical Tuya device id, which is
    // what the token/DP-refresh calls below actually need.
    final chMatch = RegExp(r'^tuya_(.+)_ch\d+$').firstMatch(deviceId);
    final realId = chMatch?.group(1) ?? deviceId.substring('tuya_'.length);
    return (
      client: client,
      token: token,
      deviceId: realId,
    );
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
    if (device.id.startsWith('ha_')) {
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

    // ── Tuya Cloud AC (category "kt", already correctly imported as
    // DeviceType.airConditioner — see tuya_cloud_client.dart's
    // _categoryToType) ──────────────────────────────────────────────────
    // Cloud's /commands endpoint takes named codes (unlike the local LAN
    // protocol's raw DP numbers), so this can reuse the same
    // TuyaCloudClient.sendCommands path the tuya_ setOnOff branch above
    // uses. Code names are Tuya's own documented standard instruction set
    // for category "kt" (temp_set, mode, fan_speed_enum, switch_horizontal)
    // — not invented — but real-world devices vary (same reason the switch
    // branch resolves switch_1/switch/switch_led instead of assuming one),
    // so this reads tuyaDps for whichever variant this specific device
    // actually reports before falling back to the documented default.
    // Unverified against a live Tuya AC — no such device was available to
    // test with; flag any failure via the debugPrint below rather than a
    // silent dead end, same as the switch branch already does.
    //
    // tuyahub_ (local-hub) ACs are NOT handled here — the hub's local
    // control path only accepts raw numeric Tuya DPs, and there's no
    // DatapointMapper yet to translate a named climate code into the
    // right number for an unknown device/model (see the tuya skill's
    // DatapointMapper note). Falls through to `return false` below,
    // same as any other unrouted device.
    if (device.id.startsWith('tuya_') && device.type == DeviceType.airConditioner) {
      final gw = _gateway(gateways, GatewayType.tuyaSmart) ??
          _gateway(gateways, GatewayType.smartLife);
      if (gw == null) return false;
      final clientId     = gw.credentials['clientId'];
      final clientSecret = gw.credentials['clientSecret'];
      if (clientId == null || clientSecret == null) return false;
      final region = TuyaRegionHost.fromName(gw.credentials['region']);
      final client = TuyaCloudClient(
          clientId: clientId, clientSecret: clientSecret, region: region);
      final token = await client.getToken();
      if (token == null) return false;

      final knownDps =
          (device.attributes['tuyaDps'] as Map?)?.cast<String, dynamic>() ?? const {};
      final chMatch = RegExp(r'^tuya_(.+)_ch(\d+)$').firstMatch(device.id);
      final tuyaDeviceId = chMatch?.group(1) ?? device.id.substring('tuya_'.length);

      Map<String, dynamic>? command;
      if (hvacMode != null) {
        final code = knownDps.containsKey('work_mode') ? 'work_mode' : 'mode';
        command = {'code': code, 'value': hvacMode};
      } else if (temperature != null) {
        final code = knownDps.containsKey('temp_set_f') ? 'temp_set_f' : 'temp_set';
        command = {'code': code, 'value': temperature.round()};
      } else if (fanMode != null) {
        final code = knownDps.containsKey('speed') ? 'speed' : 'fan_speed_enum';
        command = {'code': code, 'value': fanMode};
      } else if (swingMode != null) {
        final code = knownDps.containsKey('windspeed') ? 'windspeed' : 'switch_horizontal';
        command = {'code': code, 'value': swingMode == 'on'};
      }
      // presetMode has no standard Tuya "kt" DP equivalent (eco/away/boost
      // presets aren't part of Tuya's documented AC schema) — left
      // unhandled rather than guessing one, per project rule 9.
      if (command == null) return false;

      final ok = await client.sendCommands(
          token: token, tuyaDeviceId: tuyaDeviceId, commands: [command]);
      if (!ok) {
        debugPrint('[Tuya] climate command failed for ${device.id} ($command): '
            '${TuyaCloudClient.lastCommandRawResponse}');
      }
      return ok;
    }

    return false;
  }

  /// Set cover/blind/valve position 0–100 (100 = fully open). A
  /// [DeviceType.blind] can back either a real cover or an HA `valve`
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

    // ── IKEA DIRIGERA ──────────────────────────────────────────────────────
    if (device.id.startsWith('dirigera_')) {
      final gw = _gateway(gateways, GatewayType.dirigera);
      if (gw == null) return false;
      final ip    = gw.credentials['ip'];
      final token = gw.credentials['token'];
      if (ip == null || token == null) return false;
      // DIRIGERA's own blindsTargetLevel is inverted (0=open, 100=closed)
      // vs. FantaTech's convention (100=open) used everywhere else here.
      return DIRIGERAGatewayClient.setBlindLevel(
          ip, token, device.id, 100 - position.clamp(0, 100));
    }

    return false;
  }

  /// Stop a moving cover/blind/valve. HA only — DIRIGERA's local REST API
  /// doesn't expose a "stop mid-motion" endpoint (only target position),
  /// unlike setCoverPosition above which DIRIGERA does support directly.
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

  /// Send a robot-vacuum command (start / pause / return to dock).
  /// Supports direct-LAN iRobot and Xiaomi vacuums, plus any vacuum synced
  /// in via Home Assistant's `vacuum` domain.
  static Future<bool> vacuumCommand(
    Device device,
    VacuumAction action, {
    required GatewayManager gateways,
  }) async {
    final id = device.id;

    // ── iRobot (Roomba / Braava) — local MQTT ──────────────────────────────
    if (id.startsWith('irobot_')) {
      final ip       = device.attributes['ip'] as String?;
      final blid     = device.attributes['blid'] as String?;
      final password = device.attributes['password'] as String?;
      if (ip == null || blid == null || password == null) return false;
      final client = IRobotClient(ip: ip, blid: blid, password: password);
      return switch (action) {
        VacuumAction.start => client.start(),
        VacuumAction.pause => client.pause(),
        VacuumAction.dock  => client.dock(),
      };
    }

    // ── Xiaomi / Mi Robot Vacuum — local miIO ──────────────────────────────
    if (id.startsWith('xiaomi_vacuum_')) {
      final ip       = device.attributes['ip'] as String?;
      final vacToken = device.attributes['token'] as String?;
      if (ip == null || vacToken == null) return false;
      final client = XiaomiVacuumClient(ip: ip, token: vacToken);
      return switch (action) {
        VacuumAction.start => client.start(),
        VacuumAction.pause => client.pause(),
        VacuumAction.dock  => client.dock(),
      };
    }

    // ── Home Assistant `vacuum` domain ──────────────────────────────────────
    if (id.startsWith('ha_')) {
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

    return false;
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
    if (id.startsWith('aqara-')) {
      final ip    = device.attributes['aqaraIp'] as String?;
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
