import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/models/button_spec.dart';
import 'package:fantatech/services/device_platform/device_adapter.dart';

void main() {
  group('ButtonSpec.forCapability', () {
    test('light onOff: on', () {
      final device = Device(
          id: 'light_1', name: 'Kitchen Light', type: DeviceType.light, isOn: true);
      final spec = ButtonSpec.forCapability(device, DeviceCapability.onOff);

      expect(spec.buttonId, 'light_1_onOff');
      expect(spec.deviceId, 'light_1');
      expect(spec.deviceType, DeviceType.light);
      expect(spec.capability, DeviceCapability.onOff);
      expect(spec.action, DeviceCommandAction.onOff);
      expect(spec.currentState, 'on');
      expect(spec.availableStates, ['on', 'off']);
      expect(spec.displayName, 'Kitchen Light');
    });

    test('switch onOff: off', () {
      final device = Device(
          id: 'switch_1', name: 'Hallway Switch', type: DeviceType.smartSwitch);
      final spec = ButtonSpec.forCapability(device, DeviceCapability.onOff);

      expect(spec.currentState, 'off');
      expect(spec.action, DeviceCommandAction.onOff);
    });

    test('lock: reports locked/unlocked, not on/off', () {
      final device =
          Device(id: 'lock_1', name: 'Front Door', type: DeviceType.smartLock, isOn: true);
      final spec = ButtonSpec.forCapability(device, DeviceCapability.lockControl);

      expect(spec.action, DeviceCommandAction.lock);
      expect(spec.currentState, 'locked');
      expect(spec.availableStates, ['locked', 'unlocked']);
    });

    test('brightness: current level read from attributes', () {
      final device = Device(
          id: 'light_2', name: 'Bedroom Lamp', type: DeviceType.light,
          isOn: true, attributes: {'brightness': 60});
      final spec = ButtonSpec.forCapability(device, DeviceCapability.brightness);

      expect(spec.action, DeviceCommandAction.brightness);
      expect(spec.currentState, '60');
    });

    test('throws when the device does not report the requested capability', () {
      final device =
          Device(id: 'sensor_1', name: 'Motion', type: DeviceType.motionSensor);

      expect(() => ButtonSpec.forCapability(device, DeviceCapability.onOff),
          throwsArgumentError);
    });
  });
}
