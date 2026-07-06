// Salted SHA-256 hashing for the local (non-cloud) email/password fallback.
//
// Cloud accounts never touch this — Supabase handles their password storage
// server-side. This only covers the on-device CSV fallback used when no
// backend is configured, which previously stored passwords in plain text.
//
// Stored format: "<saltHex(32 chars)>:<sha256Hex(64 chars)>"
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  /// Hashes [password] with a new random salt, or with [existingSalt] when
  /// re-verifying (or re-hashing) an existing password.
  static String hash(String password, [String? existingSalt]) {
    final salt = existingSalt ?? _generateSalt();
    final digest = sha256.convert(utf8.encode('$salt$password'));
    return '$salt:${digest.toString()}';
  }

  /// True if [password] matches the previously-hashed [stored] value.
  static bool verify(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    return hash(password, parts[0]) == stored;
  }

  /// True if [stored] is already in our "salt:hash" form, false if it's a
  /// legacy plaintext password that still needs migrating.
  static bool isHashed(String stored) {
    final parts = stored.split(':');
    return parts.length == 2 && parts[0].length == 32 && parts[1].length == 64;
  }

  static String _generateSalt([int bytes = 16]) {
    final rand = Random.secure();
    return List<int>.generate(bytes, (_) => rand.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
