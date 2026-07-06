// ─────────────────────────────────────────────────────────────────────────────
// Supabase configuration.
//
// Provide real values at build time WITHOUT committing secrets:
//   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=eyJ...
//
// The anon key is safe to ship (it only grants what Row-Level-Security allows).
// ─────────────────────────────────────────────────────────────────────────────
class SupabaseConfig {
  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True once real credentials are supplied. When false the app runs fully
  /// on local/mock data and never touches the network.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
