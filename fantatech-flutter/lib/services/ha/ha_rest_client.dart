// ─────────────────────────────────────────────────────────────────────────────
// HaRestClient — typed HTTP layer for Home Assistant REST API
//
// Returns HaResult<T> instead of nullable/boolean.  Every caller gets a
// machine-readable error kind (network / auth / notFound / server / parse)
// so the UI can react differently: show "check URL" vs "invalid token" vs
// "HA returned an error".
//
// Usage:
//   final client = HaRestClient(config);
//   final result = await client.get<Map<String,dynamic>>('/api/');
//   switch (result) {
//     case HaOk(:final data):  print(data);
//     case HaErr(:final error): showError(error.message);
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ha_config.dart';
import 'ha_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HaResult — sealed result type
// ─────────────────────────────────────────────────────────────────────────────

sealed class HaResult<T> {
  const HaResult();
}

final class HaOk<T> extends HaResult<T> {
  final T data;
  const HaOk(this.data);
}

final class HaErr<T> extends HaResult<T> {
  final HaError error;
  const HaErr(this.error);
}

// ── Error detail ──────────────────────────────────────────────────────────────

enum HaErrorKind {
  network,   // socket / host unreachable
  auth,      // 401 — bad or expired token
  notFound,  // 404 — entity/endpoint does not exist
  server,    // 5xx
  timeout,   // request exceeded timeout
  parse,     // JSON decode failed
  unknown,
}

class HaError {
  final HaErrorKind kind;
  final String message;
  final int? statusCode;

  const HaError({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'HaError(${kind.name}, $message)';
}

// ─────────────────────────────────────────────────────────────────────────────
// HaRestClient
// ─────────────────────────────────────────────────────────────────────────────

class HaRestClient {
  final HaConfig config;

  const HaRestClient(this.config);

  // ── GET ──────────────────────────────────────────────────────────────────

  Future<HaResult<T>> get<T>(
    String path, {
    T Function(dynamic)? parse,
  }) async {
    try {
      final uri = Uri.parse('${config.baseUrl}$path');
      HaLogger.d('HaRestClient', 'GET $path');
      final res = await http
          .get(uri, headers: config.headers)
          .timeout(config.timeout);
      return _handle<T>(res, path: path, parse: parse);
    } on TimeoutException {
      HaLogger.e('HaRestClient', 'GET $path — timed out after ${config.timeout.inSeconds}s');
      return const HaErr(HaError(kind: HaErrorKind.timeout, message: 'Request timed out'));
    } on SocketException catch (e) {
      HaLogger.e('HaRestClient', 'GET $path — network error: ${e.message}');
      return HaErr(HaError(kind: HaErrorKind.network, message: e.message));
    } catch (e) {
      HaLogger.e('HaRestClient', 'GET $path — unexpected error: $e');
      return HaErr(HaError(kind: HaErrorKind.unknown, message: e.toString()));
    }
  }

  // ── POST ─────────────────────────────────────────────────────────────────

  Future<HaResult<T>> post<T>(
    String path,
    Map<String, dynamic> body, {
    T Function(dynamic)? parse,
  }) async {
    try {
      final uri = Uri.parse('${config.baseUrl}$path');
      HaLogger.d('HaRestClient', 'POST $path');
      final res = await http
          .post(uri, headers: config.headers, body: jsonEncode(body))
          .timeout(config.timeout);
      return _handle<T>(res, path: path, parse: parse);
    } on TimeoutException {
      HaLogger.e('HaRestClient', 'POST $path — timed out after ${config.timeout.inSeconds}s');
      return const HaErr(HaError(kind: HaErrorKind.timeout, message: 'Request timed out'));
    } on SocketException catch (e) {
      HaLogger.e('HaRestClient', 'POST $path — network error: ${e.message}');
      return HaErr(HaError(kind: HaErrorKind.network, message: e.message));
    } catch (e) {
      HaLogger.e('HaRestClient', 'POST $path — unexpected error: $e');
      return HaErr(HaError(kind: HaErrorKind.unknown, message: e.toString()));
    }
  }

  // ── service call shorthand ────────────────────────────────────────────────

  Future<bool> callService(
    String domain,
    String service, {
    String? entityId,
    Map<String, dynamic> extra = const {},
  }) async {
    final body = <String, dynamic>{...extra};
    if (entityId != null) body['entity_id'] = entityId;
    final result = await post<dynamic>('/api/services/$domain/$service', body);
    return result is HaOk;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  HaResult<T> _handle<T>(
    http.Response res, {
    String path = '',
    T Function(dynamic)? parse,
  }) {
    if (res.statusCode == 401) {
      HaLogger.e('HaRestClient',
          'HTTP 401 on $path — token invalid or revoked');
      return const HaErr(HaError(
        kind: HaErrorKind.auth,
        message: 'Invalid or expired token (401)',
        statusCode: 401,
      ));
    }
    if (res.statusCode == 404) {
      HaLogger.w('HaRestClient', 'HTTP 404 on $path');
      return const HaErr(HaError(
        kind: HaErrorKind.notFound,
        message: 'Endpoint not found (404)',
        statusCode: 404,
      ));
    }
    if (res.statusCode >= 500) {
      HaLogger.e('HaRestClient',
          'HTTP ${res.statusCode} on $path — server error');
      return HaErr(HaError(
        kind: HaErrorKind.server,
        message: 'Server error ${res.statusCode}',
        statusCode: res.statusCode,
      ));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      HaLogger.w('HaRestClient', 'HTTP ${res.statusCode} on $path');
      return HaErr(HaError(
        kind: HaErrorKind.unknown,
        message: 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      ));
    }

    if (parse != null) {
      try {
        final decoded = jsonDecode(res.body);
        return HaOk(parse(decoded));
      } catch (e) {
        HaLogger.e('HaRestClient', 'Parse error on $path: $e');
        return HaErr(HaError(kind: HaErrorKind.parse, message: 'Parse failed: $e'));
      }
    }

    // No custom parser — try to return raw decoded JSON as T
    try {
      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      return HaOk(decoded as T);
    } catch (_) {
      return HaOk(null as T);
    }
  }
}
