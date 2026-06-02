// ─────────────────────────────────────────────────────────────────────────────
// Gateway Discovery
// Deep-probes hosts found by the WiFi scanner to identify Zigbee/WiFi/Z-Wave
// gateways and smart home hubs specifically. Uses HTTP fingerprinting,
// port signatures, and URL pattern matching.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'discovery_models.dart';

// ── Gateway Fingerprint Database ─────────────────────────────────────────────
class _GwFingerprint {
  final String manufacturer;
  final String model;
  final DiscoveredDeviceType type;

  // At least one of these must match for positive ID.
  final List<String> urlProbes;       // paths that return 200
  final List<String> bodyPatterns;    // regex patterns in HTTP body
  final List<String> headerPatterns;  // regex patterns in headers
  final List<int> requiredPorts;      // ports that MUST be open

  const _GwFingerprint({
    required this.manufacturer,
    required this.model,
    required this.type,
    this.urlProbes = const [],
    this.bodyPatterns = const [],
    this.headerPatterns = const [],
    this.requiredPorts = const [],
  });
}

const _fingerprints = [
  // ── Shelly motion sensors (Gen2/3 RPC) ──────────────────────────────────
  // Shelly Plus Motion: app="PlusMot"; Shelly Gen3 Motion: app="S3MotionPMD"
  _GwFingerprint(
    manufacturer: 'Shelly',
    model: 'Plus Motion',
    type: DiscoveredDeviceType.motionSensor,
    urlProbes: ['/rpc/Shelly.GetDeviceInfo'],
    bodyPatterns: [r'"PlusMot"', r'"S3Motion', r'"motion"'],
    requiredPorts: [80],
  ),
  // Shelly Motion Gen1: type="SHMOS-01"
  _GwFingerprint(
    manufacturer: 'Shelly',
    model: 'Motion',
    type: DiscoveredDeviceType.motionSensor,
    urlProbes: ['/shelly'],
    bodyPatterns: [r'SHMOS'],
    requiredPorts: [80],
  ),
  // ── Shelly door/window sensors ───────────────────────────────────────────
  // Gen2: app="SensorDW" or "PlusDW"
  _GwFingerprint(
    manufacturer: 'Shelly',
    model: 'Plus DW',
    type: DiscoveredDeviceType.windowSensor,
    urlProbes: ['/rpc/Shelly.GetDeviceInfo'],
    bodyPatterns: [r'"SensorDW"', r'"PlusDW"', r'"sensordw"', r'"plusdw"'],
    requiredPorts: [80],
  ),
  // Gen1: type starts with "SHDW"
  _GwFingerprint(
    manufacturer: 'Shelly',
    model: 'Door/Window',
    type: DiscoveredDeviceType.windowSensor,
    urlProbes: ['/shelly'],
    bodyPatterns: [r'SHDW'],
    requiredPorts: [80],
  ),
  // ── Shelly smoke sensor ──────────────────────────────────────────────────
  _GwFingerprint(
    manufacturer: 'Shelly',
    model: 'Smoke',
    type: DiscoveredDeviceType.smokeSensor,
    urlProbes: ['/shelly', '/rpc/Shelly.GetDeviceInfo'],
    bodyPatterns: [r'SHSMOKE', r'"PlusSmoke"', r'"smoke"'],
    requiredPorts: [80],
  ),
  // ── Zigbee gateways ──────────────────────────────────────────────────────
  _GwFingerprint(
    manufacturer: 'Sonoff',
    model: 'Zigbee Bridge Pro',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/zb', '/zbbridge'],
    bodyPatterns: [r'SONOFF', r'Zigbee'],
    headerPatterns: [r'Sonoff'],
    requiredPorts: [80],
  ),
  _GwFingerprint(
    manufacturer: 'Zigbee2MQTT',
    model: 'Z2M Frontend',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/api', '/frontend/config'],
    bodyPatterns: [r'zigbee2mqtt', r'\"version\"'],
    requiredPorts: [80, 8080],
  ),
  _GwFingerprint(
    manufacturer: 'HUSBZB-1',
    model: 'USB Zigbee+Z-Wave',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/info'],
    bodyPatterns: [r'HUSBZB', r'nortek'],
    requiredPorts: [8080],
  ),
  _GwFingerprint(
    manufacturer: 'deCONZ / Phoscon',
    model: 'ConBee II',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/api/challenge', '/api/config'],
    bodyPatterns: [r'deconz', r'phoscon', r'Dresden Elektronik'],
    requiredPorts: [80, 443],
  ),
  _GwFingerprint(
    manufacturer: 'Home Assistant',
    model: 'HA Core',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/api/', '/auth/providers'],
    bodyPatterns: [r'Home Assistant', r'"homeassistant"'],
    requiredPorts: [8123],
  ),

  // ── WiFi smart hubs ──────────────────────────────────────────────────────
  _GwFingerprint(
    manufacturer: 'TP-Link',
    model: 'Tapo H200',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/stok=/ds'],
    bodyPatterns: [r'TP-LINK', r'Tapo'],
    headerPatterns: [r'TP-LINK'],
    requiredPorts: [80, 443],
  ),
  _GwFingerprint(
    manufacturer: 'Philips Hue',
    model: 'Hue Bridge',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/api/0/config', '/description.xml'],
    bodyPatterns: [r'Philips hue', r'IpBridge'],
    requiredPorts: [80, 443],
  ),
  _GwFingerprint(
    manufacturer: 'Tuya',
    model: 'Tuya Smart Hub',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/gw.json'],
    bodyPatterns: [r'tuya', r'\"gwId\"'],
    requiredPorts: [6668, 6669],
  ),
  _GwFingerprint(
    manufacturer: 'SmartThings',
    model: 'Samsung SmartThings Hub',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/hub/health'],
    bodyPatterns: [r'smartthings', r'\"hubId\"'],
    requiredPorts: [39500, 8090],
  ),
  _GwFingerprint(
    manufacturer: 'openHAB',
    model: 'openHAB Core',
    type: DiscoveredDeviceType.gateway,
    urlProbes: ['/rest/'],
    bodyPatterns: [r'openHAB', r'"version"'],
    requiredPorts: [8080, 8443],
  ),
];

// ── Scanner ───────────────────────────────────────────────────────────────────
class GatewayDiscovery {
  /// Takes a list of pre-scanned [DiscoveredDevice]s from the WiFi scanner
  /// and deep-probes them to identify which are gateways.
  /// Also accepts raw IP addresses for targeted probing.
  Stream<ScannerEvent> identify(List<DiscoveredDevice> candidates) async* {
    int i = 0;
    for (final device in candidates) {
      i++;
      if (device.ip == null) continue;

      yield ScannerProgressEvent(
        i / candidates.length,
        'Gateway probe: ${device.ip}',
      );

      final refined = await _probeGateway(device);
      if (refined != null) {
        yield DeviceFoundEvent(refined);
      }
    }
    yield ScannerDoneEvent('GatewayDiscovery');
  }

  /// Deep-probe a single IP without prior WiFi scan context.
  Future<DiscoveredDevice?> probeIp(String ip) => _probeGateway(
        DiscoveredDevice(
          id: 'wifi_$ip',
          displayName: ip,
          ip: ip,
          type: DiscoveredDeviceType.unknown,
          protocol: DiscoveryProtocol.wifi,
        ),
      );

  Future<DiscoveredDevice?> _probeGateway(DiscoveredDevice device) async {
    final ip = device.ip!;

    for (final fp in _fingerprints) {
      // Check required ports first (fast reject)
      if (fp.requiredPorts.isNotEmpty) {
        bool portsOk = true;
        for (final port in fp.requiredPorts) {
          if (!device.openPorts.contains(port)) {
            // Try a quick check if we don't have scan results yet
            final ok = await _tcpCheck(ip, port);
            if (!ok) {
              portsOk = false;
              break;
            }
          }
        }
        if (!portsOk) continue;
      }

      // Probe URLs
      for (final path in fp.urlProbes) {
        final port = fp.requiredPorts.isNotEmpty ? fp.requiredPorts.first : 80;
        final response = await _httpGet(ip, port, path);
        if (response == null) continue;

        // Check body patterns
        bool matched = fp.bodyPatterns.isEmpty;
        for (final pattern in fp.bodyPatterns) {
          if (RegExp(pattern, caseSensitive: false).hasMatch(response.body)) {
            matched = true;
            break;
          }
        }

        // Check header patterns
        if (!matched) {
          for (final pattern in fp.headerPatterns) {
            if (RegExp(pattern, caseSensitive: false)
                .hasMatch(response.headers)) {
              matched = true;
              break;
            }
          }
        }

        if (matched) {
          return device.copyWith(
            displayName: '${fp.manufacturer} — ${fp.model}',
            type: fp.type,
            manufacturer: fp.manufacturer,
            model: fp.model,
            metadata: {
              ...device.metadata,
              'fingerprint': '${fp.manufacturer}/${fp.model}',
              'matchedUrl': path,
            },
          );
        }
      }
    }

    // No fingerprint matched — return null (not a known gateway)
    return null;
  }

  Future<bool> _tcpCheck(String ip, int port,
      {int timeoutMs = 500}) async {
    try {
      final sock = await Socket.connect(ip, port,
          timeout: Duration(milliseconds: timeoutMs));
      await sock.close();
      return true;
    } on SocketException {
      return false;
    }
  }

  Future<_HttpResponse?> _httpGet(
      String ip, int port, String path) async {
    try {
      final sock = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 600));
      sock.write(
          'GET $path HTTP/1.0\r\nHost: $ip\r\nAccept: application/json, text/html\r\n\r\n');
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
        const Duration(milliseconds: 800),
        onTimeout: (sink) => sink.close(),
      )) {
        bytes.addAll(chunk);
        if (bytes.length >= 2048) break;
      }
      await sock.close();

      if (bytes.isEmpty) return null;

      // Split at double CRLF to separate headers from body
      final raw = utf8.decode(bytes, allowMalformed: true);
      final sep = raw.indexOf('\r\n\r\n');
      return _HttpResponse(
        headers: sep > 0 ? raw.substring(0, sep) : raw,
        body: sep > 0 ? raw.substring(sep + 4) : '',
        statusCode: _parseStatus(raw),
      );
    } catch (_) {
      return null;
    }
  }

  int _parseStatus(String raw) {
    final m = RegExp(r'HTTP/\S+\s+(\d+)').firstMatch(raw);
    return m != null ? (int.tryParse(m.group(1)!) ?? 0) : 0;
  }
}

class _HttpResponse {
  final String headers;
  final String body;
  final int statusCode;
  const _HttpResponse(
      {required this.headers, required this.body, required this.statusCode});
}
