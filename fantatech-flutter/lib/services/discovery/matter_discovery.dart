// ─────────────────────────────────────────────────────────────────────────────
// Matter Discovery
// Uses mDNS (multicast DNS) to find Matter-compliant devices on the LAN.
// Matter devices advertise via:
//   _matter._tcp.local         – commissioned devices
//   _matterc._udp.local        – devices in commissioning window
//   _matterd._tcp.local        – Matter bridge/coordinator
// Also detects Homekit (_hap._tcp), Google Home Cast (_googlecast._tcp),
// and Amazon Echo (_amzn-alexa._tcp) as they share the LAN fabric.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import 'discovery_models.dart';

/// mDNS service types we listen for.
const _serviceTypes = [
  '_matter._tcp.local',
  '_matterc._udp.local',
  '_matterd._tcp.local',
  '_hap._tcp.local',         // Apple HomeKit (often bridges to Matter)
  '_esphomelib._tcp.local',  // ESPHome — very common in DIY setups
  '_http._tcp.local',        // Generic — many smart devices register here
  '_mqtt._tcp.local',        // MQTT brokers / Zigbee2MQTT
];

/// How long to listen for mDNS responses per service type.
const _queryTimeoutMs = 2000;

class MatterDiscovery {
  /// Scan the multicast DNS namespace for Matter + related services.
  Stream<ScannerEvent> scan() async* {
    final client = MDnsClient(
      rawDatagramSocketFactory: (dynamic host, int port,
              {bool reuseAddress = true,
              bool reusePort = true,
              int ttl = 255}) =>
          RawDatagramSocket.bind(host, port,
              reuseAddress: reuseAddress, reusePort: reusePort, ttl: ttl),
    );

    try {
      await client.start();
    } catch (e) {
      yield ScannerErrorEvent('MatterDiscovery', 'Cannot start mDNS: $e');
      return;
    }

    int foundCount = 0;

    for (final serviceType in _serviceTypes) {
      yield ScannerProgressEvent(
        _serviceTypes.indexOf(serviceType) / _serviceTypes.length,
        'mDNS: probing $serviceType',
      );

      try {
        await for (final PtrResourceRecord ptr in client
            .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(serviceType),
            )
            .timeout(
              const Duration(milliseconds: _queryTimeoutMs),
              onTimeout: (sink) => sink.close(),
            )) {
          // For each PTR record, look up the SRV + TXT records.
          final instanceName = ptr.domainName;

          String? host;
          int? port;
          Map<String, String> txtData = {};

          // SRV record → host + port
          await for (final SrvResourceRecord srv in client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(instanceName),
              )
              .timeout(
                const Duration(milliseconds: 500),
                onTimeout: (sink) => sink.close(),
              )) {
            host = srv.target;
            port = srv.port;
            break;
          }

          // TXT record → metadata key=value pairs
          await for (final TxtResourceRecord txt in client
              .lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(instanceName),
              )
              .timeout(
                const Duration(milliseconds: 500),
                onTimeout: (sink) => sink.close(),
              )) {
            for (final entry in txt.text.split('\n')) {
              final idx = entry.indexOf('=');
              if (idx > 0) {
                txtData[entry.substring(0, idx)] = entry.substring(idx + 1);
              }
            }
            break;
          }

          // Resolve hostname → IP
          String? ip;
          if (host != null) {
            await for (final IPAddressResourceRecord a in client
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(host),
                )
                .timeout(
                  const Duration(milliseconds: 500),
                  onTimeout: (sink) => sink.close(),
                )) {
              ip = a.address.address;
              break;
            }
          }

          foundCount++;

          final device = _buildDevice(
            instanceName: instanceName,
            serviceType: serviceType,
            ip: ip,
            port: port,
            txtData: txtData,
          );

          yield DeviceFoundEvent(device);
        }
      } catch (_) {
        // Per-service-type errors are non-fatal; continue with next type.
      }
    }

    client.stop();

    yield ScannerProgressEvent(1.0, 'mDNS: $foundCount device(s) found');
    yield ScannerDoneEvent('MatterDiscovery');
  }

  DiscoveredDevice _buildDevice({
    required String instanceName,
    required String serviceType,
    String? ip,
    int? port,
    required Map<String, String> txtData,
  }) {
    // Derive a human-readable name from the instance name.
    // Instance names look like: "Sonoff-Basic-123456._matter._tcp.local"
    final rawName = instanceName.split('.').first;
    final displayName = rawName.replaceAll('-', ' ').trim();

    final protocol = _protocolForService(serviceType);
    final type = _typeFromTxt(txtData, displayName);
    final manufacturer = _manufacturerFromTxt(txtData, displayName);

    return DiscoveredDevice(
      id: 'mdns_${ip ?? instanceName}',
      displayName: displayName,
      ip: ip,
      type: type,
      protocol: protocol,
      manufacturer: manufacturer,
      model: txtData['md'] ?? txtData['model'],
      metadata: {
        'serviceType': serviceType,
        if (port != null) 'port': port,
        ...txtData,
      },
    );
  }

  DiscoveryProtocol _protocolForService(String serviceType) {
    if (serviceType.contains('matter') || serviceType.contains('matterc')) {
      return DiscoveryProtocol.matter;
    }
    if (serviceType.contains('hap')) return DiscoveryProtocol.wifi;
    return DiscoveryProtocol.wifi;
  }

  /// Matter TXT record keys:
  ///   D = discriminator, CM = commissioning mode, DT = device type (uint16),
  ///   DN = device name, VP = vendor/product IDs, SII/SAI = intervals.
  DiscoveredDeviceType _typeFromTxt(
      Map<String, String> txt, String name) {
    // Matter device type hint from DT field (CSA spec Table 2)
    final dtStr = txt['DT'];
    if (dtStr != null) {
      final dt = int.tryParse(dtStr);
      if (dt != null) {
        // Only the most common types listed here
        if (dt == 0x0100 || dt == 0x0101) return DiscoveredDeviceType.light;
        if (dt == 0x010A) return DiscoveredDeviceType.socket;
        if (dt == 0x000E) return DiscoveredDeviceType.thermostat;
        if (dt == 0x0302) return DiscoveredDeviceType.camera;
        if (dt == 0x0011) return DiscoveredDeviceType.gateway;
        if (dt == 0x0015) return DiscoveredDeviceType.gateway; // Bridge
      }
    }

    // Fallback: infer from name
    final n = name.toLowerCase();
    if (n.contains('light') || n.contains('bulb') || n.contains('lamp')) {
      return DiscoveredDeviceType.light;
    }
    if (n.contains('plug') || n.contains('socket')) {
      return DiscoveredDeviceType.socket;
    }
    if (n.contains('thermo') || n.contains('sensor')) {
      return DiscoveredDeviceType.thermostat;
    }
    if (n.contains('bridge') || n.contains('hub') || n.contains('gateway')) {
      return DiscoveredDeviceType.gateway;
    }
    if (n.contains('cam')) return DiscoveredDeviceType.camera;

    return DiscoveredDeviceType.unknown;
  }

  String? _manufacturerFromTxt(Map<String, String> txt, String name) {
    // VP field: "VENDORID+PRODUCTID" hex — see CSA assigned numbers
    final vp = txt['VP'];
    if (vp != null) {
      final vendorId = int.tryParse(vp.split('+').first);
      if (vendorId != null) {
        // Partial CSA vendor list
        const vendors = {
          0x1037: 'Espressif',
          0x10F2: 'Tuya',
          0x1217: 'Sonoff',
          0x1049: 'Signify (Philips Hue)',
          0x117C: 'IKEA',
          0x1135: 'TP-Link',
          0x1257: 'Shelly',
          0x1321: 'Xiaomi',
        };
        if (vendors.containsKey(vendorId)) return vendors[vendorId];
      }
    }

    final n = name.toLowerCase();
    if (n.contains('sonoff')) return 'Sonoff';
    if (n.contains('shelly')) return 'Shelly';
    if (n.contains('ikea') || n.contains('tradfri')) return 'IKEA';
    if (n.contains('hue') || n.contains('philips')) return 'Philips Hue';
    if (n.contains('tapo') || n.contains('tp-link')) return 'TP-Link';
    if (n.contains('xiaomi') || n.contains('aqara')) return 'Xiaomi';
    if (n.contains('esp') || n.contains('esphome')) return 'Espressif';

    return null;
  }
}
