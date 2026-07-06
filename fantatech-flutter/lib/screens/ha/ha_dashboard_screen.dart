import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HaDashboardScreen — ממשק FantaTech ראשי מחובר ל-Home Assistant
// עיצוב כהה ומקצועי, שליטה מהירה, סטטוס בזמן אמת
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ha/ha_entity.dart';
import '../../services/ha/ha_provider.dart';
import '../../theme/device_icons.dart';
import 'ha_camera_viewer_screen.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _card    = Color(0xFF21262D);
const _border  = Color(0xFF30363D);
const _orange  = Color(0xFFFF6B00);
const _green   = Color(0xFF3FB950);
const _red     = Color(0xFFF85149);
const _yellow  = Color(0xFFD29922);
const _blue    = Color(0xFF58A6FF);
const _text1   = Color(0xFFE6EDF3);
const _text2   = Color(0xFF8B949E);

/// Runs an HA command and surfaces a visible SnackBar if it fails or throws
/// — without this, a failed/no-op command (wrong entity, disconnected mid-
/// tap, an exception in the WS/REST layer) looked exactly like "nothing
/// happened", which is indistinguishable from the button being dead.
Future<void> _runHaCommand(
  BuildContext context,
  Future<bool> Function() action, {
  String? emptyMessage,
}) async {
  try {
    final ok = await action();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(emptyMessage ??
            'הפקודה לא הגיעה ל-Home Assistant — בדוק את החיבור'),
        backgroundColor: _red,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('שגיאה: $e'),
        backgroundColor: _red,
      ));
    }
  }
}

class HaDashboardScreen extends StatelessWidget {
  const HaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ha = context.watch<HaProvider>();

    if (!ha.isConnected) {
      return const _ConnectingView();
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────
            const SliverToBoxAdapter(child: _TopBar()),

            // ── Status Strip ──────────────────────────────────────
            SliverToBoxAdapter(child: _StatusStrip(ha: ha)),

            // ── Alarm ─────────────────────────────────────────────
            if (ha.alarms.isNotEmpty)
              SliverToBoxAdapter(child: _AlarmCard(alarms: ha.alarms)),

            // ── Quick Controls ────────────────────────────────────
            SliverToBoxAdapter(child: _SectionHeader('שליטה מהירה', Symbols.bolt)),
            SliverToBoxAdapter(child: _QuickControls(ha: ha)),

            // ── Rooms ─────────────────────────────────────────────
            if (ha.areas.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('חדרים', Symbols.meeting_room)),
              SliverToBoxAdapter(child: _RoomsRow(ha: ha)),
            ],

            // ── Lights ───────────────────────────────────────────
            if (ha.lights.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('תאורה', Symbols.lightbulb)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _EntityRow(entity: ha.lights[i], ha: ha),
                  childCount: ha.lights.length,
                ),
              ),
            ],

            // ── Switches ─────────────────────────────────────────
            if (ha.switches.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('מפסקים', Symbols.toggle_on)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _EntityRow(entity: ha.switches[i], ha: ha),
                  childCount: ha.switches.length,
                ),
              ),
            ],

            // ── Climate ──────────────────────────────────────────
            if (ha.climates.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('מיזוג', Symbols.thermostat)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ClimateRow(entity: ha.climates[i], ha: ha),
                  childCount: ha.climates.length,
                ),
              ),
            ],

            // ── Covers ───────────────────────────────────────────
            if (ha.covers.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('תריסים', Symbols.blinds)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _CoverRow(entity: ha.covers[i], ha: ha),
                  childCount: ha.covers.length,
                ),
              ),
            ],

            // ── Locks ─────────────────────────────────────────────
            if (ha.locks.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('מנעולים', Symbols.lock)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _LockRow(entity: ha.locks[i], ha: ha),
                  childCount: ha.locks.length,
                ),
              ),
            ],

            // ── Fans ──────────────────────────────────────────────
            if (ha.fans.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('מאווררים', Symbols.air)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FanRow(entity: ha.fans[i], ha: ha),
                  childCount: ha.fans.length,
                ),
              ),
            ],

            // ── Media Players ─────────────────────────────────────
            if (ha.mediaPlayers.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('מדיה', Symbols.speaker)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _MediaPlayerRow(
                    entity:  ha.mediaPlayers[i],
                    ha:      ha,
                    baseUrl: ha.config?.baseUrl ?? '',
                  ),
                  childCount: ha.mediaPlayers.length,
                ),
              ),
            ],

            // ── Cameras ───────────────────────────────────────────
            if (ha.cameras.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('מצלמות', Symbols.videocam)),
              SliverToBoxAdapter(
                child: _CameraThumbRow(
                  cameras: ha.cameras,
                  baseUrl: ha.config?.baseUrl ?? '',
                  ha:      ha,
                ),
              ),
            ],

            // ── Sensors ──────────────────────────────────────────
            if (ha.sensors.isNotEmpty || ha.binarySensors.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader('חיישנים', Symbols.sensors)),
              SliverToBoxAdapter(
                child: _SensorsGrid(
                  sensors: _filteredSensors(ha),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Device-class prefixes that are home-automation sensors ───────────────
  static const _kHomeSensorClasses = {
    'temperature', 'humidity', 'motion', 'occupancy',
    'door', 'window', 'opening', 'contact',
    'smoke', 'gas', 'carbon_monoxide', 'moisture', 'water',
    'vibration', 'power', 'energy', 'battery',
    'illuminance', 'pressure', 'voltage', 'current', 'frequency',
    'pm25', 'pm10', 'co2', 'volatile_organic_compounds',
    'sound_pressure', 'distance',
  };

  List<HaEntity> _filteredSensors(HaProvider ha) {
    // 1. Merge sensor + binary_sensor
    final all = [...ha.sensors, ...ha.binarySensors];

    // 2. Remove unavailable / unknown states
    final valid = all.where((e) =>
        e.state != 'unavailable' && e.state != 'unknown').toList();

    // 3. Keep only entities with a recognised home-automation device_class
    final home = valid.where((e) =>
        e.deviceClass != null && _kHomeSensorClasses.contains(e.deviceClass)).toList();

    // 4. Deduplicate: if the same physical device has both a sensor and a
    //    binary_sensor, prefer the binary_sensor (door/window open/closed
    //    is more useful than a numeric value from the same unit).
    //    Key = deviceId if present, otherwise entityId.
    final seen  = <String>{};
    final dedup = <HaEntity>[];
    for (final e in home) {
      final key = e.deviceId?.isNotEmpty == true ? e.deviceId! : e.entityId;
      if (seen.add(key)) dedup.add(e);
    }

    return dedup;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final ha = context.watch<HaProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Symbols.home, color: _orange, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FantaTech', style: TextStyle(
                color: _text1, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Smart Home', style: TextStyle(color: _text2, fontSize: 12)),
            ],
          ),
          const Spacer(),
          // Connection status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ha.isConnected
                  ? _green.withValues(alpha: 0.15)
                  : _red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ha.isConnected
                    ? _green.withValues(alpha: 0.4)
                    : _red.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ha.isConnected ? _green : _red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ha.isConnected ? 'מחובר' : 'מנותק',
                  style: TextStyle(
                    color: ha.isConnected ? _green : _red,
                    fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Refresh
          GestureDetector(
            onTap: () => context.read<HaProvider>().refresh(),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(Symbols.refresh, color: _text2, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Strip
// ─────────────────────────────────────────────────────────────────────────────
class _StatusStrip extends StatelessWidget {
  final HaProvider ha;
  const _StatusStrip({required this.ha});

  @override
  Widget build(BuildContext context) {
    final lightsOn   = ha.lights.where((e) => e.isOn).length;
    final switchesOn = ha.switches.where((e) => e.isOn).length;
    final locksLocked = ha.locks.where((e) => e.isLocked).length;
    final mediaOn    = ha.mediaPlayers.where((e) => e.state == 'playing').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatChip(icon: Symbols.lightbulb,    label: '$lightsOn דולקות',  color: _yellow),
            const SizedBox(width: 8),
            _StatChip(icon: Symbols.power,         label: '$switchesOn מפסקים', color: _green),
            if (ha.locks.isNotEmpty) ...[
              const SizedBox(width: 8),
              _StatChip(icon: Symbols.lock, label: '$locksLocked נעולים', color: _blue),
            ],
            if (ha.mediaPlayers.isNotEmpty) ...[
              const SizedBox(width: 8),
              _StatChip(icon: Symbols.speaker, label: '$mediaOn מנגנים', color: _orange),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alarm Card
// ─────────────────────────────────────────────────────────────────────────────
class _AlarmCard extends StatelessWidget {
  final List<HaEntity> alarms;
  const _AlarmCard({required this.alarms});

  @override
  Widget build(BuildContext context) {
    final alarm   = alarms.first;
    final armed   = alarm.isAlarmArmed;
    final color   = alarm.alarmState == 'triggered' ? _red
                  : armed ? _yellow : _green;
    final label   = _alarmLabel(alarm.alarmState);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            armed ? Symbols.security : Symbols.shield,
            color: color, size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alarm.friendlyName,
                    style: const TextStyle(color: _text1, fontWeight: FontWeight.w600)),
                Text(label, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
          // Arm / Disarm
          if (!armed)
            _AlarmButton(
              label: 'הפעל',
              color: _yellow,
              onTap: () => context.read<HaProvider>()
                  .armAlarm(alarm.entityId, mode: 'away'),
            )
          else
            _AlarmButton(
              label: 'כבה',
              color: _red,
              onTap: () => context.read<HaProvider>()
                  .disarmAlarm(alarm.entityId),
            ),
        ],
      ),
    );
  }

  String _alarmLabel(String state) {
    switch (state) {
      case 'armed_away':    return 'מופעל — עזיבה';
      case 'armed_home':    return 'מופעל — בבית';
      case 'armed_night':   return 'מופעל — לילה';
      case 'disarmed':      return 'כבוי';
      case 'triggered':     return '⚠️ אזעקה פעילה!';
      case 'pending':       return 'ממתין...';
      default:              return state;
    }
  }
}

class _AlarmButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AlarmButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Controls — כבה/הדלק הכל
// ─────────────────────────────────────────────────────────────────────────────
class _QuickControls extends StatelessWidget {
  final HaProvider ha;
  const _QuickControls({required this.ha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(child: _QuickBtn(
            icon: Symbols.lightbulb,
            label: 'כל האורות\nכבה',
            color: _yellow,
            onTap: () => _runHaCommand(context, () async {
              if (ha.lights.isEmpty) return false;
              var allOk = true;
              for (final l in ha.lights) {
                if (!await ha.setOnOff(l.entityId, false)) allOk = false;
              }
              return allOk;
            }, emptyMessage: ha.lights.isEmpty
                ? 'לא נמצאו מנורות ב-Home Assistant'
                : null),
          )),
          const SizedBox(width: 10),
          Expanded(child: _QuickBtn(
            icon: Symbols.lightbulb,
            label: 'כל האורות\nהדלק',
            color: _yellow,
            onTap: () => _runHaCommand(context, () async {
              if (ha.lights.isEmpty) return false;
              var allOk = true;
              for (final l in ha.lights) {
                if (!await ha.setOnOff(l.entityId, true)) allOk = false;
              }
              return allOk;
            }, emptyMessage: ha.lights.isEmpty
                ? 'לא נמצאו מנורות ב-Home Assistant'
                : null),
          )),
          const SizedBox(width: 10),
          Expanded(child: _QuickBtn(
            icon: Symbols.blinds,
            label: 'כל התריסים\nסגור',
            color: _blue,
            onTap: () => _runHaCommand(context, () async {
              if (ha.covers.isEmpty) return false;
              var allOk = true;
              for (final c in ha.covers) {
                if (!await ha.setOnOff(c.entityId, false)) allOk = false;
              }
              return allOk;
            }, emptyMessage: ha.covers.isEmpty
                ? 'לא נמצאו תריסים ב-Home Assistant'
                : null),
          )),
          const SizedBox(width: 10),
          Expanded(child: _QuickBtn(
            icon: Symbols.blinds_closed,
            label: 'כל התריסים\nפתח',
            color: _blue,
            onTap: () => _runHaCommand(context, () async {
              if (ha.covers.isEmpty) return false;
              var allOk = true;
              for (final c in ha.covers) {
                if (!await ha.setOnOff(c.entityId, true)) allOk = false;
              }
              return allOk;
            }, emptyMessage: ha.covers.isEmpty
                ? 'לא נמצאו תריסים ב-Home Assistant'
                : null),
          )),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _text2, fontSize: 10, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rooms Row
// ─────────────────────────────────────────────────────────────────────────────
class _RoomsRow extends StatelessWidget {
  final HaProvider ha;
  const _RoomsRow({required this.ha});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: ha.areas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final area    = ha.areas[i];
          final devices = ha.entitiesInArea(area.id);
          final onCount = devices.where((e) => e.isOn).length;
          return Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Symbols.meeting_room, color: _orange, size: 18),
                Text(area.name,
                    style: const TextStyle(color: _text1, fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$onCount פעילים',
                    style: const TextStyle(color: _text2, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entity Row — light / switch (עם טוגל)
// ─────────────────────────────────────────────────────────────────────────────
class _EntityRow extends StatelessWidget {
  final HaEntity entity;
  final HaProvider ha;
  const _EntityRow({required this.entity, required this.ha});

  @override
  Widget build(BuildContext context) {
    final isLight = entity.domain == 'light';
    final color   = isLight ? _yellow : _green;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entity.isOn ? color.withValues(alpha: 0.35) : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: entity.isOn
                  ? color.withValues(alpha: 0.15)
                  : _surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLight ? Symbols.lightbulb : Symbols.power,
              color: entity.isOn ? color : _text2,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entity.friendlyName,
                    style: const TextStyle(color: _text1, fontSize: 14,
                        fontWeight: FontWeight.w500)),
                if (entity.brightness != null)
                  Text('${entity.brightness}% בהירות',
                      style: const TextStyle(color: _text2, fontSize: 11)),
              ],
            ),
          ),
          // Toggle
          GestureDetector(
            onTap: () => _runHaCommand(
                context, () => ha.setOnOff(entity.entityId, !entity.isOn)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 24,
              decoration: BoxDecoration(
                color: entity.isOn ? color : _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: entity.isOn ? color : _border),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: entity.isOn
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 18, height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Climate Row
// ─────────────────────────────────────────────────────────────────────────────
class _ClimateRow extends StatelessWidget {
  final HaEntity entity;
  final HaProvider ha;
  const _ClimateRow({required this.entity, required this.ha});

  @override
  Widget build(BuildContext context) {
    final isOn = entity.isOn;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOn
            ? _blue.withValues(alpha: 0.35) : _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isOn ? _blue.withValues(alpha: 0.15) : _surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Symbols.thermostat,
                color: isOn ? _blue : _text2, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entity.friendlyName,
                    style: const TextStyle(color: _text1, fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Row(children: [
                  if (entity.currentTemperature != null)
                    Text('${entity.currentTemperature}°',
                        style: const TextStyle(color: _text2, fontSize: 12)),
                  if (entity.targetTemperature != null) ...[
                    const Text(' → ',
                        style: TextStyle(color: _text2, fontSize: 12)),
                    Text('${entity.targetTemperature}°',
                        style: const TextStyle(color: _blue, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ]),
              ],
            ),
          ),
          // -/+ temp
          if (entity.targetTemperature != null) ...[
            _TempBtn(icon: Symbols.remove, onTap: () =>
                ha.setClimateTemp(entity.entityId,
                    entity.targetTemperature! - 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${entity.targetTemperature}°',
                  style: const TextStyle(color: _text1, fontWeight: FontWeight.bold)),
            ),
            _TempBtn(icon: Symbols.add, onTap: () =>
                ha.setClimateTemp(entity.entityId,
                    entity.targetTemperature! + 0.5)),
          ],
        ],
      ),
    );
  }
}

class _TempBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TempBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _border)),
      child: Icon(icon, size: 14, color: _text1),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover Row
// ─────────────────────────────────────────────────────────────────────────────
class _CoverRow extends StatelessWidget {
  final HaEntity entity;
  final HaProvider ha;
  const _CoverRow({required this.entity, required this.ha});

  @override
  Widget build(BuildContext context) {
    final pos = entity.coverPosition ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.blinds, color: _blue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(entity.friendlyName,
                    style: const TextStyle(color: _text1, fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              Text('$pos%', style: const TextStyle(color: _text2, fontSize: 13)),
              const SizedBox(width: 10),
              _CoverBtn(icon: Symbols.keyboard_arrow_up,
                  onTap: () => _runHaCommand(
                      context, () => ha.setOnOff(entity.entityId, true))),
              const SizedBox(width: 6),
              _CoverBtn(icon: Symbols.stop,
                  onTap: () => _runHaCommand(
                      context, () => ha.coverStop(entity.entityId))),
              const SizedBox(width: 6),
              _CoverBtn(icon: Symbols.keyboard_arrow_down,
                  onTap: () => _runHaCommand(
                      context, () => ha.setOnOff(entity.entityId, false))),
            ],
          ),
          const SizedBox(height: 10),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: _blue,
              inactiveTrackColor: _border,
              thumbColor: Colors.white,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: pos.toDouble(),
              min: 0, max: 100,
              onChangeEnd: (v) =>
                  ha.setCoverPosition(entity.entityId, v.round()),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CoverBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _border)),
      child: Icon(icon, size: 16, color: _text1),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sensors Grid
// ─────────────────────────────────────────────────────────────────────────────
class _SensorsGrid extends StatelessWidget {
  final List<HaEntity> sensors;
  const _SensorsGrid({required this.sensors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8, mainAxisSpacing: 8,
          childAspectRatio: 1.3,
        ),
        itemCount: sensors.length,
        itemBuilder: (ctx, i) {
          final s = sensors[i];
          final color = _sensorColor(s.deviceClass);
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(_sensorIcon(s.deviceClass), color: color, size: 16),
                Text('${s.state}${s.unit ?? ''}',
                    style: TextStyle(color: color, fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Text(s.friendlyName,
                    style: const TextStyle(color: _text2, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _sensorColor(String? cls) {
    switch (cls) {
      case 'temperature':    return _red;
      case 'humidity':       return _blue;
      case 'motion':
      case 'occupancy':      return _orange;
      case 'door':
      case 'window':
      case 'opening':        return _yellow;
      case 'smoke':
      case 'gas':
      case 'carbon_monoxide':return _red;
      case 'moisture':
      case 'water':          return _blue;
      case 'vibration':      return _orange;
      case 'power':
      case 'energy':         return _green;
      default:               return _text2;
    }
  }

  // Routed through the app-wide icon service so HA screens stay consistent
  // with every other screen (this used to be an independent copy that had
  // silently drifted).
  IconData _sensorIcon(String? cls) => DeviceIcons.forHaDeviceClass(cls);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44, height: 24,
      decoration: BoxDecoration(
        color: value ? color : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? color : _border),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18, height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Lock Row
// ─────────────────────────────────────────────────────────────────────────────

class _LockRow extends StatelessWidget {
  final HaEntity   entity;
  final HaProvider ha;
  const _LockRow({required this.entity, required this.ha});

  @override
  Widget build(BuildContext context) {
    final locked  = entity.isLocked;
    final jammed  = entity.isJammed;
    final transit = entity.isLocking || entity.isUnlocking;
    final color   = jammed   ? _red
                  : transit  ? _yellow
                  : locked   ? _green : _orange;
    final label   = jammed   ? 'תקוע'
                  : transit  ? (entity.isLocking ? 'נועל...' : 'פותח...')
                  : locked   ? 'נעול' : 'פתוח';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              locked ? Symbols.lock : Symbols.lock_open,
              color: color, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entity.friendlyName,
                    style: const TextStyle(color: _text1, fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(label, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
          if (transit)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _yellow),
            )
          else if (!jammed)
            _ActionBtn(
              label:  locked ? 'פתח' : 'נעל',
              color:  locked ? _orange : _green,
              onTap:  () => locked
                  ? ha.lockUnlock(entity.entityId)
                  : ha.lockLock(entity.entityId),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fan Row
// ─────────────────────────────────────────────────────────────────────────────

class _FanRow extends StatelessWidget {
  final HaEntity   entity;
  final HaProvider ha;
  const _FanRow({required this.entity, required this.ha});

  @override
  Widget build(BuildContext context) {
    final isOn  = entity.isOn;
    final pct   = entity.fanPercentage ?? 0;
    final color = isOn ? _blue : _text2;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isOn ? _blue.withValues(alpha: 0.35) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isOn ? _blue.withValues(alpha: 0.15) : _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Symbols.air, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.friendlyName,
                        style: const TextStyle(color: _text1, fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    if (isOn && entity.fanPresetMode != null)
                      Text(entity.fanPresetMode!,
                          style: const TextStyle(color: _text2, fontSize: 11)),
                  ],
                ),
              ),
              if (isOn) ...[
                Text('$pct%',
                    style: TextStyle(color: color, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
              ],
              _Toggle(
                value:     isOn,
                color:     _blue,
                onChanged: (v) => ha.setOnOff(entity.entityId, v),
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor:   _blue,
                inactiveTrackColor: _border,
                thumbColor:         Colors.white,
                overlayShape:       SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value:       pct.toDouble(),
                min: 0, max: 100,
                onChangeEnd: (v) => ha.fanSetPercentage(entity.entityId, v.round()),
                onChanged:   (_) {},
              ),
            ),
            if (entity.fanPresetModes.isNotEmpty)
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection:  Axis.horizontal,
                  itemCount:        entity.fanPresetModes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final mode   = entity.fanPresetModes[i];
                    final active = mode == entity.fanPresetMode;
                    return GestureDetector(
                      onTap: () => ha.fanSetPresetMode(entity.entityId, mode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: active
                              ? _blue.withValues(alpha: 0.2) : _surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: active
                                ? _blue.withValues(alpha: 0.5) : _border),
                        ),
                        child: Text(mode,
                            style: TextStyle(
                              color:      active ? _blue : _text2,
                              fontSize:   11,
                              fontWeight: active
                                  ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Media Player Row
// ─────────────────────────────────────────────────────────────────────────────

class _MediaPlayerRow extends StatefulWidget {
  final HaEntity   entity;
  final HaProvider ha;
  final String     baseUrl;
  const _MediaPlayerRow({
    required this.entity,
    required this.ha,
    required this.baseUrl,
  });

  @override
  State<_MediaPlayerRow> createState() => _MediaPlayerRowState();
}

class _MediaPlayerRowState extends State<_MediaPlayerRow> {
  double? _localVol; // tracks slider drag locally for smooth feedback

  @override
  void didUpdateWidget(_MediaPlayerRow old) {
    super.didUpdateWidget(old);
    // Reset local vol when HA pushes a new state so slider stays in sync
    if (old.entity.volumeLevel != widget.entity.volumeLevel) {
      _localVol = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entity     = widget.entity;
    final ha         = widget.ha;
    final baseUrl    = widget.baseUrl;
    final isPlaying  = entity.state == 'playing';
    final isOff      = entity.state == 'off';
    final vol        = _localVol ?? entity.volumeLevel ?? 0.0;
    final muted      = entity.isVolumeMuted;
    final thumbPath  = entity.mediaThumbnail;
    final thumbUrl   = (thumbPath != null && thumbPath.isNotEmpty && baseUrl.isNotEmpty)
        ? '${baseUrl.replaceAll(RegExp(r'/$'), '')}$thumbPath'
        : null;
    final authHeader = ha.config != null
        ? {'Authorization': 'Bearer ${ha.config!.token}'}
        : const <String, String>{};

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPlaying ? _blue.withValues(alpha: 0.35) : _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44, height: 44,
                  child: thumbUrl != null && isPlaying
                      ? Image.network(
                          thumbUrl, fit: BoxFit.cover, headers: authHeader,
                          errorBuilder: (_, __, ___) => _placeholderIcon(isPlaying),
                        )
                      : _placeholderIcon(isPlaying),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.friendlyName,
                        style: const TextStyle(color: _text1, fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (entity.mediaTitle != null)
                      Text(entity.mediaTitle!,
                          style: const TextStyle(color: _text2, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (entity.mediaArtist != null)
                      Text(entity.mediaArtist!,
                          style: const TextStyle(color: _text2, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (isOff)
                      const Text('כבוי',
                          style: TextStyle(color: _text2, fontSize: 11)),
                  ],
                ),
              ),
              // Mute toggle — 40×40 tap target
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ha.mediaVolumeMute(entity.entityId, mute: !muted),
                child: SizedBox(
                  width: 40, height: 40,
                  child: Icon(
                    muted
                        ? Symbols.volume_off
                        : Symbols.volume_up,
                    color: muted ? _red : _text2, size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (!isOff) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                // Prev
                _MediaBtn(icon: Symbols.skip_previous,
                    onTap: () => ha.mediaPrevTrack(entity.entityId)),
                const SizedBox(width: 12),
                // Play/Pause
                GestureDetector(
                  onTap: () => isPlaying
                      ? ha.mediaPause(entity.entityId)
                      : ha.mediaPlay(entity.entityId),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _blue.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      isPlaying
                          ? Symbols.pause
                          : Symbols.play_arrow,
                      color: _blue, size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Next
                _MediaBtn(icon: Symbols.skip_next,
                    onTap: () => ha.mediaNextTrack(entity.entityId)),
                const Spacer(),
                // Volume slider
                SizedBox(
                  width: 90,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor:   _blue,
                      inactiveTrackColor: _border,
                      thumbColor:         Colors.white,
                      overlayShape:       SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value:       muted ? 0 : vol.clamp(0.0, 1.0),
                      min: 0, max: 1,
                      onChanged:   (v) => setState(() => _localVol = v),
                      onChangeEnd: (v) {
                        ha.mediaVolumeSet(entity.entityId, v);
                        setState(() => _localVol = null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholderIcon(bool playing) => Container(
    color: _surface,
    child: Icon(
      playing ? Symbols.music_note : Symbols.speaker,
      color: _blue, size: 22,
    ),
  );
}

class _MediaBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _MediaBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: 44, height: 44,
      child: Icon(icon, color: _text2, size: 22),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera Thumbnail Row
// ─────────────────────────────────────────────────────────────────────────────

class _CameraThumbRow extends StatelessWidget {
  final List<HaEntity> cameras;
  final String         baseUrl;
  final HaProvider     ha;
  const _CameraThumbRow({
    required this.cameras,
    required this.baseUrl,
    required this.ha,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount:        cameras.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final cam      = cameras[i];
          final picPath  = cam.attributes['entity_picture'] as String?;
          final thumbUrl = (picPath != null && picPath.isNotEmpty && baseUrl.isNotEmpty)
              ? '${baseUrl.replaceAll(RegExp(r'/$'), '')}$picPath'
              : null;
          final headers  = ha.config != null
              ? {'Authorization': 'Bearer ${ha.config!.token}'}
              : const <String, String>{};

          return GestureDetector(
            onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => HaCameraViewerScreen(camera: cam),
            )),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbUrl != null)
                    Image.network(
                      thumbUrl, fit: BoxFit.cover, headers: headers,
                      errorBuilder: (_, __, ___) => const Icon(
                          Symbols.videocam_off,
                          color: _text2, size: 28),
                    )
                  else
                    const Icon(Symbols.videocam,
                        color: _text2, size: 28),
                  // Name overlay
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Text(cam.friendlyName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(children: [
      Icon(icon, color: _orange, size: 16),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
          color: _text1, fontSize: 15, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Connecting / Error View
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    final ha = context.watch<HaProvider>();
    final isConnecting = ha.status == HaStatus.connecting;

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: isConnecting
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: _orange, strokeWidth: 2.5),
                      )
                    : const Icon(Symbols.home, color: _orange, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                isConnecting ? 'מתחבר ל-Home Assistant...' : 'FantaTech',
                style: const TextStyle(color: _text1, fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              if (ha.error != null) ...[
                const SizedBox(height: 12),
                Text(ha.error!, style: const TextStyle(color: _red, fontSize: 14),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

