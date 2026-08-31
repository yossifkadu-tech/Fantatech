// ─────────────────────────────────────────────────────────────────────────────
// DeviceAdapterRegistry — in-memory lookup from a Device to the DeviceAdapter
// that should handle it.
//
// STATUS: nothing calls `register()` from app startup yet, and no existing
// screen or service consults this registry — it starts empty and stays
// empty until a future phase migrates a specific brand onto it. That's what
// makes this phase risk-free: the registry exists, but the app's runtime
// behavior is unchanged because nothing is registered.
// ─────────────────────────────────────────────────────────────────────────────
import '../../models/device.dart';
import 'device_adapter.dart';

class DeviceAdapterRegistry {
  final Map<String, DeviceAdapter> _adapters = {};

  /// Registers [adapter], replacing any existing adapter with the same id.
  void register(DeviceAdapter adapter) {
    _adapters[adapter.id] = adapter;
  }

  /// Removes the adapter registered under [id], if any.
  void unregister(String id) {
    _adapters.remove(id);
  }

  /// The first registered adapter that reports it can handle [device], or
  /// null if none does — callers should fall back to legacy dispatch logic
  /// in that case, not treat it as an error.
  DeviceAdapter? adapterFor(Device device) {
    for (final adapter in _adapters.values) {
      if (adapter.canHandle(device)) return adapter;
    }
    return null;
  }

  /// All currently registered adapters.
  List<DeviceAdapter> get all => _adapters.values.toList(growable: false);
}
