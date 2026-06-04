import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/brand_logo.dart';
import '../devices/devices_screen.dart';
import '../energy/energy_screen.dart';
import '../cameras/cameras_screen.dart';
import '../notifications/notifications_screen.dart';
import '../automations/automations_screen.dart';
import '../smarthome/add_device_screen.dart';
import '../ai/fanta_ai_screen.dart';
import '../rooms/rooms_screen.dart';
import '../solar/solar_screen.dart';
import '../breakers/breakers_screen.dart';
import '../boiler/boiler_screen.dart';
import '../media/media_screen.dart';
import '../../models/custom_scene.dart';
import '../../utils/haptics.dart';

// ══════════════════════════════════════════════════════════════
//  Original futuristic vector icons — no third-party assets,
//  100% custom geometry drawn with Flutter's Canvas API.
//  All paths, shapes, and glyphs are original work.
// ══════════════════════════════════════════════════════════════
enum _Ft {
  shield, cam, bulb, snow, plug, thermo, blind, sensor,
  bolt, moon, sun, hub, switches, rooms, film
}

class _FtIcon extends StatelessWidget {
  final _Ft type;
  final Color color;
  final double size;
  const _FtIcon({required this.type, required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _FtP(type: type, color: color));
}

class _FtP extends CustomPainter {
  final _Ft type;
  final Color color;
  const _FtP({required this.type, required this.color});

  Paint get _s => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.55
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _f => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  Paint _t(double w) => Paint()
    ..color = color.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size z) {
    final cx = z.width / 2;
    final cy = z.height / 2;

    switch (type) {
      // ── Pentagon shield with inner check-mark ──────────────
      case _Ft.shield:
        final r = z.width * 0.44;
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - r)
            ..lineTo(cx + r * .88, cy - r * .38)
            ..lineTo(cx + r * .88, cy + r * .20)
            ..lineTo(cx, cy + r)
            ..lineTo(cx - r * .88, cy + r * .20)
            ..lineTo(cx - r * .88, cy - r * .38)
            ..close(),
          _s,
        );
        canvas.drawLine(Offset(cx - r * .30, cy + r * .04),
            Offset(cx - r * .05, cy + r * .28), _t(1.55));
        canvas.drawLine(Offset(cx - r * .05, cy + r * .28),
            Offset(cx + r * .38, cy - r * .22), _t(1.55));

      // ── Camera body + lens + viewfinder bump ───────────────
      case _Ft.cam:
        final bw = z.width * 0.80;
        final bh = z.height * 0.52;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy + 2), width: bw, height: bh),
            const Radius.circular(4)),
          _s,
        );
        canvas.drawCircle(Offset(cx, cy + 2), bh * .33, _s);
        canvas.drawCircle(
          Offset(cx, cy + 2), bh * .16,
          _f..color = color.withValues(alpha: 0.38),
        );
        canvas.drawCircle(Offset(cx, cy + 2), bh * .16, _t(.9));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy - bh * .64), width: bw * .37, height: bh * .28),
            const Radius.circular(3)),
          _s,
        );
        canvas.drawCircle(
          Offset(cx + bw * .38, cy - bh * .28 + 2), 2.2,
          _f..color = color,
        );

      // ── Incandescent bulb + filament W ─────────────────────
      case _Ft.bulb:
        final r = z.width * 0.30;
        final top = cy - r * .10;
        canvas.drawCircle(Offset(cx, top), r, _s);
        canvas.drawLine(
          Offset(cx - r * .58, top + r * .88), Offset(cx + r * .58, top + r * .88), _s);
        canvas.drawLine(
          Offset(cx - r * .48, top + r * 1.08), Offset(cx + r * .48, top + r * 1.08),
          _t(1.2));
        canvas.drawLine(
          Offset(cx - r * .58, top + r * .88), Offset(cx - r * .58, top + r * .28),
          _t(1.2));
        canvas.drawLine(
          Offset(cx + r * .58, top + r * .88), Offset(cx + r * .58, top + r * .28),
          _t(1.2));
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * .30, top + r * .12)
            ..lineTo(cx - r * .14, top - r * .22)
            ..lineTo(cx, top + r * .12)
            ..lineTo(cx + r * .14, top - r * .22)
            ..lineTo(cx + r * .30, top + r * .12),
          _t(1.05),
        );

      // ── 6-arm snowflake with branches ──────────────────────
      case _Ft.snow:
        final r = z.width * 0.42;
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3 - math.pi / 6;
          canvas.drawLine(Offset(cx, cy),
              Offset(cx + r * math.cos(a), cy + r * math.sin(a)),
              _s..strokeWidth = 1.5);
          final bx = cx + r * .55 * math.cos(a);
          final by = cy + r * .55 * math.sin(a);
          for (final sg in [-1.0, 1.0]) {
            final a2 = a + sg * math.pi / 3;
            canvas.drawLine(Offset(bx, by),
                Offset(bx + r * .22 * math.cos(a2), by + r * .22 * math.sin(a2)),
                _t(1.1));
          }
        }
        canvas.drawCircle(Offset(cx, cy), 2.6, _f..color = color);

      // ── Smart plug with dual pin slots ─────────────────────
      case _Ft.plug:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: z.width * .65, height: z.height * .65),
            const Radius.circular(7)),
          _s,
        );
        for (final dx in [-0.15, 0.15]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + z.width * dx, cy - z.height * .06),
                  width: z.width * .09,
                  height: z.height * .23),
              const Radius.circular(2)),
            _f..color = color.withValues(alpha: 0.75),
          );
        }
        canvas.drawCircle(
          Offset(cx, cy + z.height * .14), 2.0, _f..color = color);

      // ── Thermometer with fill level ────────────────────────
      case _Ft.thermo:
        final r = z.width * .09;
        final top = z.height * .10;
        final bot = z.height * .68;
        final br = z.width * .20;
        canvas.drawPath(
          Path()
            ..moveTo(cx - r, top + r)
            ..lineTo(cx - r, bot)
            ..arcToPoint(Offset(cx + r, bot), radius: Radius.circular(r))
            ..lineTo(cx + r, top + r)
            ..arcToPoint(Offset(cx - r, top + r), radius: Radius.circular(r)),
          _s,
        );
        canvas.drawCircle(Offset(cx, bot + br * .65), br, _s);
        canvas.drawCircle(
          Offset(cx, bot + br * .65), br * .55,
          _f..color = color.withValues(alpha: 0.50),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(cx - r * .70, top + (bot - top) * .35, cx + r * .70, bot),
            Radius.circular(r * .70)),
          _f..color = color.withValues(alpha: 0.55),
        );
        for (int i = 1; i <= 3; i++) {
          final y = top + (bot - top) * i / 4;
          canvas.drawLine(Offset(cx + r, y), Offset(cx + r + 4.5, y), _t(1.0));
        }

      // ── Horizontal slats (blind/shutter) ───────────────────
      case _Ft.blind:
        final m = z.width * .10;
        for (int i = 0; i < 5; i++) {
          final y = z.height * .15 + i * z.height * .165;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(m, y - 2.5, z.width - m, y + 2.5),
              const Radius.circular(2)),
            _s..strokeWidth = i == 0 ? 1.8 : 1.3,
          );
        }
        canvas.drawLine(Offset(z.width - m - 5, z.height * .10),
            Offset(z.width - m - 5, z.height * .90), _t(.9));

      // ── Radar / motion sensor ──────────────────────────────
      case _Ft.sensor:
        final r = z.width * 0.40;
        for (int i = 0; i < 3; i++) {
          final ri = r * (.35 + i * .32);
          canvas.drawArc(
            Rect.fromCenter(center: Offset(cx, cy), width: ri * 2, height: ri * 2),
            -math.pi * .72, math.pi * 1.44, false,
            i == 0 ? _s : _t(1.0),
          );
        }
        canvas.drawCircle(Offset(cx, cy), r * .14, _f..color = color);
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + r * .92 * math.cos(-math.pi * .28),
              cy + r * .92 * math.sin(-math.pi * .28)),
          _t(.9),
        );

      // ── Lightning bolt (energy) ────────────────────────────
      case _Ft.bolt:
        canvas.drawPath(
          Path()
            ..moveTo(cx + z.width * .10, cy - z.height * .42)
            ..lineTo(cx - z.width * .18, cy + z.height * .04)
            ..lineTo(cx + z.width * .04, cy + z.height * .04)
            ..lineTo(cx - z.width * .10, cy + z.height * .42)
            ..lineTo(cx + z.width * .20, cy - z.height * .02)
            ..lineTo(cx + z.width * .02, cy - z.height * .02)
            ..close(),
          _s..style = PaintingStyle.stroke,
        );

      // ── Crescent moon + stars ──────────────────────────────
      case _Ft.moon:
        final r = z.width * 0.38;
        final path = Path()
          ..addArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
              math.pi * .30, math.pi * 1.40)
          ..arcToPoint(Offset(cx + r * .10, cy - r * .85),
              radius: Radius.circular(r * .68), clockwise: false);
        canvas.drawPath(path, _s..style = PaintingStyle.stroke);
        canvas.drawCircle(
          Offset(cx + r * .62, cy - r * .52), 1.7, _f..color = color);
        canvas.drawCircle(
          Offset(cx + r * .82, cy + r * .02), 1.1,
          _f..color = color.withValues(alpha: .65));

      // ── Sun with 8 rays ────────────────────────────────────
      case _Ft.sun:
        final r = z.width * 0.22;
        canvas.drawCircle(Offset(cx, cy), r, _s);
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset(cx + (r + 3.5) * math.cos(a), cy + (r + 3.5) * math.sin(a)),
            Offset(cx + (r + 8.5) * math.cos(a), cy + (r + 8.5) * math.sin(a)),
            _s..strokeWidth = 1.5,
          );
        }

      // ── Mesh hub / gateway ─────────────────────────────────
      case _Ft.hub:
        final r = z.width * .35;
        canvas.drawCircle(Offset(cx, cy), r * .32, _s);
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final sx = cx + r * .70 * math.cos(a);
          final sy = cy + r * .70 * math.sin(a);
          canvas.drawCircle(Offset(sx, sy), r * .16, _s);
          canvas.drawLine(Offset(cx, cy), Offset(sx, sy), _t(1.0));
        }

      // ── Rounded toggle track (smart switch) ───────────────
      case _Ft.switches:
        final rr = z.height * 0.26;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: z.width * .74, height: rr * 2),
            Radius.circular(rr)),
          _s,
        );
        canvas.drawCircle(
          Offset(cx + z.width * .20, cy), rr * .68,
          _f..color = color.withValues(alpha: .75),
        );

      // ── Floor-plan 2×2 grid (room management) ─────────────
      case _Ft.rooms:
        final rm = z.width * 0.10;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(rm, rm, z.width - rm, z.height - rm),
            const Radius.circular(3)),
          _s,
        );
        canvas.drawLine(Offset(cx, rm), Offset(cx, z.height - rm), _t(1.1));
        canvas.drawLine(Offset(rm, cy), Offset(z.width - rm, cy), _t(1.1));
        // Door arc in bottom-left room
        canvas.drawArc(
          Rect.fromCircle(
              center: Offset(cx - z.width * .04, cy + z.height * .26),
              radius: z.width * .15),
          -math.pi / 2, -math.pi / 2, false,
          _t(.9),
        );

      // ── TV screen with stand ──────────────────────────────────
      case _Ft.film:
        final tw = z.width * 0.82;
        final th = z.height * 0.52;
        final ty = cy - th * 0.30;
        // Screen frame
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, ty), width: tw, height: th),
            const Radius.circular(3)),
          _s,
        );
        // Inner screen
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, ty), width: tw * .82, height: th * .72),
            const Radius.circular(2)),
          _f..color = color.withValues(alpha: 0.25),
        );
        // Stand neck
        canvas.drawLine(
          Offset(cx, ty + th * .50),
          Offset(cx, ty + th * .72),
          _t(1.4),
        );
        // Stand base
        canvas.drawLine(
          Offset(cx - tw * .22, ty + th * .72),
          Offset(cx + tw * .22, ty + th * .72),
          _s,
        );
        // Play triangle
        final ps = th * .18;
        final path = Path()
          ..moveTo(cx - ps * .55, ty - ps * .65)
          ..lineTo(cx - ps * .55, ty + ps * .65)
          ..lineTo(cx + ps * .70, ty)
          ..close();
        canvas.drawPath(path, _f..color = color.withValues(alpha: 0.80));
    }
  }

  @override
  bool shouldRepaint(_FtP old) => old.type != type || old.color != color;
}

// ══════════════════════════════════════════════════════════════
//  Camera background painter — original surveillance-style grid
// ══════════════════════════════════════════════════════════════
class _CamBgPainter extends CustomPainter {
  final Color tint;
  const _CamBgPainter({required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    final gridP = Paint()
      ..color = tint.withValues(alpha: 0.045)
      ..strokeWidth = 0.5;
    const step = 18.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP);
    }
    // Corner recording markers
    final cp = Paint()
      ..color = tint.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    const o = 5.0;
    const l = 9.0;
    for (final corner in [
      [o, o, 1.0, 1.0],
      [size.width - o, o, -1.0, 1.0],
      [o, size.height - o, 1.0, -1.0],
      [size.width - o, size.height - o, -1.0, -1.0],
    ]) {
      final x = corner[0];
      final y = corner[1];
      final dx = corner[2];
      final dy = corner[3];
      canvas.drawLine(Offset(x, y), Offset(x + dx * l, y), cp);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * l), cp);
    }
  }

  @override
  bool shouldRepaint(_CamBgPainter old) => old.tint != tint;
}

// ══════════════════════════════════════════════════════════════
//  Dashboard Screen
// ══════════════════════════════════════════════════════════════
// ── Temperature bottom-sheet helper ──────────────────────────────────────────
void _showTempSheet(BuildContext context, AppState state, S s) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TempControlSheet(state: state, s: s),
  );
}

// ── Scene activation helper (shows SnackBar feedback) ────────────────────────
void _activateScene(
    BuildContext context, S s, String label, VoidCallback action) {
  Haptics.medium();
  action();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '✓  $label',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      backgroundColor: const Color(0xFF1E1E2E),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    if (state.gridLayout) {
      return const _GridHome();
    }

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──────────────────────────────────────
            SliverToBoxAdapter(child: _TopBar()),

            // ── Water-leak alert banner (urgent) ─────────────
            if (state.leakAlertActive)
              SliverToBoxAdapter(child: _LeakBanner(name: state.leakAlertName)),

            // ── Welcome + security status ────────────────────
            SliverToBoxAdapter(
              child: _WelcomeCard(
                isSecured: state.isSecured,
                firstName: state.userFirstName,
                strings: s,
                onToggle: state.toggleSecurity,
                camerasLive: state.cameras.where((c) => c.isOnline).length,
              ),
            ),

            // ── Status cards ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(children: [
                  // Row 1 — AC carousel | Home Management
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(child: _AcCarouselCard()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            iconType: _Ft.rooms,
                            iconColor: const Color(0xFF9C7AFF),
                            title: s.roomManagement,
                            badgeText: null,
                            badgeColor: const Color(0xFF9C7AFF),
                            valueLine:
                                '${state.rooms.length} ${s.roomsUnit}',
                            valueColor: const Color(0xFF9C7AFF),
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const RoomsScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Row 2 — Lighting (disabled) | Temperature
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatCard(
                            iconType: _Ft.bulb,
                            iconColor: AppColors.lightColor,
                            title: s.lightingTitle,
                            badgeText: null,
                            badgeColor: AppColors.lightColor,
                            valueLine:
                                '${state.devices.where((d) => d.type == DeviceType.light && d.isOn).length}'
                                ' ${s.lightsOn}',
                            valueColor: AppColors.lightColor,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    DevicesScreen(initialCategory: DeviceType.light))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            iconType: _Ft.thermo,
                            iconColor: AppColors.acColor,
                            title: s.tempTitle,
                            badgeText: null,
                            badgeColor: AppColors.acColor,
                            bigText: '${state.targetTemp.toStringAsFixed(0)}°C',
                            valueLine: s.tempComfy,
                            valueColor: AppColors.acColor,
                            onTap: () => _showTempSheet(context, state, s),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Quick links (Energy + Automations) ───────────
            SliverToBoxAdapter(child: _QuickLinksRow()),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Scene controls (3 equal buttons) ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SceneActionsRow(state: state, s: s),
              ),
            ),

            // NOTE: "Smart Energy" (Solar + Breakers) and the store ad banner
            // were moved off the home screen to reduce clutter. Energy remains
            // reachable via the Quick Links row above.
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Water-leak alert banner — urgent, dismissable
// ──────────────────────────────────────────────────────────────
class _LeakBanner extends StatelessWidget {
  final String name;
  const _LeakBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.unsecured.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.unsecured, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_damage, color: AppColors.unsecured, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('זוהתה נזילת מים!',
                    style: TextStyle(
                        color: AppColors.unsecured,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                Text(name,
                    style: TextStyle(
                        color: context.tText2(0.7), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.tText2(0.6), size: 20),
            onPressed: state.dismissLeakAlert,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Grid home layout — clean uniform 2-column card grid (light-first)
//  Selectable alternative to the classic layout (Settings → Display).
// ──────────────────────────────────────────────────────────────
class _GridHome extends StatelessWidget {
  const _GridHome();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    final lightsOn = state.devices
        .where((d) => d.type == DeviceType.light && d.isOn).length;
    final blindsOn = state.devices
        .where((d) => d.type == DeviceType.blind && d.isOn).length;
    final acCount = state.devices
        .where((d) => d.type == DeviceType.airConditioner).length;
    final autos = state.automations.where((a) => a.isEnabled).length;
    final camsLive = state.cameras.where((c) => c.isOnline).length;

    final tiles = <Widget>[
      _GridTile(
        ft: _Ft.rooms, color: const Color(0xFF9C7AFF),
        title: s.roomManagement, subtitle: '${state.rooms.length} ${s.roomsUnit}',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RoomsScreen())),
      ),
      _GridTile(
        ft: _Ft.snow, color: AppColors.acColor,
        title: s.acCategory,
        subtitle: acCount == 0 ? s.acNoUnits : '$acCount ${s.acConnected}',
        onTap: () => showModalBottomSheet(
            context: context, backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _AcListSheet(state: state, s: s)),
      ),
      _GridTile(
        ft: _Ft.thermo, color: AppColors.acColor,
        title: s.tempTitle, bigText: '${state.targetTemp.toStringAsFixed(0)}°C',
        subtitle: s.tempComfy,
        onTap: () => _showTempSheet(context, state, s),
      ),
      _GridTile(
        ft: _Ft.bulb, color: AppColors.lightColor,
        title: s.lightingTitle, subtitle: '$lightsOn ${s.lightsOn}',
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DevicesScreen(initialCategory: DeviceType.light))),
      ),
      _GridTile(
        ft: _Ft.hub, color: const Color(0xFF9C7AFF),
        title: s.automationsTitle, subtitle: '$autos ${s.activeAutomations}',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AutomationsScreen())),
      ),
      _GridTile(
        ft: _Ft.bolt, color: AppColors.lightColor,
        title: s.energyTitle, subtitle: '245 kWh  −12%',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EnergyScreen())),
      ),
      _GridTile(
        ft: _Ft.switches, color: const Color(0xFF7BB8FF),
        title: s.breakersTitle, subtitle: '8/9 ${s.breakerOn}',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BreakersScreen())),
      ),
      _GridTile(
        ft: _Ft.sun, color: const Color(0xFFFFB300),
        title: s.solarTitle, subtitle: '4.7 kW  ↑',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SolarScreen())),
      ),
      _GridTile(
        ft: _Ft.blind, color: AppColors.primary,
        title: s.blindsCategory, subtitle: '$blindsOn ${s.devicesOn}',
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DevicesScreen(initialCategory: DeviceType.blind))),
      ),
      _GridTile(
        ft: _Ft.thermo, color: AppColors.acColor,
        title: s.boilerTitle, subtitle: '60°C',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BoilerScreen())),
      ),
      _GridTile(
        ft: _Ft.bolt, color: AppColors.primary,
        title: s.turnOffAll,
        onTap: () => _activateScene(
            context, s, s.turnOffAll, state.activateTurnOffAll),
      ),
      _GridTile(
        ft: _Ft.sun, color: AppColors.lightColor,
        title: s.leaveHome,
        onTap: () => _activateScene(
            context, s, s.leaveHome, state.activateLeaveHome),
      ),
      _GridTile(
        ft: _Ft.cam, color: AppColors.cameraColor,
        title: s.camerasTitle, subtitle: '$camsLive ${s.activeAutomations}',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CamerasScreen())),
      ),
      _GridTile(
        ft: _Ft.moon, color: const Color(0xFF9C7AFF),
        title: s.goodNight,
        onTap: () => _activateScene(
            context, s, s.goodNight, state.activateGoodNight),
      ),
    ];

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),
            if (state.leakAlertActive)
              SliverToBoxAdapter(child: _LeakBanner(name: state.leakAlertName)),
            SliverToBoxAdapter(
              child: _WelcomeCard(
                isSecured: state.isSecured,
                firstName: state.userFirstName,
                strings: s,
                onToggle: state.toggleSecurity,
                camerasLive: camsLive,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                delegate: SliverChildListDelegate(tiles),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Single soft-shadow card used by the grid layout.
class _GridTile extends StatelessWidget {
  final _Ft ft;
  final Color color;
  final String title;
  final String? subtitle;
  final String? bigText;
  final VoidCallback onTap;
  const _GridTile({
    required this.ft,
    required this.color,
    required this.title,
    this.subtitle,
    this.bigText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final light = context.isLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: light
                  ? const Color(0xFF1A1D27).withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: light
              ? null
              : Border.all(color: color.withValues(alpha: 0.16), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (bigText != null) ...[
                    const SizedBox(height: 2),
                    Text(bigText!,
                        style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: TextStyle(
                            color: color, fontSize: 11,
                            fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: light ? 0.12 : 0.16),
              ),
              child: Center(child: _FtIcon(type: ft, color: color, size: 22)),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Top bar
// ──────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _NavBtn(icon: Icons.menu, onTap: () {}),
          // App name
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: BrandLogo(size: BrandLogoSize.medium),
          ),
          // Google Assistant button
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FantaAIScreen())),
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.30),
                    blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 16),
            ),
          ),
          const Spacer(),
          _NavBtn(
            icon: Icons.videocam_outlined,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CamerasScreen())),
          ),
          const SizedBox(width: 6),
          _NavBtn(
            icon: Icons.notifications_outlined,
            badge: true,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.tText2(0.06),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: context.tText2(0.08), width: 1),
          ),
          child: Icon(icon, color: context.tText2(0.7), size: 19),
        ),
        if (badge)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.unsecured,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Welcome card
// ──────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final bool isSecured;
  final String firstName;
  final S strings;
  final VoidCallback onToggle;
  final int camerasLive;
  const _WelcomeCard({
    required this.isSecured,
    required this.firstName,
    required this.strings,
    required this.onToggle,
    required this.camerasLive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSecured ? AppColors.secured : AppColors.unsecured;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          children: [
            // Shield icon — same 44×44 circle as _AddDeviceCard
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                border: Border.all(
                    color: color.withValues(alpha: 0.45), width: 1.5),
              ),
              child: Center(
                child: _FtIcon(type: _Ft.shield, color: color, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            // Greeting + status — fontSize 14 matching _AddDeviceCard
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${strings.greetingPrefix} $firstName',
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isSecured
                        ? strings.homeSecured
                        : strings.homeNotSecured,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Security-camera status icon — green/live when cameras are
            // online, grey when none are active.
            _CameraStatusBadge(live: camerasLive > 0),
            const SizedBox(width: 8),
            // Status chip on the right
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSecured ? Icons.chevron_right : Icons.chevron_right,
                color: color,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Security-camera status badge
//  Green camera + pulsing dot when at least one camera is online,
//  grey (muted) when none are active.
// ──────────────────────────────────────────────────────────────
class _CameraStatusBadge extends StatefulWidget {
  final bool live;
  const _CameraStatusBadge({required this.live});

  @override
  State<_CameraStatusBadge> createState() => _CameraStatusBadgeState();
}

class _CameraStatusBadgeState extends State<_CameraStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.live ? AppColors.secured : const Color(0xFF6B7280);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.40), width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Realistic CCTV / security-camera glyph
          Icon(Icons.camera_outdoor_rounded, color: color, size: 18),
          // Live indicator dot (only when cameras are online)
          if (widget.live)
            Positioned(
              top: -2,
              right: -2,
              child: FadeTransition(
                opacity: _pulse,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.secured,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.tBg, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secured.withValues(alpha: 0.7),
                        blurRadius: 5,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Section header
// ──────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 14, 10),
      child: Row(children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22)),
              ),
              child: const Text(
                '→',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  AC Carousel Card — cycles through connected AC units
// ──────────────────────────────────────────────────────────────
class _AcCarouselCard extends StatefulWidget {
  const _AcCarouselCard();

  @override
  State<_AcCarouselCard> createState() => _AcCarouselCardState();
}

class _AcCarouselCardState extends State<_AcCarouselCard> {
  int _idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final acs = context.read<AppState>().devices
          .where((d) => d.type == DeviceType.airConditioner)
          .toList();
      if (acs.length > 1) {
        setState(() => _idx = (_idx + 1) % acs.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final acs = state.devices
        .where((d) => d.type == DeviceType.airConditioner)
        .toList();

    final idx   = acs.isEmpty ? 0 : _idx % acs.length;
    final ac    = acs.isEmpty ? null : acs[idx];
    final setpt = ac == null
        ? null
        : (ac.attributes['setpoint'] as double? ?? state.targetTemp);

    final titleText = ac?.name ?? s.acCategory;
    final bigText   = setpt != null ? '${setpt.toStringAsFixed(0)}°C' : null;
    final valueLine = acs.isEmpty
        ? s.acNoUnits
        : acs.length == 1
            ? s.acConnected
            : '${idx + 1}/${acs.length}  ${s.acConnected}';

    return _StatCard(
      iconType: _Ft.snow,
      iconColor: AppColors.acColor,
      title: titleText,
      badgeText: null,
      badgeColor: AppColors.acColor,
      bigText: bigText,
      valueLine: valueLine,
      valueColor: AppColors.acColor,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _AcListSheet(state: state, s: s),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  AC List Sheet — shows all connected AC units
// ──────────────────────────────────────────────────────────────
class _AcListSheet extends StatelessWidget {
  final AppState state;
  final S s;
  const _AcListSheet({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    final acs = state.devices
        .where((d) => d.type == DeviceType.airConditioner)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.acColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.acColor.withValues(alpha: 0.30)),
              ),
              child: Center(
                  child: _FtIcon(
                      type: _Ft.snow, color: AppColors.acColor, size: 22)),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.acCategory,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              Text('${acs.length} ${s.acConnected}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 20),

          // Empty state
          if (acs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.ac_unit_outlined, color: Colors.white24, size: 40),
                const SizedBox(height: 10),
                Text(s.acNoUnits,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13)),
              ]),
            )
          else
            ...acs.map((ac) {
              final setpt =
                  ac.attributes['setpoint'] as double? ?? state.targetTemp;
              final roomLabel = ac.room.isEmpty
                  ? ''
                  : state.strings.translateRoomKey(ac.room);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.acColor
                          .withValues(alpha: ac.isOn ? 0.25 : 0.08)),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: (ac.isOn ? AppColors.acColor : Colors.white38)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                        child: _FtIcon(
                            type: _Ft.snow,
                            color: ac.isOn
                                ? AppColors.acColor
                                : Colors.white38,
                            size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ac.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          if (roomLabel.isNotEmpty)
                            Text(roomLabel,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 11)),
                        ]),
                  ),
                  Text('${setpt.toStringAsFixed(0)}°',
                      style: const TextStyle(
                          color: AppColors.acColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: ac.isOn ? AppColors.secured : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Unified status card — used for all 4 grid positions
// ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _Ft iconType;
  final Color iconColor;
  final String title;
  final String? badgeText;
  final Color badgeColor;
  final String? valueLine;
  final Color? valueColor;
  final String? bigText;
  final VoidCallback? onTap;
  final bool disabled;

  const _StatCard({
    required this.iconType,
    required this.iconColor,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    this.valueLine,
    this.valueColor,
    this.bigText,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.40 : 1.0,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: iconColor.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            // Icon circle — same size as Quick Links
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
                border: Border.all(
                    color: iconColor.withValues(alpha: 0.28), width: 1),
              ),
              child: Center(
                child: _FtIcon(type: iconType, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Big text (temperature)
                  if (bigText != null)
                    Text(
                      bigText!,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  // Badge pill
                  if (badgeText != null) _Badge(badgeText!, badgeColor),
                  // Sub-value line
                  if (valueLine != null && valueLine!.isNotEmpty)
                    Text(
                      valueLine!,
                      style: TextStyle(
                        color: valueColor ?? iconColor.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ), // Opacity
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Device scene strip
// ──────────────────────────────────────────────────────────────
class _DeviceSceneStrip extends StatelessWidget {
  final AppState state;
  final S s;
  const _DeviceSceneStrip({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _DeviceTypeCard(item: items[i]),
      ),
    );
  }

  List<_DevItem> _buildItems() {
    final devs = state.devices;
    int count(bool Function(Device) test) => devs.where(test).length;
    int on(bool Function(Device) test) =>
        devs.where((d) => test(d) && d.isOn).length;

    return [
      _DevItem(
        ft: _Ft.bulb,
        color: AppColors.lightColor,
        label: s.lightsCategory,
        total: count((d) => d.type == DeviceType.light),
        active: on((d) => d.type == DeviceType.light),
        filterType: DeviceType.light,
      ),
      _DevItem(
        ft: _Ft.snow,
        color: AppColors.acColor,
        label: s.acCategory,
        total: count((d) =>
            d.type == DeviceType.airConditioner ||
            d.type == DeviceType.waterHeater),
        active: on((d) =>
            d.type == DeviceType.airConditioner ||
            d.type == DeviceType.waterHeater),
        filterType: DeviceType.airConditioner,
      ),
      _DevItem(
        ft: _Ft.blind,
        color: AppColors.primary,
        label: s.blindsCategory,
        total: count((d) => d.type == DeviceType.blind),
        active: on((d) => d.type == DeviceType.blind),
        filterType: DeviceType.blind,
      ),
      _DevItem(
        ft: _Ft.plug,
        color: AppColors.plugColor,
        label: s.plugsCategory,
        total: count((d) => d.type == DeviceType.smartPlug),
        active: on((d) => d.type == DeviceType.smartPlug),
        filterType: DeviceType.smartPlug,
      ),
      _DevItem(
        ft: _Ft.sensor,
        color: AppColors.motionColor,
        label: s.sensorsCategory,
        total: count((d) =>
            d.type == DeviceType.motionSensor ||
            d.type == DeviceType.doorSensor ||
            d.type == DeviceType.windowSensor),
        active: on((d) =>
            d.type == DeviceType.motionSensor ||
            d.type == DeviceType.doorSensor ||
            d.type == DeviceType.windowSensor),
        filterType: DeviceType.motionSensor,
      ),
      _DevItem(
        ft: _Ft.switches,
        color: const Color(0xFF9C7AFF),
        label: s.switchesCategory,
        total: count((d) => d.type == DeviceType.smartSwitch),
        active: on((d) => d.type == DeviceType.smartSwitch),
        filterType: DeviceType.smartSwitch,
      ),
      _DevItem(
        ft: _Ft.hub,
        color: const Color(0xFF00B4D8),
        label: s.networkLabel,
        total: count((d) =>
            d.type == DeviceType.router || d.type == DeviceType.gateway),
        active: count((d) =>
            (d.type == DeviceType.router || d.type == DeviceType.gateway) &&
            d.status == DeviceStatus.online),
        filterType: DeviceType.router,
      ),
    ];
  }
}

class _DevItem {
  final _Ft ft;
  final Color color;
  final String label;
  final int total;
  final int active;
  final DeviceType? filterType; // null = network (router/gateway)
  const _DevItem({
    required this.ft,
    required this.color,
    required this.label,
    required this.total,
    required this.active,
    this.filterType,
  });
}

class _DeviceTypeCard extends StatelessWidget {
  final _DevItem item;
  const _DeviceTypeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isActive = item.active > 0;
    final c = item.color;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DevicesScreen(initialCategory: item.filterType),
        ),
      ),
      child: Container(
      width: 82,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? c.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.07),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon bubble
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.withValues(alpha: isActive ? 0.15 : 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: c.withValues(alpha: isActive ? 0.30 : 0.12),
                    width: 1),
              ),
              child: Center(
                child: _FtIcon(type: item.ft, color: isActive ? c : c.withValues(alpha: 0.45), size: 22),
              ),
            ),
            // Label
            Text(
              item.label,
              style: TextStyle(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.35),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Count chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? c.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.active}/${item.total}',
                style: TextStyle(
                  color: isActive ? c : Colors.white.withValues(alpha: 0.25),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ), // Container
    ); // GestureDetector
  }
}

// ──────────────────────────────────────────────────────────────
//  Camera strip
// ──────────────────────────────────────────────────────────────
// ──────────────────────────────────────────────────────────────
//  Camera grid — 2-column prominent display (center of screen)
// ──────────────────────────────────────────────────────────────
class _CameraGrid extends StatelessWidget {
  final AppState state;
  final S s;
  const _CameraGrid({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    final cameras = state.cameras;
    if (cameras.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Center(
            child: Text(
              'אין מצלמות מחוברות',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemCount: cameras.length,
        itemBuilder: (ctx, i) => _CameraGridCard(
          camera: cameras[i],
          s: s,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CamerasScreen()),
          ),
        ),
      ),
    );
  }
}

class _CameraGridCard extends StatelessWidget {
  final Camera camera;
  final S s;
  final VoidCallback onTap;
  const _CameraGridCard(
      {required this.camera, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLive = camera.isOnline;
    final tint = isLive ? AppColors.cameraColor : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLive
                  ? [const Color(0xFF0B1428), const Color(0xFF0F1E3C)]
                  : [const Color(0xFF111118), const Color(0xFF181820)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tint.withValues(alpha: isLive ? 0.30 : 0.10),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Grid background
              Positioned.fill(
                child: CustomPaint(painter: _CamBgPainter(tint: tint)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: icon + LIVE badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: tint.withValues(alpha: 0.28), width: 1),
                          ),
                          child: Center(
                            child: _FtIcon(type: _Ft.cam, color: tint, size: 17),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFFEA4335).withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLive
                                  ? const Color(0xFFEA4335)
                                      .withValues(alpha: 0.45)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive
                                      ? const Color(0xFFEA4335)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isLive ? s.liveLabel : s.offlineLabel,
                                style: TextStyle(
                                  color: isLive
                                      ? const Color(0xFFEA4335)
                                      : Colors.grey,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Camera name
                    Text(
                      camera.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Room + motion dot
                    Row(children: [
                      Text(
                        camera.room == 'outdoor'
                            ? s.cameraRoomOutdoor
                            : s.cameraRoomIndoor,
                        style: TextStyle(
                          color: tint.withValues(alpha: 0.70),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (camera.motionDetection) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ]),
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

// ──────────────────────────────────────────────────────────────
//  Camera strip (kept for potential future use)
// ──────────────────────────────────────────────────────────────
class _CameraStrip extends StatelessWidget {
  final AppState state;
  final S s;
  const _CameraStrip({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    final cameras = state.cameras;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cameras.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _CameraFeedCard(
          camera: cameras[i],
          s: s,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CamerasScreen()),
          ),
        ),
      ),
    );
  }
}

class _CameraFeedCard extends StatelessWidget {
  final Camera camera;
  final S s;
  final VoidCallback onTap;
  const _CameraFeedCard(
      {required this.camera, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLive = camera.isOnline;
    final tint = isLive ? AppColors.cameraColor : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 158,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLive
                  ? [const Color(0xFF0B1428), const Color(0xFF0F1E3C)]
                  : [const Color(0xFF111118), const Color(0xFF181820)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tint.withValues(alpha: isLive ? 0.25 : 0.10),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Surveillance grid background
              Positioned.fill(
                child: CustomPaint(
                  painter: _CamBgPainter(tint: tint),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: camera icon + LIVE / OFFLINE badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: tint.withValues(alpha: 0.25),
                                width: 1),
                          ),
                          child: Center(
                            child: _FtIcon(type: _Ft.cam, color: tint, size: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFFEA4335).withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLive
                                  ? const Color(0xFFEA4335).withValues(alpha: 0.45)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive
                                      ? const Color(0xFFEA4335)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLive ? s.liveLabel : s.offlineLabel,
                                style: TextStyle(
                                  color: isLive
                                      ? const Color(0xFFEA4335)
                                      : Colors.grey,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Camera name
                    Text(
                      camera.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Room + motion indicator
                    Row(children: [
                      Text(
                        camera.room == 'outdoor'
                            ? s.cameraRoomOutdoor
                            : s.cameraRoomIndoor,
                        style: TextStyle(
                          color: tint.withValues(alpha: 0.75),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (camera.motionDetection) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ]),
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

// ──────────────────────────────────────────────────────────────
//  Quick links row (Energy + Automations)
// ──────────────────────────────────────────────────────────────
class _QuickLinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: _QuickLink(
            ft: _Ft.bolt,
            color: AppColors.lightColor,
            title: s.energyTitle,
            subtitle: '245 kWh  −12%',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EnergyScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLink(
            ft: _Ft.hub,
            color: const Color(0xFF9C7AFF),
            title: s.automationsTitle,
            subtitle:
                '${state.automations.where((a) => a.isEnabled).length} ${s.activeAutomations}',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AutomationsScreen())),
          ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Smart Energy row (Solar + Circuit Breakers)
// ──────────────────────────────────────────────────────────────
class _SmartEnergyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: _QuickLink(
                ft: _Ft.sun,
                color: const Color(0xFFFFB300),
                title: s.solarTitle,
                subtitle: '4.7 kW  ↑',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SolarScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickLink(
                ft: _Ft.switches,
                color: const Color(0xFF7BB8FF),
                title: s.breakersTitle,
                subtitle: '8/9 ${s.breakerOn}',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BreakersScreen())),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _QuickLink(
                ft: _Ft.thermo,
                color: AppColors.acColor,
                title: s.boilerTitle,
                subtitle: '60°C',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BoilerScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickLink(
                ft: _Ft.blind,
                color: AppColors.primary,
                title: s.blindsCategory,
                subtitle: '${state.devices.where((d) => d.type == DeviceType.blind && d.isOn).length} ${s.devicesOn}',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                        DevicesScreen(initialCategory: DeviceType.blind))),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final _Ft ft;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _QuickLink({
    required this.ft,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Center(child: _FtIcon(type: ft, color: color, size: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.75), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Scene actions — 3 perfectly equal-sized buttons
// ──────────────────────────────────────────────────────────────
class _SceneActionsRow extends StatelessWidget {
  final AppState state;
  final S s;
  const _SceneActionsRow({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SceneBtn(
                  ft: _Ft.sun,
                  color: AppColors.lightColor,
                  label: s.leaveHome,
                  onTap: () => _activateScene(
                      context, s, s.leaveHome, state.activateLeaveHome),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SceneBtn(
                  ft: _Ft.bolt,
                  color: AppColors.primary,
                  label: s.turnOffAll,
                  onTap: () => _activateScene(
                      context, s, s.turnOffAll, state.activateTurnOffAll),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SceneBtn(
                  ft: _Ft.moon,
                  color: const Color(0xFF9C7AFF),
                  label: s.goodNight,
                  onTap: () => _activateScene(
                      context, s, s.goodNight, state.activateGoodNight),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SceneBtn(
                  ft: _Ft.film,
                  color: const Color(0xFFFF6B6B),
                  label: s.mediaTitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MediaScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Custom scenes + add ─────────────────────────────────
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...state.customScenes.map((sc) => _CustomSceneBtn(
                  scene: sc,
                  onTap: () {
                    Haptics.medium();
                    state.activateCustomScene(sc);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${sc.name} ✓'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  onLongPress: () => showSceneEditor(context, state, sc),
                )),
            _AddSceneBtn(onTap: () => showSceneEditor(context, state, null)),
          ],
        ),
      ],
    );
  }
}

/// Chip-style button for a user-created scene.
class _CustomSceneBtn extends StatelessWidget {
  final CustomScene scene;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _CustomSceneBtn({
    required this.scene,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(scene.colorValue);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconData(scene.iconCode, fontFamily: 'MaterialIcons'),
                color: color, size: 18),
            const SizedBox(width: 8),
            Text(scene.name,
                style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// "+" tile that opens the scene editor.
class _AddSceneBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSceneBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.tText2(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.tText2(0.18),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: context.tText2(0.7), size: 18),
            const SizedBox(width: 6),
            Text(
              context.read<AppState>().strings.sceneCreate,
              style: TextStyle(
                  color: context.tText2(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scene editor bottom sheet ─────────────────────────────────
void showSceneEditor(BuildContext context, AppState state, CustomScene? existing) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SceneEditor(state: state, existing: existing),
  );
}

class _SceneEditor extends StatefulWidget {
  final AppState state;
  final CustomScene? existing;
  const _SceneEditor({required this.state, this.existing});

  @override
  State<_SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<_SceneEditor> {
  late final TextEditingController _nameCtrl;
  late bool? _lights, _plugs, _ac, _blinds, _arm;
  int _iconCode = 0xe5ca; // check
  int _colorValue = 0xFF1A73E8;

  static const _icons = [0xe5ca, 0xe1ad, 0xef44, 0xe40a, 0xe3a9, 0xe1c4, 0xe57f, 0xe333];
  static const _colors = [
    0xFF1A73E8, 0xFFFF6B6B, 0xFF9C7AFF, 0xFFFFB300,
    0xFF34A853, 0xFF00B4D8, 0xFFFF2D8A,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _lights = e?.lights;
    _plugs = e?.plugs;
    _ac = e?.ac;
    _blinds = e?.blindsOpen;
    _arm = e?.arm;
    _iconCode = e?.iconCode ?? 0xe5ca;
    _colorValue = e?.colorValue ?? 0xFF1A73E8;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final s = widget.state.strings;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.sceneName), duration: const Duration(seconds: 1)),
      );
      return;
    }
    final scene = CustomScene(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      iconCode: _iconCode,
      colorValue: _colorValue,
      lights: _lights,
      plugs: _plugs,
      ac: _ac,
      blindsOpen: _blinds,
      arm: _arm,
    );
    if (widget.existing != null) {
      widget.state.updateScene(scene);
    } else {
      widget.state.addScene(scene);
    }
    Haptics.medium();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.strings;
    final pad = MediaQuery.of(context).viewInsets.bottom;
    final dir = widget.state.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + pad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  widget.existing == null ? s.sceneNew : s.edit,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.existing != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.unsecured),
                    onPressed: () {
                      widget.state.removeScene(widget.existing!.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Name
            TextField(
              controller: _nameCtrl,
              textDirection: dir,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: s.sceneName,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon picker
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _icons.map((c) {
                final sel = c == _iconCode;
                return GestureDetector(
                  onTap: () => setState(() => _iconCode = c),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: sel
                          ? Color(_colorValue).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: sel
                              ? Color(_colorValue)
                              : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Icon(IconData(c, fontFamily: 'MaterialIcons'),
                        color: sel ? Color(_colorValue) : Colors.white60,
                        size: 20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Color picker
            Wrap(
              spacing: 10,
              children: _colors.map((c) {
                final sel = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
                          width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            _SectionTitle(s.sceneActions),
            const SizedBox(height: 8),
            _ActionRow(label: s.lightsCategory, value: _lights,
                onChanged: (v) => setState(() => _lights = v), s: s),
            _ActionRow(label: s.actPlugs, value: _plugs,
                onChanged: (v) => setState(() => _plugs = v), s: s),
            _ActionRow(label: s.acCategory, value: _ac,
                onChanged: (v) => setState(() => _ac = v), s: s),
            _ActionRow(label: s.blindsCategory, value: _blinds,
                onChanged: (v) => setState(() => _blinds = v), s: s,
                onLabel: s.valOn, offLabel: s.valOff),
            _ActionRow(label: s.securityTitle, value: _arm,
                onChanged: (v) => setState(() => _arm = v), s: s),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_colorValue),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(s.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);
  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1),
      );
}

/// Tri-state action row: No change / On / Off.
class _ActionRow extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final S s;
  final String? onLabel;
  final String? offLabel;
  const _ActionRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.s,
    this.onLabel,
    this.offLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          _seg(s.valKeep, null),
          _seg(onLabel ?? s.valOn, true),
          _seg(offLabel ?? s.valOff, false),
        ],
      ),
    );
  }

  Widget _seg(String text, bool? v) {
    final sel = value == v;
    return GestureDetector(
      onTap: () { Haptics.select(); onChanged(v); },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: sel
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(text,
            style: TextStyle(
                color: sel ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SceneBtn extends StatelessWidget {
  final _Ft ft;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _SceneBtn({
    required this.ft,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withValues(alpha: 0.20), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FtIcon(type: ft, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.90),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


// ──────────────────────────────────────────────────────────────
//  Add device — compact pill button
// ──────────────────────────────────────────────────────────────
class _AddDeviceCompact extends StatelessWidget {
  final String label;
  const _AddDeviceCompact({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 15),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Add device card (full — kept for reference)
// ──────────────────────────────────────────────────────────────
class _AddDeviceCard extends StatelessWidget {
  final String label;
  const _AddDeviceCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.primary.withValues(alpha: 0.07),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.38)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.18),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1.5),
            ),
            child: const Icon(Icons.add, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left,
                color: AppColors.primary, size: 17),
          ),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Badge pill
// ──────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Temperature control bottom-sheet
// ──────────────────────────────────────────────────────────────
class _TempControlSheet extends StatefulWidget {
  final AppState state;
  final S s;
  const _TempControlSheet({required this.state, required this.s});

  @override
  State<_TempControlSheet> createState() => _TempControlSheetState();
}

class _TempControlSheetState extends State<_TempControlSheet> {
  late double _temp;

  @override
  void initState() {
    super.initState();
    _temp = widget.state.targetTemp;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final acCount = widget.state.devices
        .where((d) => d.type == DeviceType.airConditioner).length;

    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.acColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.acColor.withValues(alpha: 0.30)),
                ),
                child: Center(
                  child: _FtIcon(
                      type: _Ft.thermo, color: AppColors.acColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.tempTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  Text('$acCount ${s.acConnected}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Big temperature display
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF00C2FF), Color(0xFF7B2FFF)],
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(
              '${_temp.toStringAsFixed(0)}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w200,
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(s.tempComfy,
              style: TextStyle(
                  color: AppColors.acColor.withValues(alpha: 0.7),
                  fontSize: 13)),

          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.acColor,
              inactiveTrackColor: AppColors.acColor.withValues(alpha: 0.15),
              thumbColor: Colors.white,
              overlayColor: AppColors.acColor.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _temp,
              min: 16,
              max: 30,
              divisions: 14,
              onChanged: (v) => setState(() => _temp = v),
            ),
          ),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('16°',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12)),
                Text('30°',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                widget.state.setTargetTemp(_temp);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✓  ${s.tempTitle}: ${_temp.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    backgroundColor: const Color(0xFF1E1E2E),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A0D0), Color(0xFF7B2FFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'הגדר ${_temp.toStringAsFixed(0)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
