import 'device.dart';
import 'device_capabilities.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeviceState — the single, uniform snapshot of a device's REAL state, per
// the requested shape { deviceId, online, capabilities, properties,
// lastUpdated }. Always built fresh from the live Device via [fromDevice] —
// never cached/held onto by a button after a tap, which is the whole point:
// the UI renders what the device IS right now (AppState's source of truth,
// updated by gateway sync/polling), not "the state I last pressed for".
//
// Rule-9 disclosure: Device has no persisted last-changed timestamp
// anywhere in this project today. [lastUpdated] is therefore the moment
// this snapshot was built, not a tracked "device last reported at" time —
// flagged here rather than faking a real timestamp.
// ─────────────────────────────────────────────────────────────────────────────

class DeviceState {
  final String deviceId;
  final bool online;
  final Set<DeviceCapability> capabilities;
  final Map<String, dynamic> properties;
  final DateTime lastUpdated;

  const DeviceState({
    required this.deviceId,
    required this.online,
    required this.capabilities,
    required this.properties,
    required this.lastUpdated,
  });

  factory DeviceState.fromDevice(Device device) => DeviceState(
        deviceId: device.id,
        online: device.online,
        capabilities: DeviceCapabilities.of(device),
        properties: {
          ...device.attributes,
          'isOn': device.isOn,
          'name': device.name,
          'room': device.room,
        },
        lastUpdated: DateTime.now(),
      );
}
