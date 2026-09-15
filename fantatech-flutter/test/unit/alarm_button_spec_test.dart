import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/app_state.dart';
import 'package:fantatech/models/alarm_button_spec.dart';

void main() {
  group('AlarmButtonSpec.forAction', () {
    test('arm targets armedAway', () {
      final spec = AlarmButtonSpec.forAction(AlarmAction.arm, SecurityMode.disarmed);
      expect(spec.targetMode, SecurityMode.armedAway);
      expect(spec.requiresConfirmation, isFalse);
    });

    test('home targets armedHome', () {
      final spec = AlarmButtonSpec.forAction(AlarmAction.home, SecurityMode.disarmed);
      expect(spec.targetMode, SecurityMode.armedHome);
    });

    test('away targets armedAway', () {
      final spec = AlarmButtonSpec.forAction(AlarmAction.away, SecurityMode.disarmed);
      expect(spec.targetMode, SecurityMode.armedAway);
    });

    test('night targets the newly-added armedNight state', () {
      final spec = AlarmButtonSpec.forAction(AlarmAction.night, SecurityMode.disarmed);
      expect(spec.targetMode, SecurityMode.armedNight);
    });

    test('disarm targets disarmed and requires confirmation', () {
      final spec = AlarmButtonSpec.forAction(AlarmAction.disarm, SecurityMode.armedAway);
      expect(spec.targetMode, SecurityMode.disarmed);
      expect(spec.requiresConfirmation, isTrue);
    });

    test('only disarm requires confirmation among the four actions', () {
      for (final a in [AlarmAction.arm, AlarmAction.home, AlarmAction.away, AlarmAction.night]) {
        expect(AlarmButtonSpec.forAction(a, SecurityMode.disarmed).requiresConfirmation, isFalse,
            reason: '$a should not require confirmation');
      }
    });
  });

  group('SecurityMode — added states', () {
    test('armedNight and triggered are both armed (not disarmed/guest)', () {
      expect(SecurityMode.armedNight.isArmed, isTrue);
      expect(SecurityMode.triggered.isArmed, isTrue);
    });

    test('label covers every value including the two newly added ones', () {
      expect(SecurityMode.armedNight.label, 'Armed Night');
      expect(SecurityMode.triggered.label, 'Triggered');
    });
  });
}
