// ─────────────────────────────────────────────────────────────────────────────
// BackendService — single entry point for the Supabase client.
//
// Call `await BackendService.init()` early in main(). It is a no-op when no
// credentials are configured, so the app keeps working offline/mock.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class BackendService {
  static bool _ready = false;

  /// True once Supabase is initialized and usable.
  static bool get isReady => _ready && SupabaseConfig.isConfigured;

  /// Initialize Supabase. Safe to call when unconfigured (does nothing).
  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _ready = true;
  }

  /// The shared Supabase client. Throws if accessed before a configured init.
  static SupabaseClient get client {
    if (!isReady) {
      throw StateError(
          'Supabase is not configured. Pass --dart-define=SUPABASE_URL/'
          'SUPABASE_ANON_KEY and call BackendService.init().');
    }
    return Supabase.instance.client;
  }
}
