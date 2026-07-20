import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
enum BreakerState { on, off, tripped }

class _Breaker {
  final String id;
  final String room;
  final int amps;
  BreakerState state;
  bool isConnected;
  bool useZigbee; // false = WiFi — no gateway reports real protocol yet

  _Breaker({
    required this.id,
    required this.room,
    required this.amps,
    this.state = BreakerState.on,
    this.isConnected = true,
    this.useZigbee = false,
  });
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class BreakersScreen extends StatefulWidget {
  const BreakersScreen({super.key});

  @override
  State<BreakersScreen> createState() => _BreakersScreenState();
}

class _BreakersScreenState extends State<BreakersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Real circuit-breaker devices only. No gateway currently classifies
  // anything as DeviceType.circuitBreaker, so this is honestly empty for
  // virtually everyone — see the empty state in build() below, instead of
  // the fixed 9-room demo panel this screen used to show unconditionally
  // (which is why a real "off"/"tripped" room could never change color).
  List<_Breaker> _breakersFrom(List<Device> devices) => devices
      .map((d) => _Breaker(
            id: d.id,
            room: d.name,
            amps: (d.attributes['amps'] as num?)?.toInt() ?? 0,
            state: d.status == DeviceStatus.alarm
                ? BreakerState.tripped
                : (d.isOn ? BreakerState.on : BreakerState.off),
            isConnected: d.status.isControllable,
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final breakers = _breakersFrom(
        state.devices.where((d) => d.type == DeviceType.circuitBreaker).toList());
    final onCount = breakers.where((b) => b.state == BreakerState.on).length;
    final trippedCount =
        breakers.where((b) => b.state == BreakerState.tripped).length;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.breakersTitle),
            if (breakers.isNotEmpty)
              _StatusStrip(
                onCount: onCount,
                trippedCount: trippedCount,
                total: breakers.length,
                pulseAnim: _pulseAnim,
                onLabel: s.breakerOn,
                trippedLabel: s.breakerTripped,
              ),
            Expanded(
              child: breakers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.electrical_services,
                                color: context.tText2(0.25), size: 44),
                            const SizedBox(height: 12),
                            Text(s.notConnectedLabel,
                                style: TextStyle(
                                    color: context.tText2(0.5), fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PanelHeader(label: s.breakerPanel),
                          const SizedBox(height: 14),
                          // No real device carries a "main breaker" flag —
                          // list every real breaker uniformly instead of
                          // fabricating which one is "main".
                          _SubBreakerGrid(
                            breakers: breakers,
                            onTap: (_) {}, // no real control path yet
                            onLabel: s.breakerOn,
                            offLabel: s.breakerOff,
                            trippedLabel: s.breakerTripped,
                            ampsLabel: s.breakerAmps,
                            connectLabel: s.breakerConnect,
                            wifiLabel: s.breakerWifi,
                            zigbeeLabel: s.breakerZigbee,
                            pulseAnim: _pulseAnim,
                          ),
                          const SizedBox(height: 8),
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
              child: Icon(Symbols.chevron_right,
                  color: context.tText, size: 22),
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
          // David Matza brand badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A6B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF4A80CC).withValues(alpha: 0.5)),
            ),
            child: const Text(
              'David Matza',
              style: TextStyle(
                color: Color(0xFF7BB8FF),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status strip
// ─────────────────────────────────────────────────────────────
class _StatusStrip extends StatelessWidget {
  final int onCount;
  final int trippedCount;
  final int total;
  final Animation<double> pulseAnim;
  final String onLabel;
  final String trippedLabel;

  const _StatusStrip({
    required this.onCount,
    required this.trippedCount,
    required this.total,
    required this.pulseAnim,
    required this.onLabel,
    required this.trippedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.tText2(0.07)),
        ),
        child: Row(
          children: [
            _StatusPill(
              count: onCount,
              total: total,
              label: onLabel,
              color: AppColors.secured,
            ),
            const SizedBox(width: 12),
            if (trippedCount > 0) ...[
              AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: pulseAnim.value,
                  child: _StatusPill(
                    count: trippedCount,
                    total: total,
                    label: trippedLabel,
                    color: AppColors.unsecured,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Power flow bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(onCount / total * 100).round()}%',
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: onCount / total,
                      backgroundColor: context.tText2(0.1),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.secured),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final int count;
  final int total;
  final String label;
  final Color color;

  const _StatusPill({
    required this.count,
    required this.total,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count/$total $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Panel header
// ─────────────────────────────────────────────────────────────
class _PanelHeader extends StatelessWidget {
  final String label;
  const _PanelHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: context.tText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Icon(Symbols.electrical_services,
            color: context.tText2(0.3), size: 18),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-breaker grid
// ─────────────────────────────────────────────────────────────
class _SubBreakerGrid extends StatelessWidget {
  final List<_Breaker> breakers;
  final void Function(_Breaker) onTap;
  final String onLabel;
  final String offLabel;
  final String trippedLabel;
  final String ampsLabel;
  final String connectLabel;
  final String wifiLabel;
  final String zigbeeLabel;
  final Animation<double> pulseAnim;

  const _SubBreakerGrid({
    required this.breakers,
    required this.onTap,
    required this.onLabel,
    required this.offLabel,
    required this.trippedLabel,
    required this.ampsLabel,
    required this.connectLabel,
    required this.wifiLabel,
    required this.zigbeeLabel,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: breakers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (ctx, i) {
        final b = breakers[i];
        return _SubBreakerCard(
          breaker: b,
          onTap: () => onTap(b),
          onLabel: onLabel,
          offLabel: offLabel,
          trippedLabel: trippedLabel,
          ampsLabel: ampsLabel,
          connectLabel: connectLabel,
          wifiLabel: wifiLabel,
          zigbeeLabel: zigbeeLabel,
          pulseAnim: pulseAnim,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-breaker card
// ─────────────────────────────────────────────────────────────
class _SubBreakerCard extends StatelessWidget {
  final _Breaker breaker;
  final VoidCallback onTap;
  final String onLabel;
  final String offLabel;
  final String trippedLabel;
  final String ampsLabel;
  final String connectLabel;
  final String wifiLabel;
  final String zigbeeLabel;
  final Animation<double> pulseAnim;

  const _SubBreakerCard({
    required this.breaker,
    required this.onTap,
    required this.onLabel,
    required this.offLabel,
    required this.trippedLabel,
    required this.ampsLabel,
    required this.connectLabel,
    required this.wifiLabel,
    required this.zigbeeLabel,
    required this.pulseAnim,
  });

  Color get _stateColor {
    if (!breaker.isConnected) return Colors.white.withValues(alpha: 0.24);
    return switch (breaker.state) {
      BreakerState.on => AppColors.secured,
      BreakerState.off => Colors.white.withValues(alpha: 0.38),
      BreakerState.tripped => AppColors.unsecured,
    };
  }

  String get _stateLabel {
    if (!breaker.isConnected) return connectLabel;
    return switch (breaker.state) {
      BreakerState.on => onLabel,
      BreakerState.off => offLabel,
      BreakerState.tripped => trippedLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _stateColor;
    final isTripped = breaker.state == BreakerState.tripped;

    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: isTripped ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BreakerVisual(state: breaker.state, size: 28,
                    disconnected: !breaker.isConnected),
                const Spacer(),
                if (breaker.isConnected) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              context.select((AppState st) => st.strings).translateRoomKey(breaker.room),
              style: TextStyle(
                color: context.tText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${breaker.amps}A',
                  style: TextStyle(
                    color: context.tText2(0.4),
                    fontSize: 9,
                  ),
                ),
                const Spacer(),
                if (breaker.isConnected)
                  _ProtocolChip(
                    label: breaker.useZigbee ? zigbeeLabel : wifiLabel,
                    icon: breaker.useZigbee
                        ? Symbols.hub
                        : Symbols.wifi,
                    color: AppColors.circuitBreakerColor,
                    small: true,
                  )
                else
                  Text(
                    connectLabel,
                    style: TextStyle(
                      color: context.tText2(0.3),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _stateLabel,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (isTripped) {
      return AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.unsecured
                    .withValues(alpha: 0.25 * pulseAnim.value),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
        child: card,
      );
    }
    return card;
  }
}

// ─────────────────────────────────────────────────────────────
// Breaker visual (the physical switch shape)
// ─────────────────────────────────────────────────────────────
class _BreakerVisual extends StatelessWidget {
  final BreakerState state;
  final double size;
  final bool disconnected;

  const _BreakerVisual({
    required this.state,
    required this.size,
    this.disconnected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, switchColor;
    if (disconnected) {
      bg = context.tText2(0.06);
      switchColor = context.tText2(0.24);
    } else {
      switch (state) {
        case BreakerState.on:
          bg = AppColors.secured.withValues(alpha: 0.12);
          switchColor = AppColors.secured;
          break;
        case BreakerState.off:
          bg = context.tText2(0.06);
          switchColor = context.tText2(0.38);
          break;
        case BreakerState.tripped:
          bg = AppColors.unsecured.withValues(alpha: 0.12);
          switchColor = AppColors.unsecured;
          break;
      }
    }

    final isOn = state == BreakerState.on && !disconnected;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: switchColor.withValues(alpha: 0.3)),
      ),
      child: CustomPaint(
        painter: _BreakerSwitchPainter(
          color: switchColor,
          isOn: isOn,
          isTripped: state == BreakerState.tripped && !disconnected,
        ),
      ),
    );
  }
}

class _BreakerSwitchPainter extends CustomPainter {
  final Color color;
  final bool isOn;
  final bool isTripped;

  const _BreakerSwitchPainter({
    required this.color,
    required this.isOn,
    required this.isTripped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (isTripped) {
      // Zigzag "tripped" symbol
      final path = Path();
      final w = size.width * 0.28;
      final h = size.height * 0.32;
      path.moveTo(cx, cy - h);
      path.lineTo(cx - w * 0.5, cy - h * 0.1);
      path.lineTo(cx + w * 0.3, cy - h * 0.1);
      path.lineTo(cx, cy + h);
      path.lineTo(cx + w * 0.5, cy + h * 0.1);
      path.lineTo(cx - w * 0.3, cy + h * 0.1);
      path.close();
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else {
      // Breaker handle rectangle
      final handleW = size.width * 0.32;
      final handleH = size.height * 0.52;
      final handleX = cx - handleW / 2;
      final handleY = isOn ? cy - handleH * 0.65 : cy + handleH * 0.05;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(handleX, handleY, handleW, handleH),
          Radius.circular(handleW / 2),
        ),
        paint,
      );

      // Slot
      final slotPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              cx - handleW / 2 - 1, cy - handleH * 0.55,
              handleW + 2, handleH * 1.1),
          Radius.circular(handleW / 2 + 1),
        ),
        slotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BreakerSwitchPainter old) =>
      old.isOn != isOn || old.isTripped != isTripped || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Protocol chip
// ─────────────────────────────────────────────────────────────
class _ProtocolChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool small;

  const _ProtocolChip({
    required this.label,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: small ? 9 : 11),
          SizedBox(width: small ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: small ? 9 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
