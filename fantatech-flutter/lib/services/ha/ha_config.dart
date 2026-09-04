// ─────────────────────────────────────────────────────────────────────────────
// HaConfig — קונפיגורציה מרכזית לחיבור Home Assistant
//
// כרגע נתמך בפועל רק חיבור מקומי:  http://192.168.1.82:8123
//   - Long-Lived Access Token (נוצר ב-Profile → Security → Tokens)
//
// TODO(remote-access): כתובת מרוחקת (למשל Nabu Casa: https://xxxx.ui.nabu.casa,
// או כתובת מקומית דרך VPN כמו Tailscale) עדיין לא באמת נתמכת — HaGatewayClient
// (lib/services/gateways/clients/ha_gateway_client.dart) בונה בכל מקום
// 'http://$ip:8123' עם סכימה ופורט קבועים, כך שגם אם כאן ב-baseUrl תישמר
// כתובת https/פורט אחר, כל בקשת REST/WS בפועל עדיין תנסה להתחבר מקומית.
// כדי לאפשר גישה מרחוק בעתיד צריך לעדכן את HaGatewayClient כולו לקרוא
// scheme/port מתוך baseUrl במקום הקבועים הנוכחיים — שינוי רוחב-היקף שנוגע
// בכל נתיב השליטה במכשירים, ולכן מתוכנן כמשימה נפרדת וממוקדת כשהמשתמש
// בפועל יבחר להפעיל VPN/Nabu Casa (ולא כחצי-שינוי מוקדם).
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
