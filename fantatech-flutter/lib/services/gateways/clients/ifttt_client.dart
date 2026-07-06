// IFTTT Webhooks client
//
// IFTTT Maker Webhooks allow sending events to IFTTT applets via HTTP POST.
//
// Endpoint:
//   POST https://maker.ifttt.com/trigger/{event}/with/key/{key}
//
// Body (optional):
//   { "value1": "...", "value2": "...", "value3": "..." }
//
// No device discovery — IFTTT is outbound-only (trigger from FantaTech to IFTTT).
// To receive from IFTTT, configure an IFTTT Webhook to POST to the FantaTech
// backend API (Supabase Edge Function).
//
// Docs: https://ifttt.com/maker_webhooks
import 'dart:convert';
import 'package:http/http.dart' as http;

class IftttClient {
  static const _base    = 'https://maker.ifttt.com/trigger';
  static const _timeout = Duration(seconds: 8);

  final String _webhookKey;

  IftttClient({required String webhookKey}) : _webhookKey = webhookKey;

  /// Trigger an IFTTT event by name.
  ///
  /// [event]  — event name configured in the IFTTT Webhook applet
  /// [value1] — optional extra data (ingredient {{value1}})
  /// [value2] — optional extra data (ingredient {{value2}})
  /// [value3] — optional extra data (ingredient {{value3}})
  ///
  /// Returns true if the trigger was accepted (HTTP 200).
  Future<bool> trigger(
    String event, {
    String? value1,
    String? value2,
    String? value3,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (value1 != null) body['value1'] = value1;
      if (value2 != null) body['value2'] = value2;
      if (value3 != null) body['value3'] = value3;

      final resp = await http.post(
        Uri.parse('$_base/$event/with/key/$_webhookKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(_timeout);

      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Verify the webhook key is valid by triggering a harmless test event.
  ///
  /// Returns true if the key is accepted.
  Future<bool> testKey() async {
    return trigger('fantatech_test');
  }
}
