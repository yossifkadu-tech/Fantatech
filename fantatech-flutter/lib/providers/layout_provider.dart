import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/layout_item.dart';
import '../services/layout_sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LayoutProvider — manages per-dashboard layouts and edit mode state.
//
// Usage:
//   final lp = context.read<LayoutProvider>();
//
//   // Enter / exit edit mode
//   lp.toggleEditMode();
//
//   // Get sorted visible items for a dashboard
//   final items = lp.getItems('home');
//
//   // Reorder after a ReorderableListView callback
//   lp.reorder('home', oldIndex, newIndex);
// ─────────────────────────────────────────────────────────────────────────────

class LayoutProvider extends ChangeNotifier {
  static const _prefsKey = 'ft_layouts_v2';

  // ── State ──────────────────────────────────────────────────────────────────

  bool _editMode = false;
  bool _loaded   = false;
  final Map<String, DashboardLayout> _layouts = {};

  bool get editMode => _editMode;
  bool get loaded   => _loaded;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once from main() before runApp.
  Future<void> init() => _loadLocal();

  // ── Edit mode ──────────────────────────────────────────────────────────────

  void toggleEditMode() {
    _editMode = !_editMode;
    notifyListeners();
    if (!_editMode) _autoSave();
  }

  void exitEditMode() {
    if (!_editMode) return;
    _editMode = false;
    notifyListeners();
    _autoSave();
  }

  // ── Layout access ──────────────────────────────────────────────────────────

  DashboardLayout? getLayout(String dashboardId) => _layouts[dashboardId];

  /// Returns items for [dashboardId] sorted by pinned/order.
  /// In edit mode you usually want [allItems: true] to include hidden items.
  List<LayoutItem> getItems(String dashboardId, {bool allItems = false}) =>
      _layouts[dashboardId]?.sorted(allItems: allItems) ?? [];

  /// Ensures the dashboard exists, seeding it from [defaultItems] if not yet
  /// persisted. Safe to call inside build() — does NOT notify when already set.
  void ensureLayout(String dashboardId, List<LayoutItem> defaultItems) {
    if (_layouts.containsKey(dashboardId)) return;
    _layouts[dashboardId] =
        DashboardLayout(id: dashboardId, items: defaultItems);
    // No notifyListeners — called from build, would cause infinite rebuild
  }

  // ── Reorder ────────────────────────────────────────────────────────────────

  /// Called from ReorderableListView.onReorder.
  /// Flutter already adjusts newIndex for the removal, so we just clamp.
  void reorder(String dashboardId, int oldIndex, int newIndex) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;

    final items = layout.sorted(allItems: true);
    if (oldIndex < 0 || oldIndex >= items.length) return;

    // ReorderableListView's newIndex is post-removal, re-adjust:
    final ni = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = items.removeAt(oldIndex);
    items.insert(ni.clamp(0, items.length), item);

    _setItems(dashboardId, _reassignOrder(items));
  }

  // ── Item operations ────────────────────────────────────────────────────────

  void resize(String dashboardId, String itemId, DashboardItemSize size) =>
      _patch(dashboardId, itemId, (i) => i.copyWith(size: size));

  /// Custom user-facing label. Pass null/empty to clear the override and
  /// fall back to the resolver's default name.
  void renameItem(String dashboardId, String itemId, String? label) =>
      _patch(dashboardId, itemId, (i) {
        final cfg = Map<String, dynamic>.from(i.config);
        if (label == null || label.trim().isEmpty) {
          cfg.remove('label');
        } else {
          cfg['label'] = label.trim();
        }
        return i.copyWith(config: cfg);
      });

  void setItemPage(String dashboardId, String itemId, int page) =>
      _patch(dashboardId, itemId, (i) => i.copyWith(page: page));

  void toggleVisibility(String dashboardId, String itemId) {
    final item = _find(dashboardId, itemId);
    if (item == null) return;
    _patch(dashboardId, itemId, (i) => i.copyWith(visible: !i.visible));
  }

  void togglePin(String dashboardId, String itemId) {
    final item = _find(dashboardId, itemId);
    if (item == null) return;
    _patch(dashboardId, itemId, (i) => i.copyWith(pinned: !i.pinned));
  }

  void duplicate(String dashboardId, String itemId) {
    final layout   = _layouts[dashboardId];
    final original = _find(dashboardId, itemId);
    if (layout == null || original == null) return;
    final copy = original.copyWith(
      id:     '${itemId}_${DateTime.now().millisecondsSinceEpoch}',
      order:  original.order + 1,
      pinned: false,
    );
    _setItems(dashboardId, [...layout.items, copy]);
  }

  void deleteItem(String dashboardId, String itemId) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;
    _setItems(
      dashboardId,
      layout.items.where((i) => i.id != itemId).toList(),
    );
  }

  /// Moves an item one slot up/down within the full (visible + hidden) order.
  /// Used by the per-card "⋮" menu so reordering works without a global
  /// drag-based edit mode.
  void moveItem(String dashboardId, String itemId, {required bool up}) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;
    final items = layout.sorted(allItems: true);
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    final targetIdx = up ? idx - 1 : idx + 1;
    if (targetIdx < 0 || targetIdx >= items.length) return;
    final item = items.removeAt(idx);
    items.insert(targetIdx, item);
    _setItems(dashboardId, _reassignOrder(items));
  }

  /// Adds any [defaultItems] whose id isn't already present in the persisted
  /// layout. Needed because [ensureLayout] only seeds a brand-new dashboard —
  /// it won't retroactively add a section introduced in a later app update
  /// to a layout a user already has saved.
  void syncNewItems(String dashboardId, List<LayoutItem> defaultItems) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;
    final existingIds = layout.items.map((i) => i.id).toSet();
    final missing = defaultItems.where((d) => !existingIds.contains(d.id));
    if (missing.isEmpty) return;
    _setItems(dashboardId, [...layout.items, ...missing]);
  }

  /// Removes items of an obsolete type left over from a previous version's
  /// persisted layout (e.g. a section that was since retired).
  void pruneObsoleteTypes(String dashboardId, Set<String> obsoleteTypes) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;
    final kept = layout.items.where((i) => !obsoleteTypes.contains(i.type)).toList();
    if (kept.length == layout.items.length) return; // nothing to prune
    _setItems(dashboardId, kept);
  }

  /// One-time default page assignment: only applies if the user has never
  /// customized paging yet (heuristic: every item still sits on page 0).
  /// Types in [page0Types] go to page 0; everything else (including future,
  /// unrecognized types) goes to page 1.
  void applyDefaultPagesIfUnset(String dashboardId, Set<String> page0Types) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;
    if (layout.items.any((i) => i.page != 0)) return; // already customized
    final updated = layout.items
        .map((i) => i.copyWith(page: page0Types.contains(i.type) ? 0 : 1))
        .toList();
    _setItems(dashboardId, updated);
  }

  /// Sets an explicit order value for a single item by id. Used for
  /// one-time migrations that fix ordering on a layout a user already has
  /// persisted (new defaults only apply to brand-new layouts).
  void setItemOrder(String dashboardId, String itemId, int order) =>
      _patch(dashboardId, itemId, (i) => i.copyWith(order: order));

  void restoreDefaults(String dashboardId, List<LayoutItem> defaults) {
    _layouts[dashboardId] = DashboardLayout(id: dashboardId, items: defaults);
    notifyListeners();
    _autoSave();
  }

  // ── Cloud sync ─────────────────────────────────────────────────────────────

  Future<void> syncCloud(String userId) =>
      LayoutSyncService.push(userId, _layouts);

  Future<void> loadCloud(String userId) async {
    final remote = await LayoutSyncService.pull(userId);
    if (remote == null) return;
    remote.forEach((id, layout) => _layouts[id] = layout);
    notifyListeners();
    await saveLocal();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data  = jsonEncode(_layouts.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_prefsKey, data);
    } catch (_) {}
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_prefsKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        data.forEach((k, v) {
          _layouts[k] = DashboardLayout.fromJson(v as Map<String, dynamic>);
        });
      }
    } catch (_) {
      // Corrupt data — start fresh with defaults
    }
    _loaded = true;
    notifyListeners();
  }

  LayoutItem? _find(String dashboardId, String itemId) =>
      _layouts[dashboardId]?.items
          .cast<LayoutItem?>()
          .firstWhere((i) => i?.id == itemId, orElse: () => null);

  void _patch(String dashboardId, String itemId,
      LayoutItem Function(LayoutItem) f) {
    final layout = _layouts[dashboardId];
    if (layout == null) return;
    _setItems(
      dashboardId,
      layout.items.map((i) => i.id == itemId ? f(i) : i).toList(),
    );
  }

  void _setItems(String dashboardId, List<LayoutItem> items) {
    _layouts[dashboardId] = DashboardLayout(id: dashboardId, items: items);
    notifyListeners();
  }

  static List<LayoutItem> _reassignOrder(List<LayoutItem> items) =>
      items.asMap().entries
          .map((e) => e.value.copyWith(order: e.key))
          .toList();

  void _autoSave() => saveLocal();
}
