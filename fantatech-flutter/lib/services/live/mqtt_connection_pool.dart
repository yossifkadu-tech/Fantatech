// ─────────────────────────────────────────────────────────────────────────────
// MqttConnectionPool
//
// Singleton cache of MqttService instances keyed by "host:port".
// Guarantees one connection per broker across the entire app lifetime —
// DeviceCommander, live listeners, and any future consumer all share the
// same socket without opening duplicates.
//
// Usage:
//   final svc = await MqttConnectionPool.acquire(
//     host: '192.168.1.10', port: 1883,
//     username: 'user', password: 'pass',
//   );
//   await svc.publishJson(topic, payload);
//
// Lifecycle: call MqttConnectionPool.releaseAll() on logout/dispose.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'mqtt_service.dart';

class MqttConnectionPool {
  MqttConnectionPool._();

  static final Map<String, MqttService> _cache = {};

  // ── Acquire ────────────────────────────────────────────────────────────────

  /// Returns a connected [MqttService] for the given broker.
  ///
  /// If a cached instance exists and is already connected it is returned
  /// immediately.  Otherwise a new [MqttService] is created (and cached),
  /// then connected.  Returns null if the connection could not be established.
  static Future<MqttService?> acquire({
    required String host,
    required int port,
    String? username,
    String? password,
  }) async {
    if (host.isEmpty) return null;

    final key = '$host:$port';

    var svc = _cache[key];
    if (svc != null && svc.isConnected) return svc;

    // Create or re-create the service (stale instance replaced).
    if (svc != null) svc.dispose();
    svc = MqttService(
      host:     host,
      port:     port,
      username: username,
      password: password,
    );
    _cache[key] = svc;

    try {
      await svc.connect();
    } catch (e) {
      if (kDebugMode) debugPrint('[MqttPool] connect error ($key): $e');
    }

    if (!svc.isConnected) {
      _cache.remove(key);
      if (kDebugMode) debugPrint('[MqttPool] failed to connect to $key');
      return null;
    }

    if (kDebugMode) debugPrint('[MqttPool] connected to $key');
    return svc;
  }

  // ── Peek (no connect) ──────────────────────────────────────────────────────

  /// Returns the cached service for [host:port] only if it is already
  /// connected.  Does not attempt a new connection.
  static MqttService? peek(String host, int port) {
    final svc = _cache['$host:$port'];
    return (svc != null && svc.isConnected) ? svc : null;
  }

  // ── Release ────────────────────────────────────────────────────────────────

  /// Disconnects and removes the cached service for [host:port].
  static void release(String host, int port) {
    final key = '$host:$port';
    _cache.remove(key)?.dispose();
    if (kDebugMode) debugPrint('[MqttPool] released $key');
  }

  /// Disconnects and removes all cached services.  Call on user logout.
  static void releaseAll() {
    for (final svc in _cache.values) {
      svc.dispose();
    }
    _cache.clear();
    if (kDebugMode) debugPrint('[MqttPool] all connections released');
  }
}
