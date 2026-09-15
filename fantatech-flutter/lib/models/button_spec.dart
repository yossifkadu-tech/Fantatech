import 'package:flutter/widgets.dart' show IconData;

import 'device.dart';
import 'device_capabilities.dart';
import '../services/device_platform/device_adapter.dart' show DeviceCommandAction;
import '../theme/device_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ButtonSpec — the declarative description of a single control button, per
// the requested shape:
//   button_id, device_id, device_type, capability, action, current_state,
//   available_states, icon, display_name
//
// Reuses the existing capability/action vocabulary (DeviceType,
// DeviceCapability, DeviceCommandAction) instead of introducing parallel
// string enums — a button is always described against the Device/Capability
// layer, never against a manufacturer. Building one never talks to a
// gateway/API: [ButtonSpec.forCapability] only reads the already-known
// [Device], so it's safe to call from any screen's build().
//
// A screen renders a button from its [icon]/[displayName]/[currentState],
// and on tap builds a DeviceCommand(spec.action, ...) to send through
// DeviceCommander/DeviceAdapter — this model does not execute commands
// itself, it only describes what a button IS.
// ─────────────────────────────────────────────────────────────────────────────

class ButtonSpec {
  final String buttonId;
  final String deviceId;
  final DeviceType deviceType;
  final DeviceCapability capability;
  final DeviceCommandAction action;
  final String currentState;
  final List<String> availableStates;
  final IconData icon;
  final String displayName;

  const ButtonSpec({
    required this.buttonId,
    required this.deviceId,
    required this.deviceType,
    required this.capability,
    required this.action,
    required this.currentState,
    required this.availableStates,
    required this.icon,
    required this.displayName,
  });

  /// Builds the spec for [device]'s [capability], deriving every field from
  /// the device itself — no manufacturer-specific data involved.
  ///
  /// Throws [ArgumentError] if [device] doesn't actually report [capability]
  /// (checked against [DeviceCapabilities.of]) or the capability has no
  /// button mapping yet (see the `default` branch below) — callers should
  /// only request capabilities a device is known to support, e.g. by
  /// iterating `DeviceCapabilities.of(device)`.
  factory ButtonSpec.forCapability(Device device, DeviceCapability capability) {
    if (!DeviceCapabilities.of(device).contains(capability)) {
      throw ArgumentError(
          'Device ${device.id} does not report capability $capability');
    }

    final (DeviceCommandAction action, String currentState, List<String> states) =
        switch (capability) {
      DeviceCapability.onOff => (
          DeviceCommandAction.onOff,
          device.isOn ? 'on' : 'off',
          const ['on', 'off'],
        ),
      DeviceCapability.lockControl => (
          DeviceCommandAction.lock,
          device.isOn ? 'locked' : 'unlocked',
          const ['locked', 'unlocked'],
        ),
      DeviceCapability.brightness => (
          DeviceCommandAction.brightness,
          '${(device.attributes['brightness'] as num?)?.toInt() ?? 0}',
          const [],
        ),
      DeviceCapability.position => (
          DeviceCommandAction.coverPosition,
          '${DeviceCapabilities.positionOf(device) ?? 0}',
          const [],
        ),
      DeviceCapability.climateControl => (
          DeviceCommandAction.climate,
          device.attributes['mode'] as String? ?? 'off',
          const ['cool', 'heat', 'fan', 'dry', 'auto', 'off'],
        ),
      DeviceCapability.vacuumControl => (
          DeviceCommandAction.vacuum,
          device.isOn ? 'cleaning' : 'docked',
          const ['cleaning', 'paused', 'docked'],
        ),
      _ => throw ArgumentError(
          'Capability $capability has no button mapping yet'),
    };

    return ButtonSpec(
      buttonId: '${device.id}_${capability.name}',
      deviceId: device.id,
      deviceType: device.type,
      capability: capability,
      action: action,
      currentState: currentState,
      availableStates: states,
      icon: DeviceIcons.forDevice(device),
      displayName: device.name,
    );
  }
}
