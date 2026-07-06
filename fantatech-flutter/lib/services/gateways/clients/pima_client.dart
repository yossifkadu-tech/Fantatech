// PIMA alarm panel client — Net4Pro / Net2Pro local HTTP API
//
// PIMA (by PIMA Electronic Systems) alarm panels connect via their network
// module (Net4Pro or Net2Pro) which exposes a local HTTP/TCP interface.
//
// Protocol:
//   The Net4Pro module runs a basic HTTP API on port 9999 (default).
//   Requests are sent as HTTP GET with query parameters.
//
// Endpoints used:
//   GET /status?code=<pin>               — full system status (zones, outputs)
//   GET /arm?code=<pin>&partition=<id>   — arm a partition (0 = all)
//   GET /disarm?code=<pin>&partition=<id> — disarm a partition
//   GET /zone?code=<pin>                 — zone status list
//
// Note: The exact API paths may vary between Net4Pro firmware versions.
// This implementation uses the most common variant.
import 'dart:convert';
import 'package:http/http.dart' as http;

class PimaZone {
  final int id;
  final String name;
  final bool open;
  final bool alarmed;
  final bool bypass;
  final int? partitionId;

  const PimaZone({
    required this.id,
    required this.name,
    required this.open,
    this.alarmed = false,
    this.bypass = false,
    this.partitionId,
  });

  factory PimaZone.fromJson(Map<String, dynamic> j) => PimaZone(
    id:          j['id']          as int?    ?? 0,
    name:        j['name']        as String? ?? 'Zone ${j['id']}',
    open:        j['open']        as bool?   ?? false,
    alarmed:     j['alarm']       as bool?   ?? false,
    bypass:      j['bypass']      as bool?   ?? false,
    partitionId: j['partition_id'] as int?,
  );
}

class PimaSystemStatus {
  final bool armed;
  final bool alarmed;
  final bool acPower;
  final bool batteryOk;
  final List<PimaZone> zones;

  const PimaSystemStatus({
    required this.armed,
    required this.alarmed,
    required this.acPower,
    required this.batteryOk,
    required this.zones,
  });
}

class PimaClient {
  static const _timeout = Duration(seconds: 6);

  final String _ip;
  final int    _port;
  final String _code;

  PimaClient({
    required String ip,
    required String code,
    int port = 9999,
  })  : _ip   = ip,
        _port = port,
        _code = code;

  String get _base => 'http://$_ip:$_port';

  // ── Status ────────────────────────────────────────────────────────────────

  Future<PimaSystemStatus?> getStatus() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/status?code=$_code'),
      ).timeout(_timeout);

      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final rawZones = body['zones'] as List? ?? [];
      final zones = rawZones
          .whereType<Map<String, dynamic>>()
          .map(PimaZone.fromJson)
          .toList();

      return PimaSystemStatus(
        armed:     body['armed']      as bool? ?? false,
        alarmed:   body['alarm']      as bool? ?? false,
        acPower:   body['ac_power']   as bool? ?? true,
        batteryOk: body['battery_ok'] as bool? ?? true,
        zones:     zones,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Zones ─────────────────────────────────────────────────────────────────

  Future<List<PimaZone>> getZones() async {
    // Try the dedicated zone endpoint first; fall back to status
    try {
      final resp = await http.get(
        Uri.parse('$_base/zone?code=$_code'),
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final list = body is List ? body : (body as Map?)?['zones'] as List?;
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(PimaZone.fromJson)
              .toList();
        }
      }
    } catch (_) {}

    final status = await getStatus();
    return status?.zones ?? [];
  }

  // ── Arm / Disarm ─────────────────────────────────────────────────────────

  Future<bool> arm({int partition = 0}) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/arm?code=$_code&partition=$partition'),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disarm({int partition = 0}) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/disarm?code=$_code&partition=$partition'),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Probe (test connectivity) ─────────────────────────────────────────────

  Future<bool> probe() async {
    final status = await getStatus();
    return status != null;
  }
}
