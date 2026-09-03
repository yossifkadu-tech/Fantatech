// ─────────────────────────────────────────────────────────────────────────────
// BTHome v2 decoder
//
// BTHome (https://bthome.io) is an open, vendor-neutral BLE broadcast format
// for sensor/button data — no pairing, no GATT connection, no per-vendor
// protocol. Devices just broadcast their current readings in an advertisement
// packet under service UUID 0xFCD2; anyone listening can decode them.
//
// Shelly BLU sensors/buttons speak this natively. Xiaomi/Aqara "Mijia" BLE
// sensors do NOT on their stock firmware (proprietary, often encrypted
// MiBeacon format) — but the widely-used community ATC_MiThermometer/pvvx
// custom firmware for devices like the LYWSD03MMC can be configured to
// broadcast in this same BTHome format, which is why it's worth decoding
// generically rather than writing a one-off Shelly-only parser.
//
// Spec: https://bthome.io/format/
// ─────────────────────────────────────────────────────────────────────────────

/// A single decoded measurement from a BTHome payload.
class BtHomeReading {
  final String key;   // e.g. 'temperature', 'humidity', 'battery'
  final num value;
  final String unit;  // e.g. '°C', '%', 'lx' — empty for unitless/enum values
  const BtHomeReading(this.key, this.value, this.unit);
}

class BtHomeDecoded {
  final bool encrypted;
  final List<BtHomeReading> readings;
  const BtHomeDecoded({required this.encrypted, required this.readings});

  double? get temperature => _numOf('temperature')?.toDouble();
  double? get humidity => _numOf('humidity')?.toDouble();
  int? get batteryPercent => _numOf('battery')?.toInt();

  num? _numOf(String key) =>
      readings.where((r) => r.key == key).map((r) => r.value).firstOrNull;
}

class BtHomeDecoder {
  /// The BTHome v2 service UUID (16-bit, `0xFCD2`), as it appears in a
  /// [Guid.str] from flutter_blue_plus (lowercase, full 128-bit form).
  static const serviceUuid = '0000fcd2-0000-1000-8000-00805f9b34fb';

  /// Decodes raw BTHome v2 service-data bytes (everything after the service
  /// UUID itself — i.e. what flutter_blue_plus hands back per service GUID
  /// in `AdvertisementData.serviceData`). Returns null for malformed input
  /// or a payload this parser doesn't (yet) know how to read past.
  static BtHomeDecoded? decode(List<int> bytes) {
    if (bytes.isEmpty) return null;

    final infoByte = bytes[0];
    final encrypted = (infoByte & 0x01) != 0;
    // Encrypted payloads need a per-device bind key we don't have — report
    // that it's encrypted rather than attempting (and failing) to parse.
    if (encrypted) return const BtHomeDecoded(encrypted: true, readings: []);

    final readings = <BtHomeReading>[];
    var i = 1;
    while (i < bytes.length) {
      final objectId = bytes[i];
      i++;
      final spec = _objectSpecs[objectId];
      if (spec == null) {
        // Unknown object id — nothing tells us its length, so we can't
        // safely skip it and keep parsing the rest of the payload.
        break;
      }
      if (i + spec.length > bytes.length) break;
      final raw = bytes.sublist(i, i + spec.length);
      i += spec.length;
      final value = spec.decode(raw);
      if (value != null) {
        readings.add(BtHomeReading(spec.key, value, spec.unit));
      }
    }

    return BtHomeDecoded(encrypted: false, readings: readings);
  }

  static num _uint(List<int> b) {
    num v = 0;
    for (var i = b.length - 1; i >= 0; i--) {
      v = v * 256 + b[i];
    }
    return v;
  }

  static num _sint(List<int> b) {
    final u = _uint(b).toInt();
    final bits = b.length * 8;
    final signBit = 1 << (bits - 1);
    return (u & signBit) != 0 ? u - (1 << bits) : u;
  }

  static final Map<int, _ObjectSpec> _objectSpecs = {
    0x00: _ObjectSpec('packet_id', 1, '', (b) => _uint(b)),
    0x01: _ObjectSpec('battery', 1, '%', (b) => _uint(b)),
    0x02: _ObjectSpec('temperature', 2, '°C', (b) => _sint(b) * 0.01),
    0x03: _ObjectSpec('humidity', 2, '%', (b) => _uint(b) * 0.01),
    0x05: _ObjectSpec('illuminance', 3, 'lx', (b) => _uint(b) * 0.01),
    0x1A: _ObjectSpec('door', 1, '', (b) => _uint(b)),       // 0=closed 1=open
    0x2D: _ObjectSpec('window', 1, '', (b) => _uint(b)),     // 0=closed 1=open
    0x3A: _ObjectSpec('button', 1, '', (b) => _uint(b)),     // event code
  };
}

class _ObjectSpec {
  final String key;
  final int length;
  final String unit;
  final num? Function(List<int> bytes) decode;
  const _ObjectSpec(this.key, this.length, this.unit, this.decode);
}
