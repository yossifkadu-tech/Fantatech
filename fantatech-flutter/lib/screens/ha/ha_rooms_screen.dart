import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ha/ha_provider.dart';
import '../../services/ha/ha_entity.dart';
import '../../services/ha/ha_service.dart';

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _card    = Color(0xFF21262D);
const _border  = Color(0xFF30363D);
const _orange  = Color(0xFFFF6B00);
const _green   = Color(0xFF3FB950);
const _yellow  = Color(0xFFD29922);
const _blue    = Color(0xFF58A6FF);
const _text1   = Color(0xFFE6EDF3);
const _text2   = Color(0xFF8B949E);

class HaRoomsScreen extends StatelessWidget {
  const HaRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ha = context.watch<HaProvider>();

    if (ha.areas.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text('אין חדרים מוגדרים ב-Home Assistant',
              style: TextStyle(color: _text2)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ha.areas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final area     = ha.areas[i];
          final entities = ha.entitiesInArea(area.id);
          final lights   = entities.where((e) => e.domain == 'light').toList();
          final switches = entities.where((e) => e.domain == 'switch').toList();
          final sensors  = entities.where((e) =>
              e.domain == 'sensor' || e.domain == 'binary_sensor').toList();
          final onCount  = entities.where((e) => e.isOn).length;

          return _RoomCard(
            area: area,
            lights: lights,
            switches: switches,
            sensors: sensors,
            onCount: onCount,
            ha: ha,
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatefulWidget {
  final HaArea area;
  final List<HaEntity> lights;
  final List<HaEntity> switches;
  final List<HaEntity> sensors;
  final int onCount;
  final HaProvider ha;

  const _RoomCard({
    required this.area,
    required this.lights,
    required this.switches,
    required this.sensors,
    required this.onCount,
    required this.ha,
  });

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.lights.length + widget.switches.length + widget.sensors.length;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.onCount > 0
              ? _orange.withValues(alpha: 0.35)
              : _border,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Symbols.meeting_room, color: _orange, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.area.name,
                            style: const TextStyle(color: _text1,
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('$total ישויות | ${widget.onCount} פעילות',
                            style: const TextStyle(color: _text2, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Light count badge
                  if (widget.lights.isNotEmpty)
                    _Badge(
                      icon: Symbols.lightbulb,
                      count: widget.lights.where((e) => e.isOn).length,
                      total: widget.lights.length,
                      color: _yellow,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Symbols.expand_less : Symbols.expand_more,
                    color: _text2, size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expandable devices
          if (_expanded) ...[
            const Divider(color: _border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...widget.lights.map((e) => _MiniToggle(entity: e, ha: widget.ha)),
                  ...widget.switches.map((e) => _MiniToggle(entity: e, ha: widget.ha)),
                  ...widget.sensors.map((e) => _SensorChip(entity: e)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final int count, total;
  final Color color;
  const _Badge({required this.icon, required this.count,
      required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text('$count/$total',
            style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final HaEntity entity;
  final HaProvider ha;
  const _MiniToggle({required this.entity, required this.ha});

  @override
  Widget build(BuildContext context) {
    final isLight = entity.domain == 'light';
    final color   = isLight ? _yellow : _green;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isLight ? Symbols.lightbulb : Symbols.power,
              color: entity.isOn ? color : _text2, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(entity.friendlyName,
              style: const TextStyle(color: _text1, fontSize: 13))),
          GestureDetector(
            onTap: () => ha.setOnOff(entity.entityId, !entity.isOn),
            child: Container(
              width: 36, height: 20,
              decoration: BoxDecoration(
                color: entity.isOn ? color : _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: entity.isOn ? color : _border),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: entity.isOn
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 14, height: 14,
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

class _SensorChip extends StatelessWidget {
  final HaEntity entity;
  const _SensorChip({required this.entity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Symbols.sensors, color: _blue, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(entity.friendlyName,
              style: const TextStyle(color: _text1, fontSize: 13))),
          Text('${entity.state}${entity.unit ?? ''}',
              style: const TextStyle(color: _blue, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
