// ─────────────────────────────────────────────────────────────────────────────
// SensorController
//
// Reads current state of motion / contact / environmental sensors.
//
// Protocol matrix:
//   Shelly Gen1    GET  http://ip/status          → sensor.state | sensor.motion
//   Shelly Gen2/3  POST http://ip/rpc/Input.GetStatus | Motion.GetStatus
//   ESPHome        GET  http://ip/binary_sensor/<entityId>
//   Home Assistant GET  http://ha:8123/api/states/<entityId>
//   Zigbee2MQTT    MQTT subscribe + GET request  zigbee2mqtt/<name>
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../gateways/clients/aqara_hub_client.dart';
import 'sensor_models.dart';

class SensorController {
  static const _timeout = Duration(seconds: 6);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns true = triggered / open, false = clear / closed, null = error.
  static Future<bool?> readState(SmartSensor sensor) async {
    try {
      return await _readState(sensor);
    } catch (_) {
      return null;
    }
  }

  /// Refresh all fields (state, battery, temperature, humidity) in-place.
  /// A failed refresh (timeout, HTTP error, exception) means the sensor is
  /// no longer reachable — flip isOnline so the UI stops showing a stale
  /// "connected" card for a device that's actually offline.
  static Future<bool> refresh(SmartSensor sensor) async {
    try {
      final ok = await _refresh(sensor);
      if (!ok) sensor.isOnline = false;
      return ok;
    } catch (_) {
      sensor.isOnline = false;
      return false;
    }
  }

  // ── State readers ─────────────────────────────────────────────────────────

  static Future<bool?> _readState(SmartSensor sensor) async {
    switch (sensor.protocol) {
      case SensorProtocol.shellyGen1:
        return _shellyGen1State(sensor.ip ?? '', sensor.type);

      case SensorProtocol.shellyGen2:
        return _shellyGen2State(
          sensor.ip ?? '',
          sensor.type,
          (sensor.connectionData['channelIdx'] as int?) ?? 0,
        );

      case SensorProtocol.esphome:
        return _espHomeState(
          sensor.ip ?? '',
          sensor.connectionData['entityId'] as String? ?? sensor.id,
        );

      case SensorProtocol.haRest:
        return _haState(sensor);

      case SensorProtocol.z2mMqtt:
        return _z2mState(sensor);

      case SensorProtocol.aqaraHub:
        return _aqaraState(sensor);

      case SensorProtocol.unknown:
        return null;
    }
  }

  // ── Full refresh ──────────────────────────────────────────────────────────

  static Future<bool> _refresh(SmartSensor sensor) async {
    final ip = sensor.ip ?? '';
    switch (sensor.protocol) {
      case SensorProtocol.shellyGen1:
        final r = await http
            .get(Uri.parse('http://$ip/status'))
            .timeout(_timeout);
        if (r.statusCode != 200) return false;
        final json = jsonDecode(r.body) as Map<String, dynamic>;

        // Door/Window sensor
        final sensorBlock = json['sensor'] as Map?;
        if (sensorBlock != null) {
          // motion overrides state
          final motion = sensorBlock['motion'] as bool?;
          if (motion != null) {
            sensor.isTriggered = motion;
          } else {
            sensor.isTriggered = sensorBlock['state'] as bool?;
          }
        }
        // Battery
        final bat = json['bat'] as Map?;
        if (bat != null) {
          sensor.batteryPercent = (bat['value'] as num?)?.toInt();
        }
        // Temperature (Door/Window 2 has thermometer)
        final tmp = json['tmp'] as Map?;
        sensor.temperature = (tmp?['tC'] as num?)?.toDouble();
        // Humidity
        final hum = json['hum'] as Map?;
        sensor.humidity = (hum?['value'] as num?)?.toDouble();

        sensor.isOnline = true;
        sensor.lastSeen = DateTime.now();
        return true;

      case SensorProtocol.haRest:
        final haIp   = sensor.connectionData['haIp']    as String?;
        final token  = sensor.connectionData['haToken'] as String?;
        final entity = sensor.connectionData['entityId'] as String?;
        if (haIp == null || token == null || entity == null) return false;
        final r = await http.get(
          Uri.parse('http://$haIp:8123/api/states/$entity'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(_timeout);
        if (r.statusCode != 200) return false;
        final json  = jsonDecode(r.body) as Map<String, dynamic>;
        final state = json['state'] as String?;
        // HA reports a real entity as "unavailable"/"unknown" when the
        // underlying device has dropped off — that's a live 200 response,
        // not an HTTP failure, so it needs its own offline check.
        if (state == 'unavailable' || state == 'unknown') return false;
        sensor.isTriggered = state == 'on';
        final attrs = json['attributes'] as Map?;
        if (attrs?['battery_level'] != null) {
          sensor.batteryPercent = (attrs!['battery_level'] as num).toInt();
        }
        sensor.isOnline = true;
        sensor.lastSeen = DateTime.now();
        return true;

      default:
        // For other protocols just read state
        final state = await _readState(sensor);
        if (state != null) {
          sensor.isTriggered = state;
          sensor.isOnline    = true;
          sensor.lastSeen    = DateTime.now();
          return true;
        }
        return false;
    }
  }

  // ── Protocol-specific readers ─────────────────────────────────────────────

  static Future<bool?> _shellyGen1State(String ip, SensorType type) async {
    final r = await http
        .get(Uri.parse('http://$ip/status'))
        .timeout(_timeout);
    if (r.statusCode != 200) return null;
    final json    = jsonDecode(r.body) as Map<String, dynamic>;
    final sensor  = json['sensor'] as Map?;
    if (sensor == null) return null;
    return type == SensorType.motion
        ? sensor['motion'] as bool?
        : sensor['state'] as bool?; // true = open (door/window)
  }

  static Future<bool?> _shellyGen2State(
      String ip, SensorType type, int idx) async {
    if (type == SensorType.motion) {
      // Shelly Plus Motion: /rpc/Motion.GetStatus
      final r = await http.post(
        Uri.parse('http://$ip/rpc/Motion.GetStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': idx}),
      ).timeout(_timeout);
      if (r.statusCode != 200) return null;
      return (jsonDecode(r.body) as Map<String, dynamic>)['motion'] as bool?;
    }
    // Door/Window or input
    final r = await http.post(
      Uri.parse('http://$ip/rpc/Input.GetStatus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': idx}),
    ).timeout(_timeout);
    if (r.statusCode != 200) return null;
    return (jsonDecode(r.body) as Map<String, dynamic>)['state'] as bool?;
  }

  static Future<bool?> _espHomeState(String ip, String entityId) async {
    final r = await http
        .get(Uri.parse('http://$ip/binary_sensor/$entityId'))
        .timeout(_timeout);
    if (r.statusCode != 200) return null;
    return (jsonDecode(r.body) as Map<String, dynamic>)['state'] == 'ON';
  }

  static Future<bool?> _haState(SmartSensor sensor) async {
    final haIp   = sensor.connectionData['haIp']    as String?;
    final token  = sensor.connectionData['haToken'] as String?;
    final entity = sensor.connectionData['entityId'] as String?;
    if (haIp == null || token == null || entity == null) return null;
    final r = await http.get(
      Uri.parse('http://$haIp:8123/api/states/$entity'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
    if (r.statusCode != 200) return null;
    return (jsonDecode(r.body) as Map)['state'] == 'on';
  }

  static Future<bool?> _z2mState(SmartSensor sensor) async {
    final host = sensor.connectionData['mqttHost']   as String?;
    final port = (sensor.connectionData['mqttPort']  as int?) ?? 1883;
    final user = sensor.connectionData['mqttUser']   as String?;
    final pass = sensor.connectionData['mqttPass']   as String?;
    final name = sensor.connectionData['deviceName'] as String?;
    if (host == null || name == null) return null;

    final clientId = 'ft_sr_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(host, clientId, port)
      ..keepAlivePeriod = 10
      ..connectTimeoutPeriod = 3000
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
        return null;
      }

      client.subscribe('zigbee2mqtt/$name', MqttQos.atMostOnce);

      // Request current state
      final getBuilder = MqttClientPayloadBuilder()..addString('{}');
      client.publishMessage(
        'zigbee2mqtt/$name/get',
        MqttQos.atMostOnce,
        getBuilder.payload!,
      );

      bool? result;
      final completer = Completer<bool?>();

      client.updates?.listen((events) {
        for (final event in events) {
          final msg = event.payload;
          if (msg is! MqttPublishMessage) continue;
          final payload = MqttPublishPayload.bytesToStringAsString(
              msg.payload.message);
          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            if (sensor.type == SensorType.motion) {
              result = json['occupancy'] as bool?;
            } else if (sensor.type == SensorType.contact) {
              // contact: true = closed, false = open → isTriggered = open = !contact
              final contact = json['contact'] as bool?;
              result = contact != null ? !contact : null;
            } else {
              result = json['state'] == 'on' || json['occupancy'] == true;
            }
            if (!completer.isCompleted) completer.complete(result);
          } catch (_) {}
        }
      });

      await Future.any([
        completer.future,
        Future<void>.delayed(const Duration(seconds: 3)),
      ]);

      return result;
    } catch (_) {
      return null;
    } finally {
      try { client.disconnect(); } catch (_) {}
    }
  }

  static Future<bool?> _aqaraState(SmartSensor sensor) async {
    final ip    = sensor.connectionData['aqaraIp']    as String?;
    final token = sensor.connectionData['aqaraToken'] as String?;
    final did   = sensor.connectionData['did']        as String?;
    if (ip == null || token == null || did == null) return null;
    try {
      final devices = await AqaraHubClient(ip: ip, accessToken: token).getDevices();
      final d = devices.firstWhere(
        (d) => (d['did'] as String?) == did,
        orElse: () => <String, dynamic>{},
      );
      if (d.isEmpty) return null;
      final attrs = d['attrs'] as Map<String, dynamic>?;
      if (attrs == null) return null;
      if (sensor.type == SensorType.motion) {
        return attrs['occupancy'] as bool? ??
               ((attrs['motionStatus'] ?? attrs['motion_status'] ?? 0) as num) > 0;
      }
      if (sensor.type == SensorType.contact) {
        final open = attrs['windowState'] ?? attrs['doorState'] ??
                     attrs['contactState'] ?? attrs['open'];
        if (open is bool) return open;
        if (open is int)  return open == 1;
        if (open is String) return open == 'open' || open == '1';
        return null;
      }
      if (sensor.type == SensorType.smoke) {
        final alarm = attrs['smokeAlarm'] ?? attrs['smoke'] ?? attrs['gasAlarm'] ?? attrs['gas'];
        if (alarm is bool) return alarm;
        if (alarm is int)  return alarm == 1;
        return null;
      }
      if (sensor.type == SensorType.water) {
        final leak = attrs['waterImmersionState'] ?? attrs['water_leak'] ?? attrs['leak'];
        if (leak is bool) return leak;
        if (leak is int)  return leak == 1;
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
