// yeelight_controller.dart
//
// Yeelight LAN API controller for FantaTech smart home app.
//
// Protocol: TCP JSON-RPC on port 55443.
//   Each command is a single-line JSON object terminated with \r\n.
//   A new TCP connection is opened per command and closed immediately after.
//
// Prerequisites:
//   - Enable "LAN Control" in the Yeelight mobile app (Device → Settings → LAN Control).
//   - The device and the phone/server must be on the same Wi-Fi network.

import 'dart:io';
import 'dart:convert';
import 'dart:async';

class YeelightController {
  static const int _port = 55443;
  static const Duration _connectTimeout = Duration(seconds: 2);

  // ---------------------------------------------------------------------------
  // Internal transport
  // ---------------------------------------------------------------------------

  /// Opens a TCP connection to [ip]:55443, sends [command]\r\n, then closes.
  static Future<bool> _sendCommand(
      String ip, Map<String, dynamic> command) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, _port, timeout: _connectTimeout);
      final line = '${jsonEncode(command)}\r\n';
      socket.write(line);
      await socket.flush();
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Turns the bulb at [ip] on or off.
  ///
  /// Uses a 300 ms "smooth" transition.
  static Future<bool> setOnOff(String ip, bool on) {
    return _sendCommand(ip, {
      'id': 1,
      'method': 'set_power',
      'params': [on ? 'on' : 'off', 'smooth', 300],
    });
  }

  /// Sets brightness [level] 1–100.
  ///
  /// Uses a 300 ms "smooth" transition.
  static Future<bool> setBrightness(String ip, int level) {
    return _sendCommand(ip, {
      'id': 2,
      'method': 'set_bright',
      'params': [level.clamp(1, 100), 'smooth', 300],
    });
  }

  /// Sets the color temperature [kelvin] (typically 1700–6500 K).
  ///
  /// Uses a 300 ms "smooth" transition.
  static Future<bool> setColorTemp(String ip, int kelvin) {
    return _sendCommand(ip, {
      'id': 3,
      'method': 'set_ct_abx',
      'params': [kelvin, 'smooth', 300],
    });
  }

  /// Sets the RGB color. Each channel 0–255.
  ///
  /// Internally packs the channels into a single 24-bit integer:
  /// `rgbInt = (r << 16) | (g << 8) | b`.
  /// Uses a 300 ms "smooth" transition.
  static Future<bool> setColor(String ip, int r, int g, int b) {
    final rgbInt = ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
    return _sendCommand(ip, {
      'id': 4,
      'method': 'set_rgb',
      'params': [rgbInt, 'smooth', 300],
    });
  }
}
