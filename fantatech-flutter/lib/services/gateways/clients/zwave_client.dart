// Z-Wave JS UI (zwavejs2mqtt) REST API client
//
// Z-Wave JS UI exposes a local REST API on port 8091 (default).
// It bridges Z-Wave devices to MQTT and REST, exposing all paired Z-Wave nodes.
//
// Endpoints used:
//   GET  /api/nodes            — list all Z-Wave nodes
//   GET  /api/nodes/:nodeId    — get single node details
//   POST /api/nodes/:nodeId/values/:valueId — set a value on a node
//
// Authentication: optional Bearer token if enabled in Z-Wave JS UI settings.
//
// Docs: https://zwave-js.github.io/zwave-js-ui/
import 'dart:convert';
import 'package:http/http.dart' as http;

class ZWaveNode {
  final int nodeId;
  final String name;
  final String manufacturer;
  final String productLabel;
  final String deviceClass;    // "Binary Switch", "Multilevel Sensor", etc.
  final bool ready;
  final bool failed;
  final bool isOn;
  final int? battery;
  final Map<String, dynamic> values;

  const ZWaveNode({
    required this.nodeId,
    required this.name,
    required this.manufacturer,
    required this.productLabel,
    required this.deviceClass,
    required this.ready,
    required this.failed,
    required this.isOn,
    this.battery,
    this.values = const {},
  });

  factory ZWaveNode.fromJson(Map<String, dynamic> j) {
    final vals = j['values'] as Map<String, dynamic>? ?? {};

    // Try to infer on/off state from common value keys
    bool isOn = false;
    for (final key in ['37-0-currentValue', '38-0-currentValue', 'currentValue']) {
      if (vals.containsKey(key)) {
        final v = vals[key];
        if (v is bool) { isOn = v; break; }
        if (v is int)  { isOn = v > 0; break; }
      }
    }

    // Battery from value "128-0-level" or "battery"
    int? battery;
    final battVal = vals['128-0-level'] ?? j['battery'];
    if (battVal is int) battery = battVal;

    return ZWaveNode(
      nodeId:       j['nodeId']          as int?    ?? 0,
      name:         j['name']            as String? ??
                    j['productDescription'] as String? ??
                    'Z-Wave Node ${j['nodeId']}',
      manufacturer: j['manufacturer']    as String? ?? '',
      productLabel: j['productLabel']    as String? ?? '',
      deviceClass:  (j['deviceClass'] as Map?)?['specific']?['label'] as String? ??
                    j['deviceClass']?.toString() ?? 'unknown',
      ready:        j['ready']           as bool?   ?? false,
      failed:       j['failed']          as bool?   ?? false,
      isOn:         isOn,
      battery:      battery,
      values:       vals,
    );
  }
}

class ZWaveClient {
  static const _timeout = Duration(seconds: 8);

  final String  _ip;
  final int     _port;
  final String? _apiKey;

  ZWaveClient({
    required String ip,
    int port = 8091,
    String? apiKey,
  })  : _ip     = ip,
        _port   = port,
        _apiKey = apiKey;

  String get _base => 'http://$_ip:$_port';

  // ── Nodes ─────────────────────────────────────────────────────────────────

  Future<List<ZWaveNode>> getNodes() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/api/nodes'),
        headers: _headers(),
      ).timeout(_timeout);

      if (resp.statusCode != 200) return [];

      final body = jsonDecode(resp.body);
      final map  = body is Map ? body : null;
      final list = body is List ? body
          : map?['data'] as List?
          ?? map?['nodes'] as List?;

      return list?.whereType<Map<String, dynamic>>()
          .map(ZWaveNode.fromJson)
          .toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Control ───────────────────────────────────────────────────────────────

  /// Set the on/off state of a binary switch node.
  Future<bool> setOnOff(int nodeId, bool on) async {
    return _setValue(nodeId, '37-0-targetValue', on);
  }

  /// Set a multilevel switch (dimmer) level 0–99.
  Future<bool> setLevel(int nodeId, int level) async {
    return _setValue(nodeId, '38-0-targetValue', level.clamp(0, 99));
  }

  Future<bool> _setValue(int nodeId, String valueId, dynamic value) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/api/nodes/$nodeId/values/$valueId'),
        headers: _headers(withContentType: true),
        body: jsonEncode({'value': value}),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Probe ──────────────────────────────────────────────────────────────────

  Future<bool> probe() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/health'),
        headers: _headers(),
      ).timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      // Try nodes endpoint as fallback
      final nodes = await getNodes();
      return nodes.isNotEmpty;
    }
  }

  Map<String, String> _headers({bool withContentType = false}) {
    final h = <String, String>{};
    if (_apiKey?.isNotEmpty == true) {
      h['Authorization'] = 'Bearer $_apiKey';
    }
    if (withContentType) h['Content-Type'] = 'application/json';
    return h;
  }
}
