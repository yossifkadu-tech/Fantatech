import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/models/button_spec.dart';
import 'package:fantatech/models/button_executor.dart';

void main() {
  group('ButtonExecutor.resolveOnOffTarget — smart switch ON/OFF/TOGGLE', () {
    test('ON always targets true, regardless of current state', () {
      final off = Device(id: 's1', name: 'Switch', type: DeviceType.smartSwitch, isOn: false);
      final on = Device(id: 's1', name: 'Switch', type: DeviceType.smartSwitch, isOn: true);
      final specOff = ButtonSpec.forCapability(off, DeviceCapability.onOff);
      final specOn = ButtonSpec.forCapability(on, DeviceCapability.onOff);

      expect(ButtonExecutor.resolveOnOffTarget(specOff, explicitState: 'on'), isTrue);
      expect(ButtonExecutor.resolveOnOffTarget(specOn, explicitState: 'on'), isTrue);
    });

    test('OFF always targets false, regardless of current state', () {
      final on = Device(id: 's1', name: 'Switch', type: DeviceType.smartSwitch, isOn: true);
      final spec = ButtonSpec.forCapability(on, DeviceCapability.onOff);

      expect(ButtonExecutor.resolveOnOffTarget(spec, explicitState: 'off'), isFalse);
    });

    test('TOGGLE flips the current state', () {
      final on = Device(id: 's1', name: 'Switch', type: DeviceType.smartSwitch, isOn: true);
      final off = Device(id: 's2', name: 'Switch', type: DeviceType.smartSwitch, isOn: false);

      expect(
          ButtonExecutor.resolveOnOffTarget(
              ButtonSpec.forCapability(on, DeviceCapability.onOff)),
          isFalse);
      expect(
          ButtonExecutor.resolveOnOffTarget(
              ButtonSpec.forCapability(off, DeviceCapability.onOff)),
          isTrue);
    });
  });
}
