import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/models/device_state.dart';

void main() {
  group('DeviceState.fromDevice', () {
    test('reflects the device\'s real current state, not a cached press', () {
      final device = Device(
          id: 'light_1', name: 'Kitchen Light', type: DeviceType.light,
          isOn: true, room: 'Kitchen');
      final snapshot = DeviceState.fromDevice(device);

      expect(snapshot.deviceId, 'light_1');
      expect(snapshot.online, isTrue);
      expect(snapshot.properties['isOn'], isTrue);
      expect(snapshot.capabilities, DeviceCapabilities.of(device));
    });

    test('online reflects DeviceStatus.offline, not a UI-only flag', () {
      final device = Device(
          id: 'light_2', name: 'Offline Light', type: DeviceType.light,
          status: DeviceStatus.offline);
      final snapshot = DeviceState.fromDevice(device);

      expect(snapshot.online, isFalse);
    });

    test('two snapshots of the same mutated device differ — never stale', () {
      final device = Device(id: 'plug_1', name: 'Plug', type: DeviceType.smartPlug);

      final before = DeviceState.fromDevice(device);
      expect(before.properties['isOn'], isFalse);

      device.isOn = true;
      final after = DeviceState.fromDevice(device);
      expect(after.properties['isOn'], isTrue);
    });
  });
}
