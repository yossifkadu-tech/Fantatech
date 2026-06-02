// ─────────────────────────────────────────────────────────────────────────────
// SensorScanEngine  ChangeNotifier
//
// Discovers motion sensors, door/window contacts, and smart covers on the LAN.
//
// Scan strategy:
//   WiFi  — TCP probe /24 subnet → fingerprint Shelly sensors & roller covers
//   HA    — GET /api/states → import binary_sensor.* and cover.*
//   Z2M   — MQTT bridge/devices → filter sensor and cover devices
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'sensor_models.dart';

class SensorScanEngine extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────

  List<SmartSensor> sensors = [];
  List<SmartCover>  covers  = [];
  bool   isScanning      = false;
  double overallProgress = 0;

  final Map<String, SensorScanState> scanStates = {
    'wifi': SensorScanState(
      key:   'WiFi',
      color: const Color(0xFF18BCEC),
      icon:  Icons.wifi_rounded,
    ),
    'ha': SensorScanState(
      key:   'Home Assistant',
      color: const Color(0xFF18BFFF),
      icon:  Icons.home_outlined,
    ),
    'z2m': SensorScanState(
      key:   'Zigbee2MQTT',
      color: const Color(0xFFBA68C8),
      icon:  Icons.hub_outlined,
    ),
  };

  // ── Public ────────────────────────────────────────────────────────────────

  Future<void> startScan({
    String? haIp,
    String? haToken,
    String? mqttHost,
    int     mqttPort = 1883,
    String? mqttUser,
    String? mqttPass,
  }) async {
    if (isScanning) return;
    sensors.clear();
    covers.clear();
    overallProgress = 0;
    for (final s in scanStates.values) {
      s.status       = SensorScanStatus.scanning;
      s.foundSensors = 0;
      s.foundCovers  = 0;
    }
    isScanning = true;
    notifyListeners();

    await Future.wait([
      _runWifiScan(),
      _runHaScan(haIp, haToken),
      _runZ2mScan(mqttHost, mqttPort, mqttUser, mqttPass),
    ]);

    overallProgress = 1.0;
    isScanning = false;
    notifyListeners();
  }

  // ── WiFi scan ─────────────────────────────────────────────────────────────

  Future<void> _runWifiScan() async {
    final state = scanStates['wifi']!;
    try {
      final localIp = await NetworkInfo().getWifiIP();
      if (localIp == null) {
        state.status = SensorScanStatus.done;
        notifyListeners();
        return;
      }

      final prefix      = localIp.substring(0, localIp.lastIndexOf('.'));
      final semaphore   = _Semaphore(20);
      final futures     = <Future<void>>[];
      var done          = 0;

      for (int i = 1; i <= 254; i++) {
        final ip = '$prefix.$i';
        futures.add(semaphore.run(() async {
          await _probeHost(ip, state);
          done++;
          overallProgress = done / 254 * 0.5;
          notifyListeners();
        }));
      }

      await Future.wait(futures);
      state.status = SensorScanStatus.done;
    } catch (e) {
      state.status  = SensorScanStatus.error;
      state.message = e.toString();
    }
    notifyListeners();
  }

  Future<void> _probeHost(String ip, SensorScanState state) async {
    if (!await _tcpProbe(ip, 80)) return;

    // Try Gen2/3 first (RPC), then Gen1
    final result = await _probeGen2(ip) ?? await _probeGen1(ip);
    if (result == null) return;

    if (result is SmartSensor) {
      sensors.add(result);
      state.foundSensors++;
    } else if (result is SmartCover) {
      covers.add(result);
      state.foundCovers++;
    }
    notifyListeners();
  }

  // ── Shelly Gen2/3 ─────────────────────────────────────────────────────────

  Future<Object?> _probeGen2(String ip) async {
    try {
      final r = await http.post(
        Uri.parse('http://$ip/rpc/Shelly.GetDeviceInfo'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(const Duration(milliseconds: 1200));
      if (r.statusCode != 200) return null;

      final info  = jsonDecode(r.body) as Map<String, dynamic>;
      final app   = (info['app']  as String? ?? '').toLowerCase();
      final model = info['app']   as String? ?? '';
      final devId = info['id']    as String? ?? 'gen2-$ip';
      final fw    = info['ver']   as String?;
      final label = info['name']  as String? ?? '$model ${ip.split('.').last}';

      // Motion sensor (Shelly Plus Motion Gen2: app="PlusMot", Gen3: app="S3MotionPMD")
      // Note: app is already lowercased. "PlusMot" → "plusmot", "S3MotionPMD" → "s3motionpmd"
      if (app.contains('motion') || app.contains('plusmot') || app.contains('s3motion')) {
        final triggered = await _rpcBool(ip, 'Motion.GetStatus', 'motion');
        return SmartSensor(
          id: devId, name: label, ip: ip,
          protocol: SensorProtocol.shellyGen2,
          type: SensorType.motion,
          isTriggered: triggered,
          connectionData: {'fw': fw ?? ''},
        );
      }

      // Door/Window sensor (Shelly Plus DW)
      if (app.contains('sensordw') || app.contains('dw')) {
        final triggered = await _rpcBool(ip, 'Input.GetStatus', 'state',
            body: jsonEncode({'id': 0}));
        return SmartSensor(
          id: devId, name: label, ip: ip,
          protocol: SensorProtocol.shellyGen2,
          type: SensorType.contact,
          isTriggered: triggered,
          connectionData: {'fw': fw ?? ''},
        );
      }

      // Try cover mode
      final coverResult = await _probeGen2Cover(ip, devId, label, model);
      return coverResult;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _rpcBool(String ip, String method, String field,
      {String body = '{}'}) async {
    try {
      final r = await http.post(
        Uri.parse('http://$ip/rpc/$method'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(milliseconds: 800));
      if (r.statusCode != 200) return null;
      return (jsonDecode(r.body) as Map<String, dynamic>)[field] as bool?;
    } catch (_) { return null; }
  }

  Future<SmartCover?> _probeGen2Cover(
      String ip, String devId, String name, String model) async {
    try {
      final r = await http.post(
        Uri.parse('http://$ip/rpc/Cover.GetStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': 0}),
      ).timeout(const Duration(milliseconds: 800));
      if (r.statusCode != 200) return null;

      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (!json.containsKey('state')) return null; // not a cover response

      final stateStr = json['state'] as String?;
      final state = switch (stateStr) {
        'open'    => CoverState.open,
        'closed'  => CoverState.closed,
        'opening' => CoverState.opening,
        'closing' => CoverState.closing,
        'stopped' => CoverState.stopped,
        _         => CoverState.unknown,
      };
      final pos = (json['current_pos'] as num?)?.toInt();
      final protocol = model.toLowerCase().contains('gen3') || ip.contains('3')
          ? CoverProtocol.shellyGen3Cover
          : CoverProtocol.shellyGen2Cover;

      return SmartCover(
        id: devId, name: name, ip: ip,
        protocol: protocol, model: model,
        state: state,
        position: pos,
        hasPositionControl: pos != null,
      );
    } catch (_) { return null; }
  }

  // ── Shelly Gen1 ───────────────────────────────────────────────────────────

  Future<Object?> _probeGen1(String ip) async {
    try {
      final r = await http
          .get(Uri.parse('http://$ip/shelly'))
          .timeout(const Duration(milliseconds: 1200));
      if (r.statusCode != 200) return null;

      final info  = jsonDecode(r.body) as Map<String, dynamic>;
      final type  = (info['type'] as String? ?? '').toUpperCase();
      final mac   = info['mac'] as String?;
      final devId = mac ?? 'gen1-$ip';
      final fw    = info['fw'] as String?;
      final label = '$type ${ip.split('.').last}';

      // Door/Window sensor
      if (type.startsWith('SHDW')) {
        final status = await _shellyStatus(ip);
        return SmartSensor(
          id: devId, name: label, ip: ip,
          protocol: SensorProtocol.shellyGen1,
          type: SensorType.contact,
          isTriggered:    status?['sensor']?['state']    as bool?,
          batteryPercent: (status?['bat']?['value']      as num?)?.toInt(),
          temperature:    (status?['tmp']?['tC']         as num?)?.toDouble(),
          humidity:       (status?['hum']?['value']      as num?)?.toDouble(),
          connectionData: {'fw': fw ?? '', if (mac != null) 'mac': mac},
        );
      }

      // Motion sensor
      if (type.startsWith('SHMOS')) {
        final status = await _shellyStatus(ip);
        return SmartSensor(
          id: devId, name: label, ip: ip,
          protocol: SensorProtocol.shellyGen1,
          type: SensorType.motion,
          isTriggered:    status?['sensor']?['motion']   as bool?,
          batteryPercent: (status?['bat']?['value']      as num?)?.toInt(),
          connectionData: {'fw': fw ?? '', if (mac != null) 'mac': mac},
        );
      }

      // Shelly 2.5 — check if in roller mode
      if (type == 'SHSW-25') {
        final settings = await _shellySettings(ip);
        if (settings?['mode'] == 'roller') {
          final rollerResp = await http
              .get(Uri.parse('http://$ip/roller/0'))
              .timeout(const Duration(milliseconds: 800));
          if (rollerResp.statusCode == 200) {
            final json = jsonDecode(rollerResp.body) as Map<String, dynamic>;
            final s    = json['state'] as String?;
            final pos  = (json['current_pos'] as num?)?.toInt();
            final coverState = switch (s) {
              'open'    => CoverState.open,
              'close'   => CoverState.closed,
              'closed'  => CoverState.closed,
              'opening' => CoverState.opening,
              'closing' => CoverState.closing,
              _         => CoverState.unknown,
            };
            return SmartCover(
              id: devId, name: label, ip: ip,
              protocol: CoverProtocol.shellyGen1Roller,
              model: 'SHSW-25',
              state: coverState,
              position: pos,
              hasPositionControl: pos != null,
              connectionData: {'fw': fw ?? '', if (mac != null) 'mac': mac},
            );
          }
        }
      }

      return null;
    } catch (_) { return null; }
  }

  Future<Map?> _shellyStatus(String ip) async {
    try {
      final r = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(milliseconds: 1200));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map;
    } catch (_) { return null; }
  }

  Future<Map?> _shellySettings(String ip) async {
    try {
      final r = await http
          .get(Uri.parse('http://$ip/settings'))
          .timeout(const Duration(milliseconds: 1200));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map;
    } catch (_) { return null; }
  }

  // ── Home Assistant scan ───────────────────────────────────────────────────

  Future<void> _runHaScan(String? haIp, String? haToken) async {
    final state = scanStates['ha']!;
    if (haIp == null || haToken == null) {
      state.status = SensorScanStatus.done;
      notifyListeners();
      return;
    }
    try {
      final r = await http.get(
        Uri.parse('http://$haIp:8123/api/states'),
        headers: {'Authorization': 'Bearer $haToken'},
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');

      final entities = jsonDecode(r.body) as List<dynamic>;
      for (final ent in entities) {
        final e        = ent as Map<String, dynamic>;
        final entityId = e['entity_id'] as String;
        final domain   = entityId.split('.').first;
        final eState   = e['state'] as String?;
        final attrs    = (e['attributes'] as Map?) ?? {};
        final name     = attrs['friendly_name'] as String? ?? entityId;
        final id       = 'ha-$entityId';

        if (eState == 'unavailable' || eState == 'unknown') continue;
        if (sensors.any((s) => s.id == id) || covers.any((c) => c.id == id)) {
          continue;
        }

        final conn = {'haIp': haIp, 'haToken': haToken, 'entityId': entityId};

        if (domain == 'binary_sensor') {
          sensors.add(SmartSensor(
            id: id, name: name,
            protocol: SensorProtocol.haRest,
            type: _haInferType(entityId, attrs),
            isTriggered: eState == 'on',
            batteryPercent: attrs['battery_level'] as int?,
            connectionData: conn,
          ));
          state.foundSensors++;
        } else if (domain == 'cover') {
          final coverState = switch (eState) {
            'open'    => CoverState.open,
            'closed'  => CoverState.closed,
            'opening' => CoverState.opening,
            'closing' => CoverState.closing,
            _         => CoverState.unknown,
          };
          covers.add(SmartCover(
            id: id, name: name,
            protocol: CoverProtocol.haRest,
            state: coverState,
            position:           attrs['current_position'] as int?,
            hasPositionControl: attrs['supported_features'] != null,
            connectionData: conn,
          ));
          state.foundCovers++;
        }
      }
      state.status = SensorScanStatus.done;
    } catch (e) {
      state.status  = SensorScanStatus.error;
      state.message = e.toString();
    }
    notifyListeners();
  }

  SensorType _haInferType(String entityId, Map attrs) {
    final id = entityId.toLowerCase();
    final dc = (attrs['device_class'] as String?)?.toLowerCase() ?? '';
    if (dc == 'motion' || id.contains('motion') || id.contains('occupancy')) {
      return SensorType.motion;
    }
    if (dc == 'door'  || dc == 'window' || dc == 'opening' ||
        id.contains('door') || id.contains('window') || id.contains('contact')) {
      return SensorType.contact;
    }
    if (dc == 'smoke'    || id.contains('smoke'))    return SensorType.smoke;
    if (dc == 'moisture' || id.contains('water') || id.contains('flood')) {
      return SensorType.water;
    }
    if (dc == 'vibration' || id.contains('vibration')) {
      return SensorType.vibration;
    }
    return SensorType.unknown;
  }

  // ── Zigbee2MQTT scan ──────────────────────────────────────────────────────

  Future<void> _runZ2mScan(
    String? mqttHost, int mqttPort, String? mqttUser, String? mqttPass) async {
    final state = scanStates['z2m']!;
    if (mqttHost == null) {
      state.status = SensorScanStatus.done;
      notifyListeners();
      return;
    }

    final clientId = 'ft_sse_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(mqttHost, clientId, mqttPort)
      ..keepAlivePeriod    = 20
      ..connectTimeoutPeriod = 5000
      ..logging(on: false);

    if (mqttUser != null && mqttUser.isNotEmpty) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(mqttUser, mqttPass ?? '')
          .startClean();
    } else {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
    }

    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        throw Exception('MQTT connection failed');
      }
      client.subscribe('zigbee2mqtt/bridge/devices', MqttQos.atMostOnce);

      final completer = Completer<void>();
      client.updates?.listen((events) {
        for (final event in events) {
          final msg = event.payload;
          if (msg is! MqttPublishMessage) continue;
          if (event.topic != 'zigbee2mqtt/bridge/devices') continue;
          try {
            final pl = MqttPublishPayload.bytesToStringAsString(
                msg.payload.message);
            _parseZ2mDevices(
                jsonDecode(pl) as List, mqttHost, mqttPort, mqttUser, mqttPass);
          } catch (_) {}
          if (!completer.isCompleted) completer.complete();
        }
      });

      await Future.any([
        completer.future,
        Future<void>.delayed(const Duration(seconds: 5)),
      ]);
      state.status = SensorScanStatus.done;
    } catch (e) {
      state.status  = SensorScanStatus.error;
      state.message = e.toString();
    } finally {
      try { client.disconnect(); } catch (_) {}
    }
    notifyListeners();
  }

  void _parseZ2mDevices(
    List devices, String host, int port, String? user, String? pass) {
    final state = scanStates['z2m']!;
    for (final d in devices) {
      final device  = d as Map<String, dynamic>;
      final ieee    = device['ieee_address'] as String? ?? '';
      final name    = device['friendly_name'] as String? ?? ieee;
      final defn    = device['definition'] as Map?;
      final exposes = (defn?['exposes'] as List?) ?? [];

      if (ieee.isEmpty || name == 'Coordinator') continue;

      final conn = {
        'mqttHost':   host,
        'mqttPort':   port,
        if (user != null) 'mqttUser': user,
        if (pass != null) 'mqttPass': pass,
        'deviceName': name,
      };
      final id = 'z2m-$ieee';

      // Cover device
      if (_exposesContains(exposes, 'position') ||
          exposes.any((e) => (e as Map?)?['type'] == 'cover')) {
        if (!covers.any((c) => c.id == id)) {
          covers.add(SmartCover(
            id: id, name: name,
            protocol: CoverProtocol.z2mMqtt,
            hasPositionControl: _exposesContains(exposes, 'position'),
            connectionData: conn,
          ));
          state.foundCovers++;
        }
        continue;
      }

      // Sensor type
      final hasOcc   = _exposesContains(exposes, 'occupancy');
      final hasCont  = _exposesContains(exposes, 'contact');
      final hasSmoke = _exposesContains(exposes, 'smoke');
      final hasWater = _exposesContains(exposes, 'water_leak');
      if (!hasOcc && !hasCont && !hasSmoke && !hasWater) continue;

      final sensorType = hasOcc ? SensorType.motion
                       : hasCont ? SensorType.contact
                       : hasSmoke ? SensorType.smoke
                       : SensorType.water;

      if (!sensors.any((s) => s.id == id)) {
        sensors.add(SmartSensor(
          id: id, name: name,
          protocol: SensorProtocol.z2mMqtt,
          type: sensorType,
          connectionData: conn,
        ));
        state.foundSensors++;
      }
    }
    notifyListeners();
  }

  bool _exposesContains(List exposes, String property) =>
      exposes.any((e) => _propSearch(e as Map?, property));

  bool _propSearch(Map? e, String p) {
    if (e == null) return false;
    if (e['property'] == p) return true;
    final features = e['features'] as List?;
    if (features == null) return false;
    return features.any((f) => _propSearch(f as Map?, p));
  }

  // ── TCP probe ─────────────────────────────────────────────────────────────

  static Future<bool> _tcpProbe(String ip, int port) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 500));
      return true;
    } catch (_) { return false; }
    finally { s?.destroy(); }
  }
}

// ── Bounded concurrency helper ────────────────────────────────────────────────

class _Semaphore {
  final int _max;
  int _active = 0;
  final _queue = Queue<Completer<void>>();

  _Semaphore(this._max);

  Future<T> run<T>(Future<T> Function() fn) async {
    if (_active >= _max) {
      final c = Completer<void>();
      _queue.add(c);
      await c.future;
    }
    _active++;
    try {
      return await fn();
    } finally {
      _active--;
      if (_queue.isNotEmpty) _queue.removeFirst().complete();
    }
  }
}
