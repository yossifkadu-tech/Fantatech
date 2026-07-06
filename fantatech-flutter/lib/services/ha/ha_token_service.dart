// ─────────────────────────────────────────────────────────────────────────────
// HaTokenService — token validation + HA instance info
//
// Uses HaRestClient so every error is typed (auth / network / timeout / parse).
//
// Usage:
//   final svc    = HaTokenService(config);
//   final result = await svc.validate();
//   switch (result) {
//     case HaOk(:final data): print('HA ${data.haVersion} — ${data.locationName}');
//     case HaErr(:final error):
//       if (error.kind == HaErrorKind.auth) showInvalidTokenDialog();
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'ha_config.dart';
import 'ha_rest_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HaInstanceInfo — data returned by /api/config
// ─────────────────────────────────────────────────────────────────────────────

class HaInstanceInfo {
  final String  haVersion;
  final String  locationName;
  final String? country;
  final String? currency;
  final String  timeZone;
  final String  unitSystem;
  final List<String> components;

  const HaInstanceInfo({
    required this.haVersion,
    required this.locationName,
    this.country,
    this.currency,
    required this.timeZone,
    required this.unitSystem,
    required this.components,
  });

  factory HaInstanceInfo.fromJson(Map<String, dynamic> json) {
    final units = json['unit_system'] as Map?;
    return HaInstanceInfo(
      haVersion:    json['version']       as String? ?? 'unknown',
      locationName: json['location_name'] as String? ?? '',
      country:      json['country']       as String?,
      currency:     json['currency']      as String?,
      timeZone:     json['time_zone']     as String? ?? 'UTC',
      unitSystem:   units?['length']      as String? ?? 'km',
      components:   (json['components'] as List?)?.cast<String>() ?? [],
    );
  }

  bool hasComponent(String component) => components.contains(component);

  @override
  String toString() =>
      'HaInstanceInfo(HA $haVersion, $locationName, $timeZone)';
}

// ─────────────────────────────────────────────────────────────────────────────
// HaTokenService
// ─────────────────────────────────────────────────────────────────────────────

class HaTokenService {
  final HaRestClient _client;

  HaTokenService(HaConfig config) : _client = HaRestClient(config);

  HaTokenService.withClient(this._client);

  // ── Quick ping — just check the token is accepted ─────────────────────────

  /// Returns true when the token is valid and HA is reachable.
  /// Returns a typed [HaErr] if it isn't (check error.kind for the reason).
  Future<HaResult<bool>> ping() =>
      _client.get<bool>('/api/', parse: (_) => true);

  // ── Full validation — returns HA instance info on success ─────────────────

  /// Validates the token and returns full [HaInstanceInfo] on success.
  Future<HaResult<HaInstanceInfo>> validate() =>
      _client.get<HaInstanceInfo>(
        '/api/config',
        parse: (raw) =>
            HaInstanceInfo.fromJson(raw as Map<String, dynamic>),
      );

  // ── List registered Long-Lived Access Tokens ──────────────────────────────

  /// Returns list of LLAT metadata. Note: HA does NOT expose the raw token
  /// value in this endpoint — only id / client_name / created_at.
  Future<HaResult<List<HaTokenInfo>>> listTokens() =>
      _client.get<List<HaTokenInfo>>(
        '/api/auth/long_lived_access_token',
        parse: (raw) => (raw as List)
            .cast<Map<String, dynamic>>()
            .map(HaTokenInfo.fromJson)
            .toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HaTokenInfo — metadata about one Long-Lived Access Token
// ─────────────────────────────────────────────────────────────────────────────

class HaTokenInfo {
  final String  id;
  final String  clientName;
  final DateTime createdAt;

  const HaTokenInfo({
    required this.id,
    required this.clientName,
    required this.createdAt,
  });

  factory HaTokenInfo.fromJson(Map<String, dynamic> json) => HaTokenInfo(
        id:         json['id']          as String,
        clientName: json['client_name'] as String? ?? '',
        createdAt:  DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
