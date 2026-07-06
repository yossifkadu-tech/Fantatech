// ─────────────────────────────────────────────────────────────────────────────
// HaConfig — קונפיגורציה מרכזית לחיבור Home Assistant
//
// תומך ב:
//   - חיבור מקומי:  http://192.168.1.82:8123
//   - Nabu Casa:    https://xxxx.ui.nabu.casa
//   - Long-Lived Access Token (נוצר ב-Profile → Security → Tokens)
// ─────────────────────────────────────────────────────────────────────────────

class HaConfig {
  /// כתובת בסיס מלאה — לדוגמה: http://192.168.1.82:8123
  /// או https://xxxx.ui.nabu.casa
  final String baseUrl;

  /// Long-Lived Access Token
  final String token;

  /// זמן מקסימי לבקשות REST (ברירת מחדל: 10 שניות)
  final Duration timeout;

  const HaConfig({
    required this.baseUrl,
    required this.token,
    this.timeout = const Duration(seconds: 10),
  });

  /// כתובת ה-WebSocket — http→ws, https→wss
  String get wsUrl =>
      baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
        'Content-Type':  'application/json',
      };

  HaConfig copyWith({String? baseUrl, String? token, Duration? timeout}) =>
      HaConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        token:   token   ?? this.token,
        timeout: timeout ?? this.timeout,
      );
}
