// ─────────────────────────────────────────────────────────────────────────────
// ONVIF Service
//
// 1. WS-Discovery — UDP multicast 239.255.255.250:3702
//    Finds ONVIF cameras on the LAN and returns their endpoint URLs.
//
// 2. GetStreamUri — SOAP HTTP call to each discovered camera
//    Returns the RTSP stream URL.
//
// 3. Camera port scan fallback
//    Probes common camera ports (80, 554, 8080, 8081, 8554) on given IPs.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../models/device.dart';

class DiscoveredCamera {
  final String id;
  final String ip;
  final String name;
  final String? manufacturer;
  final String? model;
  final String? rtspUrl;
  final String? mjpegUrl;
  final String? snapshotUrl;
  final CameraStreamType streamType;
  final List<int> openPorts;

  const DiscoveredCamera({
    required this.id,
    required this.ip,
    required this.name,
    this.manufacturer,
    this.model,
    this.rtspUrl,
    this.mjpegUrl,
    this.snapshotUrl,
    this.streamType = CameraStreamType.unknown,
    this.openPorts = const [],
  });

  Camera toCamera({String room = 'outdoor', String? username, String? password}) =>
      Camera(
        id: 'cam_$id',
        name: name,
        room: room,
        isOnline: true,
        ip: ip,
        username: username,
        password: password,
        rtspUrl: rtspUrl,
        mjpegUrl: mjpegUrl,
        snapshotUrl: snapshotUrl,
        manufacturer: manufacturer,
        model: model,
        streamType: streamType,
        port: openPorts.contains(554) ? 554 : 8554,
      );
}

class OnvifService {
  // ── WS-Discovery ────────────────────────────────────────────────────────────

  static const _wsDiscoveryAddr = '239.255.255.250';
  static const _wsDiscoveryPort = 3702;

  static String _probeMessage() {
    final uuid = _uuid();
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope"
  xmlns:dn="http://www.onvif.org/ver10/network/wsdl"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery">
  <Header>
    <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>
    <wsa:MessageID>uuid:$uuid</wsa:MessageID>
    <wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>
  </Header>
  <Body>
    <wsd:Probe>
      <wsd:Types>dn:NetworkVideoTransmitter</wsd:Types>
    </wsd:Probe>
  </Body>
</Envelope>''';
  }

  static String _uuid() {
    final r = Random.secure();
    String hex(int n) => r.nextInt(n).toRadixString(16).padLeft(4, '0');
    return '${hex(65536)}${hex(65536)}-${hex(65536)}-${hex(65536)}-${hex(65536)}-${hex(65536)}${hex(65536)}${hex(65536)}';
  }

  /// Send WS-Discovery probe, collect responses for [timeout].
  static Future<List<DiscoveredCamera>> discoverOnvif({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final cameras = <DiscoveredCamera>[];
    final seen = <String>{};

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.multicastHops = 4;
      socket.broadcastEnabled = true;

      final probe = utf8.encode(_probeMessage());
      socket.send(
        probe,
        InternetAddress(_wsDiscoveryAddr),
        _wsDiscoveryPort,
      );

      final completer = Completer<void>();
      Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram == null) return;
          final body = utf8.decode(datagram.data, allowMalformed: true);
          final ip = datagram.address.address;
          if (seen.contains(ip)) return;
          seen.add(ip);

          final xAddrs = _extractXml(body, 'XAddrs') ??
              _extractXml(body, 'd:XAddrs') ??
              _extractXml(body, 'wsd:XAddrs');
          cameras.add(DiscoveredCamera(
            id: ip.replaceAll('.', '_'),
            ip: ip,
            name: 'ONVIF Camera ($ip)',
            rtspUrl: null, // enriched in next step
            streamType: CameraStreamType.rtsp,
            openPorts: const [554],
          ));
        }
      });

      await completer.future;
      socket.close();
    } catch (_) {
      // WS-Discovery not supported or network error — fall through to port scan
    }

    return cameras;
  }

  // ── Get Stream URI via ONVIF SOAP ───────────────────────────────────────────

  static String _getStreamUriSoap({String? username, String? password}) => '''<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope"
  xmlns:trt="http://www.onvif.org/ver10/media/wsdl"
  xmlns:tt="http://www.onvif.org/ver10/schema">
  <Header/>
  <Body>
    <trt:GetStreamUri>
      <trt:StreamSetup>
        <tt:Stream>RTP-Unicast</tt:Stream>
        <tt:Transport><tt:Protocol>RTSP</tt:Protocol></tt:Transport>
      </trt:StreamSetup>
      <trt:ProfileToken>MainStream</trt:ProfileToken>
    </trt:GetStreamUri>
  </Body>
</Envelope>''';

  static Future<String?> getStreamUri(
    String ip, {
    int port = 80,
    String? username,
    String? password,
  }) async {
    try {
      final body = _getStreamUriSoap(username: username, password: password);
      final sock = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 5));

      final headers = StringBuffer()
        ..write('POST /onvif/media HTTP/1.0\r\n')
        ..write('Host: $ip:$port\r\n')
        ..write('Content-Type: application/soap+xml\r\n')
        ..write('Content-Length: ${utf8.encode(body).length}\r\n');

      if (username != null && password != null) {
        final cred = base64Encode(utf8.encode('$username:$password'));
        headers.write('Authorization: Basic $cred\r\n');
      }
      headers.write('\r\n');

      sock.write(headers.toString());
      sock.write(body);
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          const Duration(seconds: 4), onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 8192) break;
      }
      await sock.close();

      final response = utf8.decode(bytes, allowMalformed: true);
      // Extract RTSP URI from SOAP response
      return _extractXml(response, 'Uri') ??
          _extractXml(response, 'tt:Uri') ??
          _extractXml(response, 'trt:Uri');
    } catch (_) {
      return null;
    }
  }

  // ── Camera Port Scan ────────────────────────────────────────────────────────

  /// Common camera HTTP paths to detect MJPEG or snapshot endpoints
  static const _cameraPaths = [
    '/mjpeg',
    '/video.mjpg',
    '/video.cgi',
    '/mjpeg.cgi',
    '/streaming/channels/1/preview',
    '/snapshot.jpg',
    '/snap.jpg',
    '/image/jpeg.cgi',
    '/cgi-bin/snapshot.cgi',
    '/axis-cgi/mjpg/video.cgi',
  ];

  static const _cameraPorts = [80, 8080, 8081, 8082, 554, 8554];

  /// Probe a single IP for camera presence. Returns null if not a camera.
  static Future<DiscoveredCamera?> probeCameraAt(
    String ip, {
    String? username,
    String? password,
    Duration timeout = const Duration(milliseconds: 1000),
  }) async {
    final openPorts = <int>[];

    // Check which camera ports are open
    final futures = _cameraPorts.map((port) async {
      try {
        final sock = await Socket.connect(ip, port, timeout: timeout);
        await sock.close();
        return port;
      } on SocketException {
        return null;
      }
    });
    for (final p in await Future.wait(futures)) {
      if (p != null) openPorts.add(p);
    }

    if (openPorts.isEmpty) return null;

    // Try to identify camera brand from HTTP banner
    String? banner;
    String? mjpegUrl;
    String? snapshotUrl;
    String? manufacturer;
    final httpPort = openPorts.firstWhere((p) => p == 80 || p == 8080,
        orElse: () => -1);

    if (httpPort > 0) {
      banner = await _httpGet(ip, httpPort, '/', username, password);

      // Detect manufacturer from banner
      if (banner != null) {
        final b = banner.toLowerCase();
        if (b.contains('hikvision') || b.contains('hikvisio')) {
          manufacturer = 'Hikvision';
        } else if (b.contains('dahua')) {
          manufacturer = 'Dahua';
        } else if (b.contains('reolink')) {
          manufacturer = 'Reolink';
        } else if (b.contains('axis')) {
          manufacturer = 'Axis';
        } else if (b.contains('tapo') || b.contains('tp-link')) {
          manufacturer = 'TP-Link Tapo';
        } else if (b.contains('amcrest')) {
          manufacturer = 'Amcrest';
        } else if (b.contains('foscam')) {
          manufacturer = 'Foscam';
        }
      }

      // Try known MJPEG paths
      for (final path in _cameraPaths) {
        if (path.contains('snapshot') || path.contains('snap') ||
            path.contains('jpeg')) {
          if (await _isReachable(ip, httpPort, path, username, password)) {
            snapshotUrl = _buildUrl(ip, httpPort, path, username, password);
            break;
          }
        } else {
          if (await _isReachable(ip, httpPort, path, username, password)) {
            mjpegUrl = _buildUrl(ip, httpPort, path, username, password);
            break;
          }
        }
      }
    }

    // Build RTSP URL
    String? rtspUrl;
    if (openPorts.contains(554) || openPorts.contains(8554)) {
      final rtspPort = openPorts.contains(554) ? 554 : 8554;
      final cred = (username != null && password != null)
          ? '$username:$password@'
          : '';
      // Try manufacturer-specific paths
      if (manufacturer == 'Hikvision') {
        rtspUrl = 'rtsp://${cred}$ip:$rtspPort/Streaming/Channels/101';
      } else if (manufacturer == 'Dahua') {
        rtspUrl = 'rtsp://${cred}$ip:$rtspPort/cam/realmonitor?channel=1&subtype=0';
      } else if (manufacturer == 'Reolink') {
        rtspUrl = 'rtsp://${cred}$ip:$rtspPort/h264Preview_01_main';
      } else if (manufacturer == 'Axis') {
        rtspUrl = 'rtsp://${cred}$ip:$rtspPort/axis-media/media.amp';
      } else {
        rtspUrl = 'rtsp://${cred}$ip:$rtspPort/';
      }
    }

    if (mjpegUrl == null && snapshotUrl == null && rtspUrl == null &&
        !openPorts.contains(554)) {
      return null; // Not convincingly a camera
    }

    final name = manufacturer != null
        ? '$manufacturer Camera'
        : 'IP Camera ($ip)';

    return DiscoveredCamera(
      id: ip.replaceAll('.', '_'),
      ip: ip,
      name: name,
      manufacturer: manufacturer,
      rtspUrl: rtspUrl,
      mjpegUrl: mjpegUrl,
      snapshotUrl: snapshotUrl,
      streamType: mjpegUrl != null
          ? CameraStreamType.mjpeg
          : (snapshotUrl != null
              ? CameraStreamType.snapshot
              : CameraStreamType.rtsp),
      openPorts: openPorts,
    );
  }

  // ── Subnet camera scan ──────────────────────────────────────────────────────

  static Stream<DiscoveredCamera> scanSubnet(
    String subnetPrefix, {
    String? username,
    String? password,
    int concurrency = 30,
  }) async* {
    // First: WS-Discovery multicast
    final onvifCams = await discoverOnvif();
    for (final cam in onvifCams) {
      yield cam;
    }

    // Second: port scan the subnet
    for (int batch = 1; batch <= 254; batch += concurrency) {
      final end = (batch + concurrency - 1).clamp(1, 254);
      final futures = <Future<DiscoveredCamera?>>[];

      for (int i = batch; i <= end; i++) {
        futures.add(
          probeCameraAt(
            '$subnetPrefix.$i',
            username: username,
            password: password,
          ),
        );
      }

      final results = await Future.wait(futures);
      for (final cam in results) {
        if (cam != null &&
            !onvifCams.any((o) => o.ip == cam.ip)) {
          yield cam;
        }
      }
    }
  }

  // ── HTTP helpers ────────────────────────────────────────────────────────────

  static Future<String?> _httpGet(
      String ip, int port, String path, String? user, String? pass) async {
    try {
      final sock = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 800));
      final req = StringBuffer()
        ..write('GET $path HTTP/1.0\r\n')
        ..write('Host: $ip:$port\r\n');
      if (user != null && pass != null) {
        final cred = base64Encode(utf8.encode('$user:$pass'));
        req.write('Authorization: Basic $cred\r\n');
      }
      req.write('\r\n');
      sock.write(req.toString());
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          const Duration(milliseconds: 600), onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 1024) break;
      }
      await sock.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _isReachable(
      String ip, int port, String path, String? user, String? pass) async {
    final r = await _httpGet(ip, port, path, user, pass);
    if (r == null) return false;
    // Check for 200 or MJPEG content type
    return r.contains('200') ||
        r.contains('multipart') ||
        r.contains('image/jpeg') ||
        r.contains('image/jpg');
  }

  static String _buildUrl(
      String ip, int port, String path, String? user, String? pass) {
    if (user != null && pass != null) {
      return 'http://$user:$pass@$ip:$port$path';
    }
    return 'http://$ip:$port$path';
  }

  // ── Extract XML tag value ───────────────────────────────────────────────────
  static String? _extractXml(String xml, String tag) {
    final match = RegExp('<$tag[^>]*>([^<]+)</$tag>').firstMatch(xml);
    return match?.group(1)?.trim();
  }
}
