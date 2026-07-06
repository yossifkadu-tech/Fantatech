import 'device.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeviceCapabilities — derives what a device can DO from what it actually
// reports, instead of hardcoding behavior per DeviceType.
//
// Matter/HA/Zigbee devices expose capabilities through their attributes
// (brightness, position, power, battery, temperature…) — two devices of the
// same DeviceType can support different feature sets, and a firmware update
// can add capabilities to an existing device. Detecting from attributes means
// the UI and automation builder pick those up automatically with no code
// change, which is the point of a capability model.
//
// Rule of thumb: a capability is granted when the device REPORTS the matching
// attribute, falling back to a type-level default only where the attribute is
// write-only (e.g. a light's brightness before it ever reported one).
// ─────────────────────────────────────────────────────────────────────────────

enum DeviceCapability {
  /// Can be switched on/off (or locked/unlocked, open/closed for covers).
  onOff,

  /// Dimmable — has or accepts a 0–100 brightness.
  brightness,

  /// Tunable white — has a color temperature in Kelvin.
  colorTemp,

  /// Positionable cover — 0 (closed) to 100 (open).
  position,

  /// Lock/unlock control (distinct from onOff so UI can render lock verbs).
  lockControl,

  /// Full climate control (mode/fan/swing/setpoint).
  climateControl,

  /// Water-heater control (target temp + eco/full mode).
  waterHeaterControl,

  /// Reports a binary sensed state (motion / open / leak / smoke / gas…).
  binaryState,

  /// Reports live power draw in watts.
  powerMeter,

  /// Reports an ambient temperature reading.
  temperature,

  /// Reports a humidity reading.
  humidity,

  /// Battery-powered — reports a charge level.
  battery,
}

abstract class DeviceCapabilities {
  DeviceCapabilities._();

  /// The attribute key holding a binary sensor's state, per type.
  /// (These keys are what HaSyncService and the gateway clients write.)
  static String? binaryStateKey(DeviceType type) => switch (type) {
        DeviceType.motionSensor     => 'detected',
        DeviceType.doorSensor       => 'open',
        DeviceType.windowSensor     => 'open',
        DeviceType.waterLeakSensor  => 'water_leak',
        DeviceType.smokeSensor      => 'smoke',
        DeviceType.gasSensor        => 'gas',
        DeviceType.glassBreakSensor => 'vibration',
        _                           => null,
      };

  static Set<DeviceCapability> of(Device d) {
    final a = d.attributes;
    final caps = <DeviceCapability>{};

    // ── Sensing ──────────────────────────────────────────────────────────────
    if (binaryStateKey(d.type) != null) caps.add(DeviceCapability.binaryState);
    if (d.battery != null || a['battery'] != null) {
      caps.add(DeviceCapability.battery);
    }
    if (a['temperature'] != null || a['currentTemp'] != null) {
      caps.add(DeviceCapability.temperature);
    }
    if (a['humidity'] != null) caps.add(DeviceCapability.humidity);
    if (a['power'] != null || d.type == DeviceType.energyMeter) {
      caps.add(DeviceCapability.powerMeter);
    }

    // ── Control ──────────────────────────────────────────────────────────────
    switch (d.type) {
      case DeviceType.smartLock:
        caps.add(DeviceCapability.lockControl);
        break;
      case DeviceType.airConditioner:
        caps.addAll([DeviceCapability.onOff, DeviceCapability.climateControl]);
        break;
      case DeviceType.waterHeater:
        caps.addAll([DeviceCapability.onOff, DeviceCapability.waterHeaterControl]);
        break;
      case DeviceType.light:
        caps.addAll([DeviceCapability.onOff, DeviceCapability.brightness]);
        break;
      case DeviceType.blind:
        caps.addAll([DeviceCapability.onOff, DeviceCapability.position]);
        break;
      case DeviceType.smartPlug:
      case DeviceType.smartSwitch:
      case DeviceType.smartTv:
      case DeviceType.intercom:
      case DeviceType.garage:
      case DeviceType.matterDevice:
        caps.add(DeviceCapability.onOff);
        break;
      default:
        break;
    }

    // Attribute-reported capabilities — a device of ANY type that reports
    // these gets the control, e.g. a Matter dimmer plug (smartPlug +
    // brightness) or an unclassified matterDevice reporting a position.
    if (a['brightness'] != null) caps.add(DeviceCapability.brightness);
    if (a['colorTempKelvin'] != null) caps.add(DeviceCapability.colorTemp);
    if (a['position'] != null || a['blindLevel'] != null) {
      caps.add(DeviceCapability.position);
    }

    return caps;
  }

  /// Current cover position 0–100, reading whichever key the source wrote.
  /// (HA sync writes 'blindLevel'; local/manual devices write 'position'.)
  static int? positionOf(Device d) =>
      (d.attributes['position'] as num?)?.toInt() ??
      (d.attributes['blindLevel'] as num?)?.toInt();

  /// True when the device can act as an automation TRIGGER (senses something).
  static bool canTrigger(Device d) =>
      of(d).contains(DeviceCapability.binaryState);

  /// True when the device can act as an automation ACTION target
  /// (something can be switched/locked/moved).
  static bool canAct(Device d) {
    final caps = of(d);
    return caps.contains(DeviceCapability.onOff) ||
        caps.contains(DeviceCapability.lockControl);
  }
}
