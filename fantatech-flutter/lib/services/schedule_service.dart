import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';

// ─────────────────────────────────────────────────────────────
// On/off schedule for any device (plug, switch, ...). Originally lived
// only in the Plugs hub screen — extracted here so any onOff-capable
// device can be scheduled the same way (e.g. from the shared device
// edit sheet).
// ─────────────────────────────────────────────────────────────

class DeviceSchedule {
  final TimeOfDay? onTime;
  final TimeOfDay? offTime;
  final Set<int> days; // 1=Mon..7=Sun; empty = every day

  const DeviceSchedule({this.onTime, this.offTime, this.days = const {}});

  bool get hasAny => onTime != null || offTime != null;

  Map<String, dynamic> toJson() => {
        if (onTime != null) 'onH': onTime!.hour,
        if (onTime != null) 'onM': onTime!.minute,
        if (offTime != null) 'offH': offTime!.hour,
        if (offTime != null) 'offM': offTime!.minute,
        'days': days.toList(),
      };

  factory DeviceSchedule.fromJson(Map<String, dynamic> json) =>
      DeviceSchedule(
        onTime: json.containsKey('onH')
            ? TimeOfDay(hour: json['onH'] as int, minute: json['onM'] as int)
            : null,
        offTime: json.containsKey('offH')
            ? TimeOfDay(hour: json['offH'] as int, minute: json['offM'] as int)
            : null,
        days: Set<int>.from(
            (json['days'] as List?)?.cast<int>() ?? const <int>[]),
      );
}

// ─────────────────────────────────────────────────────────────
// Schedule service — singleton; persists to SharedPreferences and
// executes schedules every minute while the app is in the foreground.
// Keyed by device id, so it applies to whatever device the schedule was
// saved against — plug, switch, or anything else with onOff capability.
// ─────────────────────────────────────────────────────────────

class ScheduleService extends ChangeNotifier {
  static final ScheduleService instance = ScheduleService._();
  ScheduleService._();

  // Key intentionally unchanged from the plug-only version of this
  // service, so any schedule a user already saved for a plug survives
  // this generalization to other device types.
  static const _prefKey = 'plug_schedules_v1';

  final Map<String, DeviceSchedule> _schedules = {};
  Timer? _timer;
  AppState? _appState;

  DeviceSchedule? scheduleFor(String deviceId) => _schedules[deviceId];

  /// Attach to AppState and start periodic execution. Safe to call more
  /// than once (e.g. from several hub screens) — the timer is only
  /// created the first time.
  void attach(AppState appState) {
    _appState = appState;
    _timer ??= Timer.periodic(const Duration(minutes: 1), _tick);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _schedules.clear();
      for (final e in map.entries) {
        _schedules[e.key] =
            DeviceSchedule.fromJson(e.value as Map<String, dynamic>);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveSchedule(String deviceId, DeviceSchedule schedule) async {
    if (schedule.hasAny) {
      _schedules[deviceId] = schedule;
    } else {
      _schedules.remove(deviceId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey,
        jsonEncode({
          for (final e in _schedules.entries) e.key: e.value.toJson(),
        }));
  }

  Future<void> clearSchedule(String deviceId) async {
    _schedules.remove(deviceId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey,
        jsonEncode({
          for (final e in _schedules.entries) e.key: e.value.toJson(),
        }));
  }

  void _tick(Timer _) {
    final state = _appState;
    if (state == null || _schedules.isEmpty) return;
    final now = DateTime.now();

    for (final entry in _schedules.entries) {
      final sched = entry.value;
      if (!sched.hasAny) continue;
      if (sched.days.isNotEmpty && !sched.days.contains(now.weekday)) continue;

      final hasDevice = state.devices.any((d) => d.id == entry.key);
      if (!hasDevice) continue;

      // Always issue the command for the matching minute — don't gate on
      // the device's cached isOn flag. That cache can lag behind an
      // HA-synced device's real state, which silently made the scheduler
      // look like it "did nothing" at the scheduled time even though the
      // timer fired correctly.
      if (sched.onTime != null &&
          now.hour == sched.onTime!.hour &&
          now.minute == sched.onTime!.minute) {
        state.setDevicePower(entry.key, true);
      }
      if (sched.offTime != null &&
          now.hour == sched.offTime!.hour &&
          now.minute == sched.offTime!.minute) {
        state.setDevicePower(entry.key, false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
