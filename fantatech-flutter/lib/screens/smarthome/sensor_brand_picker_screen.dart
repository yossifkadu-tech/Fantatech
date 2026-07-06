import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_button.dart';
import '../../services/discovery/real_discovery_engine.dart';
import '../../services/discovery/discovery_models.dart';

// ─────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────
enum _Protocol { zigbee, wifi, zwave, matter }

class _PairingStep {
  final IconData icon;
  final String text;
  final bool isAction;
  final bool isWarning;
  const _PairingStep(this.icon, this.text, {this.isAction = false, this.isWarning = false});
}

class _Brand {
  final String id;
  final String name;
  final String model;
  final _Protocol protocol;
  final bool requiresHub;
  final String hubNote;
  final Color accentColor;
  final List<_PairingStep> steps;
  const _Brand({
    required this.id,
    required this.name,
    required this.model,
    required this.protocol,
    this.requiresHub = false,
    this.hubNote = '',
    required this.accentColor,
    required this.steps,
  });
}

// ─────────────────────────────────────────────────────────────
// Protocol accent colours
// ─────────────────────────────────────────────────────────────
const _kZigbee = Color(0xFFFF6600);
const _kWifi   = Color(0xFF00AA44);
const _kZwave  = Color(0xFF0066CC);
const _kMatter = Color(0xFF9933CC);

// ─────────────────────────────────────────────────────────────
// Motion-sensor brand catalogue
// ─────────────────────────────────────────────────────────────
const _motionBrands = <_Brand>[
  // ── Zigbee ────────────────────────────────────────────────
  _Brand(
    id: 'aqara_p1_motion',
    name: 'Aqara',
    model: 'Motion Sensor P1',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל "הוסף מכשיר / Add device"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס את הסוללה לחיישן'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור Reset 5 שניות עד הבהוב LED', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי ב-FantaTech (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'sonoff_snzb03',
    name: 'Sonoff',
    model: 'SNZB-03P',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס את הסוללה לחיישן'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור Reset 5 שניות עד הבהוב', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'philips_hue_motion',
    name: 'Philips Hue',
    model: 'Motion Sensor',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'Hue Bridge · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא ש-Hue Bridge / Hub Zigbee מחובר'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללות AA לחיישן'),
      _PairingStep(Symbols.touch_app,          'לחץ פעמיים על כפתור ה-Reset (מתחת)', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'ikea_tradfri_motion',
    name: 'IKEA',
    model: 'TRÅDFRI Motion',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub DIRIGERA מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס את הסוללה לחיישן'),
      _PairingStep(Symbols.touch_app,          'לחץ 4 פעמים מהיר על כפתור ה-Pair', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'tuya_pir',
    name: 'Tuya',
    model: 'PIR Motion Sensor',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'deCONZ · Z2M · ZHA',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2450 לחיישן'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור 10 שניות עד הבהוב', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  // ── WiFi ──────────────────────────────────────────────────
  _Brand(
    id: 'shelly_motion2',
    name: 'Shelly',
    model: 'Motion 2',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללה להפעלה ראשונה'),
      _PairingStep(Symbols.wifi,               'ב-Wi-Fi הטלפון: התחבר ל-"ShellyMotion2-XXXXXX"'),
      _PairingStep(Symbols.language,           'פתח דפדפן → 192.168.33.1 → הגדר WiFi ביתי', isAction: true),
      _PairingStep(Symbols.check_circle,        'המכשיר יצטרף לרשת הביתית'),
      _PairingStep(Symbols.add_link,                    'הוסף ב-FantaTech עם כתובת ה-IP שהוקצה'),
    ],
  ),
  _Brand(
    id: 'aqara_fp2',
    name: 'Aqara',
    model: 'Presence Sensor FP2',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.power,              'חבר את ה-FP2 לחשמל (USB-C)'),
      _PairingStep(Symbols.smartphone,         'הורד את אפליקציית "Aqara Home" (חינם)'),
      _PairingStep(Symbols.add_circle,          'ב-Aqara Home: הוסף את ה-FP2 לחשבונך', isAction: true),
      _PairingStep(Symbols.wifi,               'הגדר חיבור WiFi לרשת הביתית'),
      _PairingStep(Symbols.add_link,                    'הוסף ב-FantaTech עם ה-IP של המכשיר'),
    ],
  ),
  // ── Z-Wave ────────────────────────────────────────────────
  _Brand(
    id: 'fibaro_fgms',
    name: 'Fibaro',
    model: 'FGMS-001 Motion Sensor',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Hub נדרש',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Z-Wave מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב "Include / הוסף"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR123A לחיישן'),
      _PairingStep(Symbols.touch_app,          'לחץ 3 פעמים מהיר על כפתור ה-Reset', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי על-ידי ה-Hub (עד 60 שניות)'),
    ],
  ),
  _Brand(
    id: 'aeotec_ms6',
    name: 'Aeotec',
    model: 'MultiSensor 6',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Hub נדרש',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Z-Wave מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב Include'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללות CR123A לחיישן'),
      _PairingStep(Symbols.touch_app,          'לחץ פעם אחת על כפתור ה-Action', isAction: true),
      _PairingStep(Symbols.sensors,            'LED יהבהב ויתייצב — המתן לזיהוי'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Door-sensor brand catalogue
// ─────────────────────────────────────────────────────────────
const _doorBrands = <_Brand>[
  // ── Zigbee ────────────────────────────────────────────────
  _Brand(
    id: 'aqara_door_p1',
    name: 'Aqara',
    model: 'Door & Window P1',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2032 לחיישן'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור Reset 5 שניות עד הבהוב LED', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי ב-FantaTech (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'sonoff_snzb04',
    name: 'Sonoff',
    model: 'SNZB-04',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2032'),
      _PairingStep(Symbols.touch_app,          'לחץ לחיצה ארוכה על ה-Reset (5 שניות)', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'samsung_st_door',
    name: 'Samsung',
    model: 'SmartThings Multipurpose',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'SmartThings Hub · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2450 לחיישן'),
      _PairingStep(Symbols.touch_app,          'לחץ על כפתור ה-Pair עד שה-LED ידלק', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'tuya_contact',
    name: 'Tuya',
    model: 'Contact Sensor',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'deCONZ · Z2M · ZHA',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2032'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור 10 שניות עד הבהוב', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'ikea_parasoll',
    name: 'IKEA',
    model: 'PARASOLL',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub DIRIGERA מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2032'),
      _PairingStep(Symbols.touch_app,          'לחץ 4 פעמים מהיר על כפתור ה-Pair', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  // ── WiFi ──────────────────────────────────────────────────
  _Brand(
    id: 'shelly_doorwindow2',
    name: 'Shelly',
    model: 'Door/Window 2',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללה להפעלה'),
      _PairingStep(Symbols.wifi,               'ב-Wi-Fi הטלפון: התחבר ל-"ShellyDW2-XXXXXX"'),
      _PairingStep(Symbols.language,           'פתח דפדפן → 192.168.33.1 → הגדר WiFi ביתי', isAction: true),
      _PairingStep(Symbols.check_circle,        'המכשיר יצטרף לרשת הביתית'),
      _PairingStep(Symbols.add_link,                    'הוסף ב-FantaTech עם כתובת ה-IP שהוקצה'),
    ],
  ),
  // ── Z-Wave ────────────────────────────────────────────────
  _Brand(
    id: 'fibaro_door',
    name: 'Fibaro',
    model: 'Door Opening Sensor',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Hub נדרש',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Z-Wave מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב Include'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2032'),
      _PairingStep(Symbols.touch_app,          'לחץ 3 פעמים מהיר על כפתור ה-Reset', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי על-ידי ה-Hub (עד 60 שניות)'),
    ],
  ),
  _Brand(
    id: 'ecolink_dw',
    name: 'Ecolink',
    model: 'Door/Window Sensor',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Hub נדרש',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Z-Wave מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב Include'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס את הסוללה לחיישן'),
      _PairingStep(Symbols.touch_app,          'הוצא והחזר סוללה — יחפש אוטומטית', isAction: true),
      _PairingStep(Symbols.sensor_door,        'המתן לזיהוי על-ידי ה-Hub'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Smart-plug brand catalogue
// ─────────────────────────────────────────────────────────────
const _plugBrands = <_Brand>[
  // ── Zigbee ────────────────────────────────────────────────
  _Brand(
    id: 'ikea_plug',
    name: 'IKEA',
    model: 'TRÅDFRI Smart Plug',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,             'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,        'ב-Hub — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.power,            'חבר את השקע לשקע החשמל'),
      _PairingStep(Symbols.touch_app,        'לחץ לחיצה ארוכה על הכפתור עד הבהוב', isAction: true),
      _PairingStep(Symbols.check_circle,      'המתן לזיהוי ב-FantaTech (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'sonoff_s26z',
    name: 'Sonoff',
    model: 'S26R2ZB',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,             'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,        'ב-Hub — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.power,            'חבר את השקע לשקע החשמל'),
      _PairingStep(Symbols.touch_app,        'החזק את הכפתור 5 שניות עד הבהוב LED', isAction: true),
      _PairingStep(Symbols.check_circle,      'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'tuya_plug_z',
    name: 'Tuya',
    model: 'Smart Plug Zigbee',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'deCONZ · Z2M · ZHA',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,             'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,        'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.power,            'חבר את השקע לחשמל'),
      _PairingStep(Symbols.touch_app,        'החזק כפתור 6 שניות עד הבהוב מהיר', isAction: true),
      _PairingStep(Symbols.check_circle,      'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  // ── WiFi ──────────────────────────────────────────────────
  _Brand(
    id: 'shelly_plugs',
    name: 'Shelly',
    model: 'Plug S / Plus',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.power,            'חבר את השקע לשקע החשמל'),
      _PairingStep(Symbols.wifi,             'ב-Wi-Fi הטלפון: התחבר ל-"ShellyPlugS-XXXXXX"'),
      _PairingStep(Symbols.language,         'פתח דפדפן → 192.168.33.1 → הגדר WiFi ביתי', isAction: true),
      _PairingStep(Symbols.check_circle,      'השקע יצטרף לרשת הביתית'),
      _PairingStep(Symbols.sensors,          'FantaTech יגלה את השקע אוטומטית'),
    ],
  ),
  _Brand(
    id: 'sonoff_s26',
    name: 'Sonoff',
    model: 'S20 / S26',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.power,            'חבר את השקע לחשמל (LED יהבהב)'),
      _PairingStep(Symbols.touch_app,        'לחץ 5 פעמים מהיר לכניסה ל-DIY Mode', isAction: true),
      _PairingStep(Symbols.wifi,             'ב-Wi-Fi: התחבר ל-"ITEAD-XXXXXX"'),
      _PairingStep(Symbols.language,         'פתח דפדפן → 10.10.7.1 → הגדר WiFi'),
      _PairingStep(Symbols.sensors,          'FantaTech יגלה דרך הרשת המקומית'),
    ],
  ),
  _Brand(
    id: 'tuya_plug_w',
    name: 'Tuya',
    model: 'Smart Plug WiFi',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.power,            'חבר את השקע לחשמל'),
      _PairingStep(Symbols.touch_app,        'החזק כפתור 6 שניות עד הבהוב מהיר', isAction: true),
      _PairingStep(Symbols.sensors,          'ב-FantaTech: הפעל "סרוק רשת"'),
      _PairingStep(Symbols.check_circle,      'FantaTech יגלה אוטומטית דרך Tuya LAN'),
    ],
  ),
  _Brand(
    id: 'kasa_ep25',
    name: 'TP-Link Kasa',
    model: 'EP25 / EP10',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.power,            'חבר את השקע לחשמל'),
      _PairingStep(Symbols.touch_app,        'החזק כפתור 5 שניות עד הבהוב', isAction: true),
      _PairingStep(Symbols.wifi,             'ב-Wi-Fi: התחבר ל-"TP-Link_XXXXXX"'),
      _PairingStep(Symbols.language,         'פתח דפדפן → 192.168.0.1 → הגדר WiFi'),
      _PairingStep(Symbols.sensors,          'FantaTech יגלה דרך Kasa LAN'),
    ],
  ),
  // ── Matter ────────────────────────────────────────────────
  _Brand(
    id: 'eve_energy',
    name: 'Eve',
    model: 'Energy (Matter)',
    protocol: _Protocol.matter,
    requiresHub: false,
    accentColor: _kMatter,
    steps: [
      _PairingStep(Symbols.power,            'חבר את Eve Energy לשקע החשמל'),
      _PairingStep(Symbols.qr_code,          'מצא את קוד ה-QR / Setup Code בתחתית המכשיר'),
      _PairingStep(Symbols.hub,              'ב-FantaTech: הוסף מכשיר → Matter', isAction: true),
      _PairingStep(Symbols.qr_code_scanner,           'סרוק את קוד ה-QR עם המצלמה'),
      _PairingStep(Symbols.check_circle,      'FantaTech יקשר דרך Matter מקומי'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Smart-switch brand catalogue  (מפסקים מוטמעים — חיווט)
// ─────────────────────────────────────────────────────────────
const _switchBrands = <_Brand>[
  // ── WiFi ──────────────────────────────────────────────────
  _Brand(
    id: 'shelly_1pm',
    name: 'Shelly',
    model: '1PM / 2PM',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט: L · N · O · SW'),
      _PairingStep(Symbols.power,            'הפעל חשמל — LED יהבהב'),
      _PairingStep(Symbols.wifi,             'ב-Wi-Fi: התחבר ל-"ShellyPM1-XXXXXX"', isAction: true),
      _PairingStep(Symbols.language,         'פתח דפדפן → 192.168.33.1 → הגדר WiFi'),
    ],
  ),
  _Brand(
    id: 'sonoff_mini_r4',
    name: 'Sonoff',
    model: 'Mini R4 / Basic R4',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט: L-IN · L-OUT · N · E'),
      _PairingStep(Symbols.power,            'הפעל חשמל (LED יהבהב)'),
      _PairingStep(Symbols.touch_app,        'לחץ 5 פעמים מהיר לכניסה ל-DIY Mode', isAction: true),
      _PairingStep(Symbols.language,         'התחבר ל-ITEAD-XXXX → 10.10.7.1 → הגדר WiFi'),
    ],
  ),
  _Brand(
    id: 'tuya_switch_w',
    name: 'Tuya',
    model: 'Smart Switch WiFi',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט בגב המפסק'),
      _PairingStep(Symbols.power,            'הפעל חשמל'),
      _PairingStep(Symbols.touch_app,        'לחץ לחיצה ארוכה על כפתור ה-Reset', isAction: true),
      _PairingStep(Symbols.sensors,          'ב-FantaTech → "סרוק רשת" → Tuya LAN'),
    ],
  ),
  // ── Zigbee ────────────────────────────────────────────────
  _Brand(
    id: 'sonoff_zbmini',
    name: 'Sonoff',
    model: 'ZBMINIL2',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט: L-IN · L-OUT · N'),
      _PairingStep(Symbols.hub,              'ב-Hub Zigbee — הפעל "הוסף מכשיר"'),
      _PairingStep(Symbols.power,            'הפעל חשמל — המכשיר נכנס ל-Pairing Mode', isAction: true),
      _PairingStep(Symbols.check_circle,      'המתן לזיהוי ב-FantaTech (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'tuya_switch_z',
    name: 'Tuya',
    model: 'Smart Switch Zigbee',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'deCONZ · Z2M · ZHA',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט'),
      _PairingStep(Symbols.hub,              'ב-Hub Zigbee — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.power,            'הפעל חשמל', isAction: true),
      _PairingStep(Symbols.check_circle,      'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  // ── Z-Wave ────────────────────────────────────────────────
  _Brand(
    id: 'fibaro_switch',
    name: 'Fibaro',
    model: 'Single Switch 2',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Hub נדרש',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט: S1 · S2 · N · L'),
      _PairingStep(Symbols.hub,              'ב-Hub Z-Wave — הפעל מצב Include'),
      _PairingStep(Symbols.power,            'הפעל חשמל', isAction: true),
      _PairingStep(Symbols.touch_app,        'לחץ 3 פעמים מהיר על כפתור ה-B'),
    ],
  ),
  _Brand(
    id: 'aeotec_nano',
    name: 'Aeotec',
    model: 'Nano Switch',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Hub נדרש',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.warning_amber,     '⚠️ כבה את החשמל בלוח לפני החיבור!', isWarning: true),
      _PairingStep(Symbols.electrical_services,       'חבר לפי מפת החיווט: IN · OUT · N'),
      _PairingStep(Symbols.hub,              'ב-Hub Z-Wave — הפעל מצב Include'),
      _PairingStep(Symbols.power,            'הפעל חשמל', isAction: true),
      _PairingStep(Symbols.touch_app,        'לחץ פעם אחת על כפתור ה-Action'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Smoke detector brands
// ─────────────────────────────────────────────────────────────
const _smokeBrands = <_Brand>[
  // ── Zigbee ────────────────────────────────────────────────
  _Brand(
    id: 'aqara_smoke',
    name: 'Aqara',
    model: 'Smoke Detector',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל "הוסף מכשיר / Add device"'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללות CR123A לגלאי'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור Reset 5 שניות עד הבהוב LED', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי ב-FantaTech (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'sonoff_snzb09',
    name: 'Sonoff',
    model: 'SNZB-09 Smoke Detector',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR2 לגלאי'),
      _PairingStep(Symbols.touch_app,          'החזק כפתור 5 שניות עד הבהוב', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'tuya_smoke',
    name: 'Tuya',
    model: 'Smoke Alarm Sensor',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'deCONZ · Z2M · ZHA',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub Zigbee מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR123A לגלאי'),
      _PairingStep(Symbols.touch_app,          'לחץ 3 פעמים מהיר על כפתור ה-Pair', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  _Brand(
    id: 'ikea_badring',
    name: 'IKEA',
    model: 'BADRING Smoke Alarm',
    protocol: _Protocol.zigbee,
    requiresHub: true,
    hubNote: 'DIRIGERA · deCONZ · Z2M',
    accentColor: _kZigbee,
    steps: [
      _PairingStep(Symbols.hub,                'ודא שה-Hub DIRIGERA מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Hub — הפעל מצב הוספת מכשיר'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללות AA לגלאי'),
      _PairingStep(Symbols.touch_app,          'לחץ כפתור Pair עד הבהוב LED', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לזיהוי (עד 30 שניות)'),
    ],
  ),
  // ── WiFi ──────────────────────────────────────────────────
  _Brand(
    id: 'shelly_smoke2',
    name: 'Shelly',
    model: 'Smoke 2',
    protocol: _Protocol.wifi,
    requiresHub: false,
    accentColor: _kWifi,
    steps: [
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללות AA להפעלה ראשונה'),
      _PairingStep(Symbols.wifi,               'ב-Wi-Fi הטלפון: התחבר ל-"ShellySmoke2-XXXXXX"'),
      _PairingStep(Symbols.language,           'פתח דפדפן → 192.168.33.1 → הגדר WiFi ביתי', isAction: true),
      _PairingStep(Symbols.check_circle,        'המכשיר יצטרף לרשת הביתית'),
      _PairingStep(Symbols.add_link,                    'הוסף ב-FantaTech עם כתובת ה-IP שהוקצה'),
    ],
  ),
  // ── Z-Wave ────────────────────────────────────────────────
  _Brand(
    id: 'fibaro_fgsd002',
    name: 'Fibaro',
    model: 'FGSD-002 Smoke Sensor',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Controller',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.hub,                'ודא ש-Controller Z-Wave מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Controller — הפעל מצב Include'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת CR123A לגלאי'),
      _PairingStep(Symbols.touch_app,          'לחץ 3 פעמות מהיר על כפתור ה-B', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לסיום ה-Include (נורה ירוקה)'),
    ],
  ),
  _Brand(
    id: 'ecolink_firefighter',
    name: 'Ecolink',
    model: 'FIREFIGHTER Audio Detector',
    protocol: _Protocol.zwave,
    requiresHub: true,
    hubNote: 'Z-Wave Controller',
    accentColor: _kZwave,
    steps: [
      _PairingStep(Symbols.hub,                'ודא ש-Controller Z-Wave מחובר ל-FantaTech'),
      _PairingStep(Symbols.add_circle,          'ב-Controller — הפעל מצב Include'),
      _PairingStep(Symbols.battery_charging_full, 'הכנס סוללת 9V לגלאי'),
      _PairingStep(Symbols.touch_app,          'לחץ כפתור Tamper פעם אחת', isAction: true),
      _PairingStep(Symbols.sensors,            'המתן לסיום ה-Include (LED כחול)'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────
class SensorBrandPickerScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final IconData deviceIcon;
  final Color deviceColor;
  final void Function(String deviceName) onConfirm;

  const SensorBrandPickerScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.deviceIcon,
    required this.deviceColor,
    required this.onConfirm,
  });

  @override
  State<SensorBrandPickerScreen> createState() =>
      _SensorBrandPickerScreenState();
}

class _SensorBrandPickerScreenState extends State<SensorBrandPickerScreen> {
  _Protocol? _filter;

  List<_Brand> get _brands {
    switch (widget.deviceId) {
      case 'motion': return _motionBrands;
      case 'door':
      case 'window': return _doorBrands;
      case 'plug':   return _plugBrands;
      case 'switch1':
      case 'dimmer': return _switchBrands;
      case 'smoke':  return _smokeBrands;
      default:       return _motionBrands;
    }
  }

  List<_Protocol> get _availableProtocols {
    final seen = <_Protocol>{};
    for (final b in _brands) seen.add(b.protocol);
    return [_Protocol.zigbee, _Protocol.wifi, _Protocol.zwave, _Protocol.matter]
        .where(seen.contains)
        .toList();
  }

  List<_Brand> get _filtered =>
      _filter == null ? _brands : _brands.where((b) => b.protocol == _filter).toList();

  static String _protocolLabel(_Protocol p) => switch (p) {
    _Protocol.zigbee => 'Zigbee',
    _Protocol.wifi   => 'WiFi',
    _Protocol.zwave  => 'Z-Wave',
    _Protocol.matter => 'Matter',
  };

  static IconData _protocolIcon(_Protocol p) => switch (p) {
    _Protocol.zigbee => Symbols.hub,
    _Protocol.wifi   => Symbols.wifi,
    _Protocol.zwave  => Symbols.cell_tower,
    _Protocol.matter => Symbols.grain,
  };

  static Color _protocolColor(_Protocol p) => switch (p) {
    _Protocol.zigbee => _kZigbee,
    _Protocol.wifi   => _kWifi,
    _Protocol.zwave  => _kZwave,
    _Protocol.matter => _kMatter,
  };

  void _showPairingSheet(_Brand brand) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BrandPairingSheet(
        brand: brand,
        deviceId: widget.deviceId,
        deviceIcon: widget.deviceIcon,
        onConfirm: widget.onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.chevron_right,
                          color: context.tText2(0.7), size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.chooseBrand,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Device type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.deviceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.deviceIcon,
                            color: widget.deviceColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          widget.deviceName,
                          style: TextStyle(
                              color: widget.deviceColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Protocol filter chips (dynamic per device type) ──
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: s.allDevices,
                    icon: Symbols.grid_view,
                    selected: _filter == null,
                    color: widget.deviceColor,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ..._availableProtocols.map((p) => _FilterChip(
                        label: _protocolLabel(p),
                        icon: _protocolIcon(p),
                        selected: _filter == p,
                        color: _protocolColor(p),
                        onTap: () => setState(() => _filter = p),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Brand list ────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _BrandCard(
                  brand: _filtered[i],
                  onTap: () => _showPairingSheet(_filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Brand card
// ─────────────────────────────────────────────────────────────
class _BrandCard extends StatelessWidget {
  final _Brand brand;
  final VoidCallback onTap;
  const _BrandCard({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = brand.accentColor;
    final protocolLabel = switch (brand.protocol) {
      _Protocol.zigbee => 'Zigbee',
      _Protocol.wifi   => 'WiFi',
      _Protocol.zwave  => 'Z-Wave',
      _Protocol.matter => 'Matter',
    };
    final protocolIcon = switch (brand.protocol) {
      _Protocol.zigbee => Symbols.hub,
      _Protocol.wifi   => Symbols.wifi,
      _Protocol.zwave  => Symbols.cell_tower,
      _Protocol.matter => Symbols.grain,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            // Brand initial bubble
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: c.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(
                  brand.name[0],
                  style: TextStyle(
                      color: c, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name / model / hub note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    brand.model,
                    style: TextStyle(color: context.tText2(0.55), fontSize: 12),
                  ),
                  if (brand.requiresHub && brand.hubNote.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      brand.hubNote,
                      style:
                          TextStyle(color: c.withValues(alpha: 0.65), fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Protocol badge + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(protocolIcon, color: c, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        protocolLabel,
                        style: TextStyle(
                            color: c,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Symbols.chevron_left,
                    color: context.tText2(0.28), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pairing sheet  (steps → scan → found / notFound / manualAdd → linking)
// ─────────────────────────────────────────────────────────────
enum _PairingPhase { steps, scanning, found, notFound, manualAdd, linking }

class _BrandPairingSheet extends StatefulWidget {
  final _Brand brand;
  final String deviceId;
  final IconData deviceIcon;
  final void Function(String name) onConfirm;

  const _BrandPairingSheet({
    required this.brand,
    required this.deviceId,
    required this.deviceIcon,
    required this.onConfirm,
  });

  @override
  State<_BrandPairingSheet> createState() => _BrandPairingSheetState();
}

class _BrandPairingSheetState extends State<_BrandPairingSheet>
    with SingleTickerProviderStateMixin {
  _PairingPhase _phase = _PairingPhase.steps;

  late AnimationController _pulseCtrl;
  final RealDiscoveryEngine _engine = RealDiscoveryEngine();
  List<DiscoveredDevice> _matched = [];
  int _selectedIdx = 0;

  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _nameCtrl = TextEditingController(text: widget.brand.name);
    _engine.addListener(_onEngineUpdate);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _engine
      ..removeListener(_onEngineUpdate)
      ..stopScan();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    _matched = _engine.found.where((d) => _typeMatches(d.type)).toList();
    if (!_engine.isScanning && _phase == _PairingPhase.scanning) {
      setState(() =>
          _phase = _matched.isNotEmpty ? _PairingPhase.found : _PairingPhase.notFound);
    } else {
      setState(() {});
    }
  }

  bool _typeMatches(DiscoveredDeviceType dt) {
    switch (widget.deviceId) {
      case 'motion':
        return dt == DiscoveredDeviceType.motionSensor ||
            dt == DiscoveredDeviceType.sensor;
      case 'door':
      case 'window':
        return dt == DiscoveredDeviceType.doorSensor ||
            dt == DiscoveredDeviceType.windowSensor ||
            dt == DiscoveredDeviceType.sensor;
      case 'plug':
        return dt == DiscoveredDeviceType.socket ||
            dt == DiscoveredDeviceType.smartSwitch;
      case 'switch1':
      case 'dimmer':
        return dt == DiscoveredDeviceType.smartSwitch ||
            dt == DiscoveredDeviceType.socket;
      case 'smoke':
        return dt == DiscoveredDeviceType.smokeSensor ||
            dt == DiscoveredDeviceType.sensor;
      default:
        return false;
    }
  }

  void _startScan() {
    setState(() {
      _phase = _PairingPhase.scanning;
      _matched = [];
      _selectedIdx = 0;
    });
    _engine.startScan();
  }

  void _link() {
    final name = _matched.isNotEmpty
        ? _matched[_selectedIdx].displayName
        : widget.brand.name;
    setState(() => _phase = _PairingPhase.linking);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onConfirm(name);
      Navigator.pop(context);
    });
  }

  void _manualAdd() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _phase = _PairingPhase.linking);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.onConfirm(name);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    final c = widget.brand.accentColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24, right: 24, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.tText2(0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Brand header ────────────────────────────────────
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: c.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(widget.brand.name[0],
                    style: TextStyle(
                        color: c, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.brand.name} ${widget.brand.model}',
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _ProtocolBadge(brand: widget.brand),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Steps phase ─────────────────────────────────────
          if (_phase == _PairingPhase.steps) ...[
            Text(
              s.pairingSteps,
              style: TextStyle(
                  color: context.tText2(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 12),
            ...widget.brand.steps.asMap().entries.map((e) => _StepRow(
                  index: e.key + 1,
                  step: e.value,
                  isLast: e.key == widget.brand.steps.length - 1,
                )),
            const SizedBox(height: 20),
            FtButton(
              label: s.scanNetworkTitle,
              leadingIcon: Symbols.sensors,
              color: c,
              expand: true,
              onTap: _startScan,
            ),
            const SizedBox(height: 10),
            FtButton(
              label: s.manualAddLabel,
              leadingIcon: Symbols.edit,
              variant: FtButtonVariant.secondary,
              expand: true,
              onTap: () => setState(() => _phase = _PairingPhase.manualAdd),
            ),
            const SizedBox(height: 10),
            FtButton(
              label: s.cancel,
              variant: FtButtonVariant.ghost,
              onTap: () => Navigator.pop(context),
            ),
          ],

          // ── Scanning phase ──────────────────────────────────
          if (_phase == _PairingPhase.scanning) ...[
            _PulseRing(ctrl: _pulseCtrl, color: c, icon: widget.deviceIcon),
            const SizedBox(height: 16),
            Text(s.searching,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _engine.progress > 0 ? _engine.progress : null,
                backgroundColor: context.tText2(0.08),
                color: c,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _engine.status.isNotEmpty ? _engine.status : widget.brand.model,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.tText2(0.30),
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
            FtButton(
              label: s.cancel,
              variant: FtButtonVariant.ghost,
              onTap: () => Navigator.pop(context),
            ),
          ],

          // ── Found phase ─────────────────────────────────────
          if (_phase == _PairingPhase.found) ...[
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secured.withValues(alpha: 0.10),
                  border: Border.all(
                      color: AppColors.secured.withValues(alpha: 0.35),
                      width: 2),
                ),
                child: Icon(widget.deviceIcon,
                    color: AppColors.secured, size: 36),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.deviceFound,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.secured,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              _matched.isNotEmpty
                  ? _matched[_selectedIdx].displayName
                  : widget.brand.model,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: context.tText2(0.50), fontSize: 13),
            ),
            const SizedBox(height: 20),
            FtButton(
              label: s.linkDevice,
              leadingIcon: Symbols.link,
              color: AppColors.secured,
              expand: true,
              onTap: _link,
            ),
            const SizedBox(height: 10),
            FtButton(
              label: s.cancel,
              variant: FtButtonVariant.ghost,
              onTap: () => Navigator.pop(context),
            ),
          ],

          // ── Not-found phase ─────────────────────────────────
          if (_phase == _PairingPhase.notFound) ...[
            Center(
              child: Icon(Symbols.search_off,
                  color: context.tText2(0.22), size: 60),
            ),
            const SizedBox(height: 12),
            Text(s.deviceNotFoundStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.unsecured,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(s.deviceNotFoundHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.tText2(0.45), fontSize: 13)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: FtButton(
                  label: s.rescan,
                  leadingIcon: Symbols.refresh,
                  variant: FtButtonVariant.secondary,
                  onTap: _startScan,
                  expand: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FtButton(
                  label: s.manualAddLabel,
                  leadingIcon: Symbols.edit,
                  color: c,
                  onTap: () => setState(() => _phase = _PairingPhase.manualAdd),
                  expand: true,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            FtButton(
              label: s.back,
              variant: FtButtonVariant.ghost,
              onTap: () => setState(() => _phase = _PairingPhase.steps),
            ),
          ],

          // ── Manual-add phase ────────────────────────────────
          if (_phase == _PairingPhase.manualAdd) ...[
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: context.tText),
              decoration: InputDecoration(
                labelText: s.deviceNameLabel,
                labelStyle: TextStyle(color: context.tText2(0.55)),
                prefixIcon: Icon(widget.deviceIcon, color: c, size: 20),
                filled: true,
                fillColor: context.tCardAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.tBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.tBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FtButton(
              label: s.addDeviceBtn,
              leadingIcon: Symbols.add,
              color: c,
              expand: true,
              onTap: _manualAdd,
            ),
            const SizedBox(height: 10),
            FtButton(
              label: s.back,
              variant: FtButtonVariant.ghost,
              onTap: () => setState(() => _phase = _PairingPhase.steps),
            ),
          ],

          // ── Linking phase ───────────────────────────────────
          if (_phase == _PairingPhase.linking) ...[
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                    color: AppColors.secured, strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.connecting,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pairing step row (numbered list with connector line)
// ─────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final int index;
  final _PairingStep step;
  final bool isLast;
  const _StepRow({required this.index, required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final Color numColor = step.isWarning
        ? AppColors.unsecured
        : step.isAction
            ? AppColors.primary
            : context.tText2(0.45);
    final Color textColor = step.isWarning
        ? AppColors.unsecured
        : step.isAction
            ? context.tText
            : context.tText2(0.72);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: step.isWarning
          // ── Safety warning: full-width banner ────────────────
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.unsecured.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.unsecured.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Icon(step.icon, color: AppColors.unsecured, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.text,
                      style: TextStyle(
                        color: AppColors.unsecured,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          // ── Regular step ──────────────────────────────────────
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isAction
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : context.tText2(0.07),
                        border: step.isAction
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35))
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: TextStyle(
                              color: numColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(width: 1, height: 18, color: context.tText2(0.10)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(step.icon,
                            color: textColor.withValues(alpha: 0.50), size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: step.isAction
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Protocol + hub badges
// ─────────────────────────────────────────────────────────────
class _ProtocolBadge extends StatelessWidget {
  final _Brand brand;
  const _ProtocolBadge({required this.brand});

  @override
  Widget build(BuildContext context) {
    final c = brand.accentColor;
    final label = switch (brand.protocol) {
      _Protocol.zigbee => 'Zigbee',
      _Protocol.wifi   => 'WiFi',
      _Protocol.zwave  => 'Z-Wave',
      _Protocol.matter => 'Matter',
    };
    final icon = switch (brand.protocol) {
      _Protocol.zigbee => Symbols.hub,
      _Protocol.wifi   => Symbols.wifi,
      _Protocol.zwave  => Symbols.cell_tower,
      _Protocol.matter => Symbols.grain,
    };

    return Wrap(
      spacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 10),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: c, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (brand.requiresHub)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: context.tText2(0.07),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.device_hub,
                    color: context.tText2(0.38), size: 10),
                const SizedBox(width: 4),
                Text('Hub',
                    style: TextStyle(
                        color: context.tText2(0.38), fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pulse-ring scan animation
// ─────────────────────────────────────────────────────────────
class _PulseRing extends StatelessWidget {
  final AnimationController ctrl;
  final Color color;
  final IconData icon;
  const _PulseRing({required this.ctrl, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120, height: 120,
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final t = ctrl.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: ((1.0 - t) * 0.35).clamp(0.0, 1.0),
                  child: Container(
                    width: 60 + 60 * t, height: 60 + 60 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.2),
                    ),
                  ),
                ),
                Opacity(
                  opacity: (math.sin(t * math.pi) * 0.40).clamp(0.0, 1.0),
                  child: Container(
                    width: 50 + 40 * t, height: 50 + 40 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.0),
                    ),
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                        color: color.withValues(alpha: 0.45), width: 1.8),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Protocol filter chip
// ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : context.tCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : context.tText2(0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: selected ? color : context.tText2(0.60)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : context.tText2(0.60),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
