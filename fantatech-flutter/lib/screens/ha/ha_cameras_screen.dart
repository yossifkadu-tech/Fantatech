import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/layout_item.dart';
import '../../services/ha/ha_entity.dart';
import '../../services/ha/ha_provider.dart';
import '../../widgets/edit_mode/edit_mode.dart';
import 'ha_camera_viewer_screen.dart';

const _bg     = Color(0xFF0D1117);
const _card   = Color(0xFF21262D);
const _border = Color(0xFF30363D);
const _green  = Color(0xFF3FB950);
const _red    = Color(0xFFF85149);
const _text1  = Color(0xFFE6EDF3);
const _text2  = Color(0xFF8B949E);

class HaCamerasScreen extends StatelessWidget {
  const HaCamerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ha      = context.watch<HaProvider>();
    final s       = context.select((AppState st) => st.strings);
    final cameras = ha.cameras;
    final baseUrl = ha.config?.baseUrl ?? '';

    if (cameras.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.videocam_off, color: _text2, size: 48),
              SizedBox(height: 16),
              Text('אין מצלמות מחוברות ב-Home Assistant',
                  style: TextStyle(color: _text2)),
            ],
          ),
        ),
      );
    }

    // Build a stable default-items list from the live camera list.
    // Each camera gets its own LayoutItem keyed by entity ID so that
    // LayoutProvider can persist per-camera order/visibility.
    final defaultItems = cameras.asMap().entries.map((e) {
      return LayoutItem(
        id:    'ha_cam_${e.value.entityId}',
        type:  'ha_camera',
        order: e.key,
        config: {'entityId': e.value.entityId},
      );
    }).toList();

    // Build a lookup map so itemBuilder can resolve entity by id.
    final cameraById = {for (final c in cameras) c.entityId: c};

    return Scaffold(
      backgroundColor: _bg,
      body: ReorderableDashboard(
        dashboardId: 'ha_cameras',
        defaultItems: defaultItems,
        showEditButton: true,
        padding: const EdgeInsets.only(bottom: 16),
        nameResolver: (item) {
          final entityId = item.config['entityId'] as String? ?? item.id;
          return cameraById[entityId]?.friendlyName ?? entityId;
        },
        iconResolver: (_) => Symbols.videocam,
        itemBuilder: (ctx, item) {
          final entityId = item.config['entityId'] as String? ?? '';
          final cam      = cameraById[entityId];
          if (cam == null) return const SizedBox.shrink();
          final isOn = cam.isOn || cam.state == 'streaming';
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 160,
              child: _CameraCard(
                camera:    cam,
                baseUrl:   baseUrl,
                isOn:      isOn,
                liveLabel: s.liveLabel,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => HaCameraViewerScreen(camera: cam),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Camera card with live thumbnail ──────────────────────────────────────────

class _CameraCard extends StatefulWidget {
  final HaEntity camera;
  final String   baseUrl;
  final bool     isOn;
  final String   liveLabel;
  final VoidCallback onTap;

  const _CameraCard({
    required this.camera,
    required this.baseUrl,
    required this.isOn,
    required this.liveLabel,
    required this.onTap,
  });

  @override
  State<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<_CameraCard> {
  Uint8List? _thumb;
  bool       _thumbLoading = true;
  Timer?     _refreshTimer;

  String? get _thumbUrl {
    final pic = widget.camera.attributes['entity_picture'] as String?;
    if (pic == null || widget.baseUrl.isEmpty) return null;
    final base = widget.baseUrl.endsWith('/')
        ? widget.baseUrl.substring(0, widget.baseUrl.length - 1)
        : widget.baseUrl;
    return '$base$pic';
  }

  @override
  void initState() {
    super.initState();
    _fetchThumb();
    // Refresh grid thumbnail every 3 s — slow enough to not hammer HA
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchThumb(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchThumb() async {
    final url = _thumbUrl;
    if (url == null) {
      if (mounted) setState(() => _thumbLoading = false);
      return;
    }
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4)
        ..idleTimeout       = const Duration(seconds: 4);

      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();

      if (res.statusCode != 200) { client.close(); return; }

      final bytes = <int>[];
      await for (final chunk in res) {
        bytes.addAll(chunk);
        if (bytes.length > 1024 * 1024) break;
      }
      client.close();

      if (mounted) {
        setState(() {
          _thumb       = Uint8List.fromList(bytes);
          _thumbLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _thumbLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isOn
                ? _green.withValues(alpha: 0.35)
                : _border,
          ),
        ),
        child: Column(
          children: [
            // ── Thumbnail area ──────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background
                    const ColoredBox(color: Color(0xFF0A0E14)),

                    // Live snapshot
                    if (_thumb != null)
                      Image.memory(
                        _thumb!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => _camIcon,
                      )
                    else if (_thumbLoading)
                      const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: _text2),
                        ),
                      )
                    else
                      _camIcon,

                    // LIVE badge
                    if (widget.isOn)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Symbols.circle,
                                  color: Colors.white, size: 5),
                              const SizedBox(width: 3),
                              Text(widget.liveLabel,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                    // Fullscreen hint icon
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Symbols.fullscreen,
                            color: Colors.white54, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Label row ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isOn ? _green : _text2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.camera.friendlyName,
                      style: const TextStyle(
                          color: _text1,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Symbols.chevron_right,
                      color: _text2, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _camIcon = Center(
    child: Icon(Symbols.videocam,
        color: Color(0xFF2A3040), size: 44),
  );
}
