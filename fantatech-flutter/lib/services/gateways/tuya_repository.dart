import 'dart:async';

import '../../models/device.dart';
import 'clients/tuya_cloud_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain models
// ─────────────────────────────────────────────────────────────────────────────

class TuyaLoginResult {
  final bool   success;
  final String? token;
  final String? error;

  const TuyaLoginResult.ok(this.token)
      : success = true,
        error   = null;

  const TuyaLoginResult.fail(this.error)
      : success = false,
        token   = null;
}

/// A single datapoint command sent to a Tuya device.
/// [code] is the Tuya DP code (e.g. "switch_led", "bright_value_v2").
/// [value] can be bool, int, String, or double.
class TuyaCommand {
  final String code;
  final dynamic value;

  const TuyaCommand({required this.code, required this.value});

  Map<String, dynamic> toJson() => {'code': code, 'value': value};
}

class TuyaControlResult {
  final bool   success;
  final String? error;

  const TuyaControlResult.ok()   : success = true,  error = null;
  const TuyaControlResult.fail(this.error) : success = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract contract
// ─────────────────────────────────────────────────────────────────────────────

abstract class TuyaRepository {
  /// Authenticate with the Tuya OpenAPI and cache the access token.
  Future<TuyaLoginResult> login();

  /// Fetch all devices linked to the account.
  /// Returns a list of [SmartDevice] (type is the Tuya category string).
  Future<List<SmartDevice>> getDevices();

  /// Send [commands] to [deviceId] (the Tuya device ID, not the local app ID).
  Future<TuyaControlResult> controlDevice({
    required String deviceId,
    required List<TuyaCommand> commands,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

class TuyaRepositoryImpl implements TuyaRepository {
  final TuyaCloudClient _client;

  /// Cached access token. Tuya tokens expire after 7200 s; callers should
  /// call [login] again when [controlDevice] returns a 401-style failure.
  String? _token;

  TuyaRepositoryImpl({
    required String clientId,
    required String clientSecret,
    TuyaRegion region = TuyaRegion.eu,
  }) : _client = TuyaCloudClient(
          clientId:     clientId,
          clientSecret: clientSecret,
          region:       region,
        );

  // ── login ──────────────────────────────────────────────────────────────────

  @override
  Future<TuyaLoginResult> login() async {
    final token = await _client.getToken();
    if (token == null) {
      return const TuyaLoginResult.fail(
          'Authentication failed — check Access ID, Secret and region.');
    }
    _token = token;
    return TuyaLoginResult.ok(token);
  }

  // ── getDevices ─────────────────────────────────────────────────────────────

  @override
  Future<List<SmartDevice>> getDevices() async {
    // Ensure we have a valid token
    if (_token == null) {
      final result = await login();
      if (!result.success) return [];
    }

    final importResult = await TuyaCloudClient.fetchDevices(
      clientId:     _client.clientId,
      clientSecret: _client.clientSecret,
      region:       _client.region,
    );

    if (!importResult.isSuccess) return [];

    return importResult.devices.map((d) => SmartDevice(
      id:      d.attributes['tuyaId'] as String? ?? d.id,
      name:    d.name,
      room:    d.room,
      type:    d.attributes['category'] as String? ?? d.type.name,
      online:  d.status == DeviceStatus.online,
      battery: d.battery ?? -1,
    )).toList();
  }

  // ── controlDevice ──────────────────────────────────────────────────────────

  @override
  Future<TuyaControlResult> controlDevice({
    required String deviceId,
    required List<TuyaCommand> commands,
  }) async {
    if (_token == null) {
      final loginResult = await login();
      if (!loginResult.success) {
        return TuyaControlResult.fail(loginResult.error);
      }
    }

    final ok = await _client.sendCommands(
      token:          _token!,
      tuyaDeviceId:   deviceId,
      commands:       commands.map((c) => c.toJson()).toList(),
    );

    if (!ok) {
      // Token may have expired — retry once with a fresh token
      _token = null;
      final refresh = await login();
      if (!refresh.success) return TuyaControlResult.fail(refresh.error);

      final retry = await _client.sendCommands(
        token:        _token!,
        tuyaDeviceId: deviceId,
        commands:     commands.map((c) => c.toJson()).toList(),
      );

      return retry
          ? const TuyaControlResult.ok()
          : const TuyaControlResult.fail('Command failed after token refresh.');
    }

    return const TuyaControlResult.ok();
  }
}
