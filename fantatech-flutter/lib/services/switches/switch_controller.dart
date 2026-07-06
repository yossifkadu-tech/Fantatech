// ─────────────────────────────────────────────────────────────────────────────
// SwitchController
//
// Protocol-aware toggle / state-read for every supported switch brand.
//
// Toggle matrix:
//   Shelly Gen1      GET  http://ip/relay/N?turn=toggle
//   Shelly Gen2/3    POST http://ip/rpc/Switch.Toggle   {"id":N}
//   Sonoff DIY v2    POST http://ip:8081/zeroconf/switch {"data":{"switch":"on"}}
//   ESPHome          POST http://ip/switch/<entityId>/toggle
//   Home Assistant   POST http://ha:8123/api/services/switch/toggle
//   Zigbee2MQTT      MQTT publish  zigbee2mqtt/<name>/set  {"state":"TOGGLE"}
//   TP-Link Kasa     TCP 9999  XOR-cipher {"system":{"set_relay_state":{"state":1}}}
//   Tuya / Tapo      requires encrypted local key → show instructions only
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'smart_switch_models.dart';
import 'tapo_local_controller.dart';
import 'tuya_local_controller.dart';

class SwitchController {
  static const _timeout = Duration(seconds: 6);

  // ── Public: toggle one channel ──────────────────────────────────────────────

  /// Returns true on success.  Does not throw.
  static Future<bool> toggle(SmartSwitchDevice device, int channelIdx) async {
    try {
      return await _dispatch(device, channelIdx, null);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setOn(
      SmartSwitchDevice device, int channelIdx, bool on) async {
    try {
      return await _dispatch(device, channelIdx, on);
    } catch (_) {
      return false;
    }
  }

  /// Read current state for a channel.  Returns null on failure.
  static Future<bool?> readState(
      SmartSwitchDevice device, int channelIdx) async {
    try {
      return await _readState(device, channelIdx);
    } catch (_) {
      return null;
    }
  }

  // ── Dispatch ─────────────────────────────────────────────────────────────────

  static Future<bool> _dispatch(
      SmartSwitchDevice dev, int ch, bool? on) async {
    final ip = dev.ip ?? '';
    switch (dev.protocol) {
      // ── Shelly Gen1 ──────────────────────────────────────────────────────────
      case SwitchProtocol.shellyGen1:
        final action = on == null ? 'toggle' : (on ? 'on' : 'off');
        final r = await http
            .get(Uri.parse('http://$ip/relay/$ch?turn=$action'))
            .timeout(_timeout);
        return r.statusCode == 200;

      // ── Shelly Gen2 / Gen3 ──────────────────────────────────────────────────
      case SwitchProtocol.shellyGen2:
      case SwitchProtocol.shellyGen3:
        if (on == null) {
          final r = await http
              .post(Uri.parse('http://$ip/rpc/Switch.Toggle'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': ch}))
              .timeout(_timeout);
          return r.statusCode == 200;
        } else {
          final r = await http
              .post(Uri.parse('http://$ip/rpc/Switch.Set'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': ch, 'on': on}))
              .timeout(_timeout);
          return r.statusCode == 200;
        }

      // ── Sonoff DIY v2 ────────────────────────────────────────────────────────
      case SwitchProtocol.sonoffLan:
        final deviceId = dev.connectionData['deviceId'] as String? ?? '';
        final sw = on == null
            ? null
            : (on ? 'on' : 'off'); // null → will read current and flip
        String switchVal = sw ?? 'off';
        if (sw == null) {
          // Read current state first, then flip
          final state = await readState(dev, ch);
          switchVal = (state == true) ? 'off' : 'on';
        }
        final r = await http
            .post(
              Uri.parse('http://$ip:8081/zeroconf/switch'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'deviceid': deviceId,
                'data': {'switch': switchVal},
              }),
            )
            .timeout(_timeout);
        return r.statusCode == 200;

      // ── ESPHome ──────────────────────────────────────────────────────────────
      case SwitchProtocol.esphome:
        final entityId =
            (dev.connectionData['entityIds'] as List<dynamic>?)?[ch]
                    as String? ??
                dev.connectionData['entityId'] as String? ??
                'switch';
        final action = on == null ? 'toggle' : (on ? 'turn_on' : 'turn_off');
        final r = await http
            .post(Uri.parse('http://$ip/switch/$entityId/$action'))
            .timeout(_timeout);
        return r.statusCode == 200;

      // ── Home Assistant REST ──────────────────────────────────────────────────
      case SwitchProtocol.haRest:
        final haIp    = dev.connectionData['haIp']    as String?;
        final token   = dev.connectionData['haToken'] as String?;
        final entityId = dev.connectionData['entityId'] as String?;
        if (haIp == null || token == null || entityId == null) return false;

        final domain = entityId.startsWith('light.') ? 'light' : 'switch';
        final action = on == null ? 'toggle' : (on ? 'turn_on' : 'turn_off');
        final r = await http
            .post(
              Uri.parse('http://$haIp:8123/api/services/$domain/$action'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'entity_id': entityId}),
            )
            .timeout(_timeout);
        return r.statusCode == 200;

      // ── Zigbee2MQTT ──────────────────────────────────────────────────────────
      case SwitchProtocol.z2mMqtt:
        return _z2mToggle(dev, on);

      // ── TP-Link Kasa (XOR cipher) ────────────────────────────────────────────
      case SwitchProtocol.kasaLocal:
        return _kasaSet(ip, on == null ? null : on);

      // ── Tuya Local Protocol 3.3 ──────────────────────────────────────────────
      case SwitchProtocol.tuyaLocal:
        final localKey = dev.connectionData['localKey'] as String?;
        final devId    = dev.connectionData['devId']    as String?;
        if (localKey == null || devId == null) return false; // key not yet configured
        return TuyaLocalController.setSwitch(
          ip, devId, localKey,
          on: on,
          dpsIndex: (dev.connectionData['dpsIndex'] as int?) ?? 1,
        );

      // ── Tapo local (RSA handshake + AES-CBC session) ─────────────────────
      case SwitchProtocol.tapoLocal:
        final email    = dev.connectionData['tapoEmail']    as String?;
        final password = dev.connectionData['tapoPassword'] as String?;
        if (email == null || password == null) return false;
        return TapoLocalController.setSwitch(ip, email, password, on: on);

      // ── New manufacturers — handled by DeviceCommander before reaching here ──
      // If somehow called directly, return false (no credentials available here).
      case SwitchProtocol.merossLan:
      case SwitchProtocol.broadlinkIr:
      case SwitchProtocol.goveeLan:
      case SwitchProtocol.yeelightLan:
      case SwitchProtocol.wizLan:
      case SwitchProtocol.lifxCloud:
      case SwitchProtocol.nanoleaf:
      case SwitchProtocol.aqaraHub:
      case SwitchProtocol.unknown:
        return false;
    }
  }

  // ── Read state ────────────────────────────────────────────────────────────────

  static Future<bool?> _readState(SmartSwitchDevice dev, int ch) async {
    final ip = dev.ip ?? '';
    switch (dev.protocol) {
      case SwitchProtocol.shellyGen1:
        final r = await http
            .get(Uri.parse('http://$ip/status'))
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        final relays = json['relays'] as List?;
        return relays != null && ch < relays.length
            ? relays[ch]['ison'] as bool?
            : null;

      case SwitchProtocol.shellyGen2:
      case SwitchProtocol.shellyGen3:
        final r = await http
            .post(Uri.parse('http://$ip/rpc/Switch.GetStatus'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'id': ch}))
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        return (jsonDecode(r.body) as Map<String, dynamic>)['output'] as bool?;

      case SwitchProtocol.sonoffLan:
        final r = await http
            .get(Uri.parse('http://$ip:8081/zeroconf/info'))
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        final data =
            (jsonDecode(r.body) as Map<String, dynamic>)['data'] as Map?;
        return data?['switch'] == 'on';

      case SwitchProtocol.esphome:
        final entityId =
            (dev.connectionData['entityIds'] as List<dynamic>?)?[ch]
                    as String? ??
                dev.connectionData['entityId'] as String? ??
                'switch';
        final r = await http
            .get(Uri.parse('http://$ip/switch/$entityId'))
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        return (jsonDecode(r.body) as Map)['state'] == 'on';

      case SwitchProtocol.haRest:
        final haIp    = dev.connectionData['haIp']    as String?;
        final token   = dev.connectionData['haToken'] as String?;
        final entityId = dev.connectionData['entityId'] as String?;
        if (haIp == null || token == null || entityId == null) return null;
        final r = await http
            .get(
              Uri.parse('http://$haIp:8123/api/states/$entityId'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        return (jsonDecode(r.body) as Map)['state'] == 'on';

      case SwitchProtocol.kasaLocal:
        final info = await _kasaGetSysinfo(ip);
        if (info == null) return null;
        return info['relay_state'] == 1;

      case SwitchProtocol.tuyaLocal:
        final localKey = dev.connectionData['localKey'] as String?;
        final devId    = dev.connectionData['devId']    as String?;
        if (localKey == null || devId == null) return null;
        final dps = await TuyaLocalController.getStatus(ip, devId, localKey);
        final idx = (dev.connectionData['dpsIndex'] as int?) ?? 1;
        return dps?[idx.toString()] as bool?;

      case SwitchProtocol.tapoLocal:
        final email    = dev.connectionData['tapoEmail']    as String?;
        final password = dev.connectionData['tapoPassword'] as String?;
        if (email == null || password == null) return null;
        return TapoLocalController.getState(ip, email, password);

      default:
        return null;
    }
  }

  // ── Zigbee2MQTT helper ────────────────────────────────────────────────────────

  static Future<bool> _z2mToggle(SmartSwitchDevice dev, bool? on) async {
    final host       = dev.connectionData['mqttHost'] as String?;
    final port       = (dev.connectionData['mqttPort'] as int?) ?? 1883;
    final user       = dev.connectionData['mqttUser'] as String?;
    final pass       = dev.connectionData['mqttPass'] as String?;
    final deviceName = dev.connectionData['deviceName'] as String?;
    if (host == null || deviceName == null) return false;

    final clientId = 'ft_ctrl_${DateTime.now().millisecondsSinceEpoch}';
    final client   = MqttServerClient.withPort(host, clientId, port)
      ..keepAlivePeriod    = 10
      ..connectTimeoutPeriod = 5000
      ..logging(on: false);

    if (user != null && user.isNotEmpty) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(user, pass ?? '')
          .startClean();
    } else {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
    }

    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return false;
      }
      final payload = on == null
          ? '{"state":"TOGGLE"}'
          : '{"state":"${on ? 'ON' : 'OFF'}"}';
      final builder = MqttClientPayloadBuilder()..addString(payload);
      client.publishMessage(
        'zigbee2mqtt/$deviceName/set',
        MqttQos.atMostOnce,
        builder.payload!,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (_) {
      return false;
    } finally {
      try { client.disconnect(); } catch (_) {}
    }
  }

  // ── TP-Link Kasa XOR cipher ───────────────────────────────────────────────────
  // Reference: https://github.com/softScheck/tplink-smartplug

  static Uint8List _kasaEncrypt(String data) {
    final bytes  = utf8.encode(data);
    final result = Uint8List(bytes.length + 4);
    // 4-byte big-endian length prefix
    result[0] = (bytes.length >> 24) & 0xFF;
    result[1] = (bytes.length >> 16) & 0xFF;
    result[2] = (bytes.length >> 8)  & 0xFF;
    result[3] =  bytes.length        & 0xFF;

    int key = 171;
    for (int i = 0; i < bytes.length; i++) {
      key = key ^ bytes[i];
      result[i + 4] = key;
    }
    return result;
  }

  static String _kasaDecrypt(List<int> data) {
    // Skip 4-byte length prefix
    final start = data.length > 4 ? 4 : 0;
    int key = 171;
    final sb = StringBuffer();
    for (int i = start; i < data.length; i++) {
      final decrypted = key ^ data[i];
      key = data[i];
      sb.writeCharCode(decrypted);
    }
    return sb.toString();
  }

  static Future<Map<String, dynamic>?> _kasaSend(
      String ip, String cmd) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, 9999,
          timeout: const Duration(milliseconds: 2500));
      socket.add(_kasaEncrypt(cmd));
      await socket.flush();

      final buffer = <int>[];
      await socket
          .listen(buffer.addAll)
          .asFuture<void>()
          .timeout(const Duration(seconds: 3));

      final text = _kasaDecrypt(buffer);
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  static Future<Map<String, dynamic>?> _kasaGetSysinfo(String ip) async {
    final resp = await _kasaSend(
        ip, '{"system":{"get_sysinfo":{}}}');
    return (resp?['system']?['get_sysinfo'] as Map<String, dynamic>?);
  }

  static Future<bool> _kasaSet(String ip, bool? on) async {
    bool state;
    if (on != null) {
      state = on;
    } else {
      final info = await _kasaGetSysinfo(ip);
      state = !(info?['relay_state'] == 1);
    }
    final resp = await _kasaSend(
        ip,
        '{"system":{"set_relay_state":{"state":${state ? 1 : 0}}}}');
    return resp?['system']?['set_relay_state']?['err_code'] == 0;
  }

  // ── Utility: TCP port probe ───────────────────────────────────────────────────

  static Future<bool> probeTcp(String ip, int port,
      {Duration timeout = const Duration(milliseconds: 700)}) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      s?.destroy();
    }
  }
}
