import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/gateways/clients/ha_gateway_client.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_types.dart';
import '../../theme/app_theme.dart';

enum _CommState { idle, scanning, manual, commissioning, success, error, noHa }

class MatterCommissionScreen extends StatefulWidget {
  const MatterCommissionScreen({super.key});

  @override
  State<MatterCommissionScreen> createState() => _MatterCommissionScreenState();
}

class _MatterCommissionScreenState extends State<MatterCommissionScreen> {
  _CommState _state = _CommState.idle;
  String _scannedCode = '';
  final _manualCtrl   = TextEditingController();

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  // ── HA credentials ────────────────────────────────────────────────────────
  Map<String, String>? _haCredentials() {
    final gm = context.read<GatewayManager>();
    for (final c in gm.connections) {
      if (c.type == GatewayType.homeAssistant && c.isConnected) {
        final ip    = c.credentials['ip'];
        final token = c.credentials['token'];
        if (ip != null && token != null) return {'ip': ip, 'token': token};
      }
    }
    return null;
  }

  // ── Commission via HA ─────────────────────────────────────────────────────
  Future<void> _commission(String code) async {
    setState(() { _state = _CommState.commissioning; _scannedCode = code; });

    final creds = _haCredentials();
    if (creds == null) {
      setState(() => _state = _CommState.noHa);
      return;
    }

    final ok = await HaGatewayClient.commissionMatter(
      creds['ip']!,
      creds['token']!,
      code,
    );

    if (!mounted) return;
    setState(() => _state = ok ? _CommState.success : _CommState.error);
  }

  void _openScanner() {
    Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _MatterScannerScreen()),
    ).then((code) {
      if (code != null && code.isNotEmpty) {
        _commission(code);
      }
    });
  }

  void _submitManual() {
    final code = _manualCtrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    _commission(code);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.chevron_right, color: context.tText, size: 22),
                    ),
                  ),
                  Expanded(
                    child: Text(s.matterCommTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.tText, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: _buildBody(context, s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, dynamic s) {
    switch (_state) {
      case _CommState.idle:
        return _IdleView(
          s: s,
          onScan:   _openScanner,
          onManual: () => setState(() => _state = _CommState.manual),
        );

      case _CommState.scanning:
        // handled via push route
        return _IdleView(s: s, onScan: _openScanner,
            onManual: () => setState(() => _state = _CommState.manual));

      case _CommState.manual:
        return _ManualView(
          s: s,
          ctrl: _manualCtrl,
          onSubmit: _submitManual,
          onBack: () => setState(() => _state = _CommState.idle),
        );

      case _CommState.commissioning:
        return _CommissioningView(s: s, code: _scannedCode);

      case _CommState.success:
        return _ResultView(
          icon: Symbols.check_circle,
          color: AppColors.secured,
          title: s.matterCommSuccess,
          subtitle: _scannedCode,
          actionLabel: s.understood,
          onAction: () => Navigator.pop(context),
        );

      case _CommState.error:
        return _ResultView(
          icon: Symbols.error,
          color: AppColors.unsecured,
          title: s.matterCommFailed,
          subtitle: _scannedCode,
          actionLabel: s.matterCommRetry,
          secondaryLabel: s.cancel,
          onAction: () => setState(() => _state = _CommState.idle),
          onSecondary: () => Navigator.pop(context),
        );

      case _CommState.noHa:
        return _ResultView(
          icon: Symbols.link_off,
          color: Colors.orange,
          title: s.matterCommNoHa,
          subtitle: '',
          actionLabel: s.understood,
          onAction: () => Navigator.pop(context),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Idle — main screen
// ─────────────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final dynamic s;
  final VoidCallback onScan;
  final VoidCallback onManual;
  const _IdleView({required this.s, required this.onScan, required this.onManual});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Matter logo / icon
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Symbols.hub, color: Colors.white, size: 52),
          ),

          const SizedBox(height: 28),

          Text('Matter',
              style: TextStyle(
                  color: context.tText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),

          const SizedBox(height: 8),

          Text(s.matterCommSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.tText2(0.55), fontSize: 14, height: 1.5)),

          const SizedBox(height: 40),

          // What is Matter info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Symbols.info,
                      color: Color(0xFF6366F1), size: 16),
                  const SizedBox(width: 6),
                  Text('Matter',
                      style: TextStyle(
                          color: const Color(0xFF6366F1),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Apple, Google, Amazon, Samsung — כולם תומכים ב-Matter.\nמכשיר Matter עובד עם כל האקוסיסטמים ולא תלוי בענן.',
                  style: TextStyle(color: context.tText2(0.6), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Scan button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onScan();
              },
              icon: const Icon(Symbols.qr_code_scanner, size: 22),
              label: Text(s.matterCommScanBtn,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Manual entry button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onManual,
              icon: Icon(Symbols.keyboard, size: 18, color: context.tText2(0.6)),
              label: Text(s.matterCommManualBtn,
                  style: TextStyle(color: context.tText2(0.7), fontSize: 14)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.tText2(0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Manual entry
// ─────────────────────────────────────────────────────────────
class _ManualView extends StatelessWidget {
  final dynamic s;
  final TextEditingController ctrl;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  const _ManualView({
    required this.s, required this.ctrl,
    required this.onSubmit, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text(s.matterCommManualBtn,
              style: TextStyle(
                  color: context.tText, fontSize: 20, fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),

          Text(s.matterCommManualHint,
              style: TextStyle(color: context.tText2(0.5), fontSize: 13)),

          const SizedBox(height: 28),

          // Code input
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.text,
            style: TextStyle(
                color: context.tText, fontSize: 20,
                fontWeight: FontWeight.w600, letterSpacing: 2),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: s.matterCommCodeHint,
              hintStyle: TextStyle(
                  color: context.tText2(0.3), fontSize: 14,
                  fontWeight: FontWeight.normal, letterSpacing: 0),
              filled: true,
              fillColor: context.tText2(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.tText2(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.tText2(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Format examples
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.tText2(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormatRow(label: 'QR Code', example: 'MT:Y.K908000 0107...', context: context),
                const SizedBox(height: 4),
                _FormatRow(label: 'Manual', example: '34970-11233', context: context),
              ],
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.tText2(0.6),
                    side: BorderSide(color: context.tText2(0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(s.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(s.connect,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final String label;
  final String example;
  final BuildContext context;
  const _FormatRow({required this.label, required this.example, required this.context});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label,
              style: TextStyle(color: context.tText2(0.4), fontSize: 11)),
        ),
        Text(example,
            style: TextStyle(
                color: context.tText2(0.6),
                fontSize: 11,
                fontFamily: 'monospace')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Commissioning progress
// ─────────────────────────────────────────────────────────────
class _CommissioningView extends StatelessWidget {
  final dynamic s;
  final String code;
  const _CommissioningView({required this.s, required this.code});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 72, height: 72,
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text(s.matterCommissioning,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.tText, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.tText2(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code.length > 30 ? '${code.substring(0, 30)}…' : code,
                style: TextStyle(
                    color: context.tText2(0.45),
                    fontSize: 12,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Result (success / error / no HA)
// ─────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String? secondaryLabel;
  final VoidCallback onAction;
  final VoidCallback? onSecondary;

  const _ResultView({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 44),
          ),
          const SizedBox(height: 24),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.tText, fontSize: 18, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle.length > 40 ? '${subtitle.substring(0, 40)}…' : subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.tText2(0.45), fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!,
                  style: TextStyle(color: context.tText2(0.5))),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QR Scanner screen (push route)
// ─────────────────────────────────────────────────────────────
class _MatterScannerScreen extends StatefulWidget {
  const _MatterScannerScreen();

  @override
  State<_MatterScannerScreen> createState() => _MatterScannerScreenState();
}

class _MatterScannerScreenState extends State<_MatterScannerScreen> {
  late final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _detected = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _ctrl,
            errorBuilder: (context, error, child) {
              final denied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(denied
                              ? Symbols.camera_alt
                              : Symbols.error,
                          color: Colors.white54,
                          size: 56),
                      const SizedBox(height: 16),
                      Text(
                        denied
                            ? 'נדרשת הרשאת מצלמה'
                            : 'שגיאת מצלמה: ${error.errorCode.name}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                      ),
                      if (denied) ...[
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: openAppSettings,
                          child: const Text('פתח הגדרות'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('סגור',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_detected) return;
              final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
              if (raw.isNotEmpty) {
                _detected = true;
                HapticFeedback.mediumImpact();
                Navigator.pop(context, raw);
              }
            },
          ),

          // Overlay
          CustomPaint(
            painter: _MatterViewfinder(),
            child: const SizedBox.expand(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Symbols.close, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _ctrl.toggleTorch(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Symbols.flashlight_on,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom label
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.hub,
                          color: Color(0xFF8B5CF6), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'כוון למדבקת ה-QR של מכשיר ה-Matter',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Viewfinder painter — colored corners for Matter (purple theme)
class _MatterViewfinder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const boxSize = 240.0;
    const cornerLen = 28.0;
    const r = 4.0;

    final left   = cx - boxSize / 2;
    final top    = cy - boxSize / 2;
    final right  = cx + boxSize / 2;
    final bottom = cy + boxSize / 2;

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, boxSize), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, boxSize), overlayPaint);

    // Purple corners
    final cornerPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y + dy * r), Offset(x, y + dy * cornerLen), cornerPaint);
      canvas.drawLine(Offset(x + dx * r, y), Offset(x + dx * cornerLen, y), cornerPaint);
    }

    drawCorner(left, top, 1, 1);
    drawCorner(right, top, -1, 1);
    drawCorner(left, bottom, 1, -1);
    drawCorner(right, bottom, -1, -1);
  }

  @override
  bool shouldRepaint(_) => false;
}
