// ─────────────────────────────────────────────────────────────────────────────
// DIRIGERAGatewayClient  — IKEA DIRIGERA local REST API (HTTPS port 8443)
//
// Auth: OAuth 2.0 PKCE with physical button press.
//
//   1. POST https://[ip]:8443/v1/oauth/authorize
//         ?response_type=code
//         &code_challenge=[base64url-SHA256(verifier)]
//         &code_challenge_method=S256
//      → 403 until button pressed → 200 {code}
//
//   2. POST https://[ip]:8443/v1/oauth/token
//         {grant_type, code, code_verifier}
//      → {access_token}
//
//   3. GET  https://[ip]:8443/v1/devices
//         Authorization: Bearer [token]
//
// Since the `crypto` package may not be present, we carry a pre-computed PKCE
// test vector from RFC 7636 Appendix B. For production use, add crypto and
// generate a fresh pair per pairing attempt.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';
import '../../../models/device.dart';
import '../gateway_model.dart';

class DIRIGERAGatewayClient {
  static const _port    = 8443;
  static const _timeout = Duration(seconds: 8);

  // RFC 7636 test vector — safe to use for local home-app pairing.
  static const _codeVerifier  = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
  static const _codeChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

  // ── Pair (step 1: wait for button press) ──────────────────────────────────

  /// Returns auth code when button is pressed, null if still waiting.
  static Future<String?> tryAuthorize(String ip) async {
    final path = '/v1/oauth/authorize'
        '?response_type=code'
        '&code_challenge=$_codeChallenge'
        '&code_challenge_method=S256';
    final resp = await _post(ip, path, null);
    if (resp == null) return null;
    try {
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return j['code'] as String?;
      }
    } catch (_) {}
    return null; // 403 = button not pressed
  }

  static Future<String?> authorizeWithPolling(
    String ip, {
    int seconds = 30,
    void Function(int remaining)? onWaiting,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(deadline)) {
      onWaiting?.call(deadline.difference(DateTime.now()).inSeconds);
      final code = await tryAuthorize(ip);
      if (code != null) return code;
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  // ── Pair (step 2: exchange code for token) ─────────────────────────────────

  static Future<String?> exchangeToken(String ip, String code) async {
    final body = jsonEncode({
      'grant_type':    'authorization_code',
      'code':          code,
      'code_verifier': _codeVerifier,
    });
    final resp = await _post(ip, '/v1/oauth/token', body);
    if (resp == null || resp.statusCode != 200) return null;
    try {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return j['access_token'] as String?;
    } catch (_) {
      return null;
    }
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
          },
        ));
      }

      return GatewayImportResult.success(devices);
    } catch (e) {
      return GatewayImportResult.failure('שגיאת DIRIGERA: $e');
    }
  }

  // ── Type mapping ───────────────────────────────────────────────────────────

  static DeviceType? _mapType(String dType, Map<String, dynamic> attrs) {
    switch (dType.toLowerCase()) {
      case 'light':         return DeviceType.light;
      case 'outlet':        return DeviceType.smartPlug;
      case 'motionsensor':  return DeviceType.motionSensor;
      case 'contactsensor': return DeviceType.windowSensor;
      case 'blinds':        return DeviceType.blind;
      case 'speaker':       return null; // skip
      case 'controller':    return null; // remotes etc.
      default:              return DeviceType.smartSwitch;
    }
  }

  // ── HTTPS helpers (self-signed cert allowed) ───────────────────────────────

  static Future<_Resp?> _post(String ip, String path, String? body) =>
      _request(ip, 'POST', path, body, null);

  static Future<_Resp?> _get(String ip, String path, String token) =>
      _request(ip, 'GET', path, null, token);

  static Future<_Resp?> _request(
    String ip,
    String method,
    String path,
    String? body,
    String? token,
  ) async {
    try {
      final client = HttpClient()
        ..connectionTimeout          = _timeout
        ..badCertificateCallback     = (_, __, ___) => true; // self-signed OK
      final uri = Uri.https('$ip:$_port', path);
      final req  = method == 'GET'
          ? await client.getUrl(uri)
          : await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
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
      return _Resp(resp.statusCode, utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }
}

class _Resp {
  final int    statusCode;
  final String body;
  const _Resp(this.statusCode, this.body);
}
