// ─────────────────────────────────────────────────────────────────────────────
// HaLiveService
//
// Maintains a persistent WebSocket connection to Home Assistant and pushes
// real-time state changes into AppState.
//
// Usage (in AppState):
//   _haLive.start(ip: '192.168.1.10', token: '...', appState: this);
//   _haLive.stop();   // on logout / gateway disconnect
//
// Auto-reconnect: if the connection drops, it retries after 10 seconds.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../gateways/clients/ha_gateway_client.dart';

class HaLiveService {
  // ── Public state ───────────────────────────────────────────────────────────
  bool get isConnected => _conn?.isOpen == true;

  // ── Private ────────────────────────────────────────────────────────────────
  HaLiveConnection? _conn;
  Timer?            _retryTimer;
  String?           _ip;
  String?           _token;
  void Function(String entityId, String state, Map<String, dynamic> attributes)? _onUpdate;
  bool              _stopped = false;

  // ── Start / stop ───────────────────────────────────────────────────────────

  /// Start listening. [onUpdate] is called on every state change.
  Future<void> start({
    required String ip,
    required String token,
    required void Function(
      String entityId,
      String state,
      Map<String, dynamic> attributes,
    ) onUpdate,
  }) async {
    _ip        = ip;
    _token     = token;
    _onUpdate  = onUpdate;
    _stopped   = false;
    await _connect();
  }

  /// Stop listening and close the connection.
  void stop() {
    _stopped = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _conn?.close();
    _conn = null;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    if (_stopped || _ip == null || _token == null) return;

    _conn = await HaGatewayClient.connectLive(
      ip:    _ip!,
      token: _token!,
      onStateChange: (entityId, newState) {
        if (_stopped) return;
        final state = newState['state'] as String? ?? '';
        final attrs = (newState['attributes'] as Map?)
                ?.cast<String, dynamic>() ?? {};
        _onUpdate?.call(entityId, state, attrs);
      },
      onError: (err) {
        if (kDebugMode) debugPrint('[HaLive] $err');
      },
      onDisconnected: () {
        if (_stopped) return;
        if (kDebugMode) debugPrint('[HaLive] disconnected — retry in 10s');
        _scheduleRetry();
      },
    );

    if (_conn == null) {
      if (kDebugMode) debugPrint('[HaLive] connect failed — retry in 10s');
      _scheduleRetry();
    } else {
      if (kDebugMode) debugPrint('[HaLive] connected');
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_stopped) return;
    _retryTimer = Timer(const Duration(seconds: 10), () {
      if (!_stopped) _connect();
    });
  }
}
