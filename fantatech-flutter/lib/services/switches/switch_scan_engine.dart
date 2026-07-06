// ─────────────────────────────────────────────────────────────────────────────
// SwitchScanEngine  —  ChangeNotifier, scans ALL smart-home protocols
//
// Parallel pipeline:
//   ┌─ WiFi LAN scan (/24) ──────── Shelly Gen1/2/3, Sonoff, ESPHome, Kasa, Tapo, Tuya
//   ├─ mDNS multicast ────────────  _shelly._tcp / _esphomelib._tcp / _ewelink._tcp / _kasa._tcp
//   ├─ Home Assistant REST ────────  /api/states  (switch.* + light.*)
//   └─ Zigbee2MQTT via MQTT ───────  zigbee2mqtt/bridge/devices
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'smart_switch_models.dart';
import 'switch_controller.dart';

class SwitchScanEngine extends ChangeNotifier {
  // ── Public state ──────────────────────────────────────────────────────────
  final List<SmartSwitchDevice> devices = [];
  final Map<SwitchProtocol, ProtocolScanState> protocolStates = {};
  bool isScanning = false;
  double overallProgress = 0; // 0..1

  // ── Private ───────────────────────────────────────────────────────────────
  bool _cancelled = false;
  Timer? _debounce;
  static const _batchSize    = 30;
  static const _httpTimeout  = Duration(milliseconds: 1000);
  static const _tcpTimeout   = Duration(milliseconds: 600);

  SwitchScanEngine() {
    for (final p in SwitchProtocol.values) {
      if (p != SwitchProtocol.unknown) {
        protocolStates[p] = ProtocolScanState(protocol: p);
      }
    }
  }

  // ── Entry point ───────────────────────────────────────────────────────────

  Future<void> startScan({
    String? haIp,
    String? haToken,
    String? mqttHost,
    int     mqttPort = 1883,
    String? mqttUser,
    String? mqttPass,
  }) async {
    if (isScanning) return;

    devices.clear();
    _cancelled = false;
    isScanning = true;
    overallProgress = 0;
    for (final s in protocolStates.values) {
      s.status   = ProtocolScanStatus.idle;
      s.found    = 0;
      s.progress = 0;
      s.message  = '';
    }
    notifyListeners();

    // Detect local subnet
    String? localIp;
    try { localIp = await NetworkInfo().getWifiIP(); } catch (_) {}
    if (localIp == null) {
      try {
        final ifaces = await NetworkInterface.list(
            type: InternetAddressType.IPv4, includeLinkLocal: false);
        for (final iface in ifaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) { localIp = addr.address; break; }
          }
          if (localIp != null) break;
        }
      } catch (_) {}
    }

    final prefix = localIp?.split('.').take(3).join('.');

    // Launch all scanners in parallel
    final futures = <Future<void>>[];

    if (prefix != null) {
      futures.add(_runWifiScan(prefix));
      futures.add(_runMdns());
    }

    if (haIp != null && haToken != null && haToken.isNotEmpty) {
      futures.add(_runHaScan(haIp, haToken));
    }

    if (mqttHost != null && mqttHost.isNotEmpty) {
      futures.add(_runZ2mScan(
          mqttHost, mqttPort, mqttUser, mqttPass));
    }

    await Future.wait(futures);

    isScanning = false;
    overallProgress = 1.0;
    notifyListeners();
  }

  void stopScan() {
    _cancelled = true;
    isScanning  = false;
    notifyListeners();
  }

  // ── WiFi / LAN scan ────────────────────────────────────────────────────────

  Future<void> _runWifiScan(String prefix) async {
    _setProtocol(SwitchProtocol.shellyGen1, ProtocolScanStatus.scanning,
        message: 'WiFi scan…');
    _setProtocol(SwitchProtocol.sonoffLan,  ProtocolScanStatus.scanning);
    _setProtocol(SwitchProtocol.esphome,    ProtocolScanStatus.scanning);
    _setProtocol(SwitchProtocol.kasaLocal,  ProtocolScanStatus.scanning);
    _setProtocol(SwitchProtocol.tapoLocal,  ProtocolScanStatus.scanning);
    _setProtocol(SwitchProtocol.tuyaLocal,  ProtocolScanStatus.scanning);

    int done = 0;
    const total = 254;

    for (int batch = 1; batch <= total; batch += _batchSize) {
      if (_cancelled) break;
      final end = (batch + _batchSize - 1).clamp(1, total);
      final futs = <Future<SmartSwitchDevice?>>[];

      for (int i = batch; i <= end; i++) {
        futs.add(_probeHost('$prefix.$i'));
      }

      final results = await Future.wait(futs);
      done += (end - batch + 1);

      overallProgress = 0.05 + 0.65 * done / total;
      for (final p in [
        SwitchProtocol.shellyGen1, SwitchProtocol.sonoffLan,
        SwitchProtocol.esphome,    SwitchProtocol.kasaLocal,
        SwitchProtocol.tapoLocal,  SwitchProtocol.tuyaLocal,
      ]) {
        protocolStates[p]?.progress = done / total;
      }

      for (final dev in results) {
        if (dev != null) _addDevice(dev);
      }
      notifyListeners();
    }

    for (final p in [
      SwitchProtocol.shellyGen1, SwitchProtocol.shellyGen2,
      SwitchProtocol.shellyGen3, SwitchProtocol.sonoffLan,
      SwitchProtocol.esphome,    SwitchProtocol.kasaLocal,
      SwitchProtocol.tapoLocal,  SwitchProtocol.tuyaLocal,
    ]) {
      _setProtocol(p, ProtocolScanStatus.done);
    }
  }

  // ── Single host probe ──────────────────────────────────────────────────────

  Future<SmartSwitchDevice?> _probeHost(String ip) async {
    // Quick port check — skip if no relevant ports are open
    final results = await Future.wait([
      SwitchController.probeTcp(ip, 80,   timeout: _tcpTimeout),
      SwitchController.probeTcp(ip, 8081, timeout: _tcpTimeout),
      SwitchController.probeTcp(ip, 6668, timeout: _tcpTimeout),
      SwitchController.probeTcp(ip, 9999, timeout: _tcpTimeout),
    ]);
    final port80   = results[0];
    final port8081 = results[1];
    final port6668 = results[2];
    final port9999 = results[3];

    if (!port80 && !port8081 && !port6668 && !port9999) return null;

    // ── Shelly Gen2/3 ──────────────────────────────────────────────────────
    if (port80) {
      final shelly2 = await _probeShellyGen2(ip);
      if (shelly2 != null) return shelly2;

      // ── Shelly Gen1 ────────────────────────────────────────────────────
      final shelly1 = await _probeShellyGen1(ip);
      if (shelly1 != null) return shelly1;

      // ── ESPHome ────────────────────────────────────────────────────────
      final esp = await _probeEspHome(ip);
      if (esp != null) return esp;

      // ── TP-Link Tapo ───────────────────────────────────────────────────
      final tapo = await _probeTapo(ip);
      if (tapo != null) return tapo;
    }

    // ── Sonoff eWeLink DIY (port 8081) ─────────────────────────────────────
    if (port8081) {
      final sonoff = await _probeSonoff(ip);
      if (sonoff != null) return sonoff;
    }

    // ── TP-Link Kasa (TCP 9999) ────────────────────────────────────────────
    if (port9999) {
      final kasa = await _probeKasa(ip);
      if (kasa != null) return kasa;
    }

    // ── Tuya (TCP 6668) ────────────────────────────────────────────────────
    if (port6668) {
      return _makeTuyaDevice(ip);
    }

    // ── Tuya/MOES via HTTP banner (port 80 but no Shelly/ESPHome/Tapo match) ─
    if (port80) {
      final tuyaHttp = await _probeTuyaHttp(ip);
      if (tuyaHttp != null) return tuyaHttp;
    }

    return null;
  }

  // ── Shelly Gen2 / Gen3 prober ─────────────────────────────────────────────

  Future<SmartSwitchDevice?> _probeShellyGen2(String ip) async {
    try {
      final r = await http
          .post(
            Uri.parse('http://$ip/rpc/Shelly.GetDeviceInfo'),
            headers: {'Content-Type': 'application/json'},
            body: '{}',
          )
          .timeout(_httpTimeout);
      if (r.statusCode != 200) return null;

      final json = jsonDecode(r.body) as Map<String, dynamic>;
      final appField = json['app'] as String?;
      if (appField == null) return null;

      final gen     = json['gen']  as int?  ?? 2;
      final model   = json['model'] as String? ?? appField;
      final mac     = (json['mac'] as String?)?.toUpperCase();
      final fw      = json['fw_id'] as String?;
      final name    = json['name'] as String? ?? 'Shelly $model';

      // Fetch component list to count channels
      final compR = await http
          .post(Uri.parse('http://$ip/rpc/Shelly.GetComponents'),
              headers: {'Content-Type': 'application/json'},
              body: '{}')
          .timeout(_httpTimeout);

      final channelCount = _countShellyGen2Channels(compR);

      // Read relay states
      final channels = <SwitchChannel>[];
      for (int i = 0; i < channelCount; i++) {
        bool isOn = false;
        double? watts;
        try {
          final sr = await http
              .post(Uri.parse('http://$ip/rpc/Switch.GetStatus'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': i}))
              .timeout(_httpTimeout);
          if (sr.statusCode == 200) {
            final s = jsonDecode(sr.body) as Map<String, dynamic>;
            isOn  = s['output'] as bool? ?? false;
            watts = (s['apower'] as num?)?.toDouble();
          }
        } catch (_) {}
        channels.add(SwitchChannel(
            index: i,
            name: channelCount > 1 ? 'Channel ${i + 1}' : 'Switch',
            isOn: isOn,
            powerWatts: watts));
      }

      final proto = gen >= 3
          ? SwitchProtocol.shellyGen3
          : SwitchProtocol.shellyGen2;

      _setProtocolFound(proto);
      return SmartSwitchDevice(
        id:              'shelly_${mac ?? ip}',
        name:            name,
        ip:              ip,
        protocol:        proto,
        model:           model,
        mac:             mac,
        firmwareVersion: fw,
        channels:        channels.isEmpty
            ? [SwitchChannel(index: 0, name: 'Switch', isOn: false)]
            : channels,
      );
    } catch (_) {
      return null;
    }
  }

  int _countShellyGen2Channels(http.Response r) {
    if (r.statusCode != 200) return 1;
    try {
      final j      = jsonDecode(r.body) as Map<String, dynamic>;
      final comps  = j['components'] as List?;
      return comps
              ?.where((c) {
                final type = (c as Map<String, dynamic>)['type'];
                return type == 'switch' || type == 'relay';
              })
              .length ??
          1;
    } catch (_) {
      return 1;
    }
  }

  // ── Shelly Gen1 prober ────────────────────────────────────────────────────

  Future<SmartSwitchDevice?> _probeShellyGen1(String ip) async {
    try {
      final r = await http
          .get(Uri.parse('http://$ip/shelly'))
          .timeout(_httpTimeout);
      if (r.statusCode != 200) return null;

      final json = jsonDecode(r.body) as Map<String, dynamic>;
      // Gen1 always has 'type' like 'SHSW-1', 'SHSW-25', 'SHPLG-S'
      final type = json['type'] as String?;
      if (type == null || !type.startsWith('SH')) return null;

      final mac  = (json['mac']  as String?)?.toUpperCase();
      final fw   = json['fw']    as String?;
      final name = 'Shelly ${_shellyGen1Name(type)}';

      // Count channels
      final numRelays = type.contains('25') || type.contains('2') ? 2 : 1;

      // Read relay states
      final channels = <SwitchChannel>[];
      for (int i = 0; i < numRelays; i++) {
        bool   isOn  = false;
        double? watts;
        try {
          final sr = await http
              .get(Uri.parse('http://$ip/relay/$i'))
              .timeout(_httpTimeout);
          if (sr.statusCode == 200) {
            final s = jsonDecode(sr.body) as Map<String, dynamic>;
            isOn  = s['ison'] as bool? ?? false;
            watts = (s['power'] as num?)?.toDouble();
          }
        } catch (_) {}
        channels.add(SwitchChannel(
            index: i,
            name: numRelays > 1 ? 'Channel ${i + 1}' : 'Switch',
            isOn: isOn,
            powerWatts: watts));
      }

      _setProtocolFound(SwitchProtocol.shellyGen1);
      return SmartSwitchDevice(
        id:              'shelly_${mac ?? ip}',
        name:            name,
        ip:              ip,
        protocol:        SwitchProtocol.shellyGen1,
        model:           type,
        mac:             mac,
        firmwareVersion: fw,
        channels:        channels,
      );
    } catch (_) {
      return null;
    }
  }

  String _shellyGen1Name(String type) {
    if (type.contains('SHPLG')) return 'Plug S';
    if (type.contains('SH25'))  return '2.5';
    if (type.contains('SHEM'))  return 'EM';
    if (type.contains('SH1'))   return '1';
    return type.replaceAll('SH', '');
  }

  // ── ESPHome prober ────────────────────────────────────────────────────────

  Future<SmartSwitchDevice?> _probeEspHome(String ip) async {
    try {
      // ESPHome exposes REST: GET /api/states returns list of entities.
      final r = await http
          .get(Uri.parse('http://$ip/'))
          .timeout(_httpTimeout);
      if (r.statusCode != 200) return null;

      // ESPHome root page contains "ESPHome" in title / X-ESPHome-Version header
      if (!r.headers.containsKey('x-esphome-version') &&
          !r.body.contains('ESPHome') &&
          !r.body.contains('esphome')) {
        return null;
      }

      final ver = r.headers['x-esphome-version'] ?? 'unknown';

      // Fetch switch entities
      final sr = await http
          .get(Uri.parse('http://$ip/switch'))
          .timeout(_httpTimeout);

      final channels = <SwitchChannel>[];
      final entityIds = <String>[];
      if (sr.statusCode == 200) {
        try {
          final entities = jsonDecode(sr.body) as List;
          for (int i = 0; i < entities.length; i++) {
            final e    = entities[i] as Map<String, dynamic>;
            final id   = e['id'] as String? ?? 'switch_$i';
            final name = e['name'] as String? ?? 'Switch $i';
            final isOn = e['state'] == 'on';
            entityIds.add(id);
            channels.add(SwitchChannel(index: i, name: name, isOn: isOn));
          }
        } catch (_) {}
      }

      if (channels.isEmpty) {
        entityIds.add('switch');
        channels.add(SwitchChannel(index: 0, name: 'Switch', isOn: false));
      }

      _setProtocolFound(SwitchProtocol.esphome);
      return SmartSwitchDevice(
        id:              'esp_$ip',
        name:            'ESPHome @ $ip',
        ip:              ip,
        protocol:        SwitchProtocol.esphome,
        firmwareVersion: ver,
        channels:        channels,
        connectionData: {'entityIds': entityIds},
      );
    } catch (_) {
      return null;
    }
  }

  // ── Sonoff DIY prober ─────────────────────────────────────────────────────

  Future<SmartSwitchDevice?> _probeSonoff(String ip) async {
    try {
      final r = await http
          .get(Uri.parse('http://$ip:8081/zeroconf/info'))
          .timeout(_httpTimeout);
      if (r.statusCode != 200) return null;

      final json = jsonDecode(r.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      final deviceId = data['deviceid'] as String? ?? '';
      final model    = data['extra']?['uiid']?.toString() ?? 'Sonoff';
      final fw       = data['fwVersion'] as String?;
      final isOn     = data['switch'] == 'on';
      final name     = 'Sonoff ${deviceId.isNotEmpty ? deviceId.substring(0, 4) : ip}';

      _setProtocolFound(SwitchProtocol.sonoffLan);
      return SmartSwitchDevice(
        id:              'sonoff_${deviceId.isNotEmpty ? deviceId : ip}',
        name:            name,
        ip:              ip,
        protocol:        SwitchProtocol.sonoffLan,
        model:           model,
        firmwareVersion: fw,
        channels: [SwitchChannel(index: 0, name: 'Switch', isOn: isOn)],
        connectionData: {'deviceId': deviceId},
      );
    } catch (_) {
      return null;
    }
  }

  // ── TP-Link Kasa prober (TCP 9999 XOR) ────────────────────────────────────

  Future<SmartSwitchDevice?> _probeKasa(String ip) async {
    try {
      final info = await _kasaSysinfo(ip);
      if (info == null) return null;

      final model  = info['model']      as String? ?? 'Kasa';
      final alias  = info['alias']      as String? ?? 'TP-Link $model';
      final mac    = (info['mac'] as String?)?.toUpperCase();
      final fw     = info['sw_ver']     as String?;
      final isOn   = info['relay_state'] == 1;
      final watts  = (info['emeter']?['get_realtime']?['power'] as num?)
          ?.toDouble();

      _setProtocolFound(SwitchProtocol.kasaLocal);
      return SmartSwitchDevice(
        id:              'kasa_${mac ?? ip}',
        name:            alias,
        ip:              ip,
        protocol:        SwitchProtocol.kasaLocal,
        model:           model,
        mac:             mac,
        firmwareVersion: fw,
        channels: [
          SwitchChannel(index: 0, name: 'Switch', isOn: isOn, powerWatts: watts)
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _kasaSysinfo(String ip) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, 9999,
          timeout: const Duration(milliseconds: 1500));
      s.add(_kasaEncrypt('{"system":{"get_sysinfo":{}}}'));
      await s.flush();
      final buf = <int>[];
      await s.listen(buf.addAll).asFuture<void>()
          .timeout(const Duration(seconds: 2));
      final text = _kasaDecrypt(buf);
      final j = jsonDecode(text) as Map<String, dynamic>;
      return j['system']?['get_sysinfo'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    } finally {
      s?.destroy();
    }
  }

  // ── TP-Link Tapo prober ────────────────────────────────────────────────────

  Future<SmartSwitchDevice?> _probeTapo(String ip) async {
    try {
      // Tapo responds to POST /app with an error but reveals itself
      final r = await http
          .post(Uri.parse('http://$ip/app'),
              headers: {'Content-Type': 'application/json'},
              body: '{"method":"getDeviceInfo","params":{}}')
          .timeout(_httpTimeout);

      final body = r.body;
      // Tapo returns JSON with error_code -1008 (need auth), but the brand is visible
      if (!body.contains('error_code') || r.statusCode != 200) {
        // Check HTTP header / raw response for TP-Link signature
        if (!body.toLowerCase().contains('tp-link') &&
            !body.toLowerCase().contains('tapo')) return null;
      }

      _setProtocolFound(SwitchProtocol.tapoLocal);
      return SmartSwitchDevice(
        id:       'tapo_$ip',
        name:     'TP-Link Tapo @ $ip',
        ip:       ip,
        protocol: SwitchProtocol.tapoLocal,
        model:    'Tapo',
        channels: [SwitchChannel(index: 0, name: 'Switch', isOn: false)],
        connectionData: {'note': 'needs_auth'},
      );
    } catch (_) {
      return null;
    }
  }

  // ── Tuya / MOES via HTTP banner ───────────────────────────────────────────

  static const _tuyaBannerKeywords = [
    'tuya', 'ty_iot', 'smartlife', 'smart life',
    'bk7231', 'wifiiot', 'realtek ameba',
    // MOES and white-label Tuya brands
    'moes', 'moeshouse', 'neo coolcam', 'neo smart',
    'treatlife', 'martin jerry', 'kauf', 'zemismart',
    'aubess', 'girier', 'lonsonho', 'oittm', 'maxcio',
    'smatrul', 'avatto', 'nous', 'athom',
  ];

  Future<SmartSwitchDevice?> _probeTuyaHttp(String ip) async {
    try {
      final resp = await http.get(
        Uri.parse('http://$ip/'),
        headers: {'User-Agent': 'FantaTech/1.0'},
      ).timeout(_httpTimeout);
      final body = resp.body.toLowerCase();
      final matched = _tuyaBannerKeywords.firstWhere(
        (k) => body.contains(k),
        orElse: () => '',
      );
      if (matched.isEmpty) return null;

      // Determine friendly brand name
      String brand = 'Tuya';
      if (body.contains('moes')) brand = 'MOES';
      else if (body.contains('neo coolcam') || body.contains('neo smart')) brand = 'NEO';
      else if (body.contains('zemismart')) brand = 'Zemismart';
      else if (body.contains('treatlife')) brand = 'Treatlife';

      _setProtocolFound(SwitchProtocol.tuyaLocal);
      return SmartSwitchDevice(
        id:       '${brand.toLowerCase()}_$ip',
        name:     '$brand Smart Switch @ $ip',
        ip:       ip,
        protocol: SwitchProtocol.tuyaLocal,
        model:    brand,
        channels: [SwitchChannel(index: 0, name: 'Switch', isOn: false)],
        connectionData: {'note': 'needs_local_key'},
      );
    } catch (_) {
      return null;
    }
  }

  // ── Tuya (TCP 6668 detected only) ─────────────────────────────────────────

  SmartSwitchDevice _makeTuyaDevice(String ip) {
    _setProtocolFound(SwitchProtocol.tuyaLocal);
    return SmartSwitchDevice(
      id:       'tuya_$ip',
      name:     'Tuya Device @ $ip',
      ip:       ip,
      protocol: SwitchProtocol.tuyaLocal,
      model:    'Tuya',
      channels: [SwitchChannel(index: 0, name: 'Switch', isOn: false)],
      connectionData: {'note': 'needs_local_key'},
    );
  }

  // ── mDNS scanner ──────────────────────────────────────────────────────────

  Future<void> _runMdns() async {
    _setProtocol(SwitchProtocol.shellyGen1, ProtocolScanStatus.scanning,
        message: 'mDNS…');
    _setProtocol(SwitchProtocol.esphome,   ProtocolScanStatus.scanning);
    _setProtocol(SwitchProtocol.sonoffLan, ProtocolScanStatus.scanning);
    _setProtocol(SwitchProtocol.kasaLocal, ProtocolScanStatus.scanning);

    final client = MDnsClient();
    try {
      await client.start();

      const services = [
        '_shelly._tcp',        // Shelly (all gens)
        '_esphomelib._tcp',    // ESPHome
        '_ewelink._tcp',       // Sonoff eWeLink
        '_kasa._tcp',          // TP-Link Kasa
      ];

      for (final svc in services) {
        if (_cancelled) break;
        await _queryMdnsService(client, svc);
      }
    } catch (_) {} finally {
      client.stop();
    }
  }

  Future<void> _queryMdnsService(MDnsClient client, String svc) async {
    try {
      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer('$svc.local'))
          .timeout(const Duration(seconds: 2),
              onTimeout: (s) => s.close())) {
        if (_cancelled) return;

        // Resolve IP via SRV → A record
        String ip = '';
        try {
          await for (final SrvResourceRecord srv in client
              .lookup<SrvResourceRecord>(
                  ResourceRecordQuery.service(ptr.domainName))
              .timeout(const Duration(seconds: 1),
                  onTimeout: (s) => s.close())) {
            await for (final IPAddressResourceRecord a in client
                .lookup<IPAddressResourceRecord>(
                    ResourceRecordQuery.addressIPv4(srv.target))
                .timeout(const Duration(seconds: 1),
                    onTimeout: (s) => s.close())) {
              ip = a.address.address;
              break;
            }
            break;
          }
        } catch (_) {}

        if (ip.isEmpty) continue;

        // Probe the resolved IP for more details
        final device = await _probeHost(ip);
        if (device != null) {
          _addDevice(device);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // ── Home Assistant REST ───────────────────────────────────────────────────

  Future<void> _runHaScan(String haIp, String token) async {
    _setProtocol(SwitchProtocol.haRest, ProtocolScanStatus.scanning,
        message: 'Home Assistant…');
    try {
      final r = await http
          .get(
            Uri.parse('http://$haIp:8123/api/states'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));

      if (r.statusCode != 200) {
        _setProtocol(SwitchProtocol.haRest, ProtocolScanStatus.error,
            message: 'HTTP ${r.statusCode}');
        return;
      }

      final entities = jsonDecode(r.body) as List;
      for (final e in entities) {
        final map      = e as Map<String, dynamic>;
        final entityId = map['entity_id'] as String? ?? '';
        final state    = map['state']     as String? ?? '';

        // Only import controllable switch/light entities
        if (!entityId.startsWith('switch.') &&
            !entityId.startsWith('light.')) continue;
        if (state != 'on' && state != 'off') continue;

        final attrs    = map['attributes'] as Map<String, dynamic>? ?? {};
        final friendName = attrs['friendly_name'] as String? ?? entityId;
        final isOn     = state == 'on';

        _addDevice(SmartSwitchDevice(
          id:       'ha_$entityId',
          name:     friendName,
          ip:       haIp,
          protocol: SwitchProtocol.haRest,
          model:    entityId.split('.').first.toUpperCase(),
          channels: [
            SwitchChannel(index: 0, name: 'Switch', isOn: isOn),
          ],
          connectionData: {
            'haIp':     haIp,
            'haToken':  token,
            'entityId': entityId,
          },
        ));
      }

      _setProtocol(SwitchProtocol.haRest, ProtocolScanStatus.done,
          message: '${protocolStates[SwitchProtocol.haRest]?.found ?? 0} entities');
      notifyListeners();
    } catch (e) {
      _setProtocol(SwitchProtocol.haRest, ProtocolScanStatus.error,
          message: e.toString().substring(0, e.toString().length.clamp(0, 40)));
    }
  }

  // ── Zigbee2MQTT ───────────────────────────────────────────────────────────

  Future<void> _runZ2mScan(
      String mqttHost, int mqttPort, String? user, String? pass) async {
    _setProtocol(SwitchProtocol.z2mMqtt, ProtocolScanStatus.scanning,
        message: 'Zigbee2MQTT…');

    final clientId = 'ft_scan_${DateTime.now().millisecondsSinceEpoch}';
    final client   = MqttServerClient.withPort(mqttHost, clientId, mqttPort)
      ..keepAlivePeriod    = 20
      ..connectTimeoutPeriod = 6000
      ..logging(on: false);

    if (user != null && user.isNotEmpty) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(user, pass ?? '')
          .startClean();
    } else {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
    }

    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        _setProtocol(SwitchProtocol.z2mMqtt, ProtocolScanStatus.error,
            message: 'Cannot connect');
        return;
      }

      final devices = await _z2mGetDevices(client, mqttHost, mqttPort, user, pass);

      for (final d in devices) {
        _addDevice(d);
      }

      _setProtocol(SwitchProtocol.z2mMqtt, ProtocolScanStatus.done,
          message: '${devices.length} devices');
      notifyListeners();
    } catch (e) {
      _setProtocol(SwitchProtocol.z2mMqtt, ProtocolScanStatus.error,
          message: 'Error: $e');
    } finally {
      try { client.disconnect(); } catch (_) {}
    }
  }

  Future<List<SmartSwitchDevice>> _z2mGetDevices(
    MqttServerClient client,
    String mqttHost, int mqttPort,
    String? user, String? pass,
  ) async {
    final result = <SmartSwitchDevice>[];

    client.subscribe('zigbee2mqtt/bridge/devices', MqttQos.atMostOnce);

    final completer = Completer<List<SmartSwitchDevice>>();
    final timer = Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) completer.complete(result);
    });

    client.updates?.listen((messages) {
      for (final msg in messages) {
        if (msg.topic != 'zigbee2mqtt/bridge/devices') continue;
        // Extract payload bytes from the ReceivedMessage
        final recvMsg = msg.payload;
        if (recvMsg is! MqttPublishMessage) continue;
        final payload = MqttPublishPayload.bytesToStringAsString(
            recvMsg.payload.message);
        try {
          final list = jsonDecode(payload) as List;
          for (final item in list) {
            final dev = _parseZ2mDevice(
                item as Map<String, dynamic>,
                mqttHost, mqttPort, user, pass);
            if (dev != null) result.add(dev);
          }
          timer.cancel();
          if (!completer.isCompleted) completer.complete(result);
        } catch (_) {}
      }
    });

    return completer.future;
  }

  SmartSwitchDevice? _parseZ2mDevice(
    Map<String, dynamic> d,
    String mqttHost, int mqttPort,
    String? user, String? pass,
  ) {
    final type = d['type'] as String?;
    if (type == 'Coordinator') return null;

    final friendName = d['friendly_name'] as String? ?? d['ieee_address'] as String? ?? '?';
    final model      = d['model_id']      as String?;
    final vendor     = d['manufacturer']  as String?;
    final ieee       = d['ieee_address']  as String?;

    // Check if this device has a toggleable state
    final definition = d['definition'] as Map<String, dynamic>?;
    final exposes    = definition?['exposes'] as List?;
    bool hasState = false;
    if (exposes != null) {
      for (final exp in exposes) {
        final expMap = exp as Map<String, dynamic>;
        if (expMap['type'] == 'switch' ||
            (expMap['type'] == 'binary' &&
                expMap['name'] == 'state')) {
          hasState = true;
          break;
        }
        // Check inside endpoint features
        final features = expMap['features'] as List?;
        if (features != null) {
          for (final f in features) {
            if ((f as Map)['name'] == 'state') {
              hasState = true;
              break;
            }
          }
        }
        if (hasState) break;
      }
    }
    if (!hasState) return null;

    return SmartSwitchDevice(
      id:       'z2m_${ieee ?? friendName}',
      name:     friendName,
      protocol: SwitchProtocol.z2mMqtt,
      model:    model ?? vendor ?? 'Zigbee',
      channels: [SwitchChannel(index: 0, name: 'Switch', isOn: false)],
      connectionData: {
        'mqttHost':   mqttHost,
        'mqttPort':   mqttPort,
        if (user != null) 'mqttUser': user,
        if (pass != null) 'mqttPass': pass,
        'deviceName': friendName,
      },
    );
  }

  // ── Kasa XOR cipher (local) ───────────────────────────────────────────────

  static List<int> _kasaEncrypt(String data) {
    final bytes = utf8.encode(data);
    final result = <int>[
      (bytes.length >> 24) & 0xFF, (bytes.length >> 16) & 0xFF,
      (bytes.length >> 8) & 0xFF,  bytes.length & 0xFF,
    ];
    int key = 171;
    for (final b in bytes) {
      key = key ^ b;
      result.add(key);
    }
    return result;
  }

  static String _kasaDecrypt(List<int> data) {
    final start = data.length > 4 ? 4 : 0;
    int key = 171;
    final sb = StringBuffer();
    for (int i = start; i < data.length; i++) {
      final dec = key ^ data[i];
      key = data[i];
      sb.writeCharCode(dec);
    }
    return sb.toString();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _addDevice(SmartSwitchDevice incoming) {
    if (_cancelled) return;
    final idx = devices.indexWhere(
        (d) => d.id == incoming.id || (incoming.ip != null && d.ip == incoming.ip));
    if (idx >= 0) {
      // Prefer richer details on duplicate
      final existing = devices[idx];
      if (incoming.model != null && existing.model == null) {
        devices[idx] = incoming;
      }
    } else {
      devices.add(incoming);
      protocolStates[incoming.protocol]?.found++;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), notifyListeners);
  }

  void _setProtocol(SwitchProtocol p, ProtocolScanStatus s,
      {String message = ''}) {
    final st = protocolStates[p];
    if (st == null) return;
    st.status  = s;
    st.message = message;
    notifyListeners();
  }

  void _setProtocolFound(SwitchProtocol p) {
    protocolStates[p]?.found++;
  }
}
