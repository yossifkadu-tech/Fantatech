// ─────────────────────────────────────────────────────────────────────────────
// BiometricService — fingerprint / face unlock.
//
// Stores a per-device "enabled" flag in SharedPreferences. The biometric
// template itself never leaves the OS — local_auth only returns true/false.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const _enabledKey = 'biometric_enabled';
  static const _askedKey = 'biometric_asked';

  /// In-memory only — true once the user has passed a biometric check
  /// during this app process. Android frequently recreates the Activity
  /// (and re-runs AuthGate.initState) on a plain background/foreground
  /// cycle without a real cold start; without this flag that recreation
  /// re-prompts for a fingerprint the user already gave a moment earlier.
  /// Intentionally not persisted — a genuine cold start / process kill
  /// still asks again, which is the correct security behavior.
  static bool unlockedThisSession = false;

  /// True if the device supports biometric or PIN authentication.
  static Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompt the OS biometric sheet. Returns true on success.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Persisted preferences ────────────────────────────────────
  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, value);
  }

  /// Whether we already asked the user (so we ask only once).
  static Future<bool> wasAsked() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_askedKey) ?? false;
  }

  static Future<void> markAsked() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_askedKey, true);
  }
}
