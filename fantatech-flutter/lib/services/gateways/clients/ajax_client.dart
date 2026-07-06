// Ajax Systems Cloud API client
//
// Ajax Systems exposes a REST Cloud API:
//   Base URL: https://ajax.systems/api/
//   Auth: Basic auth (email + password) or API key as Bearer token
//   Endpoints used:
//     POST /auth             — obtain session token
//     GET  /hub/list         — list all hubs on the account
//     GET  /device/list      — list all devices on a hub
//     POST /device/arm       — arm the alarm
//     POST /device/disarm    — disarm the alarm
//
// Docs: https://ajax.systems/products/api/
import 'dart:convert';
import 'package:http/http.dart' as http;

class AjaxDevice {
  final String id;
  final String name;
  final String type;    // "MotionProtect", "DoorProtect", "FireProtect", etc.
  final String hubId;
  final bool online;
  final int? battery;
  final bool alarmed;

  const AjaxDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.hubId,
    required this.online,
    this.battery,
    this.alarmed = false,
  });

  factory AjaxDevice.fromJson(Map<String, dynamic> j, String hubId) => AjaxDevice(
    id:      j['id']?.toString()         ?? '',
    name:    j['name']   as String?      ?? 'Ajax Device',
    type:    j['type']   as String?      ?? 'unknown',
    hubId:   hubId,
    online:  j['online'] as bool?        ?? false,
    battery: j['battery'] as int?,
    alarmed: j['alarmed'] as bool?       ?? false,
  );
}

class AjaxClient {
  static const _base    = 'https://ajax.systems/api';
  static const _timeout = Duration(seconds: 10);

  final String _email;
  final String _password;
  final String? _apiKey;

  String? _sessionToken;

  AjaxClient({
    required String email,
    required String password,
    String? apiKey,
  })  : _email    = email,
        _password = password,
        _apiKey   = apiKey;

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<bool> login() async {
    if (_apiKey?.isNotEmpty == true) {
      _sessionToken = _apiKey;
      return true;
    }
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email, 'password': _password}),
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        _sessionToken = body['token'] as String? ?? body['access_token'] as String?;
        return _sessionToken != null;
      }
    } catch (_) {}
    return false;
  }

  // ── Devices ──────────────────────────────────────────────────────────────

  Future<List<AjaxDevice>> getDevices() async {
    if (_sessionToken == null) {
      final ok = await login();
      if (!ok) return [];
    }

    try {
      // 1. list hubs
      final hubResp = await http.get(
        Uri.parse('$_base/hub/list'),
        headers: _headers(),
      ).timeout(_timeout);

      if (hubResp.statusCode != 200) return [];
      final hubs = (jsonDecode(hubResp.body) as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ?? [];

      final devices = <AjaxDevice>[];
      for (final hub in hubs) {
        final hubId = hub['id']?.toString() ?? '';
        if (hubId.isEmpty) continue;

        final devResp = await http.get(
          Uri.parse('$_base/device/list?hubId=$hubId'),
          headers: _headers(),
        ).timeout(_timeout);

        if (devResp.statusCode == 200) {
          final list = jsonDecode(devResp.body);
          if (list is List) {
            devices.addAll(list
                .whereType<Map<String, dynamic>>()
                .map((d) => AjaxDevice.fromJson(d, hubId)));
          }
        }
      }
      return devices;
    } catch (_) {
      return [];
    }
  }

  Future<bool> arm(String hubId) async => _command('$_base/device/arm', hubId);
  Future<bool> disarm(String hubId) async => _command('$_base/device/disarm', hubId);

  Future<bool> _command(String url, String hubId) async {
    if (_sessionToken == null) await login();
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: _headers(withContentType: true),
        body: jsonEncode({'hubId': hubId}),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _headers({bool withContentType = false}) {
    final h = <String, String>{'Authorization': 'Bearer ${_sessionToken ?? ''}'};
    if (withContentType) h['Content-Type'] = 'application/json';
    return h;
  }
}
