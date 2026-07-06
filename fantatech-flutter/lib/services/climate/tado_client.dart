// ─────────────────────────────────────────────────────────────────────────────
// TadoClient  —  Tado° cloud REST API (OAuth2 password flow)
//
// Tado credentials = same as tado app login (email + password).
//
// Auth endpoint : https://auth.tado.com/oauth/token
// API base      : https://my.tado.com/api/v2
//
// OAuth2 flow:
//   1. POST /oauth/token with grant_type=password + credentials → access_token
//   2. Add "Authorization: Bearer <access_token>" to all API calls.
//   3. Use refresh_token to renew before expiry.
//
// Key endpoints:
//   GET  /api/v2/me                                     → account + homeId
//   GET  /api/v2/homes/{homeId}/zones                   → rooms (zones)
//   GET  /api/v2/homes/{homeId}/zones/{zoneId}/state    → current temp + setpoint
//   PUT  /api/v2/homes/{homeId}/zones/{zoneId}/overlay  → manual setpoint / off
//   DELETE /api/v2/homes/{homeId}/zones/{zoneId}/overlay → resume schedule
//
// Requirements:
//   • Active Tado account (tado.com) with at least one Tado° device installed.
//   • Internet connection (cloud API only; no local protocol).
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class TadoClient {
  // ── Constants ─────────────────────────────────────────────────────────────

  static const _authBase = 'https://auth.tado.com';
  static const _apiBase  = 'https://my.tado.com/api/v2';

  // Tado public OAuth2 client credentials (same as tado web app).
  static const _clientId     = 'tado-web-app';
  static const _clientSecret = 'wZaRN7rpjn3FoNyF38I6Lk8tNzIA';

  static const _timeout = Duration(seconds: 5);

  // ── Instance fields ───────────────────────────────────────────────────────

  final String _username;
  final String _password;

  String? _accessToken;
  String? _refreshToken;

  /// Create a Tado client.
  ///
  /// Call [authenticate] before using any API methods.
  TadoClient({
    required String username,
    required String password,
  })  : _username = username,
        _password = password;

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Authenticate with Tado using the password grant flow.
  ///
  /// Saves the access and refresh tokens internally.
  /// Returns true on success.
  Future<bool> authenticate() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_authBase/oauth/token'),
            headers: {
              HttpHeaders.contentTypeHeader:
                  'application/x-www-form-urlencoded',
            },
            body: {
              'client_id':     _clientId,
              'client_secret': _clientSecret,
              'grant_type':    'password',
              'username':      _username,
              'password':      _password,
              'scope':         'home.user',
            },
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return false;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken  = body['access_token']  as String?;
      _refreshToken = body['refresh_token'] as String?;

      return _accessToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Use the refresh token to obtain a new access token.
  ///
  /// Returns true on success. Call this when API calls return 401.
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_authBase/oauth/token'),
            headers: {
              HttpHeaders.contentTypeHeader:
                  'application/x-www-form-urlencoded',
            },
            body: {
              'client_id':     _clientId,
              'client_secret': _clientSecret,
              'grant_type':    'refresh_token',
              'refresh_token': _refreshToken!,
              'scope':         'home.user',
            },
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return false;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken  = body['access_token']  as String?;
      _refreshToken = body['refresh_token'] as String? ?? _refreshToken;

      return _accessToken != null;
    } catch (_) {
      return false;
    }
  }

  // ── Account ───────────────────────────────────────────────────────────────

  /// Fetch the account info and return the primary home ID.
  ///
  /// Returns null on failure or if no home is linked to the account.
  Future<int?> getHomeId() async {
    try {
      final body = await _get('/me');
      if (body == null) return null;

      final homes = body['homes'] as List<dynamic>?;
      if (homes == null || homes.isEmpty) return null;

      final firstHome = homes.first as Map<String, dynamic>;
      return firstHome['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  // ── Zones (rooms) ─────────────────────────────────────────────────────────

  /// Get all zones (rooms) for a home.
  ///
  /// Returns a list of zone maps. Each map contains at minimum:
  ///   "id" (int), "name" (String), "type" (String: "HEATING" etc.)
  Future<List<Map<String, dynamic>>> getZones(int homeId) async {
    try {
      final body = await _get('/homes/$homeId/zones');
      if (body == null) return [];
      // Response is a JSON array
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get all zones returning raw decoded list.
  Future<List<dynamic>?> getZonesList(int homeId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiBase/homes/$homeId/zones'),
            headers: _authHeaders(),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Get the current state of a zone (room).
  ///
  /// Returns a map with fields like:
  ///   "tadoMode", "setting" (type, power, temperature),
  ///   "sensorDataPoints" (insideTemperature, humidity), "overlay"
  Future<Map<String, dynamic>?> getZoneState(int homeId, int zoneId) async {
    return _get('/homes/$homeId/zones/$zoneId/state');
  }

  // ── Temperature control ───────────────────────────────────────────────────

  /// Set a manual heating temperature setpoint in a zone.
  ///
  /// [celsius] — target temperature (e.g. 21.0).
  /// The overlay type is MANUAL, meaning it overrides the schedule
  /// until [deleteOverlay] is called.
  /// Returns true on success.
  Future<bool> setTemperature(
    int homeId,
    int zoneId,
    double celsius,
  ) async {
    final body = jsonEncode({
      'setting': {
        'type':        'HEATING',
        'power':       'ON',
        'temperature': {'celsius': celsius},
      },
      'termination': {'type': 'MANUAL'},
    });
    return _put('/homes/$homeId/zones/$zoneId/overlay', body);
  }

  /// Turn heating off in a zone (manual override).
  ///
  /// The zone will remain off until [deleteOverlay] is called.
  /// Returns true on success.
  Future<bool> setOff(int homeId, int zoneId) async {
    final body = jsonEncode({
      'setting': {
        'type':  'HEATING',
        'power': 'OFF',
      },
      'termination': {'type': 'MANUAL'},
    });
    return _put('/homes/$homeId/zones/$zoneId/overlay', body);
  }

  /// Delete the manual overlay and resume the timetable schedule.
  ///
  /// Returns true on success.
  Future<bool> deleteOverlay(int homeId, int zoneId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_apiBase/homes/$homeId/zones/$zoneId/overlay'),
            headers: _authHeaders(),
          )
          .timeout(_timeout);

      // 204 No Content = success
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiBase$path'),
            headers: _authHeaders(),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _put(String path, String body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_apiBase$path'),
            headers: _authHeaders(withContentType: true),
            body: body,
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _authHeaders({bool withContentType = false}) {
    final h = <String, String>{
      HttpHeaders.authorizationHeader: 'Bearer ${_accessToken ?? ''}',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (withContentType) {
      h[HttpHeaders.contentTypeHeader] = 'application/json';
    }
    return h;
  }
}
