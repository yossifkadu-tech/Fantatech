import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/device_capabilities.dart';
import 'package:fantatech/services/device_platform/device_adapter.dart';
import 'package:fantatech/services/device_platform/adapter_registry.dart';
import 'package:fantatech/services/device_platform/capability_model.dart';

/// Minimal fake adapter for testing the registry in isolation — matches
/// devices whose id starts with 'fake_', same pattern a real adapter would
/// use during migration of a brand still on the legacy prefix convention.
class _FakeAdapter implements DeviceAdapter {
  @override
  String get id => 'fake';

  @override
  bool canHandle(Device device) => device.id.startsWith('fake_');

  @override
  Future<bool> testConnection(Map<String, String> credentials) async => true;

  @override
  Future<List<Device>> importDevices(Map<String, String> credentials) async => [];

  @override
  Future<bool> execute(Device device, DeviceCommand command) async => true;

  @override
  Set<DeviceCapability> capabilitiesFor(Device device) => {DeviceCapability.onOff};
}

void main() {
  group('DeviceAdapterRegistry', () {
    test('adapterFor matches a device the adapter can handle', () {
      final registry = DeviceAdapterRegistry();
      registry.register(_FakeAdapter());

      final device = Device(id: 'fake_1', name: 'Fake Plug', type: DeviceType.smartPlug);
      final adapter = registry.adapterFor(device);

      expect(adapter, isNotNull);
      expect(adapter!.id, 'fake');
    });

    test('adapterFor returns null for a device no registered adapter can handle', () {
      final registry = DeviceAdapterRegistry();
      registry.register(_FakeAdapter());

      final device = Device(id: 'other_1', name: 'Other Plug', type: DeviceType.smartPlug);

      expect(registry.adapterFor(device), isNull);
    });

    test('unregister removes an adapter from lookup', () {
      final registry = DeviceAdapterRegistry();
      registry.register(_FakeAdapter());
      registry.unregister('fake');

      final device = Device(id: 'fake_1', name: 'Fake Plug', type: DeviceType.smartPlug);

      expect(registry.adapterFor(device), isNull);
      expect(registry.all, isEmpty);
    });
  });

  group('CapabilityModel resolve', () {
    test('adapter-declared capabilities are included in the resolved set', () {
      final device = Device(id: 'fake_1', name: 'Fake Plug', type: DeviceType.smartPlug);
      final resolved = CapabilityModel.resolve(device, adapter: _FakeAdapter());

      expect(resolved.contains(DeviceCapability.onOff), isTrue);
    });

    test('with no adapter, resolve matches DeviceCapabilities.of directly', () {
      final device = Device(id: 'plain_1', name: 'Plain Plug', type: DeviceType.smartPlug);

      expect(CapabilityModel.resolve(device), DeviceCapabilities.of(device));
    });
  });
}
