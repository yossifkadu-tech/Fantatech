import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fantatech/screens/ha/ha_automations_screen.dart';
import 'package:fantatech/services/ha/ha_provider.dart';

import '../helpers/fake_ha_provider.dart';

// ── Test harness ──────────────────────────────────────────────────────────────

Widget _harness(FakeHaProvider provider) => ChangeNotifierProvider<HaProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(body: HaAutomationsScreen()),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('HaAutomationsScreen', () {
    // ── Empty state ──────────────────────────────────────────────────────────

    testWidgets('empty-connected: shows empty icon and Hebrew message',
        (tester) async {
      await tester.pumpWidget(_harness(FakeHaProvider()));

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.text('אין אוטומציות ב-Home Assistant'), findsOneWidget);
    });

    testWidgets('empty-disconnected: shows wifi-off icon',
        (tester) async {
      await tester.pumpWidget(
        _harness(FakeHaProvider(connected: false)),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('לא מחובר ל-Home Assistant'), findsOneWidget);
    });

    // ── List rendering ───────────────────────────────────────────────────────

    testWidgets('renders friendly names when list has entries',
        (tester) async {
      final provider = FakeHaProvider(automations: [
        fakeAutomation(id: 'automation.lights', name: 'Turn on lights', state: 'on'),
        fakeAutomation(id: 'automation.lock',   name: 'Lock doors',      state: 'off'),
      ]);

      await tester.pumpWidget(_harness(provider));

      expect(find.text('Turn on lights'), findsOneWidget);
      expect(find.text('Lock doors'),     findsOneWidget);
    });

    testWidgets('shows summary chips when list is non-empty',
        (tester) async {
      final provider = FakeHaProvider(automations: [
        fakeAutomation(state: 'on'),
        fakeAutomation(id: 'automation.b', name: 'B', state: 'off'),
      ]);

      await tester.pumpWidget(_harness(provider));

      // "1 פעילות" + "1 מושבתות"
      expect(find.text('1 פעילות'),   findsOneWidget);
      expect(find.text('1 מושבתות'), findsOneWidget);
    });

    // ── ON / OFF button states ────────────────────────────────────────────────

    testWidgets('ON automation: הפעלה button is active (dimmed onTap), כיבוי enabled',
        (tester) async {
      final provider = FakeHaProvider(automations: [
        fakeAutomation(state: 'on'),
      ]);
      await tester.pumpWidget(_harness(provider));

      // Both buttons render
      expect(find.text('הפעלה'), findsOneWidget);
      expect(find.text('כיבוי'), findsOneWidget);
    });

    testWidgets('trigger button (▶) exists for each automation row',
        (tester) async {
      final provider = FakeHaProvider(automations: [
        fakeAutomation(),
        fakeAutomation(id: 'automation.b', name: 'B'),
      ]);
      await tester.pumpWidget(_harness(provider));

      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(2));
    });

    // ── Search ───────────────────────────────────────────────────────────────

    testWidgets('search filters visible rows by name',
        (tester) async {
      final provider = FakeHaProvider(automations: [
        fakeAutomation(id: 'automation.lights', name: 'Lights On', state: 'on'),
        fakeAutomation(id: 'automation.lock',   name: 'Lock Doors', state: 'off'),
      ]);
      await tester.pumpWidget(_harness(provider));

      // Type into the search field
      await tester.enterText(find.byType(TextField), 'lights');
      await tester.pump();

      expect(find.text('Lights On'),  findsOneWidget);
      expect(find.text('Lock Doors'), findsNothing);
    });

    testWidgets('"אין תוצאות" shown when filter matches nothing',
        (tester) async {
      final provider = FakeHaProvider(automations: [
        fakeAutomation(name: 'Lights On'),
      ]);
      await tester.pumpWidget(_harness(provider));

      await tester.enterText(find.byType(TextField), 'zzznomatch');
      await tester.pump();

      expect(find.text('אין תוצאות'), findsOneWidget);
    });
  });
}
