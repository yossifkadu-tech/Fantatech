// ─────────────────────────────────────────────────────────────────────────────
// PressScale — shared press-feedback wrapper.
//
// Starts scale-down on onTapDown (0 ms latency) and calls onTap after the
// brief spring-back animation.  Adds a light haptic on every press.
//
// Usage:
//   PressScale(
//     onTap: () { ... },
//     child: MyCard(),
//   )
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../utils/haptics.dart';

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale factor when pressed (default 0.955 — subtle but clearly felt)
  final double scale;

  /// Whether to fire a light haptic on press (default true)
  final bool haptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.955,
    this.haptic = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _anim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.haptic) Haptics.light();
    _ctrl.forward();
  }

  void _up() => _ctrl.reverse();

  void _tap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _down : null,
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.onTap != null ? _tap : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.scale(scale: _anim.value, child: child),
        child: widget.child,
      ),
    );
  }
}
