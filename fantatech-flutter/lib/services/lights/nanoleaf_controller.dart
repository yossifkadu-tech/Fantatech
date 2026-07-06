// nanoleaf_controller.dart
//
// Nanoleaf REST API controller for FantaTech smart home app.
//
// Protocol: HTTP REST on port 16021 (local network only).
//   Authentication: auth token acquired via the pairing handshake.
//
// Pairing flow:
//   1. Hold the Nanoleaf power button for 5–7 seconds until the LEDs flash.
//   2. Within 30 s, call `requestToken()` — it POSTs to /api/v1/new and
//      returns a token string.
//   3. Persist the token and pass it to the constructor for all future calls.

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

class NanoleafController {
  final String _ip;
  final int port;
  String? _token;

  static const Duration _timeout = Duration(seconds: 3);

  /// Creates a [NanoleafController].
  ///
  /// [ip] is the local IP of the Nanoleaf panel.
  /// [port] defaults to 16021.
  /// [authToken] is the previously acquired token (optional — call
  /// [requestToken] if you don't have one yet).
  NanoleafController({
    required String ip,
    this.port = 16021,
    String? authToken,
  })  : _ip = ip,
        _token = authToken;

  /// The auth token currently in use (may be null before pairing).
  String? get authToken => _token;

  // ---------------------------------------------------------------------------
  // Internal transport
  // ---------------------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('http://$_ip:$port$path');

  /// Sends an HTTP [method] request to [path] with an optional JSON [body].
  /// Returns the response body string, or null on error/timeout.
  Future<String?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = _timeout
        ..idleTimeout = _timeout;

      final uri = _uri(path);
      final HttpClientRequest req;
      switch (method.toUpperCase()) {
        case 'GET':
          req = await client.getUrl(uri).timeout(_timeout);
          break;
        case 'POST':
          req = await client.postUrl(uri).timeout(_timeout);
          break;
        case 'PUT':
          req = await client.putUrl(uri).timeout(_timeout);
          break;
        case 'DELETE':
          req = await client.deleteUrl(uri).timeout(_timeout);
          break;
        default:
          return null;
      }

      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      if (body != null) {
        final encoded = utf8.encode(jsonEncode(body));
        req.headers.set(HttpHeaders.contentLengthHeader, encoded.length);
        req.add(encoded);
      }

      final resp = await req.close().timeout(_timeout);
      final responseBody =
          await resp.transform(utf8.decoder).join().timeout(_timeout);
      return responseBody;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  Future<bool> _put(String path, Map<String, dynamic> body) async {
    final result = await _request('PUT', path, body: body);
    return result != null;
  }

  // ---------------------------------------------------------------------------
  // Pairing
  // ---------------------------------------------------------------------------

  /// Requests a new auth token from the panel.
  ///
  /// The panel must be in pairing mode first (hold power button 5–7 s until
  /// LEDs flash white).
  ///
  /// Returns the token string on success, or null on failure.
  /// The token is also stored internally so subsequent calls work immediately.
  Future<String?> requestToken() async {
    final result = await _request('POST', '/api/v1/new');
    if (result == null) return null;
    try {
      final json = jsonDecode(result) as Map<String, dynamic>;
      final token = json['auth_token'] as String?;
      if (token != null) _token = token;
      return token;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Turns the panels on (`true`) or off (`false`).
  Future<bool> setOnOff(bool on) {
    if (_token == null) return Future.value(false);
    return _put('/api/v1/$_token/state', {
      'on': {'value': on},
    });
  }

  /// Sets brightness [level] 0–100.
  Future<bool> setBrightness(int level) {
    if (_token == null) return Future.value(false);
    return _put('/api/v1/$_token/state', {
      'brightness': {'value': level.clamp(0, 100)},
    });
  }

  /// Sets color temperature [kelvin] (typically 1200–6500 K).
  Future<bool> setColorTemp(int kelvin) {
    if (_token == null) return Future.value(false);
    return _put('/api/v1/$_token/state', {
      'ct': {'value': kelvin},
    });
  }

  /// Sets the static color using RGB values (each 0–255).
  ///
  /// Nanoleaf's state endpoint accepts HSV, so the RGB values are converted
  /// internally via the standard RGB→HSV algorithm.
  Future<bool> setColor(int r, int g, int b) {
    if (_token == null) return Future.value(false);
    final hsv = _rgbToHsv(r, g, b);
    return _put('/api/v1/$_token/state', {
      'hue': {'value': hsv[0]},
      'sat': {'value': hsv[1]},
      'brightness': {'value': hsv[2]},
    });
  }

  /// Activates a saved effect by [name].
  Future<bool> setEffect(String name) {
    if (_token == null) return Future.value(false);
    return _put('/api/v1/$_token/effects', {'select': name});
  }

  /// Returns the full device info map, or null on error.
  ///
  /// The map includes fields such as `name`, `serialNo`, `firmwareVersion`,
  /// `state`, `effects`, `panelLayout`, etc.
  Future<Map<String, dynamic>?> getInfo() async {
    if (_token == null) return null;
    final result = await _request('GET', '/api/v1/$_token');
    if (result == null) return null;
    try {
      return jsonDecode(result) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Color conversion helper
  // ---------------------------------------------------------------------------

  /// Converts RGB (each 0–255) to HSV.
  ///
  /// Returns `[hue (0–359), saturation (0–100), value (0–100)]`.
  static List<int> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final max = math.max(rf, math.max(gf, bf));
    final min = math.min(rf, math.min(gf, bf));
    final delta = max - min;

    // Value
    final v = (max * 100).round();

    // Saturation
    final s = max == 0.0 ? 0 : ((delta / max) * 100).round();

    // Hue
    int h = 0;
    if (delta != 0.0) {
      double rawHue;
      if (max == rf) {
        rawHue = ((gf - bf) / delta) % 6;
      } else if (max == gf) {
        rawHue = (bf - rf) / delta + 2;
      } else {
        rawHue = (rf - gf) / delta + 4;
      }
      h = ((rawHue * 60).round() + 360) % 360;
    }

    return [h, s, v];
  }
}
