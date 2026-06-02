// ─────────────────────────────────────────────────────────────────────────────
// SmartSwitchScanner
//
// חיפוש מפסקים חכמים אמיתיים על רשת ה-LAN:
//
//   ┌──────────┬────────────────────────────────────────────────────────────┐
//   │ מותג     │ שיטת גילוי                                                 │
//   ├──────────┼────────────────────────────────────────────────────────────┤
//   │ Shelly   │ Gen1: GET /shelly → JSON model                             │
//   │          │ Gen2/3: POST /rpc/Shelly.GetDeviceInfo → JSON              │
//   │          │ mDNS: _shelly._tcp                                         │
//   ├──────────┼────────────────────────────────────────────────────────────┤
//   │ Sonoff   │ mDNS: _ewelink._tcp (port 8081)                            │
//   │          │ HTTP: GET /zeroconf/info → JSON                            │
//   │          │ HTTP banner: "eWeLink" / "iTead"                           │
//   ├──────────┼────────────────────────────────────────────────────────────┤
//   │ Tuya     │ TCP port 6668 / 6669 (LAN API)                             │
//   │          │ HTTP port 80: banner כולל "Tuya" / "ty_iot"               │
//   │          │ mDNS: _tuya._tcp / _smartlife._tcp                         │
//   └──────────┴────────────────────────────────────────────────────────────┘
//
// כל מכשיר שנמצא חוזר כ-DiscoveredSwitch עם פרטי חיבור מלאים.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'discovery_models.dart';
import 'device_classifier.dart';

// ── Result model ─────────────────────────────────────────────────────────────

enum SwitchBrand { shelly, sonoff, tuya, unknown }

class DiscoveredSwitch {
  final String id;
  final String ip;
  final String name;
  final SwitchBrand brand;
  final String? model;
  final String? firmwareVersion;
  final String? mac;
  final int? channels;        // number of relay channels
  final bool hasPowerMeter;   // energy monitoring?
  final List<int> openPorts;
  final DiscoveredDeviceType deviceType;

  // Connection details
  final String? apiBaseUrl;   // e.g. http://192.168.1.55
  final String? localKey;     // Tuya local key (if known)

  const DiscoveredSwitch({
    required this.id,
    required this.ip,
    required this.name,
    required this.brand,
    this.model,
    this.firmwareVersion,
    this.mac,
    this.channels,
    this.hasPowerMeter = false,
    this.openPorts = const [],
    this.deviceType = DiscoveredDeviceType.smartSwitch,
    this.apiBaseUrl,
    this.localKey,
  });

  @override
  String toString() =>
      '${brand.name.toUpperCase()} | $name | $ip${model != null ? " | $model" : ""}';
}

// ── Scanner ──────────────────────────────────────────────────────────────────

class SmartSwitchScanner {
  static const _timeout  = Duration(milliseconds: 1200);
  static const _httpTime = Duration(milliseconds: 900);

  // All ports relevant to smart switches
  static const _scanPorts = [
    80,    // HTTP (Shelly Gen1, Sonoff HTTP, Tuya)
    8080,  // alt HTTP
    8081,  // Sonoff LAN API (eWeLink)
    8083,  // Sonoff alt
    6668,  // Tuya LAN API (TCP)
    6669,  // Tuya LAN API alt
    1883,  // MQTT (Z2M, HA)
    502,   // Modbus (Shelly EM)
  ];

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Scan an entire /24 subnet and yield discovered switches.
  static Stream<DiscoveredSwitch> scanSubnet(
    String subnetPrefix, {
    int concurrency = 25,
    void Function(int done, int total)? onProgress,
  }) async* {
    int done = 0;
    const total = 254;

    for (int batch = 1; batch <= total; batch += concurrency) {
      final end = (batch + concurrency - 1).clamp(1, total);
      final futures = <Future<DiscoveredSwitch?>>[];

      for (int i = batch; i <= end; i++) {
        futures.add(probeHost('$subnetPrefix.$i'));
      }

      final results = await Future.wait(futures);
      done += (end - batch + 1);
      onProgress?.call(done, total);

      for (final sw in results) {
        if (sw != null) yield sw;
      }
    }
  }

  /// Probe a single host.  Returns null if not a smart switch.
  static Future<DiscoveredSwitch?> probeHost(String ip) async {
    // Step 1: quick port scan
    final openPorts = await _scanPorts_(ip);
    if (openPorts.isEmpty) return null;

    // Step 2: brand-specific fingerprinting in priority order
    final sw = await _tryShelly(ip, openPorts) ??
               await _trySonoff(ip, openPorts) ??
               await _tryTuya(ip, openPorts);

    return sw;
  }

  // ── Shelly ────────────────────────────────────────────────────────────────────

  static Future<DiscoveredSwitch?> _tryShelly(
      String ip, List<int> openPorts) async {
    if (!openPorts.contains(80) && !openPorts.contains(8080)) return null;
    final httpPort = openPorts.contains(80) ? 80 : 8080;

    // --- Gen1: GET /shelly ---------------------------------------------------
    final gen1 = await _httpGet(ip, httpPort, '/shelly');
    if (gen1 != null) {
      final body = _body(gen1);
      if (body.contains('"type"') || body.contains('"model"')) {
        try {
          final j = jsonDecode(body) as Map<String, dynamic>;
          final model   = (j['type'] ?? j['model'] ?? j['app']) as String? ?? 'Shelly';
          final mac     = j['mac'] as String?;
          final fw      = j['fw'] as String?;
          final type    = DeviceClassifier.classifyShellyModel(model);

          // How many channels?
          int? channels;
          if (model.contains('-25') || model.contains('-PM25')) channels = 2;
          else if (model.contains('-4') || model.contains('4PM')) channels = 4;
          else channels = 1;

          return DiscoveredSwitch(
            id:           mac?.replaceAll(':', '') ?? 'shelly_${ip.replaceAll('.','_')}',
            ip:           ip,
            name:         _shellyFriendlyName(model),
            brand:        SwitchBrand.shelly,
            model:        model,
            firmwareVersion: fw,
            mac:          mac,
            channels:     channels,
            hasPowerMeter: model.contains('PM') || model.contains('EM'),
            openPorts:    openPorts,
            deviceType:   type,
            apiBaseUrl:   'http://$ip',
          );
        } catch (_) {}
      }
    }

    // --- Gen2 / Gen3: POST /rpc/Shelly.GetDeviceInfo -------------------------
    final gen2body = '{"id":1,"method":"Shelly.GetDeviceInfo","params":{}}';
    final gen2 = await _httpPost(ip, httpPort, '/rpc', gen2body);
    if (gen2 != null) {
      final body = _body(gen2);
      if (body.contains('"result"') && body.contains('"model"')) {
        try {
          final j      = jsonDecode(body) as Map<String, dynamic>;
          final result = j['result'] as Map<String, dynamic>? ?? {};
          final model  = result['model']  as String? ?? 'Shelly Gen2';
          final mac    = result['mac']    as String?;
          final fw     = result['ver']    as String?;
          final app    = result['app']    as String? ?? model;
          final type   = DeviceClassifier.classifyShellyModel(model);

          return DiscoveredSwitch(
            id:           mac?.replaceAll(':', '') ?? 'shellyg2_${ip.replaceAll('.','_')}',
            ip:           ip,
            name:         _shellyFriendlyName(app),
            brand:        SwitchBrand.shelly,
            model:        model,
            firmwareVersion: fw,
            mac:          mac,
            hasPowerMeter: model.toLowerCase().contains('pm') ||
                           app.toLowerCase().contains('plus') ||
                           app.toLowerCase().contains('pro'),
            openPorts:    openPorts,
            deviceType:   type,
            apiBaseUrl:   'http://$ip',
          );
        } catch (_) {}
      }
    }

    return null;
  }

  static String _shellyFriendlyName(String model) {
    final m = model.toUpperCase();
    if (m.contains('SHSW-1'))   return 'Shelly 1 (Relay)';
    if (m.contains('SHSW-PM'))  return 'Shelly 1PM (Energy)';
    if (m.contains('SHSW-25'))  return 'Shelly 2.5 (2 channels)';
    if (m.contains('SHPLG'))    return 'Shelly Plug';
    if (m.contains('SHEM'))     return 'Shelly EM (Energy Meter)';
    if (m.contains('SHBDUO'))   return 'Shelly Duo (Bulb)';
    if (m.contains('SHRGBW'))   return 'Shelly RGBW';
    if (m.contains('SHUNI'))    return 'Shelly UNI';
    if (m.startsWith('SHIX3'))  return 'Shelly i3 (Input)';
    if (m.contains('PLUS1PM'))  return 'Shelly Plus 1PM';
    if (m.contains('PLUS2PM'))  return 'Shelly Plus 2PM';
    if (m.contains('PLUS4PM'))  return 'Shelly Plus 4PM';
    if (m.contains('PRO4PM'))   return 'Shelly Pro 4PM';
    if (m.contains('MINI'))     return 'Shelly Mini';
    return 'Shelly $model';
  }

  // ── Sonoff ────────────────────────────────────────────────────────────────────

  static Future<DiscoveredSwitch?> _trySonoff(
      String ip, List<int> openPorts) async {
    // Sonoff LAN API runs on port 8081 (eWeLink)
    final port = openPorts.contains(8081) ? 8081
               : openPorts.contains(8083) ? 8083
               : openPorts.contains(80)   ? 80
               : null;
    if (port == null) return null;

    // --- GET /zeroconf/info --------------------------------------------------
    final resp = await _httpGet(ip, port, '/zeroconf/info');
    if (resp != null) {
      final body = _body(resp);
      if (body.contains('error') || body.contains('deviceid') ||
          body.contains('eWeLink') || body.contains('iTead')) {
        try {
          // Try to parse device info
          final j = jsonDecode(body.isEmpty ? '{}' : body) as Map<String, dynamic>;
          final data = (j['data'] as Map?)?.cast<String, dynamic>() ?? {};
          final deviceId  = data['deviceid']   as String? ?? ip.replaceAll('.','');
          final model     = data['productModel'] as String? ??
                            data['extra']?['model'] as String? ?? 'Sonoff';
          final fw        = data['fwVersion']  as String?;

          return DiscoveredSwitch(
            id:           'sonoff_$deviceId',
            ip:           ip,
            name:         _sonoffFriendlyName(model),
            brand:        SwitchBrand.sonoff,
            model:        model,
            firmwareVersion: fw,
            openPorts:    openPorts,
            deviceType:   DiscoveredDeviceType.smartSwitch,
            apiBaseUrl:   'http://$ip:$port',
          );
        } catch (_) {}

        // At least we know it's Sonoff/eWeLink
        return DiscoveredSwitch(
          id:        'sonoff_${ip.replaceAll('.','_')}',
          ip:        ip,
          name:      'Sonoff ($ip)',
          brand:     SwitchBrand.sonoff,
          openPorts: openPorts,
          deviceType: DiscoveredDeviceType.smartSwitch,
          apiBaseUrl: 'http://$ip:$port',
        );
      }
    }

    // --- Fallback: check HTTP banner for "eWeLink" / "iTead" ----------------
    if (openPorts.contains(80)) {
      final banner = await _httpGet(ip, 80, '/');
      if (banner != null) {
        final b = banner.toLowerCase();
        if (b.contains('ewelink') || b.contains('itead') || b.contains('sonoff')) {
          return DiscoveredSwitch(
            id:        'sonoff_${ip.replaceAll('.','_')}',
            ip:        ip,
            name:      'Sonoff ($ip)',
            brand:     SwitchBrand.sonoff,
            openPorts: openPorts,
            deviceType: DiscoveredDeviceType.smartSwitch,
            apiBaseUrl: 'http://$ip',
          );
        }
      }
    }

    return null;
  }

  static String _sonoffFriendlyName(String model) {
    final m = model.toUpperCase();
    if (m.contains('MINI'))     return 'Sonoff Mini R2';
    if (m.contains('BASIC'))    return 'Sonoff Basic';
    if (m.contains('POW'))      return 'Sonoff POW (Energy)';
    if (m.contains('DUAL'))     return 'Sonoff Dual (2ch)';
    if (m.contains('4CH'))      return 'Sonoff 4CH (4ch)';
    if (m.contains('ZBMINI'))   return 'Sonoff ZBMINI (Zigbee)';
    if (m.contains('ZBBRIDGE')) return 'Sonoff Zigbee Bridge';
    if (m.contains('NSPanel'))  return 'Sonoff NSPanel';
    if (m.contains('SPM'))      return 'Sonoff SPM (Smart Power)';
    return 'Sonoff $model';
  }

  // ── Tuya ──────────────────────────────────────────────────────────────────────

  static Future<DiscoveredSwitch?> _tryTuya(
      String ip, List<int> openPorts) async {
    // Tuya LAN API: TCP port 6668 / 6669
    final hasTuya = openPorts.contains(6668) || openPorts.contains(6669);

    // Also check HTTP banner for Tuya keywords
    String? banner;
    if (openPorts.contains(80)) {
      banner = await _httpGet(ip, 80, '/');
    }
    final bannerLower = banner?.toLowerCase() ?? '';
    final tuyaInBanner = bannerLower.contains('tuya') ||
        bannerLower.contains('ty_iot') ||
        bannerLower.contains('smartlife') ||
        bannerLower.contains('bk7231') || // common Tuya MCU
        bannerLower.contains('wifiiot');

    if (!hasTuya && !tuyaInBanner) return null;

    // Try Tuya-specific HTTP endpoints
    String? model;
    String? deviceId;

    if (openPorts.contains(80)) {
      // Some Tuya devices expose a local HTTP API
      final infoResp = await _httpGet(ip, 80, '/');
      if (infoResp != null) {
        final body = _body(infoResp);
        // Try to find device ID
        final devIdMatch = RegExp(r'"devId"\s*:\s*"([^"]+)"').firstMatch(body);
        deviceId = devIdMatch?.group(1);
        final modelMatch = RegExp(r'"productKey"\s*:\s*"([^"]+)"').firstMatch(body);
        model = modelMatch?.group(1);
      }
    }

    return DiscoveredSwitch(
      id:        deviceId ?? 'tuya_${ip.replaceAll('.','_')}',
      ip:        ip,
      name:      _tuyaFriendlyName(model, openPorts),
      brand:     SwitchBrand.tuya,
      model:     model,
      openPorts: openPorts,
      deviceType: openPorts.contains(6668) || openPorts.contains(6669)
          ? DiscoveredDeviceType.smartSwitch
          : DiscoveredDeviceType.socket,
      apiBaseUrl: 'http://$ip',
      // Note: Tuya control requires the local key (32-char hex)
      // Get it from Tuya IoT Platform → Device Info → Local Key
    );
  }

  static String _tuyaFriendlyName(String? model, List<int> ports) {
    if (model != null && model.isNotEmpty) return 'Tuya $model';
    if (ports.contains(6668)) return 'Tuya Smart Switch';
    return 'Tuya Device';
  }

  // ── Network helpers ───────────────────────────────────────────────────────────

  static Future<List<int>> _scanPorts_(String ip) async {
    final futures = _scanPorts.map((port) async {
      try {
        final sock = await Socket.connect(ip, port, timeout: _timeout);
        await sock.close();
        return port;
      } on SocketException {
        return null;
      }
    });
    final results = await Future.wait(futures);
    return results.whereType<int>().toList();
  }

  static Future<String?> _httpGet(String ip, int port, String path) async {
    try {
      final sock = await Socket.connect(ip, port, timeout: _timeout);
      sock.write(
          'GET $path HTTP/1.0\r\n'
          'Host: $ip\r\n'
          'User-Agent: FantaTech-Scanner/1.0\r\n'
          '\r\n');
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          _httpTime, onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 4096) break;
      }
      await sock.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _httpPost(
      String ip, int port, String path, String body) async {
    try {
      final encoded = utf8.encode(body);
      final sock = await Socket.connect(ip, port, timeout: _timeout);
      sock.write(
          'POST $path HTTP/1.0\r\n'
          'Host: $ip\r\n'
          'Content-Type: application/json\r\n'
          'Content-Length: ${encoded.length}\r\n'
          '\r\n');
      sock.add(encoded);
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          _httpTime, onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 4096) break;
      }
      await sock.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static String _body(String raw) {
    final sep = raw.indexOf('\r\n\r\n');
    return sep >= 0 ? raw.substring(sep + 4) : raw;
  }
}

// ── Control API helpers ───────────────────────────────────────────────────────

/// Shelly control — toggle relay channel
class ShellyApi {
  final String ip;
  final bool isGen2;
  const ShellyApi(this.ip, {this.isGen2 = false});

  /// Turn relay on/off. [channel] = 0 for single-relay devices.
  Future<bool> setRelay(int channel, bool on) async {
    if (isGen2) {
      return _postRpc('Switch.Set',
          '{"id":0,"method":"Switch.Set","params":{"id":$channel,"on":$on}}');
    } else {
      return _get('/relay/$channel?turn=${on ? 'on' : 'off'}');
    }
  }

  /// Read relay state. Returns null on error.
  Future<bool?> getRelay(int channel) async {
    if (isGen2) {
      final resp = await _httpGet('/rpc',
          '{"id":1,"method":"Switch.GetStatus","params":{"id":$channel}}');
      if (resp == null) return null;
      try {
        final j = jsonDecode(resp) as Map;
        return j['result']?['output'] as bool?;
      } catch (_) { return null; }
    } else {
      final resp = await _httpGet('/relay/$channel', null);
      if (resp == null) return null;
      return resp.contains('"ison":true');
    }
  }

  Future<bool> _get(String path) async {
    try {
      final sock = await Socket.connect(ip, 80,
          timeout: const Duration(seconds: 5));
      sock.write('GET $path HTTP/1.0\r\nHost: $ip\r\n\r\n');
      await sock.flush();
      final bytes = <int>[];
      await for (final c in sock
          .timeout(const Duration(seconds: 4), onTimeout: (s) => s.close())) {
        bytes.addAll(c);
        if (bytes.length > 512) break;
      }
      await sock.close();
      final r = utf8.decode(bytes, allowMalformed: true);
      return r.contains('200') || r.contains('"ison"');
    } catch (_) { return false; }
  }

  Future<bool> _postRpc(String method, String body) async {
    try {
      final enc = utf8.encode(body);
      final sock = await Socket.connect(ip, 80,
          timeout: const Duration(seconds: 5));
      sock.write(
          'POST /rpc HTTP/1.0\r\nHost: $ip\r\n'
          'Content-Type: application/json\r\nContent-Length: ${enc.length}\r\n\r\n');
      sock.add(enc);
      await sock.flush();
      await sock.close();
      return true;
    } catch (_) { return false; }
  }

  Future<String?> _httpGet(String path, String? postBody) async {
    try {
      final enc = postBody != null ? utf8.encode(postBody) : null;
      final sock = await Socket.connect(ip, 80,
          timeout: const Duration(seconds: 5));
      if (enc != null) {
        sock.write('POST $path HTTP/1.0\r\nHost: $ip\r\n'
            'Content-Type: application/json\r\nContent-Length: ${enc.length}\r\n\r\n');
        sock.add(enc);
      } else {
        sock.write('GET $path HTTP/1.0\r\nHost: $ip\r\n\r\n');
      }
      await sock.flush();
      final bytes = <int>[];
      await for (final c in sock
          .timeout(const Duration(seconds: 4), onTimeout: (s) => s.close())) {
        bytes.addAll(c);
        if (bytes.length > 2048) break;
      }
      await sock.close();
      final raw = utf8.decode(bytes, allowMalformed: true);
      final sep = raw.indexOf('\r\n\r\n');
      return sep >= 0 ? raw.substring(sep + 4) : raw;
    } catch (_) { return null; }
  }
}

/// Sonoff LAN API — control via eWeLink local API (firmware 3.6+)
class SonoffApi {
  final String ip;
  final int port;
  final String deviceId;
  const SonoffApi(this.ip, this.deviceId, {this.port = 8081});

  Future<bool> setSwitch(bool on, {int outlet = 0}) async {
    final body = jsonEncode({
      'deviceid': deviceId,
      'data': {'switches': [{'switch': on ? 'on' : 'off', 'outlet': outlet}]},
    });
    return _post('/zeroconf/switches', body);
  }

  Future<bool> setSingleSwitch(bool on) async {
    final body = jsonEncode({
      'deviceid': deviceId,
      'data': {'switch': on ? 'on' : 'off'},
    });
    return _post('/zeroconf/switch', body);
  }

  Future<bool> _post(String path, String body) async {
    try {
      final enc = utf8.encode(body);
      final sock = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 5));
      sock.write(
          'POST $path HTTP/1.0\r\nHost: $ip:$port\r\n'
          'Content-Type: application/json\r\nContent-Length: ${enc.length}\r\n\r\n');
      sock.add(enc);
      await sock.flush();
      final bytes = <int>[];
      await for (final c in sock
          .timeout(const Duration(seconds: 4), onTimeout: (s) => s.close())) {
        bytes.addAll(c);
        if (bytes.length > 512) break;
      }
      await sock.close();
      final r = utf8.decode(bytes, allowMalformed: true);
      return r.contains('"error":0') || r.contains('200');
    } catch (_) { return false; }
  }
}
