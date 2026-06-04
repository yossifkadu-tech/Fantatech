// ─────────────────────────────────────────────────────────────────────────────
// Zigbee2MQTTClient  — REST API (port 8080 by default)
//
// Enable REST API in Z2M config:  frontend: {port: 8080}
//   (or standalone: api_key: "secret")
//
//   GET  http://[ip]:[port]/api/health     → {"healthy":true}
//   GET  http://[ip]:[port]/api/devices    → [{friendly_name, definition, …}]
//
// Header: x-api-token: [token]  (only if api_key configured)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../../models/device.dart';
import '../../../services/discovery/device_classifier.dart';
import '../gateway_model.dart';

class Z2MGatewayClient {
  static const _timeout = Duration(seconds: 8);

  // ── Health check ───────────────────────────────────────────────────────────

  static Future<bool> isHealthy(String ip, int port, {String? token}) async {
    try {
      final raw = await _get(ip, port, '/api/health', token);
      return raw != null && raw.contains('healthy');
    } catch (_) {
      return false;
    }
  }

  // ── Import devices ─────────────────────────────────────────────────────────

  static Future<GatewayImportResult> fetchDevices(
      String ip, int port, {String? token}) async {
    try {
      final raw = await _get(ip, port, '/api/devices', token);
      if (raw == null) return const GatewayImportResult.failure('אין תגובה מ-Zigbee2MQTT');

      final List<dynamic> list;
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        if (raw.contains('Unauthorized') || raw.contains('401')) {
          return const GatewayImportResult.failure('API Token שגוי');
        }
        return const GatewayImportResult.failure('תגובה לא תקינה מ-Z2M');
      }

      final devices = <Device>[];
      for (final item in list) {
        final d = item as Map<String, dynamic>;

        // Skip the coordinator itself
        final devType = d['type'] as String? ?? '';
        if (devType == 'Coordinator') continue;

        final name   = d['friendly_name'] as String? ?? d['ieee_address'] as String? ?? 'Z2M Device';
        final def    = (d['definition'] as Map?)?.cast<String, dynamic>();
        final vendor = def?['vendor'] as String?;
        final model  = def?['model']  as String?;
        final desc   = def?['description'] as String? ?? '';
        final power  = d['power_source'] as String? ?? '';
        final ieee   = d['ieee_address'] as String? ?? '';

        final discType = DeviceClassifier.classifyFromWifi(
          name:         name,
          openPorts:    [],
          manufacturer: vendor,
          banner:       '$desc $model $name',
        );
        final appType = DeviceClassifier.toAppType(discType);

        devices.add(Device(
          id:         'z2m_${ieee.replaceAll('0x', '')}',
          name:       name,
          type:       appType,
          isOn:       false,
          status:     (d['interview_completed'] as bool? ?? false)
              ? DeviceStatus.online
              : DeviceStatus.offline,
          attributes: {
            'ip':            ip,
            'ieee':          ieee,
            'friendlyName':  name,   // needed for MQTT control
            'manufacturer':  vendor ?? '',
            'model':         model  ?? '',
            'powerSource':   power,
            'protocol':      'zigbee',
          },
        ));
      }

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאת Z2M: $e');
    }
  }

  // ── Device control (via MQTT publish) ──────────────────────────────────────
  //
  // Z2M control happens by publishing JSON to:
  //   zigbee2mqtt/{friendly_name}/set
  //
  // Examples:
  //   {"state": "ON"}                 — turn on
  //   {"state": "OFF"}                — turn off
  //   {"brightness": 200}             — 0..254
  //   {"color": {"hex": "#ff0000"}}   — color
  //   {"color_temp": 250}             — mireds
  //
  // Internal IDs are prefixed "z2m_" + ieee-without-0x. We don't keep the
  // friendly_name in attributes today, so callers should pass it explicitly.

  /// One-shot publish — connects, sends, disconnects.
  /// Returns true if MQTT accepted the publish.
  static Future<bool> _publishSet({
    required String mqttHost,
    int             mqttPort     = 1883,
    String?         mqttUser,
    String?         mqttPass,
    required String friendlyName,
    required Map<String, dynamic> payload,
    String          baseTopic    = 'zigbee2mqtt',
  }) async {
    final clientId = 'fantatech_ctrl_${DateTime.now().microsecondsSinceEpoch}';
    final client = MqttServerClient.withPort(mqttHost, clientId, mqttPort)
      ..keepAlivePeriod        = 10
      ..connectTimeoutPeriod   = 5000
      ..logging(on: false)
      ..autoReconnect          = false;

    var conn = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();
    if (mqttUser != null && mqttUser.isNotEmpty) {
      conn = conn.authenticateAs(mqttUser, mqttPass ?? '');
    }
    client.connectionMessage = conn;

    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        client.disconnect();
        return false;
      }

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));
      client.publishMessage(
        '$baseTopic/$friendlyName/set',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      // Give the broker a moment to ACK before we tear down.
      await Future.delayed(const Duration(milliseconds: 300));
      client.disconnect();
      return true;
    } catch (_) {
      try { client.disconnect(); } catch (_) {}
      return false;
    }
  }

  static Future<bool> setOnOff({
    required String mqttHost,
    int             mqttPort = 1883,
    String?         mqttUser,
    String?         mqttPass,
    required String friendlyName,
    required bool   isOn,
  }) =>
      _publishSet(
        mqttHost: mqttHost, mqttPort: mqttPort,
        mqttUser: mqttUser, mqttPass: mqttPass,
        friendlyName: friendlyName,
        payload: {'state': isOn ? 'ON' : 'OFF'},
      );

  /// Brightness 0..100 (mapped to Z2M 0..254).
  static Future<bool> setBrightness({
    required String mqttHost,
    int             mqttPort = 1883,
    String?         mqttUser,
    String?         mqttPass,
    required String friendlyName,
    required int    level,
  }) =>
      _publishSet(
        mqttHost: mqttHost, mqttPort: mqttPort,
        mqttUser: mqttUser, mqttPass: mqttPass,
        friendlyName: friendlyName,
        payload: {
          'state': 'ON',
          'brightness': (level.clamp(1, 100) * 2.54).round(),
        },
      );

  static Future<bool> setColorTemperature({
    required String mqttHost,
    int             mqttPort = 1883,
    String?         mqttUser,
    String?         mqttPass,
    required String friendlyName,
    required int    mireds,
  }) =>
      _publishSet(
        mqttHost: mqttHost, mqttPort: mqttPort,
        mqttUser: mqttUser, mqttPass: mqttPass,
        friendlyName: friendlyName,
        payload: {'color_temp': mireds.clamp(150, 500)},
      );

  static Future<bool> setColorHex({
    required String mqttHost,
    int             mqttPort = 1883,
    String?         mqttUser,
    String?         mqttPass,
    required String friendlyName,
    required String hex, // "#ff0000"
  }) =>
      _publishSet(
        mqttHost: mqttHost, mqttPort: mqttPort,
        mqttUser: mqttUser, mqttPass: mqttPass,
        friendlyName: friendlyName,
        payload: {'color': {'hex': hex}},
      );

  /// Generic escape hatch — caller controls the payload shape.
  static Future<bool> sendRawSet({
    required String mqttHost,
    int             mqttPort = 1883,
    String?         mqttUser,
    String?         mqttPass,
    required String friendlyName,
    required Map<String, dynamic> payload,
  }) =>
      _publishSet(
        mqttHost: mqttHost, mqttPort: mqttPort,
        mqttUser: mqttUser, mqttPass: mqttPass,
        friendlyName: friendlyName,
        payload: payload,
      );

  // ── HTTP helper ────────────────────────────────────────────────────────────

  static Future<String?> _get(
      String ip, int port, String path, String? token) async {
    try {
      final sock = await Socket.connect(ip, port, timeout: _timeout);
      final req  = StringBuffer()
        ..write('GET $path HTTP/1.0\r\n')
        ..write('Host: $ip:$port\r\n')
        ..write('Accept: application/json\r\n');
      if (token != null && token.isNotEmpty) {
        req.write('x-api-token: $token\r\n');
      }
      req.write('\r\n');
      sock.write(req.toString());
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          _timeout, onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) break;
      }
      await sock.close();
      final raw = utf8.decode(bytes, allowMalformed: true);
      final sep = raw.indexOf('\r\n\r\n');
      return sep >= 0 ? raw.substring(sep + 4) : raw;
    } catch (_) {
      return null;
    }
  }
}
