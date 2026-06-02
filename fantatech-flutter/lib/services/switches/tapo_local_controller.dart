// ─────────────────────────────────────────────────────────────────────────────
// TapoLocalController  —  TP-Link Tapo Local Protocol (HTTP)
//
// Reverse-engineered by the community (PyP100, plugp100, python-kasa).
// Works on: P100, P110, P115, L510, L530, KP115, KS200M, … (firmware ≤ 1.2.x)
//
// Handshake flow:
//   1. POST /app  { method:"handshake", params:{ key:<RSA-1024 pub PEM> } }
//      ← response.result.key  = AES-128-CBC key+IV (32 bytes) encrypted RSA
//   2. POST /app  (securePassthrough)  login_device { username, password }
//      ← response.result.token
//   3. POST /app?token=…  (securePassthrough)  set_device_info / get_device_info
//
// Encryption:
//   outer: "securePassthrough" envelope  { method, params:{ request:<b64> } }
//   inner: AES-128-CBC / PKCS7  with key[0..15] and iv[16..31]
//   RSA:   PKCS#1 v1.5  1024-bit
//
// Credentials:
//   username = base64( sha1_hex_lowercase(email) )
//   password = base64( password )
//   (alt: some firmware accepts base64(email) / base64(password) directly)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;

// ── Session cache ─────────────────────────────────────────────────────────────

class _TapoSession {
  final enc.Encrypter encrypter;
  final enc.IV        iv;
  final String        token;
  final String        cookie;

  const _TapoSession({
    required this.encrypter,
    required this.iv,
    required this.token,
    required this.cookie,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class TapoLocalController {
  static const _timeout = Duration(seconds: 8);

  /// ip → session (refreshed on auth error)
  static final Map<String, _TapoSession> _cache = {};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Set switch on/off or toggle (on == null).  Returns true on success.
  static Future<bool> setSwitch(
    String ip,
    String email,
    String password, {
    bool? on,
  }) async {
    try {
      final session = await _session(ip, email, password);
      if (session == null) return false;

      // Determine target state
      final bool target;
      if (on != null) {
        target = on;
      } else {
        final current = await _getState(ip, session);
        target = !(current ?? false);
      }

      final ok = await _command(ip, session, 'set_device_info',
          {'device_on': target});

      // On auth error the session is cleared; retry once
      if (ok == null) {
        final s2 = await _login(ip, email, password);
        if (s2 == null) return false;
        return (await _command(ip, s2, 'set_device_info',
                {'device_on': target})) !=
            null;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Read the on/off state.  Returns null on failure.
  static Future<bool?> getState(
      String ip, String email, String password) async {
    try {
      final session = await _session(ip, email, password);
      if (session == null) return null;
      return _getState(ip, session);
    } catch (_) {
      return null;
    }
  }

  /// Read full device info map (model, alias, on/off, …).
  static Future<Map<String, dynamic>?> getDeviceInfo(
      String ip, String email, String password) async {
    try {
      final session = await _session(ip, email, password);
      if (session == null) return null;
      return _command(ip, session, 'get_device_info', {});
    } catch (_) {
      return null;
    }
  }

  /// Invalidate cached session for an IP (e.g. after credential change).
  static void clearSession(String ip) => _cache.remove(ip);

  // ── Session management ────────────────────────────────────────────────────

  static Future<_TapoSession?> _session(
      String ip, String email, String password) async {
    final cached = _cache[ip];
    if (cached != null) return cached;
    return _login(ip, email, password);
  }

  static Future<_TapoSession?> _login(
      String ip, String email, String password) async {
    try {
      // ── Step 1: RSA handshake ─────────────────────────────────────────────
      final keyPair = _generateRsaKeyPair();
      final pubKey  = keyPair.publicKey  as pc.RSAPublicKey;
      final privKey = keyPair.privateKey as pc.RSAPrivateKey;

      final handshakeBody = jsonEncode({
        'method': 'handshake',
        'params': {
          'key':             _publicKeyToPem(pubKey),
          'requestTimeMils': 0,
        },
      });

      final hsResp = await http
          .post(Uri.parse('http://$ip/app'),
              headers: {'Content-Type': 'application/json'},
              body: handshakeBody)
          .timeout(_timeout);

      if (hsResp.statusCode != 200) return null;
      final hsJson = jsonDecode(hsResp.body) as Map<String, dynamic>;
      if ((hsJson['error_code'] as int? ?? -1) != 0) return null;

      // Decrypt the 32-byte AES key+IV with our RSA private key
      final encKeyB64   = hsJson['result']['key'] as String;
      final encKeyBytes = base64.decode(encKeyB64);
      final rawKey      = _rsaDecrypt(privKey, encKeyBytes);
      if (rawKey.length < 32) return null;

      final aesKey = enc.Key(Uint8List.fromList(rawKey.sublist(0, 16)));
      final aesIV  = enc.IV(Uint8List.fromList(rawKey.sublist(16, 32)));
      final encrypter =
          enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));

      // Extract session cookie
      final rawCookie  = hsResp.headers['set-cookie'] ?? '';
      final cookieMatch = RegExp(r'TP_SESSIONID=[^;,\s]+')
          .firstMatch(rawCookie);
      final cookie = cookieMatch?.group(0) ?? rawCookie.split(';').first;

      // ── Step 2: login_device ──────────────────────────────────────────────
      // Primary encoding: username = base64(sha1_hex(email.lower()))
      final session = await _doLogin(
        ip, email, password, encrypter, aesIV, cookie,
        usernameAsHash: true,
      );
      if (session != null) {
        _cache[ip] = session;
        return session;
      }

      // Fallback: some firmware accepts base64(email) directly
      final fallback = await _doLogin(
        ip, email, password, encrypter, aesIV, cookie,
        usernameAsHash: false,
      );
      if (fallback != null) _cache[ip] = fallback;
      return fallback;
    } catch (_) {
      return null;
    }
  }

  static Future<_TapoSession?> _doLogin(
    String ip,
    String email,
    String password,
    enc.Encrypter encrypter,
    enc.IV iv,
    String cookie, {
    required bool usernameAsHash,
  }) async {
    final username = usernameAsHash
        ? base64.encode(utf8.encode(_sha1Hex(email.toLowerCase())))
        : base64.encode(utf8.encode(email));
    final pwd = base64.encode(utf8.encode(password));

    final body = _wrapPayload(encrypter, iv, {
      'method': 'login_device',
      'params': {'username': username, 'password': pwd},
    });

    final resp = await http
        .post(Uri.parse('http://$ip/app'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookie,
            },
            body: body)
        .timeout(_timeout);

    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((json['error_code'] as int? ?? -1) != 0) return null;

    final inner = _unwrapPayload(encrypter, iv, json);
    if (inner == null) return null;

    final token = inner['token'] as String? ?? '';
    return _TapoSession(encrypter: encrypter, iv: iv,
        token: token, cookie: cookie);
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  static Future<bool?> _getState(String ip, _TapoSession s) async {
    final result = await _command(ip, s, 'get_device_info', {});
    return result?['device_on'] as bool?;
  }

  /// Returns inner result map, or null on transport error, or null+clears
  /// cache on auth error (error_code ≠ 0).
  static Future<Map<String, dynamic>?> _command(
    String ip,
    _TapoSession session,
    String method,
    Map<String, dynamic> params,
  ) async {
    final body = _wrapPayload(session.encrypter, session.iv, {
      'method':        method,
      'params':        params,
      'requestTimeMils': DateTime.now().millisecondsSinceEpoch,
      'terminalUUID':  '88-00-DE-AD-BE-EF',
    });

    final resp = await http
        .post(
          Uri.parse('http://$ip/app?token=${session.token}'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': session.cookie,
          },
          body: body,
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((json['error_code'] as int? ?? -1) != 0) {
      _cache.remove(ip); // session expired — clear so next call re-logins
      return null;
    }

    return _unwrapPayload(session.encrypter, session.iv, json);
  }

  // ── Secure-passthrough crypto ─────────────────────────────────────────────

  /// Wrap inner command as AES-CBC encrypted securePassthrough envelope.
  static String _wrapPayload(
      enc.Encrypter enc_, enc.IV iv, Map<String, dynamic> inner) {
    final plain     = jsonEncode(inner);
    final encrypted = enc_.encrypt(plain, iv: iv);
    return jsonEncode({
      'method': 'securePassthrough',
      'params': {'request': encrypted.base64},
    });
  }

  /// Decrypt the securePassthrough response envelope.
  static Map<String, dynamic>? _unwrapPayload(
      enc.Encrypter enc_, enc.IV iv, Map<String, dynamic> outer) {
    try {
      final encB64 = outer['result']?['response'] as String?;
      if (encB64 == null) return null;
      final plain = enc_.decrypt64(encB64, iv: iv);
      return jsonDecode(plain) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── RSA helpers ───────────────────────────────────────────────────────────

  static pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey>
      _generateRsaKeyPair() {
    final rng = pc.FortunaRandom();
    rng.seed(pc.KeyParameter(Uint8List.fromList(
        List.generate(32, (_) => Random.secure().nextInt(256)))));

    final params = pc.RSAKeyGeneratorParameters(
      BigInt.from(65537),
      1024,
      12,
    );
    final gen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(params, rng));
    return gen.generateKeyPair();
  }

  /// RSA PKCS#1 v1.5 decrypt.
  static Uint8List _rsaDecrypt(pc.RSAPrivateKey key, Uint8List data) {
    final cipher = pc.PKCS1Encoding(pc.RSAEngine())
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(key));
    return cipher.process(data);
  }

  // ── DER / PEM encoding ────────────────────────────────────────────────────

  /// Encode RSA public key as SubjectPublicKeyInfo (X.509) PEM string.
  static String _publicKeyToPem(pc.RSAPublicKey key) {
    final der   = _spkiDer(key);
    final b64   = base64.encode(der);
    // 64-char line wrap
    final lines = RegExp(r'.{1,64}')
        .allMatches(b64)
        .map((m) => m.group(0)!)
        .join('\n');
    return '-----BEGIN PUBLIC KEY-----\n$lines\n-----END PUBLIC KEY-----\n';
  }

  /// Build SubjectPublicKeyInfo DER bytes.
  static Uint8List _spkiDer(pc.RSAPublicKey key) {
    // Inner PKCS#1 RSAPublicKey: SEQUENCE { INTEGER n, INTEGER e }
    final pkcs1 = _derSeq([
      _derInt(_bigIntBytes(key.modulus!)),
      _derInt(_bigIntBytes(key.exponent!)),
    ]);

    // AlgorithmIdentifier: SEQUENCE { OID rsaEncryption, NULL }
    const oidBytes = [
      0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01
    ];
    final algId = _derSeq([_derOid(oidBytes), _derNull()]);

    // SPKI: SEQUENCE { AlgorithmIdentifier, BIT STRING { pkcs1 } }
    return _derSeq([algId, _derBitStr(pkcs1)]);
  }

  // ASN.1 primitives
  static Uint8List _derSeq(List<Uint8List> items) {
    final body = items.fold<List<int>>([], (a, b) => [...a, ...b]);
    return Uint8List.fromList([0x30, ..._derLen(body.length), ...body]);
  }

  static Uint8List _derInt(List<int> bytes) =>
      Uint8List.fromList([0x02, ..._derLen(bytes.length), ...bytes]);

  static Uint8List _derOid(List<int> oid) =>
      Uint8List.fromList([0x06, ..._derLen(oid.length), ...oid]);

  static Uint8List _derNull() => Uint8List.fromList([0x05, 0x00]);

  static Uint8List _derBitStr(Uint8List data) {
    final content = [0x00, ...data]; // 0x00 = 0 unused bits
    return Uint8List.fromList([0x03, ..._derLen(content.length), ...content]);
  }

  static List<int> _derLen(int n) {
    if (n < 128)  return [n];
    if (n < 256)  return [0x81, n];
    return [0x82, (n >> 8) & 0xFF, n & 0xFF];
  }

  /// BigInt → unsigned DER integer bytes (prepend 0x00 if MSB is set).
  static List<int> _bigIntBytes(BigInt v) {
    var hex = v.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final bytes = List<int>.generate(
        hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
    if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) return [0x00, ...bytes];
    return bytes;
  }

  // ── SHA-1 helper ──────────────────────────────────────────────────────────

  /// Returns lowercase hex SHA-1 digest.
  static String _sha1Hex(String input) {
    final digest = pc.SHA1Digest();
    final hash   = digest.process(Uint8List.fromList(utf8.encode(input)));
    return hash
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
