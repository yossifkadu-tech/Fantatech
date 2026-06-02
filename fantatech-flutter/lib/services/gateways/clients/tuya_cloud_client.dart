// ─────────────────────────────────────────────────────────────────────────────
// TuyaCloudClient — Tuya OpenAPI v1.0 cloud client (covers Moes / Tuya hubs).
//
// Auth flow (HMAC-SHA256 signed):
//   1. GET /v1.0/token?grant_type=1                 → access_token
//   2. GET /v1.0/iot-01/associated-users/devices    → all linked-account devices
//   3. POST /v1.0/devices/{id}/commands             → control
//
// Signing (Tuya spec):
//   stringToSign = METHOD \n SHA256(body) \n headers \n url
//   token req:    sign = HMAC256(clientId + t + nonce + stringToSign, secret)
//   business req: sign = HMAC256(clientId + token + t + nonce + stringToSign, secret)
//   sign is upper-case hex.
//
// Setup: create a project at https://iot.tuya.com, link the Smart Life app
// account, and copy Access ID (clientId) + Access Secret (clientSecret).
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../models/device.dart';
import '../gateway_model.dart';

/// Tuya regional data centers.
enum TuyaRegion { eu, us, cn, india }

extension TuyaRegionHost on TuyaRegion {
  String get host => switch (this) {
        TuyaRegion.eu => 'openapi.tuyaeu.com',
        TuyaRegion.us => 'openapi.tuyaus.com',
        TuyaRegion.cn => 'openapi.tuyacn.com',
        TuyaRegion.india => 'openapi.tuyain.com',
      };

  String get label => switch (this) {
        TuyaRegion.eu => 'Europe',
        TuyaRegion.us => 'America',
        TuyaRegion.cn => 'China',
        TuyaRegion.india => 'India',
      };

  static TuyaRegion fromName(String? n) =>
      TuyaRegion.values.firstWhere((e) => e.name == n,
          orElse: () => TuyaRegion.eu);
}

class TuyaCloudClient {
  static const _timeout = Duration(seconds: 15);
  static const _emptyBodySha =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  final String clientId;
  final String clientSecret;
  final TuyaRegion region;

  TuyaCloudClient({
    required this.clientId,
    required this.clientSecret,
    this.region = TuyaRegion.eu,
  });

  String get _host => region.host;

  // ── Public: verify credentials by fetching a token ─────────────────────────
  static Future<bool> testConnection({
    required String clientId,
    required String clientSecret,
    required TuyaRegion region,
  }) async {
    final c = TuyaCloudClient(
        clientId: clientId, clientSecret: clientSecret, region: region);
    final token = await c._getToken();
    return token != null;
  }

  // ── Public: import devices ─────────────────────────────────────────────────
  static Future<GatewayImportResult> fetchDevices({
    required String clientId,
    required String clientSecret,
    required TuyaRegion region,
  }) async {
    final c = TuyaCloudClient(
        clientId: clientId, clientSecret: clientSecret, region: region);
    try {
      final token = await c._getToken();
      if (token == null) {
        return const GatewayImportResult.failure(
            'אימות Tuya נכשל — בדוק Access ID/Secret והאזור');
      }

      final resp = await c._signedGet(
          '/v1.0/iot-01/associated-users/devices', token);
      if (resp == null) {
        return const GatewayImportResult.failure('אין תגובה מ-Tuya');
      }
      final body = jsonDecode(resp) as Map<String, dynamic>;
      if (body['success'] != true) {
        return GatewayImportResult.failure(
            'Tuya: ${body['msg'] ?? 'שגיאה'}');
      }

      final result = body['result'] as Map<String, dynamic>? ?? {};
      final list = (result['devices'] as List<dynamic>?) ?? [];
      final devices = <Device>[];

      for (final item in list) {
        final d = item as Map<String, dynamic>;
        final id = d['id'] as String? ?? '';
        final name = d['name'] as String? ?? 'Tuya Device';
        final category = d['category'] as String? ?? '';
        final online = d['online'] as bool? ?? true;

        final type = _categoryToType(category);
        if (type == null) continue; // skip hubs / unknown

        devices.add(Device(
          id: 'tuya_$id',
          name: name,
          type: type,
          isOn: false,
          status: online ? DeviceStatus.online : DeviceStatus.offline,
          attributes: {
            'manufacturer': 'Tuya/Moes',
            'model': d['product_name'] as String? ?? category,
            'protocol': 'tuya',
            'tuyaId': id,
            'category': category,
          },
        ));
      }

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאת Tuya: $e');
    }
  }

  // ── Tuya category → DeviceType ─────────────────────────────────────────────
  // https://developer.tuya.com/en/docs/iot/standarddescription
  static DeviceType? _categoryToType(String category) {
    switch (category) {
      case 'dj': // light bulb
      case 'dd': // light strip
      case 'dc': // string light
      case 'xdd': // ceiling light
        return DeviceType.light;
      case 'kg': // switch
      case 'tdq': // breaker
        return DeviceType.smartSwitch;
      case 'cz': // socket
      case 'pc': // power strip
        return DeviceType.smartPlug;
      case 'pir': // PIR motion sensor
        return DeviceType.motionSensor;
      case 'mcs': // contact / door-window sensor
        return DeviceType.windowSensor;
      case 'ywbj': // smoke detector
        return DeviceType.smokeSensor;
      case 'rqbj': // gas detector
      case 'cobj': // CO detector
        return DeviceType.gasSensor;
      case 'sj': // water leak sensor
        return DeviceType.waterLeakSensor;
      case 'ms': // door lock
      case 'jtmspro':
        return DeviceType.smartLock;
      case 'cl': // curtain / blind motor
        return DeviceType.blind;
      case 'wk': // thermostat
      case 'ktkzq': // AC controller
        return DeviceType.airConditioner;
      case 'znjld': // energy meter
      case 'zndb':
        return DeviceType.energyMeter;
      case 'sp': // smart camera
        return DeviceType.camera;
      case 'wg2': // gateway / hub
      case 'wf_gw':
        return null; // hide the hub itself
      default:
        return null;
    }
  }

  // ── Token ──────────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    const path = '/v1.0/token?grant_type=1';
    final t = DateTime.now().millisecondsSinceEpoch.toString();
    final stringToSign = 'GET\n$_emptyBodySha\n\n$path';
    final sign = _hmac('$clientId$t$stringToSign');

    final resp = await _request('GET', path, headers: {
      'client_id': clientId,
      'sign': sign,
      't': t,
      'sign_method': 'HMAC-SHA256',
    });
    if (resp == null) return null;
    try {
      final body = jsonDecode(resp) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return (body['result'] as Map<String, dynamic>)['access_token']
          as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Signed GET (business request) ──────────────────────────────────────────
  Future<String?> _signedGet(String path, String token) async {
    final t = DateTime.now().millisecondsSinceEpoch.toString();
    final stringToSign = 'GET\n$_emptyBodySha\n\n$path';
    final sign = _hmac('$clientId$token$t$stringToSign');

    return _request('GET', path, headers: {
      'client_id': clientId,
      'access_token': token,
      'sign': sign,
      't': t,
      'sign_method': 'HMAC-SHA256',
    });
  }

  // ── HMAC-SHA256 → upper-case hex ───────────────────────────────────────────
  String _hmac(String message) {
    final h = Hmac(sha256, utf8.encode(clientSecret));
    return h.convert(utf8.encode(message)).toString().toUpperCase();
  }

  // ── Raw HTTPS request ──────────────────────────────────────────────────────
  Future<String?> _request(String method, String path,
      {required Map<String, String> headers}) async {
    try {
      final client = HttpClient()..connectionTimeout = _timeout;
      final uri = Uri.parse('https://$_host$path');
      final req = await client.openUrl(method, uri);
      headers.forEach(req.headers.set);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      final resp = await req.close().timeout(_timeout);
      final bytes = await resp.fold<List<int>>([], (a, b) => a..addAll(b));
      client.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
