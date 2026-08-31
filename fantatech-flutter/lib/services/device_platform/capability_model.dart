// ─────────────────────────────────────────────────────────────────────────────
// CapabilityModel — composes the existing DeviceType/attribute-based
// DeviceCapabilities with whatever an adapter additionally declares.
//
// device_capabilities.dart is NOT modified by this file — it stays the
// source of truth for type/attribute-based capability inference exactly as
// it works today. This just gives an adapter (once one exists) a second,
// additive voice in what a device can do.
// ─────────────────────────────────────────────────────────────────────────────
import '../../models/device.dart';
import '../../models/device_capabilities.dart';
import 'device_adapter.dart';

class CapabilityModel {
  CapabilityModel._();

  /// The full set of capabilities [device] supports: everything
  /// [DeviceCapabilities.of] infers, unioned with whatever [adapter]
  /// (if any) additionally declares via [DeviceAdapter.capabilitiesFor].
  static Set<DeviceCapability> resolve(Device device, {DeviceAdapter? adapter}) {
    final base = DeviceCapabilities.of(device);
    if (adapter == null) return base;
    return {...base, ...adapter.capabilitiesFor(device)};
  }
}
