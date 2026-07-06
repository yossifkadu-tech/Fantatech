// nest_cam_client.dart
// Protocol: Google Smart Device Management (SDM) API over HTTPS/REST + OAuth 2.0
//
// Credentials needed:
//   - Google Cloud project OAuth 2.0 Client ID + Client Secret.
//   - Google Nest Developer Program project ID.
//
// How to obtain credentials:
//   1. Go to https://console.cloud.google.com and create (or select) a project.
//   2. Enable the "Smart Device Management API" in the API Library.
//   3. Create OAuth 2.0 credentials (type: "Web application" or "Desktop app").
//      Note the Client ID and Client Secret.
//   4. Enrol in the Nest Device Access programme at
//      https://developers.google.com/nest/device-access
//      (one-time $5 USD registration fee as of 2024).
//   5. Create a project in the Device Access Console; note the Project ID.
//   6. Add your OAuth Client ID to the Device Access project.
//
// OAuth flow:
//   a. Call getAuthUrl(redirectUri) to get the Google consent-page URL.
//   b. Open the URL in a browser / WebView; the user grants permissions.
//   c. Google redirects to redirectUri with a `code` query parameter.
//   d. Call exchangeCode(code, redirectUri) to trade the code for tokens.
//
// Notes:
//   - RTSP streams from SDM are short-lived (5 minutes by default).
//     Re-call generateRtspStream() or call extendRtspStream() to keep alive.
//   - Supported camera types: CAMERA, DISPLAY (Nest Hub), DOORBELL.
//   - Token refresh happens automatically inside getCameras() and
//     generateRtspStream() when the access token is expired.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/cloud_camera.dart';
import '../storage/secure_cred_service.dart';

export '../../models/cloud_camera.dart' show CloudCamera;

class NestCamClient {
  static const _sdmBase =
      'https://smartdevicemanagement.googleapis.com/v1';
  static const _oauthBase = 'https://oauth2.googleapis.com';
  static const _authBase = 'https://accounts.google.com/o/oauth2/v2/auth';

  final String clientId;
  final String clientSecret;
  final String projectId;

  String? _accessToken;
  String? _refreshToken;

  NestCamClient({
    required this.clientId,
    required this.clientSecret,
    required this.projectId,
  });

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadPrefs() async {
    _accessToken  = await SecureCredService.readCameraToken('nest');
    _refreshToken = await SecureCredService.readCameraRefresh('nest');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken  = accessToken;
    _refreshToken = refreshToken;
    await SecureCredService.saveCameraToken('nest', accessToken, refresh: refreshToken);
  }

  Future<void> _saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
    await SecureCredService.saveCameraToken('nest', accessToken);
  }

  // ---------------------------------------------------------------------------
  // OAuth helpers
  // ---------------------------------------------------------------------------

  /// Returns the Google OAuth 2.0 consent-page URL.
  ///
  /// Open this URL in a browser or WebView. After the user grants permission
  /// Google redirects to [redirectUri]?code=<AUTH_CODE>.
  /// Pass that code to [exchangeCode].
  String getAuthUrl(String redirectUri) {
    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'https://www.googleapis.com/auth/sdm.service',
      'access_type': 'offline',
      'prompt': 'consent', // forces refresh_token to be issued every time
    };
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$_authBase?$query';
  }

  /// Exchanges an authorization [code] (from the OAuth redirect) for tokens.
  ///
  /// [redirectUri] must match exactly what was used in [getAuthUrl].
  /// Returns true on success, false on failure.
  Future<bool> exchangeCode(String code, String redirectUri) async {
    try {
      final response = await http.post(
        Uri.parse('$_oauthBase/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        if (accessToken != null && refreshToken != null) {
          await _saveTokens(accessToken, refreshToken);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Returns true on success. Called automatically by other methods.
  Future<bool> refreshAccessToken() async {
    await _loadPrefs();
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_oauthBase/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': _refreshToken!,
          'grant_type': 'refresh_token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          await _saveAccessToken(accessToken);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Ensures a valid access token is present, refreshing if needed.
  Future<bool> _ensureToken() async {
    await _loadPrefs();
    if (_accessToken != null) return true;
    return refreshAccessToken();
  }

  // ---------------------------------------------------------------------------
  // Camera list
  // ---------------------------------------------------------------------------

  /// Returns all Nest cameras (cameras, displays, doorbells) in the project.
  ///
  /// Automatically attempts a token refresh if the initial request returns 401.
  Future<List<CloudCamera>> getCameras() async {
    if (!await _ensureToken()) return [];

    Future<http.Response> makeRequest() => http.get(
          Uri.parse('$_sdmBase/enterprises/$projectId/devices'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

    try {
      var response = await makeRequest();

      // Attempt one token refresh on 401.
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) return [];
        response = await makeRequest();
      }

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final devices = body['devices'] as List<dynamic>? ?? [];

      const cameraTypes = {
        'sdm.devices.types.CAMERA',
        'sdm.devices.types.DISPLAY',
        'sdm.devices.types.DOORBELL',
      };

      return devices
          .whereType<Map<String, dynamic>>()
          .where((d) => cameraTypes.contains(d['type'] as String?))
          .map((d) {
            final name = d['name'] as String? ?? '';
            final traits = d['traits'] as Map<String, dynamic>? ?? {};
            final displayName =
                traits['sdm.devices.traits.Info']?['customName'] as String? ??
                    name.split('/').last;
            final connectivity =
                traits['sdm.devices.traits.Connectivity']?['status'] as String?;
            final isOnline = connectivity == 'ONLINE';
            return CloudCamera(
              id: name, // full resource name used as ID
              name: displayName,
              isOnline: isOnline,
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

  /// Generates a short-lived RTSP stream for the device identified by
  /// [deviceName] (the full resource name from [getCameras], e.g.
  /// `enterprises/<projectId>/devices/<deviceId>`).
  ///
  /// The stream is valid for approximately 5 minutes. Extend it with
  /// [extendRtspStream] or call this method again to get a new URL.
  Future<String?> generateRtspStream(String deviceName) async {
    if (!await _ensureToken()) return null;

    Future<http.Response> makeRequest() => http.post(
          Uri.parse('$_sdmBase/$deviceName:executeCommand'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'command': 'sdm.devices.commands.CameraLiveStream.GenerateRtspStream',
            'params': {},
          }),
        ).timeout(const Duration(seconds: 10));

    try {
      var response = await makeRequest();

      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) return null;
        response = await makeRequest();
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final results = body['results'] as Map<String, dynamic>? ?? {};
        final streamUrls =
            results['streamUrls'] as Map<String, dynamic>? ?? {};
        return streamUrls['rtspUrl'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Convenience wrapper required by the [CloudCamera] contract.
  ///
  /// [cameraId] should be the full device resource name returned in [getCameras].
  Future<String?> getLiveStreamUrl(String cameraId) =>
      generateRtspStream(cameraId);

  /// Returns null — the SDM API does not expose a static snapshot URL.
  ///
  /// Use [generateRtspStream] and capture a frame from the RTSP stream instead,
  /// or use the `sdm.devices.commands.CameraEventImage.GenerateImage` command
  /// (available only in response to a camera event webhook).
  Future<String?> getSnapshotUrl(String cameraId) async => null;

  // ---------------------------------------------------------------------------
  // Stream lifecycle
  // ---------------------------------------------------------------------------

  /// Extends an existing RTSP stream (identified by [streamExtensionToken])
  /// by another 5 minutes.
  ///
  /// [streamExtensionToken] is found in the `results.streamExtensionToken`
  /// field of the [generateRtspStream] response body.
  Future<bool> extendRtspStream(
      String deviceName, String streamExtensionToken) async {
    if (!await _ensureToken()) return false;

    try {
      final response = await http.post(
        Uri.parse('$_sdmBase/$deviceName:executeCommand'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'command':
              'sdm.devices.commands.CameraLiveStream.ExtendRtspStream',
          'params': {
            'streamExtensionToken': streamExtensionToken,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Stops an active RTSP stream (identified by [streamExtensionToken]).
  Future<bool> stopRtspStream(
      String deviceName, String streamExtensionToken) async {
    if (!await _ensureToken()) return false;

    try {
      final response = await http.post(
        Uri.parse('$_sdmBase/$deviceName:executeCommand'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'command': 'sdm.devices.commands.CameraLiveStream.StopRtspStream',
          'params': {
            'streamExtensionToken': streamExtensionToken,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
