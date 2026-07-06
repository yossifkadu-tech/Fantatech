import '../backend/backend_service.dart';
import '../models/layout_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LayoutSyncService — persists dashboard layouts to Supabase.
//
// Requires a 'user_layouts' table:
//   CREATE TABLE user_layouts (
//     user_id   text PRIMARY KEY,
//     payload   jsonb NOT NULL DEFAULT '{}',
//     updated_at timestamptz NOT NULL DEFAULT now()
//   );
//
// Both push() and pull() silently fail when Supabase is not configured,
// so local-only usage works without any backend setup.
// ─────────────────────────────────────────────────────────────────────────────

class LayoutSyncService {
  static const _table = 'user_layouts';

  /// Upserts all layouts to the cloud for [userId].
  static Future<void> push(
    String userId,
    Map<String, DashboardLayout> layouts,
  ) async {
    if (!BackendService.isReady) return;
    try {
      await BackendService.client.from(_table).upsert({
        'user_id':    userId,
        'payload':    layouts.map((k, v) => MapEntry(k, v.toJson())),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-fatal — local layout remains intact
    }
  }

  /// Pulls layouts from the cloud for [userId]. Returns null if not found.
  static Future<Map<String, DashboardLayout>?> pull(String userId) async {
    if (!BackendService.isReady) return null;
    try {
      final rows = await BackendService.client
          .from(_table)
          .select('payload')
          .eq('user_id', userId)
          .limit(1);
      if (rows.isEmpty) return null;
      final payload = rows.first['payload'] as Map<String, dynamic>?;
      if (payload == null) return null;
      return payload.map(
        (k, v) => MapEntry(k, DashboardLayout.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return null;
    }
  }
}
