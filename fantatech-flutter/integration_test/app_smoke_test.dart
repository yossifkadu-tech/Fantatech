import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fantatech/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke test', () {
    testWidgets('app launches and reaches initial screen without crashing',
        (tester) async {
      // Provide empty prefs so no previous HA credentials are loaded —
      // this ensures the app starts in a clean state without trying to
      // connect to a real Home Assistant instance.
      SharedPreferences.setMockInitialValues({});

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The app should render at least one widget without throwing.
      // We don't assert on specific text since the splash / login / home
      // screen depends on auth state — we just verify no crash.
      expect(tester.takeException(), isNull);
    });
  });
}
