import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/strings.dart';
import '../models/app_state.dart';
import '../models/device.dart';
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

  const _EntityEditSheet({
    required this.currentName,
    required this.icon,
    required this.color,
    required this.s,
    required this.onRename,
    required this.onDelete,
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
        ],
      ),
    );
  }
}
