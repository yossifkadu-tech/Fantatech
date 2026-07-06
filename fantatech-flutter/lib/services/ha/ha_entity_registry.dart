// ─────────────────────────────────────────────────────────────────────────────
// HaEntityRegistryEntry — entry from /api/config/entity_registry/list
//
// Metadata record for one entity. Complements /api/states (which carries
// runtime values) with static info: device linkage, area, disabled/hidden
// flags, user-given names, device_class, unit_of_measurement, etc.
// ─────────────────────────────────────────────────────────────────────────────

/// Classifies helper/diagnostic entities
enum EntityCategory {
  config,
  diagnostic,
}

EntityCategory? _parseCategory(String? raw) {
  switch (raw) {
    case 'config':     return EntityCategory.config;
    case 'diagnostic': return EntityCategory.diagnostic;
    default:           return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class HaEntityRegistryEntry {
  /// Primary key — matches entity_id in /api/states
  final String  entityId;

  /// HA device this entity belongs to (null for standalone integrations)
  final String? deviceId;

  /// Area override on the entity level (overrides device area)
  final String? areaId;

  /// User-supplied name (null if not renamed)
  final String? name;

  /// Original name from the integration
  final String? originalName;

  /// The integration that provides this entity (e.g. 'hue', 'mqtt', 'zha')
  final String  platform;

  /// device_class as registered (may differ from attributes at runtime)
  final String? deviceClass;
  final String? originalDeviceClass;

  /// Unit of measurement (e.g. '°C', 'W', '%')
  final String? unitOfMeasurement;

  /// User-set icon override (mdi:xxx)
  final String? icon;
  final String? originalIcon;

  /// True when the entity is disabled (won't appear in /api/states)
  final bool    disabled;
  final String? disabledBy; // 'user' | 'config_entry' | 'integration' | 'device'

  /// True when the entity is hidden from dashboards
  final bool    hidden;
  final String? hiddenBy;

  /// Stable unique identifier within the platform
  final String? uniqueId;

  final EntityCategory? category;

  final List<String> labels;
  final List<String> aliases;

  const HaEntityRegistryEntry({
    required this.entityId,
    this.deviceId,
    this.areaId,
    this.name,
    this.originalName,
    required this.platform,
    this.deviceClass,
    this.originalDeviceClass,
    this.unitOfMeasurement,
    this.icon,
    this.originalIcon,
    this.disabled  = false,
    this.disabledBy,
    this.hidden    = false,
    this.hiddenBy,
    this.uniqueId,
    this.category,
    this.labels    = const [],
    this.aliases   = const [],
  });

  /// Best available name: user > original > entity_id
  String get displayName => name ?? originalName ?? entityId;

  /// The entity is visible and usable
  bool get isActive => !disabled && !hidden;

  /// True for config / diagnostic helpers
  bool get isHelperEntity => category != null;

  factory HaEntityRegistryEntry.fromJson(Map<String, dynamic> json) {
    return HaEntityRegistryEntry(
      entityId:            json['entity_id']              as String,
      deviceId:            json['device_id']              as String?,
      areaId:              json['area_id']                as String?,
      name:                json['name']                   as String?,
      originalName:        json['original_name']          as String?,
      platform:            json['platform']               as String? ?? '',
      deviceClass:         json['device_class']           as String?,
      originalDeviceClass: json['original_device_class']  as String?,
      unitOfMeasurement:   json['unit_of_measurement']    as String?,
      icon:                json['icon']                   as String?,
      originalIcon:        json['original_icon']          as String?,
      disabled:            json['disabled_by'] != null,
      disabledBy:          json['disabled_by']            as String?,
      hidden:              json['hidden_by']  != null,
      hiddenBy:            json['hidden_by']              as String?,
      uniqueId:            json['unique_id']              as String?,
      category:            _parseCategory(json['entity_category'] as String?),
      labels:              (json['labels']   as List?)?.cast<String>() ?? const [],
      aliases:             (json['aliases']  as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  String toString() =>
      'HaEntityRegistryEntry($entityId, device=$deviceId, area=$areaId)';
}
