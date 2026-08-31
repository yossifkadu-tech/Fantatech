// ─────────────────────────────────────────────────────────────────────────────
// DeviceAdapter — the contract a brand/protocol implements ONCE to plug into
// the Multi-Brand Device Platform.
//
// STATUS: scaffold only. Nothing in the app constructs, registers, or calls
// a DeviceAdapter yet. `DeviceCommander` and `GatewayManager` are untouched
// and remain fully authoritative for every brand today.
//
// MIGRATION STRATEGY (for whoever does the next phase):
//   A brand is migrated by (1) writing a DeviceAdapter implementation that
//   wraps its existing client class (e.g. IRobotClient), (2) registering it
//   with DeviceAdapterRegistry at app startup, and (3) adding ONE check at
//   the top of the relevant DeviceCommander method:
//
//     final adapter = registry.adapterFor(device);
//     if (adapter != null) return adapter.execute(device, command);
//     // ...existing brand-prefix chain, unchanged, as the fallback...
//
//   Every other brand's existing `if (id.startsWith(...))` branch keeps
//   working exactly as before until it is migrated the same way. Migrating
//   one brand never risks another.
// ─────────────────────────────────────────────────────────────────────────────
import '../../models/device.dart';
import '../../models/device_capabilities.dart';

/// The action a [DeviceCommand] asks an adapter to perform.
///
/// Mirrors the methods `DeviceCommander` currently exposes as separate
/// functions (`setOnOff`, `setBrightness`, `setClimate`, `setCoverPosition`,
/// `stopCover`, `vacuumCommand`) — unified here into one dispatch surface so
/// an adapter implements a single `execute()` instead of six methods.
enum DeviceCommandAction {
  onOff,
  brightness,
  climate,
  coverPosition,
  stopCover,
  vacuum,
  lock,
}

/// A single command to send to a device, produced by whatever UI or
/// automation triggered it and consumed by `DeviceAdapter.execute()`.
///
/// [params] carries the action-specific payload, e.g. `{'on': true}` for
/// [DeviceCommandAction.onOff], `{'level': 60}` for
/// [DeviceCommandAction.brightness], `{'action': 'start'}` for
/// [DeviceCommandAction.vacuum].
class DeviceCommand {
  final DeviceCommandAction action;
  final Map<String, dynamic> params;

  const DeviceCommand(this.action, [this.params = const {}]);
}

/// Result of a connect/pairing attempt — deliberately small; adapters that
/// need richer state (pairing progress, countdown, etc.) can still expose it
/// through their own class, this is just what the registry/UI needs.
class AdapterConnectResult {
  final bool success;
  final String? error;

  const AdapterConnectResult.ok() : success = true, error = null;
  const AdapterConnectResult.fail(this.error) : success = false;
}

/// The contract a brand/protocol implements to plug into the platform.
///
/// Implementations should be thin wrappers around the brand's existing
/// client class (e.g. `IRobotClient`, `TuyaCloudClient`) — this interface
/// does not replace that client code, it gives it one uniform front door.
abstract class DeviceAdapter {
  /// Stable identifier for this adapter, e.g. `'irobot'`, `'tuya'`.
  /// Used as the [DeviceAdapterRegistry] map key.
  String get id;

  /// Whether this adapter is the right one to handle [device] — typically
  /// an `attributes['adapterId'] == id` check for devices imported by this
  /// adapter, or (during migration of a brand with existing devices already
  /// stored under the legacy `id` prefix convention) a prefix check.
  bool canHandle(Device device);

  /// Verifies [credentials] are valid and the brand's service is reachable.
  /// Never throws — returns false on any failure.
  Future<bool> testConnection(Map<String, String> credentials);

  /// Fetches the devices available under [credentials] as [Device]s ready
  /// to store. Never throws — returns an empty list on failure.
  Future<List<Device>> importDevices(Map<String, String> credentials);

  /// Sends [command] to [device]. Returns true on success, never throws.
  Future<bool> execute(Device device, DeviceCommand command);

  /// The capabilities this adapter knows [device] supports, beyond what
  /// [DeviceCapabilities.of] can infer from `DeviceType` and attributes
  /// alone. Merged by [CapabilityModel.resolve] — see capability_model.dart.
  Set<DeviceCapability> capabilitiesFor(Device device);
}
