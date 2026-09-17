// ─────────────────────────────────────────────────────────────────────────────
// HubConfig — connection details for a self-hosted FantaTech Hub (hub/, the
// Python/FastAPI local-first gateway — see the `gateway` skill). Unlike Tuya
// Smart/Smart Life (cloud), this always targets a LAN address the user
// configured, same shape as Home Assistant's baseUrl+token, except the hub
// currently has no authentication of its own, so apiKey is optional and
// unused until the hub gains one.
// ─────────────────────────────────────────────────────────────────────────────

class HubConfig {
  /// e.g. http://192.168.10.125:8080
  final String baseUrl;

  /// Reserved for when the hub adds its own auth — not required today.
  final String? apiKey;

  final Duration timeout;

  const HubConfig({
    required this.baseUrl,
    this.apiKey,
    this.timeout = const Duration(seconds: 10),
  });

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };
}
