import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

import 'app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AlarmButtonSpec — the security-system counterpart to ButtonSpec/
// SensorStateSpec. Deliberately NOT built on Device/DeviceCapability: alarm
// arm/disarm is whole-home state (AppState.securityMode), not something
// scoped to one Device's attributes, so forcing it through
// ButtonSpec.forCapability would be the wrong fit rather than reuse.
//
// States: armed/disarmed/home/away/night/triggered — all already representable
// by the existing SecurityMode enum (armedNight/triggered added alongside
// this file; every other existing SecurityMode usage in the app is
// untouched). 'triggered' is a STATE an alarm can be found in (a sensor
// tripped while armed) — it is not one of the user-initiated actions below;
// nothing in this file ever targets it.
//
// Actions: arm / disarm / home / away — each maps to setSecurityMode(),
// which already accepts any SecurityMode directly (no new AppState method
// needed). [requiresConfirmation] is exposed so a screen can gate the
// disarm action behind a confirmation dialog before calling
// [AlarmButtonExecutor.execute] — this file never shows UI itself.
// ─────────────────────────────────────────────────────────────────────────────

enum AlarmAction { arm, disarm, home, away, night }

class AlarmButtonSpec {
  final AlarmAction action;
  final SecurityMode targetMode;
  final SecurityMode currentMode;
  final bool requiresConfirmation;
  final IconData icon;
  final String displayName;

  const AlarmButtonSpec({
    required this.action,
    required this.targetMode,
    required this.currentMode,
    required this.requiresConfirmation,
    required this.icon,
    required this.displayName,
  });

  factory AlarmButtonSpec.forAction(AlarmAction action, SecurityMode currentMode) {
    final (SecurityMode target, IconData icon, String name) = switch (action) {
      AlarmAction.arm     => (SecurityMode.armedAway, Symbols.lock, 'Arm'),
      AlarmAction.disarm  => (SecurityMode.disarmed, Symbols.lock_open, 'Disarm'),
      AlarmAction.home    => (SecurityMode.armedHome, Symbols.home, 'Home'),
      AlarmAction.away    => (SecurityMode.armedAway, Symbols.directions_walk, 'Away'),
      AlarmAction.night   => (SecurityMode.armedNight, Symbols.bedtime, 'Night'),
    };

    return AlarmButtonSpec(
      action: action,
      targetMode: target,
      currentMode: currentMode,
      // Per project requirement: confirm before a sensitive action —
      // disarming is the one action here that actually reduces security.
      requiresConfirmation: action == AlarmAction.disarm,
      icon: icon,
      displayName: name,
    );
  }
}

abstract class AlarmButtonExecutor {
  AlarmButtonExecutor._();

  /// Applies [spec.targetMode]. Callers MUST have already obtained user
  /// confirmation when [spec.requiresConfirmation] is true — this method
  /// does not prompt, it only ever applies the change once told to.
  ///
  /// Routes through AppState.armDisarmSecurity, which sends a real command
  /// to a connected alarm-panel gateway (Ajax/Risco/PIMA) when one exists,
  /// and reverts the optimistic state change if that command fails — see
  /// its own doc comment. Returns whether the change actually took effect.
  static Future<bool> execute(AlarmButtonSpec spec, AppState state) {
    return state.armDisarmSecurity(spec.targetMode);
  }
}
