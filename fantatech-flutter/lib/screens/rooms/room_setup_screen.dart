import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../models/device_capabilities.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../utils/ac_options.dart';
import '../../widgets/device_card.dart';
import '../media/media_screen.dart';
import '../smarthome/scan_discovery_screen.dart';
import '../smarthome/smart_switch_hub_screen.dart';
import '../smarthome/sensor_hub_screen.dart';
import '../smarthome/intercom_hub_screen.dart';

const _kBg     = Color(0xFFF0F2F5);
const _kCard   = Colors.white;
const _kDark   = Color(0xFF1A1A2E);
const _kGrey   = Color(0xFF8E8E93);

// ── Where a tile leads when tapped ───────────────────────────────
enum _Dest { cameras, media, switches, sensors, intercom, none }

// ── A configurable room capability ──────────────────────────────
class _Cap {
  final IconData icon;
  final Color color;
  final String he;
  final String en;
  final _Dest dest;
  const _Cap(this.icon, this.color, this.he, this.en, this.dest);
}

// ── Capability catalogue ─────────────────────────────────────────
const _plugs    = _Cap(Symbols.power,            Color(0xFF42A5F5), 'שקעים חכמים', 'Smart Plugs', _Dest.switches);
const _cameras  = _Cap(Symbols.videocam,         Color(0xFF26C6DA), 'מצלמות', 'Cameras', _Dest.cameras);
const _gates    = _Cap(Symbols.fence,            Color(0xFF8D6E63), 'שערים', 'Gates', _Dest.none);
const _media    = _Cap(Symbols.movie,            Color(0xFFE53935), 'מולטימדיה', 'Multimedia', _Dest.media);
const _switches = _Cap(Symbols.toggle_on,        Color(0xFF7E57C2), 'מפסקים חכמים', 'Smart Switches', _Dest.switches);
const _light    = _Cap(Symbols.lightbulb,        Color(0xFFFFB300), 'תאורה חכמה', 'Smart Lighting', _Dest.none);
const _warmLight= _Cap(Symbols.wb_incandescent,  Color(0xFFFF8F00), 'תאורה חמה', 'Warm Lighting', _Dest.none);
const _ac       = _Cap(Symbols.ac_unit,          Color(0xFF29B6F6), 'מזגן ושלטים', 'AC & Remotes', _Dest.none);
const _odor     = _Cap(Symbols.air,              Color(0xFF66BB6A), 'גלאי ריחות', 'Odor Detector', _Dest.sensors);
const _winDoor  = _Cap(Symbols.sensor_window,    Color(0xFF26A69A), 'חיישן חלון/דלת', 'Window/Door Sensor', _Dest.sensors);
const _door     = _Cap(Symbols.sensor_door,      Color(0xFF26A69A), 'חיישן דלת', 'Door Sensor', _Dest.sensors);
const _blind    = _Cap(Symbols.blinds,           Color(0xFF8E63CE), 'מפסק תריס', 'Blind Switch', _Dest.sensors);
const _ambiance = _Cap(Symbols.auto_awesome,     Color(0xFFFF6B00), 'אוטומציות אווירה', 'Ambiance Scenes', _Dest.none);
const _speakers = _Cap(Symbols.speaker,          Color(0xFF5C6BC0), 'רמקולים', 'Speakers', _Dest.media);
const _receiver = _Cap(Symbols.settings_input_hdmi, Color(0xFF455A64), 'רסיברים', 'Receivers', _Dest.media);
const _tv       = _Cap(Symbols.tv,               Color(0xFF00897B), 'טלוויזיות חכמות', 'Smart TVs', _Dest.media);
const _streamer = _Cap(Symbols.cast,             Color(0xFFAB47BC), 'סטרימרים', 'Streamers', _Dest.media);
const _voice    = _Cap(Symbols.mic,              Color(0xFF26C6DA), 'אלקסה / סירי', 'Alexa & Siri', _Dest.none);
const _intercom = _Cap(Symbols.doorbell,         Color(0xFFEF5350), 'אינטרקום', 'Intercom', _Dest.intercom);
const _smoke    = _Cap(Symbols.local_fire_department, Color(0xFFFF7043), 'גלאי עשן', 'Smoke Detector', _Dest.sensors);
const _gas      = _Cap(Symbols.gas_meter,        Color(0xFFFFA726), 'גלאי גז', 'Gas Detector', _Dest.sensors);
const _leak     = _Cap(Symbols.water_damage,     Color(0xFF42A5F5), 'גלאי נזילות', 'Leak Detector', _Dest.sensors);

// ── Per-room-type capability sets ────────────────────────────────
const _living = <_Cap>[
  _light, _switches, _plugs, _ac, _blind, _ambiance,
  _cameras, _gates, _winDoor,
  _media, _tv, _streamer, _speakers, _receiver, _voice, _odor,
];
const _garden = <_Cap>[
  _warmLight, _switches, _plugs, _cameras, _streamer, _gates, _intercom,
];
const _kitchen = <_Cap>[
  _light, _switches, _plugs, _winDoor, _smoke, _gas, _media,
];
const _bathroom = <_Cap>[
  _switches, _plugs, _door, _odor, _leak,
];

/// Resolve which capability set a room should offer, from its key/name.
List<_Cap> _capsFor(String key) {
  final k = key.toLowerCase();
  if (k.contains('living') || k.contains('סלון')) return _living;
  if (k.contains('garden') || k.contains('גינה') || k.contains('חצר')) return _garden;
  if (k.contains('kitchen') || k.contains('מטבח')) return _kitchen;
  if (k.contains('bath') || k.contains('שירות') || k.contains('מקלח') ||
      k.contains('אמבט')) return _bathroom;
  // Bedroom / media / custom rooms → a sensible general set.
  return const <_Cap>[
    _light, _switches, _plugs, _ac, _winDoor, _media, _cameras,
  ];
}

class RoomSetupScreen extends StatelessWidget {
  final String roomKey;
  final String roomName;
  final IconData icon;
  final Color color;
  const RoomSetupScreen({
    super.key,
    required this.roomKey,
    required this.roomName,
    required this.icon,
    required this.color,
  });

  void _open(BuildContext context, _Cap cap) {
    Widget? target;
    switch (cap.dest) {
      case _Dest.cameras:
        target = const ScanDiscoveryScreen(cameraOnly: true);
      case _Dest.media:
        target = const MediaScreen();
      case _Dest.switches:
        target = const SmartSwitchHubScreen();
      case _Dest.sensors:
        target = const SensorHubScreen();
      case _Dest.intercom:
        target = const IntercomHubScreen();
      case _Dest.none:
        target = null;
    }
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
    } else {
      final s = context.read<AppState>().strings;
      final he = context.read<AppState>().locale == AppLocale.hebrew;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.capComingSoonFmt.replaceAll('{cap}', he ? cap.he : cap.en)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Multi-field watch: strings + locale + live device states for this room.
    final state = context.watch<AppState>();
    final s = state.strings;
    final he = state.locale == AppLocale.hebrew;
    final caps = _capsFor(roomKey);
    final roomDevices =
        state.devices.where((d) => d.room == roomKey).toList();

    // Partition into control sections (climate / lights / switches / sensors).
    final climate = roomDevices
        .where((d) => d.type == DeviceType.airConditioner)
        .toList();
    final lights =
        roomDevices.where((d) => d.type == DeviceType.light).toList();
    final switches = roomDevices
        .where((d) =>
            d.type == DeviceType.smartSwitch || d.type == DeviceType.smartPlug)
        .toList();
    final sensors = roomDevices.where(DeviceCapabilities.canTrigger).toList();
    final sectioned = {...climate, ...lights, ...switches, ...sensors};
    final others =
        roomDevices.where((d) => !sectioned.contains(d)).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Symbols.arrow_back, color: _kDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roomName,
                            style: const TextStyle(
                                color: _kDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        Text(s.roomSettings,
                            style: const TextStyle(color: _kGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Content: live room devices + capability grid ────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  // ── Climate: full inline AC control ──────────────
                  if (climate.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Symbols.ac_unit,
                        title: s.acCategory,
                        color: AppColors.acColor),
                    for (final d in climate) _ClimateCard(device: d, s: s),
                    const SizedBox(height: 16),
                  ],
                  // ── Lights: toggle + dimmer ──────────────────────
                  if (lights.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Symbols.lightbulb,
                        title: s.lightsCategory,
                        color: AppColors.lightColor),
                    for (final d in lights)
                      _ControlRow(device: d, accent: AppColors.lightColor),
                    const SizedBox(height: 16),
                  ],
                  // ── Switches & plugs: on/off ─────────────────────
                  if (switches.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Symbols.toggle_on,
                        title: s.switchesCategory,
                        color: AppColors.plugColor),
                    for (final d in switches)
                      _ControlRow(device: d, accent: AppColors.plugColor),
                    const SizedBox(height: 16),
                  ],
                  // ── Sensors: live status ─────────────────────────
                  if (sensors.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Symbols.sensors,
                        title: s.sensorsCategory,
                        color: AppColors.motionColor),
                    for (final d in sensors) _SensorRow(device: d, s: s),
                    const SizedBox(height: 16),
                  ],
                  // ── Everything else (cameras, locks, TVs…) ───────
                  if (others.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Symbols.devices,
                        title: s.devicesInRoom,
                        color: _kGrey),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: others.length,
                      itemBuilder: (_, i) => DeviceCard(
                        device: others[i],
                        onToggle: () => state.toggleDevice(others[i].id),
                        onFavoriteToggle: () =>
                            state.toggleFavorite(others[i].id),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // ── Capability shortcuts ─────────────────────────
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: caps.length,
                    itemBuilder: (_, i) {
                      final c = caps[i];
                  return GestureDetector(
                    onTap: () => _open(context, c),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 8,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: c.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(c.icon, color: c.color, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            he ? c.he : c.en,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _kDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.15),
                          ),
                        ],
                      ),
                    ),
                  );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section widgets — room control panel
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: _kDark, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Full inline climate control: power, target temperature, mode, fan speed.
/// Options adapt to what the AC actually supports (HA-synced mode lists).
class _ClimateCard extends StatelessWidget {
  final Device device;
  final S s;
  const _ClimateCard({required this.device, required this.s});

  Widget _chips({
    required List<(String, String, IconData)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (value, label, icon) in options)
          GestureDetector(
            onTap: () => onSelect(value),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: value == selected
                    ? AppColors.acColor.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: value == selected
                        ? AppColors.acColor
                        : Colors.black.withValues(alpha: 0.08)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    color: value == selected ? AppColors.acColor : _kGrey,
                    size: 13),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: value == selected ? _kDark : _kGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final d = device;
    final a = d.attributes;

    final minT = (a['minTemp'] as num?)?.toDouble() ?? 16;
    final maxT = (a['maxTemp'] as num?)?.toDouble() ?? 30;
    final target =
        ((a['temperature'] as num?)?.toDouble() ?? 22).clamp(minT, maxT);
    final hvacModes = (a['hvacModes'] as List?)
            ?.cast<String>()
            .where((m) => m != 'off')
            .toList() ??
        const ['cool', 'heat', 'fan', 'dry', 'auto'];
    final fanModes = (a['fanModes'] as List?)?.cast<String>() ??
        const ['low', 'med', 'high', 'auto'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.acColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Symbols.ac_unit,
                  color: AppColors.acColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _kDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            Switch(
              value: d.isOn,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.acColor,
              onChanged: (_) => state.toggleDevice(d.id),
            ),
          ]),
          if (d.isOn) ...[
            const SizedBox(height: 4),
            Text('${s.deviceTemp}: ${target.round()}°C',
                style: const TextStyle(color: _kGrey, fontSize: 12)),
            Slider(
              value: target.toDouble(),
              min: minT,
              max: maxT,
              divisions: (maxT - minT).round().clamp(1, 60),
              activeColor: AppColors.acColor,
              onChanged: (v) =>
                  state.setDeviceAttribute(d.id, 'temperature', v.toInt()),
            ),
            Text(s.acMode,
                style: const TextStyle(color: _kGrey, fontSize: 12)),
            const SizedBox(height: 6),
            _chips(
              options: [for (final m in hvacModes) acModeOption(s, m)],
              selected: a['mode'] as String? ?? hvacModes.first,
              onSelect: (v) => state.setDeviceAttribute(d.id, 'mode', v),
            ),
            const SizedBox(height: 10),
            Text(s.acFanSpeed,
                style: const TextStyle(color: _kGrey, fontSize: 12)),
            const SizedBox(height: 6),
            _chips(
              options: [for (final m in fanModes) acFanOption(s, m)],
              selected: a['fan'] as String? ?? fanModes.last,
              onSelect: (v) => state.setDeviceAttribute(d.id, 'fan', v),
            ),
          ],
        ],
      ),
    );
  }
}

/// Toggle row for lights/switches/plugs; lights also get a dimmer slider
/// when the device reports a brightness capability.
class _ControlRow extends StatelessWidget {
  final Device device;
  final Color accent;
  const _ControlRow({required this.device, required this.accent});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final d = device;
    final dimmable =
        DeviceCapabilities.of(d).contains(DeviceCapability.brightness);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Icon(DeviceIcons.forDevice(d),
              color: d.isOn && d.online ? accent : _kGrey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(d.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _kDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: d.isOn,
            activeThumbColor: Colors.white,
            activeTrackColor: accent,
            onChanged: d.online ? (_) => state.toggleDevice(d.id) : null,
          ),
        ]),
        if (dimmable && d.isOn)
          Slider(
            value: ((d.attributes['brightness'] as num?)?.toDouble() ?? 80)
                .clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 10,
            activeColor: accent,
            onChanged: (v) =>
                state.setDeviceAttribute(d.id, 'brightness', v.toInt()),
          ),
      ]),
    );
  }
}

/// Read-only live status row for a sensor (motion / leak / door / smoke…).
class _SensorRow extends StatelessWidget {
  final Device device;
  final S s;
  const _SensorRow({required this.device, required this.s});

  @override
  Widget build(BuildContext context) {
    final d = device;
    final key = DeviceCapabilities.binaryStateKey(d.type);
    final active = key != null && d.attributes[key] == true;
    final offline = !d.online;
    final color = offline
        ? AppColors.statusOffline
        : (active ? AppColors.unsecured : _kGrey);
    final label = offline
        ? s.statusOffline
        : (active ? s.activeStatus : s.normalStatus);
    final battery = d.battery ?? (d.attributes['battery'] as num?)?.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Icon(DeviceIcons.forDevice(d), color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _kDark, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        if (battery != null) ...[
          Icon(DeviceIcons.batteryIcon(battery),
              size: 13,
              color: battery <= 20 ? AppColors.statusAlarm : _kGrey),
          const SizedBox(width: 2),
          Text('$battery%',
              style: TextStyle(
                  color: battery <= 20 ? AppColors.statusAlarm : _kGrey,
                  fontSize: 11)),
          const SizedBox(width: 10),
        ],
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
