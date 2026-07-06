// govee_lan_controller.dart
//
// Govee LAN API controller for FantaTech smart home app.
//
// Protocol: UDP-based LAN control.
//   - Discovery: broadcast UDP to 255.255.255.255:4001, listen on port 4002 for 3 s.
//   - Control:   unicast UDP to <device-ip>:4003.
//
// No cloud connection required — all communication is local.
// Enable LAN control in the Govee Home app under Settings → LAN Control.

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

class GoveeLanController {
  static const int _discoveryPort = 4001;
  static const int _listenPort = 4002;
  static const int _controlPort = 4003;
  static const Duration _discoverTimeout = Duration(seconds: 3);
  static const Duration _sendTimeout = Duration(seconds: 2);

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  /// Broadcasts a scan request and collects responding Govee devices for 3 s.
  ///
  /// Returns a list of maps with keys: `ip`, `device` (MAC-like id), `sku`.
  static Future<List<Map<String, dynamic>>> discover() async {
    final results = <Map<String, dynamic>>[];

    RawDatagramSocket? txSocket;
    RawDatagramSocket? rxSocket;

    try {
      // Socket for sending the broadcast
      txSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      txSocket.broadcastEnabled = true;

      // Socket for receiving device responses
      rxSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _listenPort,
          reuseAddress: true);

      final scanMsg = jsonEncode({
        'msg': {
          'cmd': 'scan',
          'data': {'account_topic': 'reserve'},
        }
      });
      final payload = Uint8List.fromList(utf8.encode(scanMsg));

      txSocket.send(payload, InternetAddress('255.255.255.255'), _discoveryPort);

      final deadline = DateTime.now().add(_discoverTimeout);

      await for (final event in rxSocket) {
        if (DateTime.now().isAfter(deadline)) break;
        if (event == RawSocketEvent.read) {
          final dg = rxSocket.receive();
          if (dg == null) continue;
          try {
            final raw = utf8.decode(dg.data);
            final json = jsonDecode(raw) as Map<String, dynamic>;
            final data = (json['msg'] as Map<String, dynamic>?)?['data']
                as Map<String, dynamic>?;
            if (data != null) {
              results.add({
                'ip': data['ip'] ?? dg.address.address,
                'device': data['device'] ?? '',
                'sku': data['sku'] ?? '',
              });
            }
          } catch (_) {
            // Malformed packet — skip
          }
        }
        if (DateTime.now().isAfter(deadline)) break;
      }
    } catch (_) {
      // Return whatever we collected so far
    } finally {
      txSocket?.close();
      rxSocket?.close();
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Control helpers
  // ---------------------------------------------------------------------------

  /// Sends a UDP control message to [ip]:4003.
  static Future<bool> _sendCommand(String ip, Map<String, dynamic> msg) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
          .timeout(_sendTimeout);
      final payload = Uint8List.fromList(utf8.encode(jsonEncode({'msg': msg})));
      final address = InternetAddress(ip);
      socket.send(payload, address, _controlPort);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Turns the device at [ip] on (`true`) or off (`false`).
  static Future<bool> setOnOff(String ip, bool on) {
    return _sendCommand(ip, {
      'cmd': 'turn',
      'data': {'value': on ? 1 : 0},
    });
  }

  /// Sets brightness [level] 0–100.
  static Future<bool> setBrightness(String ip, int level) {
    return _sendCommand(ip, {
      'cmd': 'brightness',
      'data': {'value': level.clamp(0, 100)},
    });
  }

  /// Sets the RGB color. Each channel 0–255.
  static Future<bool> setColor(String ip, int r, int g, int b) {
    return _sendCommand(ip, {
      'cmd': 'colorwc',
      'data': {
        'color': {'r': r, 'g': g, 'b': b},
        'colorTemInKelvin': 0,
      },
    });
  }

  /// Sets the color temperature in Kelvin (e.g. 2700–6500).
  static Future<bool> setColorTemp(String ip, int kelvin) {
    return _sendCommand(ip, {
      'cmd': 'colorwc',
      'data': {
        'color': {'r': 0, 'g': 0, 'b': 0},
        'colorTemInKelvin': kelvin,
      },
    });
  }
}
