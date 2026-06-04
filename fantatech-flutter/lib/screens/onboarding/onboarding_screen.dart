// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — first-run intro (3 info pages + permission priming page).
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

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
    final s = context.watch<AppState>().strings;

    final pages = <_OnbPage>[
      _OnbPage(
        icon: Icons.home_rounded,
        color: const Color(0xFF7B2FFF),
        title: s.onb1Title,
        body: s.onb1Body,
      ),
      _OnbPage(
        icon: Icons.devices_other_rounded,
        color: const Color(0xFF00B4D8),
        title: s.onb2Title,
        body: s.onb2Body,
      ),
      _OnbPage(
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFFFB300),
        title: s.onb3Title,
        body: s.onb3Body,
      ),
      _OnbPage(
        icon: Icons.shield_rounded,
        color: const Color(0xFF34A853),
        title: s.onbPermTitle,
        body: s.onbPermBody,
        isPermission: true,
      ),
    ];

    final isLast = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0B2044),
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text(s.onbSkip,
                      style: TextStyle(
                          color: context.tText2(0.55))),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => pages[i],
              ),
            ),

            // Dots
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
                        ? context.tText
                        : context.tText2(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CTA
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
                        color: const Color(0xFF7B2FFF).withValues(alpha: 0.4),
                        blurRadius: 16,
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
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            isLast ? s.onbAllow : s.onbNext,
                            style: TextStyle(
                              color: context.tText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // "Later" on the permission page
            if (isLast)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text(s.onbLater,
                      style: TextStyle(
                          color: context.tText2(0.5))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isPermission;
  const _OnbPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.isPermission = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 62),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tText2(0.62),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (isPermission) ...[
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PermChip(icon: Icons.location_on_outlined, label: 'Location'),
                const SizedBox(width: 10),
                _PermChip(icon: Icons.bluetooth, label: 'Bluetooth'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PermChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.tText2(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tText2(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: context.tText, fontSize: 12)),
        ],
      ),
    );
  }
}
