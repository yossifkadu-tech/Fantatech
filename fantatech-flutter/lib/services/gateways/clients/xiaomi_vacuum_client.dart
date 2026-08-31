// ─────────────────────────────────────────────────────────────────────────────
// XiaomiVacuumClient  —  Xiaomi / Mi Robot Vacuum local "miIO" protocol
//
// Xiaomi's miIO devices (Mi Robot Vacuum, Mi Robot Vacuum-Mop, etc.) expose a
// local UDP control protocol on port 54321. All communication after the
// initial handshake is encrypted with the device's local "token" — a 32-hex-
// character secret tied to the device.
//
// Protocol (well documented publicly, e.g. the python-miio project):
//   1. Handshake — send a 32-byte "Hello" packet (all bytes 0xFF). The device
//      replies with a 32-byte packet containing its device_id and a time
//      stamp, used for every subsequent packet.
//   2. Commands are JSON-RPC objects, e.g. {"id":1,"method":"app_start","params":[]},
//      AES-128-CBC encrypted with key = MD5(token), iv = MD5(key + token),
//      then wrapped in a binary header (magic/length/device_id/stamp/checksum).
//   3. The response is decrypted the same way and parsed as JSON.
//
// Obtaining the local Token (one-time, done by the user):
//   The token is tied to the user's Mi Home / Xiaomi account and is not
//   exposed by the FantaTech app. Community tools ("Xiaomi Cloud Tokens
//   Extractor") retrieve it in under a minute by logging into the Xiaomi
//   cloud account once. FantaTech does not perform this extraction itself;
//   the user supplies the 32-character token once.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class XiaomiVacuumStatus {
  final int? batteryPct;
  final int? state; // raw miIO state code (5=cleaning, 8=charging, 6=returning…)
  final int? errorCode;
  final int? cleanArea;   // cm²
  final int? cleanTime;   // seconds

  const XiaomiVacuumStatus({
    this.batteryPct,
    this.state,
    this.errorCode,
    this.cleanArea,
    this.cleanTime,
  });

  bool get isCharging => state == 8;
  bool get isCleaning => state == 5 || state == 6 || state == 7;
}

class XiaomiVacuumClient {
  final String _ip;
  final Uint8List _token;

  int? _deviceId;
  int _stamp = 0;
  DateTime _stampSetAt = DateTime.now();
  int _msgId = 1;

  static const _port = 54321;
  static const _timeout = Duration(seconds: 5);

  XiaomiVacuumClient({required String ip, required String token})
      : _ip = ip,
        _token = _hexToBytes(token);

  static Uint8List _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s'), '');
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  // ── Handshake ────────────────────────────────────────────────────────────

  /// Performs the "Hello" handshake to learn the device_id + time stamp.
  /// Returns true on success.
  Future<bool> _handshake(RawDatagramSocket socket) async {
    final hello = Uint8List(32)..fillRange(0, 32, 0xFF);
    socket.send(hello, InternetAddress(_ip), _port);

    final completer = Completer<bool>();
    late StreamSubscription sub;
    sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null || dg.data.length < 32) return;
      final bytes = dg.data;
      _deviceId = ByteData.sublistView(bytes, 8, 12).getUint32(0);
      _stamp = ByteData.sublistView(bytes, 12, 16).getUint32(0);
      _stampSetAt = DateTime.now();
      if (!completer.isCompleted) completer.complete(true);
    });

    final ok = await completer.future
        .timeout(_timeout, onTimeout: () => false);
    await sub.cancel();
    return ok;
  }

  int get _currentStamp =>
      _stamp + DateTime.now().difference(_stampSetAt).inSeconds;

  // ── Encryption ───────────────────────────────────────────────────────────

  enc.Key get _aesKey => enc.Key(Uint8List.fromList(md5.convert(_token).bytes));
  enc.IV get _aesIv => enc.IV(Uint8List.fromList(
      md5.convert([..._aesKey.bytes, ..._token]).bytes));

  Uint8List _encrypt(String plaintext) {
    final encrypter = enc.Encrypter(
        enc.AES(_aesKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));
    return encrypter.encryptBytes(utf8.encode(plaintext), iv: _aesIv).bytes;
  }

  String? _decrypt(Uint8List ciphertext) {
    if (ciphertext.isEmpty) return null;
    try {
      final encrypter = enc.Encrypter(
          enc.AES(_aesKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));
      final bytes =
          encrypter.decryptBytes(enc.Encrypted(ciphertext), iv: _aesIv);
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Builds a full miIO packet: header + MD5 checksum + encrypted payload.
  Uint8List _buildPacket(Uint8List cipherData) {
    final total = 32 + cipherData.length;
    final header = ByteData(32);
    header.setUint16(0, 0x2131);          // magic
    header.setUint16(2, total);           // length
    header.setUint32(4, 0x00000000);      // unknown
    header.setUint32(8, _deviceId ?? 0);  // device id
    header.setUint32(12, _currentStamp);  // stamp
    // bytes 16..32 = checksum, filled in below

    final headerBytes = header.buffer.asUint8List();
    final forChecksum = Uint8List.fromList([
      ...headerBytes.sublist(0, 16),
      ..._token,
      ...cipherData,
    ]);
    final checksum = md5.convert(forChecksum).bytes;

    return Uint8List.fromList([
      ...headerBytes.sublist(0, 16),
      ...checksum,
      ...cipherData,
    ]);
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Sends a JSON-RPC [method] with [params] and returns the decoded
  /// "result" field, or null on any failure/timeout.
  Future<dynamic> call(String method, [List<dynamic> params = const []]) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (_deviceId == null) {
        final ok = await _handshake(socket);
        if (!ok) return null;
      }

      final id = _msgId++;
      final payload = jsonEncode({'id': id, 'method': method, 'params': params});
      final packet = _buildPacket(_encrypt(payload));

      final completer = Completer<dynamic>();
      late StreamSubscription sub;
      sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket?.receive();
        if (dg == null || dg.data.length <= 32) return;
        final cipherData = dg.data.sublist(32);
        final json = _decrypt(cipherData);
        if (json == null) return;
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          if (map['id'] == id && !completer.isCompleted) {
            completer.complete(map['result']);
          }
        } catch (_) {}
      });

      socket.send(packet, InternetAddress(_ip), _port);
      final result =
          await completer.future.timeout(_timeout, onTimeout: () => null);
      await sub.cancel();
      return result;
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }

  /// Verifies the device responds to a basic status query.
  Future<bool> testConnection() async {
    final result = await call('get_status');
    return result != null;
  }

  Future<XiaomiVacuumStatus?> getStatus() async {
    final result = await call('get_status');
    if (result is! List || result.isEmpty) return null;
    final s = result.first as Map<String, dynamic>;
    return XiaomiVacuumStatus(
      batteryPct: s['battery'] as int?,
      state: s['state'] as int?,
      errorCode: s['error_code'] as int?,
      cleanArea: s['clean_area'] as int?,
      cleanTime: s['clean_time'] as int?,
    );
  }

  Future<bool> start()  async => (await call('app_start'))  != null;
  Future<bool> stop()   async => (await call('app_stop'))   != null;
  Future<bool> pause()  async => (await call('app_pause'))  != null;
  Future<bool> dock()   async => (await call('app_charge')) != null;
}
