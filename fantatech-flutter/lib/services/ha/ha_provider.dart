// ─────────────────────────────────────────────────────────────────────────────
// HaProvider — real-time HA state manager (no manual refresh needed)
//
// Real-time sync strategy:
//   1. Initial load  — REST registries (areas + devices + entity registry) +
//                      REST states → full cache populated once on connect.
//   2. Live updates  — WebSocket state_changed events update _entities in-place.
//   3. Registry sync — entity_registry_updated / device_registry_updated /
//                      area_registry_updated events trigger targeted partial
//                      re-fetch of just that registry (not a full reload).
//   4. Reconnect     — exponential backoff; on success, re-syncs all states
//                      to recover from events missed during disconnect.
//   5. Optimistic UI — commands instantly apply a predicted state so the UI
//                      feels immediate; WS echo corrects within ~200–500 ms.
//   6. Batch notify  — rapid state_changed floods are coalesced into one
//                      notifyListeners() call per frame (16 ms debounce).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';

import 'ha_config.dart';
import 'ha_device.dart';
import 'ha_entity.dart';
import 'ha_entity_registry.dart';
import 'ha_logger.dart';
import 'ha_rest_client.dart';
import 'ha_service.dart';
import 'ha_token_service.dart';
import 'ha_ws_service.dart';

export 'ha_ws_service.dart' show HaAuthState;

enum HaStatus { disconnected, connecting, connected, error }

class HaProvider extends ChangeNotifier with WidgetsBindingObserver {
  HaProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  HaService?      _service;
  HaWsService?    _ws;
  HaInstanceInfo? _instanceInfo;

  HaStatus _status = HaStatus.disconnected;
  String?  _error;

  // ── Entity + registry caches ──────────────────────────────────────────────

  /// Runtime entity states — entity_id → HaEntity
  final Map<String, HaEntity> _entities = {};

  List<HaArea> _areas = [];

  /// Device registry — device_id → HaDevice
  final Map<String, HaDevice> _devices = {};

  /// Entity registry — entity_id → HaEntityRegistryEntry
  final Map<String, HaEntityRegistryEntry> _entityRegistry = {};

  // ── Fast-path entity callback ─────────────────────────────────────────────
  // Called immediately (before debounce) for every WS state_changed event.
  // AppState uses this to update a single Device without scanning all entities.
  void Function(HaEntity entity)? onEntityChanged;

  // ── Batch notify (coalesce rapid state_changed floods) ────────────────────
  Timer? _notifyTimer;

  void _scheduledNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 16), notifyListeners);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  HaStatus get status          => _status;
  String?  get error           => _error;
  bool     get isConnected     => _status == HaStatus.connected;
  HaConfig? get config         => _service?.config;
  HaInstanceInfo? get instanceInfo => _instanceInfo;

  /// Current WebSocket auth state (for diagnostics / UI indicators)
  HaAuthState get wsAuthState  => _ws?.authState ?? HaAuthState.disconnected;

  List<HaEntity>              get entities       => _entities.values.toList();
  List<HaArea>                get areas          => List.unmodifiable(_areas);
  List<HaDevice>              get devices        => _devices.values.toList();
  List<HaEntityRegistryEntry> get entityRegistry => _entityRegistry.values.toList();

  HaDevice?              device(String deviceId)   => _devices[deviceId];
  HaEntityRegistryEntry? registryEntry(String eid) => _entityRegistry[eid];

  List<HaEntity> get lights        => _byDomain('light');
  List<HaEntity> get switches      => _byDomain('switch');
  List<HaEntity> get climates      => _byDomain('climate');
  List<HaEntity> get covers        => _byDomain('cover');
  List<HaEntity> get sensors       => _byDomain('sensor');
  List<HaEntity> get cameras       => _byDomain('camera');
  List<HaEntity> get alarms        => _byDomain('alarm_control_panel');
  List<HaEntity> get binarySensors => _byDomain('binary_sensor');
  List<HaEntity> get locks         => _byDomain('lock');
  List<HaEntity> get fans          => _byDomain('fan');
  List<HaEntity> get mediaPlayers  => _byDomain('media_player');
  List<HaEntity> get vacuums       => _byDomain('vacuum');
  List<HaEntity> get automations   => _byDomain('automation');
  List<HaEntity> get scenes        => _byDomain('scene');
  List<HaEntity> get scripts       => _byDomain('script');

  HaEntity? entity(String entityId) => _entities[entityId];

  List<HaEntity> entitiesInArea(String areaId) =>
      _entities.values.where((e) => e.areaId == areaId).toList();

  List<HaEntity> entitiesForDevice(String deviceId) =>
      _entities.values.where((e) => e.deviceId == deviceId).toList();

  List<HaDevice> devicesInArea(String areaId) =>
      _devices.values.where((d) => d.areaId == areaId).toList();

  List<HaEntityRegistryEntry> activeEntriesForDevice(String deviceId) =>
      _entityRegistry.values
          .where((e) => e.deviceId == deviceId && e.isActive)
          .toList();

  // ── Connect ───────────────────────────────────────────────────────────────

  Future<bool> connect(HaConfig config) async {
    _cancelReconnect();
    _status = HaStatus.connecting;
    _error  = null;
    notifyListeners();
    HaLogger.i('HaProvider', 'Connecting to ${config.baseUrl}');

    _service = HaService(config);

    // 1. Validate token + fetch HA instance info via REST
    HaLogger.i('HaProvider', 'Validating token via REST /api/config');
    final validateRes = await HaTokenService(config).validate();
    switch (validateRes) {
      case HaOk(:final data):
        _instanceInfo = data;
        HaLogger.i('HaProvider',
            'Token valid — HA ${data.haVersion} "${data.locationName}"');
      case HaErr(:final error):
        _status = HaStatus.error;
        _error  = error.message;
        HaLogger.e('HaProvider',
            'Token validation failed [${error.kind.name}]: ${error.message}');
        notifyListeners();
        return false;
    }

    // 2. Full data load (registries + states) via REST
    HaLogger.i('HaProvider', 'Loading registries + states via REST');
    await _loadAll();

    _status = HaStatus.connected;
    notifyListeners();
    HaLogger.i('HaProvider',
        'REST load complete — ${_entities.length} entities, '
        '${_devices.length} devices, ${_areas.length} areas');

    // 3. Open WebSocket for live updates
    unawaited(_startWs(config));
    return true;
  }

  Future<void> disconnect() async {
    HaLogger.i('HaProvider', 'Disconnecting');
    _cancelReconnect();
    await _ws?.disconnect();
    _ws             = null;
    _instanceInfo   = null;
    _service        = null;
    _entities.clear();
    _devices.clear();
    _entityRegistry.clear();
    _areas          = [];
    _status         = HaStatus.disconnected;
    _error          = null;
    onEntityChanged = null;
    notifyListeners();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (_service == null) return;
    await _loadAll();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    if (_service == null) return;

    // Fetch all three registries in parallel
    final snapshot = await _service!.fetchAllRegistries();

    _areas = snapshot.areas;

    _devices.clear();
    for (final d in snapshot.devices) {
      _devices[d.id] = d;
    }
    _entityRegistry.clear();
    for (final e in snapshot.entityEntries) {
      _entityRegistry[e.entityId] = e;
    }

    // Fetch live states with area + device linkage from registry
    final states = await _service!.fetchEntities(registry: snapshot);
    _entities.clear();
    for (final e in states) {
      _entities[e.entityId] = e;
    }
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  Timer?        _reconnectTimer;
  int           _reconnectAttempt = 0;
  final List<int> _registrySubs   = [];    // subscription IDs to cancel on disconnect

  Future<void> _startWs(HaConfig config) async {
    await _ws?.disconnect();
    _registrySubs.clear();

    _ws = HaWsService(config)
      ..onStateChange  = _onStateChange
      ..onError        = _onWsError
      ..onDisconnected = _onWsDisconnected
      ..onAuthFailed   = _onWsAuthFailed;

    final ok = await _ws!.connect();

    if (ok) {
      // Subscribe to registry change events so we never need manual refresh
      await _subscribeRegistryEvents();
    } else if (_status != HaStatus.disconnected &&
               _status != HaStatus.error) {
      // Auth failures are handled by _onWsAuthFailed; only schedule
      // reconnect for transient network failures.
      _scheduleReconnect(config);
    }
  }

  // ── Live state update ─────────────────────────────────────────────────────

  void _onStateChange(HaEntity incoming) {
    // Preserve deviceId + areaId from registry (WS events don't carry them)
    final existing = _entities[incoming.entityId];
    final updated = incoming.copyWithState(
      incoming.state,
      incoming.attributes,
    ).copyWith(
      areaId:   existing?.areaId   ?? incoming.areaId,
      deviceId: existing?.deviceId ?? incoming.deviceId,
    );
    _entities[incoming.entityId] = updated;
    HaLogger.d('HaProvider',
        'state_changed: ${incoming.entityId} → ${incoming.state}');
    // Immediate fast-path: let AppState update just this one device now,
    // without waiting for the 16 ms debounce to fire.
    onEntityChanged?.call(updated);
    _scheduledNotify();
  }

  void _onWsError(String msg) {
    HaLogger.e('HaProvider', 'WS error: $msg');
    _error = msg;
    notifyListeners();
  }

  void _onWsDisconnected() {
    if (_status == HaStatus.connected || _status == HaStatus.error) {
      HaLogger.w('HaProvider', 'WebSocket disconnected — scheduling reconnect');
      _status = HaStatus.error;
      _error  = 'WebSocket disconnected';
      notifyListeners();
      if (_service != null) _scheduleReconnect(_service!.config);
    }
  }

  // Called when HA rejects our token (auth_invalid message).
  // We must NOT schedule a reconnect — the token will still be invalid next time.
  void _onWsAuthFailed() {
    HaLogger.e('HaProvider',
        'WS auth_invalid — token rejected. '
        'Generate a new Long-Lived Access Token in HA → Profile → Security.');
    _cancelReconnect(); // stop any pending retries
    _status = HaStatus.error;
    _error  = 'Invalid token — open Settings → Home Assistant and re-enter your token';
    notifyListeners();
  }

  // ── Registry event subscriptions ─────────────────────────────────────────

  /// Subscribes to HA registry-change events so entities/devices/areas update
  /// automatically without any manual refresh.
  Future<void> _subscribeRegistryEvents() async {
    if (_ws == null || _service == null) return;

    // Entity registry changed (entity added/removed/renamed/moved)
    final eSub = await _ws!.subscribe(
      'entity_registry_updated',
      (_) async {
        if (_service == null) return;
        final entries = await _service!.fetchEntityRegistry();
        _entityRegistry.clear();
        for (final e in entries) { _entityRegistry[e.entityId] = e; }
        // Re-apply area/deviceId to cached entities
        for (final eid in _entities.keys) {
          final reg = _entityRegistry[eid];
          if (reg == null) continue;
          final snapshot = HaRegistrySnapshot(
            areas: _areas, devices: _devices.values.toList(), entityEntries: entries,
          );
          final areaId   = snapshot.areaIdFor(eid);
          final deviceId = reg.deviceId;
          final e = _entities[eid]!;
          if (e.areaId != areaId || e.deviceId != deviceId) {
            _entities[eid] = e.copyWith(areaId: areaId, deviceId: deviceId);
          }
        }
        notifyListeners();
      },
    );
    if (eSub != null) _registrySubs.add(eSub);

    // Device registry changed (device added/removed/renamed/moved to area)
    final dSub = await _ws!.subscribe(
      'device_registry_updated',
      (_) async {
        if (_service == null) return;
        final devs = await _service!.fetchDeviceRegistry();
        _devices.clear();
        for (final d in devs) { _devices[d.id] = d; }
        notifyListeners();
      },
    );
    if (dSub != null) _registrySubs.add(dSub);

    // Area registry changed (area added/removed/renamed)
    final aSub = await _ws!.subscribe(
      'area_registry_updated',
      (_) async {
        if (_service == null) return;
        _areas = await _service!.fetchAreas();
        notifyListeners();
      },
    );
    if (aSub != null) _registrySubs.add(aSub);
  }

  // ── Reconnect ─────────────────────────────────────────────────────────────

  // Exponential backoff: 5 s → 10 s → 20 s → 40 s → 60 s (cap)
  void _scheduleReconnect(HaConfig config) {
    _reconnectTimer?.cancel();
    if (_status == HaStatus.disconnected) return;

    final delaySec = (_reconnectAttempt < 4) ? (5 * (1 << _reconnectAttempt)) : 60;
    final delay    = Duration(seconds: delaySec);
    _reconnectAttempt++;

    HaLogger.i('HaProvider',
        'Reconnect attempt #$_reconnectAttempt scheduled in ${delaySec}s');

    _reconnectTimer = Timer(delay, () async {
      if (_status == HaStatus.disconnected) return;

      // ── Token re-validation before opening WebSocket ──────────────────────
      // Catches revoked tokens early so we don't loop forever on auth failures.
      HaLogger.i('HaProvider',
          'Attempt #$_reconnectAttempt — re-validating token');
      if (await HaTokenService(config).validate()
          case HaErr(:final error)) {
        if (error.kind == HaErrorKind.auth) {
          // Token is invalid — no point reconnecting
          HaLogger.e('HaProvider',
              'Token invalid (401) — stopping reconnect. '
              'Re-enter your Long-Lived Access Token in Settings → Home Assistant.');
          _status = HaStatus.error;
          _error  = 'Invalid token — open Settings → Home Assistant and re-enter your token';
          notifyListeners();
          return;
        }
        // Network/server error — keep retrying
        HaLogger.w('HaProvider',
            'Token validation failed (${error.kind.name}) — will retry');
      }

      // ── Open WebSocket ────────────────────────────────────────────────────
      await _ws?.disconnect();
      _registrySubs.clear();

      _ws = HaWsService(config)
        ..onStateChange  = _onStateChange
        ..onError        = _onWsError
        ..onDisconnected = _onWsDisconnected
        ..onAuthFailed   = _onWsAuthFailed;

      final ok = await _ws!.connect();
      if (ok) {
        _reconnectAttempt = 0;
        HaLogger.i('HaProvider',
            'Reconnected — re-syncing states missed during disconnect');

        // Re-sync states missed during the disconnect window
        await _loadAll();

        _status = HaStatus.connected;
        _error  = null;
        notifyListeners();
        HaLogger.i('HaProvider',
            'Back online — ${_entities.length} entities synced');

        // Re-subscribe to registry events
        await _subscribeRegistryEvents();
      } else {
        _scheduleReconnect(config);
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer   = null;
    _reconnectAttempt = 0;
    _notifyTimer?.cancel();
    _notifyTimer = null;
  }

  // ── Subscribe to extra event types (public) ───────────────────────────────

  Future<int?> subscribeEvent(
    String eventType,
    void Function(Map<String, dynamic> event) handler,
  ) => _ws?.subscribe(eventType, handler) ?? Future.value(null);

  Future<bool> unsubscribeEvent(int subscriptionId) =>
      _ws?.unsubscribe(subscriptionId) ?? Future.value(false);

  // ── Optimistic state update ───────────────────────────────────────────────

  /// Immediately applies a predicted state so the UI feels instant.
  /// Also fires onEntityChanged so AppState's fast path updates in the same frame.
  /// The real state arrives via WebSocket within ~200–500 ms and overwrites this.
  void _optimistic(String entityId, String predictedState,
      [Map<String, dynamic>? attrs]) {
    final e = _entities[entityId];
    if (e == null) {
      // Silent no-op otherwise — logged so a mismatched/stale entityId
      // (which would make a button LOOK completely dead) is visible.
      HaLogger.w('HaProvider',
          'Optimistic update skipped — unknown entityId: $entityId');
      return;
    }
    final updated = e.copyWithState(predictedState, attrs ?? e.attributes);
    _entities[entityId] = updated;
    onEntityChanged?.call(updated);   // fast path → AppState._onSingleEntityChanged
    notifyListeners();
  }

  /// Returns the state string HA will most likely send after turning on/off.
  static String _predictedState(String entityId, bool on) {
    switch (entityId.split('.').first) {
      case 'cover':        return on ? 'open'      : 'closed';
      case 'lock':         return on ? 'unlocked'  : 'locked';
      case 'vacuum':       return on ? 'cleaning'  : 'docked';
      case 'media_player': return on ? 'on'        : 'off';
      default:             return on ? 'on'        : 'off';
    }
  }

  // ── WS-first service call (REST fallback) ─────────────────────────────────

  /// Routes a service call through the already-connected WebSocket when
  /// available (lower latency — no TCP handshake).  Falls back to REST if
  /// the WebSocket is not authenticated or the WS call fails.
  Future<bool> _wsCall(
    String domain,
    String service, {
    String? entityId,
    Map<String, dynamic> extra = const {},
  }) async {
    if (_ws?.isAuthenticated == true) {
      final ok = await _ws!.callService(domain, service,
          entityId: entityId, serviceData: extra);
      if (ok) return true;
      // WS call failed (mid-disconnect?) — fall through to REST
      HaLogger.w('HaProvider',
          'WS callService failed for $domain.$service — retrying via REST');
    }
    return await (_service?.callService(domain, service,
        entityId: entityId, extra: extra) ?? Future.value(false));
  }

  // ── Entity commands ───────────────────────────────────────────────────────

  Future<bool> setOnOff(String entityId, bool on) async {
    _optimistic(entityId, _predictedState(entityId, on));
    final domain = entityId.split('.').first;
    switch (domain) {
      case 'light':
        return _wsCall('light', on ? 'turn_on' : 'turn_off', entityId: entityId);
      case 'switch':
        return _wsCall('switch', on ? 'turn_on' : 'turn_off', entityId: entityId);
      case 'cover':
        return _wsCall('cover', on ? 'open_cover' : 'close_cover', entityId: entityId);
      case 'climate':
        return _wsCall('climate', 'set_hvac_mode', entityId: entityId,
            extra: {'hvac_mode': on ? 'auto' : 'off'});
      case 'lock':
        return _wsCall('lock', on ? 'unlock' : 'lock', entityId: entityId);
      case 'fan':
        return _wsCall('fan', on ? 'turn_on' : 'turn_off', entityId: entityId);
      case 'media_player':
        return _wsCall('media_player', on ? 'turn_on' : 'turn_off', entityId: entityId);
      case 'vacuum':
        return _wsCall('vacuum', on ? 'start' : 'return_to_base', entityId: entityId);
      default:
        return _wsCall(domain, on ? 'turn_on' : 'turn_off', entityId: entityId);
    }
  }

  Future<bool> setLightBrightness(String entityId, int brightness) async {
    _optimistic(entityId, 'on',
        {...?_entities[entityId]?.attributes, 'brightness': brightness * 2.55});
    return _wsCall('light', 'turn_on', entityId: entityId,
        extra: {'brightness_pct': brightness.clamp(1, 100)});
  }

  Future<bool> setLightColor(String entityId,
      {List<double>? hs, List<int>? rgb}) async {
    _optimistic(entityId, 'on', {
      ...?_entities[entityId]?.attributes,
      if (hs  != null) 'hs_color':  hs,
      if (rgb != null) 'rgb_color': rgb,
    });
    return _wsCall('light', 'turn_on', entityId: entityId, extra: {
      if (hs  != null) 'hs_color':  hs,
      if (rgb != null) 'rgb_color': rgb,
    });
  }

  Future<bool> setLightEffect(String entityId, String effect) async =>
      _wsCall('light', 'turn_on', entityId: entityId, extra: {'effect': effect});

  Future<bool> setCoverPosition(String entityId, int position) async {
    _optimistic(entityId, 'open',
        {...?_entities[entityId]?.attributes, 'current_position': position});
    return _wsCall('cover', 'set_cover_position', entityId: entityId,
        extra: {'position': position.clamp(0, 100)});
  }

  Future<bool> coverStop(String entityId) async =>
      _wsCall('cover', 'stop_cover', entityId: entityId);

  Future<bool> setClimateTemp(String entityId, double temp) async {
    _optimistic(entityId, _entities[entityId]?.state ?? 'heat',
        {...?_entities[entityId]?.attributes, 'temperature': temp});
    return _wsCall('climate', 'set_temperature', entityId: entityId,
        extra: {'temperature': temp});
  }

  Future<bool> setClimateFanMode(String entityId, String fanMode) async =>
      _wsCall('climate', 'set_fan_mode', entityId: entityId,
          extra: {'fan_mode': fanMode});

  Future<bool> armAlarm(String entityId,
      {String mode = 'away', String? code}) async {
    _optimistic(entityId, 'arming');
    final extra = <String, dynamic>{if (code != null) 'code': code};
    switch (mode) {
      case 'home':  return _wsCall('alarm_control_panel', 'alarm_arm_home',
          entityId: entityId, extra: extra);
      case 'night': return _wsCall('alarm_control_panel', 'alarm_arm_night',
          entityId: entityId, extra: extra);
      default:      return _wsCall('alarm_control_panel', 'alarm_arm_away',
          entityId: entityId, extra: extra);
    }
  }

  Future<bool> disarmAlarm(String entityId, {String? code}) async {
    _optimistic(entityId, 'disarming');
    return _wsCall('alarm_control_panel', 'alarm_disarm', entityId: entityId,
        extra: {if (code != null) 'code': code});
  }

  // ── Lock ──────────────────────────────────────────────────────────────────

  Future<bool> lockLock(String entityId, {String? code}) async {
    _optimistic(entityId, 'locking');
    return _wsCall('lock', 'lock', entityId: entityId,
        extra: {if (code != null) 'code': code});
  }

  Future<bool> lockUnlock(String entityId, {String? code}) async {
    _optimistic(entityId, 'unlocking');
    return _wsCall('lock', 'unlock', entityId: entityId,
        extra: {if (code != null) 'code': code});
  }

  // ── Fan ───────────────────────────────────────────────────────────────────

  Future<bool> fanSetPercentage(String entityId, int pct) async {
    _optimistic(entityId, 'on',
        {...?_entities[entityId]?.attributes, 'percentage': pct});
    return _wsCall('fan', 'set_percentage', entityId: entityId,
        extra: {'percentage': pct.clamp(0, 100)});
  }

  Future<bool> fanSetPresetMode(String entityId, String preset) async {
    _optimistic(entityId, 'on',
        {...?_entities[entityId]?.attributes, 'preset_mode': preset});
    return _wsCall('fan', 'set_preset_mode', entityId: entityId,
        extra: {'preset_mode': preset});
  }

  Future<bool> fanOscillate(String entityId,
      {required bool oscillating}) async {
    _optimistic(entityId, _entities[entityId]?.state ?? 'on',
        {...?_entities[entityId]?.attributes, 'oscillating': oscillating});
    return _wsCall('fan', 'oscillate', entityId: entityId,
        extra: {'oscillating': oscillating});
  }

  // ── Media Player ──────────────────────────────────────────────────────────

  Future<bool> mediaPlay(String entityId) async {
    _optimistic(entityId, 'playing');
    return _wsCall('media_player', 'media_play', entityId: entityId);
  }

  Future<bool> mediaPause(String entityId) async {
    _optimistic(entityId, 'paused');
    return _wsCall('media_player', 'media_pause', entityId: entityId);
  }

  Future<bool> mediaPlayPause(String entityId) async {
    final cur = _entities[entityId]?.state;
    _optimistic(entityId, cur == 'playing' ? 'paused' : 'playing');
    return _wsCall('media_player', 'media_play_pause', entityId: entityId);
  }

  Future<bool> mediaStop(String entityId) async {
    _optimistic(entityId, 'idle');
    return _wsCall('media_player', 'media_stop', entityId: entityId);
  }

  Future<bool> mediaNextTrack(String entityId) async =>
      _wsCall('media_player', 'media_next_track', entityId: entityId);

  Future<bool> mediaPrevTrack(String entityId) async =>
      _wsCall('media_player', 'media_previous_track', entityId: entityId);

  Future<bool> mediaVolumeSet(String entityId, double volume) async {
    _optimistic(entityId, _entities[entityId]?.state ?? 'on',
        {...?_entities[entityId]?.attributes, 'volume_level': volume});
    return _wsCall('media_player', 'volume_set', entityId: entityId,
        extra: {'volume_level': volume.clamp(0.0, 1.0)});
  }

  Future<bool> mediaVolumeMute(String entityId, {required bool mute}) async {
    _optimistic(entityId, _entities[entityId]?.state ?? 'on',
        {...?_entities[entityId]?.attributes, 'is_volume_muted': mute});
    return _wsCall('media_player', 'volume_mute', entityId: entityId,
        extra: {'is_volume_muted': mute});
  }

  Future<bool> mediaSelectSource(String entityId, String source) async {
    _optimistic(entityId, _entities[entityId]?.state ?? 'on',
        {...?_entities[entityId]?.attributes, 'source': source});
    return _wsCall('media_player', 'select_source', entityId: entityId,
        extra: {'source': source});
  }

  // ── Vacuum ────────────────────────────────────────────────────────────────

  Future<bool> vacuumStart(String entityId) async {
    _optimistic(entityId, 'cleaning');
    return _wsCall('vacuum', 'start', entityId: entityId);
  }

  Future<bool> vacuumStop(String entityId) async {
    _optimistic(entityId, 'idle');
    return _wsCall('vacuum', 'stop', entityId: entityId);
  }

  Future<bool> vacuumPause(String entityId) async {
    _optimistic(entityId, 'paused');
    return _wsCall('vacuum', 'pause', entityId: entityId);
  }

  Future<bool> vacuumReturnToBase(String entityId) async {
    _optimistic(entityId, 'returning');
    return _wsCall('vacuum', 'return_to_base', entityId: entityId);
  }

  Future<bool> vacuumLocate(String entityId) async =>
      _wsCall('vacuum', 'locate', entityId: entityId);

  // ── Automation / Scene / Script ───────────────────────────────────────────

  Future<bool> automationEnable(String entityId) async {
    _optimistic(entityId, 'on');
    return _wsCall('automation', 'turn_on', entityId: entityId);
  }

  Future<bool> automationDisable(String entityId) async {
    _optimistic(entityId, 'off');
    return _wsCall('automation', 'turn_off', entityId: entityId);
  }

  Future<bool> automationTrigger(String entityId) async =>
      _wsCall('automation', 'trigger', entityId: entityId);

  Future<bool> sceneActivate(String entityId) async =>
      _wsCall('scene', 'turn_on', entityId: entityId);

  Future<bool> scriptRun(String entityId) async =>
      _wsCall('script', 'turn_on', entityId: entityId);

  // ── Generic ───────────────────────────────────────────────────────────────

  Future<bool> callService(
    String domain,
    String service, {
    String? entityId,
    Map<String, dynamic> extra = const {},
  }) async =>
      _wsCall(domain, service, entityId: entityId, extra: extra);

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<HaEntity> _byDomain(String domain) =>
      _entities.values.where((e) => e.domain == domain).toList();

  // ── App lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
      case AppLifecycleState.paused:
        HaLogger.d('HaProvider', 'App paused — WebSocket may disconnect');
      default:
        break;
    }
  }

  void _onAppResumed() {
    if (_service == null) return; // never connected
    if (_status == HaStatus.disconnected) return; // user disconnected deliberately

    if (_ws == null || !_ws!.isAuthenticated || !_ws!.isOpen) {
      HaLogger.i('HaProvider',
          'App resumed — WebSocket dead, reconnecting immediately');
      _cancelReconnect();
      _reconnectAttempt = 0; // reset backoff so first retry is 5 s (fast)
      _scheduleReconnect(_service!.config);
    } else {
      // Socket is alive but we may have missed events while backgrounded —
      // refresh all states to close any gap.
      HaLogger.i('HaProvider',
          'App resumed — WebSocket alive, refreshing states');
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelReconnect();
    _ws?.disconnect();
    super.dispose();
  }
}
