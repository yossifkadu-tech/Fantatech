// ─── Enums ────────────────────────────────────────────────────────────────────

enum DashboardItemSize { sm, md, lg }

// ─── LayoutItem ───────────────────────────────────────────────────────────────

/// Represents a single widget/section in a dashboard layout.
class LayoutItem {
  final String id;            // Unique stable identifier for this slot
  final String type;          // Widget type key (e.g. 'weather', 'rooms', ...)
  final Map<String, dynamic> config; // Type-specific data (entityId, etc.)
  final int order;            // Sort position (lower = higher on screen)
  final DashboardItemSize size;
  final bool visible;
  final bool pinned;          // Pinned items always sort to top
  final int page;             // Which swipeable dashboard page this belongs to

  const LayoutItem({
    required this.id,
    required this.type,
    this.config = const {},
    this.order = 0,
    this.size = DashboardItemSize.md,
    this.visible = true,
    this.pinned = false,
    this.page = 0,
  });

  LayoutItem copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? config,
    int? order,
    DashboardItemSize? size,
    bool? visible,
    bool? pinned,
    int? page,
  }) =>
      LayoutItem(
        id: id ?? this.id,
        type: type ?? this.type,
        config: config ?? this.config,
        order: order ?? this.order,
        size: size ?? this.size,
        visible: visible ?? this.visible,
        pinned: pinned ?? this.pinned,
        page: page ?? this.page,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'config': config,
        'order': order,
        'size': size.name,
        'visible': visible,
        'pinned': pinned,
        'page': page,
      };

  factory LayoutItem.fromJson(Map<String, dynamic> j) => LayoutItem(
        id: j['id'] as String,
        type: j['type'] as String,
        config: Map<String, dynamic>.from(j['config'] as Map? ?? {}),
        order: j['order'] as int? ?? 0,
        size: DashboardItemSize.values.firstWhere(
          (e) => e.name == j['size'],
          orElse: () => DashboardItemSize.md,
        ),
        visible: j['visible'] as bool? ?? true,
        pinned: j['pinned'] as bool? ?? false,
        page: j['page'] as int? ?? 0,
      );

  @override
  String toString() => 'LayoutItem($id, type=$type, order=$order)';
}

// ─── DashboardLayout ─────────────────────────────────────────────────────────

class DashboardLayout {
  final String id;
  final List<LayoutItem> items;
  final int version;

  const DashboardLayout({
    required this.id,
    required this.items,
    this.version = 1,
  });

  DashboardLayout copyWith({
    String? id,
    List<LayoutItem>? items,
    int? version,
  }) =>
      DashboardLayout(
        id: id ?? this.id,
        items: items ?? this.items,
        version: version ?? this.version,
      );

  /// Returns items sorted by pin status then order.
  /// Pass [allItems: true] to include hidden items (used in edit mode).
  List<LayoutItem> sorted({bool allItems = false}) {
    final source = allItems
        ? List<LayoutItem>.from(items)
        : items.where((i) => i.visible).toList();
    source.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return a.order.compareTo(b.order);
    });
    return source;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'version': version,
      };

  factory DashboardLayout.fromJson(Map<String, dynamic> j) => DashboardLayout(
        id: j['id'] as String,
        version: j['version'] as int? ?? 1,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => LayoutItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Well-known dashboard IDs ────────────────────────────────────────────────

abstract class DashboardId {
  static const home           = 'home';
  static const smarthome      = 'smarthome';
  static const smarthomeCats  = 'smarthome_cats';
  static const cameras        = 'cameras';
  static const security       = 'security';
  static const automations    = 'automations';
}
