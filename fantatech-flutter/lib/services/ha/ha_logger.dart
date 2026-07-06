// ─────────────────────────────────────────────────────────────────────────────
// HaLogger — structured, persistent logging for the HA connection layer
//
// Features
//   • Four levels: debug / info / warning / error
//   • In-memory circular buffer (last 500 entries)
//   • Broadcast stream — live feed to a log-viewer screen
//   • Optional file persistence  (call HaLogger.initFileLogging() from main)
//   • Flutter debug console via debugPrint in debug builds
//
// Usage (anywhere in the HA service layer):
//   HaLogger.i('HaProvider',  'Connected to http://192.168.1.82:8123');
//   HaLogger.w('HaWsService', 'Heartbeat missed — scheduling reconnect');
//   HaLogger.e('HaProvider',  'Token rejected (401) — stop reconnecting');
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ── Log level ─────────────────────────────────────────────────────────────────

enum HaLogLevel { debug, info, warning, error }

// ── Log entry ─────────────────────────────────────────────────────────────────

class HaLogEntry {
  final DateTime   time;
  final HaLogLevel level;
  final String     source;
  final String     message;

  const HaLogEntry({
    required this.time,
    required this.level,
    required this.source,
    required this.message,
  });

  String get _levelTag => switch (level) {
    HaLogLevel.debug   => 'D',
    HaLogLevel.info    => 'I',
    HaLogLevel.warning => 'W',
    HaLogLevel.error   => 'E',
  };

  @override
  String toString() {
    final h  = time.hour  .toString().padLeft(2, '0');
    final m  = time.minute.toString().padLeft(2, '0');
    final s  = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '[$h:$m:$s.$ms][$_levelTag][${source.padRight(12)}] $message';
  }
}

// ── Logger singleton ──────────────────────────────────────────────────────────

class HaLogger {
  static const _maxEntries = 500;
  static const _fileName   = 'ha_connection.log';

  static final HaLogger instance = HaLogger._();
  HaLogger._();

  final _entries    = <HaLogEntry>[];
  final _controller = StreamController<HaLogEntry>.broadcast();
  IOSink? _fileSink;

  // ── Public accessors ──────────────────────────────────────────────────────

  List<HaLogEntry>   get entries => List.unmodifiable(_entries);
  Stream<HaLogEntry> get stream  => _controller.stream;

  // ── Static shortcuts ──────────────────────────────────────────────────────

  static void d(String source, String message) =>
      instance._log(HaLogLevel.debug,   source, message);
  static void i(String source, String message) =>
      instance._log(HaLogLevel.info,    source, message);
  static void w(String source, String message) =>
      instance._log(HaLogLevel.warning, source, message);
  static void e(String source, String message) =>
      instance._log(HaLogLevel.error,   source, message);

  // ── File logging (optional — call once from main()) ───────────────────────

  static Future<void> initFileLogging() async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      instance._fileSink = file.openWrite(mode: FileMode.append);
      instance._log(HaLogLevel.info, 'HaLogger',
          '─────── session start ─────── (${DateTime.now()})');
    } catch (e) {
      if (kDebugMode) debugPrint('[HaLogger] initFileLogging failed: $e');
    }
  }

  /// Returns the full log file content, or null if unavailable.
  static Future<String?> exportLog() async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      return file.existsSync() ? await file.readAsString() : null;
    } catch (_) { return null; }
  }

  /// Deletes the log file and clears the in-memory buffer.
  static Future<void> clearLog() async {
    instance._entries.clear();
    try {
      await instance._fileSink?.flush();
      await instance._fileSink?.close();
      instance._fileSink = null;
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  // ── Core ──────────────────────────────────────────────────────────────────

  void _log(HaLogLevel level, String source, String message) {
    final entry = HaLogEntry(
      time:    DateTime.now(),
      level:   level,
      source:  source,
      message: message,
    );

    // Circular in-memory buffer
    _entries.add(entry);
    if (_entries.length > _maxEntries) _entries.removeAt(0);

    // Broadcast to stream listeners (e.g. log-viewer screen)
    if (!_controller.isClosed) _controller.add(entry);

    // File persistence
    _fileSink?.writeln(entry.toString());

    // Flutter debug console (debug builds only)
    if (kDebugMode) debugPrint(entry.toString());
  }
}
