// ─────────────────────────────────────────────────────────────────────────────
// HaPushService — bridge between HA WebSocket events and push notifications
//
// Responsibilities:
//   • Init flutter_local_notifications (Android channel + permissions)
//   • Init Firebase (safe — no-op when google-services.json is unconfigured)
//   • Retrieve + expose FCM token for copy/registration
//   • Subscribe to HA WS state_changed events; evaluate HaPushRules
//   • Show local notifications for matched rules
//   • Handle incoming FCM messages (background / foreground)
//   • Register app with HA mobile_app integration (optional, sets webhook)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_version.dart';
import '../ha/ha_provider.dart';
import 'ha_push_rule.dart';

// ── Background FCM handler (must be top-level) ────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await HaPushService._showFcmNotification(message);
}

// ─────────────────────────────────────────────────────────────────────────────

class HaPushService extends ChangeNotifier {
  HaPushService._();
  static final HaPushService instance = HaPushService._();

  // ── State ─────────────────────────────────────────────────────────────────

  bool   _ready      = false;
  bool   _fcmReady   = false;
  String? _fcmToken;
  String? _webhookId;
  String? _error;

  bool    get isReady    => _ready;
  bool    get fcmReady   => _fcmReady;
  String? get fcmToken   => _fcmToken;
  String? get webhookId  => _webhookId;
  String? get error      => _error;

  List<HaPushRule> _rules = [];
  List<HaPushRule> get rules => List.unmodifiable(_rules);

  int? _wsSub;        // WS subscription ID for state_changed
  HaProvider? _ha;

  // ── Flutter Local Notifications ───────────────────────────────────────────

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'ha_events';
  static const _channelName = 'Home Assistant Events';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Real-time alerts from Home Assistant',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
  );

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_ready) return;

    await _initLocalNotifications();
    await _initFirebase();
    await _loadRules();
    await _loadWebhook();

    _ready = true;
    notifyListeners();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    // Create notification channel (Android 8+)
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Real-time alerts from Home Assistant',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Request permission on Android 13+
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS / Android 13+)
      await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      _fcmToken = await messaging.getToken();
      _fcmReady = true;

      // Token refresh
      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        notifyListeners();
      });

      // Foreground FCM messages → local notification
      FirebaseMessaging.onMessage.listen((msg) {
        _showFcmNotification(msg);
      });

      notifyListeners();
    } catch (e) {
      // Firebase not configured — local notifications still work
      _error = 'Firebase לא מוגדר: $e';
      debugPrint('[HaPushService] Firebase init failed: $e');
    }
  }

  // ── Show FCM notification (static — called from background handler too) ───

  static Future<void> _showFcmNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final id = message.messageId.hashCode;
    await _localNotifications.show(
      id,
      notification.title ?? 'Home Assistant',
      notification.body,
      _notifDetails,
    );
  }

  // ── Rules persistence ─────────────────────────────────────────────────────

  Future<void> _loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList('ha_push_rules');

    if (raw == null || raw.isEmpty) {
      // First run — use defaults
      _rules = List.from(kDefaultPushRules);
    } else {
      try {
        final saved = raw
            .map((s) => HaPushRule.fromJson(
                jsonDecode(s) as Map<String, dynamic>))
            .toList();

        // Merge with defaults: keep saved enabled-state, add any new defaults
        final merged = <HaPushRule>[];
        for (final def in kDefaultPushRules) {
          final match = saved.where((r) => r.id == def.id).firstOrNull;
          if (match != null) {
            def.enabled = match.enabled;
            merged.add(def);
          } else {
            merged.add(def);
          }
        }
        // Append any user-custom rules (id not in defaults)
        final defaultIds = {for (final d in kDefaultPushRules) d.id};
        merged.addAll(saved.where((r) => !defaultIds.contains(r.id)));

        _rules = merged;
      } catch (_) {
        _rules = List.from(kDefaultPushRules);
      }
    }
  }

  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'ha_push_rules',
      _rules.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  void setRuleEnabled(String id, bool enabled) {
    final rule = _rules.where((r) => r.id == id).firstOrNull;
    if (rule == null) return;
    rule.enabled = enabled;
    _saveRules();
    notifyListeners();
  }

  // ── Webhook persistence ───────────────────────────────────────────────────

  Future<void> _loadWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    _webhookId = prefs.getString('ha_push_webhook_id');
  }

  Future<void> _saveWebhook(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ha_push_webhook_id', id);
    _webhookId = id;
  }

  // ── Attach to HaProvider ──────────────────────────────────────────────────

  void attachHaProvider(HaProvider ha) {
    _ha?.removeListener(_onHaChange);
    _ha = ha;
    ha.addListener(_onHaChange);
    if (ha.isConnected) _subscribeEvents();
  }

  void _onHaChange() {
    final ha = _ha;
    if (ha == null) return;
    if (ha.isConnected && _wsSub == null) {
      _subscribeEvents();
    } else if (!ha.isConnected) {
      _wsSub = null; // WS reconnect will re-subscribe
    }
  }

  Future<void> _subscribeEvents() async {
    final ha = _ha;
    if (ha == null || !ha.isConnected) return;

    _wsSub = await ha.subscribeEvent('state_changed', _onStateChanged);
  }

  // ── Event evaluation ──────────────────────────────────────────────────────

  void _onStateChanged(Map<String, dynamic> event) {
    try {
      final data     = event['data']     as Map<String, dynamic>?;
      if (data == null) return;
      final entityId = data['entity_id'] as String?;
      if (entityId == null) return;

      final newState = (data['new_state'] as Map<String, dynamic>?)?['state']
          as String?;
      if (newState == null) return;

      final attrs = ((data['new_state'] as Map<String, dynamic>?)?['attributes']
          as Map<String, dynamic>?) ?? {};
      final friendlyName =
          (attrs['friendly_name'] as String?) ?? entityId;

      for (final rule in _rules) {
        if (!rule.enabled) continue;
        if (!rule.matches(entityId, newState)) continue;
        _fireNotification(rule, friendlyName, entityId, newState);
      }
    } catch (e) {
      debugPrint('[HaPushService] event error: $e');
    }
  }

  int _notifId = 1000;

  void _fireNotification(
    HaPushRule rule,
    String friendlyName,
    String entityId,
    String state,
  ) {
    final title = rule.resolveTitle(friendlyName, entityId);
    final body  = rule.resolveBody(friendlyName, entityId, state);

    _localNotifications.show(
      _notifId++,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Real-time alerts from Home Assistant',
          importance: rule.priority >= 2 ? Importance.max : Importance.high,
          priority:   rule.priority >= 2 ? Priority.max   : Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  // ── Test notification ─────────────────────────────────────────────────────

  Future<void> sendTestNotification() async {
    await _localNotifications.show(
      0,
      '✅ FantaTech Push עובד!',
      'קיבלת התראה מ-Home Assistant בהצלחה',
      _notifDetails,
    );
  }

  // ── HA mobile_app registration ────────────────────────────────────────────

  /// Registers this device with HA's mobile_app integration.
  /// Returns the webhook ID on success, null on failure.
  Future<String?> registerWithHa({
    required String baseUrl,
    required String token,
    String deviceName = 'FantaTech',
  }) async {
    try {
      final url = '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}'
          '/api/mobile_app/registrations';

      final body = jsonEncode({
        'app_id':         'il.co.fantatech.fantatech',
        'app_name':       'FantaTech',
        'app_version':    kAppVersion,
        'device_name':    deviceName,
        'manufacturer':   'Android',
        'model':          'Flutter',
        'os_name':        'Android',
        'os_version':     '13',
        'supports_encryption': false,
        'app_data': {
          'push_token':    _fcmToken ?? '',
          'push_url':      'https://mobile-push.home-assistant.io/push',
        },
      });

      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
        body: body,
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data    = jsonDecode(res.body) as Map<String, dynamic>;
        final webhook = data['webhook_id'] as String?;
        if (webhook != null) {
          await _saveWebhook(webhook);
          notifyListeners();
          return webhook;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[HaPushService] register error: $e');
      return null;
    }
  }
}
