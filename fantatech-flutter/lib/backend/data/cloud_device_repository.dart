// ─────────────────────────────────────────────────────────────────────────────
// CloudDeviceRepository — syncs the home's devices with Supabase Postgres,
// with a live realtime stream. Maps cloud rows ↔ the existing Device model.
// ─────────────────────────────────────────────────────────────────────────────
import '../../models/device.dart';
import '../backend_service.dart';

class CloudDeviceRepository {
  static const _table = 'devices';

  /// One-shot fetch of all devices for a home.
  Future<List<Device>> fetchDevices(String homeId) async {
    final rows = await BackendService.client
        .from(_table)
        .select()
        .eq('home_id', homeId);
    return (rows as List).map((r) => _toDevice(r as Map<String, dynamic>)).toList();
  }

  /// Live stream — emits the full device list whenever any row changes
  /// (insert / update / delete) on the server, across all the user's devices.
  Stream<List<Device>> watchDevices(String homeId) {
    return BackendService.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .map((rows) => rows.map(_toDevice).toList());
  }

  /// Create or update a device (upsert by id).
  Future<void> upsertDevice(Device d, {required String homeId}) async {
    await BackendService.client.from(_table).upsert(_toRow(d, homeId));
  }

  /// Optimistic on/off — patch a single column.
  Future<void> setOnOff(String deviceId, bool isOn) async {
    await BackendService.client
        .from(_table)
        .update({'is_on': isOn}).eq('id', deviceId);
  }

  Future<void> deleteDevice(String deviceId) async {
    await BackendService.client.from(_table).delete().eq('id', deviceId);
  }

  // ── Mapping ────────────────────────────────────────────────────────────────
  Device _toDevice(Map<String, dynamic> r) => Device(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        type: DeviceType.values.firstWhere(
          (e) => e.name == r['type'],
          orElse: () => DeviceType.smartPlug,
        ),
        status: (r['status'] as String?) == 'offline'
            ? DeviceStatus.offline
            : DeviceStatus.online,
        isOn: r['is_on'] as bool? ?? false,
        room: r['room_key'] as String? ?? '',
        attributes: Map<String, dynamic>.from(r['attributes'] as Map? ?? {}),
        battery: r['battery'] as int?,
      );

  Map<String, dynamic> _toRow(Device d, String homeId) => {
        'id': d.id,
        'home_id': homeId,
        'name': d.name,
        'type': d.type.name,
        'status': d.status.name,
        'is_on': d.isOn,
        'room_key': d.room,
        'battery': d.battery,
        'attributes': d.attributes,
      };
}
