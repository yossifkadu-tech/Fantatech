import 'package:material_symbols_icons/symbols.dart';
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
  aqara,           // Aqara Hub (M2, E1, M1S Gen2 — local API)
  smartThings,     // Samsung SmartThings (cloud PAT)
  tuyaSmart,       // Tuya Smart (cloud client creds)
  mqtt,            // Generic MQTT broker (HA discovery)
  matter,          // Matter / Thread (local commissioner)
  smartLife,       // Smart Life / Tuya consumer app (cloud)
  googleAssistant, // Google Assistant / Google Home
  alexa,           // Amazon Alexa
  siri,            // Apple HomeKit / Siri Shortcuts
  ajax,            // Ajax Systems alarm/security hub (Cloud API)
  risco,           // Risco alarm panel (RiscoCloud / local IP)
  pima,            // PIMA alarm panel (Net4Pro/Net2Pro local HTTP)
  zwave,           // Z-Wave JS UI (local REST API)
  ifttt,           // IFTTT Webhooks
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
      description: 'Import all devices from your Home Assistant.',
      icon:        Symbols.home,
      color:       Color(0xFF18BCEC),
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'IP Address',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:       'token',
          label:     'Long-Lived Access Token',
          hint:      'eyJ0eXAiOiJKV1Qi…',
          icon:      Symbols.key,
          inputType: FieldInputType.token,
        ),
      ],
    ),

    // ── Philips Hue ─────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.hue,
      name:        'Philips Hue',
      subtitle:    'Zigbee (Hue Protocol)',
      description: 'Press the LINK button on the bridge within 30 seconds.',
      icon:        Symbols.lightbulb,
      color:       Color(0xFFFFCC00),
      requiresButtonPress: true,
      buttonInstruction:
          'Press the large button in the center of the Hue bridge, then tap "Connect".',
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'Bridge IP Address',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
        ),
      ],
    ),

    // ── IKEA DIRIGERA ────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.dirigera,
      name:        'IKEA DIRIGERA',
      subtitle:    'Zigbee · Bluetooth',
      description: 'Tap "Connect" then press the pairing button on DIRIGERA.',
      icon:        Symbols.hub,
      color:       Color(0xFF0058A3),
      requiresButtonPress: true,
      buttonInstruction:
          'Tap "Connect", then within 60 seconds press the pairing button once on the bottom of the DIRIGERA.',
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'DIRIGERA IP Address',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
        ),
      ],
    ),

    // ── IKEA Trådfri (old) ───────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.tradfri,
      name:        'IKEA Trådfri',
      subtitle:    'Zigbee (CoAP)',
      description: 'Older IKEA gateway — requires the security code from the label.',
      icon:        Symbols.hub,
      color:       Color(0xFF0058A3),
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'Gateway IP Address',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:       'code',
          label:     'Security Code (under the gateway)',
          hint:      'xxxx-xxxx-xxxx-xxxx',
          icon:      Symbols.pin,
          inputType: FieldInputType.code,
        ),
      ],
    ),

    // ── Zigbee2MQTT ──────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.zigbee2mqtt,
      name:        'Zigbee2MQTT',
      subtitle:    'Zigbee via MQTT REST',
      description: 'Connect to Zigbee2MQTT via its REST interface.',
      icon:        Symbols.router,
      color:       Color(0xFFEE0079),
      fields: [
        GatewayFieldDef(
          key:          'ip',
          label:        'IP Address',
          hint:         '192.168.1.x',
          icon:         Symbols.wifi,
          inputType:    FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:          'port',
          label:        'Port',
          hint:         '8080',
          icon:         Symbols.settings_ethernet,
          inputType:    FieldInputType.port,
          defaultValue: '8080',
          required:     false,
        ),
        GatewayFieldDef(
          key:          'token',
          label:        'API Token (optional)',
          hint:         'Leave empty if not configured',
          icon:         Symbols.key,
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
      description: 'Authorize the connection in the Phoscon UI (Settings → Gateway → Advanced).',
      icon:        Symbols.device_hub,
      color:       Color(0xFF5C6BC0),
      requiresButtonPress: true,
      buttonInstruction:
          'Open Phoscon → Settings → Gateway → Advanced → Authenticate app, then tap "Connect".',
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'IP Address',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:          'port',
          label:        'Port',
          hint:         '80',
          icon:         Symbols.settings_ethernet,
          inputType:    FieldInputType.port,
          defaultValue: '80',
          required:     false,
        ),
      ],
    ),

    // ── Aqara Hub ────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.aqara,
      name:        'Aqara Hub',
      subtitle:    'Zigbee · Local API (M2 / E1 / M1S)',
      description: 'Connect to an Aqara Hub on your local network using a developer access token.',
      icon:        Symbols.hub,
      color:       Color(0xFF1565C0),
      setupSteps: [
        'Make sure the Aqara hub (M2 / E1 / M1S) is powered on and connected to the same WiFi as your phone.',
        'Tap "Auto-detect Hub IP" below — the app will scan your network and fill in the IP automatically.',
        'To get the Access Token: open developer.aqara.com → sign in with your Aqara account → Create Project → copy the Access Key.',
        'Paste the Access Key in the Token field and tap Connect.',
      ],
      fields: [
        GatewayFieldDef(
          key:       'ip',
          label:     'Hub IP Address',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:       'token',
          label:     'Access Token',
          hint:      'From developer.aqara.com',
          icon:      Symbols.key,
          inputType: FieldInputType.token,
        ),
      ],
    ),

    // ── SmartThings ──────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.smartThings,
      name:        'Samsung SmartThings',
      subtitle:    'Cloud · Matter · Zigbee',
      description: 'Create a Personal Access Token in the SmartThings portal.',
      icon:        Symbols.device_thermostat,
      color:       Color(0xFF1428A0),
      isCloud:     true,
      fields: [
        GatewayFieldDef(
          key:       'token',
          label:     'Personal Access Token',
          hint:      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
          icon:      Symbols.key,
          inputType: FieldInputType.token,
        ),
      ],
    ),

    // ── Tuya Smart ───────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.tuyaSmart,
      name:        'Tuya / Moes',
      subtitle:    'Cloud · WiFi · Zigbee',
      description: 'Connect a Tuya/Moes hub with Access ID and Secret from Tuya IoT.',
      icon:        Symbols.cloud,
      color:       Color(0xFFFF6600),
      isCloud:     true,
      setupSteps: [
        'Make sure your devices work in the Smart Life / Tuya Smart app.',
        'Go to iot.tuya.com → Cloud → Create Cloud Project (Data Center: Central Europe).',
        'Copy the Access ID and Access Secret from the project.',
        'Devices → Link Tuya App Account → scan QR from Smart Life ("Me" → scan).',
        'Cloud → API → ensure IoT Core + Smart Home Basic Service are enabled.',
        'Enter Access ID, Secret and region here (eu if you chose Central Europe).',
      ],
      fields: [
        GatewayFieldDef(
          key:       'clientId',
          label:     'Access ID (Client ID)',
          hint:      'From Tuya IoT Platform portal',
          icon:      Symbols.badge,
          inputType: FieldInputType.text,
        ),
        GatewayFieldDef(
          key:       'clientSecret',
          label:     'Access Secret',
          hint:      'From Tuya IoT Platform portal',
          icon:      Symbols.key,
          inputType: FieldInputType.password,
        ),
        GatewayFieldDef(
          key:          'region',
          label:        'Region: eu / us / cn / india',
          hint:         'eu (Europe — default)',
          icon:         Symbols.public,
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
      description: 'Connect to an MQTT broker and discover devices via HA-discovery.',
      icon:        Symbols.swap_horiz,
      color:       Color(0xFF660066),
      fields: [
        GatewayFieldDef(
          key:       'host',
          label:     'Host / IP',
          hint:      '192.168.1.x',
          icon:      Symbols.dns,
          inputType: FieldInputType.ip,
        ),
        GatewayFieldDef(
          key:          'port',
          label:        'Port',
          hint:         '1883',
          icon:         Symbols.settings_ethernet,
          inputType:    FieldInputType.port,
          defaultValue: '1883',
          required:     false,
        ),
        GatewayFieldDef(
          key:      'username',
          label:    'Username (optional)',
          hint:     '',
          icon:     Symbols.person,
          required: false,
        ),
        GatewayFieldDef(
          key:       'password',
          label:     'Password (optional)',
          hint:      '',
          icon:      Symbols.lock,
          inputType: FieldInputType.password,
          required:  false,
        ),
        GatewayFieldDef(
          key:          'prefix',
          label:        'Topic Prefix',
          hint:         'homeassistant',
          icon:         Symbols.label,
          defaultValue: 'homeassistant',
          required:     false,
        ),
      ],
    ),

    // ── Matter ───────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.matter,
      name:        'Matter',
      subtitle:    'Thread · WiFi · Local',
      description: 'Connect Matter devices directly on your local network without cloud.',
      icon:        Symbols.hub,
      color:       Color(0xFF00BCD4),
      setupSteps: [
        'Make sure your device supports Matter (look for the Matter logo on the box).',
        'Connect the Matter device to your WiFi or Thread network.',
        'Enter the Pairing Code from the device (11 digits, usually on the back of the box).',
        'FantaTech will connect to the device directly on the local network.',
      ],
      fields: [
        GatewayFieldDef(
          key:       'pairingCode',
          label:     'Pairing Code',
          hint:      'XXXXX-XXXXX',
          icon:      Symbols.pin,
          inputType: FieldInputType.code,
        ),
        GatewayFieldDef(
          key:       'ip',
          label:     'IP Address (optional)',
          hint:      '192.168.1.x',
          icon:      Symbols.wifi,
          inputType: FieldInputType.ip,
          required:  false,
        ),
      ],
    ),

    // ── Smart Life ───────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.smartLife,
      name:        'Smart Life',
      subtitle:    'Tuya Cloud · WiFi · Zigbee',
      description: 'Import devices from the Smart Life / Tuya Smart app.',
      icon:        Symbols.cloud_circle,
      color:       Color(0xFF00C853),
      isCloud:     true,
      setupSteps: [
        'Make sure your devices are connected and working in the Smart Life app.',
        'Go to iot.tuya.com → Cloud → Create Cloud Project.',
        'Devices → Link Tuya App Account → scan QR from Smart Life (Me → scan).',
        'Copy the Access ID and Secret from the project.',
        'Enter the credentials and your server region here.',
      ],
      fields: [
        GatewayFieldDef(
          key:       'clientId',
          label:     'Access ID',
          hint:      'From Tuya IoT portal',
          icon:      Symbols.badge,
          inputType: FieldInputType.text,
        ),
        GatewayFieldDef(
          key:       'clientSecret',
          label:     'Access Secret',
          hint:      'From Tuya IoT portal',
          icon:      Symbols.key,
          inputType: FieldInputType.password,
        ),
        GatewayFieldDef(
          key:          'region',
          label:        'Region: eu / us / cn',
          hint:         'eu',
          icon:         Symbols.public,
          inputType:    FieldInputType.text,
          defaultValue: 'eu',
          required:     false,
        ),
      ],
    ),

    // ── Google Assistant ─────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.googleAssistant,
      name:        'Google Assistant',
      subtitle:    'Google Home · Cloud',
      description: 'Control devices via "Hey Google" and the Google Home app.',
      icon:        Symbols.assistant,
      color:       Color(0xFF4285F4),
      isCloud:     true,
      setupSteps: [
        'Open the Google Home app on your device.',
        'Go to + → Set up device → Works with Google.',
        'Search for "FantaTech" in the list and tap it.',
        'Sign in to your FantaTech account.',
        'Devices will appear in Google Home and become available for "Hey Google".',
      ],
      fields: [],
    ),

    // ── Amazon Alexa ─────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.alexa,
      name:        'Amazon Alexa',
      subtitle:    'Alexa App · Cloud',
      description: 'Control devices via "Alexa" and the Amazon Alexa app.',
      icon:        Symbols.mic,
      color:       Color(0xFF00CAFF),
      isCloud:     true,
      setupSteps: [
        'Open the Amazon Alexa app.',
        'Go to More → Skills & Games.',
        'Search for "FantaTech" and enable the Skill.',
        'Sign in to your FantaTech account.',
        'Say "Alexa, discover devices" to finish connecting.',
      ],
      fields: [],
    ),

    // ── Apple Siri / HomeKit ─────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.siri,
      name:        'Siri / HomeKit',
      subtitle:    'Apple Home · HomeKit',
      description: 'Add devices to Apple Home and control them via Siri.',
      icon:        Symbols.mic_none,
      color:       Color(0xFFFF2D55),
      setupSteps: [
        'Open the Apple Home app on your iPhone or iPad.',
        'Tap + → Add Accessory.',
        'Scan the HomeKit code from the device (QR or 8 digits).',
        'To connect FantaTech: My Home → Home Settings → Home Hubs & Bridges.',
        'Say "Hey Siri, turn on [device name]" for voice control.',
      ],
      fields: [
        GatewayFieldDef(
          key:       'homekitCode',
          label:     'HomeKit Pairing Code (optional)',
          hint:      'XXX-XX-XXX',
          icon:      Symbols.pin,
          inputType: FieldInputType.code,
          required:  false,
        ),
      ],
    ),

    // ── Ajax Systems ─────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.ajax,
      name:        'Ajax Systems',
      subtitle:    'Security · Cloud API',
      description: 'Connect your Ajax alarm hub and sensors via Ajax Cloud.',
      icon:        Symbols.security,
      color:       Color(0xFFE53935),
      isCloud:     true,
      setupSteps: [
        'Open the Ajax app → Hub settings → API.',
        'Enable API access and copy the API key.',
        'Enter your Ajax account email, password and the API key below.',
        'All Ajax sensors (motion, door, smoke, flood, siren) will be imported.',
      ],
      fields: [
        GatewayFieldDef(key: 'email',    label: 'Ajax Account Email',    hint: 'your@email.com',         icon: Symbols.email,      inputType: FieldInputType.text),
        GatewayFieldDef(key: 'password', label: 'Ajax Account Password', hint: 'password',               icon: Symbols.lock,        inputType: FieldInputType.password),
        GatewayFieldDef(key: 'apiKey',   label: 'API Key (optional)',    hint: 'From Ajax app → API',    icon: Symbols.key,        inputType: FieldInputType.token, required: false),
      ],
    ),

    // ── Risco ─────────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.risco,
      name:        'Risco',
      subtitle:    'Alarm Panel · LightSYS / Agility',
      description: 'Connect a Risco alarm panel (LightSYS+, ProSYS Plus, Agility) via RiscoCloud or local IP.',
      icon:        Symbols.shield,
      color:       Color(0xFF1565C0),
      setupSteps: [
        'For RiscoCloud: log in at riscocloud.com and note your username/password.',
        'For local IP: connect the panel to your network and note the IP address.',
        'Enter either your RiscoCloud credentials or the panel local IP below.',
        'The app will import all zones (sensors), partitions, and keypad status.',
      ],
      fields: [
        GatewayFieldDef(key: 'username', label: 'Username / Email',       hint: 'riscocloud login',  icon: Symbols.person,     inputType: FieldInputType.text),
        GatewayFieldDef(key: 'password', label: 'Password',               hint: 'password',         icon: Symbols.lock,       inputType: FieldInputType.password),
        GatewayFieldDef(key: 'ip',       label: 'Panel IP (if local)',     hint: '192.168.1.x',      icon: Symbols.wifi,      inputType: FieldInputType.ip,   required: false),
        GatewayFieldDef(key: 'pin',      label: 'Panel PIN Code',          hint: '1234',             icon: Symbols.dialpad,   inputType: FieldInputType.code),
      ],
    ),

    // ── PIMA ─────────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.pima,
      name:        'PIMA',
      subtitle:    'Alarm Panel · Net4Pro / Net2Pro',
      description: 'Connect a PIMA alarm panel with network module (Net4Pro / Net2Pro) on your local network.',
      icon:        Symbols.security_update_warning,
      color:       Color(0xFF6A1B9A),
      setupSteps: [
        'Make sure the PIMA panel has a Net4Pro or Net2Pro network module installed.',
        'Connect the module to your home network and note its IP address.',
        'Enter the panel IP, port (default 9999), and installer code below.',
        'All zones and outputs will be imported automatically.',
      ],
      fields: [
        GatewayFieldDef(key: 'ip',   label: 'Panel IP Address',   hint: '192.168.1.x',  icon: Symbols.wifi,       inputType: FieldInputType.ip),
        GatewayFieldDef(key: 'port', label: 'Port',               hint: '9999',         icon: Symbols.settings_ethernet, inputType: FieldInputType.port, defaultValue: '9999', required: false),
        GatewayFieldDef(key: 'code', label: 'Installer/User Code', hint: '1234',        icon: Symbols.dialpad,    inputType: FieldInputType.code),
      ],
    ),

    // ── Z-Wave JS UI ─────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.zwave,
      name:        'Z-Wave JS UI',
      subtitle:    'Z-Wave · Local REST API',
      description: 'Connect to a Z-Wave JS UI server (Z-Wave to MQTT bridge) running on your home network.',
      icon:        Symbols.router,
      color:       Color(0xFF00796B),
      setupSteps: [
        'Make sure Z-Wave JS UI (zwavejs2mqtt) is running (usually port 8091).',
        'Open Z-Wave JS UI → Settings → Home Assistant → copy the API key.',
        'Enter the IP address, port, and optionally the API key below.',
        'All Z-Wave devices (sensors, switches, locks, thermostats) will be imported.',
      ],
      fields: [
        GatewayFieldDef(key: 'ip',     label: 'Z-Wave JS UI IP',  hint: '192.168.1.x', icon: Symbols.wifi,       inputType: FieldInputType.ip),
        GatewayFieldDef(key: 'port',   label: 'Port',             hint: '8091',        icon: Symbols.settings_ethernet, inputType: FieldInputType.port, defaultValue: '8091', required: false),
        GatewayFieldDef(key: 'apiKey', label: 'API Key (optional)', hint: 'leave empty if not set', icon: Symbols.key, inputType: FieldInputType.token, required: false),
      ],
    ),

    // ── IFTTT ────────────────────────────────────────────────────────────────
    GatewayMeta(
      type:        GatewayType.ifttt,
      name:        'IFTTT',
      subtitle:    'Webhooks · Cloud',
      description: 'Trigger IFTTT Webhooks from FantaTech automations.',
      icon:        Symbols.bolt,
      color:       Color(0xFF333333),
      isCloud:     true,
      setupSteps: [
        'Go to ifttt.com → Create → If This → Webhooks → Receive a web request.',
        'Name your event (e.g. "fantatech_trigger") and copy the key from your Webhooks settings.',
        'Enter the Webhooks key below.',
        'Use the "Trigger IFTTT" action in FantaTech automations.',
      ],
      fields: [
        GatewayFieldDef(key: 'webhookKey', label: 'Webhooks Key', hint: 'From ifttt.com/maker_webhooks/settings', icon: Symbols.key, inputType: FieldInputType.token),
      ],
    ),
  ];

  static GatewayMeta forType(GatewayType t) =>
      all.firstWhere((m) => m.type == t);
}
