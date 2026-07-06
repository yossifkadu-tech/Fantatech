// ─────────────────────────────────────────────────────────────────────────────
// WiFi Scanner
// Scans the local /24 subnet using parallel TCP socket probes.
// Emits ScannerEvents into the provided StreamController.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import 'discovery_models.dart';

/// Ports probed on every host. Chosen to cover smart home devices + cameras.
/// 80/443 = HTTP(S), 8080/8888 = alt HTTP,
/// 1883 = MQTT, 5683 = CoAP (Zigbee2MQTT), 6668 = Tuya LAN API,
/// 554/8554 = RTSP cameras, 8081/8082 = MJPEG cameras.
const _probePorts = [80, 443, 554, 8080, 8081, 8082, 8554, 8888, 1883, 5683, 6668];

/// Maximum parallel socket attempts at once (avoid overwhelming NAT/router).
const _concurrency = 40;

/// Timeout per connection attempt in milliseconds.
const _timeoutMs = 600;

class WiFiScanner {
  /// Scan the local /24 subnet.
  /// Yields [ScannerEvent]s: progress updates, found devices, done/error.
  Stream<ScannerEvent> scan() async* {
    final info = NetworkInfo();

    // Resolve our own LAN IP to derive the subnet prefix.
    String? localIp;
    try {
      localIp = await info.getWifiIP();
    } catch (_) {}

    if (localIp == null) {
      // Fallback: try dart:io
      try {
        final ifaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        for (final iface in ifaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) {
              localIp = addr.address;
              break;
            }
          }
          if (localIp != null) break;
        }
      } catch (_) {}
    }

    if (localIp == null) {
      yield ScannerErrorEvent('WiFiScanner', 'Cannot determine local IP');
      return;
    }

    // Extract subnet prefix, e.g. "192.168.1"
    final parts = localIp.split('.');
    if (parts.length != 4) {
      yield ScannerErrorEvent('WiFiScanner', 'Unexpected IP format: $localIp');
      return;
    }
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    const total = 254;
    int completed = 0;

    // Process in batches to respect concurrency limit.
    for (int batch = 0; batch < total; batch += _concurrency) {
      final end = (batch + _concurrency).clamp(0, total);
      final futures = <Future<DiscoveredDevice?>>[];

      for (int i = batch + 1; i <= end; i++) {
        final ip = '$prefix.$i';
        futures.add(_probeHost(ip));
      }

      final results = await Future.wait(futures);

      for (final device in results) {
        completed++;
        if (device != null) {
          yield DeviceFoundEvent(device);
        }
      }

      yield ScannerProgressEvent(
        completed / total,
        'WiFi scan: $completed / $total',
      );
    }

    yield ScannerDoneEvent('WiFiScanner');
  }

  /// Probe a single host. Returns a [DiscoveredDevice] if reachable, else null.
  Future<DiscoveredDevice?> _probeHost(String ip) async {
    final openPorts = <int>[];

    // Try all ports; collect the ones that respond.
    final portFutures = _probePorts.map((port) async {
      try {
        final sock = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: _timeoutMs),
        );
        await sock.close();
        return port;
      } on SocketException {
        return null;
      }
    });

    final portResults = await Future.wait(portFutures);
    for (final p in portResults) {
      if (p != null) openPorts.add(p);
    }

    if (openPorts.isEmpty) return null;

    // Try to grab an HTTP banner for fingerprinting.
    String? banner;
    String? shellyInfo;
    if (openPorts.contains(80) || openPorts.contains(8080)) {
      final httpPort = openPorts.contains(80) ? 80 : 8080;
      banner = await _httpBanner(ip, httpPort);
      // Probe Shelly Gen1 /shelly endpoint → {"type":"SHSW-1",...}
      shellyInfo = await _httpBanner(ip, httpPort, path: '/shelly');
      // Probe Shelly Gen2 /rpc/Shelly.GetDeviceInfo
      shellyInfo ??= await _httpBanner(ip, httpPort, path: '/rpc/Shelly.GetDeviceInfo');
    }

    // Derive display name from Shelly info, then banner, then IP
    String displayName = ip;
    if (shellyInfo != null && shellyInfo.contains('"type"')) {
      final m = RegExp(r'"type"\s*:\s*"([^"]+)"').firstMatch(shellyInfo);
      if (m != null) displayName = 'Shelly ${m.group(1)}';
    } else if (shellyInfo != null && shellyInfo.contains('"model"')) {
      final m = RegExp(r'"model"\s*:\s*"([^"]+)"').firstMatch(shellyInfo);
      if (m != null) displayName = 'Shelly ${m.group(1)}';
    } else if (banner != null) {
      displayName = _extractTitle(banner);
    }

    return DiscoveredDevice(
      id: 'wifi_$ip',
      displayName: displayName,
      ip: ip,
      type: DiscoveredDeviceType.unknown, // identifier refines this
      protocol: DiscoveryProtocol.wifi,
      openPorts: openPorts,
      metadata: {
        if (banner != null) 'httpBanner': banner,
        if (shellyInfo != null) 'shellyInfo': shellyInfo,
      },
    );
  }

  /// Grab the first 512 bytes of HTTP response from an IP:port.
  Future<String?> _httpBanner(String ip, int port, {String path = '/'}) async {
    try {
      final sock = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: _timeoutMs),
      );
      sock.write('GET $path HTTP/1.0\r\nHost: $ip\r\n\r\n');
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
        const Duration(milliseconds: 400),
        onTimeout: (sink) => sink.close(),
      )) {
        bytes.addAll(chunk);
        if (bytes.length >= 512) break;
      }
      await sock.close();
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Pull a meaningful name out of an HTTP banner.
  String _extractTitle(String banner) {
    // Server header: "Server: Sonoff-Device"
    final serverMatch =
        RegExp(r'Server:\s*(.+)', caseSensitive: false).firstMatch(banner);
    if (serverMatch != null) return serverMatch.group(1)!.trim();

    // <title>...</title>
    final titleMatch =
        RegExp(r'<title>([^<]+)</title>', caseSensitive: false)
            .firstMatch(banner);
    if (titleMatch != null) return titleMatch.group(1)!.trim();

    return banner.split('\n').first.trim();
  }
}
