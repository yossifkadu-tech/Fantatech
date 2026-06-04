// ─────────────────────────────────────────────────────────────────────────────
// GatewayTypes — enum + per-type metadata + connection field descriptors.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ── Gateway type enum ──────────────────────────────────────────────────────

enum GatewayType {
  homeAssistant,   // existing HA integration
  hue,             // Philips Hue Bridge v1/v2
  dirigera,        // IKEA DIRIGERA (new smart hub)
  tradfri,         // IKEA Trådfri (old gateway, security code)
  zigbee2mqtt,     // Zigbee2MQTT REST API
  deconz,          // deCONZ / Phoscon (Dresden Elektronik)
  smartThings,     // Samsung SmartThings (cloud PAT)
  tuyaSmart,       // Tuya Smart (cloud client creds)
  mqtt,            // Generic MQTT broker (HA discovery)
}

// ── Connection field descriptor ────────────────────────────────────────────

enum FieldInputType { text, ip, password, port, token, code }

class GatewayFieldDef {
  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final FieldInputType inputType;
  final String? defaultValue;
  final bool required;

  const GatewayFieldDef({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType = FieldInputType.text,
    this.defaultValue,
    this.required = true,
  });

  TextInputType get keyboardType => switch (inputType) {
    FieldInputType.ip    => TextInputType.url,
    FieldInputType.port  => TextInputType.number,
    FieldInputType.token => TextInputType.multiline,
    _                    => TextInputType.text,
  };

  bool get obscure => inputType == FieldInputType.password;
}

// ── Gateway metadata ───────────────────────────────────────────────────────

class GatewayMeta {
  final GatewayType type;
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<GatewayFieldDef> fields;

  /// True = user must press a physical button on the hub during pairing.
  final bool requiresButtonPress;
  final String? buttonInstruction;

  /// True = connects to a cloud API, not LAN.
  final bool isCloud;

  /// Optional numbered setup steps shown in the connect sheet (e.g. how to
  /// obtain cloud credentials).
  final List<String>? setupSteps;

  const GatewayMeta({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.fields,
    this.requiresButtonPress = false,
    this.buttonInstruction,
    this.isCloud = false,
    this.setupSteps,
  });
}

// ── Registry ───────────────────────────────────────────────────────────────

class GatewayRegistry {
  GatewayRegistry._();

  static const all = <GatewayMeta>[
    // ── Home Assistant ──────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.homeAssistant,
      name:        'Home Assistant',
      subtitle:    'Zigbee · Z-Wave · WiFi',
      description: 'ייבא את כל המכשירים מ-Home Assistant שלך.',
      icon:        Icons.home_outlined,
      color:       Color(0xFF18BCEC),
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'כתובת IP',
          hint:      '192.168.1.x',
          icon:      Icons.wifi_outlined,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:       'token',
          label:     'Long-Lived Access Token',
          hint:      'eyJ0eXAiOiJKV1Qi…',
          icon:      Icons.key_outlined,
          inputType: FieldInputType.token,
        ),
      ],
    ),

    // ── Philips Hue ─────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.hue,
      name:        'Philips Hue',
      subtitle:    'Zigbee (Hue Protocol)',
      description: 'לחץ על כפתור ה-LINK על הגשר תוך 30 שניות.',
      icon:        Icons.lightbulb_outlined,
      color:       Color(0xFFFFCC00),
      requiresButtonPress: true,
      buttonInstruction:
          'לחץ על הכפתור הגדול במרכז גשר ה-Hue ולאחר מכן לחץ "חבר".',
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'כתובת IP של הגשר',
          hint:      '192.168.1.x',
          icon:      Icons.wifi_outlined,
          inputType: FieldInputType.ip,
        ),
      ],
    ),

    // ── IKEA DIRIGERA ────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.dirigera,
      name:        'IKEA DIRIGERA',
      subtitle:    'Zigbee · Bluetooth',
      description: 'לחץ "חבר" ואז על כפתור ההצמדה ב-DIRIGERA.',
      icon:        Icons.hub_outlined,
      color:       Color(0xFF0058A3),
      requiresButtonPress: true,
      buttonInstruction:
          'לחץ "חבר", ותוך 60 שניות לחץ פעם אחת על כפתור ההצמדה בתחתית ה-DIRIGERA.',
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'כתובת IP של ה-DIRIGERA',
          hint:      '192.168.1.x',
          icon:      Icons.wifi_outlined,
          inputType: FieldInputType.ip,
        ),
      ],
    ),

    // ── IKEA Trådfri (old) ───────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.tradfri,
      name:        'IKEA Trådfri',
      subtitle:    'Zigbee (CoAP)',
      description: 'הגשר הישן של IKEA — נדרש קוד אבטחה מהתווית.',
      icon:        Icons.hub_outlined,
      color:       Color(0xFF0058A3),
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'כתובת IP של הגשר',
          hint:      '192.168.1.x',
          icon:      Icons.wifi_outlined,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:       'code',
          label:     'קוד אבטחה (מתחת לגשר)',
          hint:      'xxxx-xxxx-xxxx-xxxx',
          icon:      Icons.pin_outlined,
          inputType: FieldInputType.code,
        ),
      ],
    ),

    // ── Zigbee2MQTT ──────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.zigbee2mqtt,
      name:        'Zigbee2MQTT',
      subtitle:    'Zigbee via MQTT REST',
      description: 'חבר ל-Zigbee2MQTT דרך ממשק ה-REST שלו.',
      icon:        Icons.router_outlined,
      color:       Color(0xFFEE0079),
      fields: [
        GatewayFieldDef(
          key:          'ip',
          label:        'כתובת IP',
          hint:         '192.168.1.x',
          icon:         Icons.wifi_outlined,
          inputType:    FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:          'port',
          label:        'פורט',
          hint:         '8080',
          icon:         Icons.settings_ethernet_outlined,
          inputType:    FieldInputType.port,
          defaultValue: '8080',
          required:     false,
        ),
        GatewayFieldDef(
          key:          'token',
          label:        'API Token (אופציונלי)',
          hint:         'השאר ריק אם לא הוגדר',
          icon:         Icons.key_outlined,
          inputType:    FieldInputType.token,
          required:     false,
        ),
      ],
    ),

    // ── deCONZ ───────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.deconz,
      name:        'deCONZ / Phoscon',
      subtitle:    'Zigbee (ConBee/RaspBee)',
      description: 'אשר חיבור בממשק Phoscon (Settings → Gateway → Advanced).',
      icon:        Icons.device_hub_outlined,
      color:       Color(0xFF5C6BC0),
      requiresButtonPress: true,
      buttonInstruction:
          'פתח את Phoscon → Settings → Gateway → Advanced → Authenticate app, ולאחר מכן לחץ "חבר".',
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'כתובת IP',
          hint:      '192.168.1.x',
          icon:      Icons.wifi_outlined,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:          'port',
          label:        'פורט',
          hint:         '80',
          icon:         Icons.settings_ethernet_outlined,
          inputType:    FieldInputType.port,
          defaultValue: '80',
          required:     false,
        ),
      ],
    ),

    // ── SmartThings ──────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.smartThings,
      name:        'Samsung SmartThings',
      subtitle:    'Cloud · Matter · Zigbee',
      description: 'צור Personal Access Token בפורטל SmartThings.',
      icon:        Icons.device_thermostat_outlined,
      color:       Color(0xFF1428A0),
      isCloud:     true,
      fields: [
        GatewayFieldDef(
          key:       'token',
          label:     'Personal Access Token',
          hint:      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
          icon:      Icons.key_outlined,
          inputType: FieldInputType.token,
        ),
      ],
    ),

    // ── Tuya Smart ───────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.tuyaSmart,
      name:        'Tuya / Moes',
      subtitle:    'Cloud · WiFi · Zigbee',
      description: 'חבר רכזת Tuya/Moes עם Access ID ו-Secret מ-Tuya IoT.',
      icon:        Icons.cloud_outlined,
      color:       Color(0xFFFF6600),
      isCloud:     true,
      setupSteps: [
        'ודא שהמכשירים עובדים באפליקציית Smart Life / Tuya Smart.',
        'היכנס ל-iot.tuya.com → Cloud → Create Cloud Project (Data Center: Central Europe).',
        'העתק את ה-Access ID וה-Access Secret מהפרויקט.',
        'Devices → Link Tuya App Account → סרוק QR מ-Smart Life ("Me" → סריקה).',
        'Cloud → API → ודא ש-IoT Core + Smart Home Basic Service מאופשרים.',
        'הזן כאן Access ID, Secret ואזור (eu אם בחרת Central Europe).',
      ],
      fields: [
        GatewayFieldDef(
          key:       'clientId',
          label:     'Access ID (Client ID)',
          hint:      'מפורטל Tuya IoT Platform',
          icon:      Icons.badge_outlined,
          inputType: FieldInputType.text,
        ),
        GatewayFieldDef(
          key:       'clientSecret',
          label:     'Access Secret',
          hint:      'מפורטל Tuya IoT Platform',
          icon:      Icons.key_outlined,
          inputType: FieldInputType.password,
        ),
        GatewayFieldDef(
          key:          'region',
          label:        'אזור: eu / us / cn / india',
          hint:         'eu (אירופה — ברירת מחדל)',
          icon:         Icons.public_outlined,
          inputType:    FieldInputType.text,
          defaultValue: 'eu',
          required:     false,
        ),
      ],
    ),

    // ── MQTT ─────────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.mqtt,
      name:        'MQTT Broker',
      subtitle:    'Home Assistant Discovery',
      description: 'התחבר לברוקר MQTT ואסוף מכשירים דרך HA-discovery.',
      icon:        Icons.swap_horiz_outlined,
      color:       Color(0xFF660066),
      fields: [
        GatewayFieldDef(
          key:       'host',
          label:     'Host / IP',
          hint:      '192.168.1.x',
          icon:      Icons.dns_outlined,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:          'port',
          label:        'פורט',
          hint:         '1883',
          icon:         Icons.settings_ethernet_outlined,
          inputType:    FieldInputType.port,
          defaultValue: '1883',
          required:     false,
        ),
        GatewayFieldDef(
          key:      'username',
          label:    'שם משתמש (אופציונלי)',
          hint:     '',
          icon:     Icons.person_outline,
          required: false,
        ),
        GatewayFieldDef(
          key:       'password',
          label:     'סיסמה (אופציונלי)',
          hint:      '',
          icon:      Icons.lock_outline,
          inputType: FieldInputType.password,
          required:  false,
        ),
        GatewayFieldDef(
          key:          'prefix',
          label:        'Topic Prefix',
          hint:         'homeassistant',
          icon:         Icons.label_outline,
          defaultValue: 'homeassistant',
          required:     false,
        ),
      ],
    ),
  ];

  static GatewayMeta forType(GatewayType t) =>
      all.firstWhere((m) => m.type == t);
}
