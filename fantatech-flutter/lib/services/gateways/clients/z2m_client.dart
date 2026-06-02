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
import 'dart:convert';
import 'dart:io';
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
            'ip':           ip,
            'ieee':         ieee,
            'manufacturer': vendor ?? '',
            'model':        model  ?? '',
            'powerSource':  power,
            'protocol':     'zigbee',
          },
        ));
      }

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאת Z2M: $e');
    }
  }

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
