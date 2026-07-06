// ─────────────────────────────────────────────────────────────────────────────
// MerossController  —  Meross local LAN HTTP API
//
// Protocol:
//   All commands are HTTP POST to http://IP/config with JSON body.
//   No credentials are required for the LAN API (key = "" empty string).
//
// Header format:
//   {
//     "from": "",
//     "messageId": "<16 random hex chars>",
//     "method": "GET" | "SET",
//     "namespace": "<namespace>",
//     "payloadVersion": 1,
//     "sign": "<md5(messageId + key + timestamp)>",
//     "timestamp": <unix seconds>
//   }
//
// Namespaces used:
//   Appliance.System.All         — query full device state (GET)
//   Appliance.Control.Toggle     — single-channel on/off (SET)
//   Appliance.Control.ToggleX    — multi-channel on/off (SET)
//
// Requirements:
//   • Meross device must be on the same LAN.
//   • No Meross account or credentials needed for local control.
//   • Only devices with firmware that exposes the LAN API are supported
//     (most Meross MSS/MSG/MRS-series smart plugs and switches).
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class MerossController {
  static const _port    = 80;
  static const _path    = '/config';
  static const _timeout = Duration(seconds: 5);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Turn a single-channel Meross device on or off.
  ///
  /// Uses [Appliance.Control.Toggle] namespace (single channel).
  /// Returns true on success.
  static Future<bool> setOnOff(
    String ip,
    bool on, {
    int channel = 0,
  }) async {
    return _post(
      ip: ip,
      method: 'SET',
      namespace: 'Appliance.Control.Toggle',
      payload: {
        'toggle': {
          'onoff':   on ? 1 : 0,
          'channel': channel,
        },
      },
    );
  }

  /// Turn a specific channel of a multi-channel Meross device on or off.
  ///
  /// Uses [Appliance.Control.ToggleX] namespace (multi-channel power strips,
  /// dual-outlet plugs, etc.).
  /// Returns true on success.
  static Future<bool> setOnOffMulti(
    String ip,
    bool on, {
    int channel = 0,
  }) async {
    return _post(
      ip: ip,
      method: 'SET',
      namespace: 'Appliance.Control.ToggleX',
      payload: {
        'togglex': {
          'onoff':   on ? 1 : 0,
          'channel': channel,
        },
      },
    );
  }

  /// Query the full device state using [Appliance.System.All].
  ///
  /// Returns the parsed JSON map on success, or null on failure.
  /// The response contains firmware, hardware, network info and channel states.
  static Future<Map<String, dynamic>?> getStatus(String ip) async {
    final msgId = _messageId();
    final ts    = _timestamp();
    final sign  = _sign(msgId, ts);

    final body = jsonEncode({
      'header': _header(msgId, 'GET', 'Appliance.System.All', ts, sign),
      'payload': <String, dynamic>{},
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://$ip:$_port$_path'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  static Future<bool> _post({
    required String ip,
    required String method,
    required String namespace,
    required Map<String, dynamic> payload,
  }) async {
    final msgId = _messageId();
    final ts    = _timestamp();
    final sign  = _sign(msgId, ts);

    final body = jsonEncode({
      'header': _header(msgId, method, namespace, ts, sign),
      'payload': payload,
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://$ip:$_port$_path'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Build the Meross request header map.
  static Map<String, dynamic> _header(
    String msgId,
    String method,
    String namespace,
    int timestamp,
    String sign,
  ) =>
      {
        'from':           '',
        'messageId':      msgId,
        'method':         method,
        'namespace':      namespace,
        'payloadVersion': 1,
        'sign':           sign,
        'timestamp':      timestamp,
      };

  /// 16 random lowercase hex characters used as messageId.
  static String _messageId() {
    final rand  = Random.secure();
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Current Unix time in seconds.
  static int _timestamp() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Meross sign = lowercase MD5(messageId + key + timestamp).
  /// For local LAN control the key is an empty string.
  static String _sign(String messageId, int timestamp) {
    const key = ''; // Empty key for local LAN protocol
    final input = '$messageId$key$timestamp';
    final digest = md5.convert(utf8.encode(input));
    return digest.toString();
  }
}
