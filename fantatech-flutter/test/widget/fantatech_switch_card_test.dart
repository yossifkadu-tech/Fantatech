import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fantatech/widgets/fantatech_switch_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 170, height: 190, child: child))),
    );

void main() {
  group('FantaTechSwitchCard', () {
    testWidgets('tapping the circular button calls onToggle with the opposite state',
        (tester) async {
      String? calledId;
      bool? calledDesired;

      await tester.pumpWidget(_wrap(FantaTechSwitchCard(
        deviceId: 'switch_1',
        deviceName: 'תאורה סלון',
        roomName: 'Living Room',
        isOn: false,
        isOnline: true,
        onToggle: (id, desired) async {
          calledId = id;
          calledDesired = desired;
          return true;
        },
      )));

      await tester.tap(find.byIcon(Symbols.power_settings_new));
      await tester.pumpAndSettle();

      expect(calledId, 'switch_1');
      expect(calledDesired, isTrue);
    });

    testWidgets('shows a loading spinner while onToggle is pending, and ignores taps meanwhile',
        (tester) async {
      var callCount = 0;

      await tester.pumpWidget(_wrap(FantaTechSwitchCard(
        deviceId: 'switch_1',
        deviceName: 'Switch',
        roomName: 'Room',
        isOn: false,
        isOnline: true,
        onToggle: (id, desired) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        },
      )));

      await tester.tap(find.byIcon(Symbols.power_settings_new));
      await tester.pump(); // start the async onToggle, do not settle

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Second tap while loading must not call onToggle again.
      await tester.tap(find.byType(CircularProgressIndicator), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });

    testWidgets('offline device shows an offline state and never calls onToggle',
        (tester) async {
      var called = false;

      await tester.pumpWidget(_wrap(FantaTechSwitchCard(
        deviceId: 'switch_1',
        deviceName: 'Switch',
        roomName: 'Room',
        isOn: true,
        isOnline: false,
        onToggle: (id, desired) async {
          called = true;
          return true;
        },
      )));

      expect(find.text('Offline'), findsOneWidget);

      await tester.tap(find.text('Offline'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('shows ON/OFF label reflecting the current isOn value', (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSwitchCard(
        deviceId: 'switch_1',
        deviceName: 'Switch',
        roomName: 'Room',
        isOn: true,
        isOnline: true,
        onToggle: (id, desired) async => true,
      )));

      expect(find.text('ON'), findsOneWidget);
      expect(find.text('OFF'), findsNothing);
    });

    testWidgets('long device names are truncated with ellipsis, not overflowing',
        (tester) async {
      await tester.pumpWidget(_wrap(FantaTechSwitchCard(
        deviceId: 'switch_1',
        deviceName: 'A Very Very Very Long Smart Switch Device Name That Should Not Wrap',
        roomName: 'Room',
        isOn: false,
        isOnline: true,
        onToggle: (id, desired) async => true,
      )));

      final nameText = tester.widget<Text>(find.text(
          'A Very Very Very Long Smart Switch Device Name That Should Not Wrap'));
      expect(nameText.maxLines, 1);
      expect(nameText.overflow, TextOverflow.ellipsis);
      // No overflow render error was thrown during pump — implicit pass.
    });
  });
}
