// ─────────────────────────────────────────────────────────────────────────────
// LanScanner
//
// Two-pass parallel TCP scan of the local /24 subnet:
//   Pass 1 — probe primary ports (80, 8123, 1883) on all 254 hosts in batches
//             of 40 concurrent connections. Timeout 500ms per host.
//   Pass 2 — for every live host: probe secondary ports + fetch HTTP banner
//             from port 80 / 8080 / 8123, including the Shelly /shelly endpoint
//             for precise model identification.
//
// The scanner never blocks the UI — all probing runs in Dart's async I/O pool.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';
import 'discovery_models.dart';
import 'device_classifier.dart';

typedef LanProgressCallback = void Function(int done, int total, String ip);

class LanScanner {
  static const _primaryPorts   = [80, 8123, 1883];
  static const _secondaryPorts = [443, 8080, 6668, 502, 554, 1400, 4343, 9999, 8081];
  static const _connectTimeout = Duration(milliseconds: 500);
  static const _httpTimeout    = Duration(milliseconds: 800);
  static const _batchSize      = 40;

  final LanProgressCallback? onProgress;
  LanScanner({this.onProgress});

  Future<List<DiscoveredDevice>> scan() async {
    final subnet = await _getSubnet();
    if (subnet == null) return [];

    // ── Pass 1: find live hosts ───────────────────────────────────────────────
    final liveHosts = <String>[];
    var done = 0;
    const total = 254;

    for (int start = 1; start <= total; start += _batchSize) {
      final end = (start + _batchSize - 1).clamp(1, total);
      final futures = <Future<void>>[];

      for (int i = start; i <= end; i++) {
        final ip = '$subnet.$i';
        futures.add(
          _isAlive(ip).then((alive) {
            if (alive) liveHosts.add(ip);
            onProgress?.call(++done, total, ip);
          }),
        );
      }
      await Future.wait(futures);
    }

    // ── Pass 2: enrich each live host ─────────────────────────────────────────
    final results = await Future.wait(
      liveHosts.map(_enrichHost),
      eagerError: false,
    );
    return results.whereType<DiscoveredDevice>().toList();
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<bool> _isAlive(String ip) async {
    for (final port in _primaryPorts) {
      try {
        final sock = await Socket.connect(ip, port, timeout: _connectTimeout);
        await sock.close();
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<DiscoveredDevice?> _enrichHost(String ip) async {
    // Probe all ports
    final openPorts = <int>[];
    final allPorts  = [..._primaryPorts, ..._secondaryPorts];

    await Future.wait(allPorts.map((port) async {
      try {
        final sock = await Socket.connect(ip, port, timeout: _connectTimeout);
        await sock.close();
        openPorts.add(port);
      } catch (_) {}
    }));

    if (openPorts.isEmpty) return null;

    // HTTP enrichment
    String? banner;
    String? shellyModel;
    String? manufacturer;
    String? displayName;

    final httpPort = openPorts.contains(80) ? 80
        : openPorts.contains(8080) ? 8080
        : null;

    if (httpPort != null) {
      // Generic HTTP banner (HTML title)
      banner = await _httpGet(ip, httpPort, '/');

      // Shelly fingerprint: GET /shelly → {"type":"SHSW-1","model":"SHSW-1PM",...}
      final shellyResp = await _httpGet(ip, httpPort, '/shelly');
      if (shellyResp != null && shellyResp.contains('"type"')) {
        try {
          final json = jsonDecode(_bodyOnly(shellyResp)) as Map<String, dynamic>;
          shellyModel  = (json['type'] ?? json['model']) as String?;
          manufacturer = 'Shelly';
          displayName  = shellyModel;
        } catch (_) {}
      }

      // ESPHome fingerprint: page contains "ESPHome"
      if (banner != null && banner.toLowerCase().contains('esphome')) {
        manufacturer ??= 'ESPHome';
        displayName  ??= _titleFromBanner(banner);
      }
    }

    // Home Assistant fingerprint: GET /api/ → {"message":"API running."}
    if (openPorts.contains(8123)) {
      final haResp = await _httpGet(ip, 8123, '/api/');
      if (haResp != null && haResp.contains('API running')) {
        manufacturer = 'Home Assistant';
        displayName  = 'Home Assistant';
      }
    }

    displayName ??= _titleFromBanner(banner) ?? 'מכשיר $ip';

    final type = DeviceClassifier.classifyFromWifi(
      name:         displayName,
      openPorts:    openPorts,
      banner:       banner,
      manufacturer: manufacturer,
      shellyModel:  shellyModel,
    );

    return DiscoveredDevice(
      id:           'wifi_$ip',
      displayName:  displayName,
      ip:           ip,
      type:         type,
      protocol:     DiscoveryProtocol.wifi,
      manufacturer: manufacturer,
      model:        shellyModel,
      openPorts:    List.unmodifiable(openPorts),
      metadata: {
        if (banner != null)
          'httpBanner': banner.substring(0, banner.length.clamp(0, 300)),
      },
    );
  }

  Future<String?> _httpGet(String ip, int port, String path) async {
    try {
      final sock = await Socket.connect(ip, port, timeout: _connectTimeout);
      sock.write('GET $path HTTP/1.0\r\nHost: $ip\r\nUser-Agent: FantaTech/1.0\r\n\r\n');
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
        _httpTimeout,
        onTimeout: (sink) => sink.close(),
      )) {
        bytes.addAll(chunk);
        if (bytes.length > 4096) break;
      }
      await sock.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  /// Extract body from raw HTTP response (skip headers).
  String _bodyOnly(String raw) {
    final sep = raw.indexOf('\r\n\r\n');
    return sep >= 0 ? raw.substring(sep + 4) : raw;
  }

  /// Extract <title> from HTML banner.
  String? _titleFromBanner(String? banner) {
    if (banner == null) return null;
    return RegExp(r'<title>([^<]+)</title>', caseSensitive: false)
        .firstMatch(banner)
        ?.group(1)
        ?.trim();
  }

  // ── Subnet detection ─────────────────────────────────────────────────────────

  Future<String?> _getSubnet() async {
    // Primary: network_info_plus
    try {
      final ip = await NetworkInfo().getWifiIP();
      if (ip != null && _isLanIp(ip)) return _toSubnet(ip);
    } catch (_) {}

    // Fallback: enumerate network interfaces
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (_isLanIp(addr.address)) return _toSubnet(addr.address);
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isLanIp(String ip) {
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('10.'))      return true;
    final parts = ip.split('.');
    if (parts.length == 4 && parts[0] == '172') {
      final b = int.tryParse(parts[1]) ?? 0;
      if (b >= 16 && b <= 31) return true;
    }
    return false;
  }

  String _toSubnet(String ip) {
    final p = ip.split('.');
    return '${p[0]}.${p[1]}.${p[2]}';
  }
}
