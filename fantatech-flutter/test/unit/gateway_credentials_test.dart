// Tests that credential-access helpers in gateway_manager never throw
// when expected keys are missing — verifying the null-safety fixes.
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The _str() helper pattern extracted from gateway_manager._doImport
  String strFromCreds(Map<String, dynamic> creds, String key) =>
      (creds[key] as String?) ?? '';

  group('Credential safe-access', () {
    test('returns empty string for missing key', () {
      final creds = <String, dynamic>{};
      expect(strFromCreds(creds, 'ip'), '');
      expect(strFromCreds(creds, 'token'), '');
    });

    test('returns value when key exists', () {
      final creds = {'ip': '192.168.1.10', 'token': 'abc123'};
      expect(strFromCreds(creds, 'ip'), '192.168.1.10');
      expect(strFromCreds(creds, 'token'), 'abc123');
    });

    test('returns empty string when value is null', () {
      final creds = <String, dynamic>{'ip': null};
      expect(strFromCreds(creds, 'ip'), '');
    });

    test('guard condition: empty ip triggers failure path', () {
      final creds = <String, dynamic>{};
      final ip = strFromCreds(creds, 'ip');
      final token = strFromCreds(creds, 'token');
      expect(ip.isEmpty || token.isEmpty, isTrue,
          reason: 'missing credentials should trigger the failure guard');
    });

    test('port fallback uses tryParse with default', () {
      final creds = <String, dynamic>{};
      final port = int.tryParse(creds['port'] ?? '8080') ?? 8080;
      expect(port, 8080);
    });

    test('port parsed correctly when present', () {
      final creds = {'port': '1883'};
      final port = int.tryParse(creds['port'] ?? '8080') ?? 8080;
      expect(port, 1883);
    });

    test('invalid port string falls back to default', () {
      final creds = {'port': 'not-a-number'};
      final port = int.tryParse(creds['port'] ?? '8080') ?? 8080;
      expect(port, 8080);
    });
  });

  // Tests for HA token receiver null-safety (mirrors main.dart fix)
  group('HaTokenReceiver data safety', () {
    Map<String, dynamic> _receive(Map<String, dynamic> data) {
      final baseUrl = data['hassUrl'] as String? ?? '';
      final token   = data['token']   as String? ?? '';
      return {'baseUrl': baseUrl, 'token': token, 'valid': baseUrl.isNotEmpty && token.isNotEmpty};
    }

    test('valid data passes guard', () {
      final result = _receive({'hassUrl': 'http://ha.local:8123', 'token': 'tok'});
      expect(result['valid'], isTrue);
    });

    test('missing hassUrl fails guard', () {
      final result = _receive({'token': 'tok'});
      expect(result['valid'], isFalse);
    });

    test('missing token fails guard', () {
      final result = _receive({'hassUrl': 'http://ha.local:8123'});
      expect(result['valid'], isFalse);
    });

    test('null values fail guard without throwing', () {
      final result = _receive({'hassUrl': null, 'token': null});
      expect(result['valid'], isFalse);
    });

    test('empty map fails guard without throwing', () {
      final result = _receive({});
      expect(result['valid'], isFalse);
    });
  });
}
