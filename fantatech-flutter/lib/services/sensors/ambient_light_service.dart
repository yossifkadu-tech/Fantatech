// ─────────────────────────────────────────────────────────────────────────────
// AmbientLightService
//
// Reads the device's ambient-light sensor (Android TYPE_LIGHT) and maps lux
// levels to a theme mode. iOS has no public light-sensor API so the service
// simply returns false on that platform.
//
// Lux guide (approximate):
//   < 20  lux  → very dark room / night      → dark theme
//   < 120 lux  → dim / evening / indoors     → dark theme
//   ≥ 180 lux  → normal office / outdoor     → light theme
//
// A new mode is only applied after it is stable for 3 consecutive readings
// (~3 s at uiInterval) — this stops theme-flickering when walking between rooms.
// Hysteresis: the dark→light boundary (180 lux) is higher than the light→dark
// boundary (120 lux) to prevent oscillation near a single threshold.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:light/light.dart';

/// Below this lux value we switch to dark theme.
const double _kDarkThreshold  = 120.0;

/// Above this lux value we switch to light theme (hysteresis gap).
const double _kLightThreshold = 180.0;

/// Number of stable consecutive readings before applying a mode switch.
const int _kStableCount = 3;

class AmbientLightService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// True once [start] has been called and the sensor subscription is active.
  bool get isRunning => _sub != null;

  /// Last raw lux reading (null before the first event).
  double? get currentLux => _lastLux;

  /// Current inferred [ThemeMode] (null until first reading).
  ThemeMode? get currentMode => _currentMode;

  // ── Private state ──────────────────────────────────────────────────────────

  StreamSubscription<int>? _sub;
  void Function(ThemeMode mode, double lux)? _onChanged;

  double?    _lastLux;
  ThemeMode? _currentMode;
  ThemeMode? _pendingMode;   // candidate mode awaiting stability
  int        _stableCount = 0;

  // ── API ────────────────────────────────────────────────────────────────────

  /// Start listening to the ambient-light sensor.
  /// [onChanged] fires whenever the recommended [ThemeMode] changes.
  /// Returns `false` if the platform or sensor is not supported.
  Future<bool> start({
    required void Function(ThemeMode mode, double lux) onChanged,
  }) async {
    if (_sub != null) return true; // already running

    // The `light` package only supports Android.
    if (!Platform.isAndroid) return false;

    _onChanged = onChanged;

    try {
      _sub = Light().lightSensorStream.listen(
        (luxInt) => _onReading(luxInt.toDouble()),
        onError: (_) => stop(),
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop the sensor subscription.
  void stop() {
    _sub?.cancel();
    _sub         = null;
    _pendingMode = null;
    _stableCount = 0;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _onReading(double lux) {
    _lastLux = lux;

    // Hysteresis: thresholds differ depending on current mode.
    final ThemeMode desired;
    if (_currentMode == ThemeMode.light) {
      // Currently light → only switch to dark if lux drops below lower bound.
      desired = lux < _kDarkThreshold ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Currently dark (or unknown) → only switch to light above upper bound.
      desired = lux >= _kLightThreshold ? ThemeMode.light : ThemeMode.dark;
    }

    // Debounce: require _kStableCount stable readings before committing.
    if (desired == _pendingMode) {
      _stableCount++;
      if (_stableCount >= _kStableCount && desired != _currentMode) {
        _currentMode = desired;
        _pendingMode = null;
        _stableCount = 0;
        _onChanged?.call(desired, lux);
      }
    } else {
      _pendingMode = desired;
      _stableCount = 1;
    }
  }
}
