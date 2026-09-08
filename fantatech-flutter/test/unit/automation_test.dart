import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';

void main() {
  group('Automation JSON round-trip', () {
    test('preserves structured trigger/action fields', () {
      final a = Automation(
        id: 'a1',
        name: 'Evening lights',
        condition: '22:00',
        action: 'Turn on lights',
        isEnabled: true,
        triggerType: 'time',
        triggerHour: 22,
        triggerMinute: 0,
        actionType: 'turnOn',
        actionDeviceId: 'dev1',
      );

      final restored = Automation.fromJson(a.toJson());

      expect(restored.id, 'a1');
      expect(restored.name, 'Evening lights');
      expect(restored.isEnabled, true);
      expect(restored.triggerType, 'time');
      expect(restored.triggerHour, 22);
      expect(restored.triggerMinute, 0);
      expect(restored.actionType, 'turnOn');
      expect(restored.actionDeviceId, 'dev1');
    });

    test('old text-only automation (no structured fields) loads without crashing', () {
      final restored = Automation.fromJson({
        'id': 'legacy1',
        'name': 'Old automation',
        'condition': 'Motion detected',
        'action': 'Turn on lights',
        'is_enabled': true,
      });

      expect(restored.id, 'legacy1');
      expect(restored.triggerType, isNull);
      expect(restored.actionType, isNull);
    });
  });
}
