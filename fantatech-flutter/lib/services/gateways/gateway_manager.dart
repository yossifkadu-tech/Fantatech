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
import 'package:uuid/uuid.dart';
import '../storage/secure_cred_service.dart';
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
import 'clients/aqara_hub_client.dart';
import 'clients/ajax_client.dart';
import 'clients/risco_client.dart';
import 'clients/pima_client.dart';
import 'clients/zwave_client.dart';
import 'clients/ifttt_client.dart';

class GatewayManager extends ChangeNotifier {
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
    pairStatus  = 'Connecting…';
    pairCountdown = 30;
    notifyListeners();

    try {
      final result = await _doConnect(type, fields);
      isPairing = false;
      if (result.success) {
        pairStatus = 'Connected!';
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
        if (!ok) return const GatewayConnectResult.fail('Home Assistant not found at this address');
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
        _setPairStatus('Press the button on the Hue bridge…', 30);
        final bridgeName = await HueGatewayClient.getBridgeName(ip);
        if (bridgeName == null) return const GatewayConnectResult.fail('Hue bridge not found at this address');

        final username = await HueGatewayClient.pairWithPolling(ip,
          onWaiting: (rem) {
            pairCountdown = rem;
            pairStatus    = 'Waiting for button… $rem s';
            notifyListeners();
          },
        );
        if (username == null) {
          return const GatewayConnectResult.fail('Timed out — button was not pressed');
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
        _setPairStatus('Press the button on the bottom of the DIRIGERA now…', 60);
        var diag = '';
        final accessToken = await DIRIGERAGatewayClient.pairWithPolling(ip,
          seconds: 60,
          onWaiting: (rem) {
            pairCountdown = rem;
            pairStatus    = 'Waiting for button press… $rem s';
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
              diag.isEmpty ? 'Connection not completed — make sure you pressed the button in time' : diag);
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
            'Trådfri (CoAP) not supported yet — upgrade to DIRIGERA');
      }

      // ── Zigbee2MQTT ──────────────────────────────────────────────────────────
      case GatewayType.zigbee2mqtt: {
        final port   = int.tryParse(fields['port'] ?? '8080') ?? 8080;
        final apiKey = fields['token'];
        final healthy = await Z2MGatewayClient.isHealthy(ip, port, token: apiKey);
        if (!healthy) {
          return GatewayConnectResult.fail(
              'Cannot reach Zigbee2MQTT at $ip:$port');
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
        _setPairStatus('Waiting for approval in Phoscon…', 30);
        final apiKey = await DeCONZGatewayClient.pairWithPolling(ip, port,
          onWaiting: (rem) {
            pairCountdown = rem;
            pairStatus    = 'Waiting for approval… $rem s';
            notifyListeners();
          },
        );
        if (apiKey == null) return const GatewayConnectResult.fail('Not approved in Phoscon in time');
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
        if (!ok) return const GatewayConnectResult.fail('Invalid token or no network access');
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

        _setPairStatus('Connecting to Tuya Cloud…', 0);
        final ok = await TuyaCloudClient.testConnection(
          clientId:     clientId,
          clientSecret: clientSecret,
          region:       region,
        );
        if (!ok) {
          return const GatewayConnectResult.fail(
              'Tuya authentication failed — check Access ID / Secret and region');
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
        _setPairStatus('Connecting to MQTT broker…', 0);
        final ok = await MQTTGatewayClient.testConnection(
          host: host, port: mqttPort, username: user, password: pass);
        if (!ok) return const GatewayConnectResult.fail('Cannot connect to MQTT broker');
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

      // ── Matter ────────────────────────────────────────────────────────────────
      case GatewayType.matter: {
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Matter / Thread',
          credentials: {},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return const GatewayConnectResult.ok({});
      }

      // ── Smart Life / Tuya IoT ─────────────────────────────────────────────────
      case GatewayType.smartLife: {
        final clientId     = fields['clientId']     ?? '';
        final clientSecret = fields['clientSecret'] ?? '';
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Smart Life',
          credentials: {'clientId': clientId, 'clientSecret': clientSecret},
          isConnected: clientId.isNotEmpty,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({'clientId': clientId});
      }

      // ── Aqara Hub ────────────────────────────────────────────────────────────
      case GatewayType.aqara: {
        final accessToken = fields['token']?.isNotEmpty == true ? fields['token']! : token;
        if (ip.isEmpty || accessToken.isEmpty) {
          return const GatewayConnectResult.fail('IP and access token are required');
        }
        // Verify the hub is reachable — a 401 response with "aqara" in body
        // is the fingerprint (no token needed for the probe).
        final probe = await AqaraHubClient(ip: ip, accessToken: accessToken)
            .getDevices();
        // getDevices returns [] on any error, so if the token is wrong we still
        // store the connection (token may be correct but hub returned an odd format).
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Aqara Hub ($ip)',
          credentials: {'ip': ip, 'token': accessToken},
          isConnected: true,
          lastSync:    DateTime.now(),
          deviceCount: probe.length,
        ));
        return GatewayConnectResult.ok({'ip': ip, 'deviceCount': '${probe.length}'});
      }

      // ── Ajax Systems ─────────────────────────────────────────────────────────
      case GatewayType.ajax: {
        final email    = fields['email']    ?? '';
        final password = fields['password'] ?? '';
        final apiKey   = fields['apiKey']   ?? '';
        if (email.isEmpty || password.isEmpty) {
          return const GatewayConnectResult.fail('Email and password are required');
        }
        final client = AjaxClient(email: email, password: password, apiKey: apiKey.isEmpty ? null : apiKey);
        final ok = await client.login();
        if (!ok) return const GatewayConnectResult.fail('Ajax login failed — check credentials');
        final devices = await client.getDevices();
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Ajax Systems ($email)',
          credentials: {'email': email, 'password': password, 'apiKey': apiKey},
          isConnected: true,
          lastSync:    DateTime.now(),
          deviceCount: devices.length,
        ));
        return GatewayConnectResult.ok({'deviceCount': '${devices.length}'});
      }

      // ── Risco ────────────────────────────────────────────────────────────────
      case GatewayType.risco: {
        final username = fields['username'] ?? '';
        final password = fields['password'] ?? '';
        final localIp  = fields['ip']       ?? '';
        final pin      = fields['pin']      ?? '';
        if ((username.isEmpty || password.isEmpty) && localIp.isEmpty) {
          return const GatewayConnectResult.fail('Username/password or local IP required');
        }
        if (pin.isEmpty) return const GatewayConnectResult.fail('Panel PIN code is required');
        final client = RiscoClient(username: username, password: password, pin: pin, localIp: localIp.isEmpty ? null : localIp);
        final ok = await client.login();
        if (!ok) return const GatewayConnectResult.fail('Risco login failed — check credentials');
        final zones = await client.getZones();
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Risco (${localIp.isNotEmpty ? localIp : username})',
          credentials: {'username': username, 'password': password, 'ip': localIp, 'pin': pin},
          isConnected: true,
          lastSync:    DateTime.now(),
          deviceCount: zones.length,
        ));
        return GatewayConnectResult.ok({'deviceCount': '${zones.length}'});
      }

      // ── PIMA ─────────────────────────────────────────────────────────────────
      case GatewayType.pima: {
        final pimaIp   = fields['ip']   ?? '';
        final pimaPort = int.tryParse(fields['port'] ?? '') ?? 9999;
        final pimaCode = fields['code'] ?? '';
        if (pimaIp.isEmpty) return const GatewayConnectResult.fail('Panel IP address is required');
        if (pimaCode.isEmpty) return const GatewayConnectResult.fail('Installer/user code is required');
        final client = PimaClient(ip: pimaIp, code: pimaCode, port: pimaPort);
        final ok = await client.probe();
        if (!ok) return GatewayConnectResult.fail('Cannot reach PIMA panel at $pimaIp:$pimaPort');
        final zones = await client.getZones();
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'PIMA Panel ($pimaIp)',
          credentials: {'ip': pimaIp, 'port': '$pimaPort', 'code': pimaCode},
          isConnected: true,
          lastSync:    DateTime.now(),
          deviceCount: zones.length,
        ));
        return GatewayConnectResult.ok({'deviceCount': '${zones.length}'});
      }

      // ── Z-Wave JS UI ─────────────────────────────────────────────────────────
      case GatewayType.zwave: {
        final zwaveIp   = fields['ip']     ?? '';
        final zwavePort = int.tryParse(fields['port'] ?? '') ?? 8091;
        final zwaveKey  = fields['apiKey'] ?? '';
        if (zwaveIp.isEmpty) return const GatewayConnectResult.fail('Z-Wave JS UI IP address is required');
        final client = ZWaveClient(ip: zwaveIp, port: zwavePort, apiKey: zwaveKey.isEmpty ? null : zwaveKey);
        final ok = await client.probe();
        if (!ok) return GatewayConnectResult.fail('Cannot reach Z-Wave JS UI at $zwaveIp:$zwavePort');
        final nodes = await client.getNodes();
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'Z-Wave JS UI ($zwaveIp)',
          credentials: {'ip': zwaveIp, 'port': '$zwavePort', 'apiKey': zwaveKey},
          isConnected: true,
          lastSync:    DateTime.now(),
          deviceCount: nodes.length,
        ));
        return GatewayConnectResult.ok({'deviceCount': '${nodes.length}'});
      }

      // ── IFTTT ────────────────────────────────────────────────────────────────
      case GatewayType.ifttt: {
        final webhookKey = fields['webhookKey'] ?? '';
        if (webhookKey.isEmpty) return const GatewayConnectResult.fail('Webhooks key is required');
        final client = IftttClient(webhookKey: webhookKey);
        final ok = await client.testKey();
        if (!ok) return const GatewayConnectResult.fail('IFTTT Webhook key is invalid');
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: 'IFTTT Webhooks',
          credentials: {'webhookKey': webhookKey},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({});
      }

      // ── Voice assistants (instructions only — no API pairing) ─────────────────
      case GatewayType.googleAssistant:
      case GatewayType.alexa:
      case GatewayType.siri: {
        final label = type == GatewayType.googleAssistant
            ? 'Google Assistant'
            : type == GatewayType.alexa
                ? 'Amazon Alexa'
                : 'Siri / HomeKit';
        _addConnection(GatewayConnection(
          id:          _uuid.v4(),
          type:        type,
          displayName: label,
          credentials: {},
          isConnected: true,
          lastSync:    DateTime.now(),
        ));
        return GatewayConnectResult.ok({});
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
    importStatus = 'Importing devices…';
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
      importStatus     = '${result.devices.length} devices imported';
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

    String _str(String key) => (creds[key] as String?) ?? '';

    switch (conn.type) {
      case GatewayType.homeAssistant: {
        final ip = _str('ip'); final token = _str('token');
        if (ip.isEmpty || token.isEmpty) {
          return const GatewayImportResult.failure('Missing HA credentials');
        }
        final r = await HaClient.fetchDevices(ip, token);
        if (!r.isSuccess) return GatewayImportResult.failure(r.errorMessage);
        final devices = r.devices.map((d) {
          // HA reports offline devices via their state string, not a
          // separate HTTP failure — 'unavailable'/'unknown' both mean the
          // underlying device isn't actually reachable right now.
          final rawState = (d.metadata['state'] as String? ?? '').toLowerCase();
          final offline  = rawState == 'unavailable' || rawState == 'unknown';
          return Device(
            id:           d.id,
            name:         d.displayName,
            type:         DeviceClassifier.toAppType(d.type),
            status:       offline ? DeviceStatus.offline : DeviceStatus.online,
            attributes:   d.metadata,
            room:         '',
            source:       'gateway',
          );
        }).toList();
        return GatewayImportResult.success(devices);
      }

      case GatewayType.hue: {
        final ip = _str('ip'); final user = _str('username');
        if (ip.isEmpty || user.isEmpty) {
          return const GatewayImportResult.failure('Missing Hue credentials');
        }
        return HueGatewayClient.fetchDevices(ip, user);
      }

      case GatewayType.dirigera: {
        final ip = _str('ip'); final token = _str('token');
        if (ip.isEmpty || token.isEmpty) {
          return const GatewayImportResult.failure('Missing DIRIGERA credentials');
        }
        return DIRIGERAGatewayClient.fetchDevices(ip, token);
      }

      case GatewayType.zigbee2mqtt: {
        final ip = _str('ip');
        if (ip.isEmpty) {
          return const GatewayImportResult.failure('Missing Z2M host');
        }
        final tok = _str('token');
        return Z2MGatewayClient.fetchDevices(
          ip,
          int.tryParse(creds['port'] ?? '8080') ?? 8080,
          token: tok.isEmpty ? null : tok,
        );
      }

      case GatewayType.deconz: {
        final ip = _str('ip'); final key = _str('apiKey');
        if (ip.isEmpty || key.isEmpty) {
          return const GatewayImportResult.failure('Missing deCONZ credentials');
        }
        final port = int.tryParse(creds['port'] ?? '80') ?? 80;
        // Open the join window so a device held in pairing mode can
        // actually join the mesh before we read the device list back.
        await DeCONZGatewayClient.permitJoin(ip, port, key, seconds: 60);
        await Future.delayed(const Duration(seconds: 20));
        return DeCONZGatewayClient.fetchDevices(ip, port, key);
      }

      case GatewayType.smartThings: {
        final token = _str('token');
        if (token.isEmpty) {
          return const GatewayImportResult.failure('Missing SmartThings token');
        }
        return SmartThingsClient.fetchDevices(token);
      }

      case GatewayType.tuyaSmart: {
        final id = _str('clientId'); final secret = _str('clientSecret');
        if (id.isEmpty || secret.isEmpty) {
          return const GatewayImportResult.failure('Missing Tuya credentials');
        }
        return TuyaCloudClient.fetchDevices(
          clientId:     id,
          clientSecret: secret,
          region:       TuyaRegionHost.fromName(creds['region']),
        );
      }

      case GatewayType.mqtt: {
        final host = _str('host');
        if (host.isEmpty) {
          return const GatewayImportResult.failure('Missing MQTT host');
        }
        return MQTTGatewayClient.discoverDevices(
          host:     host,
          port:     int.tryParse(creds['port'] ?? '1883') ?? 1883,
          username: creds['username'],
          password: creds['password'],
          prefix:   creds['prefix'] ?? 'homeassistant',
        );
      }

      case GatewayType.aqara: {
        final ip    = _str('ip');
        final token = _str('token');
        if (ip.isEmpty || token.isEmpty) {
          return const GatewayImportResult.failure('Missing Aqara credentials');
        }
        final raw = await AqaraHubClient(ip: ip, accessToken: token).getDevices();
        final devices = raw.map((d) {
          final did   = d['did']   as String? ?? '';
          final model = d['model'] as String? ?? '';
          final name  = d['name']  as String?  ??
                        d['friendlyName'] as String? ?? model;
          return Device(
            id:         'aqara-$did',
            name:       name,
            type:       _aqaraModelToDeviceType(model),
            status:     DeviceStatus.online,
            attributes: {'model': model, 'did': did, 'aqaraIp': ip},
            room:       '',
            source:     'gateway',
          );
        }).where((d) => d.id != 'aqara-').toList();
        return GatewayImportResult.success(devices);
      }

      // ── Ajax Systems ─────────────────────────────────────────────────────────
      case GatewayType.ajax: {
        final email    = _str('email');
        final password = _str('password');
        final apiKey   = _str('apiKey');
        if (email.isEmpty || password.isEmpty) {
          return const GatewayImportResult.failure('Missing Ajax credentials');
        }
        final client  = AjaxClient(email: email, password: password, apiKey: apiKey.isEmpty ? null : apiKey);
        final devices = await client.getDevices();
        final mapped  = devices.map((d) => Device(
          id:         'ajax-${d.id}',
          name:       d.name,
          type:       _ajaxTypeToDeviceType(d.type),
          status:     d.online ? DeviceStatus.online : DeviceStatus.offline,
          attributes: {'ajaxType': d.type, 'hubId': d.hubId, 'alarmed': d.alarmed},
          room:       '',
          source:     'gateway',
          battery:    d.battery,
        )).where((d) => d.id != 'ajax-').toList();
        return GatewayImportResult.success(mapped);
      }

      // ── Risco ────────────────────────────────────────────────────────────────
      case GatewayType.risco: {
        final username = _str('username');
        final password = _str('password');
        final localIp  = _str('ip');
        final pin      = _str('pin');
        final client   = RiscoClient(username: username, password: password, pin: pin,
            localIp: localIp.isEmpty ? null : localIp);
        final zones    = await client.getZones();
        final mapped   = zones.map((z) => Device(
          id:         'risco-${z.id}',
          name:       z.name,
          type:       _riscoZoneTypeToDeviceType(z.type),
          status:     DeviceStatus.online,
          attributes: {'riscoType': z.type, 'open': z.open, 'alarmed': z.alarmed, 'bypass': z.bypass},
          room:       '',
          source:     'gateway',
        )).toList();
        return GatewayImportResult.success(mapped);
      }

      // ── PIMA ─────────────────────────────────────────────────────────────────
      case GatewayType.pima: {
        final pimaIp   = _str('ip');
        final pimaPort = int.tryParse(_str('port')) ?? 9999;
        final pimaCode = _str('code');
        final client   = PimaClient(ip: pimaIp, code: pimaCode, port: pimaPort);
        final zones    = await client.getZones();
        final mapped   = zones.map((z) => Device(
          id:         'pima-${z.id}',
          name:       z.name,
          type:       DeviceType.motionSensor, // PIMA zones are generic sensors
          status:     DeviceStatus.online,
          attributes: {'open': z.open, 'alarmed': z.alarmed, 'bypass': z.bypass},
          room:       '',
          source:     'gateway',
        )).toList();
        return GatewayImportResult.success(mapped);
      }

      // ── Z-Wave JS UI ─────────────────────────────────────────────────────────
      case GatewayType.zwave: {
        final zwaveIp   = _str('ip');
        final zwavePort = int.tryParse(_str('port')) ?? 8091;
        final zwaveKey  = _str('apiKey');
        final client    = ZWaveClient(ip: zwaveIp, port: zwavePort, apiKey: zwaveKey.isEmpty ? null : zwaveKey);
        final nodes     = await client.getNodes();
        final mapped    = nodes.map((n) => Device(
          id:         'zwave-${n.nodeId}',
          name:       n.name.isNotEmpty ? n.name : 'Z-Wave Node ${n.nodeId}',
          type:       _zwaveClassToDeviceType(n.deviceClass),
          status:     (n.ready && !n.failed) ? DeviceStatus.online : DeviceStatus.offline,
          isOn:       n.isOn,
          battery:    n.battery,
          attributes: {'nodeId': n.nodeId, 'manufacturer': n.manufacturer, 'productLabel': n.productLabel, 'deviceClass': n.deviceClass},
          room:       '',
          source:     'gateway',
        )).toList();
        return GatewayImportResult.success(mapped);
      }

      // ── IFTTT (no device import — outbound-trigger only) ──────────────────────
      case GatewayType.ifttt:
        return GatewayImportResult.success([]);

      default:
        return const GatewayImportResult.failure('Not supported yet');
    }
  }

  // ── Type mapping helpers ───────────────────────────────────────────────────

  DeviceType _ajaxTypeToDeviceType(String type) {
    final t = type.toLowerCase();
    if (t.contains('motion') || t.contains('pir'))      return DeviceType.motionSensor;
    if (t.contains('door') || t.contains('magnet'))     return DeviceType.doorSensor;
    if (t.contains('smoke') || t.contains('fire'))      return DeviceType.smokeSensor;
    if (t.contains('flood') || t.contains('water'))     return DeviceType.waterLeakSensor;
    if (t.contains('glass'))                            return DeviceType.glassBreakSensor;
    if (t.contains('keypad') || t.contains('panel'))    return DeviceType.alarmPanel;
    if (t.contains('siren') || t.contains('hub'))       return DeviceType.alarmPanel;
    return DeviceType.motionSensor;
  }

  DeviceType _riscoZoneTypeToDeviceType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pir') || t.contains('motion'))  return DeviceType.motionSensor;
    if (t.contains('magnet') || t.contains('door')) return DeviceType.doorSensor;
    if (t.contains('smoke') || t.contains('fire'))  return DeviceType.smokeSensor;
    if (t.contains('flood') || t.contains('water')) return DeviceType.waterLeakSensor;
    if (t.contains('glass'))                        return DeviceType.glassBreakSensor;
    return DeviceType.motionSensor;
  }

  DeviceType _zwaveClassToDeviceType(String deviceClass) {
    final d = deviceClass.toLowerCase();
    if (d.contains('binary switch') || d.contains('on/off')) return DeviceType.smartSwitch;
    if (d.contains('multilevel switch') || d.contains('dimmer')) return DeviceType.smartSwitch;
    if (d.contains('binary sensor')) return DeviceType.motionSensor;
    if (d.contains('motion'))        return DeviceType.motionSensor;
    if (d.contains('door') || d.contains('contact')) return DeviceType.doorSensor;
    if (d.contains('smoke') || d.contains('fire'))   return DeviceType.smokeSensor;
    if (d.contains('flood') || d.contains('water'))  return DeviceType.waterLeakSensor;
    if (d.contains('lock'))                          return DeviceType.smartLock;
    if (d.contains('thermostat') || d.contains('hvac')) return DeviceType.airConditioner;
    if (d.contains('plug') || d.contains('outlet'))  return DeviceType.smartPlug;
    if (d.contains('light') || d.contains('bulb'))   return DeviceType.light;
    if (d.contains('blind') || d.contains('curtain')) return DeviceType.blind;
    return DeviceType.smartPlug;
  }

  // ── Aqara model → DeviceType mapping ──────────────────────────────────────

  DeviceType _aqaraModelToDeviceType(String model) {
    final m = model.toLowerCase();
    if (m.contains('motion') || m.contains('rtcgq') || m.contains('rtczcgq')) {
      return DeviceType.motionSensor;
    }
    if (m.contains('magnet') || m.contains('contact') || m.contains('sensor_door')) {
      return DeviceType.doorSensor;
    }
    if (m.contains('smoke')) return DeviceType.smokeSensor;
    if (m.contains('wleak') || m.contains('water') || m.contains('flood')) {
      return DeviceType.waterLeakSensor;
    }
    if (m.contains('gas') || m.contains('natgas')) return DeviceType.smokeSensor;
    if (m.contains('camera') || m.contains('cam') || m.contains('g3') || m.contains('g2h')) {
      return DeviceType.camera;
    }
    if (m.contains('plug') || m.contains('ctrl_neutral') || m.contains('switch')) {
      return DeviceType.smartPlug;
    }
    if (m.contains('curtain') || m.contains('blinds')) return DeviceType.blind;
    if (m.contains('sensor_ht') || m.contains('weather')) return DeviceType.smartPlug;
    return DeviceType.gateway;
  }

  // ── Register / update a gateway from an external screen ─────────────────
  /// Upsert an HA gateway connection. Called from HaIntegrationScreen after
  /// the user successfully connects, so DeviceCommander and the live service
  /// can find the credentials.
  void upsertHaConnection({
    required String ip,
    required String token,
    required int deviceCount,
  }) {
    final existing = connections
        .where((c) => c.type == GatewayType.homeAssistant)
        .toList();
    for (final c in existing) {
      connections.remove(c);
    }
    connections.add(GatewayConnection(
      id:          _uuid.v4(),
      type:        GatewayType.homeAssistant,
      displayName: 'Home Assistant ($ip)',
      credentials: {'ip': ip, 'token': token},
      isConnected: true,
      deviceCount: deviceCount,
      lastSync:    DateTime.now(),
    ));
    _persist();
    notifyListeners();
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

  // ── Persistence (encrypted — Keychain/EncryptedSharedPreferences) ──────────

  Future<void> _persist() async {
    try {
      final list = connections.map((c) => c.toJson()).toList();
      await SecureCredService.saveGateways(jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('[GatewayManager] persist error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final raw = await SecureCredService.readGateways();
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        try {
          connections.add(
              GatewayConnection.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[GatewayManager] load error: $e');
    }
  }
}
