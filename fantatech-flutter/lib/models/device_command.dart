import 'app_state.dart';
import 'device.dart';

// ─────────────────────────────────────────────────────────────────────────────
// sendDeviceCommand — the ONE entry point every button should call, per the
// requested shape sendDeviceCommand(deviceId, capability, action, value).
// Replaces "every button sends a command differently" with a single
// dispatcher — internally it still calls the exact same AppState methods
// (setDevicePower / agentSetBrightness / agentSetCoverPosition /
// agentSetClimate) that ButtonExecutor and the rest of the app already use,
// so nothing about the real command path changes; this only unifies the
// entry point new callers (an AI tool, a future generic button widget) use.
//
// Offline contract (per project requirement):
//   - A single attempt only. This function NEVER loops or auto-retries —
//     "Retry" is a user action: a screen calls sendDeviceCommand() again on
//     a button tap, this function itself holds no retry state at all.
//   - If the device is offline, no network/gateway call is attempted —
//     returns CommandOutcome.offline immediately. The UI is expected to
//     show "Offline" from DeviceState.online, not from this result alone.
//   - Never claims success without AppState's own confirmed result — those
//     methods already revert their optimistic UI update on failure, so a
//     failed command never leaves the app showing a state that didn't
//     actually happen.
// ─────────────────────────────────────────────────────────────────────────────

enum CommandOutcome { success, offline, failed }

class CommandResult {
  final CommandOutcome outcome;
  final String? message;

  const CommandResult(this.outcome, [this.message]);

  bool get success => outcome == CommandOutcome.success;
  bool get isOffline => outcome == CommandOutcome.offline;
}

/// Pure — no AppState involved. Returns the immediate offline result, or
/// null when the caller should proceed to actually send the command.
/// Pass [Device.status]'s `isControllable` (true unless DeviceStatus.
/// offline) here, not a strict online check — a device in a warning/alert/
/// alarm/info state is still reachable and shouldn't be blocked.
CommandResult? resolveOfflineGuard(bool deviceControllable) {
  if (!deviceControllable) {
    return const CommandResult(CommandOutcome.offline, 'Device is offline');
  }
  return null;
}

Future<CommandResult> sendDeviceCommand(
  String deviceId,
  String capability,
  String action,
  dynamic value,
  AppState state,
) async {
  Device? device;
  for (final d in state.devices) {
    if (d.id == deviceId) {
      device = d;
      break;
    }
  }
  if (device == null) {
    return const CommandResult(CommandOutcome.failed, 'Device not found');
  }

  // device.status.isControllable, not device.online — a device in a
  // warning/alert/alarm/info state is still reachable and controllable;
  // only DeviceStatus.offline itself should block a command (see
  // AppState's own command methods, which apply the same fix).
  final offlineResult = resolveOfflineGuard(device.status.isControllable);
  if (offlineResult != null) return offlineResult;

  try {
    final bool ok = switch ((capability, action)) {
      ('power', 'turn_on')   => await state.setDevicePower(deviceId, true),
      ('power', 'turn_off')  => await state.setDevicePower(deviceId, false),
      ('power', 'toggle')    => await state.setDevicePower(deviceId, !device.isOn),
      ('brightness', 'set')  => await state.agentSetBrightness(deviceId, (value as num).toInt()),
      ('position', 'set')    => await state.agentSetCoverPosition(deviceId, (value as num).toInt()),
      ('temperature', 'set') => await state.agentSetClimate(deviceId, temperature: (value as num).toDouble()),
      ('mode', 'set')        => await state.agentSetClimate(deviceId, hvacMode: value as String),
      _ => throw UnimplementedError(
          'sendDeviceCommand: no mapping for capability="$capability" '
          'action="$action" — add one instead of guessing at a call site'),
    };
    return ok
        ? const CommandResult(CommandOutcome.success)
        : const CommandResult(CommandOutcome.failed, 'Device did not confirm the command');
  } catch (e) {
    return CommandResult(CommandOutcome.failed, e.toString());
  }
}
