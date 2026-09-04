// ─────────────────────────────────────────────────────────────────────────────
// HaImportService
//
// Bulk "import all HA entities as devices" logic — extracted out of
// HaIntegrationScreen so it can run both from that screen's "Connect"/
// "Import" button AND unattended, once, on app startup (see main.dart) for
// an already-saved connection. Silent/best-effort by design: on startup
// there is no UI to show an error in, so any failure (HA unreachable, no
// saved credentials) just leaves the app on its last-known device list.
//
// Not to be confused with HaSyncService, which bridges HaProvider's live
// WebSocket entity stream to AppState for already-imported devices.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../gateways/clients/ha_gateway_client.dart';
import '../gateways/gateway_manager.dart';
import 'ha_config.dart';
import 'ha_provider.dart';
import '../storage/secure_cred_service.dart';

class HaImportStats {
  final int lights, switches, sensors, others, areas;
  const HaImportStats({
    required this.lights,
    required this.switches,
    required this.sensors,
    required this.others,
    required this.areas,
  });
}

class HaImportService {
  /// Reads the saved HA connection (if any) and re-imports devices.
  /// Returns null when there's nothing saved or HA couldn't be reached —
  /// callers doing this unattended (app startup) should treat that as a
  /// normal, silent no-op rather than an error.
  static Future<HaImportStats?> syncFromSaved(
    AppState state,
    GatewayManager gateways,
    HaProvider haProvider,
  ) async {
    final savedUrl = await SecureCredService.readHaIp();
    final token    = await SecureCredService.readHaToken();
    debugPrint('[HaImportService] savedUrl=$savedUrl tokenPresent=${token != null && token.isNotEmpty}');
    if (savedUrl == null || savedUrl.isEmpty || token == null || token.isEmpty) {
      debugPrint('[HaImportService] no saved HA credentials — skipping startup sync');
      return null;
    }

    final ip = normalizeUrl(savedUrl);
    // Retry the first ping a couple of times with a short backoff — on a
    // cold app launch the device's WiFi/DNS often isn't actually ready yet
    // at T=0, so a single attempt here would fail even though HA is
    // perfectly reachable a second later. Without this, that one failed
    // ping was the whole story: no auto-sync all session, and the user had
    // to manually reconnect from the HA settings screen every time.
    var ok = false;
    for (var attempt = 1; attempt <= 3 && !ok; attempt++) {
      debugPrint('[HaImportService] pinging $ip (attempt $attempt) ...');
      ok = await HaGatewayClient.ping(ip, token);
      if (!ok && attempt < 3) {
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    debugPrint('[HaImportService] ping result: $ok');
    if (!ok) return null;

    final states   = await HaGatewayClient.fetchAllStates(ip, token);
    final areas    = await HaGatewayClient.fetchAreas(ip, token);
    final registry = await HaGatewayClient.fetchEntityRegistryInfo(ip, token);
    debugPrint('[HaImportService] fetched states=${states.length} areas=${areas.length} registry=${registry.length}');

    final stats = importFromHa(state, states, areas, registry, ip);
    debugPrint('[HaImportService] import stats: lights=${stats.lights} switches=${stats.switches} sensors=${stats.sensors} others=${stats.others}');

    final totalDevices = stats.lights + stats.switches + stats.sensors + stats.others;
    gateways.upsertHaConnection(ip: ip, token: token, deviceCount: totalDevices);

    final fullUrl = 'http://$ip:8123';
    unawaited(haProvider.connect(HaConfig(baseUrl: fullUrl, token: token)));

    return stats;
  }

  /// Maps raw HA entity states into FantaTech Devices and upserts them into
  /// [state]. Pure/reusable — no UI, no BuildContext.
  static HaImportStats importFromHa(
    AppState state,
    List<Map<String, dynamic>> states,
    List<Map<String, dynamic>> areas,
    Map<String, HaEntityRegistryInfo> registry,
    String ip,
  ) {
    // An HA "area" maps 1:1 to a FantaTech room — it is NOT wrapped in a
    // room-group. (Room groups in this app are meant for HA's separate,
    // optional "Floors" feature — see AppState._syncHaRooms — which can
    // genuinely contain several differently-named rooms. Wrapping every
    // single-room area in its own identically-named group just showed the
    // same name twice in the UI: a "Kitchen" group containing one room
    // also called "Kitchen".) Build a local area-id → area-name lookup for
    // resolving each device's room below, without touching state.roomGroups.
    final areaNameById = <String, String>{};
    for (final area in areas) {
      final id   = (area['area_id'] as String?) ?? '';
      final name = (area['name']    as String?) ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      areaNameById[id] = name;

      final icon = _iconForAreaName(name);
      // The app's default seed rooms are stored as internal keys (e.g.
      // '__living__') and only translated to a display name like "סלון"
      // at render time (S.translateRoomKey) — comparing raw stored names
      // against HA's literal area name ("סלון") would never match a
      // default room, always creating a same-looking duplicate room.
      final normalized = name.trim().toLowerCase();
      final exists = state.rooms.any((r) => state.strings
          .translateRoomKey(r['name'] as String? ?? '')
          .trim()
          .toLowerCase() ==
          normalized);
      if (!exists) state.addRoom(name, icon);
    }

    int lights = 0, switches = 0, sensors = 0, others = 0;

    for (final entity in states) {
      final entityId = (entity['entity_id'] as String?) ?? '';
      final attrs    = (entity['attributes'] as Map<String, dynamic>?) ?? {};
      final stateStr = (entity['state'] as String?) ?? 'off';

      final domain   = entityId.split('.').first;
      final friendly = (attrs['friendly_name'] as String?) ?? entityId;

      // Skip HA's own internal bookkeeping entities (diagnostic/config, or
      // disabled) — e.g. "Backup: Last successful backup", "Sun: Next dawn",
      // a device's WiFi-signal sensor. An entity absent from the registry
      // (rare) is still imported — absence isn't evidence it's diagnostic.
      final regInfo = registry[entityId];
      if (regInfo != null && !regInfo.isImportable) continue;

      // Fallback for well-known Home Assistant OS/Supervisor system
      // entities that this particular HA installation isn't tagging with
      // entity_category: 'diagnostic' in its registry (so the check above
      // doesn't catch them) — e.g. "Raspberry Pi Power status", CPU/disk/
      // memory usage, update-available sensors. These are HA housekeeping,
      // never a physical smart-home device.
      if (_isKnownSystemEntity(entityId)) continue;

      // Area mapping — /api/states never carries area_id in attributes;
      // resolve via the entity/device registry fetched separately.
      final areaId = regInfo?.areaId;

      DeviceType? type;
      switch (domain) {
        case 'light':  type = DeviceType.light;       lights++;   break;
        case 'switch': type = DeviceType.smartSwitch; switches++; break;
        case 'input_boolean':
                       type = DeviceType.smartSwitch; switches++; break;
        case 'binary_sensor':
          type = _sensorType(entityId, attrs);
          sensors++;
          break;
        case 'sensor':
          type = _sensorType(entityId, attrs, fallback: DeviceType.energyMeter);
          sensors++;
          break;
        case 'cover':  type = DeviceType.blind;       others++;   break;
        case 'lock':   type = DeviceType.smartLock;   others++;   break;
        case 'climate':type = DeviceType.airConditioner; others++; break;
        default:       others++; break;
      }

      if (type == null) continue;

      // Re-sync an already-imported entity too (not skip it) — otherwise a
      // device imported under an older/buggy version of this classifier
      // (e.g. missing 'source', wrong type) never gets corrected, no matter
      // how many times the user re-imports or the app auto-syncs on
      // launch. Preserve a user-given custom name (AppState.updateDeviceName)
      // instead of clobbering it with HA's current friendly_name.
      final existing = state.devices.where((d) => d.attributes['entityId'] == entityId).firstOrNull;

      // Find room name from area. A user who's already reassigned this
      // device's room in-app (AppState.updateDeviceRoom) keeps that choice
      // on resync instead of it snapping back to HA's area on every sync.
      String roomName = existing?.room ?? '';
      if (roomName.isEmpty && areaId != null) {
        roomName = areaNameById[areaId] ?? '';
      }

      final isOn = _stateIsOn(stateStr);
      final brightness = attrs['brightness'];

      state.upsertDevice(Device(
        id:         'ha_${entityId.replaceAll('.', '_')}',
        name:       existing?.name ?? friendly,
        type:       type,
        isOn:       isOn,
        room:       roomName,
        // Every other gateway client marks its imported devices 'gateway'
        // (Device.source defaults to 'manual' otherwise) — the home
        // screen's smart-home summary card filters on this.
        source:     'gateway',
        attributes: {
          'entityId':    entityId,
          'deviceClass': (attrs['device_class'] as String?) ?? '',
          'domain':      domain,
          'haIp':        ip,
          if (brightness != null)
            'brightness': ((brightness as num) / 2.55).round(),
          if (attrs['temperature'] != null)
            'temperature': attrs['temperature'],
          // State fields read by the security screen
          if (type == DeviceType.waterLeakSensor) 'water_leak': isOn,
          if (type == DeviceType.smokeSensor)      'smoke':      isOn,
          if (type == DeviceType.motionSensor)     'detected':   isOn,
          if (type == DeviceType.doorSensor)       'open':       isOn,
          if (type == DeviceType.windowSensor)     'open':       isOn,
        },
      ));
    }

    return HaImportStats(
      lights:   lights,
      switches: switches,
      sensors:  sensors,
      others:   others,
      areas:    areas.length,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Entity-id substrings that identify Home Assistant's own OS/Supervisor
  /// housekeeping entities — never worth importing as a "device", but not
  /// reliably tagged `entity_category: diagnostic` on every HA install.
  static const _systemEntitySubstrings = [
    'raspberry_pi_power',
    'supervisor_',
    'core_update',
    'os_update',
    'operating_system_update',
    'hassio_',
    'addon_',
    'cpu_percent',
    'disk_free',
    'disk_use',
    'memory_use',
    'memory_free',
    'load_1m', 'load_5m', 'load_15m',
    'swap_',
    'system_health',
  ];

  static bool _isKnownSystemEntity(String entityId) {
    final id = entityId.toLowerCase();
    return _systemEntitySubstrings.any(id.contains);
  }

  static String normalizeUrl(String raw) {
    var url = raw.replaceAll(RegExp(r'^https?://'), '');
    url = url.split('/').first; // strip path
    url = url.split(':').first; // strip port (we use fixed 8123)
    return url;
  }

  static bool _stateIsOn(String state) =>
      const {'on','open','unlocked','heat','cool','auto'}.contains(state.toLowerCase());

  static DeviceType _sensorType(
    String entityId,
    Map attrs, {
    DeviceType fallback = DeviceType.motionSensor,
  }) {
    final dc = (attrs['device_class'] as String?) ?? '';
    final id = entityId.toLowerCase();
    if (dc == 'motion'   || dc == 'occupancy' || id.contains('motion') || id.contains('occupancy')) return DeviceType.motionSensor;
    if (dc == 'door'     || id.contains('door'))                                                     return DeviceType.doorSensor;
    if (dc == 'window'   || dc == 'opening'   || id.contains('window'))                             return DeviceType.windowSensor;
    if (dc == 'smoke'    || id.contains('smoke'))                                                    return DeviceType.smokeSensor;
    if (dc == 'moisture' || dc == 'water'     || id.contains('water') || id.contains('leak') || id.contains('moisture')) return DeviceType.waterLeakSensor;
    if (dc == 'gas'      || id.contains('gas') || id.contains('co2') || id.contains('co_'))         return DeviceType.gasSensor;
    if (dc == 'vibration' || id.contains('vibration') || id.contains('glass'))                      return DeviceType.glassBreakSensor;
    if (dc == 'energy'   || dc == 'power'     || id.contains('energy') || id.contains('power'))     return DeviceType.energyMeter;
    return fallback;
  }

  static int _iconForAreaName(String name) {
    final k = name.toLowerCase();
    if (k.contains('bed')  || k.contains('sleep')) return 0xe239;  // bed
    if (k.contains('bath') || k.contains('wc'))    return 0xe63d;  // wc
    if (k.contains('kit')  || k.contains('cook'))  return 0xf04c3; // kitchen
    if (k.contains('liv')  || k.contains('salon')) return 0xe318;  // weekend
    if (k.contains('garden')|| k.contains('yard')) return 0xf08d8; // yard
    if (k.contains('garage'))                       return 0xe1b3;  // garage
    if (k.contains('office')|| k.contains('study')) return 0xef53;  // desk
    return 0xe88a; // home
  }
}
