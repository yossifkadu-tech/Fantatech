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

  /// Human-readable dump of the last `fetchDevices()` call — exactly what
  /// Tuya's API returned (or the raw error), so import problems (wrong
  /// linked account, unmapped categories, etc.) are visible instead of
  /// silently showing "0 imported".
  static String lastRawSummary = '';

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
        lastRawSummary = 'Authentication failed — check Access ID/Secret and region.\n'
            'Verify the Cloud Authorization IP Allowlist is disabled or set to allow all.';
        return const GatewayImportResult.failure(
            'Tuya authentication failed — check Access ID/Secret and region');
      }

      final resp = await c._signedGet(
          '/v1.0/iot-01/associated-users/devices', token);
      if (resp == null) {
        lastRawSummary = 'No response from Tuya (network/timeout).';
        return const GatewayImportResult.failure('No response from Tuya');
      }
      final body = jsonDecode(resp) as Map<String, dynamic>;
      if (body['success'] != true) {
        lastRawSummary = 'Tuya API error.\n'
            'code: ${body['code']}\n'
            'msg: ${body['msg']}\n'
            'Raw response:\n$resp';
        return GatewayImportResult.failure(
            'Tuya: ${body['msg'] ?? 'error'}');
      }

      final result = body['result'] as Map<String, dynamic>? ?? {};
      final list = (result['devices'] as List<dynamic>?) ?? [];
      final devices = <Device>[];
      final summaryLines = <String>[
        'Tuya API returned ${list.length} device(s) for this account.',
        '',
      ];

      for (final item in list) {
        final d = item as Map<String, dynamic>;
        final id = d['id'] as String? ?? '';
        final name = d['name'] as String? ?? 'Tuya Device';
        final category = d['category'] as String? ?? '';
        final online = d['online'] as bool? ?? true;

        final type = _categoryToType(category);
        summaryLines.add(
            '• $name — category "$category" → ${type?.name ?? "HIDDEN (hub/gateway)"}'
            ' (id: tuya_$id, online: $online)');
        if (type == null) continue; // skip hubs only — everything else maps to a type

        devices.add(Device(
          id: 'tuya_$id',
          name: name,
          type: type,
          isOn: false,
          status: online ? DeviceStatus.online : DeviceStatus.offline,
          source: 'gateway',
          attributes: {
            'manufacturer': 'Tuya/Moes',
            'model': d['product_name'] as String? ?? category,
            'protocol': 'tuya',
            'tuyaId': id,
            'category': category,
          },
        ));
      }

      if (list.isEmpty) {
        summaryLines.add(
            'No devices were returned at all — this usually means the '
            'Smart Life account was not fully linked to this project '
            '(Devices → Link Tuya App Account), not a filtering issue.');
      }
      lastRawSummary = summaryLines.join('\n');

      return GatewayImportResult.success(devices);
    } catch (e) {
      lastRawSummary = 'Exception while importing: $e';
      return GatewayImportResult.failure('Tuya error: $e');
    }
  }

  // ── Tuya category → DeviceType ─────────────────────────────────────────────
  // https://developer.tuya.com/en/docs/iot/standarddescription
  //
  // Tuya's category taxonomy is large and grows over time — rather than only
  // recognizing a hand-picked list and silently dropping everything else
  // (which made real devices with less-common category codes vanish from
  // import with no error), every category maps to a concrete DeviceType.
  // Only the hub/gateway categories are explicitly hidden; anything else we
  // don't have a specific mapping for still imports as DeviceType.unknown
  // rather than disappearing.
  static DeviceType? _categoryToType(String category) {
    switch (category) {
      // ── Lights ──────────────────────────────────────────────────────────
      case 'dj': // light bulb
      case 'dd': // light strip
      case 'dc': // string light
      case 'xdd': // ceiling light
      case 'fwd': // ceiling fan light
      case 'tgq': // dimmer switch/lamp
      case 'tgkg': // dimmer switch
        return DeviceType.light;
      // ── Switches ────────────────────────────────────────────────────────
      case 'kg': // switch
      case 'tdq': // breaker
      case 'kj': // air purifier / switch-adjacent controllers
      case 'qn': // heater switch
        return DeviceType.smartSwitch;
      // ── Plugs / sockets ─────────────────────────────────────────────────
      case 'cz': // socket
      case 'pc': // power strip
      case 'insleep': // smart plug variant
        return DeviceType.smartPlug;
      // ── Motion / presence sensors ───────────────────────────────────────
      case 'pir': // PIR motion sensor
      case 'hps': // human presence sensor
      case 'ldcg': // radar motion sensor
        return DeviceType.motionSensor;
      // ── Door / window sensors ───────────────────────────────────────────
      case 'mcs': // contact / door-window sensor
        return DeviceType.windowSensor;
      // ── Smoke ───────────────────────────────────────────────────────────
      case 'ywbj': // smoke detector
        return DeviceType.smokeSensor;
      // ── Gas / CO ────────────────────────────────────────────────────────
      case 'rqbj': // gas detector
      case 'cobj': // CO detector
        return DeviceType.gasSensor;
      // ── Water leak ──────────────────────────────────────────────────────
      case 'sj': // water leak sensor
        return DeviceType.waterLeakSensor;
      // ── Locks ───────────────────────────────────────────────────────────
      case 'ms': // door lock
      case 'jtmspro':
      case 'videolock': // video door lock
        return DeviceType.smartLock;
      // ── Blinds / curtains ───────────────────────────────────────────────
      case 'cl': // curtain / blind motor
      case 'clkg': // curtain switch
        return DeviceType.blind;
      // ── Climate ─────────────────────────────────────────────────────────
      case 'wk': // thermostat
      case 'ktkzq': // AC controller
      case 'kt': // air conditioner
        return DeviceType.airConditioner;
      // ── Energy ──────────────────────────────────────────────────────────
      case 'znjld': // energy meter
      case 'zndb':
        return DeviceType.energyMeter;
      case 'dlq': // circuit breaker w/ metering
        return DeviceType.circuitBreaker;
      // ── Cameras ─────────────────────────────────────────────────────────
      case 'sp': // smart camera
        return DeviceType.camera;
      // ── Gateways / hubs — hidden, not imported as devices ──────────────
      case 'wg2':
      case 'wf_gw':
      case 'zigbee_gateway':
        return null;
      // ── Anything else: import as a generic device rather than drop it ───
      default:
        return DeviceType.unknown;
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

  // ── Public: send commands to a device ────────────────────────────────────
  /// Send one or more [commands] to [tuyaDeviceId].
  /// [commands] is a list of `{"code": "...", "value": ...}` maps.
  /// Returns true on success.
  Future<bool> sendCommands({
    required String token,
    required String tuyaDeviceId,
    required List<Map<String, dynamic>> commands,
  }) async {
    final path = '/v1.0/devices/$tuyaDeviceId/commands';
    final body = jsonEncode({'commands': commands});
    final resp = await _signedPost(path, token, body);
    if (resp == null) return false;
    try {
      final parsed = jsonDecode(resp) as Map<String, dynamic>;
      return parsed['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Fetch token (public for repository use) ───────────────────────────────
  Future<String?> getToken() => _getToken();

  // ── Signed POST (business request) ───────────────────────────────────────
  Future<String?> _signedPost(String path, String token, String body) async {
    final t        = DateTime.now().millisecondsSinceEpoch.toString();
    final bodySha  = sha256.convert(utf8.encode(body)).toString();
    final stringToSign = 'POST\n$bodySha\n\n$path';
    final sign     = _hmac('$clientId$token$t$stringToSign');

    return _request('POST', path,
        headers: {
          'client_id':    clientId,
          'access_token': token,
          'sign':         sign,
          't':            t,
          'sign_method':  'HMAC-SHA256',
        },
        body: body);
  }

  // ── HMAC-SHA256 → upper-case hex ───────────────────────────────────────────
  String _hmac(String message) {
    final h = Hmac(sha256, utf8.encode(clientSecret));
    return h.convert(utf8.encode(message)).toString().toUpperCase();
  }

  // ── Raw HTTPS request ──────────────────────────────────────────────────────
  Future<String?> _request(String method, String path,
      {required Map<String, String> headers, String? body}) async {
    try {
      final http = HttpClient()..connectionTimeout = _timeout;
      final uri  = Uri.parse('https://$_host$path');
      final req  = await http.openUrl(method, uri);
      headers.forEach(req.headers.set);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (body != null) req.write(body);
      final resp  = await req.close().timeout(_timeout);
      final bytes = await resp.fold<List<int>>([], (a, b) => a..addAll(b));
      http.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
