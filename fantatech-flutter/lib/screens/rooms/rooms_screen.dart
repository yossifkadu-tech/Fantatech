import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';

// ── Room icon palette — user can pick one ────────────────────
const _kIconChoices = [
  (Icons.weekend,          0xe318), // sofa / living room
  (Icons.hotel,            0xe239), // bedroom
  (Icons.kitchen,          0xf04c3),// kitchen
  (Icons.child_care,       0xe556), // kids room
  (Icons.balcony,          0xe3a3), // balcony
  (Icons.garage,           0xe1b3), // garage
  (Icons.pool,             0xe0ee), // pool
  (Icons.fitness_center,   0xe1d5), // gym
  (Icons.bathtub_outlined, 0xf05b3),// bathroom
  (Icons.desk_outlined,    0xef53), // office/study
  (Icons.dining,           0xe15b), // dining room
  (Icons.outdoor_grill_outlined, 0xefb9), // garden / outdoor
];

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        state.isRtl
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.roomManagement,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Add room button
                  GestureDetector(
                    onTap: () => _showRoomDialog(context, state, s),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.add,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Room count ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(children: [
                Text(
                  '${state.rooms.length} ${s.roomsUnit}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 12,
                  ),
                ),
              ]),
            ),

            // ── Rooms list ──────────────────────────────────
            Expanded(
              child: state.rooms.isEmpty
                  ? _EmptyRooms(onAdd: () => _showRoomDialog(context, state, s))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      itemCount: state.rooms.length,
                      onReorder: (oldIdx, newIdx) {
                        // ReorderableListView quirk
                        if (newIdx > oldIdx) newIdx--;
                        final rooms = List<Map<String, dynamic>>.from(state.rooms);
                        final item = rooms.removeAt(oldIdx);
                        rooms.insert(newIdx, item);
                        for (var i = 0; i < rooms.length; i++) {
                          state.editRoom(i, rooms[i]['name'], rooms[i]['icon']);
                        }
                      },
                      itemBuilder: (ctx, i) {
                        final room = state.rooms[i];
                        final rawName = room['name'] as String;
                        final devicesInRoom = state.devices
                            .where((d) => d.room == room['name'])
                            .toList();
                        return _RoomTile(
                          key: ValueKey('room_$i'),
                          name: state.strings.translateRoomKey(rawName),
                          iconCodePoint: room['icon'] as int,
                          deviceCount: devicesInRoom.length,
                          onTap: () => _showRoomDevices(
                              context, state.strings.translateRoomKey(rawName),
                              room['icon'] as int, devicesInRoom),
                          onEdit: () => _showRoomDialog(
                              context, state, s,
                              editIndex: i,
                              initialName: rawName,
                              initialIcon: room['icon']),
                          onDelete: () =>
                              _confirmDelete(context, state, s, i,
                                  state.strings.translateRoomKey(rawName)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDevices(
    BuildContext context,
    String roomName,
    int iconCodePoint,
    List<Device> devices,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RoomDevicesSheet(
        roomName: roomName,
        iconCodePoint: iconCodePoint,
        devices: devices,
      ),
    );
  }

  void _showRoomDialog(
    BuildContext context,
    AppState state,
    dynamic s, {
    int? editIndex,
    String initialName = '',
    int initialIcon = 0xe318,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RoomEditSheet(
        s: s,
        initialName: initialName,
        initialIconCode: initialIcon,
        isEdit: editIndex != null,
        onSave: (name, iconCode) {
          if (editIndex != null) {
            state.editRoom(editIndex, name, iconCode);
          } else {
            state.addRoom(name, iconCode);
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(editIndex != null ? s.roomEdited : s.roomAdded),
            backgroundColor: AppColors.secured,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, dynamic s,
      int index, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              '${s.deleteRoom} "$name"?',
              style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text(s.cancel,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    state.deleteRoom(index);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(s.roomDeleted),
                      backgroundColor: AppColors.unsecured,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.unsecured.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.unsecured.withValues(alpha: 0.35))),
                    child: Center(
                        child: Text(s.delete,
                            style: const TextStyle(
                                color: AppColors.unsecured,
                                fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Room tile
// ─────────────────────────────────────────────────────────────
class _RoomTile extends StatelessWidget {
  final String name;
  final int iconCodePoint;
  final int deviceCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomTile({
    super.key,
    required this.name,
    required this.iconCodePoint,
    required this.deviceCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');
    final s = context.watch<AppState>().strings;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          // Name + device count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(
                  '$deviceCount ${s.devicesTitle}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 12),
                ),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 34, height: 34,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white54, size: 16),
            ),
          ),

          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.unsecured.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.unsecured, size: 16),
            ),
          ),

          // Drag handle
          const SizedBox(width: 8),
          const Icon(Icons.drag_handle_rounded,
              color: Colors.white24, size: 18),
        ],
      ),
    ),
    ); // GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────
// Room devices sheet
// ─────────────────────────────────────────────────────────────
class _RoomDevicesSheet extends StatelessWidget {
  final String roomName;
  final int iconCodePoint;
  final List<Device> devices;

  const _RoomDevicesSheet({
    required this.roomName,
    required this.iconCodePoint,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    final icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: room icon + name
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    Text(
                      '${devices.length} ${s.devicesTitle}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Device list or empty state
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.devices_outlined,
                                color: Colors.white24, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s.noDevicesInRoom,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      itemCount: devices.length,
                      itemBuilder: (ctx, i) {
                        final d = devices[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: (d.isOn
                                        ? AppColors.primary
                                        : Colors.white38)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForType(d.type),
                                color: d.isOn
                                    ? AppColors.primary
                                    : Colors.white38,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(d.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: d.isOn
                                    ? AppColors.secured
                                    : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(DeviceType type) {
    switch (type) {
      case DeviceType.light:         return Icons.lightbulb_outline;
      case DeviceType.airConditioner: return Icons.ac_unit;
      case DeviceType.blind:         return Icons.blinds_outlined;
      case DeviceType.smartPlug:     return Icons.power_outlined;
      case DeviceType.motionSensor:  return Icons.sensors_outlined;
      case DeviceType.doorSensor:    return Icons.sensor_door_outlined;
      case DeviceType.waterHeater:   return Icons.water_drop_outlined;
      case DeviceType.camera:        return Icons.videocam_outlined;
      case DeviceType.router:        return Icons.router_outlined;
      case DeviceType.gateway:       return Icons.hub_outlined;
      default:                       return Icons.devices_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Room edit / add sheet
// ─────────────────────────────────────────────────────────────
class _RoomEditSheet extends StatefulWidget {
  final dynamic s;
  final String initialName;
  final int initialIconCode;
  final bool isEdit;
  final void Function(String name, int iconCode) onSave;

  const _RoomEditSheet({
    required this.s,
    required this.initialName,
    required this.initialIconCode,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<_RoomEditSheet> createState() => _RoomEditSheetState();
}

class _RoomEditSheetState extends State<_RoomEditSheet> {
  late TextEditingController _nameCtrl;
  late int _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _selectedIcon = widget.initialIconCode;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            widget.isEdit ? s.editRoom : s.addRoom,
            style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Name input
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: s.roomNameHint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.30)),
              prefixIcon: const Icon(Icons.drive_file_rename_outline,
                  color: Colors.white38, size: 18),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Icon picker
          Text(
            s.roomIconLabel,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kIconChoices.map((entry) {
              final (iconData, code) = entry;
              final selected = _selectedIcon == code;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                      width: selected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: selected ? AppColors.primary : Colors.white38,
                    size: 20,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  widget.onSave(name, _selectedIcon);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                s.save,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyRooms extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyRooms({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Icon(Icons.meeting_room_outlined,
                color: Colors.white24, size: 34),
          ),
          const SizedBox(height: 16),
          Text(s.roomManagement,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(s.addRoom,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
