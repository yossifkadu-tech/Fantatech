import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/models/camera_button_spec.dart';

Camera _camera({
  bool isPtz = false,
  String? snapshotUrl,
  String? ip,
}) =>
    Camera(
      id: 'cam_1',
      name: 'Front Door',
      room: 'Entrance',
      snapshotUrl: snapshotUrl,
      isPtz: isPtz,
      ip: ip,
    );

void main() {
  group('CameraButtonSpec.forAction', () {
    test('view is always supported — it is pure navigation', () {
      final spec = CameraButtonSpec.forAction(_camera(), CameraAction.view);
      expect(spec.isSupported, isTrue);
    });

    test('snapshot supported only when the camera reports a snapshotUrl', () {
      expect(
          CameraButtonSpec.forAction(_camera(snapshotUrl: 'http://x/s.jpg'), CameraAction.snapshot)
              .isSupported,
          isTrue);
      expect(CameraButtonSpec.forAction(_camera(), CameraAction.snapshot).isSupported, isFalse);
    });

    test('ptz supported only when the camera reports isPtz', () {
      expect(CameraButtonSpec.forAction(_camera(isPtz: true), CameraAction.ptz).isSupported,
          isTrue);
      expect(CameraButtonSpec.forAction(_camera(isPtz: false), CameraAction.ptz).isSupported,
          isFalse);
    });

    test('record is never supported — no backend exists yet', () {
      expect(CameraButtonSpec.forAction(_camera(), CameraAction.record).isSupported, isFalse);
    });
  });

  group('CameraButtonExecutor.execute', () {
    test('view throws — callers must navigate directly, never execute() it', () async {
      final camera = _camera();
      final spec = CameraButtonSpec.forAction(camera, CameraAction.view);
      expect(() => CameraButtonExecutor.execute(spec, camera), throwsStateError);
    });

    test('record throws UnimplementedError instead of fabricating success', () async {
      final camera = _camera();
      final spec = CameraButtonSpec.forAction(camera, CameraAction.record);
      expect(() => CameraButtonExecutor.execute(spec, camera), throwsUnimplementedError);
    });

    test('snapshot resolves true when the camera has a snapshotUrl', () async {
      final camera = _camera(snapshotUrl: 'http://x/s.jpg');
      final spec = CameraButtonSpec.forAction(camera, CameraAction.snapshot);
      expect(await CameraButtonExecutor.execute(spec, camera), isTrue);
    });

    test('ptz on a camera with no ip resolves false rather than throwing', () async {
      final camera = _camera(isPtz: true, ip: null);
      final spec = CameraButtonSpec.forAction(camera, CameraAction.ptz);
      expect(await CameraButtonExecutor.execute(spec, camera), isFalse);
    });
  });
}
