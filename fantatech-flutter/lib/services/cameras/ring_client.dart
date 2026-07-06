// ring_client.dart
// Protocol: Ring (Amazon) proprietary cloud API over HTTPS/REST
//
// Credentials needed:
//   - Ring account email + password (the same credentials used in the Ring app)
//   - No developer registration required — Ring uses a fixed first-party app client.
//
// Notes:
//   - Ring 2FA: if authenticate() returns HTTP 412, a 2FA code was sent to the
//     user's phone or email. Call authenticate2fa(twoFaCode) to complete login.
//   - Ring does not publish an official public API; this implementation mirrors
//     the community-documented unofficial endpoint behaviour.
//   - A hardware_id (random UUID) is generated once and stored in SharedPreferences.
//     Ring uses this to identify a "device" across sessions.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // used only for non-sensitive hardware_id
import '../../models/cloud_camera.dart';
import '../storage/secure_cred_service.dart';

export '../../models/cloud_camera.dart' show CloudCamera;

class RingClient {
  static const _apiBase = 'https://oauth.ring.com/oauth/token';
  static const _ringApiBase = 'https://api.ring.com/clients_api';

  final String email;
  final String password;

  String? _accessToken;
  String? _hardwareId;

  RingClient({required this.email, required this.password});

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadPrefs() async {
    _accessToken  = await SecureCredService.readCameraToken('ring');
    // hardware_id is non-sensitive — keep in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _hardwareId = prefs.getString('ring_hardware_id');
    if (_hardwareId == null) {
      _hardwareId = _generateUuid();
      await prefs.setString('ring_hardware_id', _hardwareId!);
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken  = accessToken;
    await SecureCredService.saveCameraToken('ring', accessToken, refresh: refreshToken);
  }

  String _generateUuid() {
    // Simple UUID-v4-like generator without external packages.
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = now.toRadixString(16).padLeft(16, '0');
    return '${rnd.substring(0, 8)}-${rnd.substring(8, 12)}-4${rnd.substring(13, 16)}'
        '-${(8 + now % 4).toRadixString(16)}${rnd.substring(0, 3)}'
        '-${rnd.substring(0, 12)}';
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Authenticates with Ring using email + password.
  ///
  /// Returns true on success.
  /// Returns false on network / parse error.
  /// Throws [RingTwoFactorException] when Ring responds with HTTP 412,
  /// indicating that a 2FA code has been sent — call [authenticate2fa] next.
  Future<bool> authenticate() async {
    await _loadPrefs();
    try {
      final response = await http.post(
        Uri.parse(_apiBase),
        headers: {
          'Content-Type': 'application/json',
          'hardware_id': _hardwareId!,
          'User-Agent': 'android:com.ringapp:2.0.67(423)',
        },
        body: jsonEncode({
          'client_id': 'ring_official_android',
          'grant_type': 'password',
          'username': email,
          'password': password,
          'scope': 'client',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 412) {
        throw RingTwoFactorException(
          'Ring sent a 2FA code to your phone/email. Call authenticate2fa(code).',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        if (accessToken != null && refreshToken != null) {
          await _saveTokens(accessToken, refreshToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e is RingTwoFactorException) rethrow;
      return false;
    }
  }

  /// Completes Ring 2FA login. Pass the code Ring texted / emailed.
  ///
  /// The hardware_id header must match the one sent during [authenticate].
  Future<bool> authenticate2fa(String twoFaCode) async {
    await _loadPrefs();
    try {
      final response = await http.post(
        Uri.parse(_apiBase),
        headers: {
          'Content-Type': 'application/json',
          'hardware_id': _hardwareId!,
          '2fa-support': 'true',
          '2fa-code': twoFaCode,
          'User-Agent': 'android:com.ringapp:2.0.67(423)',
        },
        body: jsonEncode({
          'client_id': 'ring_official_android',
          'grant_type': 'password',
          'username': email,
          'password': password,
          'scope': 'client',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  // ---------------------------------------------------------------------------
  // Camera list
  // ---------------------------------------------------------------------------

  /// Returns all Ring cameras (doorbots + stickup cams) linked to the account.
  Future<List<CloudCamera>> getCameras() async {
    await _loadPrefs();
    if (_accessToken == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_ringApiBase/ring_devices'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'hardware_id': _hardwareId ?? '',
          'User-Agent': 'android:com.ringapp:2.0.67(423)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final cameras = <CloudCamera>[];

      void parseDevices(List<dynamic> devices) {
        for (final device in devices) {
          final d = device as Map<String, dynamic>;
          final id = d['id']?.toString() ?? '';
          final description = d['description'] as Map<String, dynamic>? ?? {};
          final name = description['name'] as String? ?? d['description']?['name'] ?? 'Ring Camera';
          final isOnline = d['alerts']?['connection'] == 'online';
          final snapshotUrl = '$_ringApiBase/snapshots/image/$id';
          cameras.add(CloudCamera(
            id: id,
            name: name,
            isOnline: isOnline,
            snapshotUrl: snapshotUrl,
          ));
        }
      }

      final doorbots = data['authorized_doorbots'] as List<dynamic>? ?? [];
      final stickupCams = data['stickup_cams'] as List<dynamic>? ?? [];
      parseDevices(doorbots);
      parseDevices(stickupCams);

      return cameras;
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Streaming
  // ---------------------------------------------------------------------------

  /// Initiates a live call for [cameraId] and returns the SIP or RTSP URL.
  ///
  /// Note: the returned URL is short-lived (typically valid for a few minutes).
  Future<String?> getLiveStreamUrl(String cameraId) async {
    await _loadPrefs();
    if (_accessToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_ringApiBase/devices/$cameraId/live_call'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'hardware_id': _hardwareId ?? '',
          'Content-Type': 'application/json',
          'User-Agent': 'android:com.ringapp:2.0.67(423)',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // The response embeds a SIP offer or server URL depending on Ring firmware.
        final sessionId = data['session_id'] as String?;
        final server = data['server'] as String?;
        return server ?? sessionId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the snapshot URL for [cameraId].
  ///
  /// The URL requires an Authorization: Bearer header; it cannot be opened in a
  /// plain browser without the token. Use an authenticated http.get() call to
  /// retrieve the JPEG bytes for display.
  Future<String?> getSnapshotUrl(String cameraId) async {
    // The snapshot endpoint returns binary JPEG directly.
    // The URL itself is the authenticated endpoint — include the token in headers.
    return '$_ringApiBase/snapshots/image/$cameraId';
  }
}

/// Thrown when Ring responds with HTTP 412 (Two-Factor Authentication required).
class RingTwoFactorException implements Exception {
  final String message;
  const RingTwoFactorException(this.message);

  @override
  String toString() => 'RingTwoFactorException: $message';
}
