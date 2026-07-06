import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';

import '../models/device.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeviceIcons — single source of truth for every device/entity icon (and its
// matching accent color) shown anywhere in the app.
//
// Before this file existed, the same 28-case DeviceType → Icon/Color switch
// was copy-pasted in device_card.dart, devices_screen.dart (×2) and
// notifications_screen.dart, and state-aware variants (locked/unlocked,
// open/closed) were duplicated ad hoc per screen. Everything now routes
// through here so a new device type or a new state variant only needs to be
// taught once.
//
// Swappable icon set: all lookups delegate to [DeviceIconSet] (see below).
// The default is [MaterialSymbolsIconSet] — Material Design 3's icon pack —
// but the whole app can switch to a different icon library later by calling
// `DeviceIcons.use(SomeOtherIconSet())` once (e.g. in main() or a settings
// screen); no call site anywhere else in the app needs to change.
// ─────────────────────────────────────────────────────────────────────────────
abstract class DeviceIcons {
  DeviceIcons._();

  static DeviceIconSet _active = const MaterialSymbolsIconSet();

  /// Swaps the entire icon set app-wide (e.g. to switch icon libraries or
  /// ship an alternate visual theme). Every DeviceIcons.* call below is
  /// re-derived from whatever set is active — no other file needs to change.
  static void use(DeviceIconSet set) => _active = set;

  /// Base icon for a device type, ignoring current state.
  /// Use [forDevice] instead when a live [Device] is available — it picks a
  /// state-aware variant (locked/unlocked, open/closed, etc.) where one exists.
  static IconData icon(DeviceType type) => _active.icon(type);

  /// Accent color that matches [icon].
  static Color color(DeviceType type) => _active.color(type);

  /// State-aware icon for a live [Device] — falls back to [icon] for types
  /// with no meaningful state variant.
  static IconData forDevice(Device d) => _active.forDevice(d);

  /// Lock icon for a given locked/unlocked state — used by every screen that
  /// shows a smart lock's current state.
  static IconData lockIcon(bool isLocked) => _active.lockIcon(isLocked);

  /// Blind/cover icon for a 0 (closed) – 100 (open) position, or the
  /// direction-agnostic default when position is unknown.
  static IconData blindIcon(int? position) => _active.blindIcon(position);

  /// Icon for a Home Assistant `device_class` — fills the gap for sensor
  /// sub-kinds that don't have a distinct [DeviceType] (temperature,
  /// humidity, pressure, illuminance, air quality, electrical measurements).
  static IconData forHaDeviceClass(String? deviceClass, {IconData? fallback}) =>
      _active.forHaDeviceClass(deviceClass, fallback: fallback ?? _active.icon(DeviceType.motionSensor));

  /// Battery-level icon — reflects charge, not device type.
  static IconData batteryIcon(int? level) => _active.batteryIcon(level);
}

// ─────────────────────────────────────────────────────────────────────────────
// DeviceIconSet — the swap point. Implement this to ship a different icon
// library or visual style; [DeviceIcons.use] activates it app-wide.
// ─────────────────────────────────────────────────────────────────────────────
abstract class DeviceIconSet {
  const DeviceIconSet();

  IconData icon(DeviceType type);
  Color color(DeviceType type);
  IconData forDevice(Device d);
  IconData lockIcon(bool isLocked);
  IconData blindIcon(int? position);
  IconData forHaDeviceClass(String? deviceClass, {required IconData fallback});
  IconData batteryIcon(int? level);
}

// ─────────────────────────────────────────────────────────────────────────────
// MaterialSymbolsIconSet — default implementation, Google's Material Design 3
// icon pack (package:material_symbols_icons).
// ─────────────────────────────────────────────────────────────────────────────
class MaterialSymbolsIconSet extends DeviceIconSet {
  const MaterialSymbolsIconSet();

  @override
  IconData icon(DeviceType type) => switch (type) {
        DeviceType.light            => Symbols.lightbulb,
        DeviceType.blind            => Symbols.blinds,
        DeviceType.airConditioner   => Symbols.hvac,
        DeviceType.smartPlug        => Symbols.power,
        DeviceType.smartSwitch      => Symbols.toggle_on,
        DeviceType.motionSensor     => Symbols.sensors,
        DeviceType.doorSensor       => Symbols.sensor_door,
        DeviceType.windowSensor     => Symbols.window,
        DeviceType.waterHeater      => Symbols.water_drop,
        DeviceType.camera           => Symbols.videocam,
        DeviceType.intercom         => Symbols.doorbell,
        DeviceType.router           => Symbols.router,
        DeviceType.gateway          => Symbols.hub,
        DeviceType.circuitBreaker   => Symbols.electrical_services,
        DeviceType.solar            => Symbols.wb_sunny,
        DeviceType.smokeSensor      => Symbols.local_fire_department,
        DeviceType.energyMeter      => Symbols.bolt,
        DeviceType.smartLock        => Symbols.lock,
        DeviceType.gasSensor        => Symbols.cloud,
        DeviceType.waterLeakSensor  => Symbols.water_damage,
        DeviceType.glassBreakSensor => Symbols.crisis_alert,
        DeviceType.matterDevice     => Symbols.hexagon,
        DeviceType.smartTv          => Symbols.tv,
        DeviceType.networkDevice    => Symbols.phone_android,
        DeviceType.printer          => Symbols.print,
        DeviceType.garage           => Symbols.garage,
        DeviceType.alarmPanel       => Symbols.security,
        DeviceType.unknown          => Symbols.device_unknown,
      };

  @override
  Color color(DeviceType type) => switch (type) {
        DeviceType.light            => AppColors.lightColor,
        DeviceType.airConditioner   => AppColors.acColor,
        DeviceType.waterHeater      => AppColors.acColor,
        DeviceType.smartPlug        => AppColors.plugColor,
        DeviceType.smartSwitch      => AppColors.plugColor,
        DeviceType.motionSensor     => AppColors.motionColor,
        DeviceType.doorSensor       => AppColors.doorColor,
        DeviceType.windowSensor     => AppColors.doorColor,
        DeviceType.camera           => AppColors.cameraColor,
        DeviceType.intercom         => AppColors.cameraColor,
        DeviceType.blind            => AppColors.primary,
        DeviceType.router           => AppColors.networkColor,
        DeviceType.gateway          => AppColors.networkColor,
        DeviceType.circuitBreaker   => AppColors.circuitBreakerColor,
        DeviceType.solar            => AppColors.solarColor,
        DeviceType.smokeSensor      => AppColors.smokeColor,
        DeviceType.glassBreakSensor => AppColors.smokeColor,
        DeviceType.energyMeter      => AppColors.energyColor,
        DeviceType.smartLock        => AppColors.lockColor,
        DeviceType.gasSensor        => AppColors.motionColor,
        DeviceType.waterLeakSensor  => AppColors.networkColor,
        DeviceType.matterDevice     => AppColors.matterColor,
        DeviceType.smartTv          => AppColors.acColor,
        DeviceType.networkDevice    => AppColors.networkDeviceColor,
        DeviceType.printer          => AppColors.printerColor,
        DeviceType.garage           => AppColors.garageColor,
        DeviceType.alarmPanel       => AppColors.statusAlarm,
        DeviceType.unknown          => AppColors.plugColor,
      };

  @override
  IconData forDevice(Device d) {
    switch (d.type) {
      case DeviceType.smartLock:
        return lockIcon(d.isOn);
      case DeviceType.doorSensor:
        return (d.attributes['open'] as bool? ?? false)
            ? Symbols.door_open
            : Symbols.sensor_door;
      case DeviceType.windowSensor:
        return (d.attributes['open'] as bool? ?? false)
            ? Symbols.window_open
            : Symbols.window;
      case DeviceType.motionSensor:
        return (d.attributes['detected'] as bool? ?? d.isOn)
            ? Symbols.directions_run
            : Symbols.sensors;
      case DeviceType.smokeSensor:
        return (d.attributes['smoke'] as bool? ?? d.isOn)
            ? Symbols.local_fire_department
            : Symbols.detector_smoke;
      case DeviceType.waterLeakSensor:
        return (d.attributes['water_leak'] as bool? ?? d.isOn)
            ? Symbols.water_damage
            : Symbols.water_drop;
      case DeviceType.light:
        return d.isOn ? Symbols.lightbulb : Symbols.lightbulb_outline;
      case DeviceType.blind:
        // Smart water/gas valves share DeviceType.blind (same open/closed +
        // position semantics as a cover) but need a distinct icon — the
        // HA `valve` domain is carried in attributes at sync time.
        if (d.attributes['domain'] == 'valve') {
          final deviceClass = d.attributes['deviceClass'] as String?;
          return deviceClass == 'gas' ? Symbols.propane : Symbols.faucet;
        }
        final position = d.attributes['blindLevel'] as int?;
        return blindIcon(position);
      default:
        return icon(d.type);
    }
  }

  @override
  IconData lockIcon(bool isLocked) =>
      isLocked ? Symbols.lock : Symbols.lock_open;

  @override
  IconData blindIcon(int? position) {
    if (position == null) return Symbols.blinds;
    if (position <= 5) return Symbols.blinds_closed;
    return Symbols.blinds;
  }

  @override
  IconData forHaDeviceClass(String? deviceClass, {required IconData fallback}) {
    switch (deviceClass) {
      case 'temperature':      return Symbols.thermometer;
      case 'humidity':         return Symbols.humidity_percentage;
      case 'pressure':
      case 'atmospheric_pressure': return Symbols.speed;
      case 'illuminance':       return Symbols.light_mode;
      case 'battery':           return Symbols.battery_full;
      case 'energy':            return Symbols.bolt;
      case 'power':             return Symbols.electric_bolt;
      case 'voltage':           return Symbols.electrical_services;
      case 'current':           return Symbols.electrical_services;
      case 'co2':
      case 'carbon_dioxide':    return Symbols.co2;
      case 'carbon_monoxide':   return Symbols.cloud;
      case 'pm25':
      case 'pm10':              return Symbols.airwave;
      case 'sound':             return Symbols.volume_up;
      case 'vibration':         return Symbols.crisis_alert;
      case 'weight':            return Symbols.scale;
      case 'moisture':
      case 'water':             return Symbols.water_damage;
      case 'motion':
      case 'occupancy':         return Symbols.sensors;
      case 'door':              return Symbols.sensor_door;
      case 'window':
      case 'opening':           return Symbols.window;
      case 'smoke':             return Symbols.detector_smoke;
      case 'gas':               return Symbols.cloud;
      default:                  return fallback;
    }
  }

  @override
  IconData batteryIcon(int? level) {
    if (level == null) return Symbols.battery_unknown;
    if (level <= 20) return Symbols.battery_alert;
    if (level <= 50) return Symbols.battery_3_bar;
    if (level <= 80) return Symbols.battery_5_bar;
    return Symbols.battery_full;
  }
}
