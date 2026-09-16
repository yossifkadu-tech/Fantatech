import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/strings.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../models/device_capabilities.dart';
import '../models/media_module.dart';
import '../services/gateways/clients/tuya_cloud_client.dart';
import '../theme/app_theme.dart';
import '../theme/device_icons.dart';
import 'schedule_sheet.dart';

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
  // Optional — when provided, an "on/off schedule" option appears in the
  // sheet, opening the shared schedule sheet.
  VoidCallback? onSchedule,
  // Optional — when both provided, an "advanced settings" section lists
  // every raw Tuya DP this device reported (code → current value) with an
  // inline editor per row, calling onSetTuyaDp(code, newValue) to apply.
  // Vendor/model-specific (sensitivity, delay, detection range, ...) — no
  // normalized FantaTech capability covers these, so they're surfaced as-is
  // rather than guessed at.
  Map<String, dynamic>? tuyaDps,
  void Function(String code, dynamic value)? onSetTuyaDp,
  // Optional — when provided, shows a "refresh from Tuya" action that
  // re-fetches this device's full current DP set on demand (the bulk
  // import list can be a trimmed subset for some categories/models) and
  // returns the fresh map, or null on failure.
  Future<Map<String, dynamic>?> Function()? onRefreshTuyaDps,
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
      onSchedule: onSchedule,
      tuyaDps: tuyaDps,
      onSetTuyaDp: onSetTuyaDp,
      onRefreshTuyaDps: onRefreshTuyaDps,
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
    rooms: state.rooms
        .map((r) => r['name'] as String? ?? '')
        .where((r) => r.isNotEmpty)
        .toList(),
    currentRoom: device.room,
    onAssignRoom: (room) => state.updateDeviceRoom(device.id, room),
    ipAddress: device.attributes['ip'] as String?,
    onSchedule: DeviceCapabilities.of(device).contains(DeviceCapability.onOff)
        ? () => showScheduleSheet(context,
            device: device, color: DeviceIcons.color(device.type))
        : null,
    tuyaDps: (device.attributes['tuyaDps'] as Map?)?.cast<String, dynamic>(),
    onSetTuyaDp: device.id.startsWith('tuya_')
        ? (code, value) => state.setTuyaDp(device.id, code, value)
        : null,
    onRefreshTuyaDps: device.id.startsWith('tuya_')
        ? () async {
            final ok = await state.refreshTuyaDps(device.id);
            return ok
                ? (device.attributes['tuyaDps'] as Map?)
                    ?.cast<String, dynamic>()
                : null;
          }
        : null,
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
    MediaDeviceKind.tv => Symbols.tv,
    MediaDeviceKind.soundbar => Symbols.speaker_group,
    MediaDeviceKind.speaker => Symbols.speaker,
    _ => Symbols.cast,
  };
  return showEntityEditSheet(
    context,
    currentName: device.name,
    icon: icon,
    color: AppColors.primary,
    s: state.strings,
    onRename: (name) => state.updateMediaDeviceName(device.id, name),
    onDelete: () => state.removeMediaDevice(device.id),
    rooms: state.rooms
        .map((r) => r['name'] as String? ?? '')
        .where((r) => r.isNotEmpty)
        .toList(),
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
  final VoidCallback? onSchedule;
  final Map<String, dynamic>? tuyaDps;
  final void Function(String code, dynamic value)? onSetTuyaDp;
  final Future<Map<String, dynamic>?> Function()? onRefreshTuyaDps;

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
    this.onSchedule,
    this.tuyaDps,
    this.onSetTuyaDp,
    this.onRefreshTuyaDps,
  });

  @override
  State<_EntityEditSheet> createState() => _EntityEditSheetState();
}

class _EntityEditSheetState extends State<_EntityEditSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.currentName);
  late Map<String, dynamic>? _tuyaDps = widget.tuyaDps;
  bool _refreshingTuya = false;
  // Populated after a refresh — the exact request/response Tuya's API gave
  // (see TuyaCloudClient.lastStatusRawResponse), shown when the DP list
  // comes back empty so "genuinely no settings" can be told apart from a
  // masked API error instead of both looking identical.
  String? _tuyaDiagnostic;

  Future<void> _refreshTuyaDps() async {
    final cb = widget.onRefreshTuyaDps;
    if (cb == null || _refreshingTuya) return;
    setState(() => _refreshingTuya = true);
    final fresh = await cb();
    final diagnostic = TuyaCloudClient.lastStatusRawResponse;
    if (!mounted) return;
    setState(() {
      _refreshingTuya = false;
      if (fresh != null) _tuyaDps = fresh;
      _tuyaDiagnostic = diagnostic;
    });
    if (fresh == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('לא הצלחנו לרענן מ-Tuya — בדוק חיבור לאינטרנט ונסה שוב'),
        backgroundColor: AppColors.unsecured,
      ));
    }
  }

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
        title: Text(widget.currentName,
            style: TextStyle(color: sheetContext.tText)),
        content: Text(s.deviceDeleteConfirm,
            style: TextStyle(color: sheetContext.tText2(0.65))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: TextStyle(color: sheetContext.tText2(0.6))),
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
          SnackBar(
              content: Text('שגיאה בשיוך חדר: $e'),
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
      // Scrollable — the Tuya advanced-settings section (esp. its raw
      // diagnostic dump) has unbounded height, unlike the rest of this
      // sheet's fixed-size rows; without this it silently overflowed the
      // screen instead of scrolling.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: context.tText2(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                width: 40,
                height: 40,
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
                    style:
                        TextStyle(color: context.tText2(0.45), fontSize: 12)),
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
                  color: context.tText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
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
                  borderSide: BorderSide(
                      color: color.withValues(alpha: 0.50), width: 1.5),
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
                        SnackBar(
                            content: Text(s.deviceRenamed),
                            backgroundColor: color),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(12)),
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
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(12)),
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
                      Icon(Symbols.meeting_room,
                          color: context.tText2(0.6), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.assignRoom,
                            style: TextStyle(
                                color: context.tText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        (widget.currentRoom == null ||
                                widget.currentRoom!.isEmpty)
                            ? s.noRoom
                            : s.translateRoomKey(widget.currentRoom!),
                        style: TextStyle(
                            color: context.tText2(0.45), fontSize: 13),
                      ),
                      Icon(Symbols.chevron_right,
                          color: context.tText2(0.35), size: 16),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onSchedule != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.onSchedule,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.tText2(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.schedule,
                          color: context.tText2(0.6), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.boilerSchedule,
                            style: TextStyle(
                                color: context.tText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      Icon(Symbols.chevron_right,
                          color: context.tText2(0.35), size: 16),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onSetTuyaDp != null ||
                widget.onRefreshTuyaDps != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text('הגדרות מתקדמות (Tuya)',
                      style: TextStyle(
                          color: context.tText2(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                if (widget.onRefreshTuyaDps != null)
                  GestureDetector(
                    onTap: _refreshingTuya ? null : _refreshTuyaDps,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_refreshingTuya)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: color),
                          )
                        else
                          Icon(Symbols.refresh, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text('רענן מ-Tuya',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(
                  'ערכים גולמיים שהמכשיר מדווח לענן Tuya — לא כל שורה בהכרח ניתנת לעריכה.',
                  style: TextStyle(color: context.tText2(0.4), fontSize: 10.5)),
              const SizedBox(height: 8),
              if (_tuyaDps == null || _tuyaDps!.isEmpty) ...[
                Text(
                    _refreshingTuya
                        ? 'טוען...'
                        : 'לא נמצאו הגדרות נוספות למכשיר הזה.',
                    style: TextStyle(color: context.tText2(0.4), fontSize: 12)),
                if (!_refreshingTuya &&
                    _tuyaDiagnostic != null &&
                    _tuyaDiagnostic!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('פרטים טכניים (לצורך אבחון):',
                      style: TextStyle(
                          color: context.tText2(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  SelectableText(_tuyaDiagnostic!,
                      style: TextStyle(
                          color: context.tText2(0.4),
                          fontSize: 9.5,
                          fontFamily: 'monospace')),
                ],
              ] else if (widget.onSetTuyaDp != null)
                ..._tuyaDps!.entries.map((e) => _TuyaDpRow(
                      code: e.key,
                      value: e.value,
                      color: color,
                      onSet: widget.onSetTuyaDp!,
                    )),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.unsecured.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.unsecured.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.delete,
                        color: AppColors.unsecured, size: 17),
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TuyaDpRow — one raw Tuya DP (data point), editable in place. A bool value
// gets a Switch; anything else (num/String) gets a text field + apply
// button, sent back as-is if it parses as a number, otherwise as a string —
// Tuya rejects a command whose value type doesn't match what it expects for
// that code, so this can't validate further without knowing the code's
// meaning ahead of time (see tuyaDps' doc comment on showEntityEditSheet).
// ─────────────────────────────────────────────────────────────────────────────
class _TuyaDpRow extends StatefulWidget {
  final String code;
  final dynamic value;
  final Color color;
  final void Function(String code, dynamic value) onSet;
  const _TuyaDpRow({
    required this.code,
    required this.value,
    required this.color,
    required this.onSet,
  });

  @override
  State<_TuyaDpRow> createState() => _TuyaDpRowState();
}

class _TuyaDpRowState extends State<_TuyaDpRow> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value?.toString() ?? '');
  bool _saving = false;

  Future<void> _save(dynamic value) async {
    setState(() => _saving = true);
    widget.onSet(widget.code, value);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isBool = widget.value is bool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(widget.code,
                style: TextStyle(
                    color: context.tText2(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: isBool
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Switch(
                      value: widget.value == true,
                      activeThumbColor: widget.color,
                      onChanged: _saving ? null : (v) => _save(v),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          enabled: !_saving,
                          style: TextStyle(color: context.tText, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: context.tText2(0.05),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _saving
                            ? null
                            : () {
                                final text = _ctrl.text.trim();
                                final n = num.tryParse(text);
                                _save(n ?? text);
                              },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: _saving
                              ? Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: widget.color),
                                )
                              : Icon(Symbols.check,
                                  color: widget.color, size: 16),
                        ),
                      ),
                    ],
                  ),
          ),
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
          left: 20,
          right: 20,
          top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                width: 42,
                height: 42,
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
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color =
        iconColor ?? (selected ? AppColors.primary : context.tText2(0.45));
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
            Icon(Symbols.check_circle, color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }
}
