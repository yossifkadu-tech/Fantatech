import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_nav.dart';
import 'room_setup_screen.dart';

Color _colorForRoom(String rawKey) {
  final k = rawKey.toLowerCase();
  if (k.contains('bedroom') || k.contains('חדר שינה') || k.contains('שינה')) {
    return const Color(0xFF26C6DA);
  }
  if (k.contains('living') || k.contains('סלון')) return const Color(0xFF7C4DFF);
  if (k.contains('kitchen') || k.contains('מטבח')) return const Color(0xFFFF7043);
  if (k.contains('garden') || k.contains('גינה') || k.contains('חצר')) {
    return const Color(0xFF66BB6A);
  }
  if (k.contains('bath') || k.contains('שירות') || k.contains('מקלח') ||
      k.contains('אמבט')) return const Color(0xFF29B6F6);
  if (k.contains('kids') || k.contains('ילד') || k.contains('ילדים')) {
    return const Color(0xFFFFB300);
  }
  return AppColors.primary;
}

// ── Room icon palette — user can pick one ────────────────────
const _kIconChoices = [
  (Symbols.weekend,          0xe318), // sofa / living room
  (Symbols.hotel,            0xe239), // bedroom
  (Symbols.kitchen,          0xf04c3),// kitchen
  (Symbols.child_care,       0xe556), // kids room
  (Symbols.balcony,          0xe3a3), // balcony
  (Symbols.garage,           0xe1b3), // garage
  (Symbols.pool,             0xe0ee), // pool
  (Symbols.fitness_center,   0xe1d5), // gym
  (Symbols.bathtub, 0xf05b3),// bathroom
  (Symbols.desk,    0xef53), // office/study
  (Symbols.dining,           0xe15b), // dining room
  (Symbols.outdoor_grill, 0xefb9), // garden / outdoor
];

// Const lookup map so Flutter's icon tree-shaker can statically enumerate
// every icon used at runtime — avoids non-const IconData invocations.
const _kIconMap = <int, IconData>{
  0xe318: Symbols.weekend,
  0xe239: Symbols.hotel,
  0xf04c3: Symbols.kitchen,
  0xe556: Symbols.child_care,
  0xe3a3: Symbols.balcony,
  0xe1b3: Symbols.garage,
  0xe0ee: Symbols.pool,
  0xe1d5: Symbols.fitness_center,
  0xf05b3: Symbols.bathtub,
  0xef53: Symbols.desk,
  0xe15b: Symbols.dining,
  0xefb9: Symbols.outdoor_grill,
};

IconData _resolveIcon(int cp) => _kIconMap[cp] ?? Symbols.home;

class RoomsScreen extends StatefulWidget {
  final bool openAddDialog;
  const RoomsScreen({super.key, this.openAddDialog = false});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final state = context.read<AppState>();
          _showRoomDialog(context, state, state.strings);
        }
      });
    }
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  const FtBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.roomManagement,
                      style: TextStyle(
                        color: context.tText,
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
                      child: Icon(Symbols.add,
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
                    color: context.tText2(0.40),
                    fontSize: 12,
                  ),
                ),
              ]),
            ),

            // ── Grouped + root rooms list ────────────────────
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: _listAnim, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: _listAnim, curve: Curves.easeOut)),
                  child: state.rooms.isEmpty && state.roomGroups.isEmpty
                  ? _EmptyRooms(onAdd: () => _showRoomDialog(context, state, s))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      children: [
                        // Groups first
                        for (final group in state.roomGroups) ...[
                          _GroupSection(
                            group:   group,
                            rooms:   state.roomsInGroup(
                                         group['id'] as String),
                            allRooms: state.rooms,
                            strings:  s,
                            onAddRoom: () => _showRoomDialog(
                                context, state, s,
                                parentGroupId: group['id'] as String),
                            onToggle: () => state.setRoomGroupCollapsed(
                                group['id'] as String,
                                !(group['collapsed'] as bool? ?? false)),
                            onDeleteGroup: () => _confirmDeleteGroup(
                                context, state, s, group),
                            onEditRoom: (rawName, icon, occupant, globalIdx) =>
                                _showRoomDialog(context, state, s,
                                    editIndex:      globalIdx,
                                    initialName:    rawName,
                                    initialIcon:    icon,
                                    initialOccupant: occupant,
                                    parentGroupId:
                                        group['id'] as String),
                            onDeleteRoom: (globalIdx, displayName) =>
                                _confirmDelete(context, state, s,
                                    globalIdx, displayName),
                            onTapRoom: (rawName, displayName, icon, devices) =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoomSetupScreen(
                                      roomKey:  rawName,
                                      roomName: displayName,
                                      icon: _resolveIcon(icon),
                                      color: _colorForRoom(rawName),
                                    ),
                                  )),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Root rooms (no parentGroupId)
                        if (state.rootRooms.isNotEmpty) ...[
                          if (state.roomGroups.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 2),
                              child: Text(
                                'OTHER ROOMS',
                                style: TextStyle(
                                    color:         context.tText2(0.35),
                                    fontSize:      10,
                                    fontWeight:    FontWeight.w700,
                                    letterSpacing: 0.8),
                              ),
                            ),
                          ],
                          for (final room in state.rootRooms) ...[
                            Builder(builder: (ctx) {
                              final rawName = room['name'] as String;
                              final globalIdx = state.rooms.indexOf(room);
                              final displayName =
                                  s.translateRoomKey(rawName);
                              final devicesInRoom = state.devices
                                  .where((d) => d.room == rawName)
                                  .toList();
                              return _RoomTile(
                                key: ValueKey('root_$globalIdx'),
                                name:          displayName,
                                iconCodePoint: room['icon'] as int,
                                deviceCount:   devicesInRoom.length,
                                devices:       devicesInRoom,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RoomSetupScreen(
                                        roomKey:  rawName,
                                        roomName: displayName,
                                        icon: _resolveIcon(room['icon'] as int),
                                        color: _colorForRoom(rawName),
                                      ),
                                    )),
                                onEdit: () => _showRoomDialog(
                                    context, state, s,
                                    editIndex:      globalIdx,
                                    initialName:    rawName,
                                    initialIcon:    room['icon'] as int,
                                    initialOccupant:
                                        room['occupant'] as String?),
                                onDelete: () => _confirmDelete(
                                    context, state, s,
                                    globalIdx, displayName),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                ),  // SlideTransition
              ),    // FadeTransition
            ),
          ],
        ),
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
    String? initialOccupant,
    String? parentGroupId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RoomEditSheet(
        s: s,
        initialName: initialName,
        initialIconCode: initialIcon,
        initialOccupant: initialOccupant,
        isEdit: editIndex != null,
        onSave: (name, iconCode, occupant) {
          if (editIndex != null) {
            state.editRoom(editIndex, name, iconCode,
                occupant: occupant, parentGroupId: parentGroupId);
          } else {
            state.addRoom(name, iconCode,
                occupant: occupant, parentGroupId: parentGroupId);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, AppState state, dynamic s,
      Map<String, dynamic> group) {
    final groupName = group['name'] as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FtModalHandle(),
            const SizedBox(height: 20),
            Text(
              'Delete group "$groupName"?',
              style: TextStyle(
                color: context.tText, fontSize: 16,
                fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Rooms in this group will be moved to the root list.',
              style: TextStyle(color: context.tText2(0.55), fontSize: 13),
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
                      color: context.tText2(0.07),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text(s.cancel,
                            style: TextStyle(color: context.tText2(0.7)))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    state.deleteRoomGroup(group['id'] as String);
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
                            style: TextStyle(
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

  void _confirmDelete(BuildContext context, AppState state, dynamic s,
      int index, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FtModalHandle(),
            const SizedBox(height: 20),
            Text(
              '${s.deleteRoom} "$name"?',
              style: TextStyle(
                color: context.tText, fontSize: 16, fontWeight: FontWeight.bold),
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
                      color: context.tText2(0.07),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text(s.cancel,
                            style: TextStyle(
                                color: context.tText2(0.7)))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    state.deleteRoom(index);
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
                            style: TextStyle(
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
// Group section
// ─────────────────────────────────────────────────────────────
class _GroupSection extends StatelessWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> allRooms;
  final dynamic strings;
  final VoidCallback onAddRoom;
  final VoidCallback onToggle;
  final VoidCallback onDeleteGroup;
  final void Function(String rawName, int icon, String? occupant, int globalIdx) onEditRoom;
  final void Function(int globalIdx, String displayName) onDeleteRoom;
  final void Function(String rawName, String displayName, int icon, List<Device> devices) onTapRoom;

  const _GroupSection({
    required this.group,
    required this.rooms,
    required this.allRooms,
    required this.strings,
    required this.onAddRoom,
    required this.onToggle,
    required this.onDeleteGroup,
    required this.onEditRoom,
    required this.onDeleteRoom,
    required this.onTapRoom,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final collapsed = group['collapsed'] as bool? ?? false;
    final groupIcon = _resolveIcon(group['icon'] as int);
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Group header ─────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(groupIcon, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group['name'] as String,
                  style: TextStyle(
                    color: context.tText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${rooms.length}',
                style: TextStyle(
                    color: context.tText2(0.45), fontSize: 12),
              ),
              const SizedBox(width: 6),
              // Delete group
              GestureDetector(
                onTap: onDeleteGroup,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Symbols.delete,
                      color: context.tText2(0.35), size: 16),
                ),
              ),
              const SizedBox(width: 2),
              // Collapse toggle
              Icon(
                collapsed
                    ? Symbols.keyboard_arrow_down
                    : Symbols.keyboard_arrow_up,
                color: context.tText2(0.45),
                size: 18,
              ),
            ]),
          ),
        ),
        // ── Rooms inside group ────────────────────────────────
        if (!collapsed) ...[
          const SizedBox(height: 8),
          if (rooms.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final room in rooms)
                    Builder(builder: (ctx) {
                      final rawName     = room['name'] as String;
                      final globalIdx   = allRooms.indexOf(room);
                      final displayName = s.translateRoomKey(rawName);
                      final devicesInRoom = state.devices
                          .where((d) => d.room == rawName)
                          .toList();
                      final icon = _resolveIcon(room['icon'] as int);
                      final tileColor = _colorForRoom(rawName);
                      return GestureDetector(
                        onTap: () => onTapRoom(
                            rawName, displayName, room['icon'] as int, devicesInRoom),
                        onLongPress: () => onEditRoom(rawName,
                            room['icon'] as int,
                            room['occupant'] as String?,
                            globalIdx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: tileColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: tileColor.withValues(alpha: 0.22)),
                          ),
                          child: Row(children: [
                            Icon(icon,
                                color: tileColor, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                    color: context.tText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => onDeleteRoom(
                                  globalIdx, displayName),
                              child: Icon(Symbols.close,
                                  color: context.tText2(0.25),
                                  size: 14),
                            ),
                          ]),
                        ),
                      );
                    }),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // ── Add room button ────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
            child: GestureDetector(
              onTap: onAddRoom,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.add,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      s.addRoom,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
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
  final List<Device> devices;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  _RoomTile({
    super.key,
    required this.name,
    required this.iconCodePoint,
    required this.deviceCount,
    this.devices = const [],
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  /// Live per-room summary chips: temperature, lights on, AC state, motion.
  List<Widget> _summaryChips(BuildContext context, S s) {
    final chips = <Widget>[];

    Widget chip(IconData icon, String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ],
        );

    // Temperature — first device reporting a reading (sensor or AC).
    double? temp;
    for (final d in devices) {
      final t = (d.attributes['currentTemp'] as num?) ??
          (d.type == DeviceType.airConditioner
              ? null
              : d.attributes['temperature'] as num?);
      if (t != null) {
        temp = t.toDouble();
        break;
      }
    }
    if (temp != null) {
      chips.add(chip(Symbols.thermometer, '${temp.round()}°',
          context.tText2(0.55)));
    }

    // Lights on
    final lightsOn = devices
        .where((d) => d.type == DeviceType.light && d.isOn && d.online)
        .length;
    if (lightsOn > 0) {
      chips.add(chip(Symbols.lightbulb, '$lightsOn', AppColors.lightColor));
    }

    // AC — shown whenever the room has one; running mode when on, OFF when not.
    final acs = devices
        .where((d) => d.type == DeviceType.airConditioner)
        .toList();
    if (acs.isNotEmpty) {
      final running =
          acs.where((d) => d.isOn && d.online).toList();
      final on = running.isNotEmpty;
      final String label;
      if (on) {
        label = switch (running.first.attributes['mode'] as String?) {
          'cool'              => s.modeCool,
          'heat'              => s.modeHeat,
          'dry'               => s.modeDry,
          'fan' || 'fan_only' => s.modeFan,
          'auto'              => s.modeAuto,
          _                   => s.breakerOn,
        };
      } else {
        label = s.breakerOff;
      }
      chips.add(chip(Symbols.ac_unit, label,
          on ? AppColors.acColor : context.tText2(0.3)));
    }

    // Motion — only when actively detected.
    final motion = devices.any((d) =>
        d.type == DeviceType.motionSensor &&
        d.online &&
        (d.attributes['detected'] == true));
    if (motion) {
      chips.add(
          chip(Symbols.directions_run, '', AppColors.motionColor));
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _resolveIcon(iconCodePoint);
    final s = context.select<AppState, S>((st) => st.strings);
    final chips = _summaryChips(context, s);

    final roomColor = _colorForRoom(name);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: roomColor.withValues(alpha: 0.55), width: 3),
          top: BorderSide(color: context.tText2(0.07)),
          right: BorderSide(color: context.tText2(0.07)),
          bottom: BorderSide(color: context.tText2(0.07)),
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: roomColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: roomColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Name + live summary (falls back to device count)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (chips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 3,
                      children: chips,
                    ),
                  )
                else
                  Text(
                    '$deviceCount ${s.devicesTitle}',
                    style: TextStyle(
                        color: context.tText2(0.38),
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
              margin: const EdgeInsetsDirectional.only(end: 8),
              decoration: BoxDecoration(
                color: context.tText2(0.06),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Symbols.edit,
                  color: context.tText2(0.54), size: 16),
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
              child: Icon(Symbols.delete,
                  color: AppColors.unsecured, size: 16),
            ),
          ),

          // Drag handle
          const SizedBox(width: 8),
          Icon(Symbols.drag_handle,
              color: context.tText2(0.24), size: 18),
        ],
      ),
    ),
    ); // GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────
// Room edit / add sheet
// ─────────────────────────────────────────────────────────────
class _RoomEditSheet extends StatefulWidget {
  final dynamic s;
  final String initialName;
  final int initialIconCode;
  final String? initialOccupant;
  final bool isEdit;
  final void Function(String name, int iconCode, String? occupant) onSave;

  const _RoomEditSheet({
    required this.s,
    required this.initialName,
    required this.initialIconCode,
    required this.initialOccupant,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<_RoomEditSheet> createState() => _RoomEditSheetState();
}

class _RoomEditSheetState extends State<_RoomEditSheet> {
  late TextEditingController _nameCtrl;
  late int _selectedIcon;
  String? _occupant;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _selectedIcon = widget.initialIconCode;
    _occupant = widget.initialOccupant;
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
          const FtModalHandle(),
          const SizedBox(height: 18),

          // Title
          Text(
            widget.isEdit ? s.editRoom : s.addRoom,
            style: TextStyle(
              color: context.tText, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Name input
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: context.tText, fontSize: 14),
            decoration: InputDecoration(
              hintText: s.roomNameHint,
              hintStyle: TextStyle(color: context.tText2(0.30)),
              prefixIcon: Icon(Symbols.drive_file_rename,
                  color: context.tText2(0.38), size: 18),
              filled: true,
              fillColor: context.tText2(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: context.tText2(0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: context.tText2(0.10)),
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
                color: context.tText2(0.55),
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
                        : context.tText2(0.06),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : context.tText2(0.08),
                      width: selected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: selected ? AppColors.primary : context.tText2(0.38),
                    size: 20,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Occupant (kids / adults) picker
          Text(
            s.roomOccupantLabel,
            style: TextStyle(
                color: context.tText2(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _OccupantChip(
                label: s.occupantNone,
                icon: Symbols.block,
                selected: _occupant == null,
                onTap: () => setState(() => _occupant = null),
              ),
              const SizedBox(width: 8),
              _OccupantChip(
                label: s.occupantKids,
                icon: Symbols.child_care,
                selected: _occupant == 'kids',
                onTap: () => setState(() => _occupant = 'kids'),
              ),
              const SizedBox(width: 8),
              _OccupantChip(
                label: s.occupantAdults,
                icon: Symbols.person,
                selected: _occupant == 'adults',
                onTap: () => setState(() => _occupant = 'adults'),
              ),
            ],
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
                  widget.onSave(name, _selectedIcon, _occupant);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.tText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                s.save,
                style: TextStyle(
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
// Occupant selector chip (kids / adults / none)
// ─────────────────────────────────────────────────────────────
class _OccupantChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _OccupantChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.18)
                : context.tText2(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.tText2(0.08),
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: selected ? AppColors.primary : context.tText2(0.40),
                  size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected ? AppColors.primary : context.tText2(0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
    final s = context.select<AppState, S>((st) => st.strings);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: context.tText2(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: context.tText2(0.07)),
            ),
            child: Icon(Symbols.meeting_room,
                color: context.tText2(0.24), size: 34),
          ),
          const SizedBox(height: 16),
          Text(s.roomManagement,
              style: TextStyle(
                  color: context.tText,
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
                Icon(Symbols.add, color: context.tText, size: 18),
                const SizedBox(width: 8),
                Text(s.addRoom,
                    style: TextStyle(
                        color: context.tText, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
