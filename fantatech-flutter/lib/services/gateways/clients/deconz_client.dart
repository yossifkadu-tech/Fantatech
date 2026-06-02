// ─────────────────────────────────────────────────────────────────────────────
// DeCONZGatewayClient  (deCONZ / Phoscon — Dresden Elektronik)
//
// API identical to Philips Hue v1:
//   POST http://[ip]:[port]/api  {"devicetype":"fantatech"}  → apikey (after Phoscon auth)
//   GET  http://[ip]:[port]/api/[key]/lights
//   GET  http://[ip]:[port]/api/[key]/sensors
//
// Auth button: user must click "Authenticate app" in Phoscon web UI first.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';
import '../../../models/device.dart';
import '../gateway_model.dart';

class DeCONZGatewayClient {
  static const _timeout  = Duration(seconds: 5);
  static const _appType  = 'fantatech';

  // ── Pairing ────────────────────────────────────────────────────────────────

  static Future<String?> tryPair(String ip, int port) async {
    final body = jsonEncode({'devicetype': _appType});
    final raw  = await _post(ip, port, '/api', body);
    if (raw == null) return null;
    try {
      final list  = jsonDecode(raw) as List<dynamic>;
      final first = list.first as Map<String, dynamic>;
      if (first.containsKey('success')) {
        return (first['success'] as Map<String, dynamic>)['username'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> pairWithPolling(
    String ip,
    int port, {
    int seconds = 30,
    void Function(int remaining)? onWaiting,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(deadline)) {
      onWaiting?.call(deadline.difference(DateTime.now()).inSeconds);
      final key = await tryPair(ip, port);
      if (key != null) return key;
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  static Future<GatewayImportResult> fetchDevices(
      String ip, int port, String apiKey) async {
    try {
      final lights  = await _getJson(ip, port, '/api/$apiKey/lights')  as Map? ?? {};
      final sensors = await _getJson(ip, port, '/api/$apiKey/sensors') as Map? ?? {};

      final devices = <Device>[];

      lights.forEach((id, d) {
        final state = (d['state'] as Map?)?.cast<String, dynamic>() ?? {};
        devices.add(Device(
          id:         'deconz_light_$id',
          name:       d['name'] as String? ?? 'deCONZ Light $id',
          type:       DeviceType.light,
          isOn:       state['on'] as bool? ?? false,
          status:     DeviceStatus.online,
          attributes: {
            'ip':           ip,
            'apiKey':       apiKey,
            'manufacturer': d['manufacturername'] as String? ?? 'Zigbee',
            'model':        d['modelid'] as String? ?? '',
            'brightness':   state['bri'] != null
                ? ((state['bri'] as int) / 2.54).round()
                : 80,
          },
        ));
      });

      sensors.forEach((id, d) {
        final type = d['type'] as String? ?? '';
        final dt   = _sensorType(type);
        if (dt == null) return;

        final state  = (d['state']  as Map?)?.cast<String, dynamic>() ?? {};
        final config = (d['config'] as Map?)?.cast<String, dynamic>() ?? {};
        devices.add(Device(
          id:         'deconz_sensor_$id',
          name:       d['name'] as String? ?? 'Sensor $id',
          type:       dt,
          isOn:       config['on'] as bool? ?? true,
          status:     DeviceStatus.online,
          attributes: {
            'ip':       ip,
            'apiKey':   apiKey,
            'battery':  config['battery'] ?? 100,
            'detected': state['presence'] ?? state['open'] ?? false,
          },
        ));
      });

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאת deCONZ: $e');
    }
  }

  // ── Type mapping ───────────────────────────────────────────────────────────

  static DeviceType? _sensorType(String type) {
    if (type.contains('ZHAPresence') || type.contains('ZLLPresence'))
      return DeviceType.motionSensor;
    if (type.contains('ZHAOpenClose'))
      return DeviceType.windowSensor;
    if (type.contains('ZHAFire'))
      return DeviceType.smokeSensor;
    if (type.contains('ZHASwitch') || type.contains('ZLLSwitch'))
      return DeviceType.smartSwitch;
    return null;
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  static Future<Object?> _getJson(String ip, int port, String path) async {
    final raw = await _request(ip, port, 'GET', path, null);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<String?> _post(String ip, int port, String path, String body) =>
      _request(ip, port, 'POST', path, body);

  static Future<String?> _request(
      String ip, int port, String method, String path, String? body) async {
    try {
      final sock = await Socket.connect(ip, port, timeout: _timeout);
      final req  = StringBuffer()
        ..write('$method $path HTTP/1.0\r\n')
        ..write('Host: $ip:$port\r\n')
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
