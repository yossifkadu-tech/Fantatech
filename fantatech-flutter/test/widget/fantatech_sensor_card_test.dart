import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/fantatech_sensor_data.dart';
import 'package:fantatech/widgets/fantatech_sensor_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 170, height: 200, child: child))),
    );

FantaTechSensorData _sensor({
  required FantaTechSensorType type,
  required String state,
  String name = 'חיישן',
  String room = 'Room',
  bool online = true,
  num? value,
  String unit = '',
  DateTime? lastUpdated,
}) =>
    FantaTechSensorData(
      sensorId: 's1',
      sensorType: type,
      sensorName: name,
      roomName: room,
      state: state,
      isOnline: online,
      value: value,
      unit: unit,
      lastUpdated: lastUpdated,
    );

void main() {
  group('FantaTechSensorCard — per-type labels', () {
    testWidgets('motion: clear shows "אין תנועה", detected shows "תנועה זוהתה"',
        (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.motion, state: 'clear'))));
      expect(find.text('אין תנועה'), findsOneWidget);

      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.motion, state: 'motion_detected'))));
      await tester.pump();
      expect(find.text('תנועה זוהתה'), findsOneWidget);
    });

    testWidgets('gas: normal/warning/gas_detected map to the three required labels',
        (tester) async {
      for (final entry in {
        'normal': 'תקין',
        'warning': 'אזהרה',
        'gas_detected': 'זוהה גז',
      }.entries) {
        await tester.pumpWidget(_wrap(
            FantaTechSensorCard(data: _sensor(type: FantaTechSensorType.gas, state: entry.key))));
        await tester.pump();
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('window: closed/open', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.window, state: 'closed'))));
      expect(find.text('סגור'), findsOneWidget);

      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.window, state: 'open'))));
      await tester.pump();
      expect(find.text('פתוח'), findsOneWidget);
    });

    testWidgets('water leak: dry/leak_detected', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.waterLeak, state: 'dry'))));
      expect(find.text('יבש'), findsOneWidget);

      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.waterLeak, state: 'leak_detected'))));
      await tester.pump();
      expect(find.text('נזילה זוהתה'), findsOneWidget);
    });

    testWidgets('tamper: normal/tamper_detected', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.tamper, state: 'tamper_detected'))));
      await tester.pump();
      expect(find.text('מניפולציה זוהתה'), findsOneWidget);
    });

    testWidgets('mail: no_mail/mail_present', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.mail, state: 'mail_present'))));
      await tester.pump();
      expect(find.text('יש דואר'), findsOneWidget);
    });
  });

  group('FantaTechSensorCard — CO2 numeric display', () {
    testWidgets('shows value and ppm unit inside the circle', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(
              type: FantaTechSensorType.co2, state: 'normal', value: 742, unit: 'ppm'))));

      expect(find.text('742'), findsOneWidget);
      expect(find.text('ppm'), findsOneWidget);
    });
  });

  group('FantaTechSensorCard — offline', () {
    testWidgets('shows "לא מחובר" and last-updated hint, never the stale state label',
        (tester) async {
      final tenMinAgo = DateTime.now().subtract(const Duration(minutes: 10));
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(
              type: FantaTechSensorType.motion,
              state: 'motion_detected',
              online: false,
              lastUpdated: tenMinAgo))));

      expect(find.text('לא מחובר'), findsOneWidget);
      expect(find.text('תנועה זוהתה'), findsNothing);
      expect(find.textContaining('עדכון אחרון'), findsOneWidget);
    });
  });

  group('FantaTechSensorCard — interaction', () {
    testWidgets('tap calls onTap, long-press calls onLongPress', (tester) async {
      var tapped = false;
      var longPressed = false;

      await tester.pumpWidget(_wrap(FantaTechSensorCard(
        data: _sensor(type: FantaTechSensorType.motion, state: 'clear'),
        onTap: () => tapped = true,
        onLongPress: () => longPressed = true,
      )));

      await tester.tap(find.byType(FantaTechSensorCard));
      expect(tapped, isTrue);

      await tester.longPress(find.byType(FantaTechSensorCard));
      expect(longPressed, isTrue);
    });
  });

  group('FantaTechSensorCard — unconfigured future type', () {
    testWidgets('falls back to generic config instead of crashing', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSensorCard(
          data: _sensor(type: FantaTechSensorType.temperature, state: 'normal'))));
      expect(find.text('תקין'), findsOneWidget);
    });
  });
}
