import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/device_card.dart';
import 'add_device_screen.dart';

class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  String _selectedRoom = 'הכל';

  static const _categories = [
    ('אורות', DeviceType.light, Icons.lightbulb_outline, AppColors.lightColor),
    ('תריסים', DeviceType.blind, Icons.blinds_outlined, AppColors.primary),
    ('מזגנים', DeviceType.airConditioner, Icons.hvac, AppColors.acColor),
    ('שקעים', DeviceType.smartPlug, Icons.power_outlined, AppColors.plugColor),
    ('מפסקים', DeviceType.smartSwitch, Icons.toggle_on_outlined, AppColors.plugColor),
    ('חיישנים', DeviceType.motionSensor, Icons.sensors_outlined, AppColors.motionColor),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    final rooms = ['הכל', ...{...state.devices.map((d) => d.room)}];
    final filtered = _selectedRoom == 'הכל'
        ? state.devices
        : state.devices.where((d) => d.room == _selectedRoom).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'בית חכם',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          color: AppColors.primary,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddDeviceScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category chips
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final (label, type, icon, color) = _categories[i];
                          final count = state.devices
                              .where((d) =>
                                  d.type == type ||
                                  (type == DeviceType.motionSensor &&
                                      (d.type == DeviceType.doorSensor ||
                                          d.type == DeviceType.windowSensor)))
                              .length;
                          return _CategoryChip(
                            label: label,
                            icon: icon,
                            color: color,
                            count: count,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Room filter
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: rooms.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final room = rooms[i];
                          final selected = _selectedRoom == room;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedRoom = room),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : theme.colorScheme.outline,
                                ),
                              ),
                              child: Text(
                                room,
                                style: TextStyle(
                                  color: selected ? context.tText : null,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '${filtered.length} מכשירים',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => DeviceCard(
                    device: filtered[i],
                    onToggle: () => state.toggleDevice(filtered[i].id),
                    onTap: () => _showDeviceDetail(context, filtered[i], state),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _showDeviceDetail(BuildContext context, Device device, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DeviceDetailSheet(device: device, state: state),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _DeviceDetailSheet extends StatefulWidget {
  final Device device;
  final AppState state;

  const _DeviceDetailSheet({required this.device, required this.state});

  @override
  State<_DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends State<_DeviceDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.device;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                d.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: d.isOn,
                onChanged: (v) {
                  widget.state.toggleDevice(d.id);
                  setState(() {});
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          Text(
            d.room,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),

          // AC controls
          if (d.type == DeviceType.airConditioner) ...[
            Text('טמפרטורה: ${d.attributes['temperature']}°C',
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (d.attributes['temperature'] as int).toDouble(),
              min: 16,
              max: 30,
              divisions: 14,
              label: '${d.attributes['temperature']}°C',
              activeColor: AppColors.acColor,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'temperature', v.toInt());
                setState(() {});
              },
            ),
          ],

          // Light controls
          if (d.type == DeviceType.light) ...[
            Text('עוצמה: ${d.attributes['brightness']}%',
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (d.attributes['brightness'] as int? ?? 80).toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: '${d.attributes['brightness']}%',
              activeColor: AppColors.lightColor,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'brightness', v.toInt());
                setState(() {});
              },
            ),
          ],

          // Blind controls
          if (d.type == DeviceType.blind) ...[
            Text('מיקום: ${d.attributes['position']}%',
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (d.attributes['position'] as int? ?? 50).toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: '${d.attributes['position']}%',
              activeColor: AppColors.primary,
              onChanged: (v) {
                widget.state.setDeviceAttribute(d.id, 'position', v.toInt());
                setState(() {});
              },
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
