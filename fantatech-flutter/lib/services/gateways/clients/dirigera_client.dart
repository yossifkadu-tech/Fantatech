// ─────────────────────────────────────────────────────────────────────────────
// DIRIGERAGatewayClient  — IKEA DIRIGERA local REST API (HTTPS port 8443)
//
// Auth: OAuth 2.0 PKCE with physical button press.
//
//   1. POST https://[ip]:8443/v1/oauth/authorize
//         ?audience=homesmart.local
//         &response_type=code
//         &code_challenge=[base64url-SHA256(verifier)]
//         &code_challenge_method=S256
//      → 200 {code}   ← returned IMMEDIATELY, no button needed
//
//   2. User presses the physical action button on the gateway.
//
//   3. POST https://[ip]:8443/v1/oauth/token   (form-urlencoded)
//         code, name, grant_type=authorization_code, code_verifier
//      → 403 until button pressed → 200 {access_token}
//
//   4. GET  https://[ip]:8443/v1/devices
//         Authorization: Bearer [token]
//
// A fresh PKCE verifier/challenge pair is generated per pairing attempt using
// SHA-256 (RFC 7636), which some DIRIGERA firmware versions require.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../../models/device.dart';
import '../gateway_model.dart';

class DIRIGERAGatewayClient {
  static const _port    = 8443;
  static const _timeout = Duration(seconds: 8);

  // Client name registered with the gateway (shown in the IKEA app's client list).
  static const _clientName = 'FantaTech';

  // ── PKCE helpers (RFC 7636) ────────────────────────────────────────────────

  /// Generates a high-entropy code verifier: 43–128 unreserved chars.
  static String _generateVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(64, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// S256 challenge: base64url(SHA-256(verifier)), without padding.
  static String _challengeFor(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // ── Pair (step 1: request auth code — returned immediately) ────────────────
  //
  // The reference DIRIGERA flow uses GET for authorize; some firmware also
  // accepts POST. We try GET first and fall back to POST so we work on both.

  /// Requests an authorization code. Returns (httpStatus, code).
  static Future<(int, String?)> requestCode(String ip, String challenge) async {
    final path = '/v1/oauth/authorize'
        '?audience=homesmart.local'
        '&response_type=code'
        '&code_challenge=$challenge'
        '&code_challenge_method=S256';

    var resp = await _request(ip, 'GET', path, null, null);
    // Fall back to POST if GET is rejected (older firmware behaviour).
    if (resp == null || resp.statusCode == 404 || resp.statusCode == 405) {
      resp = await _request(ip, 'POST', path, null, null);
    }
    if (resp == null) return (0, null);
    if (resp.statusCode != 200) return (resp.statusCode, null);
    try {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return (200, j['code'] as String?);
    } catch (_) {
      return (resp.statusCode, null);
    }
  }

  // ── Pair (step 2: exchange code for token — gated on button press) ─────────
  //
  // The token endpoint returns 403 until the user presses the physical action
  // button on the gateway, then 200 with the access_token. The body must be
  // form-urlencoded (NOT JSON) and must include a client `name`.

  /// Attempts a single token exchange. Returns (httpStatus, accessToken).
  static Future<(int, String?)> tryExchangeToken(
      String ip, String code, String verifier) async {
    final form = {
      'code':          code,
      'name':          _clientName,
      'grant_type':    'authorization_code',
      'code_verifier': verifier,
    }.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}'
            '=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final resp = await _request(
        ip, 'POST', '/v1/oauth/token', form, null,
        contentType: 'application/x-www-form-urlencoded');
    if (resp == null) return (0, null);
    if (resp.statusCode != 200) return (resp.statusCode, null); // 403 = wait
    try {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return (200, j['access_token'] as String?);
    } catch (_) {
      return (resp.statusCode, null);
    }
  }

  /// Full pairing: gets a code, then polls the token endpoint while the user
  /// presses the button. Returns the access token, or null if it times out.
  /// [onStatus] surfaces human-readable diagnostics (HTTP codes) for the UI.
  static Future<String?> pairWithPolling(
    String ip, {
    int seconds = 60,
    void Function(int remaining)? onWaiting,
    void Function(String message)? onStatus,
  }) async {
    final verifier  = _generateVerifier();
    final challenge = _challengeFor(verifier);

    final (authStatus, code) = await requestCode(ip, challenge);
    if (code == null) {
      onStatus?.call(authStatus == 0
          ? (lastError.isEmpty ? 'אין תגובה מהרכזת (בדוק IP/רשת)' : lastError)
          : 'authorize נכשל — HTTP $authStatus');
      return null;
    }

    final deadline = DateTime.now().add(Duration(seconds: seconds));
    var lastTokenStatus = -1;
    while (DateTime.now().isBefore(deadline)) {
      onWaiting?.call(deadline.difference(DateTime.now()).inSeconds);
      final (tokenStatus, token) = await tryExchangeToken(ip, code, verifier);
      if (token != null) return token;
      lastTokenStatus = tokenStatus;
      onStatus?.call(tokenStatus == 403
          ? 'ממתין ללחיצת כפתור… (403)'
          : 'token: HTTP $tokenStatus — ממתין…');
      await Future.delayed(const Duration(seconds: 2));
    }
    onStatus?.call('פג הזמן — token האחרון: HTTP $lastTokenStatus');
    return null;
  }

  // ── Import devices ─────────────────────────────────────────────────────────

  static Future<GatewayImportResult> fetchDevices(
      String ip, String token) async {
    try {
      final resp = await _get(ip, '/v1/devices', token);
      if (resp == null) return const GatewayImportResult.failure('אין תגובה מ-DIRIGERA');
      if (resp.statusCode == 401) return const GatewayImportResult.failure('Token לא תקין');

      final List<dynamic> list;
      try {
        list = jsonDecode(resp.body) as List<dynamic>;
      } catch (_) {
        return const GatewayImportResult.failure('תגובה לא תקינה');
      }

      final devices = <Device>[];
      for (final item in list) {
        final d = item as Map<String, dynamic>;
        final attrs = (d['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
        final name  = attrs['customName'] as String?
            ?? attrs['model'] as String?
            ?? 'IKEA Device';
        final dType = d['deviceType'] as String? ?? '';
        final appType = _mapType(dType, attrs);
        if (appType == null) continue;

        final detected = _detectionState(dType, attrs);

        devices.add(Device(
          id:         'dirigera_${d["id"]}',
          name:       name,
          type:       appType,
          isOn:       attrs['isOn'] as bool? ?? false,
          status:     (d['isReachable'] as bool? ?? false)
              ? DeviceStatus.online
              : DeviceStatus.offline,
          attributes: {
            'ip':           ip,
            'manufacturer': 'IKEA',
            'model':        attrs['model'] as String? ?? dType,
            'firmware':     attrs['firmwareVersion'] as String? ?? '',
            if (detected != null) 'detected': detected,
            if (attrs['batteryPercentage'] != null)
              'battery': attrs['batteryPercentage'],
          },
        ));
      }

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאת DIRIGERA: $e');
    }
  }

  // ── Device control ─────────────────────────────────────────────────────────
  //
  // DIRIGERA accepts PATCH /v1/devices/{id} with a JSON array of attribute
  // updates: [{"attributes": {"isOn": true, "lightLevel": 80}}]
  //
  // The internal device IDs we emit are prefixed with "dirigera_" — strip the
  // prefix before sending to the gateway.

  static String _stripPrefix(String id) =>
      id.startsWith('dirigera_') ? id.substring(9) : id;

  /// Turn a device on/off. Returns true on success.
  static Future<bool> setOnOff(
      String ip, String token, String deviceId, bool isOn) async {
    return _patchAttrs(ip, token, deviceId, {'isOn': isOn});
  }

  /// Set light brightness 0..100.
  static Future<bool> setBrightness(
      String ip, String token, String deviceId, int level) async {
    final clamped = level.clamp(1, 100);
    return _patchAttrs(ip, token, deviceId, {'lightLevel': clamped});
  }

  /// Set color temperature in Kelvin (typically 2200..4000).
  static Future<bool> setColorTemperature(
      String ip, String token, String deviceId, int kelvin) async {
    return _patchAttrs(ip, token, deviceId, {'colorTemperature': kelvin});
  }

  /// Set color via hue (0..360) and saturation (0..1.0).
  static Future<bool> setColor(String ip, String token, String deviceId,
      double hue, double saturation) async {
    return _patchAttrs(ip, token, deviceId, {
      'colorHue':        hue,
      'colorSaturation': saturation,
    });
  }

  /// Set blind position 0..100 (0 = open, 100 = closed).
  static Future<bool> setBlindLevel(
      String ip, String token, String deviceId, int level) async {
    return _patchAttrs(ip, token, deviceId,
        {'blindsTargetLevel': level.clamp(0, 100)});
  }

  static Future<bool> _patchAttrs(String ip, String token, String deviceId,
      Map<String, dynamic> attrs) async {
    final body = jsonEncode([{'attributes': attrs}]);
    final resp = await _request(
        ip, 'PATCH', '/v1/devices/${_stripPrefix(deviceId)}', body, token);
    if (resp == null) return false;
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  // ── Type mapping ───────────────────────────────────────────────────────────

  static DeviceType? _mapType(String dType, Map<String, dynamic> attrs) {
    // 1. Attribute-based detection — most reliable, independent of how IKEA
    //    names the deviceType (Badring etc. can report several variants).
    if (attrs.containsKey('waterLeakDetected')) return DeviceType.waterLeakSensor;
    if (attrs.containsKey('isDetected'))        return DeviceType.motionSensor;
    if (attrs.containsKey('isOpen'))            return DeviceType.windowSensor;
    if (attrs.containsKey('blindsTargetLevel') ||
        attrs.containsKey('blindsCurrentLevel')) return DeviceType.blind;

    final t     = dType.toLowerCase();
    final model = (attrs['model'] ?? '').toString().toLowerCase();

    // 2. Name/model hints for water-leak sensors.
    if (t.contains('water') || t.contains('leak') ||
        model.contains('badring') || model.contains('water') ||
        model.contains('leak')) {
      return DeviceType.waterLeakSensor;
    }

    // 3. Fallback to deviceType string.
    switch (t) {
      case 'light':          return DeviceType.light;
      case 'outlet':         return DeviceType.smartPlug;
      case 'motionsensor':   return DeviceType.motionSensor;
      case 'contactsensor':  return DeviceType.windowSensor;
      case 'watersensor':    return DeviceType.waterLeakSensor;
      case 'blinds':         return DeviceType.blind;
      case 'speaker':        return null; // skip
      case 'controller':     return null; // remotes etc.
      default:               return DeviceType.smartSwitch;
    }
  }

  /// Extracts a sensor's "triggered" state from DIRIGERA attributes, by
  /// attribute presence (independent of deviceType naming).
  static bool? _detectionState(String dType, Map<String, dynamic> attrs) {
    if (attrs.containsKey('waterLeakDetected')) {
      return attrs['waterLeakDetected'] as bool?;
    }
    if (attrs.containsKey('isDetected')) return attrs['isDetected'] as bool?;
    if (attrs.containsKey('isOpen'))     return attrs['isOpen'] as bool?;
    return null;
  }

  // ── HTTPS helpers (self-signed cert allowed) ───────────────────────────────

  /// Human-readable description of the last network error (for diagnostics).
  static String lastError = '';

  static Future<_Resp?> _get(String ip, String path, String token) =>
      _request(ip, 'GET', path, null, token);

  static Future<_Resp?> _request(
    String ip,
    String method,
    String path,
    String? body,
    String? token, {
    String contentType = 'application/json',
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout          = _timeout
        ..badCertificateCallback     = (_, __, ___) => true; // self-signed OK
      // Use Uri.parse so an embedded query string (?a=b&c=d) is handled
      // correctly — Uri.https would percent-encode the '?' into the path.
      final uri = Uri.parse('https://$ip:$_port$path');
      final req = switch (method) {
        'GET'   => await client.getUrl(uri),
        'POST'  => await client.postUrl(uri),
        'PATCH' => await client.patchUrl(uri),
        'PUT'   => await client.putUrl(uri),
        _       => await client.postUrl(uri),
      };
      req.headers.set(HttpHeaders.contentTypeHeader, contentType);
      req.headers.set(HttpHeaders.acceptHeader,      'application/json');
      if (token != null) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        final bytes = utf8.encode(body);
        req.headers.contentLength = bytes.length;
        req.add(bytes);
      }
      final resp  = await req.close().timeout(_timeout);
      final bytes = await resp.fold<List<int>>([], (a, b) => a..addAll(b));
      client.close();
      lastError = '';
      return _Resp(resp.statusCode, utf8.decode(bytes, allowMalformed: true));
    } on SocketException catch (e) {
      lastError = 'אין קשר ל-$ip:$_port (${e.osError?.message ?? "socket"})';
    } on HandshakeException catch (_) {
      lastError = 'שגיאת TLS מול $ip:$_port';
    } on TimeoutException catch (_) {
      lastError = 'timeout מול $ip:$_port';
    } catch (e) {
      lastError = e.runtimeType.toString();
    } finally {
      client?.close(force: true);
    }
    return null;
  }
}

class _Resp {
  final int    statusCode;
  final String body;
  const _Resp(this.statusCode, this.body);
}
