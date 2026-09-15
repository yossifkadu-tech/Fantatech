import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_theme.dart';
import '../../widgets/fantatech_switch_card.dart';
import '../../models/fantatech_sensor_data.dart';
import '../../widgets/fantatech_sensor_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FantaTechSwitchCardDemoScreen — temporary preview screen for testing
// FantaTechSwitchCard on a real device before it's wired into a real
// dashboard. Entry point is a single "בדיקה" item in Profile's more-options
// sheet (see profile_screen.dart) — safe to delete both once testing is
// done, neither touches any existing feature.
// ─────────────────────────────────────────────────────────────────────────────

class FantaTechSwitchCardDemoScreen extends StatefulWidget {
  const FantaTechSwitchCardDemoScreen({super.key});

  @override
  State<FantaTechSwitchCardDemoScreen> createState() =>
      _FantaTechSwitchCardDemoScreenState();
}

class _FantaTechSwitchCardDemoScreenState
    extends State<FantaTechSwitchCardDemoScreen> {
  final Map<String, bool> _states = {
    's1': true,
    's2': false,
    's3': true,
    's4': false,
  };

  Future<bool> _fakeToggle(String id, bool desired) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _states[id] = desired);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      appBar: AppBar(
        backgroundColor: context.tBg,
        elevation: 0,
        title: Text('FantaTechSwitchCard — בדיקה',
            style: TextStyle(color: context.tText, fontSize: 16)),
        iconTheme: IconThemeData(color: context.tText),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionTitle('FantaTechSwitchCard', context),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 170 / 185,
              children: [
                FantaTechSwitchCard(
                  deviceId: 's1',
                  deviceName: 'תאורה סלון',
                  roomName: 'Living Room',
                  isOn: _states['s1']!,
                  isOnline: true,
                  onToggle: _fakeToggle,
                ),
                FantaTechSwitchCard(
                  deviceId: 's2',
                  deviceName: 'מתג מטבח',
                  roomName: 'Kitchen',
                  isOn: _states['s2']!,
                  isOnline: true,
                  onToggle: _fakeToggle,
                ),
                FantaTechSwitchCard(
                  deviceId: 's3',
                  deviceName: 'שקע חכם — מכשיר עם שם ארוך מאוד לבדיקת גלישה',
                  roomName: 'Bedroom',
                  isOn: _states['s3']!,
                  isOnline: true,
                  onToggle: _fakeToggle,
                ),
                FantaTechSwitchCard(
                  deviceId: 's4',
                  deviceName: 'מתג לא מחובר',
                  roomName: 'Garage',
                  isOn: _states['s4']!,
                  isOnline: false,
                  onToggle: _fakeToggle,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle('FantaTechSensorCard', context),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 170 / 185,
              children: [
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen1',
                    sensorType: FantaTechSensorType.motion,
                    sensorName: 'חיישן תנועה',
                    roomName: 'Hallway',
                    state: 'clear',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen2',
                    sensorType: FantaTechSensorType.motion,
                    sensorName: 'תנועה — מטבח',
                    roomName: 'Kitchen',
                    state: 'motion_detected',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen3',
                    sensorType: FantaTechSensorType.gas,
                    sensorName: 'גלאי גז',
                    roomName: 'Kitchen',
                    state: 'gas_detected',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen4',
                    sensorType: FantaTechSensorType.gas,
                    sensorName: 'גלאי גז 2',
                    roomName: 'Garage',
                    state: 'warning',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen5',
                    sensorType: FantaTechSensorType.window,
                    sensorName: 'חלון סלון',
                    roomName: 'Living Room',
                    state: 'open',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen6',
                    sensorType: FantaTechSensorType.waterLeak,
                    sensorName: 'נזילה מטבח',
                    roomName: 'Kitchen',
                    state: 'leak_detected',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: FantaTechSensorData(
                    sensorId: 'sen7',
                    sensorType: FantaTechSensorType.co2,
                    sensorName: 'CO2 סלון',
                    roomName: 'Living Room',
                    state: const Co2Thresholds().resolveState(742),
                    value: 742,
                    unit: 'ppm',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen8',
                    sensorType: FantaTechSensorType.tamper,
                    sensorName: 'חיישן מניפולציה',
                    roomName: 'Panel',
                    state: 'tamper_detected',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: const FantaTechSensorData(
                    sensorId: 'sen9',
                    sensorType: FantaTechSensorType.mail,
                    sensorName: 'תיבת דואר',
                    roomName: 'Entrance',
                    state: 'mail_present',
                  ),
                  onTap: () {},
                ),
                FantaTechSensorCard(
                  data: FantaTechSensorData(
                    sensorId: 'sen10',
                    sensorType: FantaTechSensorType.motion,
                    sensorName: 'חיישן לא מחובר',
                    roomName: 'Basement',
                    state: 'clear',
                    isOnline: false,
                    lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final BuildContext ctx;
  const _SectionTitle(this.text, this.ctx);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(text,
          style: TextStyle(
              color: ctx.tText, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

/// Icon/color used by the Profile entry that opens this screen.
const kDevSwitchCardDemoIcon = Symbols.science;
const kDevSwitchCardDemoColor = AppColors.primary;
