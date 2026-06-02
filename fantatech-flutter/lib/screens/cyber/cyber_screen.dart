import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

class CyberScreen extends StatefulWidget {
  const CyberScreen({super.key});

  @override
  State<CyberScreen> createState() => _CyberScreenState();
}

class _CyberScreenState extends State<CyberScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  static const _cyan   = Color(0xFF00E5FF);
  static const _green  = Color(0xFF00E676);
  static const _orange = Color(0xFFFF9800);
  static const _red    = Color(0xFFEA4335);

  @override
  Widget build(BuildContext context) {
    final state        = context.watch<AppState>();
    final s            = state.strings;
    final totalDevices = state.devices.length;
    final onlineDevices =
        state.devices.where((d) => d.status.name == 'online').length;
    const threats = 0;  // mock
    const score   = 94; // mock cyber score

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      s.cyberTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  _TopBtn(icon: Icons.refresh_rounded, color: _cyan, onTap: () {}),
                ]),
              ),
            ),

            // ── Cyber score ring ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _CyberScoreCard(
                  score: score,
                  threats: threats,
                  scanAnim: _scanCtrl,
                  s: s,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Metric row ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.devices_outlined,
                          iconColor: _cyan,
                          title: s.cyberDevicesMetric,
                          value: '$onlineDevices/$totalDevices',
                          subtitle: s.cyberConnected,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.shield_outlined,
                          iconColor: threats == 0 ? _green : _red,
                          title: s.cyberThreats,
                          value: '$threats',
                          subtitle: threats == 0 ? s.cyberNoThreatsSub : s.cyberNeedsTreatment,
                          valueColor: threats == 0 ? _green : _red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.lock_outlined,
                          iconColor: _green,
                          title: s.cyberEncryption,
                          value: 'AES',
                          subtitle: '256-bit',
                          valueColor: _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Network protection ────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(title: s.cyberNetProtection)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _ProtectionRow(
                    icon: Icons.router_outlined,
                    title: s.cyberFirewallTitle,
                    subtitle: s.cyberFirewallSub,
                    statusLabel: s.cyberStatusActive,
                    statusColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _ProtectionRow(
                    icon: Icons.vpn_lock_outlined,
                    title: 'VPN',
                    subtitle: s.cyberVpnSub,
                    statusLabel: s.cyberStatusOff,
                    statusColor: Colors.grey,
                    hasToggle: true,
                  ),
                  const SizedBox(height: 10),
                  _ProtectionRow(
                    icon: Icons.public_off_outlined,
                    title: s.cyberDnsTitle,
                    subtitle: s.cyberDnsSub,
                    statusLabel: s.cyberStatusActive,
                    statusColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _ProtectionRow(
                    icon: Icons.wifi_protected_setup_outlined,
                    title: s.cyberIotTitle,
                    subtitle: s.cyberIotSub,
                    statusLabel: s.cyberStatusActive,
                    statusColor: _green,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Device audit ──────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(title: s.cyberDeviceAudit)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _AuditRow(
                    title: s.cyberFirmware,
                    detail: '$totalDevices ${s.cyberFirmwareUpToDate}',
                    icon: Icons.system_update_outlined,
                    color: _green,
                    badge: s.cyberBadgeOk,
                    badgeColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _AuditRow(
                    title: s.cyberDefaultPassTitle,
                    detail: s.cyberDefaultPassSub,
                    icon: Icons.password_outlined,
                    color: _green,
                    badge: s.cyberBadgeOk,
                    badgeColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _AuditRow(
                    title: s.cyberSecurityProto,
                    detail: 'WPA3 / TLS 1.3',
                    icon: Icons.security_outlined,
                    color: _cyan,
                    badge: s.cyberBadgeRecommended,
                    badgeColor: _cyan,
                  ),
                  const SizedBox(height: 10),
                  _AuditRow(
                    title: s.cyberRemoteAccess,
                    detail: s.cyberRemoteAccessSub,
                    icon: Icons.manage_accounts_outlined,
                    color: _orange,
                    badge: s.cyberBadgeCheck,
                    badgeColor: _orange,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Recent events ─────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(title: s.cyberRecentEvents)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _EventRow(time: s.cyberEvent1Time, text: s.cyberEvent1Text, color: _green,  icon: Icons.check_circle_outline),
                  const SizedBox(height: 8),
                  _EventRow(time: s.cyberEvent2Time, text: s.cyberEvent2Text, color: _cyan,   icon: Icons.device_hub_outlined),
                  const SizedBox(height: 8),
                  _EventRow(time: s.cyberEvent3Time, text: s.cyberEvent3Text, color: _orange, icon: Icons.block_outlined),
                  const SizedBox(height: 8),
                  _EventRow(time: s.cyberEvent4Time, text: s.cyberEvent4Text, color: _green,  icon: Icons.update_outlined),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Cyber score card
// ──────────────────────────────────────────────────────────────
class _CyberScoreCard extends StatelessWidget {
  final int score;
  final int threats;
  final Animation<double> scanAnim;
  final dynamic s; // S strings object

  const _CyberScoreCard({
    required this.score,
    required this.threats,
    required this.scanAnim,
    required this.s,
  });

  static const _cyan = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? const Color(0xFF00E676)
        : score >= 60
            ? const Color(0xFFFF9800)
            : const Color(0xFFEA4335);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cyan.withValues(alpha: 0.07), AppColors.darkCard],
        ),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 100, height: 100,
            child: AnimatedBuilder(
              animation: scanAnim,
              builder: (ctx, _) => CustomPaint(
                painter: _ScoreRingPainter(
                  progress: score / 100,
                  color: color,
                  scanAngle: scanAnim.value * 2 * math.pi,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$score',
                          style: TextStyle(
                              color: color,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1)),
                      Text(s.cyberScore,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score >= 80 ? s.cyberNetProtected : s.cyberNeedsImprovement,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  threats == 0
                      ? s.cyberNoThreats
                      : '$threats ${s.cyberActiveThreats}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(s.cyberLastScan,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.28),
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double scanAngle;
  const _ScoreRingPainter(
      {required this.progress, required this.color, required this.scanAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final r    = size.width * 0.44;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawArc(rect, 0, 2 * math.pi, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7);

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);

    final sx = cx + r * 0.6 * math.cos(scanAngle - math.pi / 2);
    final sy = cy + r * 0.6 * math.sin(scanAngle - math.pi / 2);
    canvas.drawLine(Offset(cx, cy), Offset(sx, sy),
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.scanAngle != scanAngle;
}

// ──────────────────────────────────────────────────────────────
//  Helpers
// ──────────────────────────────────────────────────────────────
class _TopBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TopBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
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
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Color? valueColor;
  const _MetricCard({
    required this.icon, required this.iconColor,
    required this.title, required this.value,
    required this.subtitle, this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
      ]),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final bool hasToggle;

  const _ProtectionRow({
    required this.icon, required this.title, required this.subtitle,
    required this.statusLabel, required this.statusColor,
    this.hasToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
          ),
          child: Text(statusLabel,
              style: TextStyle(
                  color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String title, detail, badge;
  final IconData icon;
  final Color color, badgeColor;
  const _AuditRow({
    required this.title, required this.detail, required this.badge,
    required this.icon, required this.color, required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            Text(detail,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
          ),
          child: Text(badge,
              style: TextStyle(
                  color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String time, text;
  final Color color;
  final IconData icon;
  const _EventRow(
      {required this.time, required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 30, height: 30,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(time,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
        ]),
      ),
    ]);
  }
}
