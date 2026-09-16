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
import '../../../models/device_capabilities.dart';
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

  /// Same idea as [lastRawSummary] but for the last [fetchDeviceStatus]
  /// call — the exact request path and raw response body, so a "no DPs
  /// returned" result can be told apart from a masked API error (wrong
  /// API version enabled on the project, missing subscription, etc.)
  /// instead of both looking identical to the caller.
  static String lastStatusRawResponse = '';

  /// Same idea again, for the last [sendCommands] call. sendCommands()
  /// itself only ever returned a bare bool — a rejected command (wrong DP
  /// code, project not authorized for the command endpoint, device
  /// offline on Tuya's side, etc.) was indistinguishable from "the
  /// physical device just didn't respond", with nothing to diagnose why a
  /// toggle silently did nothing.
  static String lastCommandRawResponse = '';

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

        // 'cur_power' is Tuya's standard live-power DP for metering sockets
        // (kept in the 'cz' category), reported in units of 0.1 W — hence
        // the /10. Devices that don't report it (most switches, and plugs
        // without a metering chip) simply have no 'watts' attribute at all,
        // rather than a fabricated 0 — that's what the Energy screen uses
        // to tell "no data" apart from "actually drawing nothing".
        num? watts;
        final statusList = d['status'] as List<dynamic>? ?? const [];
        // Every DP Tuya reports for this device, kept verbatim (code →
        // value) — not just the ones this app already understands
        // (switch/power below). Devices like sensors report vendor- and
        // model-specific config DPs (sensitivity, delay, detection range,
        // etc.) that have no normalized FantaTech capability; surfacing
        // them raw here is what lets the edit sheet offer a "Tuya advanced
        // settings" section for whatever a specific device actually
        // exposes, instead of guessing DP names that vary by model.
        final dps = <String, dynamic>{};
        // A multi-gang switch (e.g. a 3-way wall switch) reports one DP per
        // gang — switch_1, switch_2, switch_3 — not a single switch_1 for
        // "the device". This used to only ever read switch_1, so gang 2 and
        // 3 were never imported as anything at all (their DPs still landed
        // in 'dps' above, but no Device was ever created to represent or
        // control them) — user-reported: a 3-gang "מפסק ראשי" only ever
        // showed as one switch. Collect every numbered channel found;
        // channel 1 also accepts the older bare 'switch'/'switch_led' codes
        // some single-gang devices still use instead of 'switch_1'.
        final channelStates = <int, bool>{};
        final channelDpCode = RegExp(r'^switch_(\d+)$');
        for (final s in statusList) {
          final entry = s as Map<String, dynamic>;
          final code = entry['code'] as String?;
          if (code == null) continue;
          dps[code] = entry['value'];
          final m = channelDpCode.firstMatch(code);
          if (m != null) {
            channelStates[int.parse(m.group(1)!)] = entry['value'] == true;
          } else if (code == 'switch' || code == 'switch_led') {
            channelStates[1] = entry['value'] == true;
          } else if (code == 'cur_power') {
            final raw = entry['value'] as num?;
            if (raw != null) watts = raw / 10;
          }
        }

        // Map the sensor-triggered DP into the same normalized attribute
        // key DeviceCapabilities.binaryStateKey(type) expects (used by
        // AppState's alert/notification logic and the sensor cards' UI) —
        // this never existed before, so a Tuya sensor's actual trigger DP
        // only ever landed in the raw 'tuyaDps' bag above, which nothing
        // reads for display or alerting. isOn also gets it for sensor
        // types (isOn otherwise only comes from the switch_* codes above,
        // which sensors don't have, so it would silently stay false
        // forever regardless of real motion/contact/leak state).
        final detected = _sensorDetectedFromDps(type, dps);

        final baseAttrs = {
          'manufacturer': 'Tuya/Moes',
          'model': d['product_name'] as String? ?? category,
          'protocol': 'tuya',
          'tuyaId': id,
          'category': category,
          if (watts != null) 'watts': watts,
          if (dps.isNotEmpty) 'tuyaDps': dps,
          if (detected != null) DeviceCapabilities.binaryStateKey(type)!: detected,
        };

        if (channelStates.length > 1) {
          // Real multi-gang device — one Device per gang, same '_chN'
          // id convention the LAN switch scanner already uses
          // (smart_switch_hub_screen.dart's _addToHome), so both import
          // paths produce ids DeviceCommander can route the same way.
          final channels = channelStates.keys.toList()..sort();
          for (final ch in channels) {
            devices.add(Device(
              id: 'tuya_${id}_ch$ch',
              // Matches the LAN switch scanner's own multi-channel naming
              // convention (smart_switch_hub_screen.dart's _addToHome).
              name: '$name — Channel $ch',
              type: type,
              isOn: channelStates[ch]!,
              status: online ? DeviceStatus.online : DeviceStatus.offline,
              source: 'gateway',
              attributes: {...baseAttrs, 'channel': '$ch'},
            ));
          }
        } else {
          final isOn = detected ?? (channelStates[1] ?? false);
          devices.add(Device(
            id: 'tuya_$id',
            name: name,
            type: type,
            isOn: isOn,
            status: online ? DeviceStatus.online : DeviceStatus.offline,
            source: 'gateway',
            attributes: baseAttrs,
          ));
        }
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

  // ── Sensor-triggered DP → normalized 'detected' state ───────────────────────
  // https://developer.tuya.com/en/docs/iot/standarddescription — DP codes
  // vary by device generation/manufacturer even within one category (same
  // situation as the switch_1/switch/switch_led check above), so each
  // sensor type checks every documented code its category is known to use.
  // Returns null when none of them are present (device didn't report a
  // trigger state at all) rather than guessing false, so a device this
  // doesn't recognize just keeps whatever isOn it already had instead of
  // being silently forced to "clear".
  static bool? _sensorDetectedFromDps(DeviceType type, Map<String, dynamic> dps) {
    bool? asBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'pir' || s == 'alarm' || s == 'alarming' || s == 'true' || s == '1') return true;
        if (s == 'none' || s == 'normal' || s == 'false' || s == '0') return false;
      }
      return null;
    }

    switch (type) {
      case DeviceType.motionSensor:
        for (final code in ['pir', 'presence_state', 'radar_state']) {
          if (dps.containsKey(code)) return asBool(dps[code]) ?? false;
        }
        return null;
      case DeviceType.windowSensor:
        for (final code in ['doorcontact_state']) {
          if (dps.containsKey(code)) return asBool(dps[code]) ?? false;
        }
        return null;
      case DeviceType.smokeSensor:
        for (final code in ['smoke_sensor_status', 'smoke_sensor_state']) {
          if (dps.containsKey(code)) return asBool(dps[code]) ?? false;
        }
        return null;
      case DeviceType.gasSensor:
        for (final code in ['gas_sensor_status', 'co_status', 'co_state']) {
          if (dps.containsKey(code)) return asBool(dps[code]) ?? false;
        }
        return null;
      case DeviceType.waterLeakSensor:
        for (final code in ['watersensor_state', 'water_sensor_state']) {
          if (dps.containsKey(code)) return asBool(dps[code]) ?? false;
        }
        return null;
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
    if (resp == null) {
      lastCommandRawResponse =
          'POST $path\nbody: $body\n\nNo response from Tuya (network/timeout).';
      return false;
    }
    lastCommandRawResponse = 'POST $path\nbody: $body\n\n$resp';
    try {
      final parsed = jsonDecode(resp) as Map<String, dynamic>;
      return parsed['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Fetch token (public for repository use) ───────────────────────────────
  Future<String?> getToken() => _getToken();

  // ── Fetch one device's live status (all DPs) ───────────────────────────────
  /// Returns every DP Tuya currently has for this device (code → value), as
  /// a map. Deliberately separate from the bulk associated-users/devices
  /// list used by [fetchDevices]: that list endpoint's per-device 'status'
  /// can be a trimmed subset for some categories/models, so a single-device
  /// endpoint is the reliable way to pull a device's full current DP set on
  /// demand (e.g. an "advanced settings" refresh button in the edit sheet),
  /// not just at import time.
  ///
  /// Tries the newer `/v1.0/iot-03/devices/{id}/status` endpoint first —
  /// the older plain `/v1.0/devices/{id}/status` returns `code 2003
  /// "function not support"` for device categories onboarded through
  /// Tuya's newer "quick response"/data-model flow (seen live on a
  /// presence/illuminance sensor whose Smart Life app clearly shows this
  /// data, so the device itself is not the problem). Falls back to the
  /// older endpoint for any device category where that's what actually
  /// works, keeping both raw responses in [lastStatusRawResponse] if both
  /// fail so a still-unexplained case is diagnosable without guessing a
  /// third path blind.
  Future<Map<String, dynamic>?> fetchDeviceStatus({
    required String token,
    required String tuyaDeviceId,
  }) async {
    final modern = await _fetchStatusFrom(
        '/v1.0/iot-03/devices/$tuyaDeviceId/status', token);
    if (modern != null) return modern;
    final modernLog = lastStatusRawResponse;

    final legacy =
        await _fetchStatusFrom('/v1.0/devices/$tuyaDeviceId/status', token);
    if (legacy != null) return legacy;

    lastStatusRawResponse = '$modernLog\n\n$lastStatusRawResponse';
    return null;
  }

  Future<Map<String, dynamic>?> _fetchStatusFrom(
      String path, String token) async {
    final resp = await _signedGet(path, token);
    if (resp == null) {
      lastStatusRawResponse =
          'No response from Tuya (network/timeout) for $path.';
      return null;
    }
    lastStatusRawResponse = 'GET $path\n$resp';
    try {
      final body = jsonDecode(resp) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final list = body['result'] as List<dynamic>? ?? const [];
      final dps = <String, dynamic>{};
      for (final entry in list) {
        final e = entry as Map<String, dynamic>;
        final code = e['code'] as String?;
        if (code != null) dps[code] = e['value'];
      }
      return dps;
    } catch (_) {
      return null;
    }
  }

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
