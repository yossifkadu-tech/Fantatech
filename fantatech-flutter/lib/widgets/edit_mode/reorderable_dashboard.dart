import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/layout_item.dart';
import '../../providers/layout_provider.dart';
import '../../theme/app_theme.dart';
import 'draggable_item.dart';
import 'edit_toolbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReorderableDashboard
//
// Drop-in replacement for a ListView / Column that adds Enterprise Edit Mode:
//
//   • Normal mode   — CustomScrollView showing items in layout order.
//   • Edit mode     — SliverReorderableList, each item wrapped in DraggableItem.
//                     Header / footer slivers are pinned and never draggable.
//   • EditToolbar   — slides in from the top when edit mode is active.
//   • EditModeButton — optionally shown inside this widget (showEditButton:true)
//                      or embedded by the caller in their AppBar.
//
// Minimal usage:
//
//   ReorderableDashboard(
//     dashboardId: DashboardId.home,
//     defaultItems: DashboardDefaults.home,
//     nameResolver: DashboardDefaults.nameOf,
//     iconResolver: DashboardDefaults.iconOf,
//     header: const _TopBar(),
//     footer: const _AdBanner(),
//     itemBuilder: (ctx, item) => switch (item.type) {
//       'weather'  => const _WeatherEnergyRow(),
//       'security' => const _SecurityBanner(),
//       _          => const SizedBox.shrink(),
//     },
//   )
// ─────────────────────────────────────────────────────────────────────────────

typedef DashboardItemBuilder = Widget Function(
  BuildContext context,
  LayoutItem item,
);

class ReorderableDashboard extends StatefulWidget {
  final String dashboardId;
  final List<LayoutItem> defaultItems;
  final DashboardItemBuilder itemBuilder;

  /// Human-readable name shown in the action sheet. Falls back to [item.type].
  final String Function(LayoutItem item)? nameResolver;

  /// Icon shown in the action sheet header.
  final IconData Function(LayoutItem item)? iconResolver;

  /// Pinned, non-draggable widget above the reorderable list.
  final Widget? header;

  /// Pinned, non-draggable widget below the reorderable list.
  final Widget? footer;

  /// Outer padding applied around the scroll view.
  final EdgeInsets padding;

  /// Set true to render the edit toggle button inside this widget (e.g. when
  /// the screen has no AppBar). When false, place [EditModeButton] in the
  /// screen's AppBar actions instead.
  final bool showEditButton;

  /// When set, only items whose [LayoutItem.page] matches this value are
  /// shown — used to split a dashboard across swipeable pages.
  final int? page;

  const ReorderableDashboard({
    super.key,
    required this.dashboardId,
    required this.defaultItems,
    required this.itemBuilder,
    this.nameResolver,
    this.iconResolver,
    this.header,
    this.footer,
    this.padding = const EdgeInsets.only(bottom: 40),
    this.showEditButton = false,
    this.page,
  });

  @override
  State<ReorderableDashboard> createState() => _ReorderableDashboardState();
}

class _ReorderableDashboardState extends State<ReorderableDashboard> {
  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<LayoutProvider>();
    final editMode  = provider.editModeFor(widget.dashboardId);

    // Seed defaults if this dashboard has not been persisted yet.
    // Safe to call from build — does NOT call notifyListeners when already set.
    provider.ensureLayout(widget.dashboardId, widget.defaultItems);

    var items = provider.getItems(
      widget.dashboardId,
      allItems: editMode, // show hidden items in edit mode
    );
    if (widget.page != null) {
      items = items.where((i) => i.page == widget.page).toList();
    }

    return Stack(
      children: [
        // ── Main scroll area ──────────────────────────────────────
        editMode
            ? _EditModeScroll(
                dashboardId:  widget.dashboardId,
                items:        items,
                provider:     provider,
                header:       widget.header,
                footer:       widget.footer,
                padding:      widget.padding,
                showEditBtn:  widget.showEditButton,
                nameResolver: widget.nameResolver,
                iconResolver: widget.iconResolver,
                itemBuilder:  widget.itemBuilder,
                proxyDecor:   _proxyDecorator,
              )
            : _NormalScroll(
                header:       widget.header,
                footer:       widget.footer,
                padding:      widget.padding,
                showEditBtn:  widget.showEditButton,
                dashboardId:  widget.dashboardId,
                items:        items,
                itemBuilder:  widget.itemBuilder,
              ),

        // ── Toolbar slides in from top ────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: EditToolbar(
            dashboardId:  widget.dashboardId,
            defaultItems: widget.defaultItems,
          ),
        ),
      ],
    );
  }

  Widget _proxyDecorator(
      Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) {
        final t = Curves.easeOut.transform(animation.value);
        return Transform.scale(
          scale: 1.0 + t * 0.025,
          child: Opacity(
            opacity: 0.92,
            child: Material(
              color: Colors.transparent,
              elevation: 12 * t,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Theme.of(ctx)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ─── Normal mode scroll ───────────────────────────────────────────────────────

class _NormalScroll extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final EdgeInsets padding;
  final bool showEditBtn;
  final String dashboardId;
  final List<LayoutItem> items;
  final DashboardItemBuilder itemBuilder;

  const _NormalScroll({
    required this.header,
    required this.footer,
    required this.padding,
    required this.showEditBtn,
    required this.dashboardId,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header!),
        if (showEditBtn)
          SliverToBoxAdapter(
            child: _InlineEditButton(dashboardId: dashboardId),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final item = items[i];
              return _CustomizedItem(item: item, child: itemBuilder(ctx, item));
            },
            childCount: items.length,
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer!),
        SliverPadding(padding: padding),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CustomizedItem — applies the user's per-item size (S/M/L) and shows a
// small custom-name badge when the user renamed the widget via the
// "customize home screen" sheet. Deliberately minimal: no per-item color
// or font overrides, to keep the design system consistent.
// ─────────────────────────────────────────────────────────────────────────────

class _CustomizedItem extends StatelessWidget {
  final LayoutItem item;
  final Widget child;
  const _CustomizedItem({required this.item, required this.child});

  @override
  Widget build(BuildContext context) {
    final customLabel = item.config['label'] as String?;

    Widget sized = switch (item.size) {
      DashboardItemSize.sm => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: child,
        ),
      DashboardItemSize.lg => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                blurRadius: 16,
              ),
            ],
          ),
          child: child,
        ),
      DashboardItemSize.md => child,
    };

    if (customLabel == null || customLabel.isEmpty) return sized;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        sized,
        PositionedDirectional(
          top: 4, start: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.label, size: 10, color: Colors.white70),
                const SizedBox(width: 3),
                Text(customLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Edit mode scroll ─────────────────────────────────────────────────────────

class _EditModeScroll extends StatelessWidget {
  final String dashboardId;
  final List<LayoutItem> items;
  final LayoutProvider provider;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets padding;
  final bool showEditBtn;
  final String Function(LayoutItem)? nameResolver;
  final IconData Function(LayoutItem)? iconResolver;
  final DashboardItemBuilder itemBuilder;
  final ReorderItemProxyDecorator proxyDecor;

  const _EditModeScroll({
    required this.dashboardId,
    required this.items,
    required this.provider,
    required this.header,
    required this.footer,
    required this.padding,
    required this.showEditBtn,
    required this.nameResolver,
    required this.iconResolver,
    required this.itemBuilder,
    required this.proxyDecor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Spacer for the edit toolbar overlay (52px) ────────────
        const SliverToBoxAdapter(child: SizedBox(height: 52)),

        // ── Non-draggable header ──────────────────────────────────
        if (header != null) SliverToBoxAdapter(child: header!),
        if (showEditBtn)
          SliverToBoxAdapter(
            child: _InlineEditButton(dashboardId: dashboardId),
          ),

        // ── Reorderable items ─────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.only(
            left:  padding.left,
            right: padding.right,
            top:   padding.top,
          ),
          sliver: SliverReorderableList(
            itemCount:       items.length,
            proxyDecorator:  proxyDecor,
            onReorder: (oldIndex, newIndex) =>
                provider.reorder(dashboardId, oldIndex, newIndex),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return ReorderableDelayedDragStartListener(
                key:   ValueKey(item.id),
                index: i,
                child: DraggableItem(
                  dashboardId:  dashboardId,
                  item:         item,
                  displayName:  nameResolver?.call(item) ?? item.type,
                  icon:         iconResolver?.call(item),
                  child:        itemBuilder(ctx, item),
                ),
              );
            },
          ),
        ),

        // ── Non-draggable footer ──────────────────────────────────
        if (footer != null) SliverToBoxAdapter(child: footer!),
        SliverPadding(padding: EdgeInsets.only(bottom: padding.bottom)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InlineEditButton — shown inside the list as an alternative to putting
// [EditModeButton] in the screen's AppBar. Used when showEditButton: true.
// ─────────────────────────────────────────────────────────────────────────────

class _InlineEditButton extends StatelessWidget {
  final String dashboardId;
  const _InlineEditButton({required this.dashboardId});

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<LayoutProvider>();
    final isEditMode = provider.editModeFor(dashboardId);
    final accent     = Theme.of(context).colorScheme.primary;
    final isLight    = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isEditMode
                ? accent.withValues(alpha: 0.12)
                : (isLight ? Colors.white : AppColors.darkCard),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEditMode
                  ? accent.withValues(alpha: 0.45)
                  : (isLight ? AppColors.lightBorder : AppColors.darkBorder),
            ),
            boxShadow: isEditMode
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => provider.toggleEditMode(dashboardId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEditMode ? Symbols.check : Symbols.edit,
                    size: 16,
                    color:
                        isEditMode ? accent : context.tTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEditMode ? 'סיום עריכה' : 'ערוך לוח',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isEditMode ? accent : context.tTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DashboardDefaults — default item lists for every dashboard screen.
// ─────────────────────────────────────────────────────────────────────────────

abstract class DashboardDefaults {
  // Page 1: smart home, security, cameras, ad banner, store.
  // Page 2: energy (weather), system status, home management, media.
  static const List<LayoutItem> home = [
    LayoutItem(id: 'ai_hero',         type: 'ai_hero',         order: 0,  page: 0, pinned: true),
    LayoutItem(id: 'quick_actions',   type: 'quick_actions',   order: 1,  page: 0),
    LayoutItem(id: 'security',        type: 'security',        order: 2,  page: 0),
    LayoutItem(id: 'cameras',         type: 'cameras',         order: 3,  page: 0),
    LayoutItem(id: 'ad_banner',       type: 'ad_banner',       order: 4,  page: 0),
    LayoutItem(id: 'store',           type: 'store',           order: 5,  page: 0),
    LayoutItem(id: 'weather',         type: 'weather',         order: 10, page: 1),
    LayoutItem(id: 'system_status',   type: 'system_status',   order: 11, page: 1),
    LayoutItem(id: 'home_management', type: 'home_management', order: 12, page: 1),
    LayoutItem(id: 'media',           type: 'media',           order: 13, page: 1),
  ];

  /// Item types that belong on home-screen page 1. Anything else (including
  /// future/unrecognized types) defaults to page 2 — the "אחר" bucket.
  static const homePage0Types = {
    'ai_hero', 'quick_actions', 'security', 'cameras', 'ad_banner', 'store',
  };

  // Cameras screen
  static const List<LayoutItem> cameras = [
    LayoutItem(id: 'cam_live_grid', type: 'live_grid',  order: 0),
    LayoutItem(id: 'cam_timeline',  type: 'timeline',   order: 1),
    LayoutItem(id: 'cam_motion',    type: 'motion_log', order: 2),
  ];

  // Security screen
  static const List<LayoutItem> security = [
    LayoutItem(id: 'sec_status',  type: 'arm_status', order: 0, pinned: true),
    LayoutItem(id: 'sec_zones',   type: 'zones',      order: 1),
    LayoutItem(id: 'sec_locks',   type: 'locks',      order: 2),
    LayoutItem(id: 'sec_sensors', type: 'sensors',    order: 3),
    LayoutItem(id: 'sec_history', type: 'event_log',  order: 4),
  ];

  // SmartHome category chips — Lights / Switches / Plugs / Robot Vacuum.
  // Climate (AC) lives in Home Management; all sensor/detector categories
  // live in Security — neither belongs inside Smart Home.
  static const List<LayoutItem> smarthomeCats = [
    LayoutItem(id: 'cat_light',  type: 'cat_light',  order: 0),
    LayoutItem(id: 'cat_blind',  type: 'cat_blind',  order: 1),
    LayoutItem(id: 'cat_plug',   type: 'cat_plug',   order: 2),
    LayoutItem(id: 'cat_switch', type: 'cat_switch', order: 3),
    LayoutItem(id: 'cat_vacuum', type: 'cat_vacuum', order: 4),
  ];

  // Automations screen
  static const List<LayoutItem> automations = [
    LayoutItem(id: 'auto_ha',    type: 'ha_automations', order: 0),
    LayoutItem(id: 'auto_scene', type: 'scenes',         order: 1),
    LayoutItem(id: 'auto_sched', type: 'schedules',      order: 2),
  ];

  static String nameOf(LayoutItem item) {
    const names = <String, String>{
      'ai_hero':       'Fanta AI',
      'weather':       'צריכת אנרגיה',
      'security':      'כרזת אבטחה',
      'rooms':         'חדרים',
      'cameras':       'מצלמות',
      'quick_actions': 'בית חכם',
      'climate_energy': 'אקלים ואנרגיה',
      'home_management': 'ניהול הבית',
      'store':         'חנות',
      'ad_banner':     'פרסום ומימון',
      'media':         'מדיה',
      'system_status': 'סטטוס מערכת',
      'live_grid':     'שידור חי',
      'timeline':      'ציר זמן',
      'motion_log':    'יומן תנועה',
      'arm_status':    'סטטוס הגנה',
      'zones':         'אזורים',
      'locks':         'מנעולים',
      'sensors':       'חיישנים',
      'event_log':     'יומן אירועים',
      'ha_automations':'אוטומציות HA',
      'scenes':        'סצנות',
      'schedules':     'לוח זמנים',
    };
    return names[item.type] ??
        item.config['label'] as String? ??
        item.type;
  }

  static IconData iconOf(LayoutItem item) {
    const icons = <String, IconData>{
      'ai_hero':       Symbols.auto_awesome,
      'weather':       Symbols.bolt,
      'security':      Symbols.shield,
      'rooms':         Symbols.door_front,
      'cameras':       Symbols.videocam,
      'quick_actions': Symbols.home_iot_device,
      'climate_energy': Symbols.thermostat,
      'home_management': Symbols.groups,
      'store':         Symbols.storefront,
      'ad_banner':     Symbols.campaign,
      'media':         Symbols.speaker,
      'system_status': Symbols.memory,
      'live_grid':     Symbols.grid_view,
      'timeline':      Symbols.timeline,
      'motion_log':    Symbols.directions_run,
      'arm_status':    Symbols.security,
      'zones':         Symbols.location_on,
      'locks':         Symbols.lock,
      'sensors':       Symbols.sensors,
      'event_log':     Symbols.list_alt,
      'ha_automations':Symbols.auto_awesome,
      'scenes':        Symbols.palette,
      'schedules':     Symbols.schedule,
    };
    return icons[item.type] ?? Symbols.widgets;
  }
}
