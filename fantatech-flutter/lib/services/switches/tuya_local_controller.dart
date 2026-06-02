// ─────────────────────────────────────────────────────────────────────────────
// TuyaLocalController  —  Tuya LAN Protocol 3.3
//
// Reference: https://developer.tuya.com/en/docs/iot/lan-control
//
// Frame layout (all integers big-endian):
//   [prefix:4]  0x000055AA
//   [seqno:4]   sequence number
//   [cmd:4]     command type
//   [len:4]     payload_len + 8  (= CRC + suffix)
//   [payload:N] version_header(12) + AES-128-ECB(json)
//   [crc:4]     CRC-32 over everything from prefix through payload
//   [suffix:4]  0x0000AA55
//
// Commands used:
//   0x07  SET_DPS   — set device datapoints (DPS)
//   0x0A  GET_DPS   — query current datapoints
//
// AES key  = local_key bytes (16 chars → AES-128, 32 chars → AES-256)
// Padding  = PKCS7
// IV       = none (ECB mode)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

class TuyaLocalController {
  // ── Protocol constants ────────────────────────────────────────────────────

  static const _prefix  = [0x00, 0x00, 0x55, 0xAA];
  static const _suffix  = [0x00, 0x00, 0xAA, 0x55];
  // Version header "3.3" right-padded to 12 bytes
  static const _verHdr  = [
    0x33, 0x2E, 0x33, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00,
  ];
  static const _cmdSet  = 0x07;
  static const _cmdGet  = 0x0A;
  static const _port    = 6668;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Toggle DPS "1" (main switch) for a Tuya device.
  /// [ip]       — device IP on LAN
  /// [devId]    — Tuya device ID (from IoT platform)
  /// [localKey] — 16-char local key (from IoT platform)
  /// [on]       — true = ON, false = OFF, null = toggle
  /// Returns true on success.
  static Future<bool> setSwitch(
    String ip,
    String devId,
    String localKey, {
    bool? on,
    int dpsIndex = 1,
  }) async {
    // If toggle requested, read current state first
    bool targetOn;
    if (on == null) {
      final status = await getStatus(ip, devId, localKey);
      final current = status?[dpsIndex.toString()] as bool? ?? false;
      targetOn = !current;
    } else {
      targetOn = on;
    }

    return _sendSet(ip, devId, localKey, {dpsIndex.toString(): targetOn});
  }

  /// Read current DPS map.  Returns null on failure.
  static Future<Map<String, dynamic>?> getStatus(
    String ip,
    String devId,
    String localKey,
  ) async {
    final encrypter = _encrypter(localKey);
    if (encrypter == null) return null;

    final payloadJson = jsonEncode({
      'devId': devId,
      'uid':   devId,
      't':     _tsNow(),
    });

    final encPayload = _encryptPayload(encrypter, payloadJson);
    final frame = _buildFrame(_cmdGet, encPayload, 1);

    final raw = await _sendReceive(ip, frame);
    if (raw == null || raw.length < 28) return null;

    return _decodeResponse(raw, encrypter);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<bool> _sendSet(
    String ip,
    String devId,
    String localKey,
    Map<String, dynamic> dps,
  ) async {
    final encrypter = _encrypter(localKey);
    if (encrypter == null) return false;

    final payloadJson = jsonEncode({
      'devId': devId,
      'uid':   devId,
      't':     _tsNow(),
      'dps':   dps,
    });

    final encPayload = _encryptPayload(encrypter, payloadJson);
    final frame = _buildFrame(_cmdSet, encPayload, 2);

    final raw = await _sendReceive(ip, frame);
    return raw != null && raw.length > 20;
  }

  // ── Frame helpers ─────────────────────────────────────────────────────────

  /// Encrypt JSON payload and prepend the 12-byte version header.
  static Uint8List _encryptPayload(enc.Encrypter encrypter, String json) {
    final encrypted = encrypter.encryptBytes(utf8.encode(json));
    return Uint8List.fromList([..._verHdr, ...encrypted.bytes]);
  }

  /// Build the complete binary frame.
  static Uint8List _buildFrame(int cmd, Uint8List payload, int seqno) {
    final lenVal = payload.length + 8; // payload + CRC(4) + suffix(4)

    final bb = BytesBuilder()
      ..add(_prefix)
      ..add(_u32(seqno))
      ..add(_u32(cmd))
      ..add(_u32(lenVal))
      ..add(payload);

    final withoutTail = bb.toBytes();
    final crc         = _crc32(withoutTail);

    return Uint8List.fromList([
      ...withoutTail,
      ..._u32(crc),
      ..._suffix,
    ]);
  }

  /// Decrypt the response frame and return the DPS map.
  static Map<String, dynamic>? _decodeResponse(
      List<int> raw, enc.Encrypter encrypter) {
    try {
      // Header: prefix(4) + seq(4) + cmd(4) + len(4) = 16 bytes
      // Then payload bytes end at raw.length - 8 (skip CRC + suffix)
      const headerLen = 16;
      final payloadEnd = raw.length - 8;
      if (payloadEnd <= headerLen) return null;

      var payloadBytes = raw.sublist(headerLen, payloadEnd);

      // Strip 12-byte version header if present
      if (payloadBytes.length > 12 &&
          payloadBytes[0] == 0x33 &&
          payloadBytes[1] == 0x2E) {
        payloadBytes = payloadBytes.sublist(12);
      }

      if (payloadBytes.isEmpty) return null;

      final decrypted = encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(payloadBytes)));
      final text = utf8.decode(decrypted, allowMalformed: true);

      // Response may be raw JSON or wrapped {"dps":{...},...}
      final json = jsonDecode(text) as Map<String, dynamic>;
      return (json['dps'] as Map<String, dynamic>?) ?? json;
    } catch (_) {
      return null;
    }
  }

  // ── TCP send / receive ─────────────────────────────────────────────────────

  static Future<List<int>?> _sendReceive(String ip, Uint8List frame) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, _port,
          timeout: const Duration(seconds: 3));
      socket.add(frame);
      await socket.flush();

      final buf = <int>[];
      await socket
          .listen(buf.addAll)
          .asFuture<void>()
          .timeout(const Duration(seconds: 3));

      return buf.isEmpty ? null : buf;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  // ── Crypto ────────────────────────────────────────────────────────────────

  /// Build AES-ECB encrypter from local key.
  /// Accepts 16-char (AES-128) or 32-char (AES-256) keys.
  static enc.Encrypter? _encrypter(String localKey) {
    try {
      final raw = utf8.encode(localKey);

      // Tuya keys are 16 or 32 bytes
      final Uint8List keyBytes;
      if (raw.length >= 32) {
        keyBytes = Uint8List.fromList(raw.sublist(0, 32));
      } else if (raw.length >= 16) {
        keyBytes = Uint8List.fromList(raw.sublist(0, 16));
      } else {
        // Pad short keys with zeros
        final padded = Uint8List(16);
        padded.setRange(0, raw.length, raw);
        keyBytes = padded;
      }

      final key = enc.Key(keyBytes);
      return enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
    } catch (_) {
      return null;
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  static List<int> _u32(int v) => [
        (v >> 24) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 8)  & 0xFF,
         v        & 0xFF,
      ];

  static String _tsNow() =>
      (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

  // CRC-32 (standard polynomial 0xEDB88320)
  static int _crc32(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return (~crc) & 0xFFFFFFFF;
  }
}
