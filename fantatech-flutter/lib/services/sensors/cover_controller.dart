// ─────────────────────────────────────────────────────────────────────────────
// CoverController
//
// Open / close / stop / set-position for smart covers (shutters, blinds).
//
// Protocol matrix:
//   Shelly 2.5 Gen1    GET  http://ip/roller/0?go=open|close|stop|to_pos&roller_pos=N
//   Shelly Plus Gen2/3 POST http://ip/rpc/Cover.Open|Close|Stop|GoToPosition
//   ESPHome            POST http://ip/cover/<id>/open|close|stop
//                      POST http://ip/cover/<id>/set  {"position":0.5}
//   Home Assistant     POST http://ha:8123/api/services/cover/open_cover|…
//   Zigbee2MQTT        MQTT publish  zigbee2mqtt/<name>/set  {"state":"OPEN"}
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'sensor_models.dart';

typedef CoverStatus = ({CoverState state, int? position});

class CoverController {
  static const _timeout = Duration(seconds: 6);

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<bool> open(SmartCover cover) =>
      _dispatch(cover, _CoverCmd.open, null);

  static Future<bool> close(SmartCover cover) =>
      _dispatch(cover, _CoverCmd.close, null);

  static Future<bool> stop(SmartCover cover) =>
      _dispatch(cover, _CoverCmd.stop, null);

  static Future<bool> setPosition(SmartCover cover, int pos) =>
      _dispatch(cover, _CoverCmd.position, pos.clamp(0, 100));

  static Future<CoverStatus?> readState(SmartCover cover) async {
    try {
      return await _readState(cover);
    } catch (_) {
      return null;
    }
  }

  // ── Dispatch ──────────────────────────────────────────────────────────────

  static Future<bool> _dispatch(
      SmartCover cover, _CoverCmd cmd, int? pos) async {
    try {
      final ip = cover.ip ?? '';
      switch (cover.protocol) {
        // ── Shelly 2.5 Gen1 roller ──────────────────────────────────────────
        case CoverProtocol.shellyGen1Roller:
          final query = switch (cmd) {
            _CoverCmd.open     => 'go=open',
            _CoverCmd.close    => 'go=close',
            _CoverCmd.stop     => 'go=stop',
            _CoverCmd.position => 'go=to_pos&roller_pos=$pos',
          };
          final r = await http
              .get(Uri.parse('http://$ip/roller/0?$query'))
              .timeout(_timeout);
          return r.statusCode == 200;

        // ── Shelly Plus / Pro Gen2/3 cover ──────────────────────────────────
        case CoverProtocol.shellyGen2Cover:
        case CoverProtocol.shellyGen3Cover:
          final method = switch (cmd) {
            _CoverCmd.open     => 'Cover.Open',
            _CoverCmd.close    => 'Cover.Close',
            _CoverCmd.stop     => 'Cover.Stop',
            _CoverCmd.position => 'Cover.GoToPosition',
          };
          final body = cmd == _CoverCmd.position
              ? jsonEncode({'id': 0, 'pos': pos})
              : jsonEncode({'id': 0});
          final r = await http
              .post(
                Uri.parse('http://$ip/rpc/$method'),
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(_timeout);
          return r.statusCode == 200;

        // ── ESPHome cover ───────────────────────────────────────────────────
        case CoverProtocol.esphome:
          final entityId =
              cover.connectionData['entityId'] as String? ?? 'cover';
          if (cmd == _CoverCmd.position) {
            // ESPHome cover /set expects 0.0–1.0
            final r = await http
                .post(
                  Uri.parse('http://$ip/cover/$entityId/set'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'position': pos! / 100.0}),
                )
                .timeout(_timeout);
            return r.statusCode == 200;
          }
          final action = switch (cmd) {
            _CoverCmd.open  => 'open',
            _CoverCmd.close => 'close',
            _CoverCmd.stop  => 'stop',
            _               => 'stop',
          };
          final r = await http
              .post(Uri.parse('http://$ip/cover/$entityId/$action'))
              .timeout(_timeout);
          return r.statusCode == 200;

        // ── Home Assistant ──────────────────────────────────────────────────
        case CoverProtocol.haRest:
          final haIp   = cover.connectionData['haIp']    as String?;
          final token  = cover.connectionData['haToken'] as String?;
          final entity = cover.connectionData['entityId'] as String?;
          if (haIp == null || token == null || entity == null) return false;

          if (cmd == _CoverCmd.position) {
            final r = await http
                .post(
                  Uri.parse(
                      'http://$haIp:8123/api/services/cover/set_cover_position'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({'entity_id': entity, 'position': pos}),
                )
                .timeout(_timeout);
            return r.statusCode == 200;
          }

          final svc = switch (cmd) {
            _CoverCmd.open  => 'open_cover',
            _CoverCmd.close => 'close_cover',
            _CoverCmd.stop  => 'stop_cover',
            _               => 'stop_cover',
          };
          final r = await http
              .post(
                Uri.parse('http://$haIp:8123/api/services/cover/$svc'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'entity_id': entity}),
              )
              .timeout(_timeout);
          return r.statusCode == 200;

        // ── Zigbee2MQTT ─────────────────────────────────────────────────────
        case CoverProtocol.z2mMqtt:
          return _z2mDispatch(cover, cmd, pos);

        case CoverProtocol.unknown:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  // ── Read state ────────────────────────────────────────────────────────────

  static Future<CoverStatus?> _readState(SmartCover cover) async {
    final ip = cover.ip ?? '';
    switch (cover.protocol) {
      case CoverProtocol.shellyGen1Roller:
        final r = await http
            .get(Uri.parse('http://$ip/roller/0'))
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        return (
          state:    _parseShellyState(json['state'] as String?),
          position: (json['current_pos'] as num?)?.toInt(),
        );

      case CoverProtocol.shellyGen2Cover:
      case CoverProtocol.shellyGen3Cover:
        final r = await http
            .post(
              Uri.parse('http://$ip/rpc/Cover.GetStatus'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'id': 0}),
            )
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        return (
          state:    _parseShellyState(json['state'] as String?),
          position: (json['current_pos'] as num?)?.toInt(),
        );

      case CoverProtocol.esphome:
        final entityId =
            cover.connectionData['entityId'] as String? ?? 'cover';
        final r = await http
            .get(Uri.parse('http://$ip/cover/$entityId'))
            .timeout(_timeout);
        if (r.statusCode != 200) return null;
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        final posRaw = (json['position'] as num?)?.toDouble();
        return (
          state:    _parseHaState(json['state'] as String?),
          position: posRaw != null ? (posRaw * 100).round() : null,
        );

      case CoverProtocol.haRest:
        final haIp   = cover.connectionData['haIp']    as String?;
        final token  = cover.connectionData['haToken'] as String?;
        final entity = cover.connectionData['entityId'] as String?;
        if (haIp == null || token == null || entity == null) return null;
        final r = await http.get(
          Uri.parse('http://$haIp:8123/api/states/$entity'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(_timeout);
        if (r.statusCode != 200) return null;
        final json  = jsonDecode(r.body) as Map<String, dynamic>;
        final attrs = json['attributes'] as Map?;
        return (
          state:    _parseHaState(json['state'] as String?),
          position: attrs?['current_position'] as int?,
        );

      case CoverProtocol.z2mMqtt:
        return _z2mReadState(cover);

      case CoverProtocol.unknown:
        return null;
    }
  }

  // ── State parsers ─────────────────────────────────────────────────────────

  static CoverState _parseShellyState(String? s) => switch (s) {
        'open'    => CoverState.open,
        'close'   => CoverState.closed,
        'closed'  => CoverState.closed,
        'opening' => CoverState.opening,
        'closing' => CoverState.closing,
        'stop'    => CoverState.stopped,
        'stopped' => CoverState.stopped,
        _         => CoverState.unknown,
      };

  static CoverState _parseHaState(String? s) => switch (s) {
        'open'    => CoverState.open,
        'closed'  => CoverState.closed,
        'opening' => CoverState.opening,
        'closing' => CoverState.closing,
        _         => CoverState.unknown,
      };

  // ── Zigbee2MQTT helpers ───────────────────────────────────────────────────

  static Future<bool> _z2mDispatch(
      SmartCover cover, _CoverCmd cmd, int? pos) async {
    final host = cover.connectionData['mqttHost']   as String?;
    final port = (cover.connectionData['mqttPort']  as int?) ?? 1883;
    final user = cover.connectionData['mqttUser']   as String?;
    final pass = cover.connectionData['mqttPass']   as String?;
    final name = cover.connectionData['deviceName'] as String?;
    if (host == null || name == null) return false;

    final clientId = 'ft_cv_${DateTime.now().millisecondsSinceEpoch}';
    final client = _buildMqttClient(host, clientId, port, user, pass);

    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return false;
      }

      final payload = cmd == _CoverCmd.position
          ? '{"position":$pos}'
          : switch (cmd) {
              _CoverCmd.open  => '{"state":"OPEN"}',
              _CoverCmd.close => '{"state":"CLOSE"}',
              _CoverCmd.stop  => '{"state":"STOP"}',
              _               => '{"state":"STOP"}',
            };

      final builder = MqttClientPayloadBuilder()..addString(payload);
      client.publishMessage(
          'zigbee2mqtt/$name/set', MqttQos.atMostOnce, builder.payload!);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (_) {
      return false;
    } finally {
      try { client.disconnect(); } catch (_) {}
    }
  }

  static Future<CoverStatus?> _z2mReadState(SmartCover cover) async {
    final host = cover.connectionData['mqttHost']   as String?;
    final port = (cover.connectionData['mqttPort']  as int?) ?? 1883;
    final user = cover.connectionData['mqttUser']   as String?;
    final pass = cover.connectionData['mqttPass']   as String?;
    final name = cover.connectionData['deviceName'] as String?;
    if (host == null || name == null) return null;

    final clientId = 'ft_cvr_${DateTime.now().millisecondsSinceEpoch}';
    final client = _buildMqttClient(host, clientId, port, user, pass);

    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return null;
      }

      client.subscribe('zigbee2mqtt/$name', MqttQos.atMostOnce);

      CoverStatus? result;
      final completer = Completer<CoverStatus?>();

      client.updates?.listen((events) {
        for (final event in events) {
          final msg = event.payload;
          if (msg is! MqttPublishMessage) continue;
          final pl = MqttPublishPayload.bytesToStringAsString(
              msg.payload.message);
          try {
            final json = jsonDecode(pl) as Map<String, dynamic>;
            final s = (json['state'] as String?)?.toLowerCase();
            final coverState = switch (s) {
              'open'    => CoverState.open,
              'closed'  => CoverState.closed,
              'opening' => CoverState.opening,
              'closing' => CoverState.closing,
              _         => CoverState.unknown,
            };
            result = (
              state:    coverState,
              position: (json['position'] as num?)?.toInt(),
            );
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

  // ── MQTT factory ─────────────────────────────────────────────────────────

  static MqttServerClient _buildMqttClient(
      String host, String clientId, int port, String? user, String? pass) {
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
    return client;
  }
}

enum _CoverCmd { open, close, stop, position }
