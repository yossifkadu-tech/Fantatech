import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/fantatech_sensor_data.dart';

void main() {
  group('Co2Thresholds.resolveState', () {
    const thresholds = Co2Thresholds(normalMaxPpm: 1000, warningMaxPpm: 2000);

    test('at or below normalMaxPpm resolves to normal', () {
      expect(thresholds.resolveState(742), 'normal');
      expect(thresholds.resolveState(1000), 'normal');
    });

    test('between normalMaxPpm and warningMaxPpm resolves to warning', () {
      expect(thresholds.resolveState(1500), 'warning');
      expect(thresholds.resolveState(2000), 'warning');
    });

    test('above warningMaxPpm resolves to danger', () {
      expect(thresholds.resolveState(2500), 'danger');
    });

    test('thresholds are configurable, not hard-coded', () {
      const strict = Co2Thresholds(normalMaxPpm: 500, warningMaxPpm: 800);
      expect(strict.resolveState(742), 'warning');
      // Same raw ppm reads differently under different configured
      // thresholds — proves the logic isn't baked into a fixed constant.
      expect(thresholds.resolveState(742), 'normal');
    });
  });

  group('FantaTechSensorData', () {
    test('defaults: online, empty unit, no value/battery/lastUpdated', () {
      const data = FantaTechSensorData(
        sensorId: 's1',
        sensorType: FantaTechSensorType.motion,
        sensorName: 'Hallway Motion',
        roomName: 'Hallway',
        state: 'clear',
      );

      expect(data.isOnline, isTrue);
      expect(data.unit, '');
      expect(data.value, isNull);
      expect(data.batteryLevel, isNull);
      expect(data.lastUpdated, isNull);
      expect(data.capabilities, isEmpty);
    });
  });
}
