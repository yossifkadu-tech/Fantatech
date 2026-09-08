import 'dart:async';

import '../models/app_state.dart';
import '../models/device.dart';
import '../models/device_capabilities.dart';

/// Executes the automations built in the Automations screen's "add" wizard.
///
/// Previously that wizard only wrote a human-readable label into
/// [Automation.condition]/[Automation.action] — nothing ever evaluated it.
/// This reads the structured trigger/action fields ([Automation.triggerType]
/// etc., added alongside this engine) and actually runs them:
///
///  - 'time' triggers: checked once a minute against the clock.
///  - 'device'/'sensor' triggers: checked on every AppState change, firing
///    once on the rising edge (off→on / not-detected→detected), not on
///    every tick while the condition stays true.
///  - 'arrival' triggers: NOT implemented — the app has no location/geofence
///    plumbing. An automation left on this trigger type simply never fires;
///    it's still selectable in the wizard for a future phase.
class AutomationEngine {
  static final AutomationEngine instance = AutomationEngine._();
  AutomationEngine._();

  AppState? _appState;
  Timer? _timer;
  bool _listening = false;

  // Rising-edge tracking for device/sensor triggers, keyed by automation id.
  final Map<String, bool> _lastTriggerState = {};
  // De-dupes a time trigger firing more than once inside the same minute.
  final Map<String, String> _lastFiredMinuteKey = {};

  /// Attach to AppState and start evaluating automations. Safe to call more
  /// than once (e.g. from several screens) — the timer/listener are only
  /// created the first time.
  void attach(AppState appState) {
    _appState = appState;
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => _checkTimeTriggers());
    if (!_listening) {
      _listening = true;
      appState.addListener(_checkEventTriggers);
    }
  }

  void _checkTimeTriggers() {
    final state = _appState;
    if (state == null) return;
    final now = DateTime.now();
    final minuteKey = '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';

    for (final a in state.automations) {
      if (!a.isEnabled || a.triggerType != 'time') continue;
      if (a.triggerHour != now.hour || a.triggerMinute != now.minute) continue;
      if (_lastFiredMinuteKey[a.id] == minuteKey) continue;
      _lastFiredMinuteKey[a.id] = minuteKey;
      _executeAction(state, a);
    }
  }

  void _checkEventTriggers() {
    final state = _appState;
    if (state == null) return;

    for (final a in state.automations) {
      if (!a.isEnabled) continue;
      if (a.triggerType != 'device' && a.triggerType != 'sensor') continue;
      final deviceId = a.triggerDeviceId;
      if (deviceId == null) continue;

      Device? device;
      for (final d in state.devices) {
        if (d.id == deviceId) {
          device = d;
          break;
        }
      }
      if (device == null) continue;

      final bool current;
      if (a.triggerType == 'sensor') {
        final key = DeviceCapabilities.binaryStateKey(device.type);
        current = key != null && device.attributes[key] == true;
      } else {
        current = device.isOn;
      }

      final last = _lastTriggerState[a.id];
      _lastTriggerState[a.id] = current;
      if (current && last != true) {
        _executeAction(state, a);
      }
    }
  }

  void _executeAction(AppState state, Automation a) {
    switch (a.actionType) {
      case 'turnOn':
        _applyOnOff(state, a.actionDeviceId, true, onlyLights: a.actionDeviceId == null);
        break;
      case 'turnOff':
        _applyOnOff(state, a.actionDeviceId, false, onlyLights: a.actionDeviceId == null);
        break;
      case 'allLightsOff':
        _applyOnOff(state, null, false, onlyLights: true, includeAc: true);
        break;
      case 'lock':
        _applyLock(state, true);
        break;
      case 'unlock':
        _applyLock(state, false);
        break;
      case 'openBlind':
        _applyCover(state, 100);
        break;
      case 'closeBlind':
        _applyCover(state, 0);
        break;
    }
  }

  void _applyOnOff(AppState state, String? deviceId, bool on,
      {bool onlyLights = false, bool includeAc = false}) {
    if (deviceId != null) {
      state.setDevicePower(deviceId, on);
      return;
    }
    // Always issue the command — don't gate on the device's cached isOn
    // flag, which can lag behind an HA-synced device's real state.
    for (final d in state.devices) {
      final isTarget = onlyLights
          ? (d.type == DeviceType.light ||
              (includeAc && d.type == DeviceType.airConditioner))
          : DeviceCapabilities.of(d).contains(DeviceCapability.onOff);
      if (isTarget) {
        state.setDevicePower(d.id, on);
      }
    }
  }

  void _applyLock(AppState state, bool locked) {
    for (final d in state.devices) {
      if (DeviceCapabilities.of(d).contains(DeviceCapability.lockControl)) {
        state.setDevicePower(d.id, locked);
      }
    }
  }

  void _applyCover(AppState state, int position) {
    for (final d in state.devices) {
      if (DeviceCapabilities.of(d).contains(DeviceCapability.position)) {
        state.setCoverPosition(d.id, position);
      }
    }
  }
}
