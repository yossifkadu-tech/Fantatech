import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

// ── Solar colour palette ─────────────────────────────────────
const _kSolarYellow  = Color(0xFFFFB800);
const _kSolarOrange  = Color(0xFFFF6B00);
const _kSolarGreen   = Color(0xFF00C853);
const _kSolarBlue    = Color(0xFF00B4D8);

class SolarScreen extends StatefulWidget {
  const SolarScreen({super.key});
  @override
  State<SolarScreen> createState() => _SolarScreenState();
}

class _SolarScreenState extends State<SolarScreen>
    with TickerProviderStateMixin {
  late AnimationController _sunCtrl;
  late AnimationController _flowCtrl;
  late Animation<double> _sunPulse;
  late Animation<double> _flowAnim;

  // Simulated live data
  final double _productionKw   = 4.7;
  final double _consumptionKw  = 2.1;
  final double _batteryPct     = 78.0;
  final double _feedInKw       = 2.6;
  final double _todayKwh       = 18.4;
  final double _savingToday    = 22.1; // ₪

  // 24-hour production curve (hourly kWh)
  static const _hourly = [
    0.0, 0.0, 0.0, 0.0, 0.0, 0.1,
    0.3, 0.8, 1.6, 2.8, 3.9, 4.5,
    4.7, 4.6, 4.2, 3.5, 2.6, 1.4,
    0.6, 0.2, 0.0, 0.0, 0.0, 0.0,
  ];

  bool _isConnected = false;
  String _selectedProtocol = 'WiFi';

  @override
  void initState() {
    super.initState();
    _sunCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _sunPulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _sunCtrl, curve: Curves.easeInOut));
    _flowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _flowAnim = CurvedAnimation(parent: _flowCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _sunCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.chevron_left,
                          color: context.tText, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.solarTitle,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  // Connection indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_isConnected ? _kSolarGreen : context.tText2(0.24))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_isConnected ? _kSolarGreen : context.tText2(0.24))
                            .withValues(alpha: 0.35)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isConnected ? _kSolarGreen : context.tText2(0.38)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isConnected ? s.solarStatus : s.solarConnect,
                        style: TextStyle(
                          color: _isConnected ? _kSolarGreen : context.tText2(0.54),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Sun animation + live production ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1200), Color(0xFF1A2000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: _kSolarYellow.withValues(alpha: 0.20)),
                  ),
                  child: Stack(
                    children: [
                      // Background glow
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _sunPulse,
                          builder: (_, __) => CustomPaint(
                            painter: _SunGlowPainter(
                                scale: _sunPulse.value),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.solarProduction,
                                style: TextStyle(
                                  color: context.tText2(0.55),
                                  fontSize: 13,
                                )),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _productionKw.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: _kSolarYellow,
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('kW',
                                      style: TextStyle(
                                        color: context.tText
                                            .withValues(alpha: 0.50),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      )),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(children: [
                              _LiveChip(
                                icon: Icons.wb_sunny_outlined,
                                label:
                                    '${s.solarToday}: ${_todayKwh.toStringAsFixed(1)} ${s.solarKw}',
                                color: _kSolarYellow,
                              ),
                              const SizedBox(width: 10),
                              _LiveChip(
                                icon: Icons.savings_outlined,
                                label:
                                    '${s.solarSaving}: ₪${_savingToday.toStringAsFixed(0)}',
                                color: _kSolarGreen,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Power flow diagram ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _flowAnim,
                  builder: (_, __) => _PowerFlowCard(
                    productionKw: _productionKw,
                    consumptionKw: _consumptionKw,
                    feedInKw: _feedInKw,
                    batteryPct: _batteryPct,
                    flowProgress: _flowAnim.value,
                    s: s,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Metrics row ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.battery_charging_full_outlined,
                      label: s.solarBattery,
                      value: '${_batteryPct.round()}%',
                      color: _kSolarGreen,
                      progress: _batteryPct / 100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.electrical_services_outlined,
                      label: s.solarFeedIn,
                      value:
                          '${_feedInKw.toStringAsFixed(1)} kW',
                      color: _kSolarBlue,
                      progress: _feedInKw / _productionKw,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.home_outlined,
                      label: s.solarConsumption,
                      value:
                          '${_consumptionKw.toStringAsFixed(1)} kW',
                      color: _kSolarOrange,
                      progress: _consumptionKw / _productionKw,
                    ),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── 24h production curve ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.tCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: context.tText2(0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.solarToday,
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 110,
                        child: CustomPaint(
                          size: const Size(double.infinity, 110),
                          painter: _SolarCurvePainter(
                              data: _hourly,
                              color: _kSolarYellow),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['00', '06', '12', '18', '24']
                            .map((h) => Text(h,
                                style: TextStyle(
                                    color: context.tText2(0.30),
                                    fontSize: 10)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Connect / Protocol selection ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.tCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: context.tText2(0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.solarConnect,
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      // Protocol chips
                      Row(children: [
                        _ProtoChip(
                          label: 'WiFi',
                          icon: Icons.wifi_outlined,
                          selected: _selectedProtocol == 'WiFi',
                          onTap: () =>
                              setState(() => _selectedProtocol = 'WiFi'),
                        ),
                        const SizedBox(width: 10),
                        _ProtoChip(
                          label: 'Zigbee',
                          icon: Icons.hub_outlined,
                          selected: _selectedProtocol == 'Zigbee',
                          onTap: () =>
                              setState(() => _selectedProtocol = 'Zigbee'),
                        ),
                        const SizedBox(width: 10),
                        _ProtoChip(
                          label: 'Modbus',
                          icon: Icons.cable_outlined,
                          selected: _selectedProtocol == 'Modbus',
                          onTap: () =>
                              setState(() => _selectedProtocol = 'Modbus'),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            _isConnected
                                ? Icons.check_circle_outline
                                : Icons.solar_power_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _isConnected
                                ? s.solarStatus
                                : '${s.solarConnect} · $_selectedProtocol',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: () =>
                              setState(() => _isConnected = !_isConnected),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isConnected ? _kSolarGreen : _kSolarYellow,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                        ),
                      ),
                    ],
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

// ─── Widgets ────────────────────────────────────────────────

class _LiveChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _LiveChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double progress;
  const _MetricCard(
      {required this.icon, required this.label, required this.value,
       required this.color, required this.progress});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: context.tText2(0.40), fontSize: 10),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: context.tText2(0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ]),
      );
}

class _ProtoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ProtoChip(
      {required this.label, required this.icon,
       required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? _kSolarYellow.withValues(alpha: 0.15)
                : context.tText2(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _kSolarYellow.withValues(alpha: 0.50)
                  : context.tText2(0.10),
              width: 1.2,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: selected ? _kSolarYellow : context.tText2(0.38), size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: selected ? _kSolarYellow : context.tText2(0.38),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        ),
      );
}

// ─── Power flow card ─────────────────────────────────────────
class _PowerFlowCard extends StatelessWidget {
  final double productionKw, consumptionKw, feedInKw, batteryPct, flowProgress;
  final dynamic s;
  const _PowerFlowCard(
      {required this.productionKw, required this.consumptionKw,
       required this.feedInKw, required this.batteryPct,
       required this.flowProgress, required this.s});

  @override
  Widget build(BuildContext context) => Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: context.tText2(0.07)),
        ),
        child: CustomPaint(
          painter: _FlowPainter(
              progress: flowProgress,
              productionKw: productionKw,
              consumptionKw: consumptionKw,
              feedInKw: feedInKw,
              batteryPct: batteryPct,
              labelSolar: s.solarProduction,
              labelHome: s.solarConsumption,
              labelGrid: s.solarGrid,
              labelBatt: s.solarBattery),
          child: const SizedBox.expand(),
        ),
      );
}

// ─── Custom Painters ─────────────────────────────────────────
class _SunGlowPainter extends CustomPainter {
  final double scale;
  const _SunGlowPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.75, cy = size.height * 0.35;
    final r = size.height * 0.45 * scale;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          _kSolarYellow.withValues(alpha: 0.20),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
  }

  @override
  bool shouldRepaint(_SunGlowPainter old) => old.scale != scale;
}

class _SolarCurvePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const _SolarCurvePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final max = data.reduce(math.max);
    if (max == 0) return;

    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] / max) * size.height;
      pts.add(Offset(x, y));
    }

    // Smooth curve
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final mid = Offset(
          (pts[i].dx + pts[i + 1].dx) / 2,
          (pts[i].dy + pts[i + 1].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // Fill area
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FlowPainter extends CustomPainter {
  final double progress;
  final double productionKw, consumptionKw, feedInKw, batteryPct;
  final String labelSolar, labelHome, labelGrid, labelBatt;

  const _FlowPainter({
    required this.progress,
    required this.productionKw, required this.consumptionKw,
    required this.feedInKw, required this.batteryPct,
    required this.labelSolar, required this.labelHome,
    required this.labelGrid, required this.labelBatt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Node positions
    final solar   = Offset(w * 0.20, h * 0.25);
    final home    = Offset(w * 0.80, h * 0.25);
    final grid    = Offset(w * 0.80, h * 0.80);
    final battery = Offset(w * 0.20, h * 0.80);

    void drawNode(Offset pos, String label, Color color, IconData icon) {
      canvas.drawCircle(pos, 22,
          Paint()..color = color.withValues(alpha: 0.15));
      canvas.drawCircle(pos, 22,
          Paint()
            ..color = color.withValues(alpha: 0.40)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 26));
    }

    void drawFlow(Offset from, Offset to, Color color, double kw) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(from, to, paint);

      // Animated dot
      final t = progress % 1.0;
      final dot = Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t,
      );
      canvas.drawCircle(dot, 4,
          Paint()..color = color.withValues(alpha: 0.85));

      // kW label at midpoint
      final mid = Offset(
          (from.dx + to.dx) / 2 + 6, (from.dy + to.dy) / 2 - 12);
      final tp = TextPainter(
        text: TextSpan(
          text: '${kw.toStringAsFixed(1)}kW',
          style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mid);
    }

    drawFlow(solar, home,    _kSolarYellow, productionKw - feedInKw);
    drawFlow(solar, battery, _kSolarGreen,  batteryPct / 100 * 1.5);
    drawFlow(solar, grid,    _kSolarBlue,   feedInKw);

    drawNode(solar,   labelSolar, _kSolarYellow, Icons.wb_sunny_outlined);
    drawNode(home,    labelHome,  _kSolarOrange, Icons.home_outlined);
    drawNode(grid,    labelGrid,  _kSolarBlue,   Icons.electrical_services);
    drawNode(battery, labelBatt,  _kSolarGreen,  Icons.battery_charging_full);
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.progress != progress;
}
