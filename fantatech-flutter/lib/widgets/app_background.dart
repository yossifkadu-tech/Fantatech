import 'package:flutter/material.dart';

/// Shared full-screen background used across all auth screens.
/// Renders the smart-home illustration at the top with a blue gradient overlay.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Illustration — pinned to top at natural height
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/main.jpg',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        // Gradient overlay — matches illustration blue (#1D75BD)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x331D75BD), // 20% — illustration visible at top
                Color(0xCC1D75BD), // 80% — rich blue mid
                Color(0xFF1D75BD), // 100% — solid blue at bottom
              ],
              stops: [0.0, 0.35, 1.0],
            ),
          ),
        ),
        // Screen content
        child,
      ],
    );
  }
}
