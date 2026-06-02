// ─────────────────────────────────────────────────────────────────────────────
// BLE Scanner
// Wraps flutter_blue_plus to scan for nearby Bluetooth Low Energy devices.
// Filters for known smart home service UUIDs and advertisement names.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'discovery_models.dart';

/// How long to actively scan for BLE advertisements.
const _scanDuration = Duration(seconds: 10);

/// Known BLE service UUIDs that indicate smart home devices.
/// Source: official Bluetooth SIG + vendor SDKs.
const _knownServiceUuids = {
  // Matter commissioning window
  '0000fff6-0000-1000-8000-00805f9b34fb',
  // Zigbee-over-BLE provisioning (Silicon Labs)
  '0000ffe0-0000-1000-8000-00805f9b34fb',
  // Generic Access Profile — always present, used as fallback
  '00001800-0000-1000-8000-00805f9b34fb',
  // Xiaomi/Aqara Mi-Home BLE
  'fe95',
  // Govee lights
  'ec88',
  // IKEA Tradfri
  'fe59',
  // Shelly BLU
  '1800',
};

/// Name prefixes that strongly suggest smart home hardware.
const _knownNamePrefixes = [
  'sonoff', 'shelly', 'tasmota', 'esp', 'zigbee',
  'ikea', 'tradfri', 'govee', 'xiaomi', 'aqara',
  'hue', 'philips', 'tuya', 'beken', 'matter',
  'tp-link', 'tapo', 'meross', 'kasa',
];

class BLEScanner {
  /// Scans for BLE devices and emits [ScannerEvent]s.
  Stream<ScannerEvent> scan() async* {
    // Check adapter state
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      yield ScannerErrorEvent(
        'BLEScanner',
        'Bluetooth is ${adapterState.name}. Enable it to scan for BLE devices.',
      );
      return;
    }

    final seenIds = <String>{};

    // Start the scan
    try {
      FlutterBluePlus.startScan(
        timeout: _scanDuration,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      yield ScannerErrorEvent('BLEScanner', 'Cannot start scan: $e');
      return;
    }

    // Stream results in real time
    int count = 0;
    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        if (seenIds.contains(r.device.remoteId.str)) continue;
        if (!_isSmartHomeDevice(r)) continue;

        seenIds.add(r.device.remoteId.str);
        count++;

        final device = _toDiscoveredDevice(r);
        yield DeviceFoundEvent(device);
      }

      yield ScannerProgressEvent(
        -1, // indeterminate for BLE
        'BLE: $count device${count == 1 ? '' : 's'} found',
      );
    }

    await FlutterBluePlus.stopScan();
    yield ScannerDoneEvent('BLEScanner');
  }

  /// Returns true if the advertisement looks like smart home hardware.
  bool _isSmartHomeDevice(ScanResult r) {
    final name = (r.advertisementData.advName).toLowerCase();

    // Match by advertisement name prefix
    for (final prefix in _knownNamePrefixes) {
      if (name.startsWith(prefix)) return true;
    }

    // Match by advertised service UUIDs
    for (final svc in r.advertisementData.serviceUuids) {
      final uuidStr = svc.str.toLowerCase();
      for (final known in _knownServiceUuids) {
        if (uuidStr.contains(known.toLowerCase())) return true;
      }
    }

    // Accept any device with RSSI > -80 dBm that has manufacturer data
    // (smart home devices typically broadcast short-range)
    if (r.rssi > -80 &&
        r.advertisementData.manufacturerData.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Converts a flutter_blue_plus [ScanResult] to our [DiscoveredDevice].
  DiscoveredDevice _toDiscoveredDevice(ScanResult r) {
    final advName = r.advertisementData.advName;
    final name = advName.isNotEmpty ? advName : r.device.remoteId.str;
    final mac = r.device.remoteId.str;

    final manufacturer = _resolveManufacturer(r);
    final type = _inferType(r, manufacturer);

    // Collect service UUIDs as strings
    final serviceUuids =
        r.advertisementData.serviceUuids.map((u) => u.str).toList();

    // Manufacturer-specific payload as hex
    final mfData = r.advertisementData.manufacturerData.entries
        .map((e) =>
            '${e.key.toRadixString(16).padLeft(4, '0')}: ${e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}')
        .join(', ');

    return DiscoveredDevice(
      id: 'ble_$mac',
      displayName: name,
      mac: mac,
      type: type,
      protocol: DiscoveryProtocol.ble,
      manufacturer: manufacturer,
      metadata: {
        'rssi': r.rssi,
        'serviceUuids': serviceUuids,
        if (mfData.isNotEmpty) 'manufacturerData': mfData,
        'connectable': r.advertisementData.connectable,
      },
    );
  }

  /// Resolve manufacturer name from known company identifiers (partial list).
  String? _resolveManufacturer(ScanResult r) {
    // First check the name
    final name = r.advertisementData.advName.toLowerCase();
    if (name.contains('sonoff')) return 'ITEAD / Sonoff';
    if (name.contains('shelly')) return 'Shelly';
    if (name.contains('ikea') || name.contains('tradfri')) return 'IKEA';
    if (name.contains('govee')) return 'Govee';
    if (name.contains('xiaomi') || name.contains('aqara')) return 'Xiaomi';
    if (name.contains('hue') || name.contains('philips')) return 'Philips Hue';
    if (name.contains('tuya')) return 'Tuya';
    if (name.contains('tapo') || name.contains('tp-link')) return 'TP-Link';
    if (name.contains('meross') || name.contains('kasa')) return 'Meross';

    // Bluetooth SIG company identifiers (partial)
    final mfKeys = r.advertisementData.manufacturerData.keys;
    for (final key in mfKeys) {
      switch (key) {
        case 0x0006: return 'Microsoft';
        case 0x004C: return 'Apple';
        case 0x0075: return 'Samsung';
        case 0x0087: return 'Garmin';
        case 0x00E0: return 'Google';
        case 0x0171: return 'Amazon';
        case 0x05A7: return 'Sonos';
        case 0x0397: return 'IKEA';
        case 0x0590: return 'Xiaomi';
      }
    }
    return null;
  }

  /// Infer device type from advertisement data.
  DiscoveredDeviceType _inferType(ScanResult r, String? manufacturer) {
    final name = r.advertisementData.advName.toLowerCase();
    if (name.contains('bulb') || name.contains('lamp') || name.contains('light') || name.contains('strip')) {
      return DiscoveredDeviceType.light;
    }
    if (name.contains('plug') || name.contains('socket') || name.contains('outlet')) {
      return DiscoveredDeviceType.socket;
    }
    if (name.contains('thermo') || name.contains('sensor') || name.contains('temp')) {
      return DiscoveredDeviceType.thermostat;
    }
    if (name.contains('cam') || name.contains('camera')) {
      return DiscoveredDeviceType.camera;
    }
    if (name.contains('hub') || name.contains('bridge') || name.contains('gateway')) {
      return DiscoveredDeviceType.gateway;
    }
    if (name.contains('speaker') || name.contains('echo') || name.contains('dot')) {
      return DiscoveredDeviceType.speaker;
    }
    if (manufacturer == 'Philips Hue' || manufacturer == 'IKEA') {
      return DiscoveredDeviceType.light;
    }
    return DiscoveredDeviceType.unknown;
  }
}
