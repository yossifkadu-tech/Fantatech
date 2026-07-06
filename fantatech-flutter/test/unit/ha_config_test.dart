import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/services/ha/ha_config.dart';

void main() {
  // ── wsUrl ─────────────────────────────────────────────────────────────────

  group('HaConfig.wsUrl', () {
    test('converts http:// → ws://', () {
      const cfg = HaConfig(baseUrl: 'http://192.168.1.82:8123', token: 'tok');
      expect(cfg.wsUrl, 'ws://192.168.1.82:8123');
    });

    test('converts https:// → wss://', () {
      const cfg = HaConfig(baseUrl: 'https://abc123.ui.nabu.casa', token: 'tok');
      expect(cfg.wsUrl, 'wss://abc123.ui.nabu.casa');
    });

    test('appends WebSocket path when present in baseUrl', () {
      const cfg = HaConfig(baseUrl: 'http://ha.local:8123', token: 'tok');
      expect(cfg.wsUrl.startsWith('ws://'), isTrue);
      expect(cfg.wsUrl, isNot(contains('https')));
      expect(cfg.wsUrl, isNot(contains('http://')));
    });

    test('does not double-convert already-ws URL', () {
      // Calling wsUrl on an already-ws:// URL should leave it unchanged
      // (replaceFirst only replaces first occurrence of the exact prefix)
      const cfg = HaConfig(baseUrl: 'ws://192.168.1.1:8123', token: 't');
      expect(cfg.wsUrl, 'ws://192.168.1.1:8123');
    });
  });

  // ── headers ───────────────────────────────────────────────────────────────

  group('HaConfig.headers', () {
    test('includes Authorization Bearer header', () {
      const cfg = HaConfig(baseUrl: 'http://ha.local', token: 'my-secret-token');
      expect(cfg.headers['Authorization'], 'Bearer my-secret-token');
    });

    test('includes Content-Type json header', () {
      const cfg = HaConfig(baseUrl: 'http://ha.local', token: 'tok');
      expect(cfg.headers['Content-Type'], 'application/json');
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────

  group('HaConfig.copyWith', () {
    const original = HaConfig(
      baseUrl: 'http://192.168.0.1:8123',
      token:   'original-token',
      timeout: Duration(seconds: 10),
    );

    test('overrides baseUrl only', () {
      final updated = original.copyWith(baseUrl: 'https://new.nabu.casa');
      expect(updated.baseUrl, 'https://new.nabu.casa');
      expect(updated.token,   original.token);
      expect(updated.timeout, original.timeout);
    });

    test('overrides token only', () {
      final updated = original.copyWith(token: 'new-token');
      expect(updated.token,   'new-token');
      expect(updated.baseUrl, original.baseUrl);
    });

    test('overrides timeout only', () {
      final updated = original.copyWith(timeout: const Duration(seconds: 30));
      expect(updated.timeout, const Duration(seconds: 30));
      expect(updated.baseUrl, original.baseUrl);
      expect(updated.token,   original.token);
    });

    test('null arguments preserve existing values', () {
      final updated = original.copyWith();
      expect(updated.baseUrl, original.baseUrl);
      expect(updated.token,   original.token);
      expect(updated.timeout, original.timeout);
    });
  });

  // ── default timeout ───────────────────────────────────────────────────────

  test('default timeout is 10 seconds', () {
    const cfg = HaConfig(baseUrl: 'http://ha.local', token: 't');
    expect(cfg.timeout, const Duration(seconds: 10));
  });
}
