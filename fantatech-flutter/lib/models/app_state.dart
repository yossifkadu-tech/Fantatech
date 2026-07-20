import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as _math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device.dart';
import 'face_analysis.dart';
import 'known_person.dart';
import 'media_module.dart';
import 'custom_scene.dart';
import '../mock/mock_data.dart';
import '../l10n/strings.dart';
import '../services/ai/azure_face_service.dart';
import '../services/control/device_commander.dart';
import '../services/gateways/gateway_manager.dart';
import '../services/ha/ha_entity.dart';
import '../services/ha/ha_provider.dart';
import '../services/ha/ha_sync_service.dart';
import '../services/sensors/ambient_light_service.dart';
import '../services/auth/user_service.dart';
import 'app_user.dart' show Permission;
import '../services/storage/secure_cred_service.dart';
import '../theme/app_theme.dart';

enum SecurityMode { disarmed, armedHome, armedAway, panic, guest }

extension SecurityModeX on SecurityMode {
  bool get isArmed => this != SecurityMode.disarmed && this != SecurityMode.guest;
  bool get isGuest => this == SecurityMode.guest;
  String get label => switch (this) {
    SecurityMode.disarmed  => 'Disarmed',
    SecurityMode.armedHome => 'Armed Home',
    SecurityMode.armedAway => 'Armed Away',
    SecurityMode.panic     => 'PANIC',
    SecurityMode.guest     => 'Welcome Guest',
  };
}
enum AppLocale { hebrew, english, arabic, amharic, spanish, russian, french }

/// Ad track — which product category rotates in the dashboard banner
enum AdTrack { featured, newArrivals, all, none }

/// Subscription tier — controls feature access throughout the app
enum UserPlan { free, basic, advanced, advancedPlus, unlimited }

extension UserPlanX on UserPlan {
  /// Monthly price (display string)
  String get priceIls => switch (this) {
    UserPlan.free         => '₪0',
    UserPlan.basic        => '₪19',
    UserPlan.advanced     => '₪39',
    UserPlan.advancedPlus => '₪69',
    UserPlan.unlimited    => '₪100',
  };

  /// Max devices allowed (null = unlimited)
  int? get maxDevices => switch (this) {
    UserPlan.free         => 7,
    UserPlan.basic        => 10,
    UserPlan.advanced     => 15,
    UserPlan.advancedPlus => 20,
    UserPlan.unlimited    => null,
  };

  /// Max rooms allowed (null = unlimited)
  int? get maxRooms => switch (this) {
    UserPlan.free         => 3,
    UserPlan.basic        => 3,
    UserPlan.advanced     => 5,
    UserPlan.advancedPlus => null,
    UserPlan.unlimited    => null,
  };

  /// Max automations allowed (null = unlimited)
  int? get maxAutomations => switch (this) {
    UserPlan.free         => 0,
    UserPlan.basic        => 3,
    UserPlan.advanced     => 5,
    UserPlan.advancedPlus => 10,
    UserPlan.unlimited    => null,
  };

  /// Max cameras allowed
  int? get maxCameras => switch (this) {
    UserPlan.free         => 0,
    UserPlan.basic        => 0,
    UserPlan.advanced     => 3,
    UserPlan.advancedPlus => 5,
    UserPlan.unlimited    => 5,
  };

  /// History retention in months
  int get historyMonths => switch (this) {
    UserPlan.free         => 6,
    UserPlan.basic        => 12,
    UserPlan.advanced     => 12,
    UserPlan.advancedPlus => 12,
    UserPlan.unlimited    => 24,
  };

  bool get canControlDevices => this != UserPlan.free && this != UserPlan.basic;
  bool get hasAI             => this == UserPlan.advancedPlus || this == UserPlan.unlimited;
  bool get hasIntercom       => this == UserPlan.advancedPlus || this == UserPlan.unlimited;
  bool get hasCameras        => this != UserPlan.free && this != UserPlan.basic;
  bool get hasSolar          => this != UserPlan.free && this != UserPlan.basic;
  bool get hasBreakers       => this != UserPlan.free && this != UserPlan.basic;
}

// ─────────────────────────────────────────────────────────────
// Household user model
// ─────────────────────────────────────────────────────────────
class HomeUser {
  final String id;
  String name;
  bool isManager;
  String? imagePath;

  HomeUser({
    required this.id,
    required this.name,
    this.isManager = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id':        id,
    'name':      name,
    'isManager': isManager,
    'imagePath': imagePath,
  };

  factory HomeUser.fromJson(Map<String, dynamic> j) => HomeUser(
    id:        j['id'] as String,
    name:      j['name'] as String? ?? '',
    isManager: j['isManager'] as bool? ?? false,
    imagePath: j['imagePath'] as String?,
  );
}

class AppState extends ChangeNotifier {
  AppState() {
    _initFromPrefs();
  }

  // ── Sign-out bridge ────────────────────────────────────────────────────────
  // The auth gate (main.dart, above MaterialApp) registers itself here so any
  // screen — however deeply nested — can trigger a full sign-out without a
  // callback threaded through every widget in between. Callers MUST have
  // already re-verified the user's identity (password / biometric) before
  // calling [requestSignOut] — this is the actual sign-out, not a prompt.
  VoidCallback? onSignOutRequested;
  void requestSignOut() => onSignOutRequested?.call();

  // ── Installer mode ─────────────────────────────────────────────────────────
  // A technician/installer code — same concept as the "installer code" on a
  // physical alarm panel (Ajax/Risco/Pima all use one). Session-only by
  // design: like a real panel, it doesn't stay unlocked across app restarts.
  bool _installerMode = false;
  bool get installerMode => _installerMode;

  static const _installerCode = '113696';

  /// Verifies [code] and activates Installer Mode for this session on match.
  bool tryUnlockInstallerMode(String code) {
    if (code != _installerCode) return false;
    _installerMode = true;
    notifyListeners();
    return true;
  }

  void exitInstallerMode() {
    _installerMode = false;
    notifyListeners();
  }

  SecurityMode _securityMode = SecurityMode.armedAway;
  ThemeMode _themeMode = ThemeMode.dark; // soft-charcoal single look
  AppThemePrefs _themePrefs = const AppThemePrefs();
  bool _gridLayout = true; // home screen layout: false = classic, true = grid (premium default)
  GatewayManager? _gateways;

  // ── HaProvider subscription ───────────────────────────────────────────────
  // AppState subscribes to HaProvider so that live WebSocket entity updates
  // flow through the single canonical HA connection (HaProvider) rather than
  // a duplicate socket.  Call [attachHaProvider] once from main() after both
  // objects are constructed.
  HaProvider? _haProvider;

  /// Wire [AppState] to receive live entity updates from [HaProvider].
  ///
  /// Must be called exactly once in main() after both notifiers are created.
  /// Every time [HaProvider] emits (initial load or WebSocket push), AppState
  /// upserts the translated [Device] objects.
  void attachHaProvider(HaProvider provider) {
    _haProvider?.removeListener(_onHaProviderUpdate);
    _haProvider = provider;
    _haProvider!.addListener(_onHaProviderUpdate);
    // Fast path: each WS state_changed event updates exactly one device
    // without waiting for the 16 ms debounce or scanning all entities.
    provider.onEntityChanged = _onSingleEntityChanged;
  }

  /// Resolves an HA area id to its human-readable name, if known.
  String? _haAreaName(String? areaId) {
    if (areaId == null) return null;
    final areas = _haProvider?.areas;
    if (areas == null) return null;
    for (final a in areas) {
      if (a.id == areaId) return a.name;
    }
    return null;
  }

  // Called immediately on every WS state_changed event.
  void _onSingleEntityChanged(HaEntity entity) {
    // Resolve sibling battery/temperature entities of the same physical
    // device — without this, a live event would rebuild the device WITHOUT
    // the readings that only the full batch sync merges in, making values
    // like a sensor's temperature vanish until the next registry sync.
    int? siblingBattery;
    double? siblingTemperature;
    final devId = entity.deviceId;
    final provider = _haProvider;
    if (devId != null && provider != null) {
      for (final e in provider.entities) {
        if (e.deviceId != devId) continue;
        final v = e.numericValue;
        if (v == null) continue;
        if (e.deviceClass == 'battery') {
          siblingBattery = v.toInt();
        } else if (e.deviceClass == 'temperature') {
          siblingTemperature = v;
        }
      }
    }

    final device = HaSyncService.entityToDevice(
      entity,
      areaName: _haAreaName(entity.areaId),
      siblingBattery: siblingBattery,
      siblingTemperature: siblingTemperature,
    );
    if (device == null) return;
    if (_removedDeviceIds.contains(device.id)) return;
    final idx = _devices.indexWhere((d) => d.id == device.id);
    if (idx == -1) {
      _devices.add(device);
    } else {
      _devices[idx] = device;
    }
    notifyListeners();
  }

  // Called on initial connect and registry changes — full batch sync.
  // Uses a single notifyListeners() instead of one per entity.
  void _onHaProviderUpdate() {
    final provider = _haProvider;
    if (provider == null || !provider.isConnected) return;
    var changed = _syncHaRooms(provider);
    final liveByEntityId = <String, HaEntity>{};
    for (final entity in provider.entities) {
      liveByEntityId[entity.entityId] = entity;
      final device = HaSyncService.entityToDevice(
        entity,
        areaName: _haAreaName(entity.areaId),
      );
      if (device == null || _removedDeviceIds.contains(device.id)) continue;
      final idx = _devices.indexWhere((d) => d.id == device.id);
      if (idx == -1) {
        _devices.add(device);
        changed = true;
      } else {
        _devices[idx] = device;
        changed = true;
      }
    }
    // One-time cleanup: remove already-persisted HA-sourced devices that no
    // longer classify to a real device type. Before a fix in HaSyncService,
    // a battery/illuminance sibling entity whose entity_id happened to
    // contain "motion"/"water"/etc. was misclassified as its own phantom
    // motion/leak sensor — duplicating the real one. Fixing the
    // classification alone doesn't remove what's already saved, so re-check
    // every stored HA device's live entity here and drop it if it no longer
    // classifies (still respecting explicit user deletions below).
    final before = _devices.length;
    _devices.removeWhere((d) {
      if (d.source != 'gateway' || !d.id.startsWith('ha_')) return false;
      final entityId = d.attributes['entityId'] as String?;
      final live = entityId != null ? liveByEntityId[entityId] : null;
      if (live == null) return false; // entity gone from HA entirely — leave as-is, handled elsewhere
      return HaSyncService.classify(live) == null;
    });
    if (_devices.length != before) changed = true;
    if (changed) {
      _saveDevicesToPrefs();
      notifyListeners();
    }
  }

  /// Mirrors HA's area/floor registries into the app's rooms list:
  /// each HA area becomes a room (marked with 'haAreaId'), each HA floor
  /// becomes a room group. Runs on every registry update, so rooms added,
  /// renamed, or deleted in HA propagate automatically. User-created and
  /// predefined rooms are never touched. Returns true if anything changed.
  bool _syncHaRooms(HaProvider provider) {
    final areas = provider.areas;
    if (areas.isEmpty) return false;
    var changed = false;

    // Floors → room groups.
    final floorIds = areas.map((a) => a.floorId).whereType<String>().toSet();
    for (final fid in floorIds) {
      final gid = 'ha_floor_$fid';
      if (!_roomGroups.any((g) => g['id'] == gid)) {
        _roomGroups.add({'id': gid, 'name': _prettySlug(fid), 'icon': 0xe318});
        changed = true;
      }
    }

    // Areas → rooms.
    for (final a in areas) {
      final gid = a.floorId != null ? 'ha_floor_${a.floorId}' : null;
      final idx = _rooms.indexWhere((r) => r['haAreaId'] == a.id);
      if (idx == -1) {
        // Skip if a user/predefined room already uses this exact name —
        // devices will group under it anyway.
        if (_rooms.any((r) => r['name'] == a.name)) continue;
        _rooms.add({
          'name': a.name,
          'icon': 0xe318,
          'haAreaId': a.id,
          if (gid != null) 'parentGroupId': gid,
        });
        changed = true;
      } else if (_rooms[idx]['name'] != a.name ||
          _rooms[idx]['parentGroupId'] != gid) {
        _rooms[idx] = {
          ..._rooms[idx],
          'name': a.name,
          'parentGroupId': gid,
        };
        changed = true;
      }
    }

    // Areas deleted in HA → remove their mirrored rooms.
    final liveIds = areas.map((a) => a.id).toSet();
    final before = _rooms.length;
    _rooms.removeWhere(
        (r) => r['haAreaId'] != null && !liveIds.contains(r['haAreaId']));
    if (_rooms.length != before) changed = true;

    return changed;
  }

  /// 'first_floor' → 'First Floor' — readable label for HA floor ids
  /// (floor display names aren't in the area registry payload).
  static String _prettySlug(String raw) => raw
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  // ── Ambient light auto-theme ─────────────────────────────────
  final AmbientLightService _lightSensor = AmbientLightService();
  bool _autoTheme = false;
  double? _currentLux;

  void attachGateways(GatewayManager m) {
    _gateways = m;
    _startDeviceMonitor();
  }

  // ── Live device monitor (leak / sensor alerts) ───────────────────────────
  Timer? _monitorTimer;

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _guestTimer?.cancel();
    _haProvider?.removeListener(_onHaProviderUpdate);
    _lightSensor.stop();
    super.dispose();
  }

  /// Polls connected gateways every 60s and merges fresh device state so
  /// sensors (e.g. water-leak) raise an alert the moment they trigger.
  void _startDeviceMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      final gw = _gateways;
      if (gw == null || gw.connections.where((c) => c.isConnected).isEmpty) {
        return;
      }
      final fresh = await gw.fetchAllCurrentDevices();
      _mergeFreshDevices(fresh);
    });
  }

  void _mergeFreshDevices(List<Device> fresh) {
    var changed = false;
    for (final f in fresh) {
      final idx = _devices.indexWhere((d) => d.id == f.id);
      if (idx == -1) continue;
      final cur = _devices[idx];
      final wasDetected = cur.attributes['detected'] == true;
      final nowDetected = f.attributes['detected'] == true;

      cur.status     = f.status;
      cur.isOn       = f.isOn;
      cur.attributes = {...cur.attributes, ...f.attributes};
      changed = true;

      // Rising edge on a sensor → raise an alert.
      if (!wasDetected && nowDetected) {
        _raiseSensorAlert(cur);
      }
    }
    if (changed) notifyListeners();
  }

  /// True for ~30s after a leak is detected, so the UI can show a banner.
  bool _leakAlertActive = false;
  String _leakAlertName = '';
  bool   get leakAlertActive => _leakAlertActive;
  String get leakAlertName   => _leakAlertName;
  void dismissLeakAlert() {
    _leakAlertActive = false;
    notifyListeners();
  }

  void _raiseSensorAlert(Device d) {
    final isLeak = d.type == DeviceType.waterLeakSensor;
    final title = isLeak
        ? '⚠️ Water leak detected — ${d.name}'
        : '⚠️ Alert — ${d.name}';
    _appNotifications.insert(0, AppNotification(
      id: 'alert_${d.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      deviceId: d.id,
      deviceType: d.type,
      timestamp: DateTime.now(),
    ));
    if (isLeak) {
      _leakAlertActive = true;
      _leakAlertName = d.name;
    }
  }
  AppLocale _locale = AppLocale.hebrew;
  bool _keepShabbat = false;
  double _kwhRate = 0.55; // ₪ per kWh — user-configurable
  UserPlan _userPlan = UserPlan.free;
  AdTrack _adTrack = AdTrack.featured;
  String _userName = '';
  String _userEmail = '';
  String? _userImagePath;

  List<HomeUser> _homeUsers = [];
  String? _homePin;
  String? _householdCode;
  int _homeIconCode  = 0xe318; // Symbols.home codepoint
  int _homeColorValue = 0xFF00B4D8; // AppColors.primary

  List<Device> _devices = [];

  /// Ids the user has explicitly deleted. Devices sourced from a live
  /// gateway/HA sync get re-fetched and re-added on every sync cycle by
  /// design (upsertDevice) — without this blocklist, deleting one of them
  /// looked like "delete does nothing" because the very next sync silently
  /// brought it right back.
  Set<String> _removedDeviceIds = {};
  List<AppNotification> _appNotifications = [];
  List<Camera> _cameras = [];
  List<FaceAnalysisResult> _faceAnalysisHistory = [];

  // Media subsystem (smart speakers / TVs / cast targets)
  MediaModule _media = MediaModule();

  // User-created scenes
  List<CustomScene> _customScenes = [];

  // Azure Face API
  String? _azureEndpoint;
  String? _azureApiKey;
  List<KnownPerson> _knownPersons = [];
  List<SecurityEvent> _events = [];
  List<Automation> _automations = [];

  // Rooms — each entry: {name, icon (codePoint), occupant?, parentGroupId?}
  // Default names use translation keys (e.g. '__living__') so they render
  // in the active language. User-renamed rooms keep their custom string.
  // parentGroupId links the room to a _roomGroups entry by id.
  List<Map<String, dynamic>> _rooms = [
    {'name': '__living__',  'icon': 0xe318},
    {'name': '__kitchen__', 'icon': 0xf04c3},
    {'name': '__bedroom__', 'icon': 0xe239},
    {'name': '__bathroom__','icon': 0xe63d},
    {'name': '__garden__',  'icon': 0xf08d8},
  ];

  // Room groups — each entry: {id, name, icon (codePoint), collapsed?}
  List<Map<String, dynamic>> _roomGroups = [];

  SecurityMode get securityMode => _securityMode;
  ThemeMode get themeMode => _themeMode;
  AppThemePrefs get themePrefs => _themePrefs;
  bool get gridLayout => _gridLayout;
  bool   get autoTheme    => _autoTheme;
  double? get currentLux  => _currentLux;
  bool   get lightSensorAvailable => _lightSensor.isRunning;
  AppLocale get locale => _locale;
  bool get keepShabbat => _keepShabbat;
  double get kwhRate => _kwhRate;
  UserPlan get userPlan => _userPlan;
  AdTrack get adTrack => _adTrack;

  // ── Media subsystem ──────────────────────────────────────────
  MediaModule get media => _media;
  List<MediaDevice> get mediaDevices => List.unmodifiable(_media.devices);

  void setMediaEnabled(bool v) {
    _media.enabled = v;
    notifyListeners();
  }

  void setMediaAutoDiscovery(bool v) {
    _media.autoDiscovery = v;
    notifyListeners();
  }

  void setMediaAllowCasting(bool v) {
    _media.allowCasting = v;
    notifyListeners();
  }

  void addMediaDevice(MediaDevice d) {
    if (!_media.devices.any((e) => e.id == d.id)) {
      _media.devices.add(d);
      notifyListeners();
    }
  }

  void removeMediaDevice(String id) {
    _media.devices.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  MediaDevice? _findMedia(String id) {
    for (final d in _media.devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  void toggleMediaPlay(String id) {
    final d = _findMedia(id);
    if (d != null) {
      d.isPlaying = !d.isPlaying;
      notifyListeners();
    }
  }

  void mediaNext(String id) {
    final d = _findMedia(id);
    if (d != null) {
      d.trackIndex++;
      d.progress = 0;
      d.isPlaying = true;
      notifyListeners();
    }
  }

  void mediaPrev(String id) {
    final d = _findMedia(id);
    if (d != null) {
      if (d.trackIndex > 0) d.trackIndex--;
      d.progress = 0;
      d.isPlaying = true;
      notifyListeners();
    }
  }

  /// The device currently playing (for the Now-Playing card), if any.
  MediaDevice? get nowPlaying {
    for (final d in _media.devices) {
      if (d.isPlaying) return d;
    }
    return null;
  }

  void setMediaVolume(String id, int volume) {
    final d = _findMedia(id);
    if (d != null) {
      d.volume = volume.clamp(0, 100);
      notifyListeners();
    }
  }

  void setMediaProgress(String id, int progress) {
    final d = _findMedia(id);
    if (d != null) {
      d.progress = progress.clamp(0, 100);
      notifyListeners();
    }
  }

  // ── Multi-room / group control ───────────────────────────────
  /// Master volume across every online speaker.
  void setAllMediaVolume(int volume) {
    final v = volume.clamp(0, 100);
    for (final d in _media.devices) {
      if (d.isOnline) d.volume = v;
    }
    notifyListeners();
  }

  /// Average volume of online speakers (for the master slider).
  int get masterMediaVolume {
    final online = _media.devices.where((d) => d.isOnline).toList();
    if (online.isEmpty) return 0;
    final sum = online.fold<int>(0, (a, d) => a + d.volume);
    return (sum / online.length).round();
  }

  /// True when more than one speaker is playing together.
  bool get mediaGroupActive =>
      _media.devices.where((d) => d.isPlaying).length > 1;

  /// Party mode — play the same track on all online speakers.
  void mediaPlayAll() {
    // Pick the current track (or the first track) as the group source.
    final src = nowPlaying;
    final idx = src?.trackIndex ?? 0;
    for (final d in _media.devices) {
      if (!d.isOnline) continue;
      d.trackIndex = idx;
      d.progress = src?.progress ?? 0;
      d.isPlaying = true;
    }
    notifyListeners();
  }

  /// Stop every speaker.
  void mediaStopAll() {
    for (final d in _media.devices) {
      d.isPlaying = false;
    }
    notifyListeners();
  }

  void setAdTrack(AdTrack track) {
    _adTrack = track;
    notifyListeners();
  }
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get userImagePath => _userImagePath;
  String get userFirstName => _userName.split(' ').first;
  List<HomeUser> get homeUsers => List.unmodifiable(_homeUsers);
  String? get homePin => _homePin;
  String? get householdCode => _householdCode;
  int   get homeIconCode   => _homeIconCode;
  Color get homeColor      => Color(_homeColorValue);
  bool get hasHomeManager => _homeUsers.any((u) => u.isManager);
  HomeUser? get homeManager {
    try { return _homeUsers.firstWhere((u) => u.isManager); }
    catch (_) { return null; }
  }
  List<Device> get devices => _devices;
  List<AppNotification> get notifications => List.unmodifiable(_appNotifications);
  List<Camera> get cameras => _cameras;
  List<FaceAnalysisResult> get faceAnalysisHistory =>
      List.unmodifiable(_faceAnalysisHistory);
  List<SecurityEvent> get events => _events;

  // Azure Face API
  String? get azureEndpoint  => _azureEndpoint;
  String? get azureApiKey    => _azureApiKey;
  bool get hasAzureConfig    =>
      _azureEndpoint != null && _azureApiKey != null &&
      _azureEndpoint!.isNotEmpty && _azureApiKey!.isNotEmpty;
  List<KnownPerson> get knownPersons => List.unmodifiable(_knownPersons);

  AzureFaceService? get azureFaceService => hasAzureConfig
      ? AzureFaceService(
          endpoint: _azureEndpoint!,
          apiKey:   _azureApiKey!,
        )
      : null;
  List<Automation> get automations => _automations;
  List<Map<String, dynamic>> get rooms       => List.unmodifiable(_rooms);
  List<Map<String, dynamic>> get roomGroups  => List.unmodifiable(_roomGroups);

  /// Rooms with no parentGroupId — shown at root level.
  List<Map<String, dynamic>> get rootRooms =>
      List.unmodifiable(_rooms.where((r) => r['parentGroupId'] == null).toList());

  /// Rooms belonging to a specific group.
  List<Map<String, dynamic>> roomsInGroup(String groupId) =>
      List.unmodifiable(_rooms.where((r) => r['parentGroupId'] == groupId).toList());

  bool get isSecured => _securityMode.isArmed;

  int get devicesOnlineCount =>
      _devices.where((d) => d.status == DeviceStatus.online).length;

  // ── Cyber security computed properties ──────────────────────────────────

  /// Real cyber score 0–100 based on actual device/gateway/security state.
  int get cyberScore {
    int score = 50; // baseline

    final total   = _devices.length;
    final online  = devicesOnlineCount;
    final offline = total - online;
    final gwCount = _gateways?.connections.where((c) => c.isConnected).length ?? 0;

    // Security mode armed → good
    if (isSecured) score += 15;

    // No active leak alert → good
    if (!_leakAlertActive) score += 10;

    // All devices online
    if (total > 0 && offline == 0) score += 10;
    else if (total > 0) score -= (offline * 3).clamp(0, 15);

    // Gateways connected (encrypted channel)
    score += (gwCount * 5).clamp(0, 10);

    // User has an email (account configured)
    if (_userEmail.isNotEmpty) score += 5;

    // Penalties
    if (_leakAlertActive) score -= 25;
    if (_securityMode == SecurityMode.disarmed && total > 0) score -= 5;

    return score.clamp(0, 100);
  }

  /// Active threat count — real events from the last 24h marked as alerts.
  int get cyberThreatCount {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    int count = _events.where((e) => e.isAlert && e.timestamp.isAfter(cutoff)).length;
    if (_leakAlertActive) count++;
    return count;
  }

  /// Last 4 security events (most recent first) for cyber screen.
  /// Real cyber-security events only. Empty until a backend/monitor reports
  /// genuine events — the screen shows a localized "no recent events" state
  /// rather than fake demo data.
  final List<SecurityEvent> _cyberEvents = [];
  List<SecurityEvent> get recentCyberEvents {
    final sorted = [..._cyberEvents]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(4).toList();
  }

  // VPN state (UI toggle — links to Tailscale)
  bool _vpnEnabled = false;
  bool get vpnEnabled => _vpnEnabled;
  void setVpnEnabled(bool v) {
    _vpnEnabled = v;
    notifyListeners();
  }

  int get automationsActiveCount =>
      _automations.where((a) => a.isEnabled).length;

  Locale get flutterLocale {
    switch (_locale) {
      case AppLocale.english:
        return const Locale('en');
      case AppLocale.arabic:
        return const Locale('ar');
      case AppLocale.amharic:
        return const Locale('am');
      case AppLocale.spanish:
        return const Locale('es');
      case AppLocale.russian:
        return const Locale('ru');
      case AppLocale.french:
        return const Locale('fr');
      case AppLocale.hebrew:
        return const Locale('he');
    }
  }

  bool get isRtl => _locale == AppLocale.hebrew || _locale == AppLocale.arabic;

  S get strings => S.of(_locale);

  void setSecurityMode(SecurityMode mode) {
    _securityMode = mode;
    notifyListeners();
  }

  void toggleSecurity() {
    _securityMode = isSecured ? SecurityMode.disarmed : SecurityMode.armedAway;
    _guestTimer?.cancel();
    _guestTimer = null;
    notifyListeners();
  }

  // ── Guest / Welcome mode ──────────────────────────────────────────────────

  Timer? _guestTimer;

  /// Remaining seconds of guest mode (0 when not active).
  int _guestSecondsLeft = 0;
  int get guestSecondsLeft => _guestSecondsLeft;
  bool get isGuestMode => _securityMode.isGuest;

  /// Disarm the system, unlock the front door, and auto-rearm after [minutes].
  void welcomeGuest({int minutes = 5}) {
    _guestTimer?.cancel();
    _securityMode = SecurityMode.guest;
    _guestSecondsLeft = minutes * 60;

    // Unlock first smart-lock found
    final lock = _devices.firstWhere(
      (d) => d.type == DeviceType.smartLock,
      orElse: () => Device(id: '', name: '', type: DeviceType.smartLock),
    );
    if (lock.id.isNotEmpty) {
      lock.isOn = false; // unlock
    }

    notifyListeners();

    // Tick every second for the countdown
    _guestTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _guestSecondsLeft--;
      if (_guestSecondsLeft <= 0) {
        t.cancel();
        _guestTimer = null;
        _guestSecondsLeft = 0;
        _securityMode = SecurityMode.armedAway;
        // Re-lock front door
        if (lock.id.isNotEmpty) lock.isOn = true;
      }
      notifyListeners();
    });
  }

  void cancelGuestMode() {
    _guestTimer?.cancel();
    _guestTimer = null;
    _guestSecondsLeft = 0;
    _securityMode = SecurityMode.armedAway;
    notifyListeners();
  }

  void toggleDevice(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    final wantOn = !device.isOn;
    // Optimistic UI update — feels instant to the user.
    device.isOn = wantOn;
    notifyListeners();
    // Fire-and-forget: send the actual command to the physical device.
    final gw = _gateways;
    if (gw != null) {
      DeviceCommander.setOnOff(device, wantOn, gateways: gw).then((ok) {
        if (!ok) {
          // Revert UI if the command failed (gateway offline, wrong creds, …)
          device.isOn = !wantOn;
          notifyListeners();
        }
      });
    }
  }

  /// Deterministic, awaitable power set — unlike [toggleDevice] this doesn't
  /// just flip the current state, and it actually reports whether the
  /// physical command succeeded. Built for the AI agent: it must never claim
  /// an action succeeded without a real confirmation from the gateway layer.
  Future<bool> setDevicePower(String id, bool on) async {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx == -1) return false;
    final device = _devices[idx];
    final was = device.isOn;
    device.isOn = on;
    notifyListeners();
    final gw = _gateways;
    if (gw == null) return true; // no gateway configured — local-only device
    final ok = await DeviceCommander.setOnOff(device, on, gateways: gw);
    if (!ok) {
      device.isOn = was;
      notifyListeners();
    }
    return ok;
  }

  /// Awaitable brightness set (0-100) — same "confirm before claiming
  /// success" contract as [setDevicePower], for the AI agent.
  Future<bool> agentSetBrightness(String id, int level) async {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx == -1) return false;
    final gw = _gateways;
    if (gw == null) return false;
    return DeviceCommander.setBrightness(_devices[idx], level, gateways: gw);
  }

  /// Awaitable cover/blind/valve position set (0-100) for the AI agent.
  Future<bool> agentSetCoverPosition(String id, int position) async {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx == -1) return false;
    final gw = _gateways;
    if (gw == null) return false;
    final ok = await DeviceCommander.setCoverPosition(_devices[idx], position,
        gateways: gw);
    if (ok) {
      _devices[idx].attributes = {..._devices[idx].attributes, 'position': position};
      notifyListeners();
    }
    return ok;
  }

  /// Awaitable climate set for the AI agent — only one of the named
  /// parameters should be supplied per call, mirroring [DeviceCommander.setClimate].
  Future<bool> agentSetClimate(String id,
      {String? hvacMode, double? temperature, String? fanMode}) async {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx == -1) return false;
    final gw = _gateways;
    if (gw == null) return false;
    return DeviceCommander.setClimate(_devices[idx],
        hvacMode: hvacMode,
        temperature: temperature,
        fanMode: fanMode,
        gateways: gw);
  }

  void toggleFavorite(String id) {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    _devices[idx].isFavorite = !_devices[idx].isFavorite;
    notifyListeners();
    _saveDevicesToPrefs();
  }

  void setCoverPosition(String id, int position) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.attributes = {...device.attributes, 'position': position};
    notifyListeners();
    final gw = _gateways;
    if (gw != null) {
      DeviceCommander.setCoverPosition(device, position, gateways: gw);
    }
  }

  void stopCover(String id) {
    final gw = _gateways;
    if (gw == null) return;
    final device = _devices.firstWhere((d) => d.id == id);
    DeviceCommander.stopCover(device, gateways: gw);
  }

  void vacuumCommand(String id, VacuumAction action) {
    final gw = _gateways;
    if (gw == null) return;
    final device = _devices.firstWhere((d) => d.id == id);
    DeviceCommander.vacuumCommand(device, action, gateways: gw);
  }

  void setDeviceAttribute(String id, String key, dynamic value) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.attributes = {...device.attributes, key: value};
    notifyListeners();

    final gw = _gateways;
    if (gw == null) return;

    // Fire-and-forget: mirror brightness to the physical light/dimmer —
    // without this the slider only edits the local attribute map.
    if (key == 'brightness' && value is num) {
      DeviceCommander.setBrightness(device, value.toInt(), gateways: gw);
      return;
    }

    // Fire-and-forget: mirror climate changes to the physical AC. Without
    // this, mode/fan/temp controls only edit the local attribute map and
    // never reach the real device.
    if (device.type == DeviceType.airConditioner) {
      switch (key) {
        case 'mode':
          DeviceCommander.setClimate(device,
              hvacMode: value as String, gateways: gw);
          break;
        case 'temperature':
          DeviceCommander.setClimate(device,
              temperature: (value as num).toDouble(), gateways: gw);
          break;
        case 'fan':
          DeviceCommander.setClimate(device,
              fanMode: value as String, gateways: gw);
          break;
        case 'swingMode':
          DeviceCommander.setClimate(device,
              swingMode: value as String, gateways: gw);
          break;
        case 'presetMode':
          DeviceCommander.setClimate(device,
              presetMode: value as String, gateways: gw);
          break;
      }
    }
  }

  void toggleAutomation(String id) {
    final auto = _automations.firstWhere((a) => a.id == id);
    auto.isEnabled = !auto.isEnabled;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    // Manual theme change → disable auto-theme
    if (_autoTheme) {
      _autoTheme = false;
      _lightSensor.stop();
      SharedPreferences.getInstance().then((p) => p.setBool('auto_theme', false));
    }
    _themeMode = mode;
    notifyListeners();
  }

  /// Light theme during daytime (06:00–18:00), dark in the evening/night.
  ThemeMode _themeByHour() {
    final h = DateTime.now().hour;
    return (h >= 6 && h < 18) ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setAutoTheme(bool enabled) async {
    _autoTheme = enabled;
    if (enabled) {
      final ok = await _lightSensor.start(
        onChanged: (mode, lux) {
          _currentLux = lux;
          _themeMode  = mode;
          notifyListeners();
        },
      );
      // If there's no ambient-light sensor, still adapt by time of day so the
      // "auto" mode remains useful instead of silently turning off.
      if (!ok) _themeMode = _themeByHour();
    } else {
      _lightSensor.stop();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_theme', _autoTheme);
    notifyListeners();
  }

  void setGridLayout(bool value) {
    _gridLayout = value;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('ft_grid_layout', value));
  }

  void setThemePrefs(AppThemePrefs prefs) {
    _themePrefs = prefs;
    // Auto-switch ThemeMode when a light/dark bg style is selected
    if (prefs.bgStyle.isLight && _themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
    } else if (!prefs.bgStyle.isLight && _themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    }
    _saveThemePrefs();
    notifyListeners();
  }

  void setLocale(AppLocale locale) {
    _locale = locale;
    // Auto-enable Shabbat when switching to Hebrew (if user never changed it)
    SharedPreferences.getInstance().then((p) {
      p.setString('ft_locale', locale.name);
      if (!p.containsKey('ft_shabbat') && locale == AppLocale.hebrew) {
        _keepShabbat = true;
        p.setBool('ft_shabbat', true);
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void setKeepShabbat(bool v) {
    _keepShabbat = v;
    SharedPreferences.getInstance().then((p) => p.setBool('ft_shabbat', v));
    notifyListeners();
  }

  void setKwhRate(double rate) {
    if (rate <= 0) return;
    _kwhRate = rate;
    SharedPreferences.getInstance().then((p) => p.setDouble('ft_kwh_rate', rate));
    notifyListeners();
  }

  Map<String, dynamic> exportBackup() => {
    'version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'kwh_rate': _kwhRate,
    'keep_shabbat': _keepShabbat,
    'devices': _devices.map((d) => d.toJson()).toList(),
    'automations': _automations.map((a) => {
      'id': a.id,
      'name': a.name,
      'condition': a.condition,
      'action': a.action,
      'is_enabled': a.isEnabled,
    }).toList(),
    'rooms': _rooms
        .where((r) => !(r['key'] as String? ?? '').startsWith('__'))
        .toList(),
  };

  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    final existingIds = _devices.map((d) => d.id).toSet();
    for (final raw in (data['devices'] as List? ?? [])) {
      try {
        final d = Device.fromJson(raw as Map<String, dynamic>);
        if (!existingIds.contains(d.id)) _devices.add(d);
      } catch (_) {}
    }
    final existingAIds = _automations.map((a) => a.id).toSet();
    for (final raw in (data['automations'] as List? ?? [])) {
      try {
        final m = raw as Map<String, dynamic>;
        final id = m['id'] as String? ?? '';
        if (id.isNotEmpty && !existingAIds.contains(id)) {
          _automations.add(Automation(
            id: id,
            name: m['name'] as String? ?? '',
            condition: m['condition'] as String? ?? '',
            action: m['action'] as String? ?? '',
            isEnabled: m['is_enabled'] as bool? ?? true,
          ));
        }
      } catch (_) {}
    }
    final existingNames =
        _rooms.map((r) => r['name'] as String? ?? '').toSet();
    for (final raw in (data['rooms'] as List? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final name = m['name'] as String? ?? '';
      if (name.isNotEmpty && !existingNames.contains(name)) {
        _rooms.add(m);
      }
    }
    if (data.containsKey('kwh_rate')) {
      final r = (data['kwh_rate'] as num?)?.toDouble() ?? _kwhRate;
      if (r > 0) {
        _kwhRate = r;
        final p = await SharedPreferences.getInstance();
        await p.setDouble('ft_kwh_rate', r);
      }
    }
    if (data.containsKey('keep_shabbat')) {
      _keepShabbat = data['keep_shabbat'] as bool? ?? _keepShabbat;
      final p = await SharedPreferences.getInstance();
      await p.setBool('ft_shabbat', _keepShabbat);
    }
    notifyListeners();
  }

  void setUserPlan(UserPlan plan) {
    _userPlan = plan;
    notifyListeners();
  }

  void setUserName(String name) {
    if (name.trim().isNotEmpty) {
      _userName = name.trim();
      notifyListeners();
      SharedPreferences.getInstance()
          .then((p) => p.setString('ft_user_name', _userName));
    }
  }

  void setUserEmail(String email) {
    if (email.trim().isNotEmpty) {
      _userEmail = email.trim();
      notifyListeners();
      SharedPreferences.getInstance()
          .then((p) => p.setString('ft_user_email', _userEmail));
    }
  }

  /// Copy [pickedPath] (temporary picker path) to app documents dir so it
  /// survives restarts. Pass null to clear the image.
  Future<void> setUserImage(String? pickedPath) async {
    if (pickedPath == null) {
      _userImagePath = null;
    } else {
      final dir    = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${dir.path}/profile_images');
      await imgDir.create(recursive: true);
      final dest = '${imgDir.path}/user_avatar.jpg';
      await File(pickedPath).copy(dest);
      _userImagePath = dest;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_userImagePath != null) {
      await prefs.setString('user_image_path', _userImagePath!);
    } else {
      await prefs.remove('user_image_path');
    }
    notifyListeners();
  }

  /// Copy [pickedPath] to permanent storage for a household member.
  Future<void> setHomeUserImage(String userId, String? pickedPath) async {
    final idx = _homeUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) return;
    if (pickedPath == null) {
      _homeUsers[idx].imagePath = null;
    } else {
      final dir    = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${dir.path}/profile_images');
      await imgDir.create(recursive: true);
      final dest = '${imgDir.path}/member_$userId.jpg';
      await File(pickedPath).copy(dest);
      _homeUsers[idx].imagePath = dest;
    }
    await _saveHomeUsers();
    notifyListeners();
  }

  // ── Home users (manager + household members) ─────────────────
  void registerAsHomeManager({String? name}) {
    if (!hasHomeManager) {
      // Generate a 6-digit household joining code
      _householdCode ??= (100000 + _math.Random().nextInt(900000)).toString();
      _homeUsers.insert(0, HomeUser(
        id: 'manager_${DateTime.now().millisecondsSinceEpoch}',
        name: name ?? _userName,
        isManager: true,
        imagePath: _userImagePath,
      ));
      _saveHomeUsers();
      notifyListeners();
    }
  }

  /// True when the signed-in user is allowed to invite/remove/rename
  /// household members or regenerate the join code. Both roles can operate
  /// the home day-to-day — only [Permission.manageUsers] gates *who else*
  /// is in the home.
  bool get canManageHousehold =>
      UserService.currentUser?.can(Permission.manageUsers) ?? false;

  /// Regenerate the household joining code (e.g. if shared by mistake).
  /// Returns the unchanged code (silently) if the caller lacks permission.
  String regenerateHouseholdCode() {
    if (!canManageHousehold) return _householdCode ?? '';
    _householdCode = (100000 + _math.Random().nextInt(900000)).toString();
    _saveHomeUsers(); // code is stored alongside home users
    notifyListeners();
    return _householdCode!;
  }

  void addHouseholdMember(String name) {
    if (!canManageHousehold) return;
    _homeUsers.add(HomeUser(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isManager: false,
    ));
    _saveHomeUsers();
    notifyListeners();
  }

  void removeHomeUser(String id) {
    if (!canManageHousehold) return;
    _homeUsers.removeWhere((u) => u.id == id);
    _saveHomeUsers();
    notifyListeners();
  }

  Future<void> renameHomeUser(String id, String newName) async {
    if (!canManageHousehold) return;
    final idx = _homeUsers.indexWhere((u) => u.id == id);
    if (idx == -1 || newName.trim().isEmpty) return;
    _homeUsers[idx].name = newName.trim();
    await _saveHomeUsers();
    notifyListeners();
  }

  void setHomePin(String? pin) {
    _homePin = (pin == null || pin.isEmpty) ? null : pin;
    notifyListeners();
  }

  void setHomeIcon(int codePoint) {
    _homeIconCode = codePoint;
    notifyListeners();
    _saveHomeStyle();
  }

  void setHomeColor(int colorValue) {
    _homeColorValue = colorValue;
    notifyListeners();
    _saveHomeStyle();
  }

  Future<void> _saveHomeStyle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_icon_code',   _homeIconCode);
    await prefs.setInt('home_color_value', _homeColorValue);
  }

  /// מוסיף מכשיר חדש או מעדכן קיים (לפי id) — משמש ע"י HaSyncService וגם
  /// ע"י כל מסכי הצימוד, כדי שחיבור חוזר של אותו מכשיר יעדכן את פרטי
  /// החיבור (IP/host/token חדשים) במקום להתעלם מהם.
  void upsertDevice(Device device) {
    final idx = _devices.indexWhere((d) => d.id == device.id);
    if (idx == -1) {
      if (_removedDeviceIds.contains(device.id)) return;
      _devices.add(device);
      _appNotifications.insert(0, AppNotification(
        id: 'notif_${device.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: device.name,
        deviceId: device.id,
        deviceType: device.type,
        timestamp: DateTime.now(),
      ));
    } else {
      _devices[idx] = device;
    }
    _saveDevicesToPrefs();
    notifyListeners();
  }

  void removeDevice(String id) {
    _devices.removeWhere((d) => d.id == id);
    _removedDeviceIds.add(id);
    _saveDevicesToPrefs();
    _saveRemovedDeviceIds();
    notifyListeners();
  }

  /// Allows a previously-deleted device to be re-imported by discovery/sync
  /// again (e.g. the user re-scans and explicitly wants it back).
  void undeleteDevice(String id) {
    if (_removedDeviceIds.remove(id)) {
      _saveRemovedDeviceIds();
    }
  }

  Future<void> _saveRemovedDeviceIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ft_removed_device_ids', _removedDeviceIds.toList());
  }

  Future<void> clearAllDevices() async {
    _devices.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ft_devices');
    notifyListeners();
  }

  void updateDeviceName(String id, String name) {
    final device = _devices.firstWhere((d) => d.id == id, orElse: () => throw StateError('not found'));
    device.name = name;
    _saveDevicesToPrefs();
    notifyListeners();
  }

  void updateDeviceRoom(String id, String room) {
    final device = _devices.firstWhere((d) => d.id == id, orElse: () => throw StateError('not found'));
    device.room = room;
    _saveDevicesToPrefs();
    notifyListeners();
  }

  // ── Notifications ────────────────────────────────────────────
  void markNotificationRead(String id) {
    final idx = _appNotifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _appNotifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in _appNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void dismissNotification(String id) {
    _appNotifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearNotifications() {
    _appNotifications.clear();
    notifyListeners();
  }

  // ── SharedPreferences persistence ────────────────────────────
  Future<void> _initFromPrefs() async {
    await _loadHomeUsers(); // images + home users (needs no prefs instance)
    final prefs = await SharedPreferences.getInstance();
    // Load persisted locale (before anything below that depends on it,
    // e.g. the Shabbat-mode default check).
    final savedLocaleName = prefs.getString('ft_locale');
    if (savedLocaleName != null) {
      _locale = AppLocale.values.firstWhere(
        (e) => e.name == savedLocaleName,
        orElse: () => AppLocale.hebrew,
      );
    }
    // Load persisted user profile
    _userName      = prefs.getString('ft_user_name')  ?? '';
    _userEmail     = prefs.getString('ft_user_email') ?? '';
    _userImagePath = prefs.getString('user_image_path');
    // Fallback: sync name from UserService if not yet set
    if (_userName.isEmpty) {
      final cu = UserService.currentUser;
      if (cu != null && cu.name.isNotEmpty) {
        _userName  = cu.name;
        _userEmail = cu.email.isNotEmpty ? cu.email : _userEmail;
      }
    }
    // Shabbat mode — default true for Hebrew locale (first-run)
    final savedShabbat = prefs.getBool('ft_shabbat');
    _keepShabbat = savedShabbat ?? (_locale == AppLocale.hebrew);
    // Energy rate
    _kwhRate = prefs.getDouble('ft_kwh_rate') ?? 0.55;
    if (savedShabbat == null && _locale == AppLocale.hebrew) {
      await prefs.setBool('ft_shabbat', true);
    }

    final jsonList = prefs.getStringList('ft_devices') ?? [];
    if (jsonList.isNotEmpty) {
      _devices = jsonList
          .map((s) => Device.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }
    _removedDeviceIds = (prefs.getStringList('ft_removed_device_ids') ?? [])
        .toSet();
    final cameraJsonList = prefs.getStringList('ft_cameras') ?? [];
    if (cameraJsonList.isNotEmpty) {
      _cameras = cameraJsonList
          .map((s) => Camera.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }
    // Load home style
    _homeIconCode   = prefs.getInt('home_icon_code')   ?? _homeIconCode;
    _homeColorValue = prefs.getInt('home_color_value') ?? _homeColorValue;
    _gridLayout     = prefs.getBool('ft_grid_layout')  ?? true;
    // Load theme prefs
    final tpFont    = prefs.getString('tp_font');
    final tpAccent  = prefs.getInt('tp_accent');
    final tpBg      = prefs.getString('tp_bg');
    final tpRadius  = prefs.getString('tp_radius');
    if (tpFont != null || tpAccent != null || tpBg != null || tpRadius != null) {
      _themePrefs = AppThemePrefs.fromMap({
        'font':    tpFont    ?? 'inter',
        'accent':  tpAccent  ?? 0xFFFF6B00,
        'bgStyle': tpBg      ?? 'darkBlue',
        'radius':  tpRadius  ?? 'normal',
      });
      // Keep theme mode in sync with a saved light/dark surface style.
      _themeMode = _themePrefs.bgStyle.isLight ? ThemeMode.light : ThemeMode.dark;
    }
    // ── Theme schema migration ─────────────────────────────────────
    // A single integer key replaces the 8 boolean flags used in earlier
    // builds.  Existing installs that already ran all flags (detected by
    // theme_charcoal_v1 == true) are stamped to the current version
    // without any preference changes.  Fresh installs receive the final
    // target state in one atomic write.  Old flag keys are cleaned up.
    const int    _kThemeSchemaVersion = 8;
    const String _kThemeSchemaKey     = 'theme_schema_v';
    final int schemaVersion = prefs.getInt(_kThemeSchemaKey) ?? 0;
    if (schemaVersion < _kThemeSchemaVersion) {
      final alreadyMigrated = prefs.getBool('theme_charcoal_v1') ?? false;
      if (!alreadyMigrated) {
        _themeMode  = ThemeMode.light;
        _themePrefs = _themePrefs.copyWith(
          bgStyle: AppBgStyle.lightGray,
          accent: const Color(0xFFFF6B00),
        );
        await prefs.setString('tp_bg', AppBgStyle.lightGray.name);
        await prefs.setInt('tp_accent', 0xFFFF6B00);
        await prefs.setBool('auto_theme', false);
      }
      await prefs.setInt(_kThemeSchemaKey, _kThemeSchemaVersion);
      for (final key in const [
        'theme_charcoal_v1', 'theme_orange_v1', 'theme_navy_v1',
        'theme_orange_v2',   'theme_orange_v3', 'theme_twomode_v1',
        'theme_autooff_v1',  'theme_light_v1',
      ]) {
        await prefs.remove(key);
      }
    }
    // Load Azure credentials + known persons
    await loadAzureCredentials();
    final personsList = prefs.getStringList('known_persons') ?? [];
    _knownPersons = personsList
        .map((s) => KnownPerson.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    // Load custom scenes
    final sceneList = prefs.getStringList('ft_scenes') ?? [];
    _customScenes = sceneList
        .map((s) => CustomScene.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    // Restore ambient-light auto-theme if it was enabled
    final savedAutoTheme = prefs.getBool('auto_theme') ?? false;
    if (savedAutoTheme) {
      // Don't await — sensor start is fire-and-forget; UI rebuilds via callback
      setAutoTheme(true);
    }
    notifyListeners();
  }

  Future<void> _saveThemePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final m = _themePrefs.toMap();
    await prefs.setString('tp_font',   m['font']    as String);
    await prefs.setInt   ('tp_accent', m['accent']  as int);
    await prefs.setString('tp_bg',     m['bgStyle'] as String);
    await prefs.setString('tp_radius', m['radius']  as String);
  }

  Future<void> _saveDevicesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _devices.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList('ft_devices', jsonList);
  }

  Future<void> _saveCamerasToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cameras.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('ft_cameras', jsonList);
  }

  // ── Camera management ────────────────────────────────────────
  void addRealCamera(Camera camera) {
    if (!_cameras.any((c) => c.id == camera.id)) {
      _cameras.add(camera);
      _saveCamerasToPrefs();
      notifyListeners();
    }
  }

  void removeCamera(String id) {
    _cameras.removeWhere((c) => c.id == id);
    _saveCamerasToPrefs();
    notifyListeners();
  }

  void updateCameraName(String id, String name) {
    final camera = _cameras.firstWhere((c) => c.id == id,
        orElse: () => throw StateError('not found'));
    camera.name = name;
    _saveCamerasToPrefs();
    notifyListeners();
  }

  void updateCameraOnlineStatus(String id, bool isOnline) {
    final idx = _cameras.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _cameras[idx].isOnline = isOnline;
      notifyListeners();
    }
  }

  // ── Face Analysis history ─────────────────────────────────────
  void addFaceAnalysisResult(FaceAnalysisResult result) {
    _faceAnalysisHistory.insert(0, result); // newest first
    // Keep last 200 results
    if (_faceAnalysisHistory.length > 200) {
      _faceAnalysisHistory = _faceAnalysisHistory.take(200).toList();
    }
    notifyListeners();
  }

  void clearFaceAnalysisHistory() {
    _faceAnalysisHistory.clear();
    notifyListeners();
  }

  // ── Azure Face API settings ───────────────────────────────────
  void setAzureCredentials(String endpoint, String apiKey) {
    _azureEndpoint = endpoint.trim();
    _azureApiKey   = apiKey.trim();
    notifyListeners();
    _saveAzureCredentials();
  }

  Future<void> _saveAzureCredentials() async {
    await SecureCredService.saveAzureEndpoint(_azureEndpoint ?? '');
    await SecureCredService.saveAzureKey(_azureApiKey ?? '');
  }

  Future<void> loadAzureCredentials() async {
    _azureEndpoint = await SecureCredService.readAzureEndpoint();
    _azureApiKey   = await SecureCredService.readAzureKey();
    // Load known persons (non-sensitive — stays in SharedPreferences)
    final prefs    = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('known_persons') ?? [];
    _knownPersons  = jsonList
        .map((s) => KnownPerson.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  // ── Known persons ─────────────────────────────────────────────
  void addKnownPerson(KnownPerson person) {
    _knownPersons.removeWhere((p) => p.id == person.id);
    _knownPersons.add(person);
    notifyListeners();
    _saveKnownPersons();
  }

  void updateKnownPerson(KnownPerson person) {
    final idx = _knownPersons.indexWhere((p) => p.id == person.id);
    if (idx >= 0) {
      _knownPersons[idx] = person;
      notifyListeners();
      _saveKnownPersons();
    }
  }

  void removeKnownPerson(String id) {
    _knownPersons.removeWhere((p) => p.id == id);
    notifyListeners();
    _saveKnownPersons();
  }

  Future<void> _saveKnownPersons() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _knownPersons
        .map((p) => jsonEncode(p.toJson()))
        .toList();
    await prefs.setStringList('known_persons', jsonList);
  }

  void activateEmergencyMode() {
    _securityMode = SecurityMode.armedAway;
    notifyListeners();
  }

  void addAutomation(Automation automation) {
    _automations.add(automation);
    notifyListeners();
  }

  void updateAutomation(String id, {
    required String name,
    required String condition,
    required String action,
  }) {
    final idx = _automations.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      final wasEnabled = _automations[idx].isEnabled;
      _automations[idx] = Automation(
        id: id,
        name: name,
        condition: condition,
        action: action,
        isEnabled: wasEnabled,
      );
      notifyListeners();
    }
  }

  void deleteAutomation(String id) {
    _automations.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ── Rooms CRUD ───────────────────────────────────────────────
  void addRoom(String name, int iconCodePoint,
      {String? occupant, String? parentGroupId}) {
    final newRoom = {
      'name': name,
      'icon': iconCodePoint,
      if (occupant != null) 'occupant': occupant,
      if (parentGroupId != null) 'parentGroupId': parentGroupId,
    };
    // Insert right after the last room that follows __bedroom__
    // (so new rooms stack up after the bedroom card, not at the end).
    final bedroomIdx = _rooms.indexWhere(
        (r) => (r['key'] as String? ?? '') == '__bedroom__');
    if (bedroomIdx >= 0) {
      // find the position after __bedroom__ and any user rooms already placed there
      int insertAt = bedroomIdx + 1;
      while (insertAt < _rooms.length &&
          !(_rooms[insertAt]['key'] as String? ?? '').startsWith('__')) {
        insertAt++;
      }
      _rooms.insert(insertAt, newRoom);
    } else {
      _rooms.add(newRoom);
    }
    notifyListeners();
  }

  void editRoom(int index, String name, int iconCodePoint,
      {String? occupant, String? parentGroupId}) {
    if (index >= 0 && index < _rooms.length) {
      _rooms[index] = {
        'name': name,
        'icon': iconCodePoint,
        if (occupant != null) 'occupant': occupant,
        // preserve existing parentGroupId if caller doesn't specify a new one
        'parentGroupId': parentGroupId ?? _rooms[index]['parentGroupId'],
      };
      notifyListeners();
    }
  }

  void deleteRoom(int index) {
    if (index >= 0 && index < _rooms.length) {
      _rooms.removeAt(index);
      notifyListeners();
    }
  }

  // ── Room Groups CRUD ─────────────────────────────────────────
  void addRoomGroup(String id, String name, int iconCodePoint) {
    if (_roomGroups.any((g) => g['id'] == id)) return;
    _roomGroups.add({'id': id, 'name': name, 'icon': iconCodePoint, 'collapsed': false});
    notifyListeners();
  }

  void editRoomGroup(String id, String name, int iconCodePoint) {
    final idx = _roomGroups.indexWhere((g) => g['id'] == id);
    if (idx >= 0) {
      _roomGroups[idx] = {
        ..._roomGroups[idx],
        'name': name,
        'icon': iconCodePoint,
      };
      notifyListeners();
    }
  }

  void setRoomGroupCollapsed(String id, bool collapsed) {
    final idx = _roomGroups.indexWhere((g) => g['id'] == id);
    if (idx >= 0) {
      _roomGroups[idx] = {..._roomGroups[idx], 'collapsed': collapsed};
      notifyListeners();
    }
  }

  void deleteRoomGroup(String id) {
    _roomGroups.removeWhere((g) => g['id'] == id);
    // Unparent rooms that belonged to this group
    for (var i = 0; i < _rooms.length; i++) {
      if (_rooms[i]['parentGroupId'] == id) {
        _rooms[i] = Map.from(_rooms[i])..remove('parentGroupId');
      }
    }
    notifyListeners();
  }

  // ── Target temperature ───────────────────────────────────────
  double _targetTemp = 22.0;
  double get targetTemp => _targetTemp;

  void setTargetTemp(double temp) {
    _targetTemp = temp.clamp(16.0, 30.0);
    // sync all AC devices to the new setpoint
    for (final d in _devices) {
      if (d.type == DeviceType.airConditioner) {
        d.attributes = {...d.attributes, 'setpoint': _targetTemp};
        d.isOn = true;
      }
    }
    notifyListeners();
  }

  // ── Scenes ───────────────────────────────────────────────────

  /// Turn every light on or off (used by the AI assistant "lights" intent).
  void setAllLights(bool on) {
    for (final d in _devices) {
      if (d.type == DeviceType.light) d.isOn = on;
    }
    notifyListeners();
  }

  void activateQuietMode() {
    for (final device in _devices) {
      if (device.type == DeviceType.light ||
          device.type == DeviceType.airConditioner ||
          device.type == DeviceType.smartPlug) {
        device.isOn = false;
      }
    }
    notifyListeners();
  }

  /// יציאה מהבית — כיבוי אורות, AC, שקעים; סגירת תריסים; הפעלת אבטחה
  /// בוקר טוב — אורות, תריסים פתוחים, AC על 22°C
  void activateGoodMorning() {
    for (final d in _devices) {
      switch (d.type) {
        case DeviceType.light:
          d.isOn = true;
          d.attributes = {...d.attributes, 'brightness': 80};
          break;
        case DeviceType.blind:
          d.isOn = false;
          d.attributes = {...d.attributes, 'position': 100};
          break;
        case DeviceType.airConditioner:
          d.isOn = true;
          d.attributes = {...d.attributes, 'setpoint': 22.0, 'mode': 'cool'};
          break;
        default:
          break;
      }
    }
    _targetTemp = 22.0;
    _securityMode = SecurityMode.disarmed;
    notifyListeners();
  }

  void activateLeaveHome() {
    for (final d in _devices) {
      switch (d.type) {
        case DeviceType.light:
        case DeviceType.airConditioner:
        case DeviceType.smartPlug:
        case DeviceType.waterHeater:
          d.isOn = false;
          break;
        case DeviceType.blind:
          d.isOn = true; // closed = on for blinds
          d.attributes = {...d.attributes, 'position': 0};
          break;
        default:
          break;
      }
    }
    _securityMode = SecurityMode.armedAway;
    notifyListeners();
  }

  /// כיבוי כל הבית — הכל כבוי
  void activateTurnOffAll() {
    for (final d in _devices) {
      if (d.type != DeviceType.router &&
          d.type != DeviceType.gateway &&
          d.type != DeviceType.motionSensor &&
          d.type != DeviceType.doorSensor &&
          d.type != DeviceType.windowSensor) {
        d.isOn = false;
      }
    }
    notifyListeners();
  }

  /// לילה טוב — כיבוי אורות, AC על 20°C; תריסים סגורים
  void activateGoodNight() {
    for (final d in _devices) {
      switch (d.type) {
        case DeviceType.light:
          d.isOn = false;
          break;
        case DeviceType.airConditioner:
          d.isOn = true;
          d.attributes = {...d.attributes, 'setpoint': 20.0, 'mode': 'sleep'};
          break;
        case DeviceType.blind:
          d.isOn = true;
          d.attributes = {...d.attributes, 'position': 0};
          break;
        case DeviceType.smartPlug:
          d.isOn = false;
          break;
        default:
          break;
      }
    }
    _targetTemp = 20.0;
    notifyListeners();
  }

  /// מצב סרט — עמעום אורות, תריסים סגורים, מזגן על 23°C
  void activateMovieMode() {
    for (final d in _devices) {
      switch (d.type) {
        case DeviceType.light:
          d.isOn = true;
          d.attributes = {...d.attributes, 'brightness': 15}; // 15% עמעום
          break;
        case DeviceType.blind:
          d.isOn = true;
          d.attributes = {...d.attributes, 'position': 0}; // סגור
          break;
        case DeviceType.airConditioner:
          d.isOn = true;
          d.attributes = {...d.attributes, 'setpoint': 23.0, 'mode': 'cool'};
          break;
        default:
          break;
      }
    }
    _targetTemp = 23.0;
    notifyListeners();
  }

  // ── Custom scenes ────────────────────────────────────────────
  List<CustomScene> get customScenes => List.unmodifiable(_customScenes);

  void addScene(CustomScene scene) {
    _customScenes.add(scene);
    _saveScenes();
    notifyListeners();
  }

  void updateScene(CustomScene scene) {
    final i = _customScenes.indexWhere((s) => s.id == scene.id);
    if (i != -1) {
      _customScenes[i] = scene;
      _saveScenes();
      notifyListeners();
    }
  }

  void removeScene(String id) {
    _customScenes.removeWhere((s) => s.id == id);
    _saveScenes();
    notifyListeners();
  }

  /// Apply a custom scene's actions to the matching devices.
  void activateCustomScene(CustomScene s) {
    for (final d in _devices) {
      switch (d.type) {
        case DeviceType.light:
          if (s.lights != null) d.isOn = s.lights!;
          break;
        case DeviceType.smartPlug:
          if (s.plugs != null) d.isOn = s.plugs!;
          break;
        case DeviceType.airConditioner:
          if (s.ac != null) {
            d.isOn = s.ac!;
            if (s.ac! && s.acTemp != null) {
              d.attributes = {...d.attributes, 'setpoint': s.acTemp};
            }
          }
          break;
        case DeviceType.blind:
          if (s.blindsOpen != null) {
            d.isOn = true;
            d.attributes = {
              ...d.attributes,
              'position': s.blindsOpen! ? 100 : 0,
            };
          }
          break;
        default:
          break;
      }
    }
    if (s.ac == true && s.acTemp != null) _targetTemp = s.acTemp!;
    if (s.arm != null) {
      _securityMode = s.arm! ? SecurityMode.armedAway : SecurityMode.disarmed;

    }
    notifyListeners();
  }

  Future<void> _saveScenes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'ft_scenes',
      _customScenes.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  // ── Home-users persistence ────────────────────────────────────
  Future<void> _saveHomeUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'ft_home_users',
      _homeUsers.map((u) => jsonEncode(u.toJson())).toList(),
    );
    if (_householdCode != null) {
      await prefs.setString('ft_household_code', _householdCode!);
    }
  }

  Future<void> _loadHomeUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('ft_home_users') ?? [];
    if (list.isNotEmpty) {
      _homeUsers = list
          .map((s) => HomeUser.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }
    _householdCode = prefs.getString('ft_household_code');
    _userImagePath = prefs.getString('user_image_path');
    // Validate that image files still exist (user may have cleared storage)
    if (_userImagePath != null && !File(_userImagePath!).existsSync()) {
      _userImagePath = null;
      await prefs.remove('user_image_path');
    }
    for (final u in _homeUsers) {
      if (u.imagePath != null && !File(u.imagePath!).existsSync()) {
        u.imagePath = null;
      }
    }
  }
}
