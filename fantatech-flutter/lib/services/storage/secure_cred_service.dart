// Thin wrapper around flutter_secure_storage that centralises ALL
// sensitive credential I/O.  Every key that holds a token, password,
// or API key MUST go through this service — never through plain
// SharedPreferences.
//
// Storage back-ends:
//   Android  — EncryptedSharedPreferences  (AES-256 / AndroidKeyStore)
//   iOS/macOS — Keychain Services
//   Windows  — DPAPI
//
// Non-sensitive app settings (theme, locale, onboarding flag …) remain
// in SharedPreferences.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredService {
  SecureCredService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Generic read / write / delete ─────────────────────────────────────────

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _log('read error for $key: $e');
      return null;
    }
  }

  static Future<void> write(String key, String? value) async {
    try {
      if (value == null || value.isEmpty) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (e) {
      _log('write error for $key: $e');
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _log('delete error for $key: $e');
    }
  }

  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      _log('deleteAll error: $e');
    }
  }

  // ── Named credential slots ─────────────────────────────────────────────────

  // Home Assistant
  static const _kHaIp    = 'ha_ip';
  static const _kHaToken = 'ha_token';

  static Future<String?> readHaIp()    => read(_kHaIp);
  static Future<String?> readHaToken() => read(_kHaToken);
  static Future<void> saveHaCredentials(String ip, String token) async {
    await write(_kHaIp,    ip);
    await write(_kHaToken, token);
  }
  static Future<void> clearHaCredentials() async {
    await delete(_kHaIp);
    await delete(_kHaToken);
  }

  // Gateway connections (serialised JSON list)
  static const _kGateways = 'gateway_connections_v2';
  static Future<String?> readGateways()        => read(_kGateways);
  static Future<void>    saveGateways(String json) => write(_kGateways, json);
  static Future<void>    clearGateways()        => delete(_kGateways);

  // Azure Face API
  static const _kAzureKey      = 'azure_api_key';
  static const _kAzureEndpoint = 'azure_endpoint';
  static Future<String?> readAzureKey()          => read(_kAzureKey);
  static Future<String?> readAzureEndpoint()     => read(_kAzureEndpoint);
  static Future<void>    saveAzureKey(String k)  => write(_kAzureKey, k);
  static Future<void>    saveAzureEndpoint(String e) => write(_kAzureEndpoint, e);

  // Cloud camera tokens (vendor-specific)
  static Future<String?> readCameraToken(String vendor) =>
      read('cam_token_$vendor');
  static Future<String?> readCameraRefresh(String vendor) =>
      read('cam_refresh_$vendor');
  static Future<void> saveCameraToken(String vendor, String token,
      {String? refresh}) async {
    await write('cam_token_$vendor', token);
    if (refresh != null) await write('cam_refresh_$vendor', refresh);
  }
  static Future<void> clearCameraToken(String vendor) async {
    await delete('cam_token_$vendor');
    await delete('cam_refresh_$vendor');
  }

  // Dirigera certificate fingerprint (pinned on first connect)
  static const _kDirigeraFpPrefix = 'dirigera_fp_';
  static Future<String?> readDirigeraFingerprint(String ip) =>
      read('$_kDirigeraFpPrefix$ip');
  static Future<void> saveDirigeraFingerprint(String ip, String fp) =>
      write('$_kDirigeraFpPrefix$ip', fp);

  // ── Debug logger (debug builds only) ─────────────────────────────────────
  static void _log(String msg) {
    if (kDebugMode) debugPrint('[SecureCredService] $msg');
  }
}
