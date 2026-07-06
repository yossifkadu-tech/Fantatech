// ─────────────────────────────────────────────────────────────────────────────
// SmartThingsClient  — Samsung SmartThings cloud REST API
//
// Base URL: https://api.smartthings.com/v1
// Auth:     Authorization: Bearer [Personal Access Token]
//
// PAT creation: https://account.smartthings.com/tokens
//
//   GET /v1/devices           → list all devices
//   GET /v1/devices/[id]/status → per-device state
//
// Capability → DeviceType mapping:
//   switch / switchLevel        → smartSwitch / light
//   colorControl / colorTemperatureLight → light
//   thermostatMode              → airConditioner
//   smokeDetector               → smokeSensor
//   motionSensor                → motionSensor
//   contactSensor               → windowSensor
//   waterSensor                 → sensor
//   energyMeter / powerMeter    → energyMeter
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';
import '../../../models/device.dart';
import '../gateway_model.dart';

class SmartThingsClient {
  static const _base    = 'api.smartthings.com';
  static const _timeout = Duration(seconds: 12);

  // ── Verify token ────────────────────────────────────────────────────────────

  static Future<bool> verifyToken(String token) async {
    try {
      final resp = await _get('/v1/devices?max=1', token);
      return resp?.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Import devices ─────────────────────────────────────────────────────────

  static Future<GatewayImportResult> fetchDevices(String token) async {
    try {
      final resp = await _get('/v1/devices', token);
      if (resp == null) return const GatewayImportResult.failure('No response from SmartThings');
      if (resp.statusCode == 401) return const GatewayImportResult.failure('Invalid token');
      if (resp.statusCode != 200) {
        return GatewayImportResult.failure('שגיאה ${resp.statusCode}');
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return const GatewayImportResult.failure('Invalid response from SmartThings');
      }

      final items = (body['items'] as List<dynamic>?) ?? [];
      final devices = <Device>[];

      for (final item in items) {
        final d     = item as Map<String, dynamic>;
        final devId = d['deviceId'] as String? ?? '';
        final label = d['label'] as String?
            ?? d['name'] as String?
            ?? 'SmartThings Device';

        final comps = (d['components'] as List<dynamic>?) ?? [];
        final caps  = <String>{};
        for (final comp in comps) {
          final capList = (comp['capabilities'] as List<dynamic>?) ?? [];
          for (final c in capList) {
            final id = (c as Map<String, dynamic>)['id'] as String?;
            if (id != null) caps.add(id);
          }
        }

        final type = _capabilityToType(caps);
        if (type == null) continue; // skip virtual devices

        devices.add(Device(
          id:         'st_$devId',
          name:       label,
          type:       type,
          isOn:       false,
          status:     DeviceStatus.online,
          source:     'gateway',
          attributes: {
            'manufacturer': d['manufacturerName'] as String? ?? 'SmartThings',
            'model':        d['presentationId']   as String? ?? '',
            'protocol':     'smartthings',
            'stDeviceId':   devId,
          },
        ));
      }

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('SmartThings error: $e');
    }
  }

  // ── Capability → DeviceType ────────────────────────────────────────────────

  static DeviceType? _capabilityToType(Set<String> caps) {
    if (caps.contains('colorControl') || caps.contains('colorTemperature') ||
        caps.contains('switchLevel'))             return DeviceType.light;
    if (caps.contains('smokeDetector'))           return DeviceType.smokeSensor;
    if (caps.contains('motionSensor'))            return DeviceType.motionSensor;
    if (caps.contains('contactSensor'))           return DeviceType.windowSensor;
    if (caps.contains('thermostatMode') ||
        caps.contains('thermostatHeatingSetpoint')) return DeviceType.airConditioner;
    if (caps.contains('energyMeter') ||
        caps.contains('powerMeter'))              return DeviceType.energyMeter;
    if (caps.contains('switch'))                  return DeviceType.smartSwitch;
    if (caps.contains('lock'))                    return DeviceType.doorSensor;
    if (caps.contains('videoCamera') ||
        caps.contains('videoStream'))             return DeviceType.camera;
    if (caps.contains('waterSensor'))             return null; // skip for now
    return null;
  }

  // ── HTTPS helper ───────────────────────────────────────────────────────────

  static Future<_HttpResp?> _get(String path, String token) async {
    try {
      final client = HttpClient()..connectionTimeout = _timeout;
      final req    = await client.getUrl(Uri.https(_base, path));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final resp  = await req.close().timeout(_timeout);
      final bytes = await resp.fold<List<int>>(
        [], (a, b) => a..addAll(b));
      client.close();
      return _HttpResp(resp.statusCode, utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }
}

class _HttpResp {
  final int    statusCode;
  final String body;
  const _HttpResp(this.statusCode, this.body);
}
