// ─────────────────────────────────────────────────────────────────────────────
// HaWsService — dedicated WebSocket layer for Home Assistant
//
// Features:
//   • Auth state machine  (disconnected → connecting → authenticating → authenticated)
//   • Auto-incrementing message IDs (thread-safe, starts at 2; 1 is reserved for
//     the mandatory state_changed subscription)
//   • Multi-subscription: subscribe(eventType, handler) / unsubscribe(id)
//   • Pending call map: call(type, params) returns Future<Map> with timeout
//   • 30 s heartbeat ping — server closes idle connections after ~60 s
//   • Callbacks: onStateChange / onEvent / onError / onConnected / onDisconnected
//
// Usage:
//   final ws = HaWsService(config);
//   ws.onStateChange = (entity) { ... };
//   ws.onDisconnected = () { scheduleReconnect(); };
//   final ok = await ws.connect();
//   if (ok) {
//     await ws.callService('light', 'turn_on', entityId: 'light.living_room');
//     final subId = await ws.subscribe('zha_event', (e) { ... });
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ha_config.dart';
import 'ha_entity.dart';
import 'ha_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth state machine
// ─────────────────────────────────────────────────────────────────────────────

enum HaAuthState {
  disconnected,
  connecting,
  authenticating,
  authenticated,
  authFailed,
}

// ─────────────────────────────────────────────────────────────────────────────
// HaWsService
// ─────────────────────────────────────────────────────────────────────────────

class HaWsService {
  final HaConfig config;

  WebSocket?  _ws;
  int         _nextId    = 2;       // 1 is reserved for state_changed
  HaAuthState _authState = HaAuthState.disconnected;

  // Pending call completers  id → Completer<result-map>
  final _pending      = <int, Completer<Map<String, dynamic>>>{};

  // Event subscription handlers  subscriptionId → callback
  final _eventHandlers = <int, void Function(Map<String, dynamic>)>{};

  // Completer resolved once auth_ok / auth_invalid arrives
  Completer<bool>? _authCompleter;

  Timer? _heartbeat;

  // ── Public callbacks ──────────────────────────────────────────────────────

  /// Called whenever a state_changed event arrives with the updated entity.
  void Function(HaEntity entity)?               onStateChange;

  /// Called for every raw HA event (any subscription).
  void Function(Map<String, dynamic> event)?    onEvent;

  /// Called with a human-readable message when an error occurs.
  void Function(String error)?                  onError;

  /// Called once authentication completes successfully.
  void Function()?                              onConnected;

  /// Called when the WebSocket closes (including on error / server restart).
  void Function()?                              onDisconnected;

  /// Called when HA rejects the token (auth_invalid). The caller should
  /// NOT schedule a reconnect — a bad token won't become valid on its own.
  void Function()?                              onAuthFailed;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool         get isAuthenticated => _authState == HaAuthState.authenticated;
  bool         get isOpen          => _ws != null &&
                                      _ws!.readyState == WebSocket.open;
  HaAuthState  get authState       => _authState;

  HaWsService(this.config);

  // ── Connect ───────────────────────────────────────────────────────────────

  /// Opens the WebSocket, completes the HA auth handshake, subscribes to
  /// `state_changed`, and starts the heartbeat.
  /// Returns `true` on success, `false` if auth fails or times out.
  Future<bool> connect() async {
    if (_authState == HaAuthState.authenticated && isOpen) return true;

    _authState = HaAuthState.connecting;
    HaLogger.i('HaWsService', 'Connecting → ${config.wsUrl}/api/websocket');

    try {
      _ws = await WebSocket.connect(
        '${config.wsUrl}/api/websocket',
      ).timeout(config.timeout);
    } catch (e) {
      _authState = HaAuthState.disconnected;
      final msg = 'WS connect failed: $e';
      HaLogger.e('HaWsService', msg);
      onError?.call(msg);
      return false;
    }

    _authState      = HaAuthState.authenticating;
    _authCompleter  = Completer<bool>();
    HaLogger.d('HaWsService', 'Socket open — waiting for auth_required');

    _ws!.listen(
      _onMessage,
      onError: (dynamic e) {
        final msg = 'WS stream error: $e';
        HaLogger.e('HaWsService', msg);
        onError?.call(msg);
        _handleClose();
      },
      onDone:        _handleClose,
      cancelOnError: false,
    );

    final ok = await _authCompleter!.future.timeout(
      config.timeout,
      onTimeout: () {
        HaLogger.e('HaWsService', 'Auth handshake timed out after ${config.timeout.inSeconds}s');
        return false;
      },
    );

    if (!ok) {
      await _ws?.close();
      _ws        = null;
      if (_authState != HaAuthState.authFailed) {
        _authState = HaAuthState.disconnected;
      }
      return false;
    }

    // Subscribe to state_changed with the reserved ID = 1
    _sendRaw({
      'id':         1,
      'type':       'subscribe_events',
      'event_type': 'state_changed',
    });

    HaLogger.i('HaWsService',
        'Authenticated — subscribed to state_changed (id=1)');
    _startHeartbeat();
    onConnected?.call();
    return true;
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _stopHeartbeat();
    _authState = HaAuthState.disconnected;

    _failPending('disconnected');
    _eventHandlers.clear();

    final ws = _ws;
    _ws = null;
    try { await ws?.close(); } catch (_) {}
  }

  // ── Generic call ──────────────────────────────────────────────────────────

  /// Sends a WS message and awaits the `result` response.
  /// Returns `null` on timeout or if not connected.
  Future<Map<String, dynamic>?> call(
    String type, {
    Map<String, dynamic> params = const {},
  }) async {
    if (!isAuthenticated) return null;

    final id        = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id]    = completer;

    _sendRaw({'id': id, 'type': type, ...params});

    try {
      return await completer.future.timeout(config.timeout);
    } on TimeoutException {
      _pending.remove(id);
      return null;
    }
  }

  // ── Event subscriptions ───────────────────────────────────────────────────

  /// Subscribes to [eventType] and calls [handler] for every matching event.
  /// Returns the subscription ID (pass to [unsubscribe] to cancel).
  Future<int?> subscribe(
    String eventType,
    void Function(Map<String, dynamic> event) handler,
  ) async {
    if (!isAuthenticated) return null;

    final id = _nextId++;
    _eventHandlers[id] = handler;

    _sendRaw({
      'id':         id,
      'type':       'subscribe_events',
      'event_type': eventType,
    });

    return id;
  }

  /// Cancels a subscription created with [subscribe].
  Future<bool> unsubscribe(int subscriptionId) async {
    _eventHandlers.remove(subscriptionId);
    final result = await call(
      'unsubscribe_events',
      params: {'subscription': subscriptionId},
    );
    return result != null && result['success'] == true;
  }

  // ── Service calls via WebSocket ───────────────────────────────────────────

  /// Calls a HA service over WebSocket (lower latency than REST for fire-and-forget).
  Future<bool> callService(
    String domain,
    String service, {
    String?                entityId,
    Map<String, dynamic>   serviceData = const {},
  }) async {
    final data = <String, dynamic>{...serviceData};
    if (entityId != null) data['entity_id'] = entityId;

    final result = await call('call_service', params: {
      'domain':       domain,
      'service':      service,
      'service_data': data,
    });

    return result != null && result['success'] == true;
  }

  // ── Fetch all states via WebSocket ────────────────────────────────────────

  /// Returns current state of every entity.
  /// Faster than `GET /api/states` on large installs (single WS frame).
  Future<List<HaEntity>?> fetchStates() async {
    final result = await call('get_states');
    if (result == null) return null;

    final items = result['result'] as List?;
    if (items == null) return null;

    final entities = <HaEntity>[];
    for (final item in items) {
      try {
        entities.add(HaEntity.fromJson(item as Map<String, dynamic>));
      } catch (_) {}
    }
    return entities;
  }

  // ── Message handler ───────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    final msg = _decode(raw);
    if (msg == null) return;

    final type = msg['type'] as String? ?? '';

    switch (type) {
      // ── Auth handshake ────────────────────────────────────────────────────
      case 'auth_required':
        HaLogger.d('HaWsService', 'auth_required received — sending token');
        _sendRaw({'type': 'auth', 'access_token': config.token});
        break;

      case 'auth_ok':
        _authState = HaAuthState.authenticated;
        HaLogger.i('HaWsService', 'auth_ok — connection authenticated');
        if (_authCompleter?.isCompleted == false) {
          _authCompleter!.complete(true);
        }
        break;

      case 'auth_invalid':
        _authState = HaAuthState.authFailed;
        const msg = 'auth_invalid — token rejected by HA; generate a new Long-Lived Access Token';
        HaLogger.e('HaWsService', msg);
        onError?.call('HA token rejected — generate a new Long-Lived Access Token');
        onAuthFailed?.call();
        if (_authCompleter?.isCompleted == false) {
          _authCompleter!.complete(false);
        }
        break;

      // ── Pending call results ──────────────────────────────────────────────
      case 'result':
        final id = msg['id'] as int?;
        if (id != null) {
          final c = _pending.remove(id);
          if (c != null && !c.isCompleted) c.complete(msg);
        }
        break;

      // ── Events ────────────────────────────────────────────────────────────
      case 'event':
        final id    = msg['id']    as int?;
        final event = msg['event'] as Map<String, dynamic>?;
        if (event == null) break;

        if (id == 1) {
          // state_changed — parse and forward
          final data     = event['data']      as Map?;
          final newState = data?['new_state'] as Map?;
          if (newState != null) {
            try {
              onStateChange?.call(
                HaEntity.fromJson(newState.cast<String, dynamic>()),
              );
            } catch (err) {
              HaLogger.w('HaWsService',
                  'Failed to parse state_changed entity: $err');
            }
          }
        }

        // Dispatch to named subscription handler
        if (id != null) {
          _eventHandlers[id]?.call(event);
        }

        // Broadcast to generic listener
        onEvent?.call(event);
        break;

      // ── Heartbeat ─────────────────────────────────────────────────────────
      case 'pong':
        break; // acknowledged — nothing to do

      default:
        break;
    }
  }

  // ── Connection close ──────────────────────────────────────────────────────

  void _handleClose() {
    _stopHeartbeat();
    _ws = null;
    _failPending('connection closed');

    if (_authState != HaAuthState.disconnected &&
        _authState != HaAuthState.authFailed) {
      HaLogger.w('HaWsService', 'WebSocket closed — triggering reconnect');
      _authState = HaAuthState.disconnected;
      onDisconnected?.call();
    }
  }

  // ── Heartbeat ─────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isOpen) {
        _sendRaw({'id': _nextId++, 'type': 'ping'});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _sendRaw(Map<String, dynamic> msg) {
    try { _ws?.add(jsonEncode(msg)); } catch (_) {}
  }

  void _failPending(String reason) {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(reason);
    }
    _pending.clear();
  }

  static Map<String, dynamic>? _decode(dynamic raw) {
    try { return jsonDecode(raw as String) as Map<String, dynamic>; }
    catch (_) { return null; }
  }
}
