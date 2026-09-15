import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

import 'device.dart' show Camera;
import '../services/cameras/onvif_ptz_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CameraButtonSpec — built against Camera (models/device.dart), the model
// this app already uses for cameras — NOT DeviceType.camera. There are two
// separate camera representations in the codebase today (a `Camera` class
// for live view/streaming, and `DeviceType.camera` inside the regular
// Device/security-count system); this file only covers the former, which is
// what an actual camera card/player screen works against.
//
// Per project requirement: the PRIMARY button opens the camera's view
// screen — it must never fire a device command. [CameraAction.view] is
// therefore intentionally NOT something [CameraButtonExecutor.execute]
// handles at all: a screen should push CameraPlayerScreen directly on tap,
// with no command layer in between. snapshot/ptz/record are the secondary,
// real actions this file executes.
//
// Backend reality check (rule 9 — no invented API):
//   - snapshot: real — Camera.snapshotUrl, already fetched by the existing
//     camera viewer screens.
//   - ptz: real — services/cameras/onvif_ptz_service.dart (ContinuousMove/
//     Stop over ONVIF SOAP), reused here as-is.
//   - record: NO backend exists anywhere in this project. Flagged, not
//     invented — [CameraButtonExecutor.execute] throws UnimplementedError
//     for it instead of pretending to succeed.
// ─────────────────────────────────────────────────────────────────────────────

enum CameraAction { view, snapshot, ptz, record }

class CameraButtonSpec {
  final String cameraId;
  final CameraAction action;
  final bool isSupported;
  final IconData icon;
  final String displayName;

  const CameraButtonSpec({
    required this.cameraId,
    required this.action,
    required this.isSupported,
    required this.icon,
    required this.displayName,
  });

  factory CameraButtonSpec.forAction(Camera camera, CameraAction action) {
    final (bool supported, IconData icon, String name) = switch (action) {
      CameraAction.view     => (true, Symbols.videocam, 'View'),
      CameraAction.snapshot => (camera.snapshotUrl != null, Symbols.photo_camera, 'Snapshot'),
      CameraAction.ptz      => (camera.isPtz, Symbols.control_camera, 'PTZ'),
      // No recording backend in this project — never reports supported.
      CameraAction.record   => (false, Symbols.fiber_manual_record, 'Record'),
    };

    return CameraButtonSpec(
      cameraId: camera.id,
      action: action,
      isSupported: supported,
      icon: icon,
      displayName: name,
    );
  }
}

abstract class CameraButtonExecutor {
  CameraButtonExecutor._();

  /// Executes [spec]'s action. [CameraAction.view] is deliberately not
  /// handled — it's pure navigation, a screen should push the camera
  /// viewer directly instead of calling this. [panX]/[tiltY]/[zoomX] are
  /// only read for [CameraAction.ptz] — see [OnvifPtzService.continuousMove]
  /// for their -1.0..1.0 meaning.
  static Future<bool> execute(
    CameraButtonSpec spec,
    Camera camera, {
    double panX = 0,
    double tiltY = 0,
    double zoomX = 0,
  }) async {
    switch (spec.action) {
      case CameraAction.view:
        throw StateError(
            'CameraAction.view is navigation, not a command — push the '
            'camera viewer screen directly instead of calling execute()');

      case CameraAction.snapshot:
        // Presence check only — fetching/displaying the image from
        // camera.snapshotUrl is the viewer screen's job, not this layer's.
        return camera.snapshotUrl != null;

      case CameraAction.ptz:
        if (!spec.isSupported || camera.ip == null) return false;
        return OnvifPtzService.continuousMove(
          camera.ip!,
          port: camera.port,
          username: camera.username,
          password: camera.password,
          profileToken: camera.onvifProfileToken,
          panX: panX,
          tiltY: tiltY,
          zoomX: zoomX,
        );

      case CameraAction.record:
        throw UnimplementedError(
            'CameraButtonExecutor: no recording backend exists in this '
            'project yet — surfacing the gap instead of fabricating one, '
            'per project rule 9');
    }
  }
}
