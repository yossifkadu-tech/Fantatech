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
  waterLeakSensor,  // water leak detector
  matterDevice,     // generic Matter/Thread device
}

enum DeviceStatus { online, offline }

class Device {
  final String id;
  String name;
  final DeviceType type;
  DeviceStatus status;
  bool isOn;
  Map<String, dynamic> attributes;
  final String room;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.online,
    this.isOn = false,
    this.attributes = const {},
    this.room = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'status': status.name,
    'isOn': isOn,
    'attributes': attributes,
    'room': room,
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
    attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
    room: json['room'] as String? ?? '',
  );
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
  String condition;
  String action;
  bool isEnabled;

  Automation({
    required this.id,
    required this.name,
    required this.condition,
    required this.action,
    this.isEnabled = true,
  });
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
}
