import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ha/ha_provider.dart';
import '../../services/ha/ha_entity.dart';

const _bg     = Color(0xFF0D1117);
const _card   = Color(0xFF21262D);
const _border = Color(0xFF30363D);
const _orange = Color(0xFFFF6B00);
const _green  = Color(0xFF3FB950);
const _red    = Color(0xFFF85149);
const _yellow = Color(0xFFD29922);
const _text1  = Color(0xFFE6EDF3);
const _text2  = Color(0xFF8B949E);

class HaSecurityScreen extends StatelessWidget {
  const HaSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ha = context.watch<HaProvider>();
    final alarms  = ha.alarms;
    final sensors = [...ha.binarySensors, ...ha.sensors]
        .where((e) =>
            e.deviceClass == 'door'             ||
            e.deviceClass == 'window'           ||
            e.deviceClass == 'opening'          ||
            e.deviceClass == 'motion'           ||
            e.deviceClass == 'occupancy'        ||
            e.deviceClass == 'smoke'            ||
            e.deviceClass == 'gas'              ||
            e.deviceClass == 'moisture'         ||
            e.deviceClass == 'water'            ||
            e.deviceClass == 'carbon_monoxide'  ||
            e.deviceClass == 'vibration')
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Alarm Panels ─────────────────────────────────────────
          if (alarms.isNotEmpty) ...[
            _SectionTitle('לוחות אזעקה', Symbols.security),
            const SizedBox(height: 8),
            ...alarms.map((a) => _AlarmPanel(alarm: a, ha: ha)),
            const SizedBox(height: 16),
          ],

          // ── Sensors ───────────────────────────────────────────────
          if (sensors.isNotEmpty) ...[
            _SectionTitle('חיישני אבטחה', Symbols.sensors),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: sensors.length,
              itemBuilder: (ctx, i) => _SecuritySensorCard(sensor: sensors[i]),
            ),
          ],

          if (alarms.isEmpty && sensors.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text('אין מכשירי אבטחה מחוברים',
                    style: TextStyle(color: _text2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlarmPanel extends StatelessWidget {
  final HaEntity alarm;
  final HaProvider ha;
  const _AlarmPanel({required this.alarm, required this.ha});

  @override
  Widget build(BuildContext context) {
    final state  = alarm.alarmState;
    final armed  = alarm.isAlarmArmed;
    final triggered = state == 'triggered';
    final color  = triggered ? _red : armed ? _yellow : _green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(triggered
                  ? Symbols.warning_amber
                  : armed ? Symbols.lock : Symbols.lock_open,
                  color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(alarm.friendlyName,
                    style: const TextStyle(color: _text1, fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_label(state),
                    style: TextStyle(color: color, fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              if (!armed) ...[
                _ArmBtn('בבית', Symbols.home, _green,
                    () => ha.armAlarm(alarm.entityId, mode: 'home')),
                const SizedBox(width: 8),
                _ArmBtn('עזיבה', Symbols.directions_walk, _yellow,
                    () => ha.armAlarm(alarm.entityId, mode: 'away')),
                const SizedBox(width: 8),
                _ArmBtn('לילה', Symbols.nightlight, _orange,
                    () => ha.armAlarm(alarm.entityId, mode: 'night')),
              ] else
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red.withValues(alpha: 0.15),
                      foregroundColor: _red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: _red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Symbols.lock_open, size: 18),
                    label: const Text('כבה אזעקה',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => ha.disarmAlarm(alarm.entityId),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(String state) {
    switch (state) {
      case 'armed_away':  return 'עזיבה';
      case 'armed_home':  return 'בבית';
      case 'armed_night': return 'לילה';
      case 'disarmed':    return 'כבוי';
      case 'triggered':   return '⚠️ פעיל!';
      case 'pending':     return 'ממתין...';
      default:            return state;
    }
  }
}

class _ArmBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ArmBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _SecuritySensorCard extends StatelessWidget {
  final HaEntity sensor;
  const _SecuritySensorCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final triggered = sensor.state == 'on' || sensor.state == 'true';
    final color = triggered ? _red : _green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: triggered ? _red.withValues(alpha: 0.4) : _border),
      ),
      child: Row(
        children: [
          Icon(_sensorIcon(sensor.deviceClass), color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sensor.friendlyName,
                    style: const TextStyle(color: _text1, fontSize: 12,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(triggered ? 'פעיל' : 'רגיל',
                    style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }

  IconData _sensorIcon(String? cls) {
    switch (cls) {
      case 'door':
      case 'opening':         return Symbols.sensor_door;
      case 'window':          return Symbols.window;
      case 'motion':
      case 'occupancy':       return Symbols.sensors;
      case 'smoke':           return Symbols.local_fire_department;
      case 'moisture':
      case 'water':           return Symbols.water_damage;
      case 'gas':
      case 'carbon_monoxide': return Symbols.gas_meter;
      case 'vibration':       return Symbols.vibration;
      default:                return Symbols.security;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: _orange, size: 16),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: _text1, fontSize: 15,
        fontWeight: FontWeight.w700)),
  ]);
}
