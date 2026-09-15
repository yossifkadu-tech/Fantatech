import 'package:flutter/widgets.dart' show IconData;

import 'device.dart';
import 'device_capabilities.dart';
import '../theme/device_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SensorStateSpec — the read-only counterpart to ButtonSpec. A sensor isn't
// a control (no action/toggle) — it's a reported state, so this exposes
// exactly that: what the sensor currently reports, in a clear per-type
// label (motion → detected/clear, door/window → open/closed, water_leak →
// detected/clear, temperature/humidity → a numeric reading + unit).
//
// Built entirely from the existing capability layer:
//   - DeviceCapabilities.binaryStateKey(type) already maps each sensor
//     DeviceType to the attribute key that carries its bool state (motion→
//     'detected', door/window→'open', water_leak→'water_leak', smoke→
//     'smoke', gas→'gas') — reused here, not duplicated.
//   - Automation triggering on a sensor's state change needs NO new event
//     mechanism: AutomationEngine (services/automation_engine.dart) already
//     re-evaluates every 'sensor' trigger on every AppState.notifyListeners()
//     call, firing on the rising edge of a sensor's binary state. Any code
//     path that updates a sensor Device's attributes (HA sync, gateway
//     poll, manual test) already produces that event — this model doesn't
//     need to push anything itself.
// ─────────────────────────────────────────────────────────────────────────────

class SensorStateSpec {
  final String sensorId;
  final DeviceType deviceType;
  final DeviceCapability capability;
  final String state;
  final String unit;
  final IconData icon;
  final String displayName;

  const SensorStateSpec({
    required this.sensorId,
    required this.deviceType,
    required this.capability,
    required this.state,
    required this.unit,
    required this.icon,
    required this.displayName,
  });

  /// Per-type label for a binary sensor's active/inactive state — e.g.
  /// water_leak reports 'detected'/'clear', door/window report
  /// 'open'/'closed', matching the requested `water_leak = detected` shape.
  static ({String active, String inactive}) _binaryLabels(DeviceType type) =>
      switch (type) {
        DeviceType.doorSensor   => (active: 'open', inactive: 'closed'),
        DeviceType.windowSensor => (active: 'open', inactive: 'closed'),
        _                       => (active: 'detected', inactive: 'clear'),
      };

  factory SensorStateSpec.forCapability(Device device, DeviceCapability capability) {
    if (!DeviceCapabilities.of(device).contains(capability)) {
      throw ArgumentError(
          'Device ${device.id} does not report capability $capability');
    }

    final String state;
    final String unit;
    switch (capability) {
      case DeviceCapability.binaryState:
        final key = DeviceCapabilities.binaryStateKey(device.type);
        final active = device.attributes[key] as bool? ?? false;
        final labels = _binaryLabels(device.type);
        state = active ? labels.active : labels.inactive;
        unit = '';
        break;
      case DeviceCapability.temperature:
        final v = device.attributes['temperature'] ?? device.attributes['currentTemp'];
        state = (v as num?)?.toStringAsFixed(1) ?? '0.0';
        unit = '°C';
        break;
      case DeviceCapability.humidity:
        final v = device.attributes['humidity'] as num?;
        state = v?.toStringAsFixed(0) ?? '0';
        unit = '%';
        break;
      default:
        throw ArgumentError(
            'Capability $capability has no sensor-state mapping yet');
    }

    return SensorStateSpec(
      sensorId: device.id,
      deviceType: device.type,
      capability: capability,
      state: state,
      unit: unit,
      icon: DeviceIcons.forDevice(device),
      displayName: device.name,
    );
  }
}
