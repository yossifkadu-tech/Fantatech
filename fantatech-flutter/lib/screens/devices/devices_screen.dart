import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../models/device_capabilities.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../utils/ac_options.dart';
import '../../l10n/strings.dart';
import '../../widgets/status_indicator.dart';
import '../smarthome/add_device_screen.dart';
import '../discovery/discovery_sheet.dart';
import '../gateways/gateway_hub_screen.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_types.dart';
import '../../services/gateways/gateway_model.dart';
import '../../services/gateways/clients/ha_gateway_client.dart';

class DevicesScreen extends StatefulWidget {
  final DeviceType? initialCategory;
  const DevicesScreen({super.key, this.initialCategory});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  DeviceType? _selectedCategory;
  String _selectedRoom = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  List<_CategoryMeta> _buildCategories(S s, List<Device> devices) {
    final cats = <_CategoryMeta>[
      _CategoryMeta(null, s.allDevices, Symbols.grid_view, context.tText2(0.7)),
    ];
    if (devices.any((d) => d.type == DeviceType.light)) {
      cats.add(_CategoryMeta(DeviceType.light, s.lightsCategory, Symbols.lightbulb, AppColors.lightColor));
    }
    if (devices.any((d) => d.type == DeviceType.blind)) {
      cats.add(_CategoryMeta(DeviceType.blind, s.blindsCategory, Symbols.blinds, AppColors.primary));
    }
    if (devices.any((d) => d.type == DeviceType.airConditioner || d.type == DeviceType.waterHeater)) {
      cats.add(_CategoryMeta(DeviceType.airConditioner, s.acCategory, Symbols.hvac, AppColors.acColor));
    }
    if (devices.any((d) => d.type == DeviceType.smartPlug)) {
      cats.add(_CategoryMeta(DeviceType.smartPlug, s.plugsCategory, Symbols.power, AppColors.plugColor));
    }
    if (devices.any((d) => d.type == DeviceType.smartSwitch)) {
      cats.add(_CategoryMeta(DeviceType.smartSwitch, s.switchesCategory, Symbols.toggle_on, AppColors.plugColor));
    }
    if (devices.any((d) => d.type == DeviceType.motionSensor || d.type == DeviceType.doorSensor || d.type == DeviceType.windowSensor)) {
      cats.add(_CategoryMeta(DeviceType.motionSensor, s.sensorsCategory, Symbols.sensors, AppColors.motionColor));
    }
    if (devices.any((d) => d.type == DeviceType.router || d.type == DeviceType.gateway)) {
      cats.add(_CategoryMeta(DeviceType.router, s.networkLabel, Symbols.router, AppColors.networkColor));
    }
    if (devices.any((d) => d.type == DeviceType.smokeSensor)) {
      cats.add(_CategoryMeta(DeviceType.smokeSensor, s.catSmoke, Symbols.local_fire_department, AppColors.smokeColor));
    }
    if (devices.any((d) => d.type == DeviceType.energyMeter)) {
      cats.add(_CategoryMeta(DeviceType.energyMeter, s.catEnergy, Symbols.bolt, AppColors.energyColor));
    }
    return cats;
  }

  bool _matchesCategory(Device d, DeviceType? cat) {
    if (cat == null) { return true; }
    if (d.type == cat) { return true; }
    if (cat == DeviceType.motionSensor &&
        (d.type == DeviceType.doorSensor || d.type == DeviceType.windowSensor)) { return true; }
    if (cat == DeviceType.airConditioner && d.type == DeviceType.waterHeater) { return true; }
    if (cat == DeviceType.router && d.type == DeviceType.gateway) { return true; }
    return false;
  }

  void _openDiscovery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiscoverySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final devices = state.devices;
    final categories = _buildCategories(s, devices);

    final rooms = <String>['', ...{...devices.map((d) => d.room)}
        .where((r) => r.isNotEmpty)];

    final filtered = devices.where((d) {
      return _matchesCategory(d, _selectedCategory) &&
          (_selectedRoom.isEmpty || d.room == _selectedRoom);
    }).toList();

    final onCount = filtered.where((d) => d.isOn).length;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(s.devicesTitle,
                    style: TextStyle(
                      color: context.tText, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Gateway hub button
                  Semantics(
                    label: s.networkLabel,
                    button: true,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GatewayHubScreen())),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.networkColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.networkColor.withValues(alpha: 0.28)),
                        ),
                        child: const Icon(Symbols.hub,
                            color: AppColors.networkColor, size: 19),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Radar / discovery scan button
                  Semantics(
                    label: s.scanFindDevices,
                    button: true,
                    child: GestureDetector(
                      onTap: () => _openDiscovery(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Symbols.radar, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: s.addDeviceBtn,
                    button: true,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(Symbols.add, color: AppColors.primary, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Symbols.more_vert,
                        color: context.tText2(0.55), size: 22),
                    onSelected: (v) async {
                      if (v == 'clear_all') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(s.deleteAll,
                                style: TextStyle(color: context.tText)),
                            content: Text(s.deleteAllConfirm,
                                style: TextStyle(color: context.tText2(0.7))),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(s.cancel,
                                    style: TextStyle(color: context.tText2(0.5))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusAlarm,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(s.deleteAll,
                                    style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context.read<AppState>().clearAllDevices();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(children: [
                          const Icon(Symbols.delete_sweep,
                              color: AppColors.statusAlarm, size: 18),
                          const SizedBox(width: 10),
                          Text(s.deleteAll,
                              style: const TextStyle(color: AppColors.statusAlarm)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Empty state ──────────────────────────────────────
            if (devices.isEmpty) ...[
              Expanded(child: _EmptyState(onScan: () => _openDiscovery(context),
                  onAdd: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddDeviceScreen())))),
            ] else ...[
              // ── Category chips (only when devices exist) ───────
              if (categories.length > 1)
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final selected = _selectedCategory == cat.type;
                      final count = devices.where((d) => _matchesCategory(d, cat.type)).length;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat.type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 68,
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color.withValues(alpha: 0.18)
                                : context.tCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? cat.color.withValues(alpha: 0.55)
                                  : context.tText2(0.09),
                              width: 1.2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat.icon, color: selected ? cat.color : context.tText2(0.38), size: 18),
                              const SizedBox(height: 3),
                              Text(cat.label,
                                style: TextStyle(
                                  color: selected ? cat.color : context.tText2(0.38),
                                  fontSize: 10, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('$count',
                                style: TextStyle(
                                  color: selected ? cat.color.withValues(alpha: 0.75) : context.tText2(0.24),
                                  fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── Room filter ────────────────────────────────────
              if (rooms.length > 1)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final selected = _selectedRoom == rooms[i];
                      final label = rooms[i].isEmpty
                          ? s.allDevices
                          : s.translateRoomKey(rooms[i]);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRoom = rooms[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : context.tCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : context.tText2(0.09)),
                          ),
                          child: Text(label, style: TextStyle(
                            color: selected ? context.tText : context.tText2(0.5),
                            fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // ── Summary row ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text('${filtered.length} ${s.devicesTitle}',
                    style: TextStyle(color: context.tText2(0.4),
                        fontSize: 12, fontWeight: FontWeight.w500)),
                  if (onCount > 0) ...[
                    const SizedBox(width: 10),
                    Container(width: 4, height: 4,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.tText2(0.24))),
                    const SizedBox(width: 10),
                    Text('$onCount ${s.devicesOn}',
                      style: TextStyle(color: AppColors.secured.withValues(alpha: 0.8),
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ]),
              ),
              const SizedBox(height: 10),

              // ── Device grid ────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(s.noResults,
                          style: TextStyle(color: context.tText2(0.3), fontSize: 14)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _DeviceCard(
                          device: filtered[i],
                          s: s,
                          onToggle: () => state.toggleDevice(filtered[i].id),
                          onTap: () => _showDetail(context, filtered[i], state, s),
                          onRemove: () => state.removeDevice(filtered[i].id),
                          onOptions: () => _showCardOptions(
                              context, filtered[i], state, s, rooms),
                          onFavoriteToggle: () =>
                              state.toggleFavorite(filtered[i].id),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Device d, AppState state, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DeviceDetailSheet(device: d, state: state, s: s),
    );
  }

  void _showCardOptions(BuildContext context, Device d, AppState state, S s,
      List<String> existingRooms) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetCtx) =>
          _CardOptionsSheet(device: d, state: state, s: s, existingRooms: existingRooms),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onAdd;
  const _EmptyState({required this.onScan, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final s = context.select<AppState, S>((st) => st.strings);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: context.tText2(0.04),
                shape: BoxShape.circle,
                border: Border.all(color: context.tText2(0.08)),
              ),
              child: Icon(Symbols.devices, color: context.tText2(0.24), size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              s.noDevicesConnected,
              style: TextStyle(color: context.tText, fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.scanToDiscover,
              style: TextStyle(color: context.tText2(0.4), fontSize: 13, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Primary: scan for real devices
            GestureDetector(
              onTap: onScan,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Symbols.radar, color: context.tText, size: 18),
                  const SizedBox(width: 10),
                  Text(s.scanFindDevices,
                    style: TextStyle(color: context.tText, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary: manual add
            GestureDetector(
              onTap: onAdd,
              child: Text(
                s.addDeviceBtn,
                style: TextStyle(
                  color: context.tText2(0.4),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: context.tText2(0.25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Device card
// ─────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final Device device;
  final S s;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onOptions;
  final VoidCallback? onFavoriteToggle;
  const _DeviceCard({
    required this.device,
    required this.s,
    required this.onToggle,
    required this.onTap,
    required this.onRemove,
    required this.onOptions,
    this.onFavoriteToggle,
  });

  Color get _color => DeviceIcons.color(device.type);

  IconData get _icon => DeviceIcons.forDevice(device);

  @override
  Widget build(BuildContext context) {
    final status    = device.status;
    final isAlerted = status.isWarning || status.isAlarm;
    final isOn      = device.isOn && !status.isOffline && !isAlerted;
    final showGlow  = isOn || isAlerted || status.isAlert;
    final color     = switch (status) {
      DeviceStatus.offline => AppColors.statusOffline,
      DeviceStatus.warning => AppColors.statusWarning,
      DeviceStatus.alert   => AppColors.statusAlert,
      DeviceStatus.alarm   => AppColors.statusAlarm,
      DeviceStatus.info    => AppColors.statusInfo,
      DeviceStatus.online  => _color,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showGlow
                ? color.withValues(alpha: 0.35)
                : context.tText2(0.07),
            width: 1.2,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Top row: Icon · Favorite · Quick Toggle ─────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: showGlow
                        ? color.withValues(alpha: 0.18)
                        : context.tText2(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _icon,
                    color: showGlow ? color : context.tText2(0.50),
                    size: 21,
                  ),
                ),
                const Spacer(),
                // Favorite button
                GestureDetector(
                  onTap: onFavoriteToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
                    child: Icon(
                      Symbols.favorite,
                      size: 16,
                      fill: device.isFavorite ? 1.0 : 0,
                      color: device.isFavorite
                          ? AppColors.statusAlarm
                          : context.tText2(0.22),
                    ),
                  ),
                ),
                // Quick toggle
                Transform.scale(
                  scale: 0.72,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: isOn,
                    onChanged: status.isControllable && !isAlerted
                        ? (_) => onToggle()
                        : null,
                    activeThumbColor: color,
                    activeTrackColor: color.withValues(alpha: 0.30),
                    inactiveThumbColor: context.tText2(0.25),
                    inactiveTrackColor: context.tText2(0.10),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            // ── Bottom: Name · Room · Status · Battery · Signal · Options ─
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device name
                      Text(
                        device.name,
                        style: TextStyle(
                          color: context.tText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Room (if set)
                      if (device.room.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Icon(Symbols.location_on,
                                size: 10, color: context.tText2(0.28)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                device.room,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.tText2(0.35),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      // Status row: dot + text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          StatusDot(status: status, isActive: isOn, size: 6),
                          const SizedBox(width: 4),
                          Text(
                            switch (status) {
                              DeviceStatus.offline => s.offlineLabel,
                              DeviceStatus.warning => 'Warning',
                              DeviceStatus.alert   => 'Alert',
                              DeviceStatus.alarm   => s.alarmTitle,
                              DeviceStatus.info    => 'Info',
                              DeviceStatus.online  =>
                                  isOn ? s.activeStatus : s.normalStatus,
                            },
                            style: TextStyle(
                              fontSize: 10.5,
                              color: showGlow
                                  ? color.withValues(alpha: 0.85)
                                  : context.tText2(0.30),
                            ),
                          ),
                          // Battery
                          if (device.battery != null) ...[
                            const SizedBox(width: 6),
                            _DeviceBatteryBadge(level: device.battery!),
                          ],
                          // Signal
                          if (device.signal != null) ...[
                            const SizedBox(width: 5),
                            _DeviceSignalBars(signal: device.signal!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Options button
                GestureDetector(
                  onTap: onOptions,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Icon(Symbols.more_vert,
                        color: context.tText2(0.3), size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────
// Card options sheet (rename / assign room / delete)
// ─────────────────────────────────────────────────────────────
class _CardOptionsSheet extends StatefulWidget {
  final Device device;
  final AppState state;
  final S s;
  final List<String> existingRooms;
  const _CardOptionsSheet(
      {required this.device, required this.state, required this.s,
       required this.existingRooms});

  @override
  State<_CardOptionsSheet> createState() => _CardOptionsSheetState();
}

class _CardOptionsSheetState extends State<_CardOptionsSheet> {
  bool _renamingMode = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName(BuildContext ctx) {
    final v = _nameCtrl.text.trim();
    if (v.isNotEmpty && v != widget.device.name) {
      widget.state.updateDeviceName(widget.device.id, v);
    }
    Navigator.pop(ctx);
  }

  void _showRoomPicker(BuildContext ctx) async {
    final s = widget.s;
    final rooms = widget.existingRooms.where((r) => r.isNotEmpty).toList();

    final picked = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: ctx.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (bCtx) => _RoomPickerSheet(
          s: s, rooms: rooms, currentRoom: widget.device.room),
    );
    if (picked != null && ctx.mounted) {
      widget.state.updateDeviceRoom(widget.device.id, picked);
      if (ctx.mounted) Navigator.pop(ctx);
    }
  }

  void _confirmDelete(BuildContext ctx) async {
    final s = widget.s;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: ctx.tCard,
        title: Text(s.remove, style: TextStyle(color: ctx.tText)),
        content: Text(s.deviceWillBeRemoved,
            style: TextStyle(color: ctx.tText2(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(s.cancel, style: TextStyle(color: ctx.tText2(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusAlarm),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(s.remove,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      final d = widget.device;
      widget.state.removeDevice(d.id);
      Navigator.pop(ctx);

      // Devices synced from Home Assistant (Matter included) live in HA's
      // own device registry — removing them locally isn't enough, the next
      // sync would just re-add them. Best-effort mirror the deletion there.
      final entityId = d.attributes['entityId'] as String?;
      if (entityId != null) {
        final gm = ctx.read<GatewayManager>();
        GatewayConnection? ha;
        for (final c in gm.connections) {
          if (c.type == GatewayType.homeAssistant && c.isConnected) { ha = c; break; }
        }
        final ip    = ha?.credentials['ip'];
        final token = ha?.credentials['token'];
        if (ip != null && token != null) {
          HaGatewayClient.removeDeviceByEntity(ip, token, entityId).then((removed) {
            if (!removed && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(s.haRemoveDeviceFailed)),
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final d = widget.device;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: context.tText2(0.22),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        // Header: device name
        Text(d.name,
            style: TextStyle(
                color: context.tText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (d.room.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(s.translateRoomKey(d.room),
                style: TextStyle(color: context.tText2(0.4), fontSize: 13)),
          ),
        const SizedBox(height: 18),

        // Rename row
        if (_renamingMode) ...[
          Row(children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(color: context.tText, fontSize: 15),
                decoration: InputDecoration(
                  hintText: s.deviceRename,
                  hintStyle: TextStyle(color: context.tText2(0.3)),
                  filled: true,
                  fillColor: context.tText2(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _saveName(context),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _saveName(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: AppColors.secured.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Symbols.check, color: AppColors.secured, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 14),
        ] else ...[
          // Rename button
          _OptionTile(
            icon: Symbols.edit,
            label: s.deviceEditName,
            color: AppColors.primary,
            onTap: () => setState(() => _renamingMode = true),
          ),
          const SizedBox(height: 10),

          // Assign room button
          _OptionTile(
            icon: Symbols.meeting_room,
            label: s.assignRoom,
            sublabel: d.room.isEmpty ? s.noRoom : s.translateRoomKey(d.room),
            color: const Color(0xFF00B4D8),
            onTap: () => _showRoomPicker(context),
          ),
          const SizedBox(height: 10),

          // Delete button
          _OptionTile(
            icon: Symbols.delete,
            label: s.remove,
            color: AppColors.statusAlarm,
            onTap: () => _confirmDelete(context),
          ),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Room picker sheet
// ─────────────────────────────────────────────────────────────
class _RoomPickerSheet extends StatefulWidget {
  final S s;
  final List<String> rooms;
  final String currentRoom;
  const _RoomPickerSheet(
      {required this.s, required this.rooms, required this.currentRoom});

  @override
  State<_RoomPickerSheet> createState() => _RoomPickerSheetState();
}

class _RoomPickerSheetState extends State<_RoomPickerSheet> {
  bool _addingNew = false;
  final _newCtrl = TextEditingController();

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: context.tText2(0.22),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Text(s.assignRoom,
            style: TextStyle(
                color: context.tText,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // No-room option
        _RoomTile(
          label: s.noRoom,
          icon: Symbols.cancel,
          selected: widget.currentRoom.isEmpty,
          onTap: () => Navigator.pop(context, ''),
        ),
        const SizedBox(height: 8),

        // Existing rooms
        ...widget.rooms.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RoomTile(
            label: s.translateRoomKey(r),
            icon: Symbols.meeting_room,
            selected: widget.currentRoom == r,
            onTap: () => Navigator.pop(context, r),
          ),
        )),

        // Add new room
        if (_addingNew) ...[
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _newCtrl,
                autofocus: true,
                style: TextStyle(color: context.tText, fontSize: 15),
                decoration: InputDecoration(
                  hintText: s.roomNameHint,
                  hintStyle: TextStyle(color: context.tText2(0.3)),
                  filled: true,
                  fillColor: context.tText2(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (v) {
                  final name = v.trim();
                  if (name.isNotEmpty) Navigator.pop(context, name);
                },
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final name = _newCtrl.text.trim();
                if (name.isNotEmpty) Navigator.pop(context, name);
              },
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: AppColors.secured.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Symbols.check, color: AppColors.secured, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ] else ...[
          _RoomTile(
            label: s.newRoom,
            icon: Symbols.add_circle,
            selected: false,
            iconColor: AppColors.primary,
            onTap: () => setState(() => _addingNew = true),
          ),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared row tiles used in _CardOptionsSheet / _RoomPickerSheet
// ─────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.icon, required this.label, required this.color,
       required this.onTap, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18))),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (sublabel != null)
                  Text(sublabel!,
                      style: TextStyle(
                          color: context.tText2(0.45), fontSize: 12)),
              ],
            ),
          ),
          Icon(Symbols.chevron_right,
              color: context.tText2(0.25), size: 18),
        ]),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;
  const _RoomTile(
      {required this.label, required this.icon, required this.selected,
       required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ??
        (selected ? AppColors.primary : context.tText2(0.45));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : context.tText2(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : context.tText2(0.08))),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: selected ? context.tText : context.tText2(0.7),
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
          ),
          if (selected)
            Icon(Symbols.check_circle,
                color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Device detail sheet
// ─────────────────────────────────────────────────────────────
class _DeviceDetailSheet extends StatefulWidget {
  final Device device;
  final AppState state;
  final S s;
  const _DeviceDetailSheet({required this.device, required this.state, required this.s});

  @override
  State<_DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends State<_DeviceDetailSheet> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;

  Color get _color => DeviceIcons.color(widget.device.type);

  bool get _isNetworkDevice =>
      widget.device.type == DeviceType.router || widget.device.type == DeviceType.gateway;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName(BuildContext context) {
    final newName = _nameCtrl.text.trim();
    if (newName.isNotEmpty && newName != widget.device.name) {
      widget.state.updateDeviceName(widget.device.id, newName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.s.deviceRenamed),
        backgroundColor: AppColors.secured,
        duration: const Duration(seconds: 2),
      ));
    }
    setState(() => _editingName = false);
  }

  void _pickRoom(BuildContext context) async {
    final s = widget.s;
    final allDevices = widget.state.devices;
    final rooms = {
      ...allDevices.map((d) => d.room).where((r) => r.isNotEmpty)
    }.toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _RoomPickerSheet(
          s: s, rooms: rooms, currentRoom: widget.device.room),
    );
    if (picked != null && context.mounted) {
      widget.state.updateDeviceRoom(widget.device.id, picked);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final s = widget.s;
    final color = _color;
    final caps = DeviceCapabilities.of(d);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 24, right: 24, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.tText2(0.24), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(DeviceIcons.forDevice(d), color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _editingName
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              autofocus: true,
                              style: TextStyle(
                                  color: context.tText, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: s.deviceRename,
                                hintStyle: TextStyle(
                                    color: context.tText2(0.3)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 0),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _saveName(context),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _saveName(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.secured.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Symbols.check,
                                  color: AppColors.secured, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              _nameCtrl.text = d.name;
                              setState(() => _editingName = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.tText2(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Symbols.close,
                                  color: context.tText2(0.54), size: 16),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: TextStyle(
                                    color: context.tText, fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                                GestureDetector(
                                  onTap: () => _pickRoom(context),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Symbols.meeting_room,
                                        color: context.tText2(0.35), size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      d.room.isEmpty
                                          ? widget.s.noRoom
                                          : widget.s.translateRoomKey(d.room),
                                      style: TextStyle(
                                          color: context.tText2(0.45),
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                          decorationColor: context.tText2(0.2))),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                          // Edit name button
                          GestureDetector(
                            onTap: () => setState(() => _editingName = true),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: context.tText2(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Symbols.edit,
                                  color: context.tText2(0.45),
                                  size: 15),
                            ),
                          ),
                        ],
                      ),
              ),
              // Network devices: status indicator
              if (_isNetworkDevice)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secured.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.secured.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secured)),
                    const SizedBox(width: 6),
                    Text(s.connectedStatus, style: TextStyle(color: AppColors.secured, fontSize: 12)),
                  ]),
                )
              else
                GestureDetector(
                  onTap: () { widget.state.toggleDevice(d.id); setState(() {}); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 52, height: 30,
                    decoration: BoxDecoration(
                      color: d.isOn ? color : context.tText2(0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      alignment: d.isOn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 24, height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.tText),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Network device info + discover button
          if (_isNetworkDevice) ...[
            if (d.attributes['ip'] != null) ...[
              _InfoRow(label: s.ipAddressLabel, value: d.attributes['ip']),
              _InfoRow(label: 'Port', value: '${d.attributes['port']}'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: Icon(Symbols.radar, size: 18),
                label: Text(s.discoverDevices,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddDeviceScreen(gateway: d),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.tText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // AC: reported temp display + target temp slider
          if (d.type == DeviceType.airConditioner) ...[
            // Current reported temperature display
            if (d.attributes['currentTemp'] != null || d.attributes['temperature'] != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Symbols.thermostat, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(s.deviceTemp,
                        style: TextStyle(color: context.tText2(0.6), fontSize: 13)),
                    ]),
                    Text(
                      '${d.attributes['currentTemp'] ?? d.attributes['temperature']}°C',
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Control-method badge (WiFi / IR / RF)
            Builder(builder: (_) {
              final method =
                  (d.attributes['method'] as String?)?.toUpperCase() ?? 'WIFI';
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Text(s.acMethod,
                      style: TextStyle(
                          color: context.tText2(0.6),
                          fontSize: 13)),
                  const Spacer(),
                  ...['WIFI', 'IR', 'RF'].map((m) {
                    final sel = m == method;
                    return GestureDetector(
                      onTap: () {
                        widget.state.setDeviceAttribute(d.id, 'method', m);
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(start: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.20)
                              : context.tText2(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel
                                  ? color
                                  : context.tText2(0.1)),
                        ),
                        child: Row(children: [
                          Icon(
                              m == 'WIFI'
                                  ? Symbols.wifi
                                  : m == 'IR'
                                      ? Symbols.settings_remote
                                      : Symbols.sensors,
                              color: sel ? color : context.tText2(0.38),
                              size: 13),
                          const SizedBox(width: 4),
                          Text(m == 'WIFI' ? 'WiFi' : m,
                              style: TextStyle(
                                  color: sel ? context.tText : context.tText2(0.54),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  }),
                ]),
              );
            }),

            // Mode — options adapt to what this AC actually supports
            Builder(builder: (_) {
              final supported = (d.attributes['hvacModes'] as List?)
                      ?.cast<String>()
                      .where((m) => m != 'off')
                      .toList() ??
                  const ['cool', 'heat', 'fan', 'dry', 'auto'];
              if (supported.isEmpty) return const SizedBox.shrink();
              return _AcChoiceRow(
                label: s.acMode,
                color: color,
                selected: d.attributes['mode'] as String? ?? supported.first,
                options: [for (final m in supported) acModeOption(s, m)],
                onSelect: (v) {
                  widget.state.setDeviceAttribute(d.id, 'mode', v);
                  setState(() {});
                },
              );
            }),
            const SizedBox(height: 12),

            // Fan speed — adapts to the entity's supported fan modes
            Builder(builder: (_) {
              final supported =
                  (d.attributes['fanModes'] as List?)?.cast<String>() ??
                      const ['low', 'med', 'high', 'auto'];
              if (supported.isEmpty) return const SizedBox.shrink();
              return _AcChoiceRow(
                label: s.acFanSpeed,
                color: color,
                selected: d.attributes['fan'] as String? ?? supported.last,
                options: [for (final m in supported) acFanOption(s, m)],
                onSelect: (v) {
                  widget.state.setDeviceAttribute(d.id, 'fan', v);
                  setState(() {});
                },
              );
            }),
            const SizedBox(height: 12),

            // Swing — HA entities expose named swing modes; local/IR devices
            // keep the simple on/off toggle.
            Builder(builder: (_) {
              final swingModes =
                  (d.attributes['swingModes'] as List?)?.cast<String>() ?? const [];
              if (swingModes.isNotEmpty) {
                return _AcChoiceRow(
                  label: s.acSwing,
                  color: color,
                  selected:
                      d.attributes['swingMode'] as String? ?? swingModes.first,
                  options: [
                    for (final m in swingModes)
                      (m, prettyMode(m), Symbols.swap_vert),
                  ],
                  onSelect: (v) {
                    widget.state.setDeviceAttribute(d.id, 'swingMode', v);
                    setState(() {});
                  },
                );
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.tText2(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.tText2(0.08)),
                ),
                child: Row(children: [
                  Icon(Symbols.swap_vert, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(s.acSwing,
                      style: TextStyle(color: context.tText, fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: d.attributes['swing'] as bool? ?? false,
                    activeThumbColor: context.tText,
                    activeTrackColor: color,
                    onChanged: (v) {
                      widget.state.setDeviceAttribute(d.id, 'swing', v);
                      setState(() {});
                    },
                  ),
                ]),
              );
            }),
            const SizedBox(height: 12),

            // Presets (eco / sleep / boost…) — only when the entity has them
            Builder(builder: (_) {
              final presets =
                  (d.attributes['presetModes'] as List?)?.cast<String>() ?? const [];
              if (presets.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AcChoiceRow(
                  label: s.acPreset,
                  color: color,
                  selected:
                      d.attributes['presetMode'] as String? ?? presets.first,
                  options: [
                    for (final m in presets)
                      (m, prettyMode(m), Symbols.eco),
                  ],
                  onSelect: (v) {
                    widget.state.setDeviceAttribute(d.id, 'presetMode', v);
                    setState(() {});
                  },
                ),
              );
            }),

            Builder(builder: (_) {
              final minT =
                  (d.attributes['minTemp'] as num?)?.toDouble() ?? 16;
              final maxT =
                  (d.attributes['maxTemp'] as num?)?.toDouble() ?? 30;
              final target =
                  ((d.attributes['temperature'] as num?)?.toDouble() ?? 22)
                      .clamp(minT, maxT);
              return _SliderRow(
                label: '${s.deviceTemp}: ${target.round()}°C',
                value: target.toDouble(),
                min: minT,
                max: maxT,
                divisions: (maxT - minT).round().clamp(1, 60),
                color: color,
                onChanged: (v) {
                  widget.state.setDeviceAttribute(d.id, 'temperature', v.toInt());
                  setState(() {});
                },
              );
            }),
          ],
          // Light: on/off buttons + brightness
          if (d.type == DeviceType.light) ...[
            // On / Off action buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!d.isOn) {
                        widget.state.toggleDevice(d.id);
                        setState(() {});
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        color: d.isOn
                            ? color.withValues(alpha: 0.18)
                            : context.tText2(0.06),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: d.isOn
                              ? color.withValues(alpha: 0.5)
                              : context.tText2(0.10),
                          width: 1.5,
                        ),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Symbols.lightbulb, color: d.isOn ? color : context.tText2(0.38), size: 18),
                        const SizedBox(width: 8),
                        Text(widget.state.strings.actionTurnOn,
                          style: TextStyle(
                            color: d.isOn ? color : context.tText2(0.38),
                            fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (d.isOn) {
                        widget.state.toggleDevice(d.id);
                        setState(() {});
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        color: !d.isOn
                            ? context.tText2(0.10)
                            : context.tText2(0.04),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: !d.isOn
                              ? context.tText2(0.35)
                              : context.tText2(0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Symbols.lightbulb, color: !d.isOn ? context.tText2(0.7) : context.tText2(0.24), size: 18),
                        const SizedBox(width: 8),
                        Text(widget.state.strings.actionTurnOff,
                          style: TextStyle(
                            color: !d.isOn ? context.tText2(0.7) : context.tText2(0.24),
                            fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ],
          // Brightness — any dimmable device (lights, Matter dimmer plugs…)
          if (caps.contains(DeviceCapability.brightness)) ...[
            _SliderRow(
              label: '${s.deviceBrightness}: ${d.attributes['brightness'] ?? 80}%',
              value: (d.attributes['brightness'] as int? ?? 80).toDouble(),
              min: 0, max: 100, divisions: 10, color: color,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'brightness', v.toInt());
                setState(() {});
              },
            ),
          ],
          // Position — any positionable cover, whichever key its source wrote
          if (caps.contains(DeviceCapability.position)) ...[
            _SliderRow(
              label: '${s.devicePosition}: ${DeviceCapabilities.positionOf(d) ?? 50}%',
              value: (DeviceCapabilities.positionOf(d) ?? 50).toDouble(),
              min: 0, max: 100, divisions: 10, color: color,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'position', v.toInt());
                setState(() {});
              },
            ),
          ],
          // Lock / unlock control
          if (caps.contains(DeviceCapability.lockControl)) ...[
            GestureDetector(
              onTap: () {
                widget.state.toggleDevice(d.id);
                setState(() {});
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: (d.isOn ? AppColors.secured : AppColors.unsecured)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (d.isOn ? AppColors.secured : AppColors.unsecured)
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(DeviceIcons.lockIcon(d.isOn),
                        color: d.isOn ? AppColors.secured : AppColors.unsecured,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      d.isOn ? s.lockedStatus : s.unlockedStatus,
                      style: TextStyle(
                        color: d.isOn ? AppColors.secured : AppColors.unsecured,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Water heater temp + mode
          if (d.type == DeviceType.waterHeater) ...[
            _SliderRow(
              label: '${s.boilerTempLabel}: ${d.attributes['targetTemp'] ?? 60}°C',
              value: (d.attributes['targetTemp'] as int? ?? 60).toDouble(),
              min: 30, max: 80, divisions: 10, color: color,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'targetTemp', v.toInt());
                setState(() {});
              },
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text(s.boilerMode, style: TextStyle(
                  color: context.tText2(0.5), fontSize: 12)),
              const SizedBox(width: 10),
              _ModeToggle(
                selected: d.attributes['mode'] as String? ?? 'eco',
                ecoLabel: s.boilerModeEco,
                fullLabel: s.boilerModeFull,
                onChanged: (m) {
                  widget.state.setDeviceAttribute(d.id, 'mode', m);
                  setState(() {});
                },
              ),
            ]),
          ],
          // Smart plug power
          if (d.type == DeviceType.smartPlug) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.tText2(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Symbols.bolt, color: AppColors.lightColor, size: 16),
                const SizedBox(width: 8),
                Text('${d.attributes['power'] ?? 0}W',
                    style: TextStyle(
                        color: context.tText, fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
          // Sensor readings — capability-driven: any binary sensor gets its
          // live state; battery/temperature/humidity chips appear only when
          // the device actually reports them.
          if (caps.contains(DeviceCapability.binaryState) ||
              caps.contains(DeviceCapability.battery) ||
              caps.contains(DeviceCapability.temperature) ||
              caps.contains(DeviceCapability.humidity)) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (caps.contains(DeviceCapability.binaryState))
                  Builder(builder: (_) {
                    final key = DeviceCapabilities.binaryStateKey(d.type)!;
                    final active = d.attributes[key] == true;
                    return _ReadingChip(
                      icon: DeviceIcons.forDevice(d),
                      label: active ? s.activeStatus : s.normalStatus,
                      color: active
                          ? AppColors.unsecured
                          : context.tText2(0.54),
                    );
                  }),
                if (caps.contains(DeviceCapability.battery))
                  Builder(builder: (_) {
                    final level = d.battery ??
                        (d.attributes['battery'] as num?)?.toInt();
                    final low = level != null && level <= 20;
                    return _ReadingChip(
                      icon: DeviceIcons.batteryIcon(level),
                      label: level != null ? '$level%' : '—',
                      color: low ? AppColors.statusAlarm : AppColors.secured,
                    );
                  }),
                // AC already shows temperature prominently in its own section
                if (caps.contains(DeviceCapability.temperature) &&
                    !caps.contains(DeviceCapability.climateControl))
                  _ReadingChip(
                    icon: DeviceIcons.forHaDeviceClass('temperature'),
                    label:
                        '${d.attributes['temperature'] ?? d.attributes['currentTemp']}°C',
                    color: context.tText2(0.54),
                  ),
                if (caps.contains(DeviceCapability.humidity))
                  _ReadingChip(
                    icon: DeviceIcons.forHaDeviceClass('humidity'),
                    label: '${d.attributes['humidity']}%',
                    color: context.tText2(0.54),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ReadingChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.tText2(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text('$label: ', style: TextStyle(color: context.tText2(0.45), fontSize: 13)),
        Text(value, style: TextStyle(color: context.tText, fontSize: 13, fontFamily: 'monospace')),
      ]),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value, required this.min,
      required this.max, required this.divisions, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.tText2(0.7),
            fontSize: 13, fontWeight: FontWeight.w500)),
        Slider(
          value: value, min: min, max: max, divisions: divisions,
          activeColor: color,
          inactiveColor: context.tText2(0.12),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String selected;
  final String ecoLabel;
  final String fullLabel;
  final ValueChanged<String> onChanged;

  const _ModeToggle({
    required this.selected,
    required this.ecoLabel,
    required this.fullLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _ModeBtn(
        label: ecoLabel, icon: Symbols.eco,
        selected: selected == 'eco',
        color: AppColors.secured,
        onTap: () => onChanged('eco'),
      ),
      const SizedBox(width: 8),
      _ModeBtn(
        label: fullLabel, icon: Symbols.local_fire_department,
        selected: selected == 'full',
        color: const Color(0xFFFF6B35),
        onTap: () => onChanged('full'),
      ),
    ]);
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label, required this.icon,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : context.tText2(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : context.tText2(0.08),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? color : context.tText2(0.38), size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
              color: selected ? color : context.tText2(0.38),
              fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _CategoryMeta {
  final DeviceType? type;
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryMeta(this.type, this.label, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────
// AC choice row — label + a wrap of selectable chips (mode / fan).
// ─────────────────────────────────────────────────────────────
class _AcChoiceRow extends StatelessWidget {
  final String label;
  final Color color;
  final String selected;
  final List<(String, String, IconData)> options;
  final ValueChanged<String> onSelect;
  const _AcChoiceRow({
    required this.label,
    required this.color,
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: context.tText2(0.6), fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final sel = opt.$1 == selected;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withValues(alpha: 0.18)
                      : context.tText2(0.05),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: sel
                          ? color.withValues(alpha: 0.6)
                          : context.tText2(0.1),
                      width: 1.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.$3,
                        color: sel ? color : context.tText2(0.54), size: 16),
                    const SizedBox(width: 6),
                    Text(opt.$2,
                        style: TextStyle(
                            color: sel ? context.tText : context.tText2(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Battery + Signal helpers (scoped to devices_screen) ─────────────────────

class _DeviceBatteryBadge extends StatelessWidget {
  final int level;
  const _DeviceBatteryBadge({required this.level});

  Color get _color {
    if (level <= 20) return AppColors.statusAlarm;
    if (level <= 50) return AppColors.statusWarning;
    return AppColors.statusOnline;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          level <= 20 ? Symbols.battery_alert : Symbols.battery_full,
          size: 11,
          color: _color,
        ),
        const SizedBox(width: 1),
        Text(
          '$level',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _color,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DeviceSignalBars extends StatelessWidget {
  final int signal;
  const _DeviceSignalBars({required this.signal});

  @override
  Widget build(BuildContext context) {
    final activeBars = (signal / 25).ceil().clamp(0, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < activeBars;
        return Container(
          width: 3,
          height: 4.0 + i * 2.5,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: active ? context.tText2(0.50) : context.tText2(0.12),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
