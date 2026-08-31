// ─────────────────────────────────────────────────────────────────────────────
// IRobotClient  —  iRobot (Roomba / Braava) local MQTT protocol
//
// iRobot's newer WiFi-connected robots (Roomba 9xx/i-series/s-series/j-series,
// Braava jet m6…) run a local MQTT broker on the robot itself — no cloud
// round-trip is required once you have the credentials.
//
// Protocol:
//   • Broker runs on the robot at port 8883 (MQTTS — TLS with a self-signed
//     certificate, so certificate verification must be disabled).
//   • Username = BLID (the robot's unique local identifier).
//   • Password = "Local Password" (a per-robot secret, NOT the iRobot
//     account password).
//   • State is published continuously as a large retained JSON blob;
//     subscribing to the wildcard topic "#" is the simplest way to receive it.
//   • Commands are published as JSON to topic "cmd", e.g.
//       {"command":"start","time":<unix seconds>,"initiator":"localApp"}
//
// Obtaining BLID + Local Password (one-time, done by the user):
//   Hold the robot's Home/Clean button for ~2 seconds until it beeps and the
//   Wi-Fi LED flashes — the robot then broadcasts its credentials for ~30s on
//   its local network, which community tools (e.g. "Get Robot Password" /
//   dorita980's getPassword) can capture. FantaTech does not perform this
//   capture itself; the user supplies BLID + password once.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class IRobotStatus {
  final int?    batteryPct;
  final String? phase;        // e.g. "run", "charge", "stop", "hmUsrDock"
  final bool?   binFull;
  final String? cleanMissionStatus;

  const IRobotStatus({
    this.batteryPct,
    this.phase,
    this.binFull,
    this.cleanMissionStatus,
  });
}

class IRobotClient {
  final String _ip;
  final String _blid;
  final String _password;

  static const _timeout = Duration(seconds: 8);

  IRobotClient({
    required String ip,
    required String blid,
    required String password,
  })  : _ip = ip,
        _blid = blid,
        _password = password;

  MqttServerClient _buildClient(String clientId) {
    final client = MqttServerClient.withPort(_ip, clientId, 8883)
      ..secure = true
      ..securityContext = SecurityContext.defaultContext
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 8000
      ..logging(on: false);
    // Robot uses a self-signed certificate — accept it explicitly.
    client.onBadCertificate = (X509Certificate cert) => true;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(_blid, _password)
        .startClean();

    return client;
  }

  /// Verify the robot is reachable and credentials are accepted.
  Future<bool> testConnection() async {
    final client = _buildClient('fantatech_test');
    try {
      await client.connect().timeout(_timeout);
      final ok = client.connectionStatus?.state == MqttConnectionState.connected;
      client.disconnect();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Connect, listen briefly for a retained state message, and return a
  /// best-effort parsed [IRobotStatus] (or null if nothing arrived in time).
  Future<IRobotStatus?> getStatus() async {
    final client = _buildClient('fantatech_status');
    try {
      await client.connect().timeout(_timeout);
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return null;
      }

      client.subscribe('#', MqttQos.atMostOnce);

      final completer = Completer<IRobotStatus?>();
      final sub = client.updates?.listen((messages) {
        for (final msg in messages) {
          final payload = MqttPublishPayload.bytesToStringAsString(
              (msg.payload as MqttPublishMessage).payload.message);
          final status = _parseStatePayload(payload);
          if (status != null && !completer.isCompleted) {
            completer.complete(status);
          }
        }
      });

      final result = await completer.future
          .timeout(_timeout, onTimeout: () => null);
      await sub?.cancel();
      client.disconnect();
      return result;
    } catch (_) {
      client.disconnect();
      return null;
    }
  }

  IRobotStatus? _parseStatePayload(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;
      final state = json['state'] as Map<String, dynamic>?;
      final reported = state?['reported'] as Map<String, dynamic>? ?? json;

      final batPct = reported['batPct'] as int?;
      final bin = reported['bin'] as Map<String, dynamic>?;
      final cleanMission =
          reported['cleanMissionStatus'] as Map<String, dynamic>?;
      final phase = cleanMission?['phase'] as String?;

      if (batPct == null && phase == null) return null;

      return IRobotStatus(
        batteryPct: batPct,
        phase: phase,
        binFull: bin?['full'] as bool?,
        cleanMissionStatus: cleanMission?['cycle'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Send a command: "start", "stop", "pause", "resume", or "dock".
  Future<bool> sendCommand(String command) async {
    final client = _buildClient('fantatech_cmd');
    try {
      await client.connect().timeout(_timeout);
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return false;
      }

      final payload = jsonEncode({
        'command': command,
        'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'initiator': 'localApp',
      });

      final builder = MqttClientPayloadBuilder()..addString(payload);
      client.publishMessage('cmd', MqttQos.atLeastOnce, builder.payload!);

      // Give the broker a moment to accept the publish before disconnecting.
      await Future.delayed(const Duration(milliseconds: 400));
      client.disconnect();
      return true;
    } catch (_) {
      client.disconnect();
      return false;
    }
  }

  Future<bool> start()  => sendCommand('start');
  Future<bool> stop()   => sendCommand('stop');
  Future<bool> pause()  => sendCommand('pause');
  Future<bool> resume() => sendCommand('resume');
  Future<bool> dock()   => sendCommand('dock');
}
