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

  /// True if the device has biometric hardware the app can use.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
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
