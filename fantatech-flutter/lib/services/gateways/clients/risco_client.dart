// Risco alarm panel client — RiscoCloud REST API
//
// Supports: LightSYS+, ProSYS Plus, Agility 3/4
//
// Protocol: RiscoCloud REST API
//   Base URL: https://www.riscocloud.com/webapi/api
//   Auth: POST /auth/login → JWT token
//   Endpoints used:
//     POST /auth/login        — obtain JWT
//     GET  /wuapiserver/sites — list all sites (panels) on the account
//     GET  /wuapiserver/zones — list all zones (sensors) for a site
//     POST /wuapiserver/arm   — arm a partition
//     POST /wuapiserver/disarm — disarm a partition
//
// For local IP access: Risco uses a proprietary binary TCP protocol on port 1000.
// This client only implements the cloud API.
import 'dart:convert';
import 'package:http/http.dart' as http;

class RiscoZone {
  final int id;
  final String name;
  final String type;   // "PIR", "Magnet", "Smoke", "Flood", etc.
  final bool open;
  final bool alarmed;
  final bool tamper;
  final bool bypass;
  final int? partitionId;

  const RiscoZone({
    required this.id,
    required this.name,
    required this.type,
    required this.open,
    this.alarmed = false,
    this.tamper = false,
    this.bypass = false,
    this.partitionId,
  });

  factory RiscoZone.fromJson(Map<String, dynamic> j) => RiscoZone(
    id:          j['zoneID']   as int?    ?? 0,
    name:        j['zoneName'] as String? ?? 'Zone ${j['zoneID']}',
    type:        j['zoneType'] as String? ?? 'unknown',
    open:        j['status']   as bool?   ?? false,
    alarmed:     j['alarm']    as bool?   ?? false,
    tamper:      j['tamper']   as bool?   ?? false,
    bypass:      j['bypass']   as bool?   ?? false,
    partitionId: j['partID']   as int?,
  );
}

class RiscoClient {
  static const _base    = 'https://www.riscocloud.com/webapi/api';
  static const _timeout = Duration(seconds: 10);

  final String _username;
  final String _password;
  final String _pin;

  String? _token;
  String? _siteId;

  RiscoClient({
    required String username,
    required String password,
    required String pin,
    // localIp reserved for future local-protocol support
    String? localIp,
  })  : _username = username,
        _password = password,
        _pin      = pin;

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<bool> login() async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': _username,
          'password': _password,
          'languageId': 'en',
        }),
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        _token = body['access_token'] as String? ??
                 body['token']        as String?;
        return _token != null;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _ensureLoggedIn() async {
    if (_token != null) return true;
    return login();
  }

  Future<String?> _getSiteId() async {
    if (_siteId != null) return _siteId;
    try {
      final resp = await http.get(
        Uri.parse('$_base/wuapiserver/sites'),
        headers: _headers(),
      ).timeout(_timeout);
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body);
        if (list is List && list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          _siteId = first['siteId']?.toString() ??
                    first['id']?.toString();
          return _siteId;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Zones (sensors) ──────────────────────────────────────────────────────

  Future<List<RiscoZone>> getZones() async {
    if (!await _ensureLoggedIn()) return [];
    final siteId = await _getSiteId();
    if (siteId == null) return [];

    try {
      final resp = await http.get(
        Uri.parse('$_base/wuapiserver/zones?siteId=$siteId'),
        headers: _headers(),
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final list = body is List ? body : (body as Map?)?['zones'] as List?;
        return list?.whereType<Map<String, dynamic>>()
            .map(RiscoZone.fromJson).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }

  // ── Arm / Disarm ─────────────────────────────────────────────────────────

  Future<bool> arm({int partitionId = 0}) async {
    if (!await _ensureLoggedIn()) return false;
    final siteId = await _getSiteId();
    if (siteId == null) return false;
    try {
      final resp = await http.post(
        Uri.parse('$_base/wuapiserver/arm'),
        headers: _headers(withContentType: true),
        body: jsonEncode({
          'siteId':      siteId,
          'partitionId': partitionId,
          'userCode':    _pin,
        }),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disarm({int partitionId = 0}) async {
    if (!await _ensureLoggedIn()) return false;
    final siteId = await _getSiteId();
    if (siteId == null) return false;
    try {
      final resp = await http.post(
        Uri.parse('$_base/wuapiserver/disarm'),
        headers: _headers(withContentType: true),
        body: jsonEncode({
          'siteId':      siteId,
          'partitionId': partitionId,
          'userCode':    _pin,
        }),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _headers({bool withContentType = false}) {
    final h = <String, String>{
      'Authorization': 'Bearer ${_token ?? ''}',
    };
    if (withContentType) h['Content-Type'] = 'application/json';
    return h;
  }
}
