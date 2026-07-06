// ─────────────────────────────────────────────────────────────────────────────
// BroadlinkController  —  Broadlink IR / RF Blaster LAN Protocol
//
// Broadlink protocol reference: https://github.com/mjg59/python-broadlink
//
// Protocol overview:
//   1. Discovery  — UDP broadcast on port 255 to find devices on the LAN.
//   2. Auth       — TCP handshake on port 80 to negotiate an AES session key
//                   and obtain a device token.
//   3. Commands   — Encrypted TCP packets on port 80. IR send = command 0x6a.
//
// AES-128-CBC encryption:
//   Initial key : [0x09, 0x76, 0x28, 0x34, 0x3f, 0xe9, 0x9e, 0x23,
//                  0x76, 0x5c, 0x15, 0x13, 0xac, 0xcf, 0x8b, 0x02]
//   Initial IV  : [0x56, 0x2e, 0x17, 0x99, 0x6d, 0x09, 0x3d, 0x28,
//                  0xdd, 0xb3, 0xba, 0x69, 0x5a, 0x2e, 0x6f, 0x58]
//   After auth the device returns a new key and token in the response.
//
// Requirements:
//   • Broadlink device (RM3, RM4, RM Mini, etc.) on the same LAN segment.
//   • No cloud account needed; fully local.
//   • IR codes must be captured from real remotes or sourced from
//     community databases (e.g. globalcache, irdb, or smart-ir databases).
//   • The placeholder hex codes in [commonAcCodes] must be replaced with
//     codes captured by the Broadlink app's "Learn" feature.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

class BroadlinkController {
  // ── Protocol constants ────────────────────────────────────────────────────

  static const _port = 80;

  static const _initialKey = <int>[
    0x09, 0x76, 0x28, 0x34, 0x3f, 0xe9, 0x9e, 0x23,
    0x76, 0x5c, 0x15, 0x13, 0xac, 0xcf, 0x8b, 0x02,
  ];

  static const _initialIv = <int>[
    0x56, 0x2e, 0x17, 0x99, 0x6d, 0x09, 0x3d, 0x28,
    0xdd, 0xb3, 0xba, 0x69, 0x5a, 0x2e, 0x6f, 0x58,
  ];

  static const _cmdAuth   = 0x65;
  static const _cmdIrSend = 0x6a;

  // ── Instance fields ───────────────────────────────────────────────────────

  final String _ip;
  Uint8List _key;
  Uint8List _iv;
  int       _token = 0;
  int       _count = 0;

  BroadlinkController._(this._ip, this._key, this._iv);

  // ── Common AC IR codes (Israeli market) ───────────────────────────────────
  //
  // ⚠  All codes below are PLACEHOLDERS.
  //    Replace with real hex strings captured via the Broadlink app
  //    "Learn" / "IR Capture" feature or from the smart-ir community database:
  //    https://github.com/smartHomeHub/SmartIR/tree/master/codes/climate
  //
  static const Map<String, Map<String, String>> commonAcCodes = {
    'Tadiran': {
      'power_on':  '260050000001...', // Replace with real captured code
      'power_off': '260050000002...', // Replace with real captured code
      'temp_22':   '260050000003...', // Replace with real captured code
      'temp_24':   '260050000004...', // Replace with real captured code
    },
    'Electra': {
      'power_on':  '260050000011...', // Replace with real captured code
      'power_off': '260050000012...', // Replace with real captured code
      'temp_22':   '260050000013...', // Replace with real captured code
      'temp_24':   '260050000014...', // Replace with real captured code
    },
    'General': {
      'power_on':  '260050000021...', // Replace with real captured code
      'power_off': '260050000022...', // Replace with real captured code
      'temp_22':   '260050000023...', // Replace with real captured code
      'temp_24':   '260050000024...', // Replace with real captured code
    },
    'LG': {
      'power_on':  '260050000031...', // Replace with real captured code
      'power_off': '260050000032...', // Replace with real captured code
      'temp_22':   '260050000033...', // Replace with real captured code
      'temp_24':   '260050000034...', // Replace with real captured code
    },
    'Samsung': {
      'power_on':  '260050000041...', // Replace with real captured code
      'power_off': '260050000042...', // Replace with real captured code
      'temp_22':   '260050000043...', // Replace with real captured code
      'temp_24':   '260050000044...', // Replace with real captured code
    },
    'Mitsubishi': {
      'power_on':  '260050000051...', // Replace with real captured code
      'power_off': '260050000052...', // Replace with real captured code
      'temp_22':   '260050000053...', // Replace with real captured code
      'temp_24':   '260050000054...', // Replace with real captured code
    },
    'Daikin': {
      'power_on':  '260050000061...', // Replace with real captured code
      'power_off': '260050000062...', // Replace with real captured code
      'temp_22':   '260050000063...', // Replace with real captured code
      'temp_24':   '260050000064...', // Replace with real captured code
    },
  };

  // ── Factory: connect ──────────────────────────────────────────────────────

  /// Authenticate with a Broadlink device at [ip] and return a controller.
  /// Returns null if connection or auth fails.
  static Future<BroadlinkController?> connect(String ip) async {
    try {
      final key = Uint8List.fromList(_initialKey);
      final iv  = Uint8List.fromList(_initialIv);
      final ctl = BroadlinkController._(ip, key, iv);

      final ok = await ctl._authenticate();
      return ok ? ctl : null;
    } catch (_) {
      return null;
    }
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

  /// Broadcast UDP discovery on the local subnet and return IPs of
  /// Broadlink devices that respond.
  ///
  /// [subnetPrefix] — e.g. "192.168.1"
  static Future<List<String>> discover(String subnetPrefix) async {
    final found = <String>[];
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;

      final packet = _buildDiscoveryPacket();
      socket.send(
        packet,
        InternetAddress('$subnetPrefix.255'),
        255,
      );

      await socket
          .where((event) => event == RawSocketEvent.read)
          .timeout(const Duration(seconds: 5))
          .forEach((event) {
        final dg = socket!.receive();
        if (dg != null) {
          found.add(dg.address.address);
        }
      }).catchError((_) {});
    } catch (_) {
      // swallow
    } finally {
      socket?.close();
    }
    return found;
  }

  // ── IR send ───────────────────────────────────────────────────────────────

  /// Send a Broadlink-format IR code.
  ///
  /// [hexCode] — hex string as produced by the Broadlink app's Learn function.
  ///             Example: "260050000001234..."
  /// Returns true on success.
  Future<bool> sendIrCode(String hexCode) async {
    try {
      final irBytes = _hexToBytes(hexCode);

      // IR send payload: 4-byte header + IR data
      final payload = BytesBuilder()
        ..add([0x26, 0x00]) // IR command type
        ..add(_u16le(irBytes.length))
        ..add(irBytes);

      // Pad to multiple of 16 for AES
      final padded = _pkcs7Pad(payload.toBytes());

      final encrypted = _aesEncrypt(padded);
      final packet    = _buildCommandPacket(_cmdIrSend, encrypted);

      return await _sendPacket(packet);
    } catch (_) {
      return false;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> _authenticate() async {
    try {
      // Generate random 16-byte device ID
      final rand     = Random.secure();
      final deviceId = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        deviceId[i] = rand.nextInt(256);
      }

      // Auth payload: device ID at offset 0x04, key at offset 0x54
      final payload = Uint8List(0x58);
      payload.setRange(0x04, 0x14, deviceId);
      payload.setRange(0x54, 0x58, [0x01, 0x00, 0x00, 0x00]);

      final padded    = _pkcs7Pad(payload);
      final encrypted = _aesEncrypt(padded);
      final packet    = _buildCommandPacket(_cmdAuth, encrypted);

      final response = await _sendReceive(packet);
      if (response == null || response.length < 0x38 + 16) return false;

      // Decrypt response payload (starts at offset 0x38)
      final encPayload = response.sublist(0x38);
      final decrypted  = _aesDecrypt(Uint8List.fromList(encPayload));

      // New key at offset 0x04..0x14, token at offset 0x00..0x04
      _token = _u32le(decrypted, 0);
      final newKey = decrypted.sublist(4, 20);
      _key = Uint8List.fromList(newKey);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Packet builders ───────────────────────────────────────────────────────

  static Uint8List _buildDiscoveryPacket() {
    final packet = Uint8List(0x30);
    // Broadlink discovery magic bytes at specific offsets
    final now = DateTime.now();
    packet[0x08] = now.year & 0xFF;
    packet[0x09] = now.year >> 8;
    packet[0x0a] = now.minute;
    packet[0x0b] = now.hour;
    packet[0x0c] = now.weekday;
    packet[0x0d] = now.day;
    packet[0x0e] = now.month;
    packet[0x26] = 0x06; // discovery command
    // Checksum
    int cs = 0xbeaf;
    for (final b in packet) cs += b;
    packet[0x20] = cs & 0xFF;
    packet[0x21] = (cs >> 8) & 0xFF;
    return packet;
  }

  Uint8List _buildCommandPacket(int command, Uint8List payload) {
    _count = (_count + 1) & 0xFFFF;
    final packet = Uint8List(0x38 + payload.length);

    packet[0x00] = 0x5a;
    packet[0x01] = 0xa5;
    packet[0x02] = 0xaa;
    packet[0x03] = 0x55;
    packet[0x04] = 0x5a;
    packet[0x05] = 0xa5;
    packet[0x06] = 0xaa;
    packet[0x07] = 0x55;
    packet[0x24] = 0x2a; // device type (RM blaster)
    packet[0x25] = 0x27;
    packet[0x26] = command & 0xFF;
    packet[0x28] = _count & 0xFF;
    packet[0x29] = (_count >> 8) & 0xFF;

    // Token
    packet[0x30] = _token & 0xFF;
    packet[0x31] = (_token >> 8) & 0xFF;
    packet[0x32] = (_token >> 16) & 0xFF;
    packet[0x33] = (_token >> 24) & 0xFF;

    // Payload checksum
    int cs = 0xbeaf;
    for (final b in payload) cs += b;
    packet[0x34] = cs & 0xFF;
    packet[0x35] = (cs >> 8) & 0xFF;

    packet.setRange(0x38, 0x38 + payload.length, payload);

    // Packet checksum
    int pcs = 0xbeaf;
    for (final b in packet) pcs += b;
    packet[0x20] = pcs & 0xFF;
    packet[0x21] = (pcs >> 8) & 0xFF;

    return packet;
  }

  // ── TCP send / receive ────────────────────────────────────────────────────

  Future<bool> _sendPacket(Uint8List packet) async {
    final resp = await _sendReceive(packet);
    return resp != null && resp.length >= 0x22;
  }

  Future<Uint8List?> _sendReceive(Uint8List packet) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        _ip,
        _port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(packet);
      await socket.flush();

      final buf = <int>[];
      await socket
          .listen(buf.addAll)
          .asFuture<void>()
          .timeout(const Duration(seconds: 5));

      return buf.isEmpty ? null : Uint8List.fromList(buf);
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  // ── AES-128-CBC ───────────────────────────────────────────────────────────

  Uint8List _aesEncrypt(Uint8List data) {
    final cipher = enc.Encrypter(
      enc.AES(
        enc.Key(_key),
        mode: enc.AESMode.cbc,
        padding: null, // already padded manually
      ),
    );
    final result = cipher.encryptBytes(
      data,
      iv: enc.IV(_iv),
    );
    return Uint8List.fromList(result.bytes);
  }

  Uint8List _aesDecrypt(Uint8List data) {
    final cipher = enc.Encrypter(
      enc.AES(
        enc.Key(_key),
        mode: enc.AESMode.cbc,
        padding: null,
      ),
    );
    final decrypted = cipher.decryptBytes(
      enc.Encrypted(data),
      iv: enc.IV(_iv),
    );
    return Uint8List.fromList(decrypted);
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  static Uint8List _pkcs7Pad(List<int> data) {
    final pad = 16 - (data.length % 16);
    return Uint8List.fromList([...data, ...List.filled(pad, pad)]);
  }

  static Uint8List _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s+'), '');
    final result = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  static List<int> _u16le(int v) => [v & 0xFF, (v >> 8) & 0xFF];

  static int _u32le(Uint8List data, int offset) =>
      data[offset] |
      (data[offset + 1] << 8) |
      (data[offset + 2] << 16) |
      (data[offset + 3] << 24);
}
