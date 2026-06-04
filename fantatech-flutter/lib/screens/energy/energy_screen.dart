import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────
class _SocketEntry {
  final String id;
  String name;
  String room;
  String protocol; // 'wifi' | 'zigbee'
  bool isOn;
  int watts;

  _SocketEntry({
    required this.id,
    required this.name,
    required this.room,
    required this.protocol,
    this.isOn = true,
    this.watts = 0,
  });
}

class _ChartPoint {
  final String label;
  final double consumption; // kWh
  final double solar; // kWh (optional overlay)
  const _ChartPoint(this.label, this.consumption, [this.solar = 0]);
}

class _DeviceRow {
  final IconData icon;
  final String name;
  final int watts;
  final Color color;
  const _DeviceRow({
    required this.icon,
    required this.name,
    required this.watts,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────
// Sample datasets
// ─────────────────────────────────────────────────────────────
const _dayData = [
  _ChartPoint('00', 0.4, 0.0),
  _ChartPoint('03', 0.2, 0.0),
  _ChartPoint('06', 0.5, 0.1),
  _ChartPoint('09', 1.2, 1.8),
  _ChartPoint('12', 1.8, 4.5),
  _ChartPoint('15', 2.1, 3.8),
  _ChartPoint('18', 3.2, 1.2),
  _ChartPoint('21', 2.8, 0.0),
];

const _weekData = [
  _ChartPoint('Sun', 8.2, 4.1),
  _ChartPoint('Mon', 9.5, 3.8),
  _ChartPoint('Tue', 7.8, 4.4),
  _ChartPoint('Wed', 11.2, 3.9),
  _ChartPoint('Thu', 10.1, 4.7),
  _ChartPoint('Fri', 6.4, 4.2),
  _ChartPoint('Sat', 12.3, 2.1),
];

const _monthData = [
  _ChartPoint('W1', 58.4, 28.2),
  _ChartPoint('W2', 63.1, 31.5),
  _ChartPoint('W3', 55.8, 29.8),
  _ChartPoint('W4', 71.2, 27.4),
];

const _devices = [
  _DeviceRow(
    icon: Icons.power_outlined,
    name: 'סלון',
    watts: 1200,
    color: AppColors.secured,
  ),
  _DeviceRow(
    icon: Icons.microwave_outlined,
    name: 'תנור',
    watts: 850,
    color: Colors.white70,
  ),
  _DeviceRow(
    icon: Icons.local_laundry_service_outlined,
    name: 'מכונת כביסה',
    watts: 480,
    color: AppColors.acColor,
  ),
];

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
List<_SocketEntry> _buildDemoSockets() => [
      _SocketEntry(
          id: 's1',
          name: 'מטען סלון',
          room: 'סלון',
          protocol: 'wifi',
          isOn: true,
          watts: 65),
      _SocketEntry(
          id: 's2',
          name: 'טלוויזיה',
          room: 'סלון',
          protocol: 'wifi',
          isOn: true,
          watts: 120),
      _SocketEntry(
          id: 's3',
          name: 'מדיח כלים',
          room: 'מטבח',
          protocol: 'zigbee',
          isOn: false,
          watts: 0),
];

class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  int _tabIndex = 0; // 0=Day, 1=Week, 2=Month
  int _selectedPoint = 4;
  late List<_SocketEntry> _sockets;

  List<_ChartPoint> get _currentData =>
      [_dayData, _weekData, _monthData][_tabIndex];

  double get _totalKwh => _currentData.fold(0, (s, p) => s + p.consumption);
  double get _totalSolar => _currentData.fold(0, (s, p) => s + p.solar);
  double get _netConsumption =>
      math.max(0, _totalKwh - _totalSolar);
  double get _savingPct => _totalKwh > 0
      ? (_totalSolar / _totalKwh * 100).clamp(0, 100)
      : 0;

  void _switchTab(int idx) {
    setState(() {
      _tabIndex = idx;
      _selectedPoint = _currentData.length - 1;
      _animCtrl.forward(from: 0);
    });
  }

  @override
  void initState() {
    super.initState();
    _sockets = _buildDemoSockets();
    _selectedPoint = _dayData.length - 1;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    final tabs = [s.energyDay, s.energyWeek, s.energyMonth];

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.energyTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Tab selector
                    _TabSelector(
                      tabs: tabs,
                      selected: _tabIndex,
                      onTap: _switchTab,
                    ),

                    const SizedBox(height: 16),

                    // Main chart card
                    _ChartCard(
                      data: _currentData,
                      selectedIndex: _selectedPoint,
                      anim: _anim,
                      onPointTap: (i) => setState(() => _selectedPoint = i),
                      totalKwh: _totalKwh,
                      totalSolar: _totalSolar,
                      netConsumption: _netConsumption,
                      savingPct: _savingPct,
                      tabIndex: _tabIndex,
                      fromLastLabel: s.fromLastMonth,
                    ),

                    const SizedBox(height: 20),

                    // Summary row
                    _SummaryRow(
                      totalKwh: _totalKwh,
                      solarKwh: _totalSolar,
                      netKwh: _netConsumption,
                      savingPct: _savingPct,
                    ),

                    const SizedBox(height: 20),

                    // Active devices
                    Text(
                      s.activeDevices,
                      style: TextStyle(
                        color: context.tText2(0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: context.tCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: context.tText2(0.07)),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _devices.length; i++) ...[
                            _DeviceTile(row: _devices[i]),
                            if (i < _devices.length - 1)
                              Divider(
                                height: 1,
                                color: context.tText2(0.06),
                                indent: 56,
                              ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Smart sockets section ─────────────────────
                    _SmartSocketsSection(
                      sockets: _sockets,
                      s: s,
                      onToggle: (id) => setState(() {
                        final sock =
                            _sockets.firstWhere((s) => s.id == id);
                        sock.isOn = !sock.isOn;
                        if (!sock.isOn) sock.watts = 0;
                      }),
                      onRegister: (name, room, protocol) => setState(() {
                        _sockets.add(_SocketEntry(
                          id: 's${_sockets.length + 1}',
                          name: name,
                          room: room,
                          protocol: protocol,
                          isOn: false,
                          watts: 0,
                        ));
                      }),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.tText,
                          side: BorderSide(
                              color: context.tText2(0.18)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          s.fullReport,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab selector
// ─────────────────────────────────────────────────────────────
class _TabSelector extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onTap;

  const _TabSelector({
    required this.tabs,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: isSelected ? context.tText : context.tText2(0.38),
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chart card
// ─────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final List<_ChartPoint> data;
  final int selectedIndex;
  final Animation<double> anim;
  final ValueChanged<int> onPointTap;
  final double totalKwh;
  final double totalSolar;
  final double netConsumption;
  final double savingPct;
  final int tabIndex;
  final String fromLastLabel;

  const _ChartCard({
    required this.data,
    required this.selectedIndex,
    required this.anim,
    required this.onPointTap,
    required this.totalKwh,
    required this.totalSolar,
    required this.netConsumption,
    required this.savingPct,
    required this.tabIndex,
    required this.fromLastLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sel = data[selectedIndex.clamp(0, data.length - 1)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${totalKwh.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.arrow_downward,
                          color: AppColors.secured, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '$fromLastLabel  ${savingPct.toStringAsFixed(0)}% solar',
                        style: TextStyle(
                          color: AppColors.secured,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Selected point badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sel.label,
                      style: TextStyle(
                        color: context.tText2(0.5),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${sel.consumption.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Legend
          Row(
            children: [
              _LegendDot(
                  color: AppColors.primary, label: 'Consumption'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: const Color(0xFFFFB300), label: 'Solar'),
            ],
          ),

          const SizedBox(height: 12),

          // Line chart
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: anim,
              builder: (ctx, _) => _LineChart(
                data: data,
                selectedIndex: selectedIndex,
                progress: anim.value,
                onTap: onPointTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
              color: context.tText2(0.45), fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Line chart
// ─────────────────────────────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<_ChartPoint> data;
  final int selectedIndex;
  final double progress;
  final ValueChanged<int> onTap;

  const _LineChart({
    required this.data,
    required this.selectedIndex,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final w = constraints.maxWidth;
                  final step = w / (data.length - 1);
                  final tapX = details.localPosition.dx;
                  int nearest = 0;
                  double minDist = double.infinity;
                  for (int i = 0; i < data.length; i++) {
                    final dist = (tapX - i * step).abs();
                    if (dist < minDist) {
                      minDist = dist;
                      nearest = i;
                    }
                  }
                  onTap(nearest);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _LineChartPainter(
                    data: data,
                    selectedIndex: selectedIndex,
                    progress: progress,
                    consumptionColor: AppColors.primary,
                    solarColor: const Color(0xFFFFB300),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // X-axis labels
        Row(
          children: List.generate(data.length, (i) {
            return Expanded(
              child: Text(
                data[i].label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i == selectedIndex
                      ? context.tText
                      : context.tText2(0.35),
                  fontSize: 9,
                  fontWeight: i == selectedIndex
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> data;
  final int selectedIndex;
  final double progress;
  final Color consumptionColor;
  final Color solarColor;

  const _LineChartPainter({
    required this.data,
    required this.selectedIndex,
    required this.progress,
    required this.consumptionColor,
    required this.solarColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data
        .map((p) => math.max(p.consumption, p.solar))
        .reduce(math.max);
    if (maxVal == 0) return;

    final w = size.width;
    final h = size.height;
    final step = w / (data.length - 1);

    Offset calcPoint(int i, double val) {
      final x = i * step;
      final y = h - (val / maxVal * h * progress).clamp(0.0, h);
      return Offset(x, y);
    }

    void drawLine(
        List<double> values, Color color, {bool fill = false}) {
      if (values.every((v) => v == 0)) return;

      final pts = List.generate(data.length, (i) => calcPoint(i, values[i]));

      // Build smooth path
      final path = Path();
      path.moveTo(pts[0].dx, pts[0].dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
        final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
        path.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
      }

      if (fill) {
        final fillPath = Path.from(path)
          ..lineTo(pts.last.dx, h)
          ..lineTo(pts.first.dx, h)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.0),
              ],
            ).createShader(Rect.fromLTWH(0, 0, w, h))
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Dots
      for (int i = 0; i < pts.length; i++) {
        final isSelected = i == selectedIndex;
        canvas.drawCircle(
          pts[i],
          isSelected ? 5.0 : 3.0,
          Paint()..color = color,
        );
        if (isSelected) {
          canvas.drawCircle(
            pts[i],
            8.0,
            Paint()
              ..color = color.withValues(alpha: 0.2)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            pts[i],
            5.0,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            pts[i],
            3.0,
            Paint()
              ..color = color
              ..style = PaintingStyle.fill,
          );
        }
      }
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Draw fills + lines
    drawLine(data.map((p) => p.solar).toList(), solarColor, fill: true);
    drawLine(data.map((p) => p.consumption).toList(), consumptionColor,
        fill: true);

    // Selected vertical line
    if (selectedIndex >= 0 && selectedIndex < data.length) {
      final x = selectedIndex * step;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.progress != progress ||
      old.selectedIndex != selectedIndex ||
      old.data != data;
}

// ─────────────────────────────────────────────────────────────
// Summary row
// ─────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final double totalKwh;
  final double solarKwh;
  final double netKwh;
  final double savingPct;

  const _SummaryRow({
    required this.totalKwh,
    required this.solarKwh,
    required this.netKwh,
    required this.savingPct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.bolt,
            value: totalKwh.toStringAsFixed(1),
            unit: 'kWh',
            label: 'Total',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.wb_sunny,
            value: solarKwh.toStringAsFixed(1),
            unit: 'kWh',
            label: 'Solar',
            color: const Color(0xFFFFB300),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.savings_outlined,
            value: savingPct.toStringAsFixed(0),
            unit: '%',
            label: 'Saved',
            color: AppColors.secured,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: context.tText2(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: context.tText2(0.35),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
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
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  Icons.chevron_right, color: context.tText, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Smart sockets section
// ─────────────────────────────────────────────────────────────
class _SmartSocketsSection extends StatelessWidget {
  final List<_SocketEntry> sockets;
  final dynamic s;
  final ValueChanged<String> onToggle;
  final void Function(String name, String room, String protocol) onRegister;

  const _SmartSocketsSection({
    required this.sockets,
    required this.s,
    required this.onToggle,
    required this.onRegister,
  });

  void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegisterSocketSheet(
        s: s,
        onSave: (name, room, protocol) {
          onRegister(name, room, protocol);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.socketRegistered),
              backgroundColor: AppColors.secured,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalW =
        sockets.where((s) => s.isOn).fold(0, (sum, s) => sum + s.watts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text(
              s.socketsTitle,
              style: TextStyle(
                color: context.tText2(0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showRegisterSheet(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      s.socketRegister,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Total watts badge
        if (totalW > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.plugColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.plugColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt,
                    color: AppColors.plugColor, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${s.socketPower}: ${totalW}W',
                  style: TextStyle(
                    color: AppColors.plugColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Socket cards list
        Container(
          decoration: BoxDecoration(
            color: context.tCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.tText2(0.07)),
          ),
          child: sockets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      s.socketAddNew,
                      style: TextStyle(
                          color: context.tText2(0.3),
                          fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < sockets.length; i++) ...[
                      _SocketTile(
                        entry: sockets[i],
                        s: s,
                        onToggle: () => onToggle(sockets[i].id),
                      ),
                      if (i < sockets.length - 1)
                        Divider(
                          height: 1,
                          color: context.tText2(0.06),
                          indent: 56,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SocketTile extends StatelessWidget {
  final _SocketEntry entry;
  final dynamic s;
  final VoidCallback onToggle;

  const _SocketTile(
      {required this.entry, required this.s, required this.onToggle});

  Color get _protoColor => entry.protocol == 'zigbee'
      ? const Color(0xFFFFB300)
      : const Color(0xFF7BB8FF);

  IconData get _protoIcon =>
      entry.protocol == 'zigbee' ? Icons.hub_outlined : Icons.wifi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Socket icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: entry.isOn
                  ? AppColors.plugColor.withValues(alpha: 0.12)
                  : context.tText2(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.power_outlined,
              color: entry.isOn ? AppColors.plugColor : context.tText2(0.24),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      entry.room,
                      style: TextStyle(
                        color: context.tText2(0.35),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(_protoIcon, color: _protoColor, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      entry.protocol.toUpperCase(),
                      style: TextStyle(color: _protoColor, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Watts
          if (entry.isOn && entry.watts > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                '${entry.watts}W',
                style: TextStyle(
                  color: AppColors.plugColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: entry.isOn
                    ? AppColors.plugColor
                    : context.tText2(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                alignment: entry.isOn
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: context.tText,
                    shape: BoxShape.circle,
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

// ─────────────────────────────────────────────────────────────
// Register socket bottom sheet
// ─────────────────────────────────────────────────────────────
class _RegisterSocketSheet extends StatefulWidget {
  final dynamic s;
  final void Function(String name, String room, String protocol) onSave;

  const _RegisterSocketSheet({required this.s, required this.onSave});

  @override
  State<_RegisterSocketSheet> createState() => _RegisterSocketSheetState();
}

class _RegisterSocketSheetState extends State<_RegisterSocketSheet> {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  String _protocol = 'wifi';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            s.socketRegister,
            style: TextStyle(
              color: context.tText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Name field
          _SheetField(
            ctrl: _nameCtrl,
            label: s.socketName,
            icon: Icons.power_outlined,
          ),
          const SizedBox(height: 12),

          // Room field
          _SheetField(
            ctrl: _roomCtrl,
            label: s.socketRoom,
            icon: Icons.meeting_room_outlined,
          ),
          const SizedBox(height: 16),

          // Protocol selector
          Text(
            s.socketProtocol,
            style: TextStyle(
              color: context.tText2(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ProtoOption(
                label: 'WiFi',
                icon: Icons.wifi,
                selected: _protocol == 'wifi',
                color: const Color(0xFF7BB8FF),
                onTap: () => setState(() => _protocol = 'wifi'),
              ),
              const SizedBox(width: 10),
              _ProtoOption(
                label: 'Zigbee',
                icon: Icons.hub_outlined,
                selected: _protocol == 'zigbee',
                color: const Color(0xFFFFB300),
                onTap: () => setState(() => _protocol = 'zigbee'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final room = _roomCtrl.text.trim();
                if (name.isEmpty || room.isEmpty) return;
                widget.onSave(name, room, _protocol);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.tText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(s.socketRegister,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;

  const _SheetField(
      {required this.ctrl, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: context.tText, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: context.tText2(0.4), fontSize: 13),
        prefixIcon:
            Icon(icon, color: context.tText2(0.3), size: 18),
        filled: true,
        fillColor: context.tText2(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: context.tText2(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ProtoOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ProtoOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : context.tText2(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : context.tText2(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : context.tText2(0.38), size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : context.tText2(0.38),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Device tile
// ─────────────────────────────────────────────────────────────
class _DeviceTile extends StatelessWidget {
  final _DeviceRow row;
  const _DeviceTile({required this.row});

  String get _percentage {
    const total = 1200 + 850 + 480;
    return '${(row.watts / total * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: row.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(row.icon, color: row.color, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: row.watts / 1200.0,
                    backgroundColor: context.tText2(0.08),
                    valueColor:
                        AlwaysStoppedAnimation(row.color.withValues(alpha: 0.7)),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${row.watts}W',
                style: TextStyle(
                  color: context.tText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _percentage,
                style: TextStyle(
                  color: context.tText2(0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
