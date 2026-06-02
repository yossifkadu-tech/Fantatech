import 'package:flutter/material.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onToggle,
    this.onTap,
  });

  IconData get _icon {
    switch (device.type) {
      case DeviceType.light:
        return Icons.lightbulb_outline;
      case DeviceType.blind:
        return Icons.blinds_outlined;
      case DeviceType.airConditioner:
        return Icons.hvac;
      case DeviceType.smartPlug:
        return Icons.power_outlined;
      case DeviceType.smartSwitch:
        return Icons.toggle_on_outlined;
      case DeviceType.motionSensor:
        return Icons.sensors_outlined;
      case DeviceType.doorSensor:
        return Icons.sensor_door_outlined;
      case DeviceType.windowSensor:
        return Icons.window_outlined;
      case DeviceType.waterHeater:
        return Icons.water_drop_outlined;
      case DeviceType.camera:
        return Icons.videocam_outlined;
      case DeviceType.router:
        return Icons.router_outlined;
      case DeviceType.gateway:
        return Icons.hub_outlined;
      case DeviceType.circuitBreaker:
        return Icons.electrical_services;
      case DeviceType.solar:
        return Icons.wb_sunny_outlined;
      case DeviceType.smokeSensor:
        return Icons.local_fire_department_outlined;
      case DeviceType.energyMeter:
        return Icons.bolt_outlined;
      case DeviceType.smartLock:
        return Icons.lock_outline;
      case DeviceType.gasSensor:
        return Icons.cloud_outlined;
      case DeviceType.waterLeakSensor:
        return Icons.water_damage_outlined;
      case DeviceType.matterDevice:
        return Icons.hexagon_outlined;
    }
  }

  Color get _accentColor {
    switch (device.type) {
      case DeviceType.light:
        return AppColors.lightColor;
      case DeviceType.airConditioner:
        return AppColors.acColor;
      case DeviceType.smartPlug:
      case DeviceType.smartSwitch:
        return AppColors.plugColor;
      case DeviceType.motionSensor:
        return AppColors.motionColor;
      case DeviceType.doorSensor:
      case DeviceType.windowSensor:
        return AppColors.doorColor;
      case DeviceType.camera:
        return AppColors.cameraColor;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline = device.status == DeviceStatus.offline;
    final color = isOffline ? Colors.grey : _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: device.isOn && !isOffline
                ? color.withOpacity(0.4)
                : theme.colorScheme.outline,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: device.isOn && !isOffline
                        ? color.withOpacity(0.15)
                        : theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _icon,
                    color: device.isOn && !isOffline ? color : Colors.grey,
                    size: 20,
                  ),
                ),
                Switch(
                  value: device.isOn && !isOffline,
                  onChanged: isOffline ? null : (_) => onToggle(),
                  activeColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const Spacer(),
            Text(
              device.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOffline ? Colors.grey : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOffline ? Colors.red : AppColors.secured,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOffline ? 'לא מחובר' : (device.isOn ? 'פועל' : 'כבוי'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOffline ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
