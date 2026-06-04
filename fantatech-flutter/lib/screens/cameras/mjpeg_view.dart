// ─────────────────────────────────────────────────────────────────────────────
// MjpegView — renders a live MJPEG stream or periodic snapshot
//
// MJPEG: parses multipart/x-mixed-replace HTTP stream into JPEG frames.
// Snapshot: fetches a JPEG image URL repeatedly at [refreshMs] interval.
// ─────────────────────────────────────────────────────────────────────────────
import '../../theme/app_theme.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

enum _Mode { mjpeg, snapshot }

class MjpegView extends StatefulWidget {
  final String url;
  final String? username;
  final String? password;

  /// For snapshot mode: refresh interval in ms. Ignored for MJPEG.
  final int refreshMs;

  const MjpegView({
    super.key,
    required this.url,
    this.username,
    this.password,
    this.refreshMs = 1000,
  });

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  Uint8List? _frame;
  String? _error;
  bool _loading = true;
  StreamSubscription<Uint8List>? _sub;
  Timer? _snapshotTimer;
  HttpClient? _client;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _snapshotTimer?.cancel();
    _client?.close(force: true);
    super.dispose();
  }

  void _start() {
    final url = widget.url;
    if (url.contains('mjpeg') || url.contains('mjpg') || url.contains('video')) {
      _startMjpeg();
    } else {
      _startSnapshot();
    }
  }

  // ── MJPEG stream ────────────────────────────────────────────────────────────

  Future<void> _startMjpeg() async {
    try {
      _client = HttpClient();
      if (widget.username != null && widget.password != null) {
        _client!.addCredentials(
          Uri.parse(widget.url),
          '',
          HttpClientBasicCredentials(widget.username!, widget.password!),
        );
      }
      final request = await _client!.getUrl(Uri.parse(widget.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        if (mounted) setState(() {
          _error = 'HTTP ${response.statusCode}';
          _loading = false;
        });
        return;
      }

      _sub = _parseMjpeg(response).listen(
        (frame) {
          if (mounted) setState(() {
            _frame = frame;
            _loading = false;
            _error = null;
          });
        },
        onError: (e) {
          if (mounted) setState(() {
            _error = 'Stream error: $e';
            _loading = false;
          });
        },
      );
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Cannot connect: $e';
        _loading = false;
      });
    }
  }

  /// Parse a multipart/x-mixed-replace MJPEG stream into individual JPEG frames.
  Stream<Uint8List> _parseMjpeg(HttpClientResponse response) async* {
    final buf = <int>[];
    // JPEG SOI marker: 0xFF 0xD8
    // JPEG EOI marker: 0xFF 0xD9
    await for (final chunk in response) {
      buf.addAll(chunk);
      // Look for complete JPEG in buffer
      int start = -1;
      for (int i = 0; i < buf.length - 1; i++) {
        if (buf[i] == 0xFF && buf[i + 1] == 0xD8) {
          start = i;
          break;
        }
      }
      if (start < 0) continue;

      int end = -1;
      for (int i = start + 2; i < buf.length - 1; i++) {
        if (buf[i] == 0xFF && buf[i + 1] == 0xD9) {
          end = i + 2;
          break;
        }
      }
      if (end < 0) continue;

      yield Uint8List.fromList(buf.sublist(start, end));
      buf.removeRange(0, end);
    }
  }

  // ── Snapshot refresh ────────────────────────────────────────────────────────

  Future<void> _startSnapshot() async {
    await _fetchSnapshot();
    if (!mounted) return;
    _snapshotTimer = Timer.periodic(
      Duration(milliseconds: widget.refreshMs),
      (_) => _fetchSnapshot(),
    );
  }

  Future<void> _fetchSnapshot() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      if (widget.username != null && widget.password != null) {
        client.addCredentials(
          Uri.parse(widget.url),
          '',
          HttpClientBasicCredentials(widget.username!, widget.password!),
        );
      }
      final req = await client.getUrl(Uri.parse(widget.url));
      final res = await req.close();

      final bytes = <int>[];
      await for (final chunk in res) {
        bytes.addAll(chunk);
        if (bytes.length > 1024 * 1024) break; // 1MB max
      }
      client.close();

      if (mounted) setState(() {
        _frame = Uint8List.fromList(bytes);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted && _frame == null) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
      );
    }
    if (_error != null && _frame == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined,
                color: context.tText2(0.38), size: 40),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: context.tText2(0.38), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_frame != null) {
      return Image.memory(
        _frame!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white38, size: 40),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
