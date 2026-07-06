// lifx_controller.dart
//
// LIFX cloud API controller for FantaTech smart home app.
//
// Protocol: HTTPS REST API at https://api.lifx.com/v1/
//   Authentication: Bearer token in the Authorization header.
//
// User must generate a personal API token at:
//   https://cloud.lifx.com/settings
//
// A "selector" targets one or more lights, e.g.:
//   "all"                  → every light
//   "id:d073d5000000"      → single light by serial
//   "label:Lamp"           → light by label
//   "group:Living Room"    → all lights in a group
//   "location:Home"        → all lights in a location

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class LifxController {
  static const String _baseUrl = 'https://api.lifx.com/v1';

  final String _apiToken;

  /// Creates a [LifxController].
  ///
  /// [apiToken] must be a personal access token generated at
  /// https://cloud.lifx.com/settings.
  LifxController({required String apiToken}) : _apiToken = apiToken;

  // ---------------------------------------------------------------------------
  // Internal transport
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json',
      };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<bool> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      // 207 Multi-Status is also a success for bulk operations
      return response.statusCode == 200 ||
          response.statusCode == 207 ||
          response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Turns lights matching [selector] on or off.
  Future<bool> setOnOff(String selector, bool on) {
    return _put('/lights/$selector/state', {'power': on ? 'on' : 'off'});
  }

  /// Sets [brightness] for lights matching [selector].
  ///
  /// [brightness] must be in range 0.0 (off) – 1.0 (full).
  Future<bool> setBrightness(String selector, double brightness) {
    return _put('/lights/$selector/state',
        {'brightness': brightness.clamp(0.0, 1.0)});
  }

  /// Sets the color for lights matching [selector].
  ///
  /// [color] is a LIFX color string, for example:
  ///   - `"rgb:255,0,0"`
  ///   - `"hue:120 saturation:1.0 brightness:0.5"`
  ///   - `"#ff0000"`
  Future<bool> setColor(String selector, String color) {
    return _put('/lights/$selector/state', {'color': color});
  }

  /// Sets color temperature [kelvin] for lights matching [selector].
  ///
  /// Typical range: 1500–9000 K.
  Future<bool> setColorTemp(String selector, int kelvin) {
    return _put('/lights/$selector/state', {'color': 'kelvin:$kelvin'});
  }

  /// Returns info for all lights accessible with this token.
  ///
  /// Each map contains fields such as `id`, `label`, `power`, `color`,
  /// `brightness`, `group`, `location`, etc.  Returns an empty list on error.
  Future<List<Map<String, dynamic>>> listLights() async {
    try {
      final response = await http
          .get(_uri('/lights/all'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
