// ─────────────────────────────────────────────────────────────────────────────
// HubRestClient — typed HTTP layer for the self-hosted FantaTech Hub REST API
// (hub/routers/*.py). Modeled directly on ha_rest_client.dart's HaResult
// pattern (same shape, same reasoning: a machine-readable error kind per
// call instead of a bare bool/null) — kept as its own small class rather
// than reusing HaRestClient/HaConfig so a hub connection doesn't get named
// after an unrelated integration (Home Assistant) in code that will outlive
// this comment.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'hub_config.dart';

sealed class HubResult<T> {
  const HubResult();
}

final class HubOk<T> extends HubResult<T> {
  final T data;
  const HubOk(this.data);
}

final class HubErr<T> extends HubResult<T> {
  final HubError error;
  const HubErr(this.error);
}

enum HubErrorKind { network, notFound, server, timeout, parse, unknown }

class HubError {
  final HubErrorKind kind;
  final String message;
  final int? statusCode;

  const HubError({required this.kind, required this.message, this.statusCode});

  @override
  String toString() => 'HubError(${kind.name}, $message)';
}

class HubRestClient {
  final HubConfig config;

  const HubRestClient(this.config);

  Future<HubResult<T>> get<T>(String path, {T Function(dynamic)? parse}) async {
    try {
      final uri = Uri.parse('${config.baseUrl}$path');
      final res = await http.get(uri, headers: config.headers).timeout(config.timeout);
      return _handle<T>(res, path: path, parse: parse);
    } on TimeoutException {
      return const HubErr(HubError(kind: HubErrorKind.timeout, message: 'Request timed out'));
    } on SocketException catch (e) {
      return HubErr(HubError(kind: HubErrorKind.network, message: e.message));
    } catch (e) {
      debugPrint('[HubRestClient] GET $path — unexpected error: $e');
      return HubErr(HubError(kind: HubErrorKind.unknown, message: e.toString()));
    }
  }

  Future<HubResult<T>> post<T>(
    String path,
    Map<String, dynamic> body, {
    T Function(dynamic)? parse,
  }) async {
    try {
      final uri = Uri.parse('${config.baseUrl}$path');
      final res = await http
          .post(uri, headers: config.headers, body: jsonEncode(body))
          .timeout(config.timeout);
      return _handle<T>(res, path: path, parse: parse);
    } on TimeoutException {
      return const HubErr(HubError(kind: HubErrorKind.timeout, message: 'Request timed out'));
    } on SocketException catch (e) {
      return HubErr(HubError(kind: HubErrorKind.network, message: e.message));
    } catch (e) {
      debugPrint('[HubRestClient] POST $path — unexpected error: $e');
      return HubErr(HubError(kind: HubErrorKind.unknown, message: e.toString()));
    }
  }

  HubResult<T> _handle<T>(http.Response res, {String path = '', T Function(dynamic)? parse}) {
    if (res.statusCode == 404) {
      return const HubErr(HubError(kind: HubErrorKind.notFound, message: 'Not found (404)', statusCode: 404));
    }
    if (res.statusCode >= 500) {
      return HubErr(HubError(kind: HubErrorKind.server, message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // The hub's endpoints raise HTTPException with a JSON {"detail": ...}
      // body on 4xx/5xx (see hub/routers/tuya.py) — surface that detail
      // instead of just the bare status code when present.
      String message = 'HTTP ${res.statusCode}';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        // body wasn't JSON — keep the generic message
      }
      return HubErr(HubError(kind: HubErrorKind.unknown, message: message, statusCode: res.statusCode));
    }

    if (parse != null) {
      try {
        final decoded = jsonDecode(res.body);
        return HubOk(parse(decoded));
      } catch (e) {
        return HubErr(HubError(kind: HubErrorKind.parse, message: 'Parse failed: $e'));
      }
    }

    try {
      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      return HubOk(decoded as T);
    } catch (_) {
      return HubOk(null as T);
    }
  }
}
