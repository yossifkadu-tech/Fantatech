// wiz_controller.dart
//
// WiZ LAN API controller for FantaTech smart home app.
//
// Protocol: UDP JSON-RPC on port 38899.
//   Commands are sent as unicast UDP datagrams to <device-ip>:38899.
//   Discovery uses a UDP broadcast to 255.255.255.255:38899.
//
// No pairing token required — WiZ bulbs accept plain UDP on the local network.

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

class WizController {
  static const int _port = 38899;
  static const Duration _sendTimeout = Duration(seconds: 2);
  static const Duration _discoverTimeout = Duration(seconds: 3);

  // ---------------------------------------------------------------------------
  // Internal transport
  // ---------------------------------------------------------------------------

  /// Sends [payload] as a UDP datagram to [ip]:38899.
  static Future<bool> _sendUdp(String ip, Map<String, dynamic> payload) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
          .timeout(_sendTimeout);
      final data = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
      socket.send(data, InternetAddress(ip), _port);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  /// Broadcasts a registration frame and collects responding WiZ device IPs
  /// for 3 s.
  ///
  /// [subnetPrefix] is the first three octets of your local network, e.g.
  /// `"192.168.1"`.  The "phoneIp" field is constructed as
  /// `"$subnetPrefix.1"` — adjust if your gateway/phone IP differs.
  static Future<List<String>> discover(String subnetPrefix) async {
    final ips = <String>[];

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final registration = jsonEncode({
        'method': 'registration',
        'params': {
          'phoneIp': '$subnetPrefix.1',
          'register': false,
          'phoneMac': 'AABBCCDDEEFF',
        },
      });
      final payload = Uint8List.fromList(utf8.encode(registration));
      socket.send(payload, InternetAddress('255.255.255.255'), _port);

      final deadline = DateTime.now().add(_discoverTimeout);

      await for (final event in socket) {
        if (DateTime.now().isAfter(deadline)) break;
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg == null) continue;
          try {
            final raw = utf8.decode(dg.data);
            final json = jsonDecode(raw) as Map<String, dynamic>;
            // WiZ responds with {"method":"registration","env":"pro","result":{...}}
            if (json['method'] == 'registration' ||
                json.containsKey('result')) {
              final ip = dg.address.address;
              if (!ips.contains(ip)) ips.add(ip);
            }
          } catch (_) {
            // Malformed packet — skip
          }
        }
        if (DateTime.now().isAfter(deadline)) break;
      }
    } catch (_) {
      // Return what we found so far
    } finally {
      socket?.close();
    }

    return ips;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Turns the bulb at [ip] on (`true`) or off (`false`).
  static Future<bool> setOnOff(String ip, bool on) {
    return _sendUdp(ip, {
      'method': 'setPilot',
      'params': {'state': on},
    });
  }

  /// Sets brightness [level] 10–100 (WiZ minimum is 10).
  static Future<bool> setBrightness(String ip, int level) {
    return _sendUdp(ip, {
      'method': 'setPilot',
      'params': {'dimming': level.clamp(10, 100)},
    });
  }

  /// Sets color temperature [kelvin] 2200–6500 K.
  static Future<bool> setColorTemp(String ip, int kelvin) {
    return _sendUdp(ip, {
      'method': 'setPilot',
      'params': {'temp': kelvin.clamp(2200, 6500)},
    });
  }

  /// Sets the RGB color. Each channel 0–255.
  static Future<bool> setColor(String ip, int r, int g, int b) {
    return _sendUdp(ip, {
      'method': 'setPilot',
      'params': {'r': r, 'g': g, 'b': b},
    });
  }
}
