import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MqttService
//
// General-purpose MQTT client. Wraps mqtt_client with:
//   • connect()               — establish/re-use connection
//   • publish(topic, payload) — QoS 1 fire-and-forget
//   • listen(topic)           — filtered Stream<String> per topic
//   • disconnect()            — clean shutdown
//
// Usage:
//   final mqtt = MqttService(host: '192.168.1.10', port: 1883);
//   await mqtt.connect();
//   await mqtt.publish('home/light/1/set', '{"state":"ON"}');
//   mqtt.listen('home/sensor/#').listen((payload) => print(payload));
// ─────────────────────────────────────────────────────────────────────────────

enum MqttState { disconnected, connecting, connected, error }

class MqttService {
  final String host;
  final int    port;
  final String clientId;
  final String? username;
  final String? password;

  /// How long to wait between automatic reconnect attempts.
  final Duration reconnectDelay;

  MqttService({
    required this.host,
    this.port       = 1883,
    String?  clientId,
    this.username,
    this.password,
    this.reconnectDelay = const Duration(seconds: 5),
  }) : clientId = clientId ?? 'fantatech_${DateTime.now().millisecondsSinceEpoch}';

  // ── Internal state ─────────────────────────────────────────────────────────

  MqttServerClient? _client;
  MqttState _state = MqttState.disconnected;

  final _stateCtrl = StreamController<MqttState>.broadcast();

  /// Emits every time the connection state changes.
  Stream<MqttState> get stateStream => _stateCtrl.stream;
  MqttState get state => _state;
  bool get isConnected => _state == MqttState.connected;

  // Subscribed topics → subscriber count (for reference tracking)
  final Map<String, int> _subscriptions = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Connect to the broker. Safe to call multiple times — no-op if already
  /// connected.
  Future<void> connect() async {
    if (_state == MqttState.connected || _state == MqttState.connecting) return;
    _setState(MqttState.connecting);

    final client = MqttServerClient.withPort(host, clientId, port)
      ..keepAlivePeriod      = 30
      ..connectTimeoutPeriod = 8000
      ..autoReconnect        = true
      ..logging(on: false);

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillQos(MqttQos.atMostOnce)
        .startClean();

    if (username != null && username!.isNotEmpty) {
      connMsg.authenticateAs(username!, password ?? '');
    }

    client.connectionMessage = connMsg;

    client.onConnected    = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onAutoReconnect  = () => _setState(MqttState.connecting);
    client.onAutoReconnected = _onConnected;

    try {
      await client.connect();
    } catch (e) {
      _setState(MqttState.error);
      return;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _setState(MqttState.error);
      return;
    }

    _client = client;
  }

  /// Publish [payload] to [topic] with QoS 1.
  /// Silently no-ops if not connected.
  Future<void> publish(String topic, String payload) async {
    if (!isConnected || _client == null) return;

    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Publish a JSON map to [topic].
  Future<void> publishJson(String topic, Map<String, dynamic> data) =>
      publish(topic, jsonEncode(data));

  /// Subscribe to [topic] and return a broadcast [Stream<String>] of payloads.
  ///
  /// Supports MQTT wildcards: `+` (single level) and `#` (multi-level).
  /// Multiple callers for the same topic share one MQTT subscription.
  Stream<String> listen(String topic) {
    if (_client == null) {
      // Return an empty stream if not yet connected — callers should connect first.
      return const Stream.empty();
    }

    // Subscribe if not already subscribed
    _subscriptions.update(
      topic,
      (count) => count + 1,
      ifAbsent: () {
        _client!.subscribe(topic, MqttQos.atLeastOnce);
        return 1;
      },
    );

    return _client!.updates!
        .expand((messages) => messages)
        .where((msg) => _topicMatches(topic, msg.topic))
        .map((msg) => MqttPublishPayload.bytesToStringAsString(
              (msg.payload as MqttPublishMessage).payload.message,
            ));
  }

  /// Subscribe to [topic] and parse each payload as JSON.
  Stream<Map<String, dynamic>> listenJson(String topic) => listen(topic)
      .where((p) => p.isNotEmpty)
      .map((p) {
        try {
          return jsonDecode(p) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      })
      .where((m) => m.isNotEmpty);

  /// Cleanly disconnect and release resources.
  Future<void> disconnect() async {
    _client?.disconnect();
    _client = null;
    _subscriptions.clear();
    _setState(MqttState.disconnected);
  }

  /// Release stream controllers. Call when the service is no longer needed.
  void dispose() {
    disconnect();
    _stateCtrl.close();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _onConnected() {
    _setState(MqttState.connected);
    // Re-subscribe to all tracked topics after reconnect
    for (final topic in _subscriptions.keys) {
      _client?.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _onDisconnected() {
    if (_state != MqttState.error) _setState(MqttState.disconnected);
  }

  void _setState(MqttState s) {
    if (_state == s) return;
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  // ── MQTT wildcard matching ─────────────────────────────────────────────────

  /// Returns true if [incoming] topic matches the subscribed [filter],
  /// respecting MQTT `+` and `#` wildcards.
  static bool _topicMatches(String filter, String incoming) {
    if (filter == incoming) return true;

    final fParts = filter.split('/');
    final iParts = incoming.split('/');

    for (int i = 0; i < fParts.length; i++) {
      final f = fParts[i];
      if (f == '#') return true;                      // multi-level wildcard
      if (i >= iParts.length) return false;
      if (f != '+' && f != iParts[i]) return false;  // single-level or literal
    }

    return fParts.length == iParts.length;
  }
}
