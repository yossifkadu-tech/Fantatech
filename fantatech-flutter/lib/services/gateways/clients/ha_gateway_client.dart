// ─────────────────────────────────────────────────────────────────────────────
// HaGatewayClient
//
// Home Assistant REST API control + WebSocket real-time state listener.
//
// REST control  →  POST http://<ip>:8123/api/services/<domain>/<service>
//                  Authorization: Bearer <token>
//                  Body: {"entity_id": "light.salon", ...extra attrs}
//
// WebSocket     →  ws://<ip>:8123/api/websocket
//   Flow:
//     server → {"type":"auth_required"}
//     client → {"type":"auth","access_token":"..."}
//     server → {"type":"auth_ok"}
//     client → {"id":1,"type":"subscribe_events","event_type":"state_changed"}
//     server → events: {"id":1,"type":"event","event":{...}}
//
// The live listener pushes state changes via [onStateChange] callback so
// AppState can update devices without polling.
//
// TODO(remote-access): every method here hardcodes http:// and port 8123 —
// LAN-only by design. See the TODO in lib/services/ha/ha_config.dart for the
// planned scope of a future remote-access (Nabu Casa / VPN) pass.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class HaGatewayClient {
  static const _port    = 8123;
  static const _timeout = Duration(seconds: 8);

  // ── REST: control helpers ──────────────────────────────────────────────────

  /// Turn any HA entity on. Handles light / switch / input_boolean / cover.
  static Future<bool> setOnOff(
    String ip,
    String token,
    String entityId,
    bool on,
  ) async {
    final domain  = _domain(entityId);
    final service = _onOffService(domain, on);
    return callService(ip, token, domain, service, entityId);
  }

  /// Set light brightness 0–100.
  static Future<bool> setBrightness(
    String ip,
    String token,
    String entityId,
    int pct,
  ) async {
    return callService(ip, token, 'light', 'turn_on', entityId,
        extra: {'brightness_pct': pct.clamp(1, 100)});
  }

  /// Set light color temperature in Kelvin (e.g. 2700–6500).
  static Future<bool> setColorTemp(
    String ip,
    String token,
    String entityId,
    int kelvin,
  ) async {
    return callService(ip, token, 'light', 'turn_on', entityId,
        extra: {'color_temp_kelvin': kelvin});
  }

  /// Commission a Matter device via the HA Matter integration.
  /// [code] is the QR string ("MT:…") or 11-digit manual pairing code.
  static Future<bool> commissionMatter(
    String ip,
    String token,
    String code, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final body = jsonEncode({'code': code});
      final result = await _post(ip, '/api/services/matter/commission_with_code', token, body)
          .timeout(timeout);
      return result != null;
    } catch (_) {
      return false;
    }
  }

  /// Removes a device (Matter or otherwise) from HA's device registry —
  /// the same action HA's own UI performs for "Delete device". For a Matter
  /// device this is what actually decommissions it from the fabric; simply
  /// deleting it from the app's local list (AppState.removeDevice) does not,
  /// since the next HA sync would just re-add it.
  ///
  /// Returns false if [entityId] isn't in HA's registry, or if any of the
  /// device's config entries fail to remove.
  static Future<bool> removeDeviceByEntity(
    String ip,
    String token,
    String entityId,
  ) async {
    final entry = await _wsCommand(ip, token, {
      'type': 'config/entity_registry/get',
      'entity_id': entityId,
    });
    final deviceId = entry is Map ? entry['device_id'] as String? : null;
    if (deviceId == null) return false;

    final devices = await _wsCommand(ip, token, {
      'type': 'config/device_registry/list',
    });
    if (devices is! List) return false;
    final device = devices.cast<Map>().firstWhere(
          (d) => d['id'] == deviceId,
          orElse: () => const {},
        );
    final entries =
        (device['config_entries'] as List?)?.cast<String>() ?? const [];
    if (entries.isEmpty) return false;

    var allOk = true;
    for (final configEntryId in entries) {
      final result = await _wsCommand(ip, token, {
        'type': 'config/device_registry/remove_config_entry',
        'device_id': deviceId,
        'config_entry_id': configEntryId,
      });
      if (result == null) allOk = false;
    }
    return allOk;
  }

  /// Sends one authenticated WebSocket command over a short-lived connection
  /// and returns its "result" payload, or null on failure/timeout. Meant for
  /// occasional admin calls (registry lookups/removal) — for continuous
  /// updates use [connectLive] instead.
  static Future<dynamic> _wsCommand(
    String ip,
    String token,
    Map<String, dynamic> command, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    WebSocket? ws;
    StreamSubscription? sub;
    try {
      ws = await WebSocket.connect('ws://$ip:$_port/api/websocket').timeout(_timeout);
      final completer = Completer<dynamic>();
      const cmdId = 9001;

      sub = ws.listen(
        (raw) {
          final msg = _decode(raw);
          if (msg == null) return;
          switch (msg['type'] as String? ?? '') {
            case 'auth_required':
              ws!.add(jsonEncode({'type': 'auth', 'access_token': token}));
              break;
            case 'auth_ok':
              ws!.add(jsonEncode({...command, 'id': cmdId}));
              break;
            case 'auth_invalid':
              if (!completer.isCompleted) completer.complete(null);
              break;
            case 'result':
              if (msg['id'] == cmdId && !completer.isCompleted) {
                completer.complete(msg['success'] == true ? msg['result'] : null);
              }
              break;
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
        cancelOnError: false,
      );

      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      await sub?.cancel();
      ws?.close();
    }
  }

  // ── Climate (HVAC) ─────────────────────────────────────────────────────────

  /// Set the HVAC operating mode (cool / heat / dry / fan_only / auto / off).
  static Future<bool> setHvacMode(
          String ip, String token, String entityId, String mode) =>
      callService(ip, token, 'climate', 'set_hvac_mode', entityId,
          extra: {'hvac_mode': mode});

  /// Set the target temperature in °C.
  static Future<bool> setClimateTemperature(
          String ip, String token, String entityId, double temperature) =>
      callService(ip, token, 'climate', 'set_temperature', entityId,
          extra: {'temperature': temperature});

  /// Set the fan speed mode (e.g. low / medium / high / auto).
  static Future<bool> setFanMode(
          String ip, String token, String entityId, String fanMode) =>
      callService(ip, token, 'climate', 'set_fan_mode', entityId,
          extra: {'fan_mode': fanMode});

  /// Set the swing mode (e.g. off / vertical / horizontal / both).
  static Future<bool> setSwingMode(
          String ip, String token, String entityId, String swingMode) =>
      callService(ip, token, 'climate', 'set_swing_mode', entityId,
          extra: {'swing_mode': swingMode});

  /// Set a preset mode (e.g. eco / sleep / boost) where supported.
  static Future<bool> setPresetMode(
          String ip, String token, String entityId, String presetMode) =>
      callService(ip, token, 'climate', 'set_preset_mode', entityId,
          extra: {'preset_mode': presetMode});

  /// Set blind / cover position 0–100 (0 = closed, 100 = open in HA).
  static Future<bool> setCoverPosition(
    String ip,
    String token,
    String entityId,
    int position,
  ) async {
    return callService(
        ip, token, 'cover', 'set_cover_position', entityId,
        extra: {'position': position.clamp(0, 100)});
  }

  /// Set a valve's position 0–100 (0 = closed, 100 = open) — smart water/gas
  /// valves and faucets. Distinct from [setCoverPosition]: HA exposes valves
  /// under their own `valve.*` services, not `cover.*`.
  static Future<bool> setValvePosition(
    String ip,
    String token,
    String entityId,
    int position,
  ) async {
    return callService(
        ip, token, 'valve', 'set_valve_position', entityId,
        extra: {'position': position.clamp(0, 100)});
  }

  /// Stop a moving valve mid-travel.
  static Future<bool> stopValve(String ip, String token, String entityId) =>
      callService(ip, token, 'valve', 'stop_valve', entityId);

  /// Generic service call.
  /// [extra] is merged into the request body alongside entity_id.
  static Future<bool> callService(
    String ip,
    String token,
    String domain,
    String service,
    String entityId, {
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final body = jsonEncode({'entity_id': entityId, ...extra});
      final result = await _post(
        ip,
        '/api/services/$domain/$service',
        token,
        body,
      );
      return result != null;
    } catch (_) {
      return false;
    }
  }

  /// Read the current state of a single entity.
  /// Returns the state string (e.g. "on", "off", "23.5") or null on failure.
  static Future<Map<String, dynamic>?> getState(
    String ip,
    String token,
    String entityId,
  ) async {
    try {
      final raw = await _get(ip, '/api/states/$entityId', token);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── WebSocket: real-time state listener ────────────────────────────────────

  /// Connect to HA WebSocket and listen for state_changed events.
  ///
  /// [onStateChange] is called for every entity state update:
  ///   entityId → {'state': 'on', 'attributes': {...}}
  ///
  /// Returns a [HaLiveConnection] that can be closed with [HaLiveConnection.close].
  static Future<HaLiveConnection?> connectLive({
    required String ip,
    required String token,
    required void Function(String entityId, Map<String, dynamic> newState) onStateChange,
    void Function(String error)? onError,
    void Function()? onDisconnected,
  }) async {
    try {
      final wsUrl = 'ws://$ip:$_port/api/websocket';
      final ws = await WebSocket.connect(wsUrl)
          .timeout(_timeout);

      final conn = HaLiveConnection._(ws, onDisconnected);

      // ── Auth + subscribe handshake ─────────────────────────────────────────
      final authCompleter = Completer<bool>();

      ws.listen(
        (raw) {
          final msg = _decode(raw);
          if (msg == null) return;
          final type = msg['type'] as String? ?? '';

          switch (type) {
            case 'auth_required':
              ws.add(jsonEncode({'type': 'auth', 'access_token': token}));
              break;

            case 'auth_ok':
              // Subscribe to ALL state_changed events
              ws.add(jsonEncode({
                'id':         1,
                'type':       'subscribe_events',
                'event_type': 'state_changed',
              }));
              if (!authCompleter.isCompleted) authCompleter.complete(true);
              break;

            case 'auth_invalid':
              if (!authCompleter.isCompleted) authCompleter.complete(false);
              onError?.call('HA WebSocket: invalid token');
              break;

            case 'event':
              // Only process our subscription (id=1)
              final event = msg['event'] as Map?;
              final data  = event?['data'] as Map?;
              if (data == null) break;
              final entityId = data['entity_id'] as String?;
              final newState = data['new_state'] as Map?;
              if (entityId != null && newState != null) {
                onStateChange(
                  entityId,
                  newState.cast<String, dynamic>(),
                );
              }
              break;
          }
        },
        onError: (e) {
          onError?.call('HA WebSocket error: $e');
          onDisconnected?.call();
        },
        onDone: () {
          onDisconnected?.call();
        },
        cancelOnError: false,
      );

      final authed = await authCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );

      if (!authed) {
        ws.close();
        onError?.call('HA WebSocket: authentication failed');
        return null;
      }

      return conn;
    } on SocketException catch (e) {
      onError?.call('Cannot connect to HA WebSocket: ${e.message}');
      return null;
    } on TimeoutException {
      onError?.call('HA WebSocket: timeout');
      return null;
    } catch (e) {
      onError?.call('HA WebSocket error: $e');
      return null;
    }
  }

  // ── Bulk fetch ─────────────────────────────────────────────────────────────

  /// Fetch all entity states from /api/states.
  /// Returns a list of state objects or empty list on failure.
  static Future<List<Map<String, dynamic>>> fetchAllStates(
    String ip,
    String token,
  ) async {
    try {
      final raw = await _get(ip, '/api/states', token);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch HA's Area registry.
  /// Returns a list of area objects [{area_id, name, icon?}] or empty list.
  ///
  /// `config/area_registry/list` is a WebSocket-only admin command — HA does
  /// not expose it over REST. An earlier version of this method called it via
  /// `_get()` against a REST path that doesn't exist, so it silently always
  /// returned [] (caught by the try/catch) and no area ever imported.
  static Future<List<Map<String, dynamic>>> fetchAreas(
    String ip,
    String token,
  ) async {
    final result =
        await _wsCommand(ip, token, {'type': 'config/area_registry/list'});
    if (result is! List) return [];
    return result.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  /// Fetches, per entity_id, the registry info needed to import it sensibly:
  /// its area (for room assignment) and whether it's a diagnostic/config/
  /// disabled entity that should be excluded from import entirely.
  ///
  /// `/api/states` (used by [fetchAllStates]) never includes `area_id` or
  /// `entity_category` in an entity's `attributes` — neither is part of that
  /// endpoint's payload. Both live only in the entity/device registry.
  ///
  /// Area resolves through the device registry when set on the device rather
  /// than the entity directly (the common case — HA shows an entity as
  /// "inheriting" its device's area unless overridden per-entity).
  ///
  /// `entity_category` of "diagnostic" or "config" marks HA's own internal
  /// bookkeeping entities (e.g. "Backup: Last successful backup", "Sun: Next
  /// dawn", a device's WiFi signal/uptime sensor) — these are not physical
  /// smart-home devices and were previously imported alongside real ones,
  /// showing up as inert toggles that do nothing.
  static Future<Map<String, HaEntityRegistryInfo>> fetchEntityRegistryInfo(
    String ip,
    String token,
  ) async {
    final entities =
        await _wsCommand(ip, token, {'type': 'config/entity_registry/list'});
    final devices =
        await _wsCommand(ip, token, {'type': 'config/device_registry/list'});
    if (entities is! List) return {};

    final deviceArea = <String, String>{};
    if (devices is List) {
      for (final d in devices.whereType<Map>()) {
        final id   = d['id']      as String?;
        final area = d['area_id'] as String?;
        if (id != null && area != null) deviceArea[id] = area;
      }
    }

    final result = <String, HaEntityRegistryInfo>{};
    for (final e in entities.whereType<Map>()) {
      final entityId = e['entity_id'] as String?;
      if (entityId == null) continue;
      final directArea = e['area_id']   as String?;
      final deviceId   = e['device_id'] as String?;
      final area = directArea ?? (deviceId != null ? deviceArea[deviceId] : null);
      result[entityId] = HaEntityRegistryInfo(
        areaId:         area,
        entityCategory: e['entity_category'] as String?,
        disabledBy:     e['disabled_by'] as String?,
      );
    }
    return result;
  }

  /// Ping the HA REST API — returns true if reachable and token is valid.
  static Future<bool> ping(String ip, String token) async {
    try {
      final raw = await _get(ip, '/api/', token);
      return raw != null && raw.contains('message');
    } catch (_) {
      return false;
    }
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type':  'application/json',
      };

  static Future<String?> _get(String ip, String path, String token) async {
    try {
      final uri = Uri.parse('http://$ip:$_port$path');
      final res = await http.get(uri, headers: _headers(token))
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300 ? res.body : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _post(
      String ip, String path, String token, String body) async {
    try {
      final uri = Uri.parse('http://$ip:$_port$path');
      final res = await http.post(uri, headers: _headers(token), body: body)
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300 ? res.body : null;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _domain(String entityId) => entityId.split('.').first;

  static String _onOffService(String domain, bool on) {
    if (domain == 'cover') return on ? 'open_cover' : 'close_cover';
    if (domain == 'valve') return on ? 'open_valve' : 'close_valve';
    if (domain == 'lock') return on ? 'lock' : 'unlock';
    return on ? 'turn_on' : 'turn_off';
  }

  static Map<String, dynamic>? _decode(dynamic raw) {
    try {
      if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
      if (raw is List<int>) {
        return jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}

// ── Entity registry info ─────────────────────────────────────────────────

/// Per-entity registry data used to decide whether/where to import it.
class HaEntityRegistryInfo {
  final String? areaId;
  final String? entityCategory; // 'diagnostic' | 'config' | null (primary)
  final String? disabledBy;     // non-null if the entity is disabled in HA

  const HaEntityRegistryInfo({
    this.areaId,
    this.entityCategory,
    this.disabledBy,
  });

  /// False for HA's own internal bookkeeping entities (diagnostic/config —
  /// e.g. "Backup: Last successful backup", "Sun: Next dawn", a device's
  /// WiFi-signal sensor) and for entities disabled in HA — neither is a
  /// controllable physical device and importing them just adds inert
  /// toggles that do nothing when tapped.
  bool get isImportable =>
      disabledBy == null &&
      entityCategory != 'diagnostic' &&
      entityCategory != 'config';
}

// ── Live connection handle ─────────────────────────────────────────────────

/// Handle to an active HA WebSocket connection. Call [close] to disconnect.
class HaLiveConnection {
  final WebSocket _ws;
  final void Function()? _onDisconnected;
  bool _closed = false;

  HaLiveConnection._(this._ws, this._onDisconnected);

  bool get isOpen => !_closed && _ws.readyState == WebSocket.open;

  void close() {
    if (_closed) return;
    _closed = true;
    _ws.close();
    _onDisconnected?.call();
  }
}
