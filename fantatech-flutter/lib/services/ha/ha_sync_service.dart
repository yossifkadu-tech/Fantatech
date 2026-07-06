// ─────────────────────────────────────────────────────────────────────────────
// HaSyncService — מגשר בין HaProvider ל-AppState
//
// כאשר HA מחזיר ישויות חיות, הן מתורגמות ל-Device ומוזרקות ל-AppState.
// עדכוני WebSocket (state_changed) מעדכנים AppState בזמן אמת.
// ─────────────────────────────────────────────────────────────────────────────

import '../../models/device.dart';
import '../../models/app_state.dart';
import 'ha_entity.dart';
import 'ha_config.dart';
import 'ha_provider.dart';

class HaSyncService {
  final AppState  _appState;
  final HaProvider _haProvider;

  HaSyncService({required AppState appState, required HaProvider haProvider})
      : _appState  = appState,
        _haProvider = haProvider;

  /// מתחבר ל-HA ומסנכרן ישויות ל-AppState
  Future<bool> connectAndSync(HaConfig config) async {
    final ok = await _haProvider.connect(config);
    if (!ok) return false;

    _syncAll(_haProvider.entities);

    // מאזין לעדכונים חיים
    _haProvider.addListener(_onHaUpdate);
    return true;
  }

  void _onHaUpdate() {
    _syncAll(_haProvider.entities);
  }

  void _syncAll(List<HaEntity> entities) {
    // Matter (and most Zigbee) devices expose battery/temperature as SIBLING
    // entities of the same physical device, not as attributes on the primary
    // entity. Group them by HA device-registry id so the primary Device
    // (e.g. a water-leak sensor) carries its own battery/temperature instead
    // of them being dropped.
    final batteryByDevice = <String, int>{};
    final tempByDevice = <String, double>{};
    for (final e in entities) {
      final devId = e.deviceId;
      if (devId == null) continue;
      final value = e.numericValue;
      if (value == null) continue;
      if (e.deviceClass == 'battery') {
        batteryByDevice[devId] = value.toInt();
      } else if (e.deviceClass == 'temperature') {
        tempByDevice[devId] = value;
      }
    }

    // Resolve HA area ids to their human-readable names so devices group
    // under real room names ("Living Room"), not registry slugs.
    final areaNames = {
      for (final a in _haProvider.areas) a.id: a.name,
    };

    for (final entity in entities) {
      final device = _toDevice(
        entity,
        siblingBattery: batteryByDevice[entity.deviceId],
        siblingTemperature: tempByDevice[entity.deviceId],
        areaName: areaNames[entity.areaId],
      );
      if (device != null) {
        _appState.upsertDevice(device);
      }
    }
  }

  void dispose() {
    _haProvider.removeListener(_onHaUpdate);
  }

  // ── המרת HaEntity → Device ────────────────────────────────────────────────

  /// Converts an [HaEntity] to an app [Device].
  /// Returns null for entity domains that have no physical device counterpart.
  /// Public so that [AppState] can use it directly when reacting to
  /// [HaProvider] notifications without going through a full sync cycle.
  static Device? entityToDevice(
    HaEntity e, {
    String? areaName,
    int? siblingBattery,
    double? siblingTemperature,
  }) =>
      _toDevice(
        e,
        areaName: areaName,
        siblingBattery: siblingBattery,
        siblingTemperature: siblingTemperature,
      );

  static Device? _toDevice(
    HaEntity e, {
    int? siblingBattery,
    double? siblingTemperature,
    String? areaName,
  }) {
    final type = _domainToType(e);
    if (type == null) return null;

    // HA reports 'unavailable' when the device is unreachable (dead battery,
    // out of range) and 'unknown' before the first reading — neither means
    // the device is online and healthy.
    final stateLower = e.state.toLowerCase();
    final unreachable = stateLower == 'unavailable' || stateLower == 'unknown';

    final battery = e.battery ?? siblingBattery;
    final temperature = e.currentTemperature ?? siblingTemperature;

    return Device(
      id:     'ha_${e.entityId}',
      name:   e.friendlyName,
      type:   type,
      room:   areaName ?? e.areaId ?? '',
      isOn:   !unreachable && e.isOn,
      status: unreachable ? DeviceStatus.offline : DeviceStatus.online,
      attributes: {
        'entityId':    e.entityId,
        'domain':      e.domain,
        'deviceClass': e.deviceClass,
        'haIp':        '',
        if (e.brightness != null)      'brightness':      e.brightness,
        if (e.colorTempKelvin != null) 'colorTempKelvin': e.colorTempKelvin,
        if (e.coverPosition != null)   'blindLevel':      e.coverPosition,
        if (battery != null)           'battery':         battery,
        // For climate entities 'temperature' means the TARGET setpoint (that's
        // what the AC controls read/write); the measured reading goes in
        // 'currentTemp'. For everything else 'temperature' is the reading.
        if (type == DeviceType.airConditioner) ...{
          if (temperature != null)            'currentTemp': temperature,
          if (e.targetTemperature != null)    'temperature': e.targetTemperature,
          if (!unreachable && e.state != 'off') 'mode':      e.state,
          if (e.hvacModes.isNotEmpty)         'hvacModes':   e.hvacModes,
          if (e.fanMode != null)              'fan':         e.fanMode,
          if (e.fanModes.isNotEmpty)          'fanModes':    e.fanModes,
          if (e.swingMode != null)            'swingMode':   e.swingMode,
          if (e.swingModes.isNotEmpty)        'swingModes':  e.swingModes,
          if (e.presetMode != null)           'presetMode':  e.presetMode,
          if (e.presetModes.isNotEmpty)       'presetModes': e.presetModes,
          if (e.minTemp != null)              'minTemp':     e.minTemp,
          if (e.maxTemp != null)              'maxTemp':     e.maxTemp,
          if (e.currentHumidity != null)      'humidity':    e.currentHumidity,
        } else ...{
          if (temperature != null)            'temperature': temperature,
          // The sensor's own numeric reading (its raw HA state, e.g. an
          // energy/power meter's kWh or W) — previously never captured at
          // all for non-climate entities, so energyMeter devices had no
          // value to display anywhere despite being correctly classified.
          if (e.numericValue != null)         'reading':     e.numericValue,
          if (e.unit != null)                 'unit':        e.unit,
        },
        if (e.alarmState.isNotEmpty)   'alarmState':      e.alarmState,
        // Sensor-specific state fields read by the security screen
        if (type == DeviceType.waterLeakSensor) 'water_leak': !unreachable && e.isOn,
        if (type == DeviceType.smokeSensor)      'smoke':      !unreachable && e.isOn,
        if (type == DeviceType.motionSensor)     'detected':   !unreachable && e.isOn,
        if (type == DeviceType.doorSensor)       'open':       !unreachable && e.isOn,
        if (type == DeviceType.windowSensor)     'open':       !unreachable && e.isOn,
      },
    );
  }

  /// Public wrapper so callers can check whether an entity currently maps
  /// to a real device type, without going through full [entityToDevice]
  /// conversion — used to detect stale/phantom devices from before a
  /// classification-logic fix.
  static DeviceType? classify(HaEntity e) => _domainToType(e);

  static DeviceType? _domainToType(HaEntity e) {
    switch (e.domain) {
      case 'light':               return DeviceType.light;
      case 'switch':              return DeviceType.smartSwitch;
      case 'cover':               return DeviceType.blind;
      // Smart valves/faucets (water, gas) — HA's `valve` domain uses the
      // same open/closed/position semantics as `cover`, so it reuses the
      // blind control UI; the device_class carried in attributes lets the
      // icon distinguish a faucet from an actual blind (see DeviceIcons).
      case 'valve':               return DeviceType.blind;
      case 'climate':             return DeviceType.airConditioner;
      case 'camera':              return DeviceType.camera;
      case 'alarm_control_panel': return DeviceType.smartLock;
      case 'lock':                return DeviceType.smartLock;
      case 'water_heater':        return DeviceType.waterHeater;
      case 'sensor':
        switch (e.deviceClass) {
          case 'temperature':
          case 'humidity':        return DeviceType.motionSensor;
          case 'motion':          return DeviceType.motionSensor;
          case 'door':            return DeviceType.doorSensor;
          case 'window':          return DeviceType.windowSensor;
          case 'smoke':           return DeviceType.smokeSensor;
          case 'gas':             return DeviceType.gasSensor;
          case 'moisture':
          case 'water':           return DeviceType.waterLeakSensor;
          case 'energy':
          case 'power':           return DeviceType.energyMeter;
          default:
            // Only guess from the entity_id when HA reports NO device_class
            // at all. A recognized-but-different class (battery, illuminance,
            // signal_strength…) is a real, distinct reading — often a
            // sibling entity of a motion/leak sensor whose entity_id happens
            // to contain "motion"/"water"/etc. (e.g.
            // sensor.water_leak_hallway_battery). Falling through to the
            // substring guess for those misclassified that battery reading
            // as its own phantom "water leak sensor" device, duplicating
            // the real one.
            if (e.deviceClass != null) return null;
            final id = e.entityId.toLowerCase();
            if (id.contains('smoke'))                                     return DeviceType.smokeSensor;
            if (id.contains('gas') || id.contains('co'))                  return DeviceType.gasSensor;
            if (id.contains('water') || id.contains('leak') || id.contains('moisture')) return DeviceType.waterLeakSensor;
            if (id.contains('motion') || id.contains('occupancy'))        return DeviceType.motionSensor;
            if (id.contains('door'))                                       return DeviceType.doorSensor;
            if (id.contains('window'))                                     return DeviceType.windowSensor;
            return null;
        }
      case 'binary_sensor':
        switch (e.deviceClass) {
          case 'motion':
          case 'occupancy':       return DeviceType.motionSensor;
          case 'door':            return DeviceType.doorSensor;
          case 'window':
          case 'opening':         return DeviceType.windowSensor;
          case 'smoke':           return DeviceType.smokeSensor;
          case 'gas':             return DeviceType.gasSensor;
          case 'moisture':
          case 'water':           return DeviceType.waterLeakSensor;
          case 'vibration':       return DeviceType.glassBreakSensor;
          default:
            // Only guess from the entity_id when HA reports NO device_class
            // at all — see the matching comment in the 'sensor' case above.
            if (e.deviceClass != null) return null;
            final id = e.entityId.toLowerCase();
            if (id.contains('water') || id.contains('leak') || id.contains('moisture'))
              return DeviceType.waterLeakSensor;
            if (id.contains('smoke'))  return DeviceType.smokeSensor;
            if (id.contains('motion') || id.contains('occupancy')) return DeviceType.motionSensor;
            if (id.contains('door'))   return DeviceType.doorSensor;
            if (id.contains('window')) return DeviceType.windowSensor;
            return null;
        }
      default: return null;
    }
  }
}
