import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/models/sensor_state_spec.dart';

void main() {
  group('SensorStateSpec.forCapability — binary sensors', () {
    test('water_leak reports "detected" when the leak attribute is true', () {
      final device = Device(
          id: 'leak_1', name: 'Kitchen Leak Sensor', type: DeviceType.waterLeakSensor,
          attributes: {'water_leak': true});
      final spec = SensorStateSpec.forCapability(device, DeviceCapability.binaryState);

      expect(spec.state, 'detected');
    });

    test('water_leak reports "clear" when no leak is present', () {
      final device = Device(
          id: 'leak_2', name: 'Bathroom Leak Sensor', type: DeviceType.waterLeakSensor,
          attributes: {'water_leak': false});
      final spec = SensorStateSpec.forCapability(device, DeviceCapability.binaryState);

      expect(spec.state, 'clear');
    });

    test('motion reports detected/clear', () {
      final on = Device(id: 'm1', name: 'Hallway Motion', type: DeviceType.motionSensor,
          attributes: {'detected': true});
      final off = Device(id: 'm2', name: 'Hallway Motion', type: DeviceType.motionSensor,
          attributes: {'detected': false});

      expect(SensorStateSpec.forCapability(on, DeviceCapability.binaryState).state, 'detected');
      expect(SensorStateSpec.forCapability(off, DeviceCapability.binaryState).state, 'clear');
    });

    test('door and window report open/closed, not detected/clear', () {
      final door = Device(id: 'd1', name: 'Front Door', type: DeviceType.doorSensor,
          attributes: {'open': true});
      final window = Device(id: 'w1', name: 'Kitchen Window', type: DeviceType.windowSensor,
          attributes: {'open': false});

      expect(SensorStateSpec.forCapability(door, DeviceCapability.binaryState).state, 'open');
      expect(SensorStateSpec.forCapability(window, DeviceCapability.binaryState).state, 'closed');
    });
  });

  group('SensorStateSpec.forCapability — readings', () {
    test('temperature reads value + °C unit', () {
      final device = Device(id: 't1', name: 'Living Room Sensor', type: DeviceType.motionSensor,
          attributes: {'detected': false, 'temperature': 22.5});
      final spec = SensorStateSpec.forCapability(device, DeviceCapability.temperature);

      expect(spec.state, '22.5');
      expect(spec.unit, '°C');
    });

    test('humidity reads value + % unit', () {
      final device = Device(id: 'h1', name: 'Living Room Sensor', type: DeviceType.motionSensor,
          attributes: {'detected': false, 'humidity': 55});
      final spec = SensorStateSpec.forCapability(device, DeviceCapability.humidity);

      expect(spec.state, '55');
      expect(spec.unit, '%');
    });
  });

  test('throws when the device does not report the requested capability', () {
    final device = Device(id: 'plug_1', name: 'Plug', type: DeviceType.smartPlug);

    expect(() => SensorStateSpec.forCapability(device, DeviceCapability.binaryState),
        throwsArgumentError);
  });
}
