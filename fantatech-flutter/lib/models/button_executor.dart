import '../services/device_platform/device_adapter.dart';
import 'app_state.dart';
import 'button_spec.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ButtonExecutor — the missing link between a declarative ButtonSpec and the
// app's existing, already-brand-agnostic control layer (AppState →
// DeviceCommander → gateway). It never talks to a manufacturer directly and
// never duplicates AppState's optimistic-update/revert-on-failure handling
// (see AppState.setDevicePower) — it only decides WHICH AppState method a
// spec's action maps to, and (for onOff) what the resulting explicit state
// should be for ON / OFF / TOGGLE.
//
// Usage from any screen:
//   final ok = await ButtonExecutor.execute(spec, state, explicitState: 'on');
//   // omit explicitState for TOGGLE — flips spec.currentState
// ─────────────────────────────────────────────────────────────────────────────

abstract class ButtonExecutor {
  ButtonExecutor._();

  /// Pure — no AppState involved, safe to unit test directly. Resolves what
  /// the ON / OFF / TOGGLE button press should set an onOff-capability
  /// device to: [explicitState] 'on'/'off' for the ON/OFF buttons, or null
  /// for TOGGLE (flips [spec.currentState]).
  static bool resolveOnOffTarget(ButtonSpec spec, {String? explicitState}) {
    if (explicitState == 'on') return true;
    if (explicitState == 'off') return false;
    return spec.currentState != 'on'; // TOGGLE
  }

  /// Executes [spec]'s action against the real device through AppState.
  /// Returns true only once the gateway layer actually confirmed the
  /// change — AppState's underlying methods already revert their optimistic
  /// UI update on failure, so a caller never needs to do that itself.
  static Future<bool> execute(
    ButtonSpec spec,
    AppState state, {
    String? explicitState,
  }) {
    switch (spec.action) {
      case DeviceCommandAction.onOff:
        final target = resolveOnOffTarget(spec, explicitState: explicitState);
        return state.setDevicePower(spec.deviceId, target);

      case DeviceCommandAction.brightness:
        final pct = int.tryParse(explicitState ?? '') ?? 0;
        return state.agentSetBrightness(spec.deviceId, pct.clamp(0, 100));

      case DeviceCommandAction.coverPosition:
        final pos = int.tryParse(explicitState ?? '') ?? 0;
        return state.agentSetCoverPosition(spec.deviceId, pos.clamp(0, 100));

      case DeviceCommandAction.climate:
        return state.agentSetClimate(spec.deviceId, hvacMode: explicitState);

      case DeviceCommandAction.lock:
      case DeviceCommandAction.stopCover:
      case DeviceCommandAction.vacuum:
        // No AppState method for these yet — surface the gap instead of
        // inventing one (per project rule: don't fabricate an API).
        throw UnimplementedError(
            'ButtonExecutor: no AppState method wired for ${spec.action} yet');
    }
  }
}
