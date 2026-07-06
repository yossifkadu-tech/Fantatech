import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — first-run intro (3 info pages + permission priming page).
// Uses the same house-photo background as the login screen for visual
// consistency across the entire pre-authenticated flow.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../widgets/brand_logo.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _requesting = false;

  static const _accent = LinearGradient(
    colors: [Color(0xFF7B2FFF), Color(0xFFFF2D8A)],
  );

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await [
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } catch (_) {
      // Some platforms / older Androids may not have all of these.
    }
    if (mounted) setState(() => _requesting = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);

    final pages = <_PageData>[
      _PageData(
        icon: Symbols.home,
        color: const Color(0xFF7B2FFF),
        title: 'FantaTech Smart Home',
        body: s.onb1Body,
      ),
      _PageData(
        icon: Symbols.devices_other,
        color: const Color(0xFF00B4D8),
        title: s.onb2Title,
        body: s.onb2Body,
      ),
      _PageData(
        icon: Symbols.auto_awesome,
        color: const Color(0xFFFFB300),
        title: s.onb3Title,
        body: s.onb3Body,
      ),
      _PageData(
        icon: Symbols.shield,
        color: const Color(0xFF34A853),
        title: s.onbPermTitle,
        body: s.onbPermBody,
        isPermission: true,
      ),
    ];

    final isLast = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── House photo background ─────────────────────────────────────────
          Image.asset(
            'assets/images/main.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Gradient overlay (light at top, dark at bottom) ────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.28, 0.55, 1.0],
                colors: [
                  Color(0x440a1628),
                  Color(0x770a1628),
                  Color(0xCC0a1628),
                  Color(0xF20a1628),
                ],
              ),
            ),
          ),

          // ── Main UI ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Skip button
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: TextButton(
                      onPressed: widget.onDone,
                      child: Text(
                        s.onbSkip,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ),
                  ),
                ),

                // Brand logo — fixed above pages
                const Center(child: BrandLogo(size: BrandLogoSize.large)),
                const SizedBox(height: 4),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: pages.length,
                    itemBuilder: (_, i) => _OnbPage(data: pages[i]),
                  ),
                ),

                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // CTA button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: GestureDetector(
                    onTap: () {
                      if (isLast) {
                        _requestPermissions();
                      } else {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF7B2FFF).withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _requesting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white),
                              )
                            : Text(
                                isLast ? s.onbAllow : s.onbNext,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                // "Later" link on the permissions page
                if (isLast)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton(
                      onPressed: widget.onDone,
                      child: Text(
                        s.onbLater,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45)),
                      ),
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

// ─── Page data ────────────────────────────────────────────────────────────────

class _PageData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isPermission;

  const _PageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.isPermission = false,
  });
}

// ─── Individual onboarding page ───────────────────────────────────────────────

class _OnbPage extends StatelessWidget {
  final _PageData data;
  const _OnbPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon inside a glowing frosted circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border:
                  Border.all(color: data.color.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(data.icon, color: data.color, size: 52),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Body
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 15,
              height: 1.65,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                ),
              ],
            ),
          ),

          // Permission chips
          if (data.isPermission) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PermChip(
                    icon: Symbols.location_on,
                    label: 'Location',
                    color: data.color),
                const SizedBox(width: 10),
                _PermChip(
                    icon: Symbols.bluetooth,
                    label: 'Bluetooth',
                    color: data.color),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Permission chip ──────────────────────────────────────────────────────────

class _PermChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PermChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
