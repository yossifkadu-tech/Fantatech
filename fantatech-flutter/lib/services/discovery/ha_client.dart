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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'discovery_models.dart';
import 'device_classifier.dart';
import '../storage/secure_cred_service.dart';

class HaClient {
  static const _port    = 8123;
  static const _timeout = Duration(seconds: 8);

  // ── Persistence (encrypted) ───────────────────────────────────────────────

  static Future<String?> savedToken() => SecureCredService.readHaToken();
  static Future<String?> savedIp()    => SecureCredService.readHaIp();

  static Future<void> saveCredentials(String ip, String token) =>
      SecureCredService.saveHaCredentials(ip, token);

  static Future<void> clearCredentials() =>
      SecureCredService.clearHaCredentials();

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
      if (raw == null) return HaImportResult.error('No response from Home Assistant — check IP and network');

      final List<dynamic> states;
      try {
        states = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        if (raw.contains('401') || raw.contains('Unauthorized')) {
          return HaImportResult.error('Invalid token — create a Long-Lived Access Token in HA');
        }
        return HaImportResult.error('Unexpected response from Home Assistant');
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

        // Skip sensor entities that are system/virtual (Sun, Backup, timestamps)
        if (domain == 'sensor') {
          const physicalClasses = {
            'temperature', 'humidity', 'pressure', 'energy', 'power',
            'voltage', 'current', 'battery', 'illuminance', 'gas',
            'moisture', 'co2', 'pm25', 'pm10', 'carbon_dioxide',
            'carbon_monoxide', 'motion', 'door', 'window', 'smoke',
            'sound', 'vibration', 'water', 'weight',
          };
          if (deviceClass == null || !physicalClasses.contains(deviceClass)) continue;
        }

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
            'isOn':        _stateIsOn(stateVal),
            'deviceClass': deviceClass,
            'haIp':        ip,
            // Preserve useful HA attributes
            if (attrs['brightness'] != null)
              'brightness': ((attrs['brightness'] as num) / 2.55).round(),
            if (attrs['color_temp_kelvin'] != null)
              'colorTempKelvin': attrs['color_temp_kelvin'],
            if (attrs['battery'] != null) 'battery': attrs['battery'],
            if (attrs['current_position'] != null)
              'blindLevel': attrs['current_position'],
          },
        ));
      }

      await saveCredentials(ip, token);
      return HaImportResult.success(devices);
    } catch (e) {
      return HaImportResult.error('Network error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _stateIsOn(String state) {
    switch (state.toLowerCase()) {
      case 'on':
      case 'open':
      case 'unlocked':
      case 'heat':
      case 'cool':
      case 'auto':
      case 'home':
        return true;
      default:
        final n = double.tryParse(state);
        return n != null && n > 0;
    }
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────────

  static Map<String, String> _headers([String? token]) => {
        'Accept':       'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<String?> _get(String ip, String path) async {
    try {
      final uri = Uri.parse('http://$ip:$_port$path');
      final res = await http.get(uri, headers: _headers())
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300 ? res.body : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getAuth(String ip, String path, String token) async {
    try {
      final uri = Uri.parse('http://$ip:$_port$path');
      final res = await http.get(uri, headers: _headers(token))
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300 ? res.body : null;
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
