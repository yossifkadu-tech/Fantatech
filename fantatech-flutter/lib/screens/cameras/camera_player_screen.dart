// ─────────────────────────────────────────────────────────────────────────────
// CameraPlayerScreen — full-screen PTZ camera viewer
//
// • RTSP streams  → media_kit Player (real-time hardware decode)
// • MJPEG/snapshot → MjpegView (existing HTTP poller)
// • PTZ joystick  → ONVIF ContinuousMove / Stop
// • Snapshot      → saves current frame / fetches snapshot URL
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../models/face_analysis.dart';
import '../../models/known_person.dart';
import '../../services/ai/face_detection_service.dart';
import '../../services/cameras/onvif_ptz_service.dart';
import '../../theme/app_theme.dart';
import 'face_analysis_screen.dart';
import 'face_enrollment_screen.dart';
import 'mjpeg_view.dart';

class CameraPlayerScreen extends StatefulWidget {
  final Camera camera;
  const CameraPlayerScreen({super.key, required this.camera});

  @override
  State<CameraPlayerScreen> createState() => _CameraPlayerScreenState();
}

class _CameraPlayerScreenState extends State<CameraPlayerScreen> {
  // ── RTSP player ─────────────────────────────────────────────────────────────
  Player? _player;
  VideoController? _videoCtrl;

  // ── UI state ─────────────────────────────────────────────────────────────────
  bool _showOverlay = true;
  bool _ptzVisible  = true;
  bool _loading     = false;
  bool _hasError    = false;
  String? _toastMsg;

  // ── Face detection state ─────────────────────────────────────────────────────
  bool _analyzing       = false;
  List<DetectedFace> _detectedFaces = [];
  Map<int, FaceIdentityResult> _faceIdentities = {};
  Size? _frameSize; // size of the rendered video area

  // ── Snapshot capture key ─────────────────────────────────────────────────────
  final GlobalKey _captureKey = GlobalKey();

  Camera get cam => widget.camera;

  bool get _useRtsp =>
      cam.streamType == CameraStreamType.rtsp ||
      (cam.mjpegUrl == null && cam.snapshotUrl == null &&
          cam.effectiveRtspUrl != null);

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Auto-hide overlay after 3 s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showOverlay = false);
    });

    if (_useRtsp) _initRtsp();
  }

  void _initRtsp() {
    final url = cam.effectiveRtspUrl;
    if (url == null) return;

    setState(() => _loading = true);

    _player = Player();
    _videoCtrl = VideoController(_player!);

    _player!.open(Media(url)).then((_) {
      // Stream starts → clear loading after first frame
      _player!.stream.buffering.listen((buffering) {
        if (!buffering && mounted) setState(() => _loading = false);
      });
    }).catchError((_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    });

    // Also detect errors from stream
    _player!.stream.error.listen((err) {
      if (err.isNotEmpty && mounted) {
        setState(() { _loading = false; _hasError = true; });
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _player?.dispose();
    super.dispose();
  }

  // ── Face Analysis ─────────────────────────────────────────────────────────────

  Future<void> _analyzeFrame() async {
    if (_analyzing) return;
    setState(() { _analyzing = true; _detectedFaces = []; _faceIdentities = {}; });

    try {
      // 1. Capture current frame as PNG
      final boundary = _captureKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _toast('שגיאה בלכידת הפריים');
        setState(() => _analyzing = false);
        return;
      }

      final image    = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) { setState(() => _analyzing = false); return; }

      final pngBytes = byteData.buffer.asUint8List();
      _frameSize = Size(image.width.toDouble(), image.height.toDouble());

      // 2. Save to temp file (ML Kit needs file path)
      final dir  = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/face_frame_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // 3. On-device face detection (ML Kit — free, no internet)
      final faces = await FaceDetectionService.detectFromFile(file.path);

      // Capture AppState before any further awaits
      if (!mounted) { file.deleteSync(); return; }
      final appState = context.read<AppState>(); // ignore: use_build_context_synchronously

      // 4. Azure identity matching (cloud, optional — only if configured)
      Map<int, FaceIdentityResult> identities = {};
      if (faces.isNotEmpty) {
        final azureService = appState.azureFaceService;

        if (azureService != null) {
          try {
            // 4a. Ask Azure to detect faces → get faceIds + bounding boxes
            final azureFaces = await azureService.detectFaces(pngBytes);

            if (azureFaces.isNotEmpty) {
              final faceIds = azureFaces
                  .map((f) => f['faceId'] as String?)
                  .whereType<String>()
                  .toList();

              // 4b. Identify faceIds against the enrolled person group
              final resolved = await azureService.resolveIdentities(
                  faceIds, appState.knownPersons);

              // 4c. Match Azure face boxes → ML Kit face boxes by nearest center
              for (int i = 0; i < faces.length; i++) {
                final mlCenter = faces[i].boundingBox.center;

                int bestAzureIdx = -1;
                double bestDist  = double.infinity;

                for (int j = 0; j < azureFaces.length; j++) {
                  final rect =
                      azureFaces[j]['faceRectangle'] as Map<String, dynamic>?;
                  if (rect == null) continue;
                  final azCenter = Offset(
                    (rect['left'] as num).toDouble() +
                        (rect['width'] as num).toDouble() / 2,
                    (rect['top'] as num).toDouble() +
                        (rect['height'] as num).toDouble() / 2,
                  );
                  final dist = (mlCenter - azCenter).distance;
                  if (dist < bestDist) {
                    bestDist     = dist;
                    bestAzureIdx = j;
                  }
                }

                if (bestAzureIdx >= 0) {
                  final azFaceId =
                      azureFaces[bestAzureIdx]['faceId'] as String?;
                  if (azFaceId != null && resolved.containsKey(azFaceId)) {
                    identities[i] = resolved[azFaceId]!;
                  }
                }
              }
            }
          } catch (_) {
            // Azure unreachable — continue with ML Kit results only
          }
        }
      }

      // 5. Save result to AppState
      if (mounted) {
        appState.addFaceAnalysisResult(FaceAnalysisResult(
          id:         'fa_${DateTime.now().millisecondsSinceEpoch}',
          cameraId:   cam.id,
          cameraName: cam.name,
          timestamp:  DateTime.now(),
          faces:      faces,
          thumbnail:  pngBytes,
        ));

        // 6. Show overlay + toast
        final knownCount =
            identities.values.where((r) => r.identified).length;

        final msg = faces.isEmpty
            ? 'לא זוהו פנים'
            : knownCount > 0
                ? 'זוהו ${faces.length} פנים — $knownCount מזוהים 🎯'
                : 'זוהו ${faces.length} פנים 🎯';

        setState(() {
          _analyzing      = false;
          _detectedFaces  = faces;
          _faceIdentities = identities;
        });
        _toast(msg);

        // Hide face boxes after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() {
            _detectedFaces  = [];
            _faceIdentities = {};
          });
        });
      }

      // Cleanup temp file
      file.deleteSync();
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        _toast('שגיאה בניתוח: $e');
      }
    }
  }

  // ── Snapshot ──────────────────────────────────────────────────────────────────

  Future<void> _takeSnapshot() async {
    try {
      // Capture the video area as PNG
      final boundary = _captureKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) { _toast('שגיאה בצילום'); return; }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) { _toast('שגיאה בצילום'); return; }

      final bytes = byteData.buffer.asUint8List();

      // Save to app documents folder
      final dir = await getApplicationDocumentsDirectory();
      final ts  = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/snapshot_$ts.png');
      await file.writeAsBytes(bytes);

      _toast('📸 נשמר: snapshot_$ts.png');
    } catch (_) {
      _toast('שגיאה בשמירת הצילום');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    setState(() => _toastMsg = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video area ──────────────────────────────────────────────────
            RepaintBoundary(
              key: _captureKey,
              child: _useRtsp
                  ? (_videoCtrl != null
                      ? Video(controller: _videoCtrl!)
                      : const SizedBox.expand(
                          child: ColoredBox(color: Colors.black)))
                  : MjpegView(
                      url: cam.mjpegUrl ?? cam.snapshotUrl!,
                      username: cam.username,
                      password: cam.password,
                      refreshMs: cam.streamType == CameraStreamType.snapshot
                          ? 1500
                          : 500,
                    ),
            ),

            // ── Loading ──────────────────────────────────────────────────────
            if (_loading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white70),
                    const SizedBox(height: 12),
                    Text(
                      'מתחבר ל-${cam.ip ?? cam.name}...',
                      style: TextStyle(
                          color: context.tText2(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),

            // ── Error ────────────────────────────────────────────────────────
            if (_hasError && !_loading) _ErrorPlaceholder(camera: cam),

            // ── Top bar ──────────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _TopOverlay(camera: cam),
            ),

            // ── PTZ joystick ─────────────────────────────────────────────────
            if (cam.isPtz)
              Positioned(
                bottom: 90,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _ptzVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _PtzJoystick(camera: cam),
                ),
              ),

            // ── Face detection overlay ───────────────────────────────────────
            if (_detectedFaces.isNotEmpty && _frameSize != null)
              _FaceOverlay(
                faces:      _detectedFaces,
                frameSize:  _frameSize!,
                identities: _faceIdentities,
              ),

            // ── Analyzing spinner ────────────────────────────────────────────
            if (_analyzing)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.watch<AppState>().hasAzureConfig
                            ? 'מזהה פנים וזהות...'
                            : 'מזהה פנים...',
                        style: TextStyle(
                            color: context.tText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Bottom controls ──────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _BottomControls(
                  camera:      cam,
                  onSnapshot:  _takeSnapshot,
                  onAnalyze:   _analyzeFrame,
                  analyzing:   _analyzing,
                  onPtzToggle: cam.isPtz
                      ? () => setState(() => _ptzVisible = !_ptzVisible)
                      : null,
                  ptzVisible: _ptzVisible,
                  onHistory: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FaceAnalysisScreen()),
                  ),
                  onEnroll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FaceEnrollmentScreen()),
                  ),
                ),
              ),
            ),

            // ── Toast ────────────────────────────────────────────────────────
            if (_toastMsg != null)
              Positioned(
                bottom: 120,
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
                      _toastMsg!,
                      style: TextStyle(
                          color: context.tText, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar overlay ───────────────────────────────────────────────────────────

class _TopOverlay extends StatelessWidget {
  final Camera camera;
  const _TopOverlay({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.tText,
                      size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(camera.name,
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      if (camera.manufacturer != null)
                        Text(camera.manufacturer!,
                            style: TextStyle(
                                color: context.tText2(0.6), fontSize: 12)),
                      if (camera.ip != null)
                        Text(camera.ip!,
                            style: TextStyle(
                                color: context.tText2(0.38), fontSize: 11)),
                    ],
                  ),
                ),
                // PTZ badge
                if (camera.isPtz)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.control_camera_outlined,
                            color: AppColors.primary, size: 12),
                        SizedBox(width: 4),
                        Text('PTZ',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                // LIVE badge
                if (camera.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text('LIVE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ],
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

class _BottomControls extends StatelessWidget {
  final Camera camera;
  final VoidCallback onSnapshot;
  final VoidCallback onAnalyze;
  final bool analyzing;
  final VoidCallback? onPtzToggle;
  final bool ptzVisible;
  final VoidCallback onHistory;
  final VoidCallback onEnroll;

  const _BottomControls({
    required this.camera,
    required this.onSnapshot,
    required this.onAnalyze,
    required this.analyzing,
    this.onPtzToggle,
    required this.ptzVisible,
    required this.onHistory,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stream type chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.tText2(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  camera.streamType.name.toUpperCase(),
                  style: TextStyle(
                      color: context.tText2(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),

              const Spacer(),

              // Snapshot button
              _CtrlBtn(
                icon: Icons.photo_camera_outlined,
                label: 'צילום',
                onTap: onSnapshot,
              ),

              const SizedBox(width: 12),

              // Face analysis button
              _CtrlBtn(
                icon: analyzing
                    ? Icons.hourglass_top_rounded
                    : Icons.face_outlined,
                label: 'נתח',
                onTap: analyzing ? () {} : onAnalyze,
                active: analyzing,
                activeColor: const Color(0xFF00C896),
              ),

              const SizedBox(width: 12),

              // Analysis history button
              _CtrlBtn(
                icon: Icons.history_outlined,
                label: 'היסטוריה',
                onTap: onHistory,
              ),

              const SizedBox(width: 12),

              // Enroll / manage identities button
              _CtrlBtn(
                icon: Icons.person_search_outlined,
                label: 'זיהויים',
                onTap: onEnroll,
              ),

              const SizedBox(width: 12),

              // PTZ toggle button
              if (onPtzToggle != null)
                _CtrlBtn(
                  icon: Icons.gamepad_outlined,
                  label: 'PTZ',
                  onTap: onPtzToggle!,
                  active: ptzVisible,
                  activeColor: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : context.tText;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.18)
                  : context.tText2(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.8), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── PTZ Joystick ──────────────────────────────────────────────────────────────

class _PtzJoystick extends StatelessWidget {
  final Camera camera;
  const _PtzJoystick({required this.camera});

  void _move({
    double panX  = 0.0,
    double tiltY = 0.0,
    double zoomX = 0.0,
  }) {
    if (camera.ip == null) return;
    OnvifPtzService.continuousMove(
      camera.ip!,
      port:          camera.port,
      username:      camera.username,
      password:      camera.password,
      profileToken:  camera.onvifProfileToken,
      panX:  panX,
      tiltY: tiltY,
      zoomX: zoomX,
    );
  }

  void _stop() {
    if (camera.ip == null) return;
    OnvifPtzService.stop(
      camera.ip!,
      port:         camera.port,
      username:     camera.username,
      password:     camera.password,
      profileToken: camera.onvifProfileToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: context.tText2(0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text('PTZ',
              style: TextStyle(
                  color: context.tText2(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 6),

          // ↑ row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PtzBtn(
                icon: Icons.keyboard_arrow_up_rounded,
                onDown: () => _move(tiltY: 0.6),
                onUp:   _stop,
              ),
            ],
          ),

          // ← ● →
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PtzBtn(
                icon: Icons.keyboard_arrow_left_rounded,
                onDown: () => _move(panX: -0.6),
                onUp:   _stop,
              ),
              const SizedBox(width: 6),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.tText2(0.25),
                ),
              ),
              const SizedBox(width: 6),
              _PtzBtn(
                icon: Icons.keyboard_arrow_right_rounded,
                onDown: () => _move(panX: 0.6),
                onUp:   _stop,
              ),
            ],
          ),

          // ↓ row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PtzBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                onDown: () => _move(tiltY: -0.6),
                onUp:   _stop,
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Zoom row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PtzBtn(
                icon: Icons.zoom_out_rounded,
                onDown: () => _move(zoomX: -0.6),
                onUp:   _stop,
                color: const Color(0xFF00B4D8),
              ),
              const SizedBox(width: 10),
              Text('ZOOM',
                  style: TextStyle(
                      color: context.tText2(0.35),
                      fontSize: 9)),
              const SizedBox(width: 10),
              _PtzBtn(
                icon: Icons.zoom_in_rounded,
                onDown: () => _move(zoomX: 0.6),
                onUp:   _stop,
                color: const Color(0xFF00B4D8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PtzBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final Color color;

  const _PtzBtn({
    required this.icon,
    required this.onDown,
    required this.onUp,
    this.color = Colors.white,
  });

  @override
  State<_PtzBtn> createState() => _PtzBtnState();
}

class _PtzBtnState extends State<_PtzBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onUp();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.25)
              : context.tText2(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _pressed
                  ? widget.color.withValues(alpha: 0.6)
                  : context.tText2(0.15),
              width: 1.2),
        ),
        child: Icon(widget.icon, color: widget.color, size: 22),
      ),
    );
  }
}

// ── Error placeholder ─────────────────────────────────────────────────────────

// ── Face bounding-box overlay ─────────────────────────────────────────────────

class _FaceOverlay extends StatelessWidget {
  final List<DetectedFace> faces;
  final Size frameSize;
  final Map<int, FaceIdentityResult> identities;

  const _FaceOverlay({
    required this.faces,
    required this.frameSize,
    this.identities = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final scaleX = constraints.maxWidth  / frameSize.width;
        final scaleY = constraints.maxHeight / frameSize.height;

        return Stack(
          children: faces.asMap().entries.map((entry) {
            final i        = entry.key;
            final face     = entry.value;
            final box      = face.boundingBox;
            final identity = identities[i];

            final identified = identity != null && identity.identified;

            // Known person → cyan box; unknown → green
            const knownColor   = Color(0xFF00D8FF);
            const unknownColor = Color(0xFF00FF88);
            final boxColor = identified ? knownColor : unknownColor;

            final left   = box.left   * scaleX;
            final top    = box.top    * scaleY;
            final width  = box.width  * scaleX;
            final height = box.height * scaleY;

            // Build label
            String label;
            if (identified) {
              label = identity!.displayName;
            } else {
              label = 'פנים ${i + 1}${face.isSmiling ? ' 😊' : ''}';
            }

            return Positioned(
              left: left,
              top:  top,
              child: SizedBox(
                width:  width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bounding box
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: boxColor, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // Label at top-left (may overflow above the box)
                    Positioned(
                      top: -20, left: 0,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: width + 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: identified ? Colors.black : Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    // Gaze / attributes at bottom (only if not identified)
                    if (!identified)
                      Positioned(
                        bottom: 0, left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            face.gazeDirection,
                            style: TextStyle(
                                color: context.tText2(0.7),
                                fontSize: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final Camera camera;
  const _ErrorPlaceholder({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined,
              color: context.tText2(0.24), size: 56),
          const SizedBox(height: 12),
          Text(camera.name,
              style:
                  TextStyle(color: context.tText2(0.6), fontSize: 16)),
          const SizedBox(height: 6),
          Text('לא ניתן להתחבר לסטרים',
              style: TextStyle(color: context.tText2(0.38), fontSize: 13)),
          if (camera.effectiveRtspUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                camera.effectiveRtspUrl!,
                style: TextStyle(
                    color: context.tText2(0.54),
                    fontSize: 10,
                    fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
