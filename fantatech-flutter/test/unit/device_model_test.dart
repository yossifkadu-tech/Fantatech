import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';

void main() {
  // ── Device constructor ────────────────────────────────────────────────────

  group('Device constructor', () {
    test('defaults: online, isOn=false, empty room', () {
      final d = Device(id: '1', name: 'Bulb', type: DeviceType.light);
      expect(d.status, DeviceStatus.online);
      expect(d.isOn, isFalse);
      expect(d.room, '');
    });

    test('battery extracted from attributes when not passed directly', () {
      final d = Device(
        id: '2',
        name: 'Sensor',
        type: DeviceType.motionSensor,
        attributes: {'battery': 72},
      );
      expect(d.battery, 72);
    });

    test('explicit battery overrides attributes value', () {
      final d = Device(
        id: '3',
        name: 'Sensor',
        type: DeviceType.motionSensor,
        battery: 55,
        attributes: {'battery': 99},
      );
      expect(d.battery, 55);
    });

    test('battery is null when attribute missing and not supplied', () {
      final d = Device(id: '4', name: 'Light', type: DeviceType.light);
      expect(d.battery, isNull);
    });
  });

  // ── online getter / setter ────────────────────────────────────────────────

  group('Device.online', () {
    test('online=true sets status to online', () {
      final d = Device(id: '5', name: 'X', type: DeviceType.light,
          status: DeviceStatus.offline);
      d.online = true;
      expect(d.status, DeviceStatus.online);
    });

    test('online=false sets status to offline', () {
      final d = Device(id: '6', name: 'X', type: DeviceType.light);
      d.online = false;
      expect(d.status, DeviceStatus.offline);
    });
  });

  // ── JSON round-trip ───────────────────────────────────────────────────────

  group('Device.toJson / fromJson', () {
    test('round-trips all fields', () {
      final original = Device(
        id: 'abc',
        name: 'Living Room Light',
        type: DeviceType.light,
        status: DeviceStatus.offline,
        isOn: true,
        attributes: {'brightness': 80, 'colorTemp': 4000},
        room: 'living',
        battery: 42,
      );

      final json = original.toJson();
      final restored = Device.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.status, original.status);
      expect(restored.isOn, original.isOn);
      expect(restored.room, original.room);
      expect(restored.battery, original.battery);
      expect(restored.attributes['brightness'], 80);
    });

    test('fromJson handles unknown type gracefully → smartPlug fallback', () {
      final d = Device.fromJson({
        'id': 'x',
        'name': 'Unknown',
        'type': 'totally_unknown_type',
        'status': 'online',
        'isOn': false,
        'battery': null,
        'attributes': {},
        'room': '',
      });
      expect(d.type, DeviceType.smartPlug);
    });

    test('fromJson handles unknown status gracefully → online fallback', () {
      final d = Device.fromJson({
        'id': 'x',
        'name': 'X',
        'type': 'light',
        'status': 'totally_unknown',
        'isOn': false,
        'battery': null,
        'attributes': {},
        'room': '',
      });
      expect(d.status, DeviceStatus.online);
    });

    test('fromJson handles missing attributes key', () {
      final d = Device.fromJson({
        'id': 'x',
        'name': 'X',
        'type': 'light',
        'status': 'online',
        'isOn': false,
        'battery': null,
        'room': '',
      });
      expect(d.attributes, isEmpty);
    });
  });

  // ── _typeFromString (via fromSmartDevice) ─────────────────────────────────

  group('Device._typeFromString', () {
    void _typeCase(String rawType, DeviceType expected) {
      test('"$rawType" → ${expected.name}', () {
        expect(Device.fromSmartDevice(_fakeDevice(rawType)).type, expected);
      });
    }

    _typeCase('bulb',         DeviceType.light);
    _typeCase('LIGHT',        DeviceType.light);
    _typeCase('blind',        DeviceType.blind);
    _typeCase('curtain',      DeviceType.blind);
    _typeCase('climate',      DeviceType.airConditioner);
    _typeCase('socket',       DeviceType.smartPlug);
    _typeCase('switch',       DeviceType.smartSwitch);
    _typeCase('motion',       DeviceType.motionSensor);
    _typeCase('contact',      DeviceType.doorSensor);
    _typeCase('window',       DeviceType.windowSensor);
    _typeCase('smoke',        DeviceType.smokeSensor);
    _typeCase('leak',         DeviceType.waterLeakSensor);
    _typeCase('lock',         DeviceType.smartLock);
    _typeCase('matter',       DeviceType.matterDevice);
    _typeCase('completely_unknown', DeviceType.smartPlug);
  });
}

// ── Test helper ───────────────────────────────────────────────────────────────

SmartDevice _fakeDevice(String type) => SmartDevice(
  id: 'test', name: 'Test', room: '', type: type, online: true, battery: -1,
);
