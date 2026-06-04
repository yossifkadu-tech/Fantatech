import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shieldCtrl;
  late Animation<double> _shieldScale;
  late Animation<double> _shieldGlow;

  @override
  void initState() {
    super.initState();
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shieldScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut),
    );
    _shieldGlow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    final doorSensor = state.devices
        .where((d) => d.type == DeviceType.doorSensor)
        .firstOrNull;
    final windowSensor = state.devices
        .where((d) => d.type == DeviceType.windowSensor)
        .firstOrNull;
    final motionSensors = state.devices
        .where((d) => d.type == DeviceType.motionSensor)
        .toList();

    final allOk = state.isSecured &&
        (doorSensor?.attributes['open'] != true) &&
        (windowSensor?.attributes['open'] != true) &&
        motionSensors.every((m) => m.attributes['detected'] != true);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.securityTitle),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    _AnimatedShield(
                      isSecured: allOk,
                      scaleAnim: _shieldScale,
                      glowAnim: _shieldGlow,
                      onToggle: state.toggleSecurity,
                      securedText: s.homeSecured,
                      notSecuredText: s.homeNotSecured,
                      activeText: s.allSystemsActive,
                      tapText: s.tapToActivate,
                    ),

                    const SizedBox(height: 28),

                    _SensorRow(
                      icon: Icons.lock_outline,
                      label: s.doorSensor,
                      status: _sensorStatusLabel(doorSensor, s),
                      color: _sensorColor(doorSensor),
                      statusIcon: _sensorIcon(doorSensor, true),
                      onTap: () => _showSensorDetail(context, s, s.doorSensor,
                          _sensorStatusLabel(doorSensor, s),
                          _sensorColor(doorSensor), Icons.lock_outline,
                          doorSensor),
                    ),
                    const SizedBox(height: 10),
                    _SensorRow(
                      icon: Icons.window_outlined,
                      label: s.windowsSensor,
                      status: _sensorStatusLabel(windowSensor, s),
                      color: _sensorColor(windowSensor),
                      statusIcon: _sensorIcon(windowSensor, true),
                      onTap: () => _showSensorDetail(context, s, s.windowsSensor,
                          _sensorStatusLabel(windowSensor, s),
                          _sensorColor(windowSensor), Icons.window_outlined,
                          windowSensor),
                    ),
                    const SizedBox(height: 10),
                    _SensorRow(
                      icon: Icons.sensors_outlined,
                      label: s.motionSensors,
                      status: motionSensors.isEmpty
                          ? s.offlineLabel
                          : motionSensors.any(
                                  (m) => m.attributes['detected'] == true)
                              ? s.activeStatus
                              : s.normalStatus,
                      color: motionSensors.any(
                              (m) => m.attributes['detected'] == true)
                          ? AppColors.unsecured
                          : AppColors.secured,
                      statusIcon: Icons.sensors,
                      onTap: () => _showSensorDetail(
                          context,
                          s,
                          s.motionSensors,
                          motionSensors.isEmpty
                              ? s.offlineLabel
                              : s.normalStatus,
                          motionSensors.any(
                                  (m) => m.attributes['detected'] == true)
                              ? AppColors.unsecured
                              : AppColors.secured,
                          Icons.sensors_outlined,
                          motionSensors.isEmpty ? null : motionSensors.first),
                    ),
                    const SizedBox(height: 10),
                    _SensorRow(
                      icon: Icons.smoke_free_outlined,
                      label: s.smokeDetector,
                      status: s.normalStatus,
                      color: AppColors.secured,
                      statusIcon: Icons.verified_outlined,
                      onTap: () => _showSensorDetail(context, s, s.smokeDetector,
                          s.normalStatus, AppColors.secured,
                          Icons.smoke_free_outlined, null),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            _PanicButton(
              onLongPress: () => _showPanicConfirm(context, state, s),
              panicLabel: s.panicLabel,
              warningLabel: s.panicWarning,
            ),
          ],
        ),
      ),
    );
  }

  void _showSensorDetail(BuildContext context, S s, String label,
      String status, Color color, IconData icon, Device? device) {
    HapticFeedback.lightImpact();
    final battery = device?.attributes['battery'];
    final online = device != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 22),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(status,
                style: TextStyle(color: color, fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 22),
            _detailRow(Icons.wifi, s.normalStatus,
                online ? s.activeStatus : s.offlineLabel,
                online ? AppColors.secured : Colors.white38),
            if (battery != null) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.battery_full, '🔋', '$battery%',
                  AppColors.secured),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _sensorStatusLabel(Device? d, S s) {
    final status = _sensorStatus(d);
    switch (status) {
      case _SensorStatus.secured:
        return s.securedStatus;
      case _SensorStatus.open:
        return s.openStatus;
      case _SensorStatus.notConnected:
        return s.offlineLabel;
    }
  }

  _SensorStatus _sensorStatus(Device? d) {
    if (d == null) return _SensorStatus.notConnected;
    if (d.status == DeviceStatus.offline) return _SensorStatus.notConnected;
    final open = d.attributes['open'] as bool? ?? false;
    return open ? _SensorStatus.open : _SensorStatus.secured;
  }

  Color _sensorColor(Device? d) {
    final s = _sensorStatus(d);
    switch (s) {
      case _SensorStatus.secured:
        return AppColors.secured;
      case _SensorStatus.open:
        return AppColors.unsecured;
      case _SensorStatus.notConnected:
        return Colors.grey;
    }
  }

  IconData _sensorIcon(Device? d, bool isDoor) {
    final s = _sensorStatus(d);
    if (s == _SensorStatus.open) return isDoor ? Icons.lock_open : Icons.window;
    if (s == _SensorStatus.notConnected) return Icons.link_off;
    return isDoor ? Icons.lock : Icons.shield_outlined;
  }

  void _showPanicConfirm(BuildContext context, AppState state, S s) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PanicSheet(
        title: s.panicButton,
        question: s.panicWarning,
        cancelLabel: s.cancel,
        confirmLabel: s.panicActivate,
        onConfirm: () {
          state.activateEmergencyMode();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.emergencyActivated),
              backgroundColor: AppColors.unsecured,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

enum _SensorStatus { secured, open, notConnected }

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
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
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
// Animated Shield
// ─────────────────────────────────────────────────────────────
class _AnimatedShield extends StatelessWidget {
  final bool isSecured;
  final Animation<double> scaleAnim;
  final Animation<double> glowAnim;
  final VoidCallback onToggle;
  final String securedText;
  final String notSecuredText;
  final String activeText;
  final String tapText;

  const _AnimatedShield({
    required this.isSecured,
    required this.scaleAnim,
    required this.glowAnim,
    required this.onToggle,
    required this.securedText,
    required this.notSecuredText,
    required this.activeText,
    required this.tapText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSecured ? AppColors.secured : AppColors.unsecured;

    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnim, glowAnim]),
      builder: (ctx, _) {
        return GestureDetector(
          onTap: onToggle,
          child: Column(
            children: [
              Transform.scale(
                scale: scaleAnim.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(
                                alpha: 0.2 * glowAnim.value),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),

                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.35),
                          color.withValues(alpha: 0.15),
                        ],
                      ).createShader(bounds),
                      child: Icon(
                        isSecured ? Icons.shield : Icons.shield_outlined,
                        size: 130,
                        color: Colors.white,
                      ),
                    ),

                    Icon(
                      isSecured ? Icons.check_rounded : Icons.close_rounded,
                      color: color,
                      size: 48,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                isSecured ? securedText : notSecuredText,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSecured ? activeText : tapText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sensor row
// ─────────────────────────────────────────────────────────────
class _SensorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color color;
  final IconData statusIcon;
  final VoidCallback? onTap;

  const _SensorRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.color,
    required this.statusIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 19),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Text(
              status,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 10),

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(statusIcon, color: color, size: 17),
            ),

            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_left,
                  color: Colors.white.withValues(alpha: 0.3), size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANIC button
// ─────────────────────────────────────────────────────────────
class _PanicButton extends StatefulWidget {
  final VoidCallback onLongPress;
  final String panicLabel;
  final String warningLabel;
  const _PanicButton({required this.onLongPress, required this.panicLabel, required this.warningLabel});

  @override
  State<_PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<_PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (ctx, _) => Transform.scale(
        scale: _pulseAnim.value,
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.warningLabel),
              duration: const Duration(seconds: 2),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD93025), Color(0xFFEA4335)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.unsecured.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.panicLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      widget.warningLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Panic confirmation sheet
// ─────────────────────────────────────────────────────────────
class _PanicSheet extends StatelessWidget {
  final String title;
  final String question;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PanicSheet({
    required this.title,
    required this.question,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.unsecured.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.unsecured,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.unsecured,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
