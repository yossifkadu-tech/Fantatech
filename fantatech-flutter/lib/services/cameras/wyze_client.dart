// wyze_client.dart
// Protocol: Wyze proprietary cloud API over HTTPS/REST
//
// Credentials needed:
//   - Wyze account email + password (the same credentials used in the Wyze app).
//   - No developer registration required.
//
// Notes:
//   - Password is sent as an MD5 hex string (Wyze's own hashing scheme).
//   - RTSP streaming requires one of:
//       a) A Wyze Cam with RTSP firmware enabled:
//          Wyze app → Account → Firmware Upgrade → Enable RTSP
//       b) A Wyze Cam Plus subscription (cloud streaming only, not true RTSP).
//     Without RTSP firmware, getLiveStreamUrl() returns a placeholder URL
//     that will not connect.
//   - getCameras() filters by product_type or product_model containing "Cam".
//   - Wyze introduced API key authentication in 2023; this client uses the
//     legacy email/password flow which may stop working if Wyze enforces API keys.

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../models/cloud_camera.dart';
import '../storage/secure_cred_service.dart';

export '../../models/cloud_camera.dart' show CloudCamera;

class WyzeClient {
  static const _apiBase = 'https://api.wyzecam.com';
  // App identity parameters appended to certain requests.
  static const _appVersion = '2.19.14';
  static const _appName = 'com.hualai.WyzeCam';

  final String email;
  final String password;

  String? _accessToken;

  WyzeClient({required this.email, required this.password});

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the MD5 hex digest of [input] (lowercase).
  String _md5Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> _loadPrefs() async {
    _accessToken = await SecureCredService.readCameraToken('wyze');
  }

  Future<void> _saveCredentials(String accessToken, String userId) async {
    _accessToken = accessToken;
    await SecureCredService.saveCameraToken('wyze', accessToken);
    await SecureCredService.write('cam_userid_wyze', userId);
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Authenticates with Wyze using [email] + [password].
  ///
  /// Password is hashed to MD5 before transmission (Wyze requirement).
  /// Returns true on success, false on failure.
  Future<bool> authenticate() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/app/user/login'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'wyze_android/$_appVersion',
        },
        body: jsonEncode({
          'email': email,
          'password': _md5Hash(password),
          'app_name': _appName,
          'app_version': _appVersion,
          'phone_system_type': '1', // 1 = Android
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Wyze wraps data in a 'data' object; top-level 'code' == "1" means success.
        final code = body['code']?.toString();
        if (code != '1') return false;

        final data = body['data'] as Map<String, dynamic>? ?? {};
        final accessToken = data['access_token'] as String?;
        final userId = data['user_id'] as String?;

        if (accessToken != null && userId != null) {
          await _saveCredentials(accessToken, userId);
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

  /// Returns all Wyze cameras linked to the account.
  ///
  /// Filters by product_type == "Camera" or product_model containing "Cam".
  Future<List<CloudCamera>> getCameras() async {
    await _loadPrefs();
    if (_accessToken == null) return [];

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/app/v2/home_page/get_object_list'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'wyze_android/$_appVersion',
        },
        body: jsonEncode({
          'access_token': _accessToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final code = body['code']?.toString();
      if (code != '1') return [];

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final deviceList = data['device_list'] as List<dynamic>? ?? [];

      return deviceList
          .whereType<Map<String, dynamic>>()
          .where((d) {
            final productType = (d['product_type'] as String? ?? '').toLowerCase();
            final productModel = (d['product_model'] as String? ?? '').toLowerCase();
            return productType == 'camera' ||
                productType == 'wyzecam' ||
                productModel.contains('cam');
          })
          .map((d) {
            final mac = d['mac'] as String? ?? '';
            final nickname = d['nickname'] as String? ?? 'Wyze Cam';
            final isOnline = d['conn_state'] == 1;
            final thumbnail = d['device_params']?['camera_thumbnails']?['thumbnails_url'] as String?;
            return CloudCamera(
              id: mac,
              name: nickname,
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

  /// Returns an RTSP URL for [deviceMac].
  ///
  /// IMPORTANT: Wyze RTSP requires RTSP firmware to be enabled on the camera.
  ///   Wyze app → Account → Firmware Upgrade → Enable RTSP
  /// Without the RTSP firmware this URL will not connect.
  ///
  /// The [deviceModel] parameter is used for constructing the stream path.
  Future<String?> getLiveStreamUrl(String deviceMac, [String deviceModel = '']) async {
    await _loadPrefs();
    if (_accessToken == null) return null;

    try {
      // Fetch device info to get stream credentials if available.
      final response = await http.post(
        Uri.parse('$_apiBase/app/v2/device/get_device_info'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'wyze_android/$_appVersion',
        },
        body: jsonEncode({
          'access_token': _accessToken,
          'device_mac': deviceMac,
          'device_model': deviceModel,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};

        // If the API returns an explicit RTSP URL, use it.
        final rtspUrl = data['device_params']?['rtsp_url'] as String?;
        if (rtspUrl != null && rtspUrl.isNotEmpty) return rtspUrl;
      }

      // Fallback: construct a standard Wyze RTSP URL.
      // This only works with RTSP-enabled firmware on the camera.
      return 'rtsp://$deviceMac:$deviceMac@rtsp.wyze.com:1935/';
    } catch (_) {
      // Even on error return the standard RTSP pattern as a best-effort value.
      return 'rtsp://$deviceMac:$deviceMac@rtsp.wyze.com:1935/';
    }
  }

  /// Returns the thumbnail/snapshot URL for [deviceMac].
  Future<String?> getSnapshotUrl(String deviceMac) async {
    await _loadPrefs();
    if (_accessToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/app/v2/device/get_device_info'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'wyze_android/$_appVersion',
        },
        body: jsonEncode({
          'access_token': _accessToken,
          'device_mac': deviceMac,
          'device_model': '',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return data['device_params']?['camera_thumbnails']?['thumbnails_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
