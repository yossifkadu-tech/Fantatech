import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:fantatech/models/app_state.dart';
import 'package:fantatech/l10n/strings.dart';
import 'package:fantatech/screens/ha/ha_cameras_screen.dart';
import 'package:fantatech/services/ha/ha_provider.dart';

import '../helpers/fake_ha_provider.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAppState extends Mock implements AppState {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _harness(FakeHaProvider haProvider, AppState appState) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HaProvider>.value(value: haProvider),
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: const MaterialApp(
        home: Scaffold(body: HaCamerasScreen()),
      ),
    );

MockAppState _mockAppState() {
  final m = MockAppState();
  when(() => m.strings).thenReturn(S.of(AppLocale.hebrew));
  return m;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('HaCamerasScreen', () {
    testWidgets('empty state: shows camera-off icon and Hebrew message',
        (tester) async {
      await tester.pumpWidget(
        _harness(FakeHaProvider(), _mockAppState()),
      );

      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      expect(
        find.text('אין מצלמות מחוברות ב-Home Assistant'),
        findsOneWidget,
      );
    });

    testWidgets('grid view renders one card per camera',
        (tester) async {
      final provider = FakeHaProvider(cameras: [
        fakeCamera(id: 'camera.front', name: 'Front Door'),
        fakeCamera(id: 'camera.back',  name: 'Back Yard'),
      ]);

      await tester.pumpWidget(_harness(provider, _mockAppState()));

      // Each card shows the friendly name
      expect(find.text('Front Door'), findsOneWidget);
      expect(find.text('Back Yard'),  findsOneWidget);
    });

    testWidgets('single camera: shows one card, no "empty" text',
        (tester) async {
      final provider = FakeHaProvider(cameras: [
        fakeCamera(name: 'Entrance'),
      ]);

      await tester.pumpWidget(_harness(provider, _mockAppState()));

      expect(find.text('Entrance'), findsOneWidget);
      expect(
        find.text('אין מצלמות מחוברות ב-Home Assistant'),
        findsNothing,
      );
    });
  });
}
