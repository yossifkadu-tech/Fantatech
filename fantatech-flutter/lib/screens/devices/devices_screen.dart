import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../smarthome/add_device_screen.dart';
import '../discovery/discovery_sheet.dart';
import '../gateways/gateway_hub_screen.dart';

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

  static const _networkColor = Color(0xFF00B4D8);

  List<_CategoryMeta> _buildCategories(S s, List<Device> devices) {
    final cats = <_CategoryMeta>[
      _CategoryMeta(null, s.allDevices, Icons.grid_view_outlined, context.tText2(0.7)),
    ];
    if (devices.any((d) => d.type == DeviceType.light))
      cats.add(_CategoryMeta(DeviceType.light, s.lightsCategory, Icons.lightbulb_outlined, AppColors.lightColor));
    if (devices.any((d) => d.type == DeviceType.blind))
      cats.add(_CategoryMeta(DeviceType.blind, s.blindsCategory, Icons.blinds_outlined, AppColors.primary));
    if (devices.any((d) => d.type == DeviceType.airConditioner || d.type == DeviceType.waterHeater))
      cats.add(_CategoryMeta(DeviceType.airConditioner, s.acCategory, Icons.hvac, AppColors.acColor));
    if (devices.any((d) => d.type == DeviceType.smartPlug))
      cats.add(_CategoryMeta(DeviceType.smartPlug, s.plugsCategory, Icons.power_outlined, AppColors.plugColor));
    if (devices.any((d) => d.type == DeviceType.smartSwitch))
      cats.add(_CategoryMeta(DeviceType.smartSwitch, s.switchesCategory, Icons.toggle_on_outlined, AppColors.plugColor));
    if (devices.any((d) => d.type == DeviceType.motionSensor || d.type == DeviceType.doorSensor || d.type == DeviceType.windowSensor))
      cats.add(_CategoryMeta(DeviceType.motionSensor, s.sensorsCategory, Icons.sensors_outlined, AppColors.motionColor));
    if (devices.any((d) => d.type == DeviceType.router || d.type == DeviceType.gateway))
      cats.add(_CategoryMeta(DeviceType.router, s.networkLabel, Icons.router_outlined, _networkColor));
    if (devices.any((d) => d.type == DeviceType.smokeSensor))
      cats.add(_CategoryMeta(DeviceType.smokeSensor, 'עשן', Icons.local_fire_department_outlined, const Color(0xFFFF6B35)));
    if (devices.any((d) => d.type == DeviceType.energyMeter))
      cats.add(_CategoryMeta(DeviceType.energyMeter, 'אנרגיה', Icons.bolt_outlined, const Color(0xFFFFD600)));
    return cats;
  }

  bool _matchesCategory(Device d, DeviceType? cat) {
    if (cat == null) return true;
    if (d.type == cat) return true;
    if (cat == DeviceType.motionSensor &&
        (d.type == DeviceType.doorSensor || d.type == DeviceType.windowSensor)) return true;
    if (cat == DeviceType.airConditioner && d.type == DeviceType.waterHeater) return true;
    if (cat == DeviceType.router && d.type == DeviceType.gateway) return true;
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
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GatewayHubScreen())),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18BCEC).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF18BCEC).withValues(alpha: 0.28)),
                      ),
                      child: Icon(Icons.hub_outlined,
                          color: Color(0xFF18BCEC), size: 19),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Radar / discovery scan button
                  GestureDetector(
                    onTap: () => _openDiscovery(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.radar, color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Icon(Icons.add, color: AppColors.primary, size: 22),
                    ),
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
    final s = context.watch<AppState>().strings;
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
              child: Icon(Icons.devices_outlined, color: context.tText2(0.24), size: 38),
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
                  Icon(Icons.radar, color: context.tText, size: 18),
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
  const _DeviceCard({required this.device, required this.s,
      required this.onToggle, required this.onTap, required this.onRemove});

  static const _networkColor = Color(0xFF00B4D8);

  Color get _color {
    switch (device.type) {
      case DeviceType.light:           return AppColors.lightColor;
      case DeviceType.blind:           return AppColors.primary;
      case DeviceType.airConditioner:
      case DeviceType.waterHeater:     return AppColors.acColor;
      case DeviceType.smartPlug:
      case DeviceType.smartSwitch:     return AppColors.plugColor;
      case DeviceType.motionSensor:
      case DeviceType.doorSensor:
      case DeviceType.windowSensor:    return AppColors.motionColor;
      case DeviceType.camera:          return AppColors.cameraColor;
      case DeviceType.router:
      case DeviceType.gateway:         return _networkColor;
      case DeviceType.circuitBreaker:  return const Color(0xFF7BB8FF);
      case DeviceType.solar:           return const Color(0xFFFFB300);
      case DeviceType.smokeSensor:     return const Color(0xFFFF6B35);
      case DeviceType.energyMeter:     return const Color(0xFFFFD600);
      case DeviceType.smartLock:       return const Color(0xFF34A853);
      case DeviceType.gasSensor:       return const Color(0xFFFF8C00);
      case DeviceType.waterLeakSensor: return const Color(0xFF00B4D8);
      case DeviceType.matterDevice:    return const Color(0xFF7B6FCD);
    }
  }

  IconData get _icon {
    switch (device.type) {
      case DeviceType.light:           return Icons.lightbulb_outlined;
      case DeviceType.blind:           return Icons.blinds_outlined;
      case DeviceType.airConditioner:  return Icons.hvac;
      case DeviceType.smartPlug:       return Icons.power_outlined;
      case DeviceType.smartSwitch:     return Icons.toggle_on_outlined;
      case DeviceType.motionSensor:    return Icons.sensors_outlined;
      case DeviceType.doorSensor:      return Icons.sensor_door_outlined;
      case DeviceType.windowSensor:    return Icons.window_outlined;
      case DeviceType.waterHeater:     return Icons.water_drop_outlined;
      case DeviceType.camera:          return Icons.videocam_outlined;
      case DeviceType.router:          return Icons.router_outlined;
      case DeviceType.gateway:         return Icons.hub_outlined;
      case DeviceType.circuitBreaker:  return Icons.electrical_services;
      case DeviceType.solar:           return Icons.wb_sunny_outlined;
      case DeviceType.smokeSensor:     return Icons.local_fire_department_outlined;
      case DeviceType.energyMeter:     return Icons.bolt_outlined;
      case DeviceType.smartLock:       return Icons.lock_outline;
      case DeviceType.gasSensor:       return Icons.cloud_outlined;
      case DeviceType.waterLeakSensor: return Icons.water_damage_outlined;
      case DeviceType.matterDevice:    return Icons.hexagon_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;
    final color = _color;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _confirmRemove(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOn
                ? color.withValues(alpha: 0.35)
                : context.tText2(0.07),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: icon + status dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isOn
                        ? color.withValues(alpha: 0.18)
                        : context.tText2(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(_icon,
                      color: isOn ? color : context.tText2(0.54),
                      size: 22),
                  ),
                ),
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: device.status == DeviceStatus.online
                        ? (isOn ? color : AppColors.secured.withValues(alpha: 0.60))
                        : context.tText2(0.24),
                  ),
                ),
              ],
            ),
            // Bottom: name + status label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                  style: TextStyle(
                    color: context.tText, fontSize: 12.5,
                    fontWeight: FontWeight.w600, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  isOn ? s.activeStatus : s.normalStatus,
                  style: TextStyle(
                    color: isOn
                        ? color.withValues(alpha: 0.85)
                        : context.tText2(0.30),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final s = context.read<AppState>().strings;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: context.tText2(0.24), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('${s.remove} "${device.name}"?',
            style: TextStyle(color: context.tText, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(s.deviceWillBeRemoved,
            style: TextStyle(color: context.tText2(0.4), fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.tText2(0.07),
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(s.cancel,
                    style: TextStyle(color: context.tText2(0.7), fontSize: 14))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () { Navigator.pop(ctx); onRemove(); },
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.unsecured.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.unsecured.withValues(alpha: 0.35))),
                  child: Center(child: Text(s.remove,
                    style: TextStyle(color: AppColors.unsecured, fontSize: 14, fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
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
  static const _networkColor = Color(0xFF00B4D8);
  bool _editingName = false;
  late TextEditingController _nameCtrl;

  Color get _color {
    switch (widget.device.type) {
      case DeviceType.light:          return AppColors.lightColor;
      case DeviceType.blind:          return AppColors.primary;
      case DeviceType.airConditioner:
      case DeviceType.waterHeater:    return AppColors.acColor;
      case DeviceType.router:
      case DeviceType.gateway:        return _networkColor;
      case DeviceType.circuitBreaker: return const Color(0xFF7BB8FF);
      case DeviceType.solar:          return const Color(0xFFFFB300);
      case DeviceType.smokeSensor:    return const Color(0xFFFF6B35);
      case DeviceType.energyMeter:    return const Color(0xFFFFD600);
      default:                        return AppColors.plugColor;
    }
  }

  IconData _iconFor(DeviceType type) {
    switch (type) {
      case DeviceType.light:          return Icons.lightbulb_outlined;
      case DeviceType.blind:          return Icons.blinds_outlined;
      case DeviceType.airConditioner: return Icons.hvac;
      case DeviceType.smartPlug:      return Icons.power_outlined;
      case DeviceType.smartSwitch:    return Icons.toggle_on_outlined;
      case DeviceType.motionSensor:   return Icons.sensors_outlined;
      case DeviceType.doorSensor:     return Icons.sensor_door_outlined;
      case DeviceType.windowSensor:   return Icons.window_outlined;
      case DeviceType.waterHeater:    return Icons.water_drop_outlined;
      case DeviceType.camera:         return Icons.videocam_outlined;
      case DeviceType.router:         return Icons.router_outlined;
      case DeviceType.gateway:        return Icons.hub_outlined;
      case DeviceType.circuitBreaker: return Icons.electrical_services;
      case DeviceType.solar:          return Icons.wb_sunny_outlined;
      case DeviceType.smokeSensor:    return Icons.local_fire_department_outlined;
      case DeviceType.energyMeter:    return Icons.bolt_outlined;
      case DeviceType.smartLock:      return Icons.lock_outline;
      case DeviceType.gasSensor:      return Icons.cloud_outlined;
      case DeviceType.waterLeakSensor:return Icons.water_damage_outlined;
      case DeviceType.matterDevice:   return Icons.hexagon_outlined;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final s = widget.s;
    final color = _color;
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
                child: Icon(_iconFor(d.type), color: color, size: 24),
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
                              child: Icon(Icons.check,
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
                              child: Icon(Icons.close,
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
                                Text(d.room, style: TextStyle(
                                    color: context.tText2(0.4),
                                    fontSize: 13)),
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
                              child: Icon(Icons.edit_outlined,
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
                icon: Icon(Icons.radar, size: 18),
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
                      Icon(Icons.thermostat_outlined, color: color, size: 20),
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
                        margin: const EdgeInsets.only(left: 6),
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
                                  ? Icons.wifi
                                  : m == 'IR'
                                      ? Icons.settings_remote
                                      : Icons.sensors,
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

            // Mode (cool / heat / fan / dry / auto)
            _AcChoiceRow(
              label: s.acMode,
              color: color,
              selected: d.attributes['mode'] as String? ?? 'cool',
              options: [
                ('cool', s.modeCool, Icons.ac_unit),
                ('heat', s.modeHeat, Icons.wb_sunny_outlined),
                ('fan', s.modeFan, Icons.air),
                ('dry', s.modeDry, Icons.water_drop_outlined),
                ('auto', s.modeAuto, Icons.autorenew),
              ],
              onSelect: (v) {
                widget.state.setDeviceAttribute(d.id, 'mode', v);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // Fan speed
            _AcChoiceRow(
              label: s.acFanSpeed,
              color: color,
              selected: d.attributes['fan'] as String? ?? 'auto',
              options: [
                ('low', s.fanLow, Icons.signal_cellular_alt_1_bar),
                ('med', s.fanMed, Icons.signal_cellular_alt_2_bar),
                ('high', s.fanHigh, Icons.signal_cellular_alt),
                ('auto', s.modeAuto, Icons.autorenew),
              ],
              onSelect: (v) {
                widget.state.setDeviceAttribute(d.id, 'fan', v);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // Swing toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.tText2(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.tText2(0.08)),
              ),
              child: Row(children: [
                Icon(Icons.swap_vert, color: color, size: 20),
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
            ),
            const SizedBox(height: 12),

            _SliderRow(
              label: '${s.deviceTemp}: ${d.attributes['temperature'] ?? 22}°C',
              value: (d.attributes['temperature'] as int? ?? 22).toDouble(),
              min: 16, max: 30, divisions: 14, color: color,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'temperature', v.toInt());
                setState(() {});
              },
            ),
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
                        Icon(Icons.lightbulb, color: d.isOn ? color : context.tText2(0.38), size: 18),
                        const SizedBox(width: 8),
                        Text('הדלק',
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
                        Icon(Icons.lightbulb_outline, color: !d.isOn ? context.tText2(0.7) : context.tText2(0.24), size: 18),
                        const SizedBox(width: 8),
                        Text('כבה',
                          style: TextStyle(
                            color: !d.isOn ? context.tText2(0.7) : context.tText2(0.24),
                            fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
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
          // Blind position
          if (d.type == DeviceType.blind) ...[
            _SliderRow(
              label: '${s.devicePosition}: ${d.attributes['position'] ?? 50}%',
              value: (d.attributes['position'] as int? ?? 50).toDouble(),
              min: 0, max: 100, divisions: 10, color: color,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'position', v.toInt());
                setState(() {});
              },
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
                Icon(Icons.bolt, color: AppColors.lightColor, size: 16),
                const SizedBox(width: 8),
                Text('${d.attributes['power'] ?? 0}W',
                    style: TextStyle(
                        color: context.tText, fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
          // Sensor info
          if (d.type == DeviceType.motionSensor ||
              d.type == DeviceType.doorSensor ||
              d.type == DeviceType.windowSensor) ...[
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.tText2(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.battery_full, color: AppColors.secured, size: 14),
                  const SizedBox(width: 5),
                  Text('${d.attributes['battery'] ?? 100}%',
                      style: TextStyle(color: AppColors.secured, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.tText2(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    d.type == DeviceType.motionSensor
                        ? Icons.sensors
                        : d.type == DeviceType.doorSensor
                            ? Icons.sensor_door
                            : Icons.window,
                    color: (d.attributes['detected'] == true ||
                            d.attributes['open'] == true)
                        ? AppColors.unsecured
                        : context.tText2(0.38),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    (d.attributes['detected'] == true ||
                            d.attributes['open'] == true)
                        ? s.activeStatus
                        : s.normalStatus,
                    style: TextStyle(
                      color: (d.attributes['detected'] == true ||
                              d.attributes['open'] == true)
                          ? AppColors.unsecured
                          : context.tText2(0.54),
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
            ]),
          ],

          const SizedBox(height: 8),
        ],
      ),
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
        label: ecoLabel, icon: Icons.eco,
        selected: selected == 'eco',
        color: AppColors.secured,
        onTap: () => onChanged('eco'),
      ),
      const SizedBox(width: 8),
      _ModeBtn(
        label: fullLabel, icon: Icons.local_fire_department,
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
