// ─────────────────────────────────────────────────────────────────────────────
// HaClient — Home Assistant REST API integration
//
// Detection (no token needed):
//   GET http://<ip>:8123/api/  →  {"message":"API running."}
//
// Import all devices (requires Long-Lived Access Token):
//   GET http://<ip>:8123/api/states
//   Authorization: Bearer <token>
//
// The token is persisted in SharedPreferences so the user only enters it once.
//
// Entities mapped to DiscoveredDevice:
//   light.*           → light
//   switch.*          → smartSwitch
//   water_heater.*    → boiler
//   climate.*         → thermostat
//   camera.*          → camera
//   binary_sensor.*   → motionSensor / windowSensor / doorSensor / smokeSensor
//   sensor.*          → energyMeter / smokeSensor / sensor
//
// Entities that are intentionally skipped (too verbose / not physical devices):
//   automation.*, script.*, scene.*, input_*, zone.*, person.*, sun.*
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'discovery_models.dart';
import 'device_classifier.dart';

class HaClient {
  static const _prefsKeyToken = 'ha_token';
  static const _prefsKeyIp    = 'ha_ip';
  static const _port          = 8123;
  static const _timeout       = Duration(seconds: 8);

  // ── Persistence ──────────────────────────────────────────────────────────────

  static Future<String?> savedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyToken);
  }

  static Future<String?> savedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyIp);
  }

  static Future<void> saveCredentials(String ip, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyIp, ip);
    await prefs.setString(_prefsKeyToken, token);
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyToken);
    await prefs.remove(_prefsKeyIp);
  }

  // ── Detection (no auth) ───────────────────────────────────────────────────────

  /// Returns true if HA is running at the given IP on port 8123.
  static Future<bool> detect(String ip) async {
    try {
      final body = await _get(ip, '/api/');
      return body != null && body.contains('API running');
    } catch (_) {
      return false;
    }
  }

  // ── Import entities ──────────────────────────────────────────────────────────

  /// Fetch all HA states using the provided token.
  /// Returns an empty list on auth failure or network error.
  static Future<HaImportResult> fetchDevices(String ip, String token) async {
    try {
      final raw = await _getAuth(ip, '/api/states', token);
      if (raw == null) return HaImportResult.error('Geen reactie van HA');

      final List<dynamic> states;
      try {
        states = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        // Not JSON — likely 401 Unauthorized
        if (raw.contains('401') || raw.contains('Unauthorized')) {
          return HaImportResult.error('Token ongeldig — controleer het');
        }
        return HaImportResult.error('Onverwacht antwoord van HA');
      }

      final devices = <DiscoveredDevice>[];
      const skip = {
        'automation', 'script', 'scene', 'input_boolean', 'input_text',
        'input_number', 'input_select', 'input_datetime', 'zone',
        'person', 'sun', 'timer', 'counter', 'group', 'device_tracker',
        'media_player', 'tts', 'system_log', 'logger', 'update', 'notify',
        'persistent_notification',
      };

      for (final state in states) {
        final entityId     = state['entity_id'] as String? ?? '';
        final domain       = entityId.split('.').first;
        if (skip.contains(domain)) continue;

        final attrs        = (state['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
        final friendlyName = (attrs['friendly_name'] as String?) ?? entityId;
        final deviceClass  = attrs['device_class'] as String?;
        final stateVal     = state['state'] as String? ?? '';

        final type = DeviceClassifier.classifyHaEntity(
          entityId:     entityId,
          deviceClass:  deviceClass,
          friendlyName: friendlyName,
        );

        // Skip unknown/sensor domains that don't correspond to physical devices
        if (type == DiscoveredDeviceType.unknown) continue;
        if (type == DiscoveredDeviceType.sensor &&
            domain != 'sensor') continue;

        devices.add(DiscoveredDevice(
          id:           'ha_$entityId',
          displayName:  friendlyName,
          ip:           ip,
          type:         type,
          protocol:     DiscoveryProtocol.zigbee,
          manufacturer: attrs['integration'] as String?,
          metadata: {
            'entityId':    entityId,
            'domain':      domain,
            'state':       stateVal,
            'deviceClass': deviceClass,
            'haIp':        ip,
          },
        ));
      }

      await saveCredentials(ip, token);
      return HaImportResult.success(devices);
    } catch (e) {
      return HaImportResult.error('שגיאת רשת: $e');
    }
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────────

  static Future<String?> _get(String ip, String path) async {
    return _request(ip, path, null);
  }

  static Future<String?> _getAuth(String ip, String path, String token) async {
    return _request(ip, path, token);
  }

  static Future<String?> _request(String ip, String path, String? token) async {
    try {
      final sock = await Socket.connect(ip, _port, timeout: _timeout);

      final headers = StringBuffer()
        ..write('GET $path HTTP/1.0\r\n')
        ..write('Host: $ip:$_port\r\n')
        ..write('Accept: application/json\r\n');
      if (token != null) {
        headers.write('Authorization: Bearer $token\r\n');
      }
      headers.write('\r\n');

      sock.write(headers.toString());
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
        _timeout,
        onTimeout: (sink) => sink.close(),
      )) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) break; // 2 MB cap
      }
      await sock.close();

      final raw = utf8.decode(bytes, allowMalformed: true);
      // Return body only (after \r\n\r\n)
      final sep = raw.indexOf('\r\n\r\n');
      return sep >= 0 ? raw.substring(sep + 4) : raw;
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result wrapper
// ─────────────────────────────────────────────────────────────────────────────
class HaImportResult {
  final List<DiscoveredDevice> devices;
  final String? errorMessage;
  bool get isSuccess => errorMessage == null;

  const HaImportResult.success(this.devices) : errorMessage = null;
  const HaImportResult.error(this.errorMessage) : devices = const [];
}
