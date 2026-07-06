// ─────────────────────────────────────────────────────────────────────────────
// HaService — שירות מרכזי לתקשורת עם Home Assistant
//
// REST:
//   GET  /api/           → בדיקת זמינות
//   GET  /api/states     → כל הישויות
//   GET  /api/areas      → חדרים / אזורים
//   POST /api/services/{domain}/{service} → הפעלת שירות
//
// WebSocket /api/websocket:
//   auth_required → auth → auth_ok → subscribe_events(state_changed)
//   events → onStateChange callback
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ha_config.dart';
import 'ha_device.dart';
import 'ha_entity.dart';
import 'ha_entity_registry.dart';

// ── דומיינים שלא מייצגים מכשירים פיזיים ──────────────────────────────────────
const _skipDomains = {
  'automation', 'script', 'scene',
  'input_boolean', 'input_text', 'input_number', 'input_select', 'input_datetime',
  'zone', 'person', 'sun', 'timer', 'counter', 'group',
  'device_tracker', 'tts', 'system_log', 'logger',
  'update', 'notify', 'persistent_notification', 'number', 'select',
  'button', 'event', 'todo', 'conversation', 'stt', 'wake_word',
};

// ── sensor device_class שמייצגים מכשיר פיזי ──────────────────────────────────
const _physicalSensorClasses = {
  'temperature', 'humidity', 'pressure', 'energy', 'power',
  'voltage', 'current', 'battery', 'illuminance', 'gas',
  'moisture', 'co2', 'pm25', 'pm10', 'carbon_dioxide',
  'carbon_monoxide', 'motion', 'door', 'window', 'smoke',
  'sound', 'vibration', 'water', 'weight',
};

// ─────────────────────────────────────────────────────────────────────────────
// תוצאות
// ─────────────────────────────────────────────────────────────────────────────

class HaConnectionResult {
  final bool success;
  final String? haVersion;
  final String? error;
  const HaConnectionResult.ok({this.haVersion}) : success = true, error = null;
  const HaConnectionResult.fail(this.error)     : success = false, haVersion = null;
}

class HaArea {
  final String  id;
  final String  name;
  final String? floorId;
  final String? icon;
  final List<String> aliases;
  final List<String> labels;

  const HaArea({
    required this.id,
    required this.name,
    this.floorId,
    this.icon,
    this.aliases = const [],
    this.labels  = const [],
  });

  factory HaArea.fromJson(Map<String, dynamic> json) => HaArea(
    id:      json['area_id'] as String,
    name:    json['name']    as String,
    floorId: json['floor_id'] as String?,
    icon:    json['icon']     as String?,
    aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
    labels:  (json['labels']  as List?)?.cast<String>() ?? const [],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HaRegistrySnapshot — all three registries fetched in one shot
// ─────────────────────────────────────────────────────────────────────────────

class HaRegistrySnapshot {
  final List<HaArea>                areas;
  final List<HaDevice>              devices;
  final List<HaEntityRegistryEntry> entityEntries;

  // Fast lookup maps
  final Map<String, HaArea>                  areaById;
  final Map<String, HaDevice>                deviceById;
  final Map<String, HaEntityRegistryEntry>   entryByEntityId;

  HaRegistrySnapshot({
    required this.areas,
    required this.devices,
    required this.entityEntries,
  })  : areaById         = {for (final a in areas)         a.id:         a},
        deviceById       = {for (final d in devices)       d.id:         d},
        entryByEntityId  = {for (final e in entityEntries) e.entityId:   e};

  /// Resolves the effective area for an entity.
  /// Priority: entity-level area > device-level area
  String? areaIdFor(String entityId) {
    final entry  = entryByEntityId[entityId];
    if (entry == null) return null;
    return entry.areaId ?? deviceById[entry.deviceId]?.areaId;
  }

  /// Returns all entity registry entries that belong to [deviceId].
  List<HaEntityRegistryEntry> entriesForDevice(String deviceId) =>
      entityEntries.where((e) => e.deviceId == deviceId).toList();

  /// Returns all devices in [areaId].
  List<HaDevice> devicesInArea(String areaId) =>
      devices.where((d) => d.areaId == areaId).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// HaService
// ─────────────────────────────────────────────────────────────────────────────

class HaService {
  final HaConfig config;

  HaService(this.config);

  HaConfig get haConfig => config;

  // ── בדיקת חיבור ──────────────────────────────────────────────────────────

  Future<HaConnectionResult> verify() async {
    try {
      final res = await http
          .get(Uri.parse('${config.baseUrl}/api/'), headers: config.headers)
          .timeout(config.timeout);
      if (res.statusCode == 200) {
        return const HaConnectionResult.ok();
      }
      if (res.statusCode == 401) {
        return const HaConnectionResult.fail('טוקן לא תקין (401)');
      }
      return HaConnectionResult.fail('שגיאה ${res.statusCode}');
    } on TimeoutException {
      return const HaConnectionResult.fail('תם הזמן הקצוב');
    } catch (e) {
      return HaConnectionResult.fail('כשל: $e');
    }
  }

  // ── שליפת אזורים (חדרים) ─────────────────────────────────────────────────

  /// מחזיר מיפוי entity_id → area_id לפי /api/template
  Future<Map<String, String>> fetchEntityAreas() async {
    try {
      const template = r'''
{
  {% for state in states %}
  {% set area = area_id(state.entity_id) %}
  {% if area %}
  "{{ state.entity_id }}": "{{ area }}"{% if not loop.last %},{% endif %}
  {% endif %}
  {% endfor %}
}
''';
      final res = await http
          .post(
            Uri.parse('${config.baseUrl}/api/template'),
            headers: config.headers,
            body: jsonEncode({'template': template}),
          )
          .timeout(config.timeout);

      if (res.statusCode != 200) return {};
      final cleaned = res.body.trim().replaceAll(RegExp(r',\s*}'), '}');
      final Map<String, dynamic> raw = jsonDecode(cleaned);
      return raw.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  /// Area registry — /api/config/area_registry/list
  Future<List<HaArea>> fetchAreas() async {
    try {
      final res = await http
          .get(Uri.parse('${config.baseUrl}/api/config/area_registry/list'),
              headers: config.headers)
          .timeout(config.timeout);
      if (res.statusCode != 200) return [];
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(HaArea.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Device registry — /api/config/device_registry/list
  Future<List<HaDevice>> fetchDeviceRegistry() async {
    try {
      final res = await http
          .get(Uri.parse('${config.baseUrl}/api/config/device_registry/list'),
              headers: config.headers)
          .timeout(config.timeout);
      if (res.statusCode != 200) return [];
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(HaDevice.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Entity registry — /api/config/entity_registry/list
  Future<List<HaEntityRegistryEntry>> fetchEntityRegistry() async {
    try {
      final res = await http
          .get(Uri.parse('${config.baseUrl}/api/config/entity_registry/list'),
              headers: config.headers)
          .timeout(config.timeout);
      if (res.statusCode != 200) return [];
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .whereType<Map<String, dynamic>>()
          .map(HaEntityRegistryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches all three registries in parallel — O(1) round trips instead of 3.
  Future<HaRegistrySnapshot> fetchAllRegistries() async {
    final results = await Future.wait([
      fetchAreas(),
      fetchDeviceRegistry(),
      fetchEntityRegistry(),
    ]);
    return HaRegistrySnapshot(
      areas:         results[0] as List<HaArea>,
      devices:       results[1] as List<HaDevice>,
      entityEntries: results[2] as List<HaEntityRegistryEntry>,
    );
  }

  // ── שליפת ישויות ─────────────────────────────────────────────────────────

  /// Fetches all entity states and returns physical devices only.
  ///
  /// [registry]: when provided, area/device linkage is resolved from the
  /// registry (fast, accurate).  Without it, areas are left null.
  /// Disabled + helper entities are excluded automatically when registry
  /// is supplied.
  Future<List<HaEntity>> fetchEntities({HaRegistrySnapshot? registry}) async {
    final res = await http
        .get(Uri.parse('${config.baseUrl}/api/states'), headers: config.headers)
        .timeout(config.timeout);

    if (res.statusCode == 401) throw Exception('HA token invalid');
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

    final List<dynamic> raw = jsonDecode(res.body);
    final entities = <HaEntity>[];

    for (final json in raw) {
      final entityId = json['entity_id'] as String? ?? '';
      final domain   = entityId.split('.').first;

      if (_skipDomains.contains(domain)) continue;

      // If registry available, skip disabled / hidden / helper entities
      if (registry != null) {
        final entry = registry.entryByEntityId[entityId];
        if (entry != null && (!entry.isActive || entry.isHelperEntity)) continue;
      }

      final attrs       = (json['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
      final deviceClass = (registry?.entryByEntityId[entityId]?.deviceClass
                          ?? attrs['device_class']) as String?;

      // Filter non-physical sensors
      if (domain == 'sensor') {
        if (deviceClass == null || !_physicalSensorClasses.contains(deviceClass)) continue;
      }

      // Resolve area + device from registry
      final registryEntry = registry?.entryByEntityId[entityId];
      final areaId  = registry?.areaIdFor(entityId);
      final deviceId = registryEntry?.deviceId;

      entities.add(HaEntity.fromJson(
        json as Map<String, dynamic>,
        areaId:   areaId,
        deviceId: deviceId,
      ));
    }

    return entities;
  }

  /// Legacy: fetch entities with area resolution via template (slow).
  /// Prefer [fetchEntities] with a [HaRegistrySnapshot].
  Future<List<HaEntity>> fetchEntitiesWithAreas() async {
    final areaMap = await fetchEntityAreas();
    final res = await http
        .get(Uri.parse('${config.baseUrl}/api/states'), headers: config.headers)
        .timeout(config.timeout);
    if (res.statusCode == 401) throw Exception('HA token invalid');
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final List<dynamic> raw = jsonDecode(res.body);
    final entities = <HaEntity>[];
    for (final json in raw) {
      final entityId = json['entity_id'] as String? ?? '';
      final domain   = entityId.split('.').first;
      if (_skipDomains.contains(domain)) continue;
      final attrs       = (json['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
      final deviceClass = attrs['device_class'] as String?;
      if (domain == 'sensor') {
        if (deviceClass == null || !_physicalSensorClasses.contains(deviceClass)) continue;
      }
      entities.add(HaEntity.fromJson(json as Map<String, dynamic>,
          areaId: areaMap[entityId]));
    }
    return entities;
  }

  /// מחזיר ישויות מסוננות לפי domain
  Future<List<HaEntity>> fetchByDomain(String domain) async {
    final all = await fetchEntities();
    return all.where((e) => e.domain == domain).toList();
  }

  /// מחזיר ישויות לפי area_id (חדר)
  Future<List<HaEntity>> fetchByArea(String areaId) async {
    final all = await fetchEntitiesWithAreas();
    return all.where((e) => e.areaId == areaId).toList();
  }

  /// מחזיר מצב ישות בודדת
  Future<HaEntity?> getEntityState(String entityId) async {
    try {
      final res = await http
          .get(Uri.parse('${config.baseUrl}/api/states/$entityId'),
              headers: config.headers)
          .timeout(config.timeout);
      if (res.statusCode != 200) return null;
      return HaEntity.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── שירות גנרי ───────────────────────────────────────────────────────────

  Future<bool> callService(
    String domain,
    String service, {
    String? entityId,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final body = <String, dynamic>{...extra};
      if (entityId != null) body['entity_id'] = entityId;

      final res = await http
          .post(
            Uri.parse('${config.baseUrl}/api/services/$domain/$service'),
            headers: config.headers,
            body: jsonEncode(body),
          )
          .timeout(config.timeout);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Light ─────────────────────────────────────────────────────────────────

  Future<bool> lightOn(
    String entityId, {
    int? brightness,
    int? colorTempKelvin,
    List<double>? hsColor,    // [hue 0-360, sat 0-100]
    List<int>?    rgbColor,   // [r, g, b] 0-255
    String? effect,
  }) =>
      callService('light', 'turn_on',
          entityId: entityId,
          extra: {
            if (brightness      != null) 'brightness_pct':  brightness.clamp(1, 100),
            if (colorTempKelvin != null) 'color_temp_kelvin': colorTempKelvin,
            if (hsColor         != null) 'hs_color':        hsColor,
            if (rgbColor        != null) 'rgb_color':       rgbColor,
            if (effect          != null) 'effect':          effect,
          });

  Future<bool> lightOff(String entityId) =>
      callService('light', 'turn_off', entityId: entityId);

  Future<bool> lightToggle(String entityId) =>
      callService('light', 'toggle', entityId: entityId);

  // ── Switch ────────────────────────────────────────────────────────────────

  Future<bool> switchOn(String entityId)  =>
      callService('switch', 'turn_on',  entityId: entityId);

  Future<bool> switchOff(String entityId) =>
      callService('switch', 'turn_off', entityId: entityId);

  Future<bool> toggleSwitch(String entityId) =>
      callService('switch', 'toggle', entityId: entityId);

  // ── Climate ───────────────────────────────────────────────────────────────

  Future<bool> climateSetTemp(String entityId, double temp) =>
      callService('climate', 'set_temperature',
          entityId: entityId, extra: {'temperature': temp});

  Future<bool> climateSetTempRange(String entityId,
          {required double low, required double high}) =>
      callService('climate', 'set_temperature', entityId: entityId,
          extra: {'target_temp_low': low, 'target_temp_high': high});

  Future<bool> climateSetMode(String entityId, String mode) =>
      callService('climate', 'set_hvac_mode',
          entityId: entityId, extra: {'hvac_mode': mode});

  Future<bool> climateSetFanMode(String entityId, String fanMode) =>
      callService('climate', 'set_fan_mode',
          entityId: entityId, extra: {'fan_mode': fanMode});

  Future<bool> climateTurnOff(String entityId) =>
      climateSetMode(entityId, 'off');

  // ── Cover (תריסים) ────────────────────────────────────────────────────────

  Future<bool> coverOpen(String entityId)  =>
      callService('cover', 'open_cover',  entityId: entityId);

  Future<bool> coverClose(String entityId) =>
      callService('cover', 'close_cover', entityId: entityId);

  Future<bool> coverStop(String entityId)  =>
      callService('cover', 'stop_cover',  entityId: entityId);

  Future<bool> coverSetPosition(String entityId, int position) =>
      callService('cover', 'set_cover_position',
          entityId: entityId, extra: {'position': position.clamp(0, 100)});

  Future<bool> coverSetTiltPosition(String entityId, int tilt) =>
      callService('cover', 'set_cover_tilt_position',
          entityId: entityId, extra: {'tilt_position': tilt.clamp(0, 100)});

  // ── Lock ──────────────────────────────────────────────────────────────────

  Future<bool> lockLock(String entityId, {String? code}) =>
      callService('lock', 'lock',
          entityId: entityId, extra: {if (code != null) 'code': code});

  Future<bool> lockUnlock(String entityId, {String? code}) =>
      callService('lock', 'unlock',
          entityId: entityId, extra: {if (code != null) 'code': code});

  Future<bool> lockOpen(String entityId, {String? code}) =>
      callService('lock', 'open',
          entityId: entityId, extra: {if (code != null) 'code': code});

  // ── Fan ───────────────────────────────────────────────────────────────────

  Future<bool> fanOn(String entityId)  =>
      callService('fan', 'turn_on',  entityId: entityId);

  Future<bool> fanOff(String entityId) =>
      callService('fan', 'turn_off', entityId: entityId);

  Future<bool> fanToggle(String entityId) =>
      callService('fan', 'toggle', entityId: entityId);

  Future<bool> fanSetPercentage(String entityId, int percentage) =>
      callService('fan', 'set_percentage',
          entityId: entityId,
          extra: {'percentage': percentage.clamp(0, 100)});

  Future<bool> fanSetPresetMode(String entityId, String preset) =>
      callService('fan', 'set_preset_mode',
          entityId: entityId, extra: {'preset_mode': preset});

  Future<bool> fanOscillate(String entityId, {required bool oscillating}) =>
      callService('fan', 'oscillate',
          entityId: entityId, extra: {'oscillating': oscillating});

  Future<bool> fanSetDirection(String entityId, String direction) =>
      callService('fan', 'set_direction',
          entityId: entityId, extra: {'direction': direction});

  // ── Media Player ──────────────────────────────────────────────────────────

  Future<bool> mediaPlay(String entityId) =>
      callService('media_player', 'media_play', entityId: entityId);

  Future<bool> mediaPause(String entityId) =>
      callService('media_player', 'media_pause', entityId: entityId);

  Future<bool> mediaPlayPause(String entityId) =>
      callService('media_player', 'media_play_pause', entityId: entityId);

  Future<bool> mediaStop(String entityId) =>
      callService('media_player', 'media_stop', entityId: entityId);

  Future<bool> mediaNextTrack(String entityId) =>
      callService('media_player', 'media_next_track', entityId: entityId);

  Future<bool> mediaPrevTrack(String entityId) =>
      callService('media_player', 'media_previous_track', entityId: entityId);

  Future<bool> mediaVolumeSet(String entityId, double volume) =>
      callService('media_player', 'volume_set',
          entityId: entityId,
          extra: {'volume_level': volume.clamp(0.0, 1.0)});

  Future<bool> mediaVolumeMute(String entityId, {required bool mute}) =>
      callService('media_player', 'volume_mute',
          entityId: entityId, extra: {'is_volume_muted': mute});

  Future<bool> mediaVolumeUp(String entityId) =>
      callService('media_player', 'volume_up', entityId: entityId);

  Future<bool> mediaVolumeDown(String entityId) =>
      callService('media_player', 'volume_down', entityId: entityId);

  Future<bool> mediaSelectSource(String entityId, String source) =>
      callService('media_player', 'select_source',
          entityId: entityId, extra: {'source': source});

  Future<bool> mediaTurnOn(String entityId) =>
      callService('media_player', 'turn_on', entityId: entityId);

  Future<bool> mediaTurnOff(String entityId) =>
      callService('media_player', 'turn_off', entityId: entityId);

  // ── Vacuum ────────────────────────────────────────────────────────────────

  Future<bool> vacuumStart(String entityId) =>
      callService('vacuum', 'start', entityId: entityId);

  Future<bool> vacuumStop(String entityId) =>
      callService('vacuum', 'stop', entityId: entityId);

  Future<bool> vacuumPause(String entityId) =>
      callService('vacuum', 'pause', entityId: entityId);

  Future<bool> vacuumReturnToBase(String entityId) =>
      callService('vacuum', 'return_to_base', entityId: entityId);

  Future<bool> vacuumLocate(String entityId) =>
      callService('vacuum', 'locate', entityId: entityId);

  Future<bool> vacuumCleanSpot(String entityId) =>
      callService('vacuum', 'clean_spot', entityId: entityId);

  Future<bool> vacuumSetFanSpeed(String entityId, String speed) =>
      callService('vacuum', 'set_fan_speed',
          entityId: entityId, extra: {'fan_speed': speed});

  // ── Input Boolean ─────────────────────────────────────────────────────────

  Future<bool> inputBooleanOn(String entityId) =>
      callService('input_boolean', 'turn_on', entityId: entityId);

  Future<bool> inputBooleanOff(String entityId) =>
      callService('input_boolean', 'turn_off', entityId: entityId);

  Future<bool> inputBooleanToggle(String entityId) =>
      callService('input_boolean', 'toggle', entityId: entityId);

  // ── Scene ─────────────────────────────────────────────────────────────────

  Future<bool> sceneActivate(String entityId) =>
      callService('scene', 'turn_on', entityId: entityId);

  // ── Script ────────────────────────────────────────────────────────────────

  Future<bool> scriptRun(String entityId) =>
      callService('script', 'turn_on', entityId: entityId);

  // ── Water Heater ─────────────────────────────────────────────────────────

  Future<bool> waterHeaterSetTemp(String entityId, double temp) =>
      callService('water_heater', 'set_temperature',
          entityId: entityId, extra: {'temperature': temp});

  Future<bool> waterHeaterSetMode(String entityId, String mode) =>
      callService('water_heater', 'set_operation_mode',
          entityId: entityId, extra: {'operation_mode': mode});

  Future<bool> waterHeaterTurnOn(String entityId) =>
      callService('water_heater', 'turn_on', entityId: entityId);

  Future<bool> waterHeaterTurnOff(String entityId) =>
      callService('water_heater', 'turn_off', entityId: entityId);

  // ── Homeassistant (generic) ───────────────────────────────────────────────

  Future<bool> genericTurnOn(String entityId) =>
      callService('homeassistant', 'turn_on', entityId: entityId);

  Future<bool> genericTurnOff(String entityId) =>
      callService('homeassistant', 'turn_off', entityId: entityId);

  Future<bool> genericToggle(String entityId) =>
      callService('homeassistant', 'toggle', entityId: entityId);

  // ── Alarm Control Panel ───────────────────────────────────────────────────

  Future<bool> alarmArmAway(String entityId, {String? code}) =>
      callService('alarm_control_panel', 'alarm_arm_away',
          entityId: entityId, extra: {if (code != null) 'code': code});

  Future<bool> alarmArmHome(String entityId, {String? code}) =>
      callService('alarm_control_panel', 'alarm_arm_home',
          entityId: entityId, extra: {if (code != null) 'code': code});

  Future<bool> alarmArmNight(String entityId, {String? code}) =>
      callService('alarm_control_panel', 'alarm_arm_night',
          entityId: entityId, extra: {if (code != null) 'code': code});

  Future<bool> alarmDisarm(String entityId, {String? code}) =>
      callService('alarm_control_panel', 'alarm_disarm',
          entityId: entityId, extra: {if (code != null) 'code': code});

  Future<bool> alarmTrigger(String entityId) =>
      callService('alarm_control_panel', 'alarm_trigger', entityId: entityId);

  // ── WebSocket — עדכונים בזמן אמת ─────────────────────────────────────────

  /// פותח WebSocket ומאזין לשינויי מצב.
  /// מחזיר [HaLiveConnection] — קרא [HaLiveConnection.close()] לניתוק.
  Future<HaLiveConnection?> connectLive({
    required void Function(HaEntity entity) onStateChange,
    void Function(String error)?  onError,
    void Function()?              onDisconnected,
  }) async {
    try {
      final wsUrl = '${config.wsUrl}/api/websocket';
      final ws    = await WebSocket.connect(wsUrl).timeout(config.timeout);

      final conn = HaLiveConnection._(ws, onDisconnected);
      final authDone = Completer<bool>();

      ws.listen(
        (raw) {
          final msg = _decode(raw);
          if (msg == null) return;

          switch (msg['type'] as String? ?? '') {
            case 'auth_required':
              ws.add(jsonEncode({
                'type':         'auth',
                'access_token': config.token,
              }));
              break;

            case 'auth_ok':
              ws.add(jsonEncode({
                'id':         1,
                'type':       'subscribe_events',
                'event_type': 'state_changed',
              }));
              if (!authDone.isCompleted) authDone.complete(true);
              break;

            case 'auth_invalid':
              if (!authDone.isCompleted) authDone.complete(false);
              onError?.call('WebSocket: טוקן לא תקין');
              break;

            case 'event':
              final event    = msg['event']          as Map?;
              final data     = event?['data']         as Map?;
              final newState = data?['new_state']     as Map?;
              if (newState == null) break;
              try {
                onStateChange(HaEntity.fromJson(
                    newState.cast<String, dynamic>()));
              } catch (_) {}
              break;
          }
        },
        onError: (e) {
          onError?.call('WebSocket error: $e');
          conn._closed = true;
        },
        onDone: () {
          conn._closed = true;
          onDisconnected?.call();
        },
        cancelOnError: false,
      );

      final ok = await authDone.future.timeout(
        config.timeout,
        onTimeout: () => false,
      );
      if (!ok) {
        await ws.close();
        return null;
      }

      return conn;
    } catch (e) {
      onError?.call('WebSocket connect failed: $e');
      return null;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static Map<String, dynamic>? _decode(dynamic raw) {
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HaLiveConnection — handle לחיבור WebSocket פעיל
// ─────────────────────────────────────────────────────────────────────────────

class HaLiveConnection {
  final WebSocket _ws;
  final void Function()? _onDisconnected;
  bool _closed = false;

  HaLiveConnection._(this._ws, this._onDisconnected);

  bool get isOpen => !_closed && _ws.readyState == WebSocket.open;

  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      await _ws.close();
      _onDisconnected?.call();
    }
  }
}
