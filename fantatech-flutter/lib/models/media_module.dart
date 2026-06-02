// ─────────────────────────────────────────────────────────────────────────────
// MediaModule — smart-media subsystem (speakers, smart TVs, cast targets).
//
// Discovered over the LAN via mDNS (Chromecast / AirPlay / Sonos / Spotify
// Connect). Kept separate from the main device list, like cameras.
// ─────────────────────────────────────────────────────────────────────────────

/// What kind of media endpoint this is.
enum MediaDeviceKind { speaker, tv, castTarget, soundbar, unknown }

/// Casting protocol the endpoint speaks.
enum MediaProtocol { chromecast, airplay, sonos, dlna, spotifyConnect, unknown }

class MediaDevice {
  final String id;
  String name;
  final MediaDeviceKind kind;
  final MediaProtocol protocol;
  final String? ip;
  final String? manufacturer;
  final String? model;
  bool isOnline;
  bool isPlaying;
  int volume; // 0–100

  // Now-playing metadata
  String track;
  String artist;
  int progress; // 0–100
  int trackIndex;

  MediaDevice({
    required this.id,
    required this.name,
    this.kind = MediaDeviceKind.unknown,
    this.protocol = MediaProtocol.unknown,
    this.ip,
    this.manufacturer,
    this.model,
    this.isOnline = true,
    this.isPlaying = false,
    this.volume = 30,
    this.track = '',
    this.artist = '',
    this.progress = 0,
    this.trackIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'protocol': protocol.name,
        'ip': ip,
        'manufacturer': manufacturer,
        'model': model,
        'isOnline': isOnline,
        'isPlaying': isPlaying,
        'volume': volume,
      };

  factory MediaDevice.fromJson(Map<String, dynamic> j) => MediaDevice(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Media',
        kind: MediaDeviceKind.values.firstWhere(
          (e) => e.name == j['kind'],
          orElse: () => MediaDeviceKind.unknown,
        ),
        protocol: MediaProtocol.values.firstWhere(
          (e) => e.name == j['protocol'],
          orElse: () => MediaProtocol.unknown,
        ),
        ip: j['ip'] as String?,
        manufacturer: j['manufacturer'] as String?,
        model: j['model'] as String?,
        isOnline: j['isOnline'] as bool? ?? true,
        isPlaying: j['isPlaying'] as bool? ?? false,
        volume: j['volume'] as int? ?? 30,
      );
}

/// Settings + state for the media subsystem.
class MediaModule {
  bool enabled;
  bool autoDiscovery;
  bool allowCasting;

  final List<MediaDevice> devices;

  MediaModule({
    this.enabled = true,
    this.autoDiscovery = true,
    this.allowCasting = true,
    List<MediaDevice>? devices,
  }) : devices = devices ?? [];

  int get onlineCount => devices.where((d) => d.isOnline).length;
  bool get hasDevices => devices.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'autoDiscovery': autoDiscovery,
        'allowCasting': allowCasting,
        'devices': devices.map((d) => d.toJson()).toList(),
      };

  factory MediaModule.fromJson(Map<String, dynamic> j) => MediaModule(
        enabled: j['enabled'] as bool? ?? true,
        autoDiscovery: j['autoDiscovery'] as bool? ?? true,
        allowCasting: j['allowCasting'] as bool? ?? true,
        devices: (j['devices'] as List? ?? [])
            .map((e) => MediaDevice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
