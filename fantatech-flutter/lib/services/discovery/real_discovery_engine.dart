// ─────────────────────────────────────────────────────────────────────────────
// RealDiscoveryEngine
//
// Scan pipeline (total ≈ 10 seconds):
//
//   ┌────────────────────────────────────────────────────────────────────┐
//   │  WiFi / LAN scan         ≈ 8s  (parallel batches of 40 hosts)     │
//   │  mDNS (8 service types)  ≈ 4s  ─┐                                 │
//   │  SSDP (UPnP M-SEARCH)    ≈ 5s  ─┤ all three run simultaneously   │
//   └────────────────────────────────┘                                   │
//
// Home Assistant (if found on port 8123):
//   • Detected automatically (GET /api/ — no token needed)
//   • haDetected / haIp exposed to UI
//   • connectHA(ip, token) fetches /api/states → all Zigbee/Z-Wave devices
//
// ChangeNotifier → drop-in with Provider, triggers UI rebuild on every find.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'discovery_models.dart';
import 'device_classifier.dart';
import 'lan_scanner.dart';
import 'ha_client.dart';

class RealDiscoveryEngine extends ChangeNotifier {
  // ── Public state ──────────────────────────────────────────────────────────
  bool   isScanning  = false;
  double progress    = 0;
  String status      = '';
  List<DiscoveredDevice> found = [];

  /// IP address where Home Assistant was detected (port 8123 open + /api/ OK).
  String? haIp;

  /// True once the user has successfully connected with a token.
  bool haConnected = false;

  int get haDeviceCount => found.where((d) => d.metadata['haIp'] != null).length;

  List<String> log = [];

  // ── Private ───────────────────────────────────────────────────────────────
  bool _cancelled = false;
  Timer? _debounceTimer;

  // ── Entry points ──────────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (isScanning) return;
    found.clear();
    log.clear();
    haIp       = null;
    haConnected = false;
    _cancelled  = false;
    _tick(0, 'מתחיל סריקה…');

    // Check for saved HA credentials from previous session
    final savedIp    = await HaClient.savedIp();
    final savedToken = await HaClient.savedToken();
    if (savedIp != null && savedToken != null) {
      haIp = savedIp;
    }

    try {
      // All three scanners run in parallel.
      // LAN scan is also parallel internally but we start it here.
      await Future.wait([
        _runLan(),
        _runMdns(),
        _runSsdp(),
      ]);
    } catch (e) {
      _addLog('[Engine] error: $e');
    }

    _debounceTimer?.cancel();
    if (!_cancelled) {
      final msg = found.isEmpty
          ? 'לא נמצאו מכשירים זמינים ברשת'
          : '${found.length} מכשירים נמצאו';
      _tick(1.0, msg);
    }
    isScanning = false;
    notifyListeners();
  }

  void stopScan() {
    _cancelled = true;
    isScanning  = false;
    status      = 'הסריקה הופסקה';
    notifyListeners();
  }

  /// Connect to Home Assistant and import all its entities.
  /// Returns an error string on failure, null on success.
  Future<String?> connectHA(String ip, String token) async {
    _addLog('[HA] מתחבר ל-$ip…');
    notifyListeners();

    final result = await HaClient.fetchDevices(ip, token);
    if (!result.isSuccess) {
      _addLog('[HA] שגיאה: ${result.errorMessage}');
      notifyListeners();
      return result.errorMessage;
    }

    for (final d in result.devices) {
      _mergeDevice(d);
    }

    haIp        = ip;
    haConnected = true;
    _addLog('[HA] יובאו ${result.devices.length} מכשירים');
    notifyListeners();
    return null;
  }

  void markRegistered(String id) {
    final idx = found.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      found[idx] = found[idx].copyWith(isRegistered: true);
      notifyListeners();
    }
  }

  void clear() {
    found.clear();
    log.clear();
    haIp        = null;
    haConnected = false;
    progress    = 0;
    status      = '';
    notifyListeners();
  }

  // ── LAN scanner ───────────────────────────────────────────────────────────

  Future<void> _runLan() async {
    _addLog('[WiFi] start');
    try {
      final scanner = LanScanner(
        onProgress: (done, total, ip) {
          if (_cancelled) return;
          _tick(0.05 + 0.55 * done / total, 'WiFi: $done / $total');
        },
      );
      final devices = await scanner.scan();
      for (final d in devices) {
        if (_cancelled) break;
        // If this host is HA, flag it
        if (d.type == DiscoveredDeviceType.gateway &&
            d.manufacturer == 'Home Assistant') {
          haIp ??= d.ip;
        }
        _mergeDevice(d);
      }
      _addLog('[WiFi] סיים — ${devices.length} מכשירים');
    } catch (e) {
      _addLog('[WiFi] error: $e');
    }
  }

  // ── mDNS scanner ──────────────────────────────────────────────────────────

  static const _mdnsServices = [
    '_shelly._tcp',
    '_esphomelib._tcp',
    '_home-assistant._tcp',
    '_hue._tcp',
    '_dirigera._tcp',
    '_hap._tcp',
    '_mqtt._tcp',
    '_matter._tcp',
  ];

  Future<void> _runMdns() async {
    _addLog('[mDNS] start');
    final client = MDnsClient();
    try {
      await client.start();
      for (final svc in _mdnsServices) {
        if (_cancelled) break;
        await _queryMdns(client, '$svc.local');
      }
      _addLog('[mDNS] סיים');
    } catch (e) {
      _addLog('[mDNS] error: $e');
    } finally {
      client.stop();
    }
  }

  Future<void> _queryMdns(MDnsClient client, String serviceType) async {
    try {
      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceType))
          .timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {

        if (_cancelled) return;

        // Resolve IP: PTR → SRV → A record
        String ip = '';
        try {
          await for (final SrvResourceRecord srv in client
              .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))
              .timeout(const Duration(seconds: 1), onTimeout: (sink) => sink.close())) {
            await for (final IPAddressResourceRecord a in client
                .lookup<IPAddressResourceRecord>(
                    ResourceRecordQuery.addressIPv4(srv.target))
                .timeout(const Duration(seconds: 1), onTimeout: (sink) => sink.close())) {
              ip = a.address.address;
              break;
            }
            break;
          }
        } catch (_) {}

        final shortSvc = serviceType.replaceAll('.local', '').replaceAll('_', '');
        final type     = DeviceClassifier.classifyFromMdns(serviceType);
        final name     = ptr.domainName.split('.').first;

        _mergeDevice(DiscoveredDevice(
          id:           'mdns_${ptr.domainName}',
          displayName:  name.isEmpty ? 'mDNS מכשיר' : name,
          ip:           ip.isEmpty ? null : ip,
          type:         type,
          protocol:     serviceType.contains('matter')
              ? DiscoveryProtocol.matter
              : DiscoveryProtocol.wifi,
          metadata: {
            'serviceType': shortSvc,
            if (ip.isNotEmpty) 'mdnsIp': ip,
          },
        ));

        // HA detected via mDNS?
        if (serviceType.contains('home-assistant') && ip.isNotEmpty) {
          haIp ??= ip;
        }
      }
    } catch (_) {}
  }

  // ── SSDP scanner ──────────────────────────────────────────────────────────

  static const _ssdpAddr = '239.255.255.250';
  static const _ssdpPort = 1900;
  static const _msearch  =
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 3\r\n'
      'ST: ssdp:all\r\n'
      '\r\n';

  Future<void> _runSsdp() async {
    _addLog('[SSDP] start');
    RawDatagramSocket? sock;
    try {
      sock = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, 0, reuseAddress: true);
      sock.joinMulticast(InternetAddress(_ssdpAddr));
      sock.send(utf8.encode(_msearch), InternetAddress(_ssdpAddr), _ssdpPort);

      final seen = <String>{};
      final done = Completer<void>();
      Timer(const Duration(seconds: 5), () {
        if (!done.isCompleted) done.complete();
      });

      sock.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = sock?.receive();
        if (dg == null) return;

        final ip = dg.address.address;
        if (!seen.add(ip)) return;

        final raw     = utf8.decode(dg.data, allowMalformed: true);
        final headers = _parseHeaders(raw);
        final server  = headers['server'] ?? '';
        final loc     = headers['location'] ?? '';

        _mergeDevice(DiscoveredDevice(
          id:          'ssdp_$ip',
          displayName: _serverName(server, ip),
          ip:          ip,
          type:        DeviceClassifier.classifyFromWifi(
              name: server, openPorts: [], banner: server),
          protocol:    DiscoveryProtocol.wifi,
          metadata: {
            if (loc.isNotEmpty) 'location': loc,
            if (server.isNotEmpty) 'server': server,
          },
        ));
      });

      await done.future;
      _addLog('[SSDP] סיים');
    } catch (e) {
      _addLog('[SSDP] error: $e');
    } finally {
      sock?.close();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Merge incoming device — deduplicate by IP or by id.
  void _mergeDevice(DiscoveredDevice incoming) {
    if (_cancelled) return;

    final idx = found.indexWhere((e) =>
        (incoming.ip != null && e.ip == incoming.ip) ||
        e.id == incoming.id);

    if (idx >= 0) {
      final existing = found[idx];
      // Prefer non-generic names and richer metadata
      found[idx] = existing.copyWith(
        displayName:  _betterName(incoming.displayName, existing.displayName),
        manufacturer: incoming.manufacturer ?? existing.manufacturer,
        model:        incoming.model ?? existing.model,
        openPorts:    {...existing.openPorts, ...incoming.openPorts}.toList(),
        metadata:     {...existing.metadata, ...incoming.metadata},
        type:         incoming.type != DiscoveredDeviceType.unknown
            ? incoming.type
            : existing.type,
      );
    } else {
      found.add(incoming);
    }
    // Debounce: batch rapid device discoveries into one UI update every 300ms
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), notifyListeners);
  }

  String _betterName(String a, String b) {
    const generic = {'WiFi Device', 'BLE Device', 'UPnP Device', 'mDNS מכשיר', 'מכשיר'};
    if (generic.any((g) => a.startsWith(g))) return b;
    if (generic.any((g) => b.startsWith(g))) return a;
    return a;
  }

  Map<String, String> _parseHeaders(String raw) {
    final map = <String, String>{};
    for (final line in raw.split('\r\n')) {
      final i = line.indexOf(':');
      if (i < 1) continue;
      map[line.substring(0, i).toLowerCase().trim()] =
          line.substring(i + 1).trim();
    }
    return map;
  }

  String _serverName(String server, String fallback) {
    if (server.isEmpty) return 'UPnP מכשיר';
    return server.split(' ').last.split('/').first.trim();
  }

  void _tick(double p, String msg) {
    progress   = p;
    status     = msg;
    isScanning = true;
    notifyListeners();
    debugPrint('[Discovery] $msg');
  }

  void _addLog(String msg) {
    log.add(msg);
    debugPrint(msg);
  }
}
