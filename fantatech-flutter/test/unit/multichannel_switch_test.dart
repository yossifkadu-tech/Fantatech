import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/models/button_spec.dart';
import 'package:fantatech/models/button_executor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Proves channel independence for a multi-gang switch, per the requested
// device_id=switch_01 / channel_1 / channel_2 example. No new production
// code needed for this: the app already registers each physical channel as
// its own Device (id suffixed '_ch<index>' — see
// smart_switch_hub_screen.dart's _findRegisteredDevice), so ButtonSpec and
// ButtonExecutor — both built per-Device — already treat each channel as a
// fully separate button with no shared mutable state.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Multi-channel switch — each channel independent', () {
    test('channel_1 and channel_2 of switch_01 get distinct button_ids', () {
      final channel1 = Device(
          id: 'switch_01_ch0', name: 'Living Room Light A',
          type: DeviceType.smartSwitch, isOn: true);
      final channel2 = Device(
          id: 'switch_01_ch1', name: 'Living Room Light B',
          type: DeviceType.smartSwitch, isOn: false);

      final spec1 = ButtonSpec.forCapability(channel1, DeviceCapability.onOff);
      final spec2 = ButtonSpec.forCapability(channel2, DeviceCapability.onOff);

      expect(spec1.buttonId, isNot(spec2.buttonId));
      expect(spec1.deviceId, 'switch_01_ch0');
      expect(spec2.deviceId, 'switch_01_ch1');
      expect(spec1.currentState, 'on');
      expect(spec2.currentState, 'off');
    });

    test('resolving TOGGLE for channel_1 never reads or affects channel_2', () {
      final channel1 = Device(
          id: 'switch_01_ch0', name: 'Ch1', type: DeviceType.smartSwitch, isOn: true);
      final channel2 = Device(
          id: 'switch_01_ch1', name: 'Ch2', type: DeviceType.smartSwitch, isOn: false);

      final spec1Before = ButtonSpec.forCapability(channel1, DeviceCapability.onOff);
      final spec2Before = ButtonSpec.forCapability(channel2, DeviceCapability.onOff);

      final channel1Target = ButtonExecutor.resolveOnOffTarget(spec1Before);
      expect(channel1Target, isFalse); // toggled on -> off

      // channel2's own device/spec is untouched by resolving channel1's toggle
      expect(channel2.isOn, isFalse);
      final spec2After = ButtonSpec.forCapability(channel2, DeviceCapability.onOff);
      expect(spec2After.currentState, spec2Before.currentState);
    });
  });
}
