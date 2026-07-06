// ─────────────────────────────────────────────────────────────────────────────
// HaEntity — מייצג ישות אחת מ-Home Assistant /api/states
// ─────────────────────────────────────────────────────────────────────────────

enum HaDomain {
  light,
  switchDomain,
  climate,
  cover,
  sensor,
  binarySensor,
  camera,
  alarmControlPanel,
  lock,
  mediaPlayer,
  fan,
  vacuum,
  other,
}

class HaEntity {
  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;
  final String? areaId;

  /// Links to the HA device registry (from entity registry, not from /api/states)
  final String? deviceId;

  const HaEntity({
    required this.entityId,
    required this.state,
    required this.attributes,
    this.areaId,
    this.deviceId,
  });

  // ── Derived properties ────────────────────────────────────────────────────

  String get domain => entityId.split('.').first;

  String get friendlyName =>
      (attributes['friendly_name'] as String?) ?? entityId;

  String? get deviceClass => attributes['device_class'] as String?;

  bool get isOn {
    switch (state.toLowerCase()) {
      case 'on':
      case 'open':
      case 'unlocked':
      case 'heat':
      case 'cool':
      case 'auto':
      case 'fan_only':
      case 'dry':
      case 'home':
      case 'playing':
      case 'paused':
      case 'cleaning':
        return true;
      default:
        final n = double.tryParse(state);
        return n != null && n > 0;
    }
  }

  HaDomain get haDomain {
    switch (domain) {
      case 'light':               return HaDomain.light;
      case 'switch':              return HaDomain.switchDomain;
      case 'climate':             return HaDomain.climate;
      case 'cover':               return HaDomain.cover;
      case 'sensor':              return HaDomain.sensor;
      case 'binary_sensor':       return HaDomain.binarySensor;
      case 'camera':              return HaDomain.camera;
      case 'alarm_control_panel': return HaDomain.alarmControlPanel;
      case 'lock':                return HaDomain.lock;
      case 'media_player':        return HaDomain.mediaPlayer;
      case 'fan':                 return HaDomain.fan;
      case 'vacuum':              return HaDomain.vacuum;
      default:                    return HaDomain.other;
    }
  }

  // ── Light attributes ──────────────────────────────────────────────────────

  /// בהירות 0–100 (HA שומר 0–255)
  int? get brightness {
    final raw = attributes['brightness'];
    if (raw == null) return null;
    return ((raw as num) / 2.55).round().clamp(0, 100);
  }

  /// טמפרטורת צבע בקלווין
  int? get colorTempKelvin =>
      (attributes['color_temp_kelvin'] as num?)?.toInt();

  /// [h, s] — hue 0–360, saturation 0–100
  List<double>? get hsColor {
    final raw = attributes['hs_color'];
    if (raw is! List || raw.length < 2) return null;
    return [raw[0] as double, raw[1] as double];
  }

  /// [r, g, b] — 0–255
  List<int>? get rgbColor {
    final raw = attributes['rgb_color'];
    if (raw is! List || raw.length < 3) return null;
    return [(raw[0] as num).toInt(), (raw[1] as num).toInt(), (raw[2] as num).toInt()];
  }

  String? get effect => attributes['effect'] as String?;

  List<String> get effectList =>
      (attributes['effect_list'] as List?)?.cast<String>() ?? [];

  List<String> get supportedColorModes =>
      (attributes['supported_color_modes'] as List?)?.cast<String>() ?? [];

  // ── Climate attributes ────────────────────────────────────────────────────

  double? get currentTemperature =>
      (attributes['current_temperature'] as num?)?.toDouble();

  double? get targetTemperature =>
      (attributes['temperature'] as num?)?.toDouble();

  double? get targetTempHigh =>
      (attributes['target_temp_high'] as num?)?.toDouble();

  double? get targetTempLow =>
      (attributes['target_temp_low'] as num?)?.toDouble();

  String? get hvacMode => state; // heat / cool / auto / off

  List<String> get hvacModes =>
      (attributes['hvac_modes'] as List?)?.cast<String>() ?? [];

  String? get fanMode => attributes['fan_mode'] as String?;

  List<String> get fanModes =>
      (attributes['fan_modes'] as List?)?.cast<String>() ?? [];

  double? get currentHumidity =>
      (attributes['current_humidity'] as num?)?.toDouble();

  String? get swingMode => attributes['swing_mode'] as String?;

  List<String> get swingModes =>
      (attributes['swing_modes'] as List?)?.cast<String>() ?? [];

  String? get presetMode => attributes['preset_mode'] as String?;

  List<String> get presetModes =>
      (attributes['preset_modes'] as List?)?.cast<String>() ?? [];

  double? get minTemp => (attributes['min_temp'] as num?)?.toDouble();
  double? get maxTemp => (attributes['max_temp'] as num?)?.toDouble();

  // ── Cover attributes ──────────────────────────────────────────────────────

  /// מיקום תריס 0–100 (0=סגור, 100=פתוח)
  int? get coverPosition =>
      (attributes['current_position'] as num?)?.toInt();

  int? get tiltPosition =>
      (attributes['current_tilt_position'] as num?)?.toInt();

  // ── Lock attributes ───────────────────────────────────────────────────────

  bool get isLocked   => state == 'locked';
  bool get isJammed   => state == 'jammed';
  bool get isLocking  => state == 'locking';
  bool get isUnlocking => state == 'unlocking';

  String? get changedBy => attributes['changed_by'] as String?;

  // ── Fan attributes ────────────────────────────────────────────────────────

  /// 0–100 — fan speed percentage
  int? get fanPercentage =>
      (attributes['percentage'] as num?)?.toInt();

  String? get fanPresetMode => attributes['preset_mode'] as String?;

  List<String> get fanPresetModes =>
      (attributes['preset_modes'] as List?)?.cast<String>() ?? [];

  bool? get fanOscillating => attributes['oscillating'] as bool?;

  String? get fanDirection => attributes['direction'] as String?;

  // ── Media Player attributes ───────────────────────────────────────────────

  String? get mediaTitle  => attributes['media_title']  as String?;
  String? get mediaArtist => attributes['media_artist'] as String?;
  String? get mediaAlbum  => attributes['media_album_name'] as String?;
  String? get mediaThumbnail => attributes['entity_picture'] as String?;

  double? get volumeLevel =>
      (attributes['volume_level'] as num?)?.toDouble();

  bool get isVolumeMuted => (attributes['is_volume_muted'] as bool?) ?? false;

  String? get mediaSource => attributes['source'] as String?;

  List<String> get mediaSourceList =>
      (attributes['source_list'] as List?)?.cast<String>() ?? [];

  String? get mediaContentType => attributes['media_content_type'] as String?;

  double? get mediaDuration =>
      (attributes['media_duration'] as num?)?.toDouble();

  double? get mediaPosition =>
      (attributes['media_position'] as num?)?.toDouble();

  bool get isMediaPlaying => state == 'playing';

  // ── Vacuum attributes ─────────────────────────────────────────────────────

  /// cleaning / docked / idle / paused / returning / error
  String get vacuumStatus => state;

  int? get vacuumBattery =>
      (attributes['battery_level'] as num?)?.toInt();

  String? get vacuumFanSpeed => attributes['fan_speed'] as String?;

  List<String> get vacuumFanSpeeds =>
      (attributes['fan_speed_list'] as List?)?.cast<String>() ?? [];

  // ── Sensor attributes ─────────────────────────────────────────────────────

  String? get unit => attributes['unit_of_measurement'] as String?;

  double? get numericValue => double.tryParse(state);

  DateTime? get lastUpdatedAt {
    final raw = attributes['last_updated'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Alarm attributes ──────────────────────────────────────────────────────

  /// armed_away / armed_home / armed_night / disarmed / triggered / pending
  String get alarmState => state;

  bool get isAlarmArmed =>
      state.startsWith('armed') || state == 'triggered';

  // ── Battery ───────────────────────────────────────────────────────────────

  int? get battery => (attributes['battery'] as num?)?.toInt();

  // ── Factory ───────────────────────────────────────────────────────────────

  factory HaEntity.fromJson(
    Map<String, dynamic> json, {
    String? areaId,
    String? deviceId,
  }) {
    return HaEntity(
      entityId:   json['entity_id'] as String,
      state:      json['state']     as String? ?? 'unknown',
      attributes: (json['attributes'] as Map?)?.cast<String, dynamic>() ?? {},
      areaId:     areaId,
      deviceId:   deviceId,
    );
  }

  HaEntity copyWithState(String newState, [Map<String, dynamic>? newAttrs]) =>
      HaEntity(
        entityId:   entityId,
        state:      newState,
        attributes: newAttrs ?? attributes,
        areaId:     areaId,
        deviceId:   deviceId,
      );

  HaEntity copyWith({String? areaId, String? deviceId}) => HaEntity(
        entityId:   entityId,
        state:      state,
        attributes: attributes,
        areaId:     areaId   ?? this.areaId,
        deviceId:   deviceId ?? this.deviceId,
      );
}
