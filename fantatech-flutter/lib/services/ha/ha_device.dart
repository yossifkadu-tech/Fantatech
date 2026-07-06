// ─────────────────────────────────────────────────────────────────────────────
// HaDevice — entry from /api/config/device_registry/list
//
// Each physical (or virtual) device in HA. Contains manufacturer metadata and
// links to areas. Multiple entities can belong to one device.
// ─────────────────────────────────────────────────────────────────────────────

class HaDevice {
  final String  id;
  final String? areaId;

  /// User-supplied name override (null if not renamed)
  final String? nameByUser;

  /// Original device name provided by the integration
  final String? name;

  final String? manufacturer;
  final String? model;
  final String? modelId;
  final String? swVersion;
  final String? hwVersion;
  final String? serialNumber;

  /// URL to the device's configuration page (e.g. http://192.168.1.x)
  final String? configurationUrl;

  final bool   disabled;
  final String? disabledBy;     // 'user' | 'config_entry' | 'integration'

  /// 'service' for virtual integrations (e.g. helpers), null for hardware
  final String? entryType;

  final List<String>        configEntries;

  /// [[domain, unique_id], ...]
  final List<List<String>>  identifiers;

  /// [['mac', 'aa:bb:cc:dd:ee:ff'], ['ip', '...'], ...]
  final List<List<String>>  connections;

  final List<String> labels;

  const HaDevice({
    required this.id,
    this.areaId,
    this.nameByUser,
    this.name,
    this.manufacturer,
    this.model,
    this.modelId,
    this.swVersion,
    this.hwVersion,
    this.serialNumber,
    this.configurationUrl,
    this.disabled = false,
    this.disabledBy,
    this.entryType,
    this.configEntries = const [],
    this.identifiers    = const [],
    this.connections    = const [],
    this.labels         = const [],
  });

  /// Human-readable name: user override > original name > id
  String get displayName => nameByUser ?? name ?? id;

  /// True for non-hardware integrations (helpers, virtual devices)
  bool get isService => entryType == 'service';

  factory HaDevice.fromJson(Map<String, dynamic> json) {
    List<List<String>> parseMatrix(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<List>()
          .map((row) => row.map((e) => e.toString()).toList())
          .toList();
    }

    return HaDevice(
      id:               json['id']                as String,
      areaId:           json['area_id']           as String?,
      nameByUser:       json['name_by_user']       as String?,
      name:             json['name']               as String?,
      manufacturer:     json['manufacturer']       as String?,
      model:            json['model']              as String?,
      modelId:          json['model_id']           as String?,
      swVersion:        json['sw_version']         as String?,
      hwVersion:        json['hw_version']         as String?,
      serialNumber:     json['serial_number']      as String?,
      configurationUrl: json['configuration_url']  as String?,
      disabled:         json['disabled_by'] != null,
      disabledBy:       json['disabled_by']        as String?,
      entryType:        json['entry_type']         as String?,
      configEntries:    (json['config_entries'] as List?)
                            ?.cast<String>() ?? const [],
      identifiers:      parseMatrix(json['identifiers']),
      connections:      parseMatrix(json['connections']),
      labels:           (json['labels'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  String toString() =>
      'HaDevice($id, $displayName, manufacturer=$manufacturer, model=$model)';
}
