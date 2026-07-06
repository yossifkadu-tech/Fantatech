import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../widgets/device_card.dart';
import '../../widgets/ft_button.dart';
import '../../widgets/edit_mode/reorderable_dashboard.dart';
import '../../widgets/edit_mode/edit_toolbar.dart';
import '../../providers/layout_provider.dart';
import '../../models/layout_item.dart';
import 'add_device_screen.dart';
import 'blind_hub_screen.dart';
import 'lights_hub_screen.dart';
import 'ac_hub_screen.dart';
import 'plugs_hub_screen.dart';
import 'smart_switch_hub_screen.dart';
import 'sensor_hub_screen.dart';
import 'intercom_hub_screen.dart';

class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  String? _selectedRoom; // null = all rooms

  @override
  void initState() {
    super.initState();
    // One-time cleanup: AC and sensor category chips used to live here —
    // they've moved to Home Management and Security respectively. Existing
    // installs would otherwise keep showing the old chips forever, since
    // seeding a dashboard only ever ADDS new items, never removes retired
    // ones.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LayoutProvider>().pruneObsoleteTypes(
          DashboardId.smarthomeCats, const {'cat_ac', 'cat_sensor'});
    });
  }

  // ── Category metadata keyed by layout item type ──────────────────────────
  Map<String, ({String label, DeviceType type, IconData icon, Color color, Widget? dest})>
      _catMeta(S s, BuildContext ctx) => {
    'cat_light':  (label: s.lightsCategory,   type: DeviceType.light,           icon: DeviceIcons.icon(DeviceType.light),           color: DeviceIcons.color(DeviceType.light),           dest: const LightsHubScreen()),
    'cat_blind':  (label: s.blindsCategory,   type: DeviceType.blind,           icon: DeviceIcons.icon(DeviceType.blind),           color: DeviceIcons.color(DeviceType.blind),           dest: const BlindHubScreen()),
    'cat_ac':     (label: s.acCategory,       type: DeviceType.airConditioner,  icon: DeviceIcons.icon(DeviceType.airConditioner),  color: DeviceIcons.color(DeviceType.airConditioner),  dest: const ACHubScreen()),
    'cat_plug':   (label: s.plugsCategory,    type: DeviceType.smartPlug,       icon: DeviceIcons.icon(DeviceType.smartPlug),       color: DeviceIcons.color(DeviceType.smartPlug),       dest: const PlugsHubScreen()),
    'cat_switch': (label: s.switchesCategory, type: DeviceType.smartSwitch,     icon: DeviceIcons.icon(DeviceType.smartSwitch),     color: DeviceIcons.color(DeviceType.smartSwitch),     dest: const SmartSwitchHubScreen()),
    'cat_sensor':   (label: s.sensorsCategory,  type: DeviceType.motionSensor, icon: DeviceIcons.icon(DeviceType.motionSensor), color: DeviceIcons.color(DeviceType.motionSensor), dest: const SensorHubScreen()),
    'cat_intercom': (label: s.intercomCategory, type: DeviceType.intercom,    icon: DeviceIcons.icon(DeviceType.intercom),     color: DeviceIcons.color(DeviceType.intercom),     dest: const IntercomHubScreen()),
  };

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final s        = state.strings;
    final theme    = Theme.of(context);
    final provider = context.watch<LayoutProvider>();
    final editMode = provider.editMode;

    // Seed category layout (no-op if already saved)
    provider.ensureLayout(DashboardId.smarthomeCats, DashboardDefaults.smarthomeCats);
    final catItems = provider.getItems(
      DashboardId.smarthomeCats,
      allItems: editMode, // show hidden in edit mode too
    );
    final meta = _catMeta(s, context);

    final rooms = [null, ...{...state.devices.map((d) => d.room)}];
    final filtered = _selectedRoom == null
        ? state.devices
        : state.devices.where((d) => d.room == _selectedRoom).toList();

    // Build default layout items from the full device list (all rooms).
    // Seeded once; room filtering is applied in the itemBuilder below.
    final allDevices = state.devices;
    final defaultItems = allDevices.asMap().entries.map((e) => LayoutItem(
      id: 'device_${e.value.id}',
      type: 'device',
      config: {'deviceId': e.value.id, 'label': e.value.name},
      order: e.key,
    )).toList();

    // Seed layout (no-op if already persisted).
    context.read<LayoutProvider>().ensureLayout(DashboardId.smarthome, defaultItems);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header (title, category chips, room filter) ──────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.smartHomeTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const EditModeButton(),
                          const SizedBox(width: 8),
                          FtButton.iconOnly(
                            icon: Symbols.add,
                            variant: FtButtonVariant.secondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddDeviceScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category chips (customizable in edit mode)
                  SizedBox(
                    height: 80,
                    child: editMode
                        // ── Edit mode: drag-to-reorder + ✕ badges ──────────
                        ? ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            buildDefaultDragHandles: false,
                            padding: EdgeInsets.zero,
                            itemCount: catItems.length,
                            onReorder: (o, n) =>
                                provider.reorder(DashboardId.smarthomeCats, o, n),
                            itemBuilder: (ctx, i) {
                              final item = catItems[i];
                              final m    = meta[item.type];
                              if (m == null) return const SizedBox.shrink(key: ValueKey('_'));
                              final count = state.devices.where((d) =>
                                d.type == m.type ||
                                (m.type == DeviceType.motionSensor &&
                                  (d.type == DeviceType.doorSensor ||
                                   d.type == DeviceType.windowSensor))).length;
                              return Padding(
                                key: ValueKey(item.id),
                                padding: const EdgeInsets.only(right: 10),
                                child: ReorderableDragStartListener(
                                  index: i,
                                  child: _CategoryChip(
                                    label: m.label,
                                    icon: m.icon,
                                    color: m.color,
                                    count: count,
                                    hidden: !item.visible,
                                    editMode: true,
                                    onTap: null,
                                    onHide: () => provider.toggleVisibility(
                                        DashboardId.smarthomeCats, item.id),
                                  ),
                                ),
                              );
                            },
                          )
                        // ── Normal mode: show visible chips only ───────────
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: catItems.where((i) => i.visible).length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final item = catItems.where((it) => it.visible).elementAt(i);
                              final m    = meta[item.type];
                              if (m == null) return const SizedBox.shrink();
                              final count = state.devices.where((d) =>
                                d.type == m.type ||
                                (m.type == DeviceType.motionSensor &&
                                  (d.type == DeviceType.doorSensor ||
                                   d.type == DeviceType.windowSensor))).length;
                              return _CategoryChip(
                                label: m.label,
                                icon: m.icon,
                                color: m.color,
                                count: count,
                                hidden: false,
                                editMode: false,
                                onTap: m.dest != null
                                    ? () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => m.dest!))
                                    : null,
                                onHide: null,
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Room filter
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final room = rooms[i]; // null = all
                        final selected = _selectedRoom == room;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRoom = room),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : context.tCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: Text(
                              room == null ? s.allDevices : s.translateRoomKey(room),
                              style: TextStyle(
                                color: selected ? context.tText : null,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    s.deviceCountFmt.replaceAll('{n}', '${filtered.length}'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Reorderable device grid (takes remaining vertical space) ───
            Expanded(
              child: filtered.isEmpty
                  ? const SizedBox.shrink()
                  : ReorderableDashboard(
                      dashboardId: DashboardId.smarthome,
                      defaultItems: defaultItems,
                      showEditButton: false,
                      nameResolver: (item) =>
                          item.config['label'] as String? ?? item.type,
                      iconResolver: (_) => Symbols.devices,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      itemBuilder: (ctx, item) {
                        final deviceId =
                            item.config['deviceId'] as String?;
                        // Find the device; skip if it doesn't match the
                        // current room filter.
                        final device = allDevices.cast<Device?>().firstWhere(
                              (d) => d?.id == deviceId,
                              orElse: () => null,
                            );
                        if (device == null) return const SizedBox.shrink();
                        if (_selectedRoom != null &&
                            device.room != _selectedRoom) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DeviceCard(
                            device: device,
                            onToggle: () => state.toggleDevice(device.id),
                            onTap: () =>
                                _showDeviceDetail(context, device, state),
                            onFavoriteToggle: () =>
                                state.toggleFavorite(device.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceDetail(BuildContext context, Device device, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DeviceDetailSheet(device: device, state: state),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool hidden;
  final bool editMode;
  final VoidCallback? onTap;
  final VoidCallback? onHide;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.hidden,
    required this.editMode,
    this.onTap,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final effectiveColor = hidden ? color.withValues(alpha: 0.35) : color;

    final chip = Container(
      width: 72,
      decoration: BoxDecoration(
        color: hidden
            ? context.tText2(0.04)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: editMode
              ? color.withValues(alpha: 0.55)
              : color.withValues(alpha: 0.20),
          width: editMode ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: effectiveColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          Text(
            '$count',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: context.tText2(hidden ? 0.28 : 0.55)),
          ),
        ],
      ),
    );

    Widget result = Semantics(
      label: '$label — $count',
      button: !editMode,
      child: GestureDetector(onTap: editMode ? null : onTap, child: chip),
    );

    if (editMode) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          // ✕ hide/show badge
          Positioned(
            top: -6, right: -6,
            child: GestureDetector(
              onTap: onHide,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: hidden ? AppColors.secured : AppColors.alert,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.tBg, width: 1.5),
                ),
                child: Icon(
                  hidden ? Symbols.add : Symbols.close,
                  size: 12, color: Colors.white,
                ),
              ),
            ),
          ),
          // Drag handle indicator at bottom
          Positioned(
            bottom: 2, left: 0, right: 0,
            child: Center(
              child: Icon(Symbols.drag_handle,
                  size: 12, color: color.withValues(alpha: 0.45)),
            ),
          ),
        ],
      );
    }

    return result;
  }
}

class _DeviceDetailSheet extends StatefulWidget {
  final Device device;
  final AppState state;

  const _DeviceDetailSheet({required this.device, required this.state});

  @override
  State<_DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends State<_DeviceDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final s     = context.select<AppState, S>((st) => st.strings);
    final theme = Theme.of(context);
    final d     = widget.device;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                d.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: d.isOn,
                onChanged: (v) {
                  widget.state.toggleDevice(d.id);
                  setState(() {});
                },
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
              ),
            ],
          ),
          Text(
            d.room,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),

          // AC controls
          if (d.type == DeviceType.airConditioner) ...[
            Text(s.temperatureFmt.replaceAll('{n}', '${d.attributes['temperature']}'),
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (d.attributes['temperature'] as int).toDouble(),
              min: 16,
              max: 30,
              divisions: 14,
              label: '${d.attributes['temperature']}°C',
              activeColor: AppColors.acColor,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'temperature', v.toInt());
                setState(() {});
              },
            ),
          ],

          // Light controls
          if (d.type == DeviceType.light) ...[
            Text(s.brightnessFmt.replaceAll('{n}', '${d.attributes['brightness']}'),
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (d.attributes['brightness'] as int? ?? 80).toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: '${d.attributes['brightness']}%',
              activeColor: AppColors.lightColor,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'brightness', v.toInt());
                setState(() {});
              },
            ),
          ],

          // Blind controls
          if (d.type == DeviceType.blind) ...[
            Text(s.positionFmt.replaceAll('{n}', '${d.attributes['position'] ?? 50}'),
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (d.attributes['position'] as int? ?? 50).toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: '${d.attributes['position'] ?? 50}%',
              activeColor: AppColors.primary,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'position', v.toInt());
                setState(() {});
              },
              onChangeEnd: (v) {
                widget.state.setCoverPosition(d.id, v.toInt());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    widget.state.toggleDevice(d.id);
                    widget.state.setCoverPosition(d.id, 100);
                    setState(() {});
                  },
                  icon: const Icon(Symbols.expand_less, size: 16),
                  label: Text(s.coverOpen.replaceAll('▲  ', '')),
                ),
                TextButton.icon(
                  onPressed: () => widget.state.stopCover(d.id),
                  icon: const Icon(Symbols.stop, size: 16),
                  label: Text(s.coverStop.replaceAll('■  ', '')),
                ),
                TextButton.icon(
                  onPressed: () {
                    widget.state.toggleDevice(d.id);
                    widget.state.setCoverPosition(d.id, 0);
                    setState(() {});
                  },
                  icon: const Icon(Symbols.expand_more, size: 16),
                  label: Text(s.coverClose.replaceAll('▼  ', '')),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
