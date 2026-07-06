import 'package:fantatech/services/ha/ha_entity.dart';
import 'package:fantatech/services/ha/ha_provider.dart';

/// Minimal stub of HaProvider for widget tests.
///
/// Extends HaProvider directly so Provider can resolve it by type.
/// HaProvider() constructor is lightweight (no network calls until
/// [connect] is invoked), so subclassing is safe in tests.
class FakeHaProvider extends HaProvider {
  final List<HaEntity> _fakeAutomations;
  final List<HaEntity> _fakeCameras;
  final bool _connected;

  FakeHaProvider({
    List<HaEntity> automations = const [],
    List<HaEntity> cameras     = const [],
    bool           connected   = true,
  })  : _fakeAutomations = automations,
        _fakeCameras     = cameras,
        _connected       = connected;

  @override
  List<HaEntity> get automations => _fakeAutomations;

  @override
  List<HaEntity> get cameras => _fakeCameras;

  @override
  bool get isConnected => _connected;

  // ── Stub service calls (no-ops so buttons don't crash) ────────────────────

  @override
  Future<bool> automationEnable(String entityId)  async => true;
  @override
  Future<bool> automationDisable(String entityId) async => true;
  @override
  Future<bool> automationTrigger(String entityId) async => true;
}

// ── Entity builders ───────────────────────────────────────────────────────────

HaEntity fakeAutomation({
  String  id    = 'automation.test',
  String  name  = 'Test Automation',
  String  state = 'on',
}) =>
    HaEntity(
      entityId:   id,
      state:      state,
      attributes: {'friendly_name': name},
    );

HaEntity fakeCamera({
  String id   = 'camera.front_door',
  String name = 'Front Door',
}) =>
    HaEntity(
      entityId:   id,
      state:      'idle',
      attributes: {
        'friendly_name':  name,
        'entity_picture': '/api/camera_proxy/$id?token=test',
      },
    );
