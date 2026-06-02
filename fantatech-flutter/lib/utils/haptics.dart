// ─────────────────────────────────────────────────────────────────────────────
// Haptics — thin wrapper around HapticFeedback for consistent tactile feel.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/services.dart';

class Haptics {
  /// Light tap — for toggles, selections, scene buttons.
  static void light() => HapticFeedback.lightImpact();

  /// Medium — for confirmations / primary actions.
  static void medium() => HapticFeedback.mediumImpact();

  /// Selection click — for sliders / segmented controls.
  static void select() => HapticFeedback.selectionClick();
}
