// arlo_client.dart
// Protocol: Arlo proprietary cloud API over HTTPS/REST
//
// Credentials needed:
//   - Arlo account email + password (the same credentials used in the Arlo app).
//   - No developer registration required.
//
// Notes:
//   - Arlo may require Multi-Factor Authentication (MFA). If authenticate()
//     returns false and no token is stored, MFA may have intercepted the login.
//     Arlo does not provide a simple 2FA continuation endpoint in their unofficial
//     API — users should temporarily disable MFA in the Arlo app if needed.
//   - Supported device types parsed from getCameras():
//       "camera", "arloq", "arloqs", "arloQ", "arloQS"
//   - getLiveStreamUrl() starts an RTSP stream; the URL expires after ~30 seconds
//     of inactivity. Keep the stream active or re-request as needed.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/cloud_camera.dart';
import '../storage/secure_cred_service.dart';

export '../../models/cloud_camera.dart' show CloudCamera;

class ArloClient {
  static const _apiBase = 'https://myapi.arlo.com/hmsweb';

  final String email;
  final String password;

  String? _token;
  String? _userId;

  ArloClient({required this.email, required this.password});

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadPrefs() async {
    _token  = await SecureCredService.readCameraToken('arlo');
    _userId = await SecureCredService.read('cam_userid_arlo');
  }

  Future<void> _saveCredentials(String token, String userId) async {
    _token  = token;
    _userId = userId;
    await SecureCredService.saveCameraToken('arlo', token);
    await SecureCredService.write('cam_userid_arlo', userId);
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Authenticates with Arlo using [email] + [password].
  ///
  /// Returns true on success, false on failure.
  /// On success the token and userId are persisted to SharedPreferences.
  Future<bool> authenticate() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/login/v2'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6)',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final success = body['success'] as bool? ?? false;
        if (!success) return false;

        final data = body['data'] as Map<String, dynamic>? ?? {};
        final token = data['token'] as String?;
        final userId = data['userId'] as String?;

        if (token != null && userId != null) {
          await _saveCredentials(token, userId);
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

  /// Returns all Arlo cameras linked to the account.
  ///
  /// Includes devices with type: "camera", "arloq", "arloqs".
  Future<List<CloudCamera>> getCameras() async {
    await _loadPrefs();
    if (_token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_apiBase/users/devices'),
        headers: {
          'Authorization': _token!,
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) return [];

      final devices = body['data'] as List<dynamic>? ?? [];
      final cameraTypes = {'camera', 'arloq', 'arloqs'};

      return devices
          .whereType<Map<String, dynamic>>()
          .where((d) {
            final type = (d['deviceType'] as String? ?? '').toLowerCase();
            return cameraTypes.contains(type);
          })
          .map((d) {
            final deviceId = d['deviceId'] as String? ?? '';
            final name = d['deviceName'] as String? ?? 'Arlo Camera';
            final isOnline = d['connectivityInfo']?['connected'] == true;
            final thumbnail = d['presignedLastImageUrl'] as String?;
            return CloudCamera(
              id: deviceId,
              name: name,
              thumbnailUrl: thumbnail,
              isOnline: isOnline,
              snapshotUrl: thumbnail,
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

  /// Starts an RTSP stream for [deviceId] and returns the stream URL.
  ///
  /// The stream URL is typically valid for 30 s of inactivity.
  /// Re-call this method to refresh the URL.
  Future<String?> getLiveStreamUrl(String deviceId) async {
    await _loadPrefs();
    if (_token == null || _userId == null) return null;

    final webUserId = '${_userId}_web';
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/users/devices/startStream'),
        headers: {
          'Authorization': _token!,
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6)',
        },
        body: jsonEncode({
          'to': deviceId,
          'from': webUserId,
          'resource': 'cameras/$deviceId',
          'action': 'set',
          'publishResponse': true,
          'transId': '',
          'body': {
            'devices': {
              deviceId: {
                'url': 'rtsp://$deviceId',
              },
            },
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final success = body['success'] as bool? ?? false;
        if (!success) return null;

        final data = body['data'] as Map<String, dynamic>? ?? {};
        return data['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the full-frame snapshot URL for [deviceId].
  ///
  /// Arlo captures a fresh frame and returns a presigned URL.
  Future<String?> getSnapshotUrl(String deviceId) async {
    await _loadPrefs();
    if (_token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_apiBase/users/devices/fullFrameSnapshot'),
        headers: {
          'Authorization': _token!,
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final success = body['success'] as bool? ?? false;
        if (!success) return null;

        final data = body['data'] as Map<String, dynamic>? ?? {};
        return data['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
