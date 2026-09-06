import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/strings.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../models/media_module.dart';
import '../theme/app_theme.dart';
import '../theme/device_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showEntityEditSheet — the single, app-wide rename/delete sheet. Generic
// over "anything with a name that can be renamed and removed" so every
// entity kind (Device, Camera, …) gets identical behavior — and the same
// confirm-before-delete step — through one implementation.
//
// Prefer the typed wrappers below ([showDeviceEditSheet], [showCameraEditSheet])
// at call sites; they exist so callers don't have to re-derive icon/color/
// strings each time.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showEntityEditSheet(
  BuildContext context, {
  required String currentName,
  required IconData icon,
  required Color color,
  required S s,
  required void Function(String newName) onRename,
  required VoidCallback onDelete,
  // Optional — when provided, an "assign room" option appears in the sheet.
  List<String>? rooms,
  String? currentRoom,
  void Function(String room)? onAssignRoom,
  // Optional — when provided, shows the device's real network address here
  // (edit sheet only — the card itself stays free of raw IPs).
  String? ipAddress,
  // TEMPORARY — see the debugInfo build in showDeviceEditSheet.
  String? debugInfo,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EntityEditSheet(
      currentName: currentName,
      icon: icon,
      color: color,
      s: s,
      onRename: onRename,
      onDelete: onDelete,
      rooms: rooms,
      currentRoom: currentRoom,
      onAssignRoom: onAssignRoom,
      ipAddress: ipAddress,
      debugInfo: debugInfo,
    ),
  );
}

/// Rename/delete sheet for a [Device] — wraps [showEntityEditSheet] with
/// the device's own icon, accent color, and app-state mutations.
Future<void> showDeviceEditSheet(
  BuildContext context, {
  required Device device,
  required AppState state,
}) {
  return showEntityEditSheet(
    context,
    currentName: device.name,
    icon: DeviceIcons.forDevice(device),
    color: DeviceIcons.color(device.type),
    s: state.strings,
    onRename: (name) => state.updateDeviceName(device.id, name),
    onDelete: () => state.removeDevice(device.id),
    rooms: state.rooms.map((r) => r['name'] as String? ?? '')
        .where((r) => r.isNotEmpty).toList(),
    currentRoom: device.room,
    onAssignRoom: (room) => state.updateDeviceRoom(device.id, room),
    ipAddress: device.attributes['ip'] as String?,
    // TEMPORARY diagnostic — shows what's actually stored for a device
    // that's misbehaving, so we don't have to keep guessing. Remove once
    // the home-screen-count issue is confirmed fixed.
    debugInfo: 'id: ${device.id}\n'
        'type: ${device.type.name}\n'
        'source: ${device.source}\n'
        'attrs: ${device.attributes.keys.join(', ')}',
  );
}

/// Rename/delete/assign-room sheet for a [MediaDevice] — wraps
/// [showEntityEditSheet] with a kind-appropriate icon and app-state
/// mutations.
Future<void> showMediaEditSheet(
  BuildContext context, {
  required MediaDevice device,
  required AppState state,
}) {
  final icon = switch (device.kind) {
    MediaDeviceKind.tv        => Symbols.tv,
    MediaDeviceKind.soundbar  => Symbols.speaker_group,
    MediaDeviceKind.speaker   => Symbols.speaker,
    _                         => Symbols.cast,
  };
  return showEntityEditSheet(
    context,
    currentName: device.name,
    icon: icon,
    color: AppColors.primary,
    s: state.strings,
    onRename: (name) => state.updateMediaDeviceName(device.id, name),
    onDelete: () => state.removeMediaDevice(device.id),
    rooms: state.rooms.map((r) => r['name'] as String? ?? '')
        .where((r) => r.isNotEmpty).toList(),
    currentRoom: device.room,
    onAssignRoom: (room) => state.updateMediaDeviceRoom(device.id, room),
  );
}

/// Rename/delete sheet for a [Camera] — wraps [showEntityEditSheet] with
/// the camera icon and app-state mutations.
Future<void> showCameraEditSheet(
  BuildContext context, {
  required Camera camera,
  required AppState state,
}) {
  return showEntityEditSheet(
    context,
    currentName: camera.name,
    icon: Symbols.videocam,
    color: AppColors.cameraColor,
    s: state.strings,
    onRename: (name) => state.updateCameraName(camera.id, name),
    onDelete: () => state.removeCamera(camera.id),
  );
}

class _EntityEditSheet extends StatefulWidget {
  final String currentName;
  final IconData icon;
  final Color color;
  final S s;
  final void Function(String newName) onRename;
  final VoidCallback onDelete;
  final List<String>? rooms;
  final String? currentRoom;
  final void Function(String room)? onAssignRoom;
  final String? ipAddress;
  final String? debugInfo;

  const _EntityEditSheet({
    required this.currentName,
    required this.icon,
    required this.color,
    required this.s,
    required this.onRename,
    required this.onDelete,
    this.rooms,
    this.currentRoom,
    this.onAssignRoom,
    this.ipAddress,
    this.debugInfo,
  });

  @override
  State<_EntityEditSheet> createState() => _EntityEditSheetState();
}

class _EntityEditSheetState extends State<_EntityEditSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext sheetContext) async {
    final s = widget.s;
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: sheetContext.tCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.currentName, style: TextStyle(color: sheetContext.tText)),
        content: Text(s.deviceDeleteConfirm,
            style: TextStyle(color: sheetContext.tText2(0.65))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: TextStyle(color: sheetContext.tText2(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: const TextStyle(
                    color: AppColors.unsecured, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete();
      if (sheetContext.mounted) Navigator.pop(sheetContext);
    }
  }

  Future<void> _showRoomPicker(BuildContext sheetContext) async {
    // TEMPORARY: wrapped in try/catch with a visible SnackBar on failure —
    // a user report said this button does nothing on tap, which in release
    // mode is exactly what an uncaught exception here would look like
    // (silently swallowed, no crash, no picker). This turns that invisible
    // failure into something reportable instead of guessing further.
    try {
      final s = widget.s;
      final rooms = widget.rooms ?? const [];
      final picked = await showModalBottomSheet<String>(
        context: sheetContext,
        backgroundColor: sheetContext.tCard,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (_) => _RoomPickerSheet(
            s: s, rooms: rooms, currentRoom: widget.currentRoom ?? ''),
      );
      if (picked != null && sheetContext.mounted) {
        widget.onAssignRoom?.call(picked);
        Navigator.pop(sheetContext);
      }
    } catch (e, st) {
      debugPrint('[_showRoomPicker] error: $e\n$st');
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          SnackBar(content: Text('שגיאה בשיוך חדר: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final color = widget.color;

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: context.tText2(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.deviceNameLabel,
                style: TextStyle(
                    color: context.tText2(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ]),
          if (widget.ipAddress != null && widget.ipAddress!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Symbols.lan, color: context.tText2(0.4), size: 15),
              const SizedBox(width: 6),
              Text('${s.ipAddressLabel}: ',
                  style: TextStyle(color: context.tText2(0.45), fontSize: 12)),
              Text(widget.ipAddress!,
                  style: TextStyle(
                      color: context.tText2(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: TextStyle(
                color: context.tText, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.tText2(0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha: 0.50), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final name = _ctrl.text.trim();
                  if (name.isNotEmpty && name != widget.currentName) {
                    widget.onRename(name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.deviceRenamed), backgroundColor: color),
                    );
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  height: 44,
                  decoration:
                      BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(s.save,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: context.tText2(0.07), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(s.cancel,
                        style: TextStyle(
                            color: context.tText2(0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ]),
          if (widget.onAssignRoom != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showRoomPicker(context),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.tText2(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.meeting_room, color: context.tText2(0.6), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.assignRoom,
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      (widget.currentRoom == null || widget.currentRoom!.isEmpty)
                          ? s.noRoom
                          : s.translateRoomKey(widget.currentRoom!),
                      style: TextStyle(color: context.tText2(0.45), fontSize: 13),
                    ),
                    Icon(Symbols.chevron_right, color: context.tText2(0.35), size: 16),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.unsecured.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.unsecured.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.delete, color: AppColors.unsecured, size: 17),
                  const SizedBox(width: 8),
                  Text(s.delete,
                      style: const TextStyle(
                          color: AppColors.unsecured,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          if (widget.debugInfo != null) ...[
            const SizedBox(height: 14),
            SelectableText(widget.debugInfo!,
                style: TextStyle(
                    color: context.tText2(0.4),
                    fontSize: 10,
                    fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoomPickerSheet — bottom sheet listing existing rooms plus a "new room"
// entry, used by the "assign room" option above.
// ─────────────────────────────────────────────────────────────────────────────
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
