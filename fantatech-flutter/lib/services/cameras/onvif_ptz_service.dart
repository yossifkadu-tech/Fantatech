// ─────────────────────────────────────────────────────────────────────────────
// OnvifPtzService — ONVIF PTZ control via SOAP over HTTP
//
// Supports: ContinuousMove, Stop
// Works with any ONVIF-compliant PTZ camera.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OnvifPtzService {
  static const _ptzPath    = '/onvif/ptz';
  static const _mediaPath  = '/onvif/media';

  // ── ContinuousMove ──────────────────────────────────────────────────────────

  /// Start continuous PTZ movement.
  /// [panX]  : -1.0 (left) → +1.0 (right)
  /// [tiltY] : -1.0 (down) → +1.0 (up)
  /// [zoomX] : -1.0 (out)  → +1.0 (in)
  static Future<bool> continuousMove(
    String ip, {
    int port = 80,
    String? username,
    String? password,
    String profileToken = 'MainStream',
    double panX  = 0.0,
    double tiltY = 0.0,
    double zoomX = 0.0,
  }) {
    final body = _continuousMoveSoap(
      profileToken: profileToken,
      panX: panX, tiltY: tiltY, zoomX: zoomX,
    );
    return _soapPost(ip, port, _ptzPath, body, username, password);
  }

  // ── Stop ────────────────────────────────────────────────────────────────────

  /// Stop all PTZ movement.
  static Future<bool> stop(
    String ip, {
    int port = 80,
    String? username,
    String? password,
    String profileToken = 'MainStream',
  }) {
    final body = _stopSoap(profileToken: profileToken);
    return _soapPost(ip, port, _ptzPath, body, username, password);
  }

  // ── GetProfiles (to get real profileToken) ──────────────────────────────────

  static Future<String?> getFirstProfileToken(
    String ip, {
    int port = 80,
    String? username,
    String? password,
  }) async {
    const body = '''<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope"
  xmlns:trt="http://www.onvif.org/ver10/media/wsdl">
  <Header/>
  <Body><trt:GetProfiles/></Body>
</Envelope>''';

    try {
      final sock = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 3));
      final bodyBytes = utf8.encode(body);
      final hdr = StringBuffer()
        ..write('POST $_mediaPath HTTP/1.0\r\n')
        ..write('Host: $ip:$port\r\n')
        ..write('Content-Type: application/soap+xml; charset=utf-8\r\n')
        ..write('Content-Length: ${bodyBytes.length}\r\n');
      if (username != null && password != null) {
        hdr.write('Authorization: Basic ${base64Encode(utf8.encode('$username:$password'))}\r\n');
      }
      hdr.write('\r\n');
      sock.add(utf8.encode(hdr.toString()));
      sock.add(bodyBytes);
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          const Duration(seconds: 2), onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 4096) break;
      }
      await sock.close();

      final resp = utf8.decode(bytes, allowMalformed: true);
      // Extract first Profiles token attribute
      final match = RegExp(r'<[^>]*Profile[^>]+token="([^"]+)"').firstMatch(resp);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  // ── SOAP builders ───────────────────────────────────────────────────────────

  static String _continuousMoveSoap({
    required String profileToken,
    required double panX,
    required double tiltY,
    required double zoomX,
  }) =>
      '''<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope"
  xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl"
  xmlns:tt="http://www.onvif.org/ver10/schema">
  <Header/>
  <Body>
    <tptz:ContinuousMove>
      <tptz:ProfileToken>$profileToken</tptz:ProfileToken>
      <tptz:Velocity>
        <tt:PanTilt x="${panX.toStringAsFixed(2)}" y="${tiltY.toStringAsFixed(2)}"/>
        <tt:Zoom x="${zoomX.toStringAsFixed(2)}"/>
      </tptz:Velocity>
    </tptz:ContinuousMove>
  </Body>
</Envelope>''';

  static String _stopSoap({required String profileToken}) =>
      '''<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope"
  xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">
  <Header/>
  <Body>
    <tptz:Stop>
      <tptz:ProfileToken>$profileToken</tptz:ProfileToken>
      <tptz:PanTilt>true</tptz:PanTilt>
      <tptz:Zoom>true</tptz:Zoom>
    </tptz:Stop>
  </Body>
</Envelope>''';

  // ── HTTP/SOAP helper ─────────────────────────────────────────────────────────

  static Future<bool> _soapPost(
    String ip,
    int port,
    String path,
    String soapBody,
    String? username,
    String? password,
  ) async {
    try {
      final bodyBytes = utf8.encode(soapBody);
      final sock = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 3));

      final hdr = StringBuffer()
        ..write('POST $path HTTP/1.0\r\n')
        ..write('Host: $ip:$port\r\n')
        ..write('Content-Type: application/soap+xml; charset=utf-8\r\n')
        ..write('Content-Length: ${bodyBytes.length}\r\n');
      if (username != null && password != null) {
        hdr.write('Authorization: Basic ${base64Encode(utf8.encode('$username:$password'))}\r\n');
      }
      hdr.write('\r\n');

      sock.add(utf8.encode(hdr.toString()));
      sock.add(bodyBytes);
      await sock.flush();

      final bytes = <int>[];
      await for (final chunk in sock.timeout(
          const Duration(seconds: 2), onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (bytes.length > 512) break;
      }
      await sock.close();

      final resp = utf8.decode(bytes, allowMalformed: true);
      return resp.contains('200') ||
          resp.contains('MoveResponse') ||
          resp.contains('StopResponse');
    } catch (_) {
      return false;
    }
  }
}
