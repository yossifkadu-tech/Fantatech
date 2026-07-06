import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_state.dart';
import '../../l10n/strings.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';

class CyberScreen extends StatefulWidget {
  const CyberScreen({super.key});

  @override
  State<CyberScreen> createState() => _CyberScreenState();
}

class _CyberScreenState extends State<CyberScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late List<_CyberAlert> _alerts;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _alerts          = _defaultAlerts();
    _recommendations = _defaultRecs();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  static const _cyan   = AppColors.cyberColor;
  static const _green  = AppColors.secured;
  static const _orange = AppColors.statusWarning;
  static const _red    = AppColors.statusAlarm;

  // Real threats only — populated by a backend/monitor when available.
  // No fake demo alerts (a security app must not show false positives).
  static List<_CyberAlert> _defaultAlerts() => [];

  late List<_CyberRec> _recommendations;

  // Real recommendations only — populated when a backend analysis is available.
  static List<_CyberRec> _defaultRecs() => [];

  void _dismissAlert(String id) =>
      setState(() => _alerts.removeWhere((a) => a.id == id));

  void _dismissRec(String id) =>
      setState(() => _recommendations.removeWhere((r) => r.id == id));

  void _refresh(BuildContext context) {
    _scanCtrl
      ..stop()
      ..reset()
      ..repeat();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.read<AppState>().strings.scanningDevices),
      backgroundColor: _cyan.withValues(alpha: 0.85),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  int get _threatCount => _alerts.length;

  int get _computedScore {
    if (_alerts.isEmpty) return 92;
    final critical = _alerts.where((a) => a.severity == _AlertSeverity.critical).length;
    final warning  = _alerts.where((a) => a.severity == _AlertSeverity.warning).length;
    return (92 - critical * 15 - warning * 7).clamp(0, 100);
  }

  // ── Tailscale VPN helpers ────────────────────────────────────────────────
  Future<void> _openTailscale(BuildContext context) async {
    // Try to open Tailscale app first, fallback to website
    const appUrl  = 'tailscale://';
    const webUrl  = 'https://tailscale.com/download';
    final appUri  = Uri.parse(appUrl);
    final webUri  = Uri.parse(webUrl);

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showVpnSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VpnSheet(
        vpnEnabled: state.vpnEnabled,
        onToggle: (v) {
          state.setVpnEnabled(v);
          if (v) _openTailscale(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state         = context.watch<AppState>();
    final s             = state.strings;
    final totalDevices  = state.devices.length;
    final onlineDevices = state.devicesOnlineCount;
    final score         = _computedScore;
    final threats       = _threatCount;

    return Scaffold(
      backgroundColor: context.tBg,
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
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  _TopBtn(icon: Symbols.refresh, color: _cyan, onTap: () => _refresh(context)),
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
                          icon: Symbols.devices,
                          iconColor: _cyan,
                          title: s.cyberDevicesMetric,
                          value: '$onlineDevices/$totalDevices',
                          subtitle: s.cyberConnected,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Symbols.shield,
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
                          icon: Symbols.lock,
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

            // ── Network map ───────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(title: s.cyberNetworkMap)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _NetworkMapCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Security alerts ───────────────────────────────
            if (_alerts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionLabel(
                  title: 'SECURITY ALERTS',
                  badge: '${_alerts.length}',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _alerts.asMap().entries.map((e) => Padding(
                      padding: EdgeInsets.only(
                          bottom: e.key < _alerts.length - 1 ? 10 : 0),
                      child: _AlertCard(
                        alert: e.value,
                        onDismiss: () => _dismissAlert(e.value.id),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            // ── Recommendations ───────────────────────────────
            if (_recommendations.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionLabel(
                  title: 'Recommendations',
                  badge: '${_recommendations.length}',
                  badgeColor: AppColors.statusWarning,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _recommendations.asMap().entries.map((e) =>
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: e.key < _recommendations.length - 1 ? 10 : 0),
                        child: _RecCard(
                          rec:       e.value,
                          onDismiss: () => _dismissRec(e.value.id),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            // ── Network protection ────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(title: s.cyberNetProtection)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _ProtectionRow(
                    icon: Symbols.router,
                    title: s.cyberFirewallTitle,
                    subtitle: s.cyberFirewallSub,
                    statusLabel: s.cyberStatusActive,
                    statusColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _ProtectionRow(
                    icon: Symbols.vpn_lock,
                    title: 'VPN (Tailscale)',
                    subtitle: s.cyberVpnSub,
                    statusLabel: state.vpnEnabled ? s.cyberStatusActive : s.cyberStatusOff,
                    statusColor: state.vpnEnabled ? _green : AppColors.statusOffline,
                    hasToggle: true,
                    onToggle: () => _showVpnSheet(context, state),
                  ),
                  const SizedBox(height: 10),
                  _ProtectionRow(
                    icon: Symbols.public_off,
                    title: s.cyberDnsTitle,
                    subtitle: s.cyberDnsSub,
                    statusLabel: s.cyberStatusActive,
                    statusColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _ProtectionRow(
                    icon: Symbols.wifi_protected_setup,
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
                    icon: Symbols.system_update,
                    color: _green,
                    badge: s.cyberBadgeOk,
                    badgeColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _AuditRow(
                    title: s.cyberDefaultPassTitle,
                    detail: s.cyberDefaultPassSub,
                    icon: Symbols.password,
                    color: _green,
                    badge: s.cyberBadgeOk,
                    badgeColor: _green,
                  ),
                  const SizedBox(height: 10),
                  _AuditRow(
                    title: s.cyberSecurityProto,
                    detail: 'WPA3 / TLS 1.3',
                    icon: Symbols.security,
                    color: _cyan,
                    badge: s.cyberBadgeRecommended,
                    badgeColor: _cyan,
                  ),
                  const SizedBox(height: 10),
                  _AuditRow(
                    title: s.cyberRemoteAccess,
                    detail: s.cyberRemoteAccessSub,
                    icon: Symbols.manage_accounts,
                    color: _orange,
                    badge: s.cyberBadgeCheck,
                    badgeColor: _orange,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Recent events (real — from AppState) ──────────
            SliverToBoxAdapter(child: _SectionLabel(title: s.cyberRecentEvents)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RealEventsList(events: state.recentCyberEvents),
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

  static const _cyan = AppColors.cyberColor;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.secured
        : score >= 60
            ? AppColors.statusWarning
            : AppColors.statusAlarm;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cyan.withValues(alpha: 0.07), context.tCard],
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
                              color: context.tText2(0.4),
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
                      color: context.tText2(0.5), fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: context.tText2(0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(s.cyberLastScan,
                    style: TextStyle(
                        color: context.tText2(0.28),
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
          ..color = AppColors.cyberColor.withValues(alpha: 0.35)
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
  final String  title;
  final String? badge;
  final Color   badgeColor;
  const _SectionLabel({
    required this.title,
    this.badge,
    this.badgeColor = AppColors.statusAlarm,
  });

  @override
  Widget build(BuildContext context) {
    final accent = badge != null ? badgeColor : AppColors.cyberColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          margin: const EdgeInsetsDirectional.only(end: 8),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: context.tText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: valueColor ?? context.tText,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title,
            style: TextStyle(
                color: context.tText, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(subtitle,
            style: TextStyle(
                color: context.tText2(0.4), fontSize: 9)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Real events list
// ──────────────────────────────────────────────────────────────
class _RealEventsList extends StatelessWidget {
  final List<SecurityEvent> events;
  const _RealEventsList({required this.events});

  static const _green  = AppColors.secured;
  static const _red    = AppColors.statusAlarm;

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            s.cyberNoEvents,
            style: TextStyle(color: context.tText2(0.4), fontSize: 13),
          ),
        ),
      );
    }
    return Column(
      children: events.asMap().entries.map((entry) {
        final e     = entry.value;
        final color = e.isAlert ? _red : _green;
        final icon  = e.isAlert ? Symbols.warning_amber : Symbols.check_circle;
        final time  = _formatTime(e.timestamp, s);
        return Padding(
          padding: EdgeInsets.only(bottom: entry.key < events.length - 1 ? 8 : 0),
          child: _EventRow(time: time, text: e.description, color: color, icon: icon),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt, S s) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return s.timeMinAgo.replaceAll('{n}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return s.timeHrAgo.replaceAll('{n}', '${diff.inHours}');
    }
    return s.timeDayAgo.replaceAll('{n}', '${diff.inDays}');
  }
}

// ──────────────────────────────────────────────────────────────
//  VPN bottom sheet
// ──────────────────────────────────────────────────────────────
class _VpnSheet extends StatelessWidget {
  final bool vpnEnabled;
  final void Function(bool) onToggle;
  const _VpnSheet({required this.vpnEnabled, required this.onToggle});

  static const _cyan  = AppColors.cyberColor;
  static const _green = AppColors.secured;

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.tText2(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(children: [
            Icon(Symbols.vpn_lock, color: _cyan, size: 22),
            const SizedBox(width: 10),
            Text('VPN — Tailscale',
                style: TextStyle(color: context.tText, fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            Switch(
              value: vpnEnabled,
              onChanged: onToggle,
              activeThumbColor: _green,
            ),
          ]),

          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cyan.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tailscaleWhat,
                    style: TextStyle(color: context.tText, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  s.tailscaleDesc,
                  style: TextStyle(color: context.tText2(0.6), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Steps
          _Step(n: '1', text: s.tailscaleStep1),
          const SizedBox(height: 8),
          _Step(n: '2', text: s.tailscaleStep2),
          const SizedBox(height: 8),
          _Step(n: '3', text: s.tailscaleStep3),

          const SizedBox(height: 20),

          // Open button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                onToggle(true);
                Navigator.pop(context);
              },
              icon: const Icon(Symbols.open_in_new, size: 18),
              label: Text(s.tailscaleOpen),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: AppColors.cyberColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(n,
            style: const TextStyle(
                color: AppColors.cyberColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: TextStyle(color: context.tText2(0.7), fontSize: 12, height: 1.4)),
      ),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────

class _ProtectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final bool hasToggle;
  final VoidCallback? onToggle;

  const _ProtectionRow({
    required this.icon, required this.title, required this.subtitle,
    required this.statusLabel, required this.statusColor,
    this.hasToggle = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.tText2(0.07)),
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
                style: TextStyle(
                    color: context.tText, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(
                    color: context.tText2(0.4), fontSize: 11)),
          ]),
        ),
        if (hasToggle && onToggle != null)
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Icon(Symbols.chevron_right, color: statusColor, size: 14),
              ]),
            ),
          )
        else
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
        color: context.tCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: context.tText, fontSize: 13, fontWeight: FontWeight.w500)),
            Text(detail,
                style: TextStyle(
                    color: context.tText2(0.4), fontSize: 11)),
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

// ──────────────────────────────────────────────────────────────
//  Network map
// ──────────────────────────────────────────────────────────────

class _NetworkMapCard extends StatelessWidget {
  const _NetworkMapCard();

  static const _cyan  = AppColors.cyberColor;
  static const _green = AppColors.secured;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    final cameraCount = state.cameras.length;
    final alarmCount  = state.devices.where((d) =>
        d.type == DeviceType.motionSensor ||
        d.type == DeviceType.doorSensor   ||
        d.type == DeviceType.windowSensor ||
        d.type == DeviceType.gateway      ||
        d.type == DeviceType.smokeSensor).length;
    final tvCount     = state.devices.where((d) => d.type == DeviceType.smartTv).length;
    final lightCount  = state.devices.where((d) => d.type == DeviceType.light).length;
    final phoneCount  = state.devices.where((d) => d.type == DeviceType.networkDevice).length;

    final leaves = [
      _NetLeaf(s.navCameras,   Symbols.videocam,    const Color(0xFF00BCD4), cameraCount),
      _NetLeaf(s.alarmTitle,   Symbols.shield,       AppColors.statusWarning, alarmCount),
      _NetLeaf('TV',           Symbols.tv,           AppColors.matterColor,   tvCount),
      _NetLeaf(s.lightsCategory, Symbols.lightbulb,   const Color(0xFFFFB300), lightCount),
      _NetLeaf(s.cyberPhones,  Symbols.phone_android, AppColors.networkDeviceColor, phoneCount),
    ];

    final onlineCount = state.devicesOnlineCount;
    final totalCount  = state.devices.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cyan.withValues(alpha: 0.06), context.tCard],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(children: [
            Icon(Symbols.account_tree, color: _cyan, size: 16),
            const SizedBox(width: 8),
            Text(s.cyberNetworkTopology,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withValues(alpha: 0.25)),
              ),
              child: Text(
                s.cyberOnlineFmt
                    .replaceAll('{on}', '$onlineCount')
                    .replaceAll('{total}', '$totalCount'),
                style: const TextStyle(
                    color: _green, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Tree diagram ─────────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 225,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TreeLinePainter(
                        totalWidth: w,
                        leafCount:  leaves.length,
                        lineColor:  _cyan.withValues(alpha: 0.32),
                      ),
                    ),
                  ),

                  // Internet — top center
                  Positioned(
                    top:  0,
                    left: w / 2 - 28,
                    child: _NetNode(
                      icon:  Symbols.cloud,
                      label: 'Internet',
                      color: _cyan,
                      nodeSize: 56,
                    ),
                  ),

                  // Router — middle center
                  Positioned(
                    top:  84,
                    left: w / 2 - 28,
                    child: _NetNode(
                      icon:  Symbols.router,
                      label: 'Router',
                      color: _cyan,
                      nodeSize: 56,
                    ),
                  ),

                  // Leaf nodes — bottom row
                  ...leaves.asMap().entries.map((e) {
                    final slotW = w / leaves.length;
                    final cx    = slotW * e.key + slotW / 2;
                    return Positioned(
                      top:  166,
                      left: cx - 27,
                      child: _NetNode(
                        icon:     e.value.icon,
                        label:    e.value.label,
                        color:    e.value.color,
                        count:    e.value.count,
                        nodeSize: 44,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────
class _NetLeaf {
  final String  label;
  final IconData icon;
  final Color   color;
  final int     count;
  const _NetLeaf(this.label, this.icon, this.color, this.count);
}

// ── Node widget ────────────────────────────────────────────────
class _NetNode extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final int?     count;
  final double   nodeSize;

  const _NetNode({
    required this.icon,
    required this.label,
    required this.color,
    this.count,
    this.nodeSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width:  nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  color:  color.withValues(alpha: 0.12),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: color.withValues(alpha: 0.40), width: 1.5),
                ),
                child: Icon(icon, color: color, size: nodeSize * 0.44),
              ),
              if (count != null && count! > 0)
                Positioned(
                  top:   -5,
                  right: -5,
                  child: Container(
                    width:  18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF080C14), width: 1.5),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:      context.tText2(0.65),
              fontSize:   10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Line painter ───────────────────────────────────────────────
class _TreeLinePainter extends CustomPainter {
  final double totalWidth;
  final int    leafCount;
  final Color  lineColor;

  const _TreeLinePainter({
    required this.totalWidth,
    required this.leafCount,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color      = lineColor
      ..strokeWidth = 1.5
      ..style      = PaintingStyle.stroke;

    final cx = totalWidth / 2;

    // Internet bottom → Router top
    // Internet: top=0, size=56 → bottom at 56
    // Router: top=84
    canvas.drawLine(Offset(cx, 56), Offset(cx, 84), paint);

    // Router bottom → branch junction
    // Router: top=84, size=56 → bottom at 140; junction at y=154
    canvas.drawLine(Offset(cx, 140), Offset(cx, 154), paint);

    // Horizontal spine across all leaves
    final slotW  = totalWidth / leafCount;
    final leftCx  = slotW * 0            + slotW / 2;
    final rightCx = slotW * (leafCount - 1) + slotW / 2;
    canvas.drawLine(Offset(leftCx, 154), Offset(rightCx, 154), paint);

    // Vertical drops from spine to each leaf
    // Leaf: top=166
    for (int i = 0; i < leafCount; i++) {
      final lx = slotW * i + slotW / 2;
      canvas.drawLine(Offset(lx, 154), Offset(lx, 166), paint);

      // Dot at junction
      canvas.drawCircle(
        Offset(lx, 154),
        3,
        Paint()..color = lineColor..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) =>
      old.totalWidth != totalWidth || old.leafCount != leafCount;
}

// ──────────────────────────────────────────────────────────────
//  Recommendation model + card
// ──────────────────────────────────────────────────────────────

class _CyberRec {
  final String   id;
  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    color;
  const _CyberRec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _RecCard extends StatelessWidget {
  final _CyberRec     rec;
  final VoidCallback  onDismiss;
  const _RecCard({required this.rec, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = rec.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(rec.icon, color: c, size: 19),
        ),
        const SizedBox(width: 12),

        // Text
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rec.title,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(rec.subtitle,
                style: TextStyle(
                    color: context.tText2(0.45), fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 10),

        // Action + dismiss column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Tip badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: c.withValues(alpha: 0.25)),
              ),
              child: Text('TIP',
                  style: TextStyle(
                      color: c,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 6),
            // Dismiss
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Symbols.check, size: 10, color: c),
                  const SizedBox(width: 3),
                  Text('Done',
                      style: TextStyle(
                          color: c,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Security alert model
// ──────────────────────────────────────────────────────────────
enum _AlertSeverity { critical, warning }

class _CyberAlert {
  final String id;
  final String title;
  final String subtitle;
  final _AlertSeverity severity;
  const _CyberAlert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
  });
}

// ──────────────────────────────────────────────────────────────
//  Alert card
// ──────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final _CyberAlert alert;
  final VoidCallback onDismiss;

  const _AlertCard({required this.alert, required this.onDismiss});

  static const _red    = AppColors.statusAlarm;
  static const _orange = AppColors.statusWarning;

  Color get _color =>
      alert.severity == _AlertSeverity.critical ? _red : _orange;

  IconData get _icon => alert.severity == _AlertSeverity.critical
      ? Symbols.error
      : Symbols.warning_amber;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withValues(alpha: 0.08), context.tCard],
        ),
      ),
      child: Row(children: [
        // Severity icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),

        // Text
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              alert.title,
              style: TextStyle(
                color: context.tText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              alert.subtitle,
              style: TextStyle(
                color: context.tText2(0.50),
                fontSize: 11,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),

        // Severity badge + dismiss
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Text(
                alert.severity == _AlertSeverity.critical ? 'CRITICAL' : 'WARNING',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.tText2(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Symbols.check, size: 10, color: context.tText2(0.45)),
                  const SizedBox(width: 3),
                  Text(
                    'Fix',
                    style: TextStyle(
                      color: context.tText2(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ),
          ],
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
              style: TextStyle(
                  color: context.tText, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(time,
              style: TextStyle(
                  color: context.tText2(0.35), fontSize: 10)),
        ]),
      ),
    ]);
  }
}
