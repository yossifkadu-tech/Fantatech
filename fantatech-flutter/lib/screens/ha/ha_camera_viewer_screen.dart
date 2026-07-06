import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HaCameraViewerScreen — fullscreen live viewer for a Home Assistant camera
//
// Features:
//   • Live   — polls HA camera_proxy snapshot at 250 ms for a smooth feed
//   • Snapshot — fetches the current frame and saves it to app documents
//   • Fullscreen — immersive mode + optional landscape lock on demand
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../services/ha/ha_entity.dart';
import '../../services/ha/ha_provider.dart';
import '../../theme/app_theme.dart';

class HaCameraViewerScreen extends StatefulWidget {
  final HaEntity camera;
  const HaCameraViewerScreen({super.key, required this.camera});

  @override
  State<HaCameraViewerScreen> createState() => _HaCameraViewerScreenState();
}

class _HaCameraViewerScreenState extends State<HaCameraViewerScreen> {
  Uint8List? _frame;
  String?    _error;
  bool       _loading    = true;
  bool       _showHud    = true;
  bool       _landscape  = false;
  bool       _saving     = false;
  String?    _toast;

  Timer? _pollTimer;
  Timer? _hudTimer;
  Timer? _toastTimer;

  String? get _snapshotUrl {
    final cfg  = context.read<HaProvider>().config;
    if (cfg == null) return null;
    final pic = widget.camera.attributes['entity_picture'] as String?;
    if (pic == null) return null;
    // entity_picture is a relative path like /api/camera_proxy/camera.xxx?token=...
    final base = cfg.baseUrl.endsWith('/') ? cfg.baseUrl.substring(0, cfg.baseUrl.length - 1) : cfg.baseUrl;
    return '$base$pic';
  }

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    _fetchFrame();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) => _fetchFrame());
    _autoHideHud();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _hudTimer?.cancel();
    _toastTimer?.cancel();
    _exitFullscreen();
    super.dispose();
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    setState(() => _landscape = true);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _toggleLandscape() {
    setState(() => _landscape = !_landscape);
    SystemChrome.setPreferredOrientations(
      _landscape
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
             DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  void _autoHideHud() {
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHud = false);
    });
  }

  void _tapToToggleHud() {
    setState(() => _showHud = !_showHud);
    if (_showHud) _autoHideHud();
  }

  Future<void> _fetchFrame() async {
    final url = _snapshotUrl;
    if (url == null) {
      if (mounted) setState(() { _error = 'no_stream'; _loading = false; });
      return;
    }
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4)
        ..idleTimeout       = const Duration(seconds: 4);

      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();

      if (res.statusCode != 200) {
        client.close();
        if (mounted && _frame == null) {
          setState(() { _error = 'HTTP ${res.statusCode}'; _loading = false; });
        }
        return;
      }

      final bytes = <int>[];
      await for (final chunk in res) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) break; // 2 MB guard
      }
      client.close();

      if (mounted) {
        setState(() {
          _frame   = Uint8List.fromList(bytes);
          _loading = false;
          _error   = null;
        });
      }
    } catch (e) {
      if (mounted && _frame == null) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _saveSnapshot() async {
    if (_saving) return;
    final url = _snapshotUrl;
    if (url == null || _frame == null) {
      _showToast('אין פריים זמין');
      return;
    }
    setState(() => _saving = true);

    try {
      final dir  = await getApplicationDocumentsDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final name = widget.camera.entityId.replaceAll('.', '_');
      final file = File('${dir.path}/ha_snap_${name}_$ts.jpg');
      await file.writeAsBytes(_frame!);
      _showToast('נשמר: ha_snap_${name}_$ts.jpg');
    } catch (e) {
      _showToast('שגיאה: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    _toastTimer?.cancel();
    setState(() => _toast = msg);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tapToToggleHud,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Live feed ─────────────────────────────────────────────────
            _buildFeed(),

            // ── Top HUD ───────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showHud ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showHud,
                child: _TopBar(camera: widget.camera, onBack: () => Navigator.pop(context)),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showHud ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showHud,
                child: _BottomBar(
                  saving:    _saving,
                  landscape: _landscape,
                  onSnapshot: _saveSnapshot,
                  onFullscreen: _toggleLandscape,
                  streamType: widget.camera.attributes['entity_picture'] != null
                      ? 'LIVE'
                      : 'N/A',
                ),
              ),
            ),

            // ── Toast ─────────────────────────────────────────────────────
            if (_toast != null)
              Positioned(
                bottom: 100,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _toast!,
                      style: TextStyle(color: context.tText, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white60),
            SizedBox(height: 12),
            Text('מתחבר…', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }
    if (_error != null && _frame == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.videocam_off, color: Colors.white24, size: 64),
            const SizedBox(height: 12),
            Text(
              _error == 'no_stream' ? 'מצלמה זו אינה מספקת stream' : _error!,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_frame != null) {
      return Image.memory(
        _frame!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Symbols.broken_image, color: Colors.white24, size: 48),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final HaEntity camera;
  final VoidCallback onBack;
  const _TopBar({required this.camera, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isOn = camera.isOn || camera.state == 'streaming';
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Symbols.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camera.friendlyName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        camera.entityId,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // LIVE badge
                if (isOn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusAlarm,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text('LIVE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                if (!isOn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      camera.state.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom controls ───────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool saving;
  final bool landscape;
  final String streamType;
  final VoidCallback onSnapshot;
  final VoidCallback onFullscreen;

  const _BottomBar({
    required this.saving,
    required this.landscape,
    required this.streamType,
    required this.onSnapshot,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Stream type chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    streamType,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8),
                  ),
                ),

                // Snapshot button
                _Btn(
                  icon: saving
                      ? Symbols.hourglass_top
                      : Symbols.photo_camera,
                  label: 'Snapshot',
                  active: saving,
                  activeColor: AppColors.primary,
                  onTap: onSnapshot,
                ),

                // Fullscreen toggle
                _Btn(
                  icon: landscape
                      ? Symbols.fullscreen_exit
                      : Symbols.fullscreen,
                  label: landscape ? 'Landscape' : 'Fullscreen',
                  active: landscape,
                  activeColor: const Color(0xFF00C896),
                  onTap: onFullscreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final col = active ? activeColor : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: col.withValues(alpha: 0.30), width: 1.2),
            ),
            child: Icon(icon, color: col, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  color: col.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
