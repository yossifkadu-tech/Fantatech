// ─────────────────────────────────────────────────────────────────────────────
// HueGatewayClient
//
// Philips Hue Bridge v1 API (REST, HTTP, no HTTPS needed on LAN).
//
// Pairing flow:
//   1. POST http://[ip]/api  {"devicetype":"fantatech#app"}
//      → [{error: {type:101}}]  until the button is pressed
//   2. After button press same endpoint returns:
//      → [{success: {username: "abc123"}}]
//
// Import:
//   GET http://[ip]/api/[user]/lights   → map → light devices
//   GET http://[ip]/api/[user]/sensors  → map → motion/contact sensors
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';
import '../../../models/device.dart';
import '../gateway_model.dart';

class HueGatewayClient {
  static const _port    = 80;
  static const _timeout = Duration(seconds: 5);
  static const _appType = 'fantatech#app';

  // ── Pairing ────────────────────────────────────────────────────────────────

  /// Try to pair. Returns a username if the bridge button was pressed,
  /// or null (button not yet pressed), or throws on network error.
  static Future<String?> tryPair(String ip) async {
    final body = jsonEncode({'devicetype': _appType});
    final raw  = await _post(ip, '/api', body);
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final first = list.first as Map<String, dynamic>;
      if (first.containsKey('success')) {
        return (first['success'] as Map<String, dynamic>)['username'] as String?;
      }
    } catch (_) {}
    return null; // button not pressed yet (error 101)
  }

  /// Poll tryPair every 2 s for up to [seconds] s.
  /// Calls [onWaiting] each tick so UI can show countdown.
  static Future<String?> pairWithPolling(
    String ip, {
    int seconds = 30,
    void Function(int remaining)? onWaiting,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(deadline)) {
      final remaining = deadline.difference(DateTime.now()).inSeconds;
      onWaiting?.call(remaining);
      final username = await tryPair(ip);
      if (username != null) return username;
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  static Future<GatewayImportResult> fetchDevices(
      String ip, String username) async {
    try {
      final lights  = await _getJson(ip, '/api/$username/lights') as Map? ?? {};
      final sensors = await _getJson(ip, '/api/$username/sensors') as Map? ?? {};

      final devices = <Device>[];

      lights.forEach((id, data) {
        final state = (data['state'] as Map?)?.cast<String, dynamic>() ?? {};
        final name  = data['name'] as String? ?? 'Hue Light $id';
        final model = data['modelid'] as String? ?? '';
        final type  = _lightType(model, data['type'] as String? ?? '');
        devices.add(Device(
          id:          'hue_light_$id',
          name:        name,
          type:        type,
          isOn:        state['on'] as bool? ?? false,
          status:      DeviceStatus.online,
          attributes: {
            'ip':           ip,
            'hueId':        id,
            'model':        model,
            'manufacturer': 'Philips Hue',
            'brightness':   state['bri'] != null
                ? ((state['bri'] as int) / 2.54).round()
                : 80,
          },
        ));
      });

      sensors.forEach((id, data) {
        final config = (data['config'] as Map?)?.cast<String, dynamic>() ?? {};
        final state  = (data['state'] as Map?)?.cast<String, dynamic>() ?? {};
        final name   = data['name'] as String? ?? 'Hue Sensor $id';
        final type   = data['type'] as String? ?? '';
        final dType  = _sensorType(type);
        if (dType == null) return;

        devices.add(Device(
          id:          'hue_sensor_$id',
          name:        name,
          type:        dType,
          isOn:        config['on'] as bool? ?? true,
          status:      DeviceStatus.online,
          attributes: {
            'ip':           ip,
            'hueId':        id,
            'manufacturer': data['manufacturername'] as String? ?? 'Philips',
            'battery':      config['battery'] ?? 100,
            'detected':     state['presence'] ?? state['open'] ?? false,
          },
        ));
      });

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאה בייבוא Hue: $e');
    }
  }

  // ── Bridge info ────────────────────────────────────────────────────────────

  static Future<String?> getBridgeName(String ip) async {
    try {
      final j = await _getJson(ip, '/api/config') as Map?;
      return j?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DeviceType _lightType(String model, String hueType) {
    if (hueType.toLowerCase().contains('group')) return DeviceType.light;
    return DeviceType.light;
  }

  static DeviceType? _sensorType(String type) {
    if (type.contains('ZLLPresence') || type.contains('ZHAPresence'))
      return DeviceType.motionSensor;
    if (type.contains('ZLLSwitch') || type.contains('ZHASwitch'))
      return DeviceType.smartSwitch;
    if (type.contains('ZHAOpenClose'))
      return DeviceType.windowSensor;
    if (type.contains('ZHATemperature') || type.contains('ZHAHumidity'))
      return null; // skip environmental sensors for now
    return null;
  }

  static Future<Object?> _getJson(String ip, String path) async {
    final raw = await _request(ip, path, 'GET', null);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<String?> _post(String ip, String path, String body) =>
      _request(ip, path, 'POST', body);

  static Future<String?> _request(
      String ip, String path, String method, String? body) async {
    try {
      final sock = await Socket.connect(ip, _port, timeout: _timeout);
      final req = StringBuffer()
        ..write('$method $path HTTP/1.0\r\n')
        ..write('Host: $ip\r\n')
        ..write('Content-Type: application/json\r\n');
      if (body != null) {
        req.write('Content-Length: ${utf8.encode(body).length}\r\n');
      }
      req.write('\r\n');
      if (body != null) req.write(body);
      sock.write(req.toString());
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          _timeout, onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 512 * 1024) break;
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
