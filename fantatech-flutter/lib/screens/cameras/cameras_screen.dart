import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../services/cameras/onvif_service.dart';
import '../notifications/notifications_screen.dart';
import '../smarthome/add_device_screen.dart';
import 'camera_player_screen.dart';
import 'mjpeg_view.dart';
import 'z2m_connect_sheet.dart';

// ── Helper: map neutral room key → localized display string ────
String _localizeRoom(String room, S s) {
  if (room == 'indoor') return s.cameraRoomIndoor;
  if (room == 'outdoor') return s.cameraRoomOutdoor;
  return room; // user-defined room names pass through as-is
}

class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRoom = '';
  late AnimationController _liveBlink;
  bool _scanning = false;
  int _scanFound = 0;

  @override
  void initState() {
    super.initState();
    _liveBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _liveBlink.dispose();
    super.dispose();
  }

  // ── Scan for cameras on LAN ──────────────────────────────────
  Future<void> _scanForCameras() async {
    // Capture context-dependent objects before any await
    final appState = context.read<AppState>();
    setState(() { _scanning = true; _scanFound = 0; });

    String? localIp;
    try {
      localIp = await NetworkInfo().getWifiIP();
    } catch (_) {}

    if (localIp == null) {
      if (mounted) setState(() => _scanning = false);
      return;
    }

    final parts = localIp.split('.');
    if (parts.length != 4) {
      if (mounted) setState(() => _scanning = false);
      return;
    }
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    int found = 0;

    await for (final cam in OnvifService.scanSubnet(prefix)) {
      if (!mounted) break;
      final camera = cam.toCamera();
      appState.addRealCamera(camera);
      found++;
      setState(() => _scanFound = found);
    }

    if (mounted) setState(() => _scanning = false);
  }

  // ── Add camera manually ──────────────────────────────────────
  void _showAddManualSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ManualCameraSheet(
        onAdd: (camera) => context.read<AppState>().addRealCamera(camera),
      ),
    );
  }

  // ── Z2M connect ──────────────────────────────────────────────
  void _showZ2MSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const Z2MConnectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    final rooms = ['', ...{...state.cameras.map((c) => c.room)}];

    final filtered = _selectedRoom.isEmpty
        ? state.cameras
        : state.cameras.where((c) => c.room == _selectedRoom).toList();

    return Scaffold(
      backgroundColor: context.tBg,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Zigbee2MQTT button
          FloatingActionButton.small(
            heroTag: 'z2m',
            onPressed: () => _showZ2MSheet(context),
            backgroundColor: const Color(0xFFFF9D00),
            child: Icon(Icons.settings_input_antenna, size: 18),
          ),
          const SizedBox(height: 8),
          // Add manually button
          FloatingActionButton.small(
            heroTag: 'manual',
            onPressed: () => _showAddManualSheet(context),
            backgroundColor: AppColors.primary,
            child: Icon(Icons.videocam_outlined, size: 18),
          ),
          const SizedBox(height: 8),
          // Scan button
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: _scanning ? null : _scanForCameras,
            backgroundColor: _scanning
                ? context.tText2(0.12)
                : const Color(0xFF00B4D8),
            icon: _scanning
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.radar, size: 18),
            label: Text(
              _scanning
                  ? 'סורק... ${_scanFound > 0 ? "($_scanFound)" : ""}'
                  : 'סרוק רשת',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(title: s.camerasTitle),

            const SizedBox(height: 12),

            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final selected = _selectedRoom == rooms[i];
                  final label = rooms[i].isEmpty
                      ? s.allCameras
                      : _localizeRoom(rooms[i], s);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRoom = rooms[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : context.tText2(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : context.tText2(0.1),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? context.tText
                              : context.tText2(0.55),
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _CameraCard(
                  camera: filtered[i],
                  isFirst: i == 0,
                  blinkAnim: _liveBlink,
                  s: s,
                  onTap: () => _openFullscreen(context, filtered[i], s),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, Camera camera, S s) {
    if (camera.hasRealStream) {
      // Real camera — use the MJPEG/stream player
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CameraPlayerScreen(camera: camera)));
    } else {
      // Mock/demo camera — use existing fullscreen viewer
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => _FullscreenCamera(camera: camera)));
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.tText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  Icons.notifications_outlined, color: context.tText, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(
                  Icons.add, color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Camera card
// ─────────────────────────────────────────────────────────────
class _CameraCard extends StatelessWidget {
  final Camera camera;
  final bool isFirst;
  final AnimationController blinkAnim;
  final S s;
  final VoidCallback onTap;

  const _CameraCard({
    required this.camera,
    required this.isFirst,
    required this.blinkAnim,
    required this.s,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = isFirst ? 200.0 : 140.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real stream preview or simulated night scene
              camera.mjpegUrl != null || camera.snapshotUrl != null
                  ? MjpegView(
                      url: camera.mjpegUrl ?? camera.snapshotUrl!,
                      username: camera.username,
                      password: camera.password,
                      refreshMs: 2000,
                    )
                  : _NightSceneBackground(
                      camera: camera,
                      seed: camera.id.hashCode,
                    ),

              // Bottom gradient for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // LIVE badge (always visible)
              if (camera.isOnline)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _LiveBadge(blinkAnim: blinkAnim, s: s),
                ),

              // OFFLINE badge (always visible)
              if (!camera.isOnline)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.offlineLabel,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

              // Play button
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.tText2(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: context.tText,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Camera name + room (always visible at bottom)
              Positioned(
                bottom: 12,
                left: 14,
                right: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      camera.name,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                    ),
                    Text(
                      _localizeRoom(camera.room, s),
                      style: TextStyle(
                        color: context.tText2(0.65),
                        fontSize: 11,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Night scene background (simulated camera feed)
// ─────────────────────────────────────────────────────────────
class _NightSceneBackground extends StatelessWidget {
  final Camera camera;
  final int seed;

  const _NightSceneBackground({required this.camera, required this.seed});

  @override
  Widget build(BuildContext context) {
    // Use neutral key 'indoor' — language-independent
    final isIndoor = camera.room == 'indoor';
    final List<Color> palette = isIndoor
        ? [
            context.tCard,
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ]
        : [
            const Color(0xFF0D1117),
            const Color(0xFF1A2332),
            const Color(0xFF0A1628),
          ];

    return CustomPaint(
      painter: _NightScenePainter(
        palette: palette,
        seed: seed,
        isOutdoor: !isIndoor,
        isOnline: camera.isOnline,
      ),
    );
  }
}

class _NightScenePainter extends CustomPainter {
  final List<Color> palette;
  final int seed;
  final bool isOutdoor;
  final bool isOnline;

  _NightScenePainter({
    required this.palette,
    required this.seed,
    required this.isOutdoor,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isOnline ? palette : [Colors.black, const Color(0xFF1A1A1A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!isOnline) {
      final textPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), 28, textPaint);
      return;
    }

    if (isOutdoor) {
      for (int i = 0; i < 30; i++) {
        final x = rng.nextDouble() * size.width;
        final y = rng.nextDouble() * size.height * 0.5;
        final r = rng.nextDouble() * 1.2 + 0.4;
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = Colors.white.withValues(
                alpha: 0.3 + rng.nextDouble() * 0.5),
        );
      }

      final groundPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D1F0D).withValues(alpha: 0.0),
            const Color(0xFF0D1F0D).withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromLTWH(
            0, size.height * 0.55, size.width, size.height * 0.45));
      canvas.drawRect(
        Rect.fromLTWH(
            0, size.height * 0.55, size.width, size.height * 0.45),
        groundPaint,
      );

      canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.2),
        55,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF5D6).withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(
            center: Offset(size.width * 0.75, size.height * 0.2),
            radius: 55,
          )),
      );

      final silPaint = Paint()
        ..color = const Color(0xFF060C14)
        ..style = PaintingStyle.fill;

      for (int t = 0; t < 2; t++) {
        final tx = size.width * (0.1 + t * 0.65);
        final ty = size.height * 0.45;
        final path = Path()
          ..moveTo(tx, ty - 40)
          ..lineTo(tx - 18, ty)
          ..lineTo(tx + 18, ty)
          ..close();
        canvas.drawPath(path, silPaint);
        canvas.drawRect(
            Rect.fromLTWH(tx - 5, ty, 10, 20), silPaint);
      }
    } else {
      final lightPaint = Paint()
        ..color = const Color(0xFF1A3050).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.55, size.height * 0.1,
              size.width * 0.35, size.height * 0.55),
          const Radius.circular(4),
        ),
        lightPaint,
      );

      canvas.drawLine(
        Offset(0, size.height * 0.75),
        Offset(size.width, size.height * 0.75),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 1,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.05, size.height * 0.6,
              size.width * 0.45, size.height * 0.15),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF0F1A28),
      );
    }

    if (isOutdoor) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = const Color(0xFF002200).withValues(alpha: 0.12)
          ..blendMode = BlendMode.overlay,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// LIVE badge
// ─────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  final AnimationController blinkAnim;
  final S s;
  const _LiveBadge({required this.blinkAnim, required this.s});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: blinkAnim,
      builder: (ctx, _) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.secured.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secured.withValues(
                    alpha: 0.4 + blinkAnim.value * 0.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secured
                        .withValues(alpha: blinkAnim.value * 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              s.liveLabel,
              style: TextStyle(
                color: AppColors.secured,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Fullscreen camera view — captions always visible
// ─────────────────────────────────────────────────────────────
class _FullscreenCamera extends StatefulWidget {
  final Camera camera;
  const _FullscreenCamera({required this.camera});

  @override
  State<_FullscreenCamera> createState() => _FullscreenCameraState();
}

class _FullscreenCameraState extends State<_FullscreenCamera>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _NightSceneBackground(
            camera: widget.camera,
            seed: widget.camera.id.hashCode,
          ),

          // Top + bottom gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Top bar — always visible ───────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.chevron_right,
                          color: context.tText, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.camera.name,
                        style: TextStyle(
                          color: context.tText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _localizeRoom(widget.camera.room, s),
                        style: TextStyle(
                          color: context.tText2(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.fullscreen,
                        color: context.tText, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── LIVE badge — always visible ───────────────────────
          if (widget.camera.isOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              child: _LiveBadge(blinkAnim: _blink, s: s),
            ),

          // ── Bottom controls — always visible ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlBtn(icon: Icons.mic_outlined,               label: s.micLabel),
                  _ControlBtn(icon: Icons.record_voice_over_outlined, label: s.speakLabel),
                  _ControlBtn(icon: Icons.screenshot_outlined,        label: s.screenshotLabel),
                  _ControlBtn(
                      icon: Icons.fiber_manual_record,
                      label: s.recordLabel,
                      color: AppColors.unsecured),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ControlBtn({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: context.tText2(0.12),
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: context.tText2(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Manual camera add sheet
// ─────────────────────────────────────────────────────────────
class _ManualCameraSheet extends StatefulWidget {
  final void Function(Camera) onAdd;
  const _ManualCameraSheet({required this.onAdd});

  @override
  State<_ManualCameraSheet> createState() => _ManualCameraSheetState();
}

class _ManualCameraSheetState extends State<_ManualCameraSheet> {
  final _nameCtrl  = TextEditingController(text: 'IP Camera');
  final _ipCtrl    = TextEditingController();
  final _portCtrl  = TextEditingController(text: '80');
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pathCtrl  = TextEditingController(text: '/mjpeg');
  String _room = 'outdoor';
  bool _testing = false;
  String? _testResult;

  // Protocol selector: 'mjpeg' | 'rtsp' | 'snapshot'
  String _protocol = 'mjpeg';
  bool _isPtz = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _ipCtrl.dispose(); _portCtrl.dispose();
    _userCtrl.dispose(); _passCtrl.dispose(); _pathCtrl.dispose();
    super.dispose();
  }

  void _onProtocolChanged(String proto) {
    setState(() {
      _protocol = proto;
      switch (proto) {
        case 'rtsp':
          _portCtrl.text = '554';
          _pathCtrl.text = '/';
          break;
        case 'snapshot':
          _portCtrl.text = '80';
          _pathCtrl.text = '/snapshot.jpg';
          break;
        default: // mjpeg
          _portCtrl.text = '80';
          _pathCtrl.text = '/mjpeg';
      }
    });
  }

  Future<void> _test() async {
    setState(() { _testing = true; _testResult = null; });
    final ip   = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 80;
    final path = _pathCtrl.text.trim();

    final cam = await OnvifService.probeCameraAt(
      ip, username: _userCtrl.text.trim().isEmpty ? null : _userCtrl.text.trim(),
      password: _passCtrl.text.trim().isEmpty ? null : _passCtrl.text.trim());

    if (mounted) setState(() {
      _testing = false;
      _testResult = cam != null
          ? '✓ נמצאה מצלמה! ${cam.manufacturer ?? ""} — פורטים פתוחים: ${cam.openPorts}'
          : '✗ לא ניתן להתחבר ל-$ip:$port';
    });
  }

  void _add() {
    final ip   = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 80;
    final path = _pathCtrl.text.trim();
    final user = _userCtrl.text.trim().isEmpty ? null : _userCtrl.text.trim();
    final pass = _passCtrl.text.trim().isEmpty ? null : _passCtrl.text.trim();

    String? mjpegUrl, snapshotUrl, rtspUrl;
    CameraStreamType streamType;

    switch (_protocol) {
      case 'rtsp':
        final cred = (user != null && pass != null) ? '$user:$pass@' : '';
        rtspUrl    = 'rtsp://$cred$ip:$port$path';
        streamType = CameraStreamType.rtsp;
        break;
      case 'snapshot':
        snapshotUrl = user != null
            ? 'http://$user:$pass@$ip:$port$path'
            : 'http://$ip:$port$path';
        streamType = CameraStreamType.snapshot;
        break;
      default: // mjpeg
        mjpegUrl   = user != null
            ? 'http://$user:$pass@$ip:$port$path'
            : 'http://$ip:$port$path';
        streamType = CameraStreamType.mjpeg;
    }

    final camera = Camera(
      id: 'cam_${ip.replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim().isEmpty ? 'IP Camera' : _nameCtrl.text.trim(),
      room: _room,
      isOnline: true,
      ip: ip,
      port: port,
      username: user,
      password: pass,
      mjpegUrl: mjpegUrl,
      snapshotUrl: snapshotUrl,
      rtspUrl: rtspUrl,
      streamType: streamType,
      isPtz: _isPtz,
    );
    widget.onAdd(camera);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.tText2(0.24),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(children: [
              Icon(Icons.videocam_outlined, color: Color(0xFF00B4D8), size: 20),
              SizedBox(width: 8),
              Text('הוסף מצלמה ידנית',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),

            // Name + room
            Row(children: [
              Expanded(child: _TF(ctrl: _nameCtrl, label: 'שם', icon: Icons.label_outline)),
              const SizedBox(width: 10),
              Expanded(child: _RoomDropdown(value: _room,
                  onChanged: (v) => setState(() => _room = v!))),
            ]),
            const SizedBox(height: 10),

            // IP + port
            Row(children: [
              Expanded(flex: 3, child: _TF(ctrl: _ipCtrl, label: 'IP',
                  hint: '192.168.1.100', icon: Icons.router_outlined,
                  keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(flex: 1, child: _TF(ctrl: _portCtrl, label: 'פורט',
                  icon: Icons.numbers, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),

            // User + pass
            Row(children: [
              Expanded(child: _TF(ctrl: _userCtrl, label: 'משתמש', icon: Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(child: _TF(ctrl: _passCtrl, label: 'סיסמה',
                  icon: Icons.lock_outline, obscure: true)),
            ]),
            const SizedBox(height: 10),

            // Protocol selector
            const SizedBox(height: 4),
            Row(children: [
              _ProtoChip(label: 'MJPEG',    value: 'mjpeg',    selected: _protocol == 'mjpeg',    onTap: _onProtocolChanged),
              const SizedBox(width: 8),
              _ProtoChip(label: 'RTSP',     value: 'rtsp',     selected: _protocol == 'rtsp',     onTap: _onProtocolChanged),
              const SizedBox(width: 8),
              _ProtoChip(label: 'Snapshot', value: 'snapshot', selected: _protocol == 'snapshot', onTap: _onProtocolChanged),
            ]),
            const SizedBox(height: 10),

            // Path / RTSP path
            _TF(
              ctrl: _pathCtrl,
              label: _protocol == 'rtsp' ? 'נתיב RTSP' : 'נתיב stream',
              hint: _protocol == 'rtsp'
                  ? '/  או  /cam/realmonitor?channel=1'
                  : _protocol == 'snapshot'
                      ? '/snapshot.jpg'
                      : '/mjpeg',
              icon: Icons.link,
            ),
            const SizedBox(height: 4),
            Text(
              _protocol == 'rtsp'
                  ? 'Hikvision: /Streaming/Channels/101  |  Dahua: /cam/realmonitor?channel=1&subtype=0'
                  : 'MJPEG: /mjpeg  |  Snapshot: /snapshot.jpg  |  Hikvision: /Streaming/Channels/1',
              style: TextStyle(
                  color: context.tText2(0.25), fontSize: 10),
            ),
            const SizedBox(height: 12),

            // PTZ toggle
            GestureDetector(
              onTap: () => setState(() => _isPtz = !_isPtz),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isPtz
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : context.tText2(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPtz
                        ? AppColors.primary.withValues(alpha: 0.40)
                        : context.tText2(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.control_camera_outlined,
                        color: _isPtz ? AppColors.primary : context.tText2(0.38),
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('מצלמת PTZ',
                              style: TextStyle(
                                  color: _isPtz ? context.tText : context.tText2(0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text('הפעל שליטת Pan / Tilt / Zoom',
                              style: TextStyle(
                                  color: context.tText2(0.35),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(
                      _isPtz
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      color: _isPtz ? AppColors.primary : context.tText2(0.24),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (_testResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('✓')
                      ? AppColors.secured.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_testResult!,
                    style: TextStyle(
                        color: _testResult!.startsWith('✓')
                            ? AppColors.secured
                            : Colors.redAccent,
                        fontSize: 12)),
              ),

            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.network_check, size: 16),
                  label: Text('בדוק חיבור'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B4D8),
                      side: const BorderSide(color: Color(0xFF00B4D8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _ipCtrl.text.isEmpty ? null : _add,
                  icon: Icon(Icons.add, size: 16),
                  label: Text('הוסף מצלמה'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: context.tText,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;

  const _TF({
    required this.ctrl, required this.label, required this.icon,
    this.hint, this.keyboardType = TextInputType.text, this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: context.tText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: context.tText2(0.45), fontSize: 12),
        hintStyle: TextStyle(color: context.tText2(0.22), fontSize: 11),
        prefixIcon: Icon(icon, color: context.tText2(0.38), size: 16),
        filled: true,
        fillColor: context.tText2(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.tText2(0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.tText2(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

// ── Protocol chip ─────────────────────────────────────────────────────────────
class _ProtoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final void Function(String) onTap;
  const _ProtoChip({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : context.tText2(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.5)
                : context.tText2(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : context.tText2(0.54),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RoomDropdown extends StatelessWidget {
  final String value;
  final void Function(String?) onChanged;
  const _RoomDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.tText2(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: context.tCard,
          style: TextStyle(color: context.tText, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'outdoor', child: Text('חוץ')),
            DropdownMenuItem(value: 'indoor',  child: Text('פנים')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
