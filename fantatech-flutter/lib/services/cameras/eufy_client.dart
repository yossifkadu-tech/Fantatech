// eufy_client.dart
// Protocol: Eufy Security proprietary cloud API over HTTPS/REST
//
// Credentials needed:
//   - Eufy Security account email + password (same credentials as the Eufy
//     Security app — not a regular Eufy/Anker account, it must be the
//     eufy Security app login).
//   - No developer registration required.
//
// Notes:
//   - Device types in getCameras() are identified by numeric type codes.
//     Camera types are typically in the range 1-255; this client includes
//     all devices returned by the API and relies on product_name to filter.
//   - getLiveStreamUrl() returns RTMP or RTSP URLs which require a Eufy
//     HomeBase or direct camera connection and may be restricted to LAN-only
//     depending on the camera model and firmware version.
//   - The Eufy API base may change; monitor for HTTP 301/302 redirects.
//   - Eufy two-factor authentication (if enabled) is handled in the app;
//     this client does not implement a 2FA flow.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/cloud_camera.dart';
import '../storage/secure_cred_service.dart';

export '../../models/cloud_camera.dart' show CloudCamera;

class EufyClient {
  static const _apiBase = 'https://mysecurity.eufylife.com/api/v1';

  final String email;
  final String password;

  String? _authToken;

  EufyClient({required this.email, required this.password});

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadPrefs() async {
    _authToken = await SecureCredService.readCameraToken('eufy');
  }

  Future<void> _saveCredentials(String authToken, String userId) async {
    _authToken = authToken;
    await SecureCredService.saveCameraToken('eufy', authToken);
    await SecureCredService.write('cam_userid_eufy', userId);
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Authenticates with Eufy Security using [email] + [password].
  ///
  /// Returns true on success, false on failure.
  /// On success the auth_token and user_id are persisted to SharedPreferences.
  Future<bool> authenticate() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/passport/login'),
        headers: {
          'Content-Type': 'application/json',
          'category': 'Home Security',
          'User-Agent': 'EufySecurity/2.0.0 (Android)',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'client_id': 'eufySecurity',
          'client_Secret': 'anyValue',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Eufy returns res_code == 0 for success.
        final resCode = body['res_code'] as int? ?? -1;
        if (resCode != 0) return false;

        final data = body['data'] as Map<String, dynamic>? ?? {};
        final authToken = data['auth_token'] as String?;
        final userId = data['user_id']?.toString();

        if (authToken != null && userId != null) {
          await _saveCredentials(authToken, userId);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Camera list
  // ---------------------------------------------------------------------------

  /// Returns all Eufy Security cameras linked to the account.
  ///
  /// Includes devices whose [device_type] falls in the typical camera range
  /// (1–255) or whose product name contains "cam" or "doorbell".
  Future<List<CloudCamera>> getCameras() async {
    await _loadPrefs();
    if (_authToken == null) return [];

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/app/get_devs_list'),
        headers: {
          'Content-Type': 'application/json',
          'category': 'Home Security',
          'User-Agent': 'EufySecurity/2.0.0 (Android)',
        },
        body: jsonEncode({
          'auth_token': _authToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final resCode = body['res_code'] as int? ?? -1;
      if (resCode != 0) return [];

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final devices = data['devices'] as List<dynamic>? ?? [];

      return devices
          .whereType<Map<String, dynamic>>()
          .where((d) {
            // Camera device_type is typically in range 1–255.
            final deviceType = d['device_type'] as int? ?? 0;
            final productName = (d['product_name'] as String? ?? '').toLowerCase();
            return (deviceType >= 1 && deviceType <= 255) ||
                productName.contains('cam') ||
                productName.contains('doorbell') ||
                productName.contains('eufycam');
          })
          .map((d) {
            final sn = d['device_sn'] as String? ?? '';
            final name = d['device_name'] as String? ?? 'Eufy Camera';
            final isOnline = d['device_status'] == 1;
            final thumbnail = d['cover_path'] as String?;
            // Construct a best-effort CDN snapshot URL.
            final snapshotUrl = thumbnail ??
                'https://home-cdn.eufylife.com/thumbnail/$sn/latest.jpg';
            return CloudCamera(
              id: sn,
              name: name,
              thumbnailUrl: thumbnail,
              isOnline: isOnline,
              snapshotUrl: snapshotUrl,
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Streaming
  // ---------------------------------------------------------------------------

  /// Starts a live stream for [deviceSn] and returns the RTMP or RTSP URL.
  ///
  /// The URL may be LAN-only depending on the camera model.
  /// [stationSn] defaults to [deviceSn] for standalone cameras;
  /// for cameras attached to a HomeBase, pass the HomeBase serial number.
  Future<String?> getLiveStreamUrl(String deviceSn, [String? stationSn]) async {
    await _loadPrefs();
    if (_authToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/web/equipment/start_livestream'),
        headers: {
          'Content-Type': 'application/json',
          'category': 'Home Security',
          'User-Agent': 'EufySecurity/2.0.0 (Android)',
        },
        body: jsonEncode({
          'auth_token': _authToken,
          'device_sn': deviceSn,
          'station_sn': stationSn ?? deviceSn,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final resCode = body['res_code'] as int? ?? -1;
        if (resCode != 0) return null;

        final data = body['data'] as Map<String, dynamic>? ?? {};
        // Response may contain 'rtsp_url', 'rtmp_url', or just 'url'.
        return (data['rtsp_url'] ?? data['rtmp_url'] ?? data['url']) as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the latest snapshot URL for [deviceSn].
  ///
  /// Uses a CDN pattern URL; actual availability depends on the camera model.
  Future<String?> getSnapshotUrl(String deviceSn) async {
    // Eufy stores thumbnails on their CDN using the device serial number.
    // The URL below is a best-effort pattern; it may return 404 for devices
    // that store snapshots differently.
    return 'https://home-cdn.eufylife.com/thumbnail/$deviceSn/latest.jpg';
  }
}
