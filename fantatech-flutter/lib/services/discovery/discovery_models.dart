// ─────────────────────────────────────────────────────────────────────────────
// Discovery Models
// Shared data types used by every scanner and the DiscoveryManager.
// ─────────────────────────────────────────────────────────────────────────────

/// High-level category of a discovered device.
enum DiscoveredDeviceType {
  light,
  socket,
  smartSwitch,
  thermostat,
  camera,
  gateway,        // Zigbee / WiFi hub/bridge
  boiler,         // Water heater
  solar,
  circuitBreaker,
  energyMeter,    // Shelly EM, Modbus meters
  smokeSensor,    // Smoke / fire detector
  motionSensor,   // PIR motion
  windowSensor,   // Window / door contact
  doorSensor,     // Door sensor
  sensor,         // Generic sensor
  speaker,
  tv,
  router,
  unknown,
}

/// Transport protocol over which the device was found.
enum DiscoveryProtocol {
  wifi,     // TCP/IP LAN scan
  ble,      // Bluetooth Low Energy
  matter,   // Matter / Thread (mDNS _matter._tcp)
  zigbee,   // Zigbee coordinator reported device
  zwave,    // Z-Wave controller reported device
  unknown,
}

/// Status of a discovery run.
enum DiscoveryStatus { idle, scanning, done, error }

// ─────────────────────────────────────────────────────────────────────────────
// DiscoveredDevice
// ─────────────────────────────────────────────────────────────────────────────
class DiscoveredDevice {
  /// Stable unique key: IP for WiFi/Matter, MAC hex for BLE.
  final String id;
  final String displayName;

  /// IP address (null for BLE-only devices).
  final String? ip;

  /// MAC address or BLE device id.
  final String? mac;

  final DiscoveredDeviceType type;
  final DiscoveryProtocol protocol;

  /// Brand / vendor string, e.g. "Sonoff", "TP-Link", "Philips Hue".
  final String? manufacturer;

  /// Model string from HTTP headers, mDNS TXT record, or BLE advertisement.
  final String? model;

  /// Open ports found on this host (WiFi scan only).
  final List<int> openPorts;

  /// Free-form key-value bag: RSSI, mDNS service name, BLE UUIDs, etc.
  final Map<String, dynamic> metadata;

  final DateTime discoveredAt;

  /// True once the user has added this device to their home.
  bool isRegistered;

  DiscoveredDevice({
    required this.id,
    required this.displayName,
    this.ip,
    this.mac,
    required this.type,
    required this.protocol,
    this.manufacturer,
    this.model,
    this.openPorts = const [],
    this.metadata = const {},
    DateTime? discoveredAt,
    this.isRegistered = false,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  DiscoveredDevice copyWith({
    String? displayName,
    DiscoveredDeviceType? type,
    String? manufacturer,
    String? model,
    List<int>? openPorts,
    Map<String, dynamic>? metadata,
    bool? isRegistered,
  }) {
    return DiscoveredDevice(
      id: id,
      displayName: displayName ?? this.displayName,
      ip: ip,
      mac: mac,
      type: type ?? this.type,
      protocol: protocol,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      openPorts: openPorts ?? this.openPorts,
      metadata: metadata ?? this.metadata,
      discoveredAt: discoveredAt,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  @override
  String toString() =>
      'DiscoveredDevice($displayName, $protocol, ${ip ?? mac})';
}

// ─────────────────────────────────────────────────────────────────────────────
// ScannerEvent — emitted by individual scanners into the manager's stream.
// ─────────────────────────────────────────────────────────────────────────────
sealed class ScannerEvent {}

class DeviceFoundEvent extends ScannerEvent {
  final DiscoveredDevice device;
  DeviceFoundEvent(this.device);
}

class ScannerProgressEvent extends ScannerEvent {
  /// 0.0 – 1.0
  final double progress;
  final String message;
  ScannerProgressEvent(this.progress, this.message);
}

class ScannerErrorEvent extends ScannerEvent {
  final String source;
  final String message;
  ScannerErrorEvent(this.source, this.message);
}

class ScannerDoneEvent extends ScannerEvent {
  final String source;
  ScannerDoneEvent(this.source);
}
