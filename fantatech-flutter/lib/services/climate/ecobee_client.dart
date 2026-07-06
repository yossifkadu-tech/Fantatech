// ─────────────────────────────────────────────────────────────────────────────
// EcobeeClient  —  Ecobee cloud thermostat API (OAuth2 PIN flow)
//
// Register your app at developer.ecobee.com to get an API key.
//
// Base URL: https://api.ecobee.com
//
// OAuth2 PIN flow:
//   1. Call [requestPin]  → get a 4-char PIN to enter in the Ecobee app + code
//   2. User enters PIN in Ecobee app (My Apps → Add Application).
//   3. Call [authenticate] with the authorization code → saves tokens.
//   4. Call [refreshToken] to renew before expiry (tokens last ~1 hour).
//
// Key endpoints:
//   GET  /authorize         → request PIN (step 1)
//   POST /token             → exchange code/refresh for tokens
//   GET  /1/thermostat      → list thermostats with sensors + runtime
//   POST /1/thermostat      → update thermostat settings / HVAC mode
//
// Requirements:
//   • Ecobee account + registered developer app (developer.ecobee.com).
//   • Internet connection (cloud API only; no local protocol for Ecobee).
//   • Replace [_appKey] with your real API key from the developer portal.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class EcobeeClient {
  // ── Constants ─────────────────────────────────────────────────────────────

  static const _base = 'https://api.ecobee.com';

  /// Register your app at developer.ecobee.com to get an API key.
  static const _appKey = 'YOUR_ECOBEE_APP_KEY'; // Replace with your key

  static const _timeout = Duration(seconds: 5);

  // ── Instance fields ───────────────────────────────────────────────────────

  String? _accessToken;
  String? _refreshToken;

  // ── PIN flow ──────────────────────────────────────────────────────────────

  /// Step 1 — Request an authorization PIN.
  ///
  /// Returns a map with:
  ///   "pin"  — 4-char PIN to enter in the Ecobee mobile app
  ///   "code" — authorization code to pass to [authenticate]
  ///   "expires_in" — minutes until the PIN expires (default 9)
  ///
  /// Returns null on failure.
  Future<Map<String, dynamic>?> requestPin() async {
    try {
      final uri = Uri.parse(
        '$_base/authorize'
        '?response_type=ecobeePin'
        '&client_id=$_appKey'
        '&scope=smartWrite',
      );

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return {
          'pin':        body['ecobeePin'] ?? body['pin'],
          'code':       body['code'],
          'expires_in': body['expires_in'],
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Step 3 — Exchange the authorization code for access + refresh tokens.
  ///
  /// [code] — the "code" returned by [requestPin] (NOT the PIN itself).
  /// Returns true on success.
  Future<bool> authenticate(String code) async {
    try {
      final uri = Uri.parse(
        '$_base/token'
        '?grant_type=ecobeePin'
        '&code=$code'
        '&client_id=$_appKey',
      );

      final response = await http
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
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

  /// Refresh the access token using the stored refresh token.
  ///
  /// Returns true on success. Call this when API calls return 401.
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final uri = Uri.parse(
        '$_base/token'
        '?grant_type=refresh_token'
        '&refresh_token=$_refreshToken'
        '&client_id=$_appKey',
      );

      final response = await http
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
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

  // ── Thermostats ───────────────────────────────────────────────────────────

  /// Fetch all registered thermostats with sensor, settings and runtime data.
  ///
  /// Returns a list of thermostat maps. Each map contains:
  ///   "identifier" (String), "name", "settings", "runtime", "sensors"
  ///
  /// Returns an empty list on failure.
  Future<List<Map<String, dynamic>>> getThermostats() async {
    try {
      // The Ecobee API uses a JSON body passed as a query parameter.
      final selection = jsonEncode({
        'selection': {
          'selectionType':    'registered',
          'selectionMatch':   '',
          'includeSensors':   true,
          'includeSettings':  true,
          'includeRuntime':   true,
        },
      });

      final uri = Uri.parse(
        '$_base/1/thermostat'
        '?format=json'
        '&body=${Uri.encodeComponent(selection)}',
      );

      final response = await http
          .get(uri, headers: _authHeaders())
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list  = body['thermostatList'] as List<dynamic>?;
      if (list == null) return [];

      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  // ── HVAC control ──────────────────────────────────────────────────────────

  /// Set the HVAC mode for a thermostat.
  ///
  /// [thermostatId] — from [getThermostats] "identifier" field
  /// [mode]         — "auto" | "cool" | "heat" | "off"
  /// Returns true on success.
  Future<bool> setHvacMode(String thermostatId, String mode) async {
    return _postThermostatUpdate(
      thermostatId: thermostatId,
      settings: {'hvacMode': mode},
    );
  }

  /// Set heating and cooling setpoints.
  ///
  /// [thermostatId]  — from [getThermostats] "identifier" field
  /// [heatCelsius]   — heating setpoint in °C (converted to °F×10 internally)
  /// [coolCelsius]   — cooling setpoint in °C (converted to °F×10 internally)
  /// Returns true on success.
  Future<bool> setTemperature(
    String thermostatId,
    int heatCelsius,
    int coolCelsius,
  ) async {
    // Ecobee API uses Fahrenheit × 10 (e.g. 720 = 72.0°F)
    final heatF = _celsiusToEcobeeF(heatCelsius);
    final coolF = _celsiusToEcobeeF(coolCelsius);

    return _postThermostatUpdate(
      thermostatId: thermostatId,
      runtime: {
        'desiredHeat': heatF,
        'desiredCool': coolF,
      },
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<bool> _postThermostatUpdate({
    required String thermostatId,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? runtime,
  }) async {
    try {
      final thermostat = <String, dynamic>{'identifier': thermostatId};
      if (settings != null) thermostat['settings'] = settings;
      if (runtime  != null) thermostat['runtime']  = runtime;

      final body = jsonEncode({
        'selection': {
          'selectionType':  'thermostats',
          'selectionMatch': thermostatId,
        },
        'thermostat': thermostat,
      });

      final response = await http
          .post(
            Uri.parse('$_base/1/thermostat'),
            headers: _authHeaders(withContentType: true),
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return false;

      // Ecobee returns {"status": {"code": 0}} on success
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status  = decoded['status'] as Map<String, dynamic>?;
      return (status?['code'] as int? ?? -1) == 0;
    } catch (_) {
      return false;
    }
  }

  /// Convert Celsius to Ecobee's Fahrenheit×10 integer format.
  static int _celsiusToEcobeeF(int celsius) {
    final fahrenheit = celsius * 9 / 5 + 32;
    return (fahrenheit * 10).round();
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
