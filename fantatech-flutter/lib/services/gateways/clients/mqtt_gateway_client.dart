// ─────────────────────────────────────────────────────────────────────────────
// MQTTGatewayClient
//
// Discovers smart home devices via Home Assistant MQTT Auto-Discovery:
//   subscribe to  [prefix]/+/+/config   (e.g. homeassistant/light/desk/config)
//   Each retained config message describes one entity.
//
// Topic format:  {prefix}/{domain}/{node_id}/config
// Payload:       {"name":"…","device":{…},"state_topic":"…",…}
//
// Supported domains: light, switch, sensor, binary_sensor, climate,
//                    cover, camera, lock, fan
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../../models/device.dart';
import '../gateway_model.dart';

class MQTTGatewayClient {
  // ── Connect + discover ─────────────────────────────────────────────────────

  static Future<GatewayImportResult> discoverDevices({
    required String host,
    required int    port,
    String?         username,
    String?         password,
    String          prefix = 'homeassistant',
    Duration        listenFor = const Duration(seconds: 12),
  }) async {
    final client = MqttServerClient.withPort(host, 'fantatech_discovery', port)
      ..keepAlivePeriod = 20
      ..connectTimeoutPeriod = 8000
      ..logging(on: false);

    if (username != null && username.isNotEmpty) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier('fantatech_discovery')
          .authenticateAs(username, password ?? '')
          .startClean();
    } else {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier('fantatech_discovery')
          .startClean();
    }

    try {
      await client.connect();
    } catch (e) {
      return GatewayImportResult.failure('MQTT connection error: $e');
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      return const GatewayImportResult.failure('Cannot connect to broker');
    }

    // Subscribe to discovery topic
    client.subscribe('$prefix/+/+/config', MqttQos.atMostOnce);

    final seen    = <String>{};
    final devices = <Device>[];
    final done    = Completer<void>();

    Timer(listenFor, () {
      if (!done.isCompleted) done.complete();
    });

    client.updates?.listen((messages) {
      for (final msg in messages) {
        final topic   = msg.topic;
        final payload = MqttPublishPayload.bytesToStringAsString(
            (msg.payload as MqttPublishMessage).payload.message);

        if (seen.contains(topic)) continue;
        seen.add(topic);

        final device = _parseDiscoveryMessage(topic, payload, prefix);
        if (device != null) devices.add(device);
      }
    });

    await done.future;
    client.disconnect();

    return GatewayImportResult.success(devices);
  }

  // ── Parse a discovery message ──────────────────────────────────────────────

  static Device? _parseDiscoveryMessage(
      String topic, String payload, String prefix) {
    try {
      final parts  = topic.split('/');
      if (parts.length < 3) return null;
      final domain = parts[1];
      final nodeId = parts[2];

      final Map<String, dynamic> cfg;
      try {
        cfg = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }

      final name = cfg['name'] as String?
          ?? cfg['friendly_name'] as String?
          ?? nodeId;
      final uniqueId = cfg['unique_id'] as String? ?? nodeId;
      final devInfo  = (cfg['device'] as Map?)?.cast<String, dynamic>() ?? {};
      final mfr      = devInfo['manufacturer'] as String? ?? '';
      final model    = devInfo['model'] as String? ?? '';

      final type = _domainToType(domain, cfg);
      if (type == null) return null;

      return Device(
        id:         'mqtt_$uniqueId',
        name:       name,
        type:       type,
        isOn:       false,
        status:     DeviceStatus.online,
        source:     'gateway',
        attributes: {
          'protocol':     'mqtt',
          'manufacturer': mfr,
          'model':        model,
          'stateTopic':   cfg['state_topic'] as String? ?? '',
          'cmdTopic':     cfg['command_topic'] as String? ?? '',
        },
      );
    } catch (_) {
      return null;
    }
  }

  // ── Domain → DeviceType ────────────────────────────────────────────────────

  static DeviceType? _domainToType(
      String domain, Map<String, dynamic> cfg) {
    final dc = (cfg['device_class'] as String? ?? '').toLowerCase();
    switch (domain) {
      case 'light':          return DeviceType.light;
      case 'switch':         return DeviceType.smartSwitch;
      case 'cover':          return DeviceType.blind;
      case 'fan':            return DeviceType.airConditioner;
      case 'climate':        return DeviceType.airConditioner;
      case 'camera':         return DeviceType.camera;
      case 'lock':           return DeviceType.doorSensor;
      case 'binary_sensor':
        if (dc == 'motion' || dc == 'occupancy') return DeviceType.motionSensor;
        if (dc == 'door')                         return DeviceType.doorSensor;
        if (dc == 'window' || dc == 'opening')    return DeviceType.windowSensor;
        if (dc == 'smoke'  || dc == 'gas')        return DeviceType.smokeSensor;
        return null;
      case 'sensor':
        if (dc == 'energy' || dc == 'power')      return DeviceType.energyMeter;
        if (dc == 'smoke')                        return DeviceType.smokeSensor;
        return null;
      default:
        return null;
    }
  }

  // ── Simple connectivity test ───────────────────────────────────────────────

  static Future<bool> testConnection({
    required String host,
    required int    port,
    String?         username,
    String?         password,
  }) async {
    final client = MqttServerClient.withPort(host, 'fantatech_test', port)
      ..keepAlivePeriod      = 10
      ..connectTimeoutPeriod = 5000
      ..logging(on: false);

    if (username != null && username.isNotEmpty) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier('fantatech_test')
          .authenticateAs(username, password ?? '')
          .startClean();
    }

    try {
      await client.connect();
      final ok = client.connectionStatus?.state
                     == MqttConnectionState.connected;
      client.disconnect();
      return ok;
    } catch (_) {
      return false;
    }
  }
}
