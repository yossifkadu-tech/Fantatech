// ─────────────────────────────────────────────────────────────────────────────
// GatewayManager — ChangeNotifier that manages all gateway connections.
//
// Responsibilities:
//   • Persist / restore connected gateways (SharedPreferences JSON)
//   • Connect to a new gateway (delegates to per-type client)
//   • Import devices from a connected gateway → returns List<Device>
//   • Expose per-gateway pairing state (waiting for button, polling, error)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/device.dart';
import '../discovery/ha_client.dart';
import '../discovery/device_classifier.dart';
import 'gateway_model.dart';
import 'gateway_types.dart';
import 'clients/hue_client.dart';
import 'clients/deconz_client.dart';
import 'clients/z2m_client.dart';
import 'clients/smartthings_client.dart';
import 'clients/dirigera_client.dart';
import 'clients/mqtt_gateway_client.dart';
import 'clients/tuya_cloud_client.dart';

class GatewayManager extends ChangeNotifier {
  static const _prefsKey = 'gateway_connections';
  static const _uuid = Uuid();

  // ── Public state ────────────────────────────────────────────────────────────
  final List<GatewayConnection> connections = [];

  /// Pairing in progress for a specific type
  bool   isPairing      = false;
  int    pairCountdown  = 30;
  String pairStatus     = '';
  String? pairError;

  /// Importing in progress
  bool   isImporting    = false;
  String importStatus   = '';

  List<String> log = [];

  // ── Init ───────────────────────────────────────────────────────────────────

  GatewayManager() {
    _load();
  }

  // ── Connect ─────────────────────────────────────────────────────────────────

  /// [fields] maps fieldDef.key → value entered by user.
  /// Returns null on success, error string on failure.
  Future<String?> connect(
    GatewayType type,
    Map<String, String> fields,
  ) async {
    isPairing   = true;
    pairError   = null;
    pairStatus  = 'מתחבר…';
    pairCountdown = 30;
    notifyListeners();

    try {
      final result = await _doConnect(type, fields);
      isPairing = false;
      if (result.success) {
        pairStatus = 'מחובר!';
        notifyListeners();
        return null;
      } else {
        pairError  = result.error;
        pairStatus = '';
        notifyListeners();
        return result.error;
      }
    } catch (e) {
      isPairing  = false;
      pairError  = e.toString();
      pairStatus = '';
      notifyListeners();
      return e.toString();
    }
  }

  Future<GatewayConnectResult> _doConnect(
    GatewayType type,
    Map<String, String> fields,
  ) async {
    final ip    = fields['ip']   ?? '';
    final token = fields['token'] ?? '';
    switch (type) {
      // ── Home Assistant ──────────────────────────────────────────────────────
      case GatewayType.homeAssistant: {
        final ok = await HaClient.detect(ip);
        if (!ok) return const GatewayConnectResult.fail('לא נמצא Home Assistant בכתובת זו');
        final res = await HaClient.fetchDevices(ip, token);
        if (!res.isSuccess) return GatewayConnectResult.fail(res.errorMessage!);
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Home Assistant ($ip)',
          credentials: {'ip': ip, 'token': token},
          isConnected: true,
          deviceCount: res.devices.length,
          lastSync:    DateTime.now(),
        ));
        // Save token for HA client too
        await HaClient.saveCredentials(ip, token);
        return GatewayConnectResult.ok({'ip': ip, 'token': token});
      }

      // ── Philips Hue ─────────────────────────────────────────────────────────
      case GatewayType.hue: {
        _setPairStatus('לחץ כפתור על גשר ה-Hue…', 30);
        final bridgeName = await HueGatewayClient.getBridgeName(ip);
        if (bridgeName == null) return const GatewayConnectResult.fail('לא נמצא גשר Hue בכתובת זו');

        final username = await HueGatewayClient.pairWithPolling(ip,
          onWaiting: (rem) {
            pairCountdown = rem;
            pairStatus    = 'ממתין לכפתור… $rem שניות';
            notifyListeners();
          },
        );
        if (username == null) {
          return const GatewayConnectResult.fail('הזמן פג — לא נלחץ הכפתור');
        }
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: bridgeName,
          credentials: {'ip': ip, 'username': username},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'ip': ip, 'username': username});
      }

      // ── IKEA DIRIGERA ────────────────────────────────────────────────────────
      case GatewayType.dirigera: {
        _setPairStatus('לחץ עכשיו על הכפתור בתחתית ה-DIRIGERA…', 60);
        var diag = '';
        final accessToken = await DIRIGERAGatewayClient.pairWithPolling(ip,
          seconds: 60,
          onWaiting: (rem) {
            pairCountdown = rem;
            pairStatus    = 'ממתין ללחיצת כפתור… $rem שניות';
            notifyListeners();
          },
          onStatus: (msg) {
            diag       = msg;
            pairStatus = msg;
            notifyListeners();
          },
        );
        if (accessToken == null) {
          return GatewayConnectResult.fail(
              diag.isEmpty ? 'לא הושלם החיבור — ודא שלחצת על הכפתור בזמן' : diag);
        }

        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'IKEA DIRIGERA ($ip)',
          credentials: {'ip': ip, 'token': accessToken},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'ip': ip, 'token': accessToken});
      }

      // ── IKEA Trådfri ─────────────────────────────────────────────────────────
      case GatewayType.tradfri: {
        // CoAP protocol — not supported natively in Dart without a native plugin.
        // Store credentials, show "coming soon" message.
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'IKEA Trådfri ($ip)',
          credentials: {'ip': ip, 'code': fields['code'] ?? ''},
          isConnected: false,
          error:       'CoAP protocol — coming in next version',
        ));
        return const GatewayConnectResult.fail(
            'Trådfri (CoAP) אינו נתמך עדיין — שדרג ל-DIRIGERA');
      }

      // ── Zigbee2MQTT ──────────────────────────────────────────────────────────
      case GatewayType.zigbee2mqtt: {
        final port   = int.tryParse(fields['port'] ?? '8080') ?? 8080;
        final apiKey = fields['token'];
        final healthy = await Z2MGatewayClient.isHealthy(ip, port, token: apiKey);
        if (!healthy) {
          return GatewayConnectResult.fail(
              'לא ניתן להגיע ל-Zigbee2MQTT בכתובת $ip:$port');
        }
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Zigbee2MQTT ($ip:$port)',
          credentials: {'ip': ip, 'port': '$port', 'token': apiKey ?? ''},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'ip': ip});
      }

      // ── deCONZ ───────────────────────────────────────────────────────────────
      case GatewayType.deconz: {
        final port = int.tryParse(fields['port'] ?? '80') ?? 80;
        _setPairStatus('ממתין לאישור ב-Phoscon…', 30);
        final apiKey = await DeCONZGatewayClient.pairWithPolling(ip, port,
          onWaiting: (rem) {
            pairCountdown = rem;
            pairStatus    = 'ממתין לאישור… $rem שניות';
            notifyListeners();
          },
        );
        if (apiKey == null) return const GatewayConnectResult.fail('לא אושר ב-Phoscon בזמן');
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'deCONZ ($ip)',
          credentials: {'ip': ip, 'port': '$port', 'apiKey': apiKey},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'ip': ip, 'apiKey': apiKey});
      }

      // ── SmartThings ──────────────────────────────────────────────────────────
      case GatewayType.smartThings: {
        final ok = await SmartThingsClient.verifyToken(token);
        if (!ok) return const GatewayConnectResult.fail('Token לא תקין או אין גישה לרשת');
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Samsung SmartThings',
          credentials: {'token': token},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'token': token});
      }

      // ── Tuya Smart (Moes / Tuya cloud) ────────────────────────────────────────
      case GatewayType.tuyaSmart: {
        final clientId     = fields['clientId']     ?? '';
        final clientSecret = fields['clientSecret'] ?? '';
        final region       = TuyaRegionHost.fromName(fields['region']);

        _setPairStatus('מתחבר ל-Tuya Cloud…', 0);
        final ok = await TuyaCloudClient.testConnection(
          clientId:     clientId,
          clientSecret: clientSecret,
          region:       region,
        );
        if (!ok) {
          return const GatewayConnectResult.fail(
              'אימות Tuya נכשל — בדוק Access ID / Secret והאזור');
        }

        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Tuya Smart (${region.label})',
          credentials: {
            'clientId':     clientId,
            'clientSecret': clientSecret,
            'region':       region.name,
          },
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'clientId': clientId});
      }

      // ── MQTT ─────────────────────────────────────────────────────────────────
      case GatewayType.mqtt: {
        final host     = fields['host'] ?? ip;
        final mqttPort = int.tryParse(fields['port'] ?? '1883') ?? 1883;
        final user     = fields['username'];
        final pass     = fields['password'];
        _setPairStatus('מתחבר לברוקר MQTT…', 0);
        final ok = await MQTTGatewayClient.testConnection(
          host: host, port: mqttPort, username: user, password: pass);
        if (!ok) return const GatewayConnectResult.fail('לא ניתן להתחבר לברוקר MQTT');
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'MQTT ($host:$mqttPort)',
          credentials: {
            'host':     host,
            'port':     '$mqttPort',
            'username': user ?? '',
            'password': pass ?? '',
            'prefix':   fields['prefix'] ?? 'homeassistant',
          },
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'host': host});
      }
    }
  }

  // ── Import devices ─────────────────────────────────────────────────────────

  /// Quietly re-fetches devices from every connected gateway (no UI status
  /// changes). Used by the background leak/state monitor.
  Future<List<Device>> fetchAllCurrentDevices() async {
    final all = <Device>[];
    for (final conn in connections.where((c) => c.isConnected)) {
      try {
        final result = await _doImport(conn);
        if (result.isSuccess) all.addAll(result.devices);
      } catch (_) {/* ignore — best-effort poll */}
    }
    return all;
  }

  Future<List<Device>> importDevices(String gatewayId) async {
    final conn = connections.firstWhere((c) => c.id == gatewayId,
        orElse: () => throw StateError('Gateway not found'));

    isImporting  = true;
    importStatus = 'מייבא מכשירים…';
    notifyListeners();

    GatewayImportResult result;
    try {
      result = await _doImport(conn);
    } catch (e) {
      result = GatewayImportResult.failure(e.toString());
    }

    isImporting = false;
    if (result.isSuccess) {
      conn.deviceCount = result.devices.length;
      conn.lastSync    = DateTime.now();
      conn.error       = null;
      importStatus     = '${result.devices.length} מכשירים יובאו';
    } else {
      conn.error   = result.error;
      importStatus = result.error ?? '';
    }
    _persist();
    notifyListeners();
    return result.isSuccess ? result.devices : [];
  }

  Future<GatewayImportResult> _doImport(GatewayConnection conn) async {
    final creds = conn.credentials;
    switch (conn.type) {
      case GatewayType.homeAssistant: {
        final r = await HaClient.fetchDevices(creds['ip']!, creds['token']!);
        if (!r.isSuccess) return GatewayImportResult.failure(r.errorMessage);
        final devices = r.devices.map((d) => Device(
          id:           d.id,
          name:         d.displayName,
          type:         DeviceClassifier.toAppType(d.type),
          status:       DeviceStatus.online,
          attributes:   d.metadata,
          room:         '',
        )).toList();
        return GatewayImportResult.success(devices);
      }

      case GatewayType.hue:
        return HueGatewayClient.fetchDevices(creds['ip']!, creds['username']!);

      case GatewayType.dirigera:
        return DIRIGERAGatewayClient.fetchDevices(creds['ip']!, creds['token']!);

      case GatewayType.zigbee2mqtt:
        return Z2MGatewayClient.fetchDevices(
          creds['ip']!,
          int.tryParse(creds['port'] ?? '8080') ?? 8080,
          token: creds['token']?.isEmpty == true ? null : creds['token'],
        );

      case GatewayType.deconz:
        return DeCONZGatewayClient.fetchDevices(
          creds['ip']!,
          int.tryParse(creds['port'] ?? '80') ?? 80,
          creds['apiKey']!,
        );

      case GatewayType.smartThings:
        return SmartThingsClient.fetchDevices(creds['token']!);

      case GatewayType.tuyaSmart:
        return TuyaCloudClient.fetchDevices(
          clientId:     creds['clientId']!,
          clientSecret: creds['clientSecret']!,
          region:       TuyaRegionHost.fromName(creds['region']),
        );

      case GatewayType.mqtt:
        return MQTTGatewayClient.discoverDevices(
          host:     creds['host']!,
          port:     int.tryParse(creds['port'] ?? '1883') ?? 1883,
          username: creds['username'],
          password: creds['password'],
          prefix:   creds['prefix'] ?? 'homeassistant',
        );

      default:
        return const GatewayImportResult.failure('לא נתמך עדיין');
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  void disconnect(String gatewayId) {
    connections.removeWhere((c) => c.id == gatewayId);
    _persist();
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _addConnection(GatewayConnection conn) {
    connections.add(conn);
    _persist();
    notifyListeners();
  }

  void _setPairStatus(String status, int countdown) {
    pairStatus    = status;
    pairCountdown = countdown;
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list  = connections.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_prefsKey, list);
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list  = prefs.getStringList(_prefsKey) ?? [];
      for (final raw in list) {
        try {
          connections.add(
              GatewayConnection.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }
}
