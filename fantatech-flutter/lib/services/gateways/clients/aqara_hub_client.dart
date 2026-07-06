// ─────────────────────────────────────────────────────────────────────────────
// AqaraHubClient  —  Aqara Hub local HTTP API
//
// Supported hubs: M2, E1, M1S Gen2 (and compatible models)
//
// Protocol:
//   The Aqara hub exposes a local REST API on port 80.
//   All endpoints are under the path /open-home/...
//   Authentication uses a Bearer token passed in the Authorization header.
//
// Requirements:
//   • Aqara hub must be on the same LAN.
//   • You need an Aqara developer account at https://developer.aqara.com
//     to generate an access token (API Key) for local LAN control.
//   • Enable local API access in the Aqara developer console.
//   • The access token is tied to the hub's location/home configuration.
//
// Endpoints used:
//   GET  /open-home/device/v1.0/query   — list all paired devices
//   POST /open-home/device/v1.0/set     — set a device attribute
//   GET  /open-home                     — fingerprint check (returns 401 + "aqara")
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AqaraHubClient {
  // ── Constructor ───────────────────────────────────────────────────────────

  final String _ip;
  final String _accessToken;

  static const _timeout = Duration(seconds: 5);

  String get ip => _ip;

  /// Create a client for an Aqara hub at [ip] authenticated with [accessToken].
  ///
  /// Requires Aqara developer account at developer.aqara.com to generate
  /// an access token.
  AqaraHubClient({
    required String ip,
    required String accessToken,
  })  : _ip = ip,
        _accessToken = accessToken;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch the list of all devices paired to this hub.
  ///
  /// Returns a list of device maps, or an empty list on failure.
  /// Each map contains fields such as "did", "model", "attrs", etc.
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://$_ip/open-home/device/v1.0/query'),
            headers: _headers(),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final data = body['data'] ?? body['result'] ?? body['devices'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Set an arbitrary attribute on a device.
  ///
  /// [did]   — Aqara device ID (from [getDevices])
  /// [attr]  — attribute name, e.g. "powerState", "brightness", "colorTemp"
  /// [value] — the value to set
  ///
  /// Returns true on success.
  Future<bool> setDeviceAttr(String did, String attr, dynamic value) async {
    try {
      final body = jsonEncode({
        'did':   did,
        'attrs': {attr: value},
      });

      final response = await http
          .post(
            Uri.parse('http://$_ip/open-home/device/v1.0/set'),
            headers: _headers(withContentType: true),
            body: body,
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Turn a device on or off.
  ///
  /// Sets the "powerState" attribute to "on" or "off".
  /// Returns true on success.
  Future<bool> setOnOff(String did, bool on) async {
    return setDeviceAttr(did, 'powerState', on ? 'on' : 'off');
  }

  /// Set brightness for a light or dimmable device.
  ///
  /// [level] — 0 to 100 (percentage).
  /// Returns true on success.
  Future<bool> setBrightness(String did, int level) async {
    final clamped = level.clamp(0, 100);
    return setDeviceAttr(did, 'brightness', clamped);
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

  /// Scan the subnet for Aqara hubs by probing port 80 on each host.
  ///
  /// A host is identified as an Aqara hub if GET /open-home returns
  /// HTTP 401 and the response body contains the string "aqara".
  ///
  /// [subnetPrefix] — e.g. "192.168.1"
  ///
  /// Returns the first discovered AqaraHubClient (with an empty access token
  /// that the caller must fill in), or null if none found.
  ///
  /// Note: scanning 254 hosts takes time. The caller should run this in
  /// an isolate or show a progress indicator.
  static Future<AqaraHubClient?> discover(String subnetPrefix) async {
    const probeTimeout = Duration(seconds: 2);

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnetPrefix.$i';
      try {
        final response = await http
            .get(Uri.parse('http://$ip/open-home'))
            .timeout(probeTimeout);

        final body = response.body.toLowerCase();
        if (response.statusCode == 401 && body.contains('aqara')) {
          // Found a hub — return client with empty token; caller supplies real token
          return AqaraHubClient(ip: ip, accessToken: '');
        }
      } catch (_) {
        // Host not reachable — continue scanning
      }
    }
    return null;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Map<String, String> _headers({bool withContentType = false}) {
    final h = <String, String>{
      HttpHeaders.authorizationHeader: _accessToken,
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (withContentType) {
      h[HttpHeaders.contentTypeHeader] = 'application/json';
    }
    return h;
  }
}
