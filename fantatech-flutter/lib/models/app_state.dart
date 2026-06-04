import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
import '../theme/app_theme.dart';

enum SecurityMode { armed, disarmed }
enum AppLocale { hebrew, english, arabic, amharic, spanish, russian }

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
}

class AppState extends ChangeNotifier {
  AppState() {
    _initFromPrefs();
  }

  SecurityMode _securityMode = SecurityMode.disarmed;
  ThemeMode _themeMode = ThemeMode.dark;
  AppThemePrefs _themePrefs = const AppThemePrefs();
  bool _gridLayout = false; // home screen layout: false = classic, true = grid
  GatewayManager? _gateways;
  void attachGateways(GatewayManager m) {
    _gateways = m;
    _startDeviceMonitor();
  }

  // ── Live device monitor (leak / sensor alerts) ───────────────────────────
  Timer? _monitorTimer;

  @override
  void dispose() {
    _monitorTimer?.cancel();
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
        ? '⚠️ זוהתה נזילת מים — ${d.name}'
        : '⚠️ התראה — ${d.name}';
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
  UserPlan _userPlan = UserPlan.advancedPlus; // default for demo
  AdTrack _adTrack = AdTrack.featured;
  String _userName = 'יוסי לוי';
  String _userEmail = 'yossi@gmail.com';
  String? _userImagePath;

  List<HomeUser> _homeUsers = [];
  String? _homePin;
  int _homeIconCode  = 0xe318; // Icons.home codepoint
  int _homeColorValue = 0xFF00B4D8; // AppColors.primary

  List<Device> _devices = [];
  List<AppNotification> _appNotifications = [];
  List<Camera> _cameras = List.from(MockData.cameras);
  List<FaceAnalysisResult> _faceAnalysisHistory = [];

  // Media subsystem (smart speakers / TVs / cast targets)
  MediaModule _media = MediaModule();

  // User-created scenes
  List<CustomScene> _customScenes = [];

  // Azure Face API
  String? _azureEndpoint;
  String? _azureApiKey;
  List<KnownPerson> _knownPersons = [];
  List<SecurityEvent> _events = List.from(MockData.events);
  List<Automation> _automations = List.from(MockData.automations);

  // Rooms — each entry: {name, icon (codePoint)}
  // Default names use translation keys (e.g. '__living__') so they render
  // in the active language. User-renamed rooms keep their custom string.
  List<Map<String, dynamic>> _rooms = [
    {'name': '__living__',  'icon': 0xe318},
    {'name': '__bedroom__', 'icon': 0xe239},
    {'name': '__kitchen__', 'icon': 0xf04c3},
    {'name': '__kids__',    'icon': 0xe556},
    {'name': '__balcony__', 'icon': 0xe3a3},
  ];

  SecurityMode get securityMode => _securityMode;
  ThemeMode get themeMode => _themeMode;
  AppThemePrefs get themePrefs => _themePrefs;
  bool get gridLayout => _gridLayout;
  AppLocale get locale => _locale;
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

  // Demo playlist used for the Now-Playing card.
  static const _demoPlaylist = [
    ('Blinding Lights', 'The Weeknd'),
    ('As It Was', 'Harry Styles'),
    ('Levitating', 'Dua Lipa'),
    ('Shape of You', 'Ed Sheeran'),
    ('Stay', 'Kid Laroi & Justin Bieber'),
  ];

  void _applyTrack(MediaDevice d) {
    final t = _demoPlaylist[d.trackIndex % _demoPlaylist.length];
    d.track = t.$1;
    d.artist = t.$2;
  }

  void toggleMediaPlay(String id) {
    final d = _findMedia(id);
    if (d != null) {
      d.isPlaying = !d.isPlaying;
      if (d.isPlaying && d.track.isEmpty) _applyTrack(d);
      notifyListeners();
    }
  }

  void mediaNext(String id) {
    final d = _findMedia(id);
    if (d != null) {
      d.trackIndex = (d.trackIndex + 1) % _demoPlaylist.length;
      d.progress = 0;
      d.isPlaying = true;
      _applyTrack(d);
      notifyListeners();
    }
  }

  void mediaPrev(String id) {
    final d = _findMedia(id);
    if (d != null) {
      d.trackIndex =
          (d.trackIndex - 1 + _demoPlaylist.length) % _demoPlaylist.length;
      d.progress = 0;
      d.isPlaying = true;
      _applyTrack(d);
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
      _applyTrack(d);
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
  List<Map<String, dynamic>> get rooms => List.unmodifiable(_rooms);

  bool get isSecured => _securityMode == SecurityMode.armed;

  int get devicesOnlineCount =>
      _devices.where((d) => d.status == DeviceStatus.online).length;

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
      case AppLocale.hebrew:
        return const Locale('he');
    }
  }

  bool get isRtl => _locale == AppLocale.hebrew || _locale == AppLocale.arabic;

  S get strings => S.of(_locale);

  void toggleSecurity() {
    _securityMode = isSecured ? SecurityMode.disarmed : SecurityMode.armed;
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

  void setDeviceAttribute(String id, String key, dynamic value) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.attributes = {...device.attributes, key: value};
    notifyListeners();
  }

  void toggleAutomation(String id) {
    final auto = _automations.firstWhere((a) => a.id == id);
    auto.isEnabled = !auto.isEnabled;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
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
    _saveThemePrefs();
    notifyListeners();
  }

  void setLocale(AppLocale locale) {
    _locale = locale;
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
    }
  }

  void setUserEmail(String email) {
    if (email.trim().isNotEmpty) {
      _userEmail = email.trim();
      notifyListeners();
    }
  }

  void setUserImage(String? path) {
    _userImagePath = path;
    notifyListeners();
  }

  // ── Home users (manager + household members) ─────────────────
  void registerAsHomeManager({String? name}) {
    if (!hasHomeManager) {
      _homeUsers.insert(0, HomeUser(
        id: 'manager_${DateTime.now().millisecondsSinceEpoch}',
        name: name ?? _userName,
        isManager: true,
        imagePath: _userImagePath,
      ));
      notifyListeners();
    }
  }

  void addHouseholdMember(String name) {
    _homeUsers.add(HomeUser(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isManager: false,
    ));
    notifyListeners();
  }

  void removeHomeUser(String id) {
    _homeUsers.removeWhere((u) => u.id == id);
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

  void addDevice(Device device) {
    if (!_devices.any((d) => d.id == device.id)) {
      _devices.add(device);
      // Create a notification for this real device connection
      _appNotifications.insert(0, AppNotification(
        id: 'notif_${device.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: device.name,
        deviceId: device.id,
        deviceType: device.type,
        timestamp: DateTime.now(),
      ));
      _saveDevicesToPrefs();
      notifyListeners();
    }
  }

  void removeDevice(String id) {
    _devices.removeWhere((d) => d.id == id);
    _saveDevicesToPrefs();
    notifyListeners();
  }

  void updateDeviceName(String id, String name) {
    final device = _devices.firstWhere((d) => d.id == id, orElse: () => throw StateError('not found'));
    device.name = name;
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
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('ft_devices') ?? [];
    if (jsonList.isNotEmpty) {
      _devices = jsonList
          .map((s) => Device.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }
    // Load home style
    _homeIconCode   = prefs.getInt('home_icon_code')   ?? _homeIconCode;
    _homeColorValue = prefs.getInt('home_color_value') ?? _homeColorValue;
    _gridLayout     = prefs.getBool('ft_grid_layout')  ?? false;
    // Load theme prefs
    final tpFont    = prefs.getString('tp_font');
    final tpAccent  = prefs.getInt('tp_accent');
    final tpBg      = prefs.getString('tp_bg');
    final tpRadius  = prefs.getString('tp_radius');
    if (tpFont != null || tpAccent != null || tpBg != null || tpRadius != null) {
      _themePrefs = AppThemePrefs.fromMap({
        'font':    tpFont    ?? 'heebo',
        'accent':  tpAccent  ?? 0xFF1A73E8,
        'bgStyle': tpBg      ?? 'darkBlue',
        'radius':  tpRadius  ?? 'normal',
      });
    }
    // Load Azure credentials + known persons
    _azureEndpoint = prefs.getString('azure_endpoint');
    _azureApiKey   = prefs.getString('azure_api_key');
    final personsList = prefs.getStringList('known_persons') ?? [];
    _knownPersons = personsList
        .map((s) => KnownPerson.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    // Load custom scenes
    final sceneList = prefs.getStringList('ft_scenes') ?? [];
    _customScenes = sceneList
        .map((s) => CustomScene.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
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

  // ── Camera management ────────────────────────────────────────
  void addRealCamera(Camera camera) {
    if (!_cameras.any((c) => c.id == camera.id)) {
      _cameras.add(camera);
      notifyListeners();
    }
  }

  void removeCamera(String id) {
    _cameras.removeWhere((c) => c.id == id);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azure_endpoint', _azureEndpoint ?? '');
    await prefs.setString('azure_api_key',  _azureApiKey   ?? '');
  }

  Future<void> loadAzureCredentials() async {
    final prefs    = await SharedPreferences.getInstance();
    _azureEndpoint = prefs.getString('azure_endpoint');
    _azureApiKey   = prefs.getString('azure_api_key');
    // Load known persons
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
    _securityMode = SecurityMode.armed;
    for (final cam in _cameras) {
      cam.isOnline = true;
    }
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
  void addRoom(String name, int iconCodePoint) {
    _rooms.add({'name': name, 'icon': iconCodePoint});
    notifyListeners();
  }

  void editRoom(int index, String name, int iconCodePoint) {
    if (index >= 0 && index < _rooms.length) {
      _rooms[index] = {'name': name, 'icon': iconCodePoint};
      notifyListeners();
    }
  }

  void deleteRoom(int index) {
    if (index >= 0 && index < _rooms.length) {
      _rooms.removeAt(index);
      notifyListeners();
    }
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
    _securityMode = SecurityMode.armed;
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
      _securityMode = s.arm! ? SecurityMode.armed : SecurityMode.disarmed;
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
}
