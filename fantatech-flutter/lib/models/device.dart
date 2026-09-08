enum DeviceType {
  light,
  blind,
  airConditioner,
  smartPlug,
  smartSwitch,
  motionSensor,
  doorSensor,
  windowSensor,
  waterHeater,
  camera,
  router,
  gateway,
  circuitBreaker,
  solar,
  smokeSensor,
  energyMeter,
  smartLock,        // door lock
  gasSensor,        // gas / CO detector
  waterLeakSensor,   // water leak detector
  glassBreakSensor,  // glass-break / vibration sensor
  co2Sensor,         // CO2 / air-quality sensor
  freezeSensor,      // pipe-freeze / low-temperature sensor
  tamperSensor,      // panel/device tamper detector
  mailboxSensor,     // mailbox / package sensor
  matterDevice,      // generic Matter/Thread device
  smartTv,           // smart television
  networkDevice,     // phones, laptops and other tracked network clients
  printer,           // network printer
  intercom,          // video door intercom
  garage,            // garage door / gate controller
  alarmPanel,        // Ajax / Risco / PIMA alarm panel
  robotVacuum,       // robot vacuum / mop (iRobot, Roborock, Ecovacs…)
  unknown,
}

enum DeviceStatus {
  online,   // turquoise (#26A69A) — reachable, operating normally
  offline,  // gray      (#757575) — unreachable / no heartbeat
  warning,  // orange    (#FB8C00) — needs attention (low battery, tamper…)
  alert,    // yellow    (#FFD54F) — elevated condition
  alarm,    // red       (#E53935) — active alarm / threshold exceeded
  info,     // blue      (#1E88E5) — informational state
}

extension DeviceStatusX on DeviceStatus {
  bool get isOnline  => this == DeviceStatus.online;
  bool get isOffline => this == DeviceStatus.offline;
  bool get isWarning => this == DeviceStatus.warning;
  bool get isAlert   => this == DeviceStatus.alert;
  bool get isAlarm   => this == DeviceStatus.alarm;
  bool get isInfo    => this == DeviceStatus.info;

  /// True when the device can still accept commands.
  bool get isControllable => this != DeviceStatus.offline;
}

class Device {
  final String id;
  String name;
  final DeviceType type;
  DeviceStatus status;
  bool isOn;
  Map<String, dynamic> attributes;
  String room;

  /// 'gateway' = imported from a real gateway, 'manual' = added via catalog.
  String source;

  /// Battery level 0–100, null if the device has no battery.
  int? battery;

  /// Link quality / signal strength 0–100, null if unknown.
  int? signal;

  /// Whether the user has starred this device.
  bool isFavorite;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.online,
    this.isOn = false,
    this.attributes = const {},
    this.room = '',
    this.source = 'manual',
    int? battery,
    this.signal,
    this.isFavorite = false,
  }) : battery = battery ??
            (attributes['battery'] is int
                ? attributes['battery'] as int
                : null);

  /// Convenience — mirrors SmartDevice.online.
  bool get online => status == DeviceStatus.online;
  set online(bool v) => status = v ? DeviceStatus.online : DeviceStatus.offline;

  /// Human-readable type string, e.g. "light", "airConditioner".
  String get typeLabel => type.name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'status': status.name,
    'isOn': isOn,
    'battery': battery,
    'signal': signal,
    'isFavorite': isFavorite,
    'attributes': attributes,
    'room': room,
    'source': source,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as String,
    name: json['name'] as String,
    type: DeviceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => DeviceType.smartPlug,
    ),
    status: DeviceStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => DeviceStatus.online,
    ),
    isOn: json['isOn'] as bool? ?? false,
    battery: json['battery'] as int?,
    signal: json['signal'] as int?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
    room: json['room'] as String? ?? '',
    source: json['source'] as String? ??
        (_isGatewayId(json['id'] as String? ?? '') ? 'gateway' : 'manual'),
  );

  /// Detect whether a persisted device ID came from a real gateway import.
  /// Used as a migration for devices saved before the source field existed.
  static bool _isGatewayId(String id) {
    const prefixes = [
      'dirigera_', 'hue_', 'hue_light_', 'hue_sensor_',
      'deconz_', 'deconz_light_', 'deconz_sensor_',
      'z2m_', 'mqtt_', 'st_', 'tuya_',
      'ha_', 'smartthings_',
      'aqara-', 'irobot_', 'xiaomi_vacuum_',
      'ajax-', 'risco-', 'pima-', 'zwave-',
    ];
    return prefixes.any(id.startsWith);
  }

  /// Create a [Device] from a [SmartDevice] discovered via an external API.
  factory Device.fromSmartDevice(SmartDevice sd, {DeviceType? type}) => Device(
    id:      sd.id,
    name:    sd.name,
    room:    sd.room,
    type:    type ?? _typeFromString(sd.type),
    status:  sd.online ? DeviceStatus.online : DeviceStatus.offline,
    battery: sd.battery >= 0 ? sd.battery : null,
  );

  static DeviceType _typeFromString(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('light') || lower.contains('bulb'))    return DeviceType.light;
    if (lower.contains('blind') || lower.contains('curtain')) return DeviceType.blind;
    if (lower.contains('plug') || lower.contains('socket'))   return DeviceType.smartPlug;
    if (lower.contains('switch'))                             return DeviceType.smartSwitch;
    if (lower.contains('motion'))                             return DeviceType.motionSensor;
    if (lower.contains('door') || lower.contains('contact'))  return DeviceType.doorSensor;
    if (lower.contains('window'))                             return DeviceType.windowSensor;
    if (lower.contains('smoke'))                              return DeviceType.smokeSensor;
    if (lower.contains('water') || lower.contains('leak'))    return DeviceType.waterLeakSensor;
    if (lower.contains('lock'))                               return DeviceType.smartLock;
    if (lower.contains('matter'))                             return DeviceType.matterDevice;
    if (lower.contains('climate') || lower.contains('hvac') || lower.contains('ac')) {
      return DeviceType.airConditioner;
    }
    return DeviceType.smartPlug;
  }
}

// ── SmartDevice ───────────────────────────────────────────────────────────────
// Lightweight discovery/API model — type is a raw string from external sources
// (Tuya, Matter, Smart Life, etc.). Convert to [Device] with Device.fromSmartDevice().

class SmartDevice {
  final String id;
  final String name;
  final String room;
  final String type;
  final bool online;

  /// Battery level 0–100. Use -1 if the device has no battery.
  final int battery;

  SmartDevice({
    required this.id,
    required this.name,
    required this.room,
    required this.type,
    required this.online,
    required this.battery,
  });

  factory SmartDevice.fromJson(Map<String, dynamic> json) => SmartDevice(
    id:      json['id']      as String,
    name:    json['name']    as String,
    room:    json['room']    as String? ?? '',
    type:    json['type']    as String? ?? 'unknown',
    online:  json['online']  as bool?   ?? false,
    battery: json['battery'] as int?    ?? -1,
  );

  Map<String, dynamic> toJson() => {
    'id':      id,
    'name':    name,
    'room':    room,
    'type':    type,
    'online':  online,
    'battery': battery,
  };

  /// Whether this device has a meaningful battery reading.
  bool get hasBattery => battery >= 0;

  /// Convert to a full [Device] for use in the app state.
  Device toDevice({DeviceType? forceType}) =>
      Device.fromSmartDevice(this, type: forceType);
}

/// In-app notification generated when a real device connects.
class AppNotification {
  final String id;
  final String title;
  final String deviceId;
  final DeviceType deviceType;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.deviceId,
    required this.deviceType,
    required this.timestamp,
    this.isRead = false,
  });
}

class SecurityEvent {
  final String id;
  final String description;
  final DateTime timestamp;
  final String deviceId;
  final bool isAlert;

  const SecurityEvent({
    required this.id,
    required this.description,
    required this.timestamp,
    required this.deviceId,
    this.isAlert = false,
  });
}

class Automation {
  final String id;
  String name;
  String condition; // human-readable display text (built by the add wizard)
  String action;    // human-readable display text (built by the add wizard)
  bool isEnabled;

  // ── Structured fields — what AutomationEngine actually executes ──────────
  // condition/action above are just labels; these are what's evaluated.
  // Nullable/defaulted so an automation restored from an old backup (text
  // only) simply never fires instead of crashing.
  String? triggerType;      // 'device' | 'sensor' | 'time' | 'arrival'
  String? triggerDeviceId;  // for 'device'/'sensor' triggers
  int? triggerHour;         // for 'time' triggers
  int? triggerMinute;

  String? actionType;       // 'turnOn'|'turnOff'|'lock'|'unlock'|'openBlind'|'closeBlind'|'allLightsOff'
  String? actionDeviceId;   // null = apply to all matching devices

  Automation({
    required this.id,
    required this.name,
    required this.condition,
    required this.action,
    this.isEnabled = true,
    this.triggerType,
    this.triggerDeviceId,
    this.triggerHour,
    this.triggerMinute,
    this.actionType,
    this.actionDeviceId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'condition': condition,
        'action': action,
        'is_enabled': isEnabled,
        if (triggerType != null) 'trigger_type': triggerType,
        if (triggerDeviceId != null) 'trigger_device_id': triggerDeviceId,
        if (triggerHour != null) 'trigger_hour': triggerHour,
        if (triggerMinute != null) 'trigger_minute': triggerMinute,
        if (actionType != null) 'action_type': actionType,
        if (actionDeviceId != null) 'action_device_id': actionDeviceId,
      };

  factory Automation.fromJson(Map<String, dynamic> json) => Automation(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        condition: json['condition'] as String? ?? '',
        action: json['action'] as String? ?? '',
        isEnabled: json['is_enabled'] as bool? ?? true,
        triggerType: json['trigger_type'] as String?,
        triggerDeviceId: json['trigger_device_id'] as String?,
        triggerHour: json['trigger_hour'] as int?,
        triggerMinute: json['trigger_minute'] as int?,
        actionType: json['action_type'] as String?,
        actionDeviceId: json['action_device_id'] as String?,
      );
}

enum CameraStreamType { mjpeg, rtsp, hls, snapshot, unknown }

class Camera {
  final String id;
  String name;
  final String room;
  bool isOnline;
  bool motionDetection;
  String? thumbnailUrl;

  // Real connection fields
  String? ip;
  int port;
  String? username;
  String? password;
  String? rtspUrl;
  String? mjpegUrl;
  String? snapshotUrl;
  String? manufacturer;
  String? model;
  CameraStreamType streamType;

  // PTZ
  bool isPtz;
  String onvifProfileToken;

  Camera({
    required this.id,
    required this.name,
    required this.room,
    this.isOnline = true,
    this.motionDetection = true,
    this.thumbnailUrl,
    this.ip,
    this.port = 554,
    this.username,
    this.password,
    this.rtspUrl,
    this.mjpegUrl,
    this.snapshotUrl,
    this.manufacturer,
    this.model,
    this.streamType = CameraStreamType.unknown,
    this.isPtz = false,
    this.onvifProfileToken = 'MainStream',
  });

  /// Best available stream URL for display
  String? get activeStreamUrl => mjpegUrl ?? snapshotUrl ?? rtspUrl;

  /// Build RTSP URL from parts if not explicitly set
  String? get effectiveRtspUrl {
    if (rtspUrl != null) return rtspUrl;
    if (ip == null) return null;
    final cred = (username != null && password != null) ? '$username:$password@' : '';
    return 'rtsp://${cred}$ip:$port/';
  }

  bool get hasRealStream =>
      mjpegUrl != null || snapshotUrl != null || rtspUrl != null ||
      (ip != null);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'room': room,
    'isOnline': isOnline,
    'motionDetection': motionDetection,
    'thumbnailUrl': thumbnailUrl,
    'ip': ip,
    'port': port,
    'username': username,
    'password': password,
    'rtspUrl': rtspUrl,
    'mjpegUrl': mjpegUrl,
    'snapshotUrl': snapshotUrl,
    'manufacturer': manufacturer,
    'model': model,
    'streamType': streamType.name,
    'isPtz': isPtz,
    'onvifProfileToken': onvifProfileToken,
  };

  factory Camera.fromJson(Map<String, dynamic> json) => Camera(
    id: json['id'] as String,
    name: json['name'] as String,
    room: json['room'] as String? ?? '',
    isOnline: json['isOnline'] as bool? ?? true,
    motionDetection: json['motionDetection'] as bool? ?? true,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    ip: json['ip'] as String?,
    port: json['port'] as int? ?? 554,
    username: json['username'] as String?,
    password: json['password'] as String?,
    rtspUrl: json['rtspUrl'] as String?,
    mjpegUrl: json['mjpegUrl'] as String?,
    snapshotUrl: json['snapshotUrl'] as String?,
    manufacturer: json['manufacturer'] as String?,
    model: json['model'] as String?,
    streamType: CameraStreamType.values.firstWhere(
      (e) => e.name == json['streamType'],
      orElse: () => CameraStreamType.unknown,
    ),
    isPtz: json['isPtz'] as bool? ?? false,
    onvifProfileToken: json['onvifProfileToken'] as String? ?? 'MainStream',
  );
}
