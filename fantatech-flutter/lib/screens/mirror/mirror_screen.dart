import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/weather/weather_service.dart';

const _kOrange  = Color(0xFFFF6B00);
const _kAmber   = Color(0xFFFFB800);
const _kGreen   = Color(0xFF34C759);
const _kRed     = Color(0xFFFF3B30);
const _kWhite70 = Color(0xB3FFFFFF);
const _kWhite40 = Color(0x66FFFFFF);

class MirrorScreen extends StatefulWidget {
  const MirrorScreen({super.key});

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  WeatherInfo? _weather;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final w = await WeatherService.fetch();
    if (mounted) setState(() => _weather = w);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final s      = state.strings;
    final armed  = state.isSecured;
    final devices = state.devices;
    final cameras = state.cameras;
    final devOn   = devices.where((d) => d.isOn).length;

    final hh = _pad(_now.hour);
    final mm = _pad(_now.minute);
    final ss = _pad(_now.second);

    final weekDays = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    final months   = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr  = '${weekDays[_now.weekday % 7]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';

    final tempStr  = _weather != null ? '${_weather!.temperatureC.round()}°C' : '—°C';
    final cityStr  = _weather?.city ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Faint grid overlay for mirror feel ──────────────
              CustomPaint(
                size: Size.infinite,
                painter: _GridPainter(),
              ),

              // ── Main content ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Clock ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$hh:$mm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 96,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ':$ss',
                          style: const TextStyle(
                            color: _kWhite40,
                            fontSize: 40,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: _kWhite70,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Weather row ───────────────────────────────
                    Row(
                      children: [
                        const Icon(Symbols.wb_sunny, color: _kAmber, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tempStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            if (cityStr.isNotEmpty)
                              Text(
                                cityStr,
                                style: const TextStyle(color: _kWhite70, fontSize: 13),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ── Status row ────────────────────────────────
                    Row(
                      children: [
                        _StatusChip(
                          icon: armed ? Symbols.lock : Symbols.lock_open,
                          label: armed ? s.secArmedShort : s.secDisarmedShort,
                          color: armed ? _kOrange : _kRed,
                        ),
                        const SizedBox(width: 12),
                        _StatusChip(
                          icon: Symbols.devices,
                          label: '$devOn ${s.devicesUnit}',
                          color: _kGreen,
                        ),
                        const SizedBox(width: 12),
                        _StatusChip(
                          icon: Symbols.videocam,
                          label: '${cameras.where((c) => c.isOnline).length}/${cameras.length}',
                          color: _kWhite70,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Hint ──────────────────────────────────────
                    Center(
                      child: Text(
                        '· · ·',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── FantaTech wordmark top-right ─────────────────────
              Positioned(
                top: 24, right: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _kOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Symbols.home, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Fanta', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      TextSpan(text: 'Tech', style: TextStyle(color: _kOrange,  fontSize: 14, fontWeight: FontWeight.w700)),
                    ])),
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
