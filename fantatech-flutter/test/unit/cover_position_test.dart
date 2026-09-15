import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/models/button_spec.dart';
import 'package:fantatech/services/device_platform/device_adapter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cover/blind position — a continuous 0-100 range instead of a fixed set of
// named states, unlike onOff's ['on','off']. ButtonExecutor.execute already
// clamps to 0-100 before calling AppState.agentSetCoverPosition (see
// button_executor.dart) — this only proves ButtonSpec reads the position
// correctly, using the same [DeviceCapabilities.positionOf] helper the rest
// of the app already relies on (HA writes 'blindLevel', local/manual writes
// 'position' — both keys are handled there, not duplicated here).
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ButtonSpec.forCapability — position (0-100)', () {
    test('reads current position from attributes', () {
      final device = Device(
          id: 'blind_1', name: 'Living Room Blind', type: DeviceType.blind,
          attributes: {'position': 40});
      final spec = ButtonSpec.forCapability(device, DeviceCapability.position);

      expect(spec.action, DeviceCommandAction.coverPosition);
      expect(spec.currentState, '40');
      // Continuous range, not a fixed set of named states like onOff.
      expect(spec.availableStates, isEmpty);
    });

    test('falls back to blindLevel (HA-synced devices) when position is absent', () {
      final device = Device(
          id: 'blind_2', name: 'HA Blind', type: DeviceType.blind,
          attributes: {'blindLevel': 75});
      final spec = ButtonSpec.forCapability(device, DeviceCapability.position);

      expect(spec.currentState, '75');
    });

    test('defaults to 0 when no position has ever been reported', () {
      final device = Device(id: 'blind_3', name: 'New Blind', type: DeviceType.blind);
      final spec = ButtonSpec.forCapability(device, DeviceCapability.position);

      expect(spec.currentState, '0');
    });
  });
}
