import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/services/push/ha_push_rule.dart';

void main() {
  group('HaPushRule.matches', () {
    test('matches exact entity_id with no triggerState', () {
      final rule = HaPushRule(
        id: 'r1', name: 'test',
        entityPattern: 'lock.front_door',
        titleTemplate: 'T', bodyTemplate: 'B',
      );
      expect(rule.matches('lock.front_door', 'unlocked'), isTrue);
      expect(rule.matches('lock.front_door', 'locked'),   isTrue);
      expect(rule.matches('lock.back_door',  'unlocked'), isFalse);
    });

    test('matches prefix (domain wildcard)', () {
      final rule = HaPushRule(
        id: 'r2', name: 'test',
        entityPattern: 'alarm_control_panel.',
        titleTemplate: 'T', bodyTemplate: 'B',
      );
      expect(rule.matches('alarm_control_panel.home',    'triggered'), isTrue);
      expect(rule.matches('alarm_control_panel.garage',  'triggered'), isTrue);
      expect(rule.matches('binary_sensor.smoke_kitchen', 'on'),        isFalse);
    });

    test('respects triggerState filter', () {
      final rule = HaPushRule(
        id: 'r3', name: 'test',
        entityPattern:  'lock.',
        triggerState:   'unlocked',
        titleTemplate:  'T', bodyTemplate: 'B',
      );
      expect(rule.matches('lock.front', 'unlocked'), isTrue);
      expect(rule.matches('lock.front', 'locked'),   isFalse);
      expect(rule.matches('lock.front', 'jammed'),   isFalse);
    });

    test('disabled rule still returns true from matches (enable check is caller responsibility)', () {
      final rule = HaPushRule(
        id: 'r4', name: 'test',
        entityPattern: 'binary_sensor.',
        enabled: false,
        titleTemplate: 'T', bodyTemplate: 'B',
      );
      // matches() doesn't check enabled — the service loop does
      expect(rule.matches('binary_sensor.motion_hall', 'on'), isTrue);
    });
  });

  group('HaPushRule template resolution', () {
    final rule = HaPushRule(
      id:            'tpl',
      name:          'Template test',
      entityPattern: 'lock.',
      titleTemplate: '🔓 {{friendly_name}} נפתח',
      bodyTemplate:  'ישות: {{entity_id}}, מצב: {{state}}',
    );

    test('resolveTitle replaces {{friendly_name}} and {{entity_id}}', () {
      expect(
        rule.resolveTitle('דלת כניסה', 'lock.front_door'),
        '🔓 דלת כניסה נפתח',
      );
    });

    test('resolveBody replaces all tokens', () {
      expect(
        rule.resolveBody('דלת כניסה', 'lock.front_door', 'unlocked'),
        'ישות: lock.front_door, מצב: פתוח',
      );
    });

    test('state localisation covers on/off/open/closed/locked/unlocked/triggered', () {
      final states = {
        'on':         'פעיל',
        'off':        'כבוי',
        'open':       'פתוח',
        'closed':     'סגור',
        'locked':     'נעול',
        'unlocked':   'פתוח',
        'triggered':  'הופעל!',
        'armed_away': 'מזויין (חוץ)',
        'disarmed':   'כובה',
        'unknown':    'unknown',  // pass-through
      };
      for (final entry in states.entries) {
        expect(
          rule.resolveBody('X', 'e', entry.key),
          contains(entry.value),
          reason: 'state "${entry.key}"',
        );
      }
    });
  });

  group('HaPushRule JSON', () {
    test('round-trip toJson / fromJson preserves all fields', () {
      final original = HaPushRule(
        id:            'json_test',
        name:          'JSON Rule',
        entityPattern: 'climate.',
        triggerState:  'heat',
        titleTemplate: 'Title {{friendly_name}}',
        bodyTemplate:  'Body {{state}}',
        priority:      2,
        enabled:       false,
      );

      final decoded = HaPushRule.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

      expect(decoded.id,            original.id);
      expect(decoded.name,          original.name);
      expect(decoded.entityPattern, original.entityPattern);
      expect(decoded.triggerState,  original.triggerState);
      expect(decoded.titleTemplate, original.titleTemplate);
      expect(decoded.bodyTemplate,  original.bodyTemplate);
      expect(decoded.priority,      original.priority);
      expect(decoded.enabled,       original.enabled);
    });

    test('fromJson tolerates missing priority field (defaults to 1)', () {
      final json = {
        'id': 'x', 'name': 'X', 'entityPattern': 'lock.',
        'triggerState': null,
        'titleTemplate': 'T', 'bodyTemplate': 'B',
        'enabled': true,
        // no 'priority'
      };
      expect(HaPushRule.fromJson(json).priority, 1);
    });
  });

  group('kDefaultPushRules', () {
    test('all rules have unique IDs', () {
      final ids = kDefaultPushRules.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all rules have non-empty templates', () {
      for (final rule in kDefaultPushRules) {
        expect(rule.titleTemplate, isNotEmpty, reason: '${rule.id} title empty');
        expect(rule.bodyTemplate,  isNotEmpty, reason: '${rule.id} body empty');
        expect(rule.entityPattern, isNotEmpty, reason: '${rule.id} pattern empty');
      }
    });

    test('critical safety rules (alarm/water/smoke) are enabled by default', () {
      final critical = {'alarm_triggered', 'water_leak', 'smoke', 'co_gas'};
      for (final rule in kDefaultPushRules) {
        if (critical.contains(rule.id)) {
          expect(rule.enabled, isTrue, reason: '${rule.id} should be ON');
        }
      }
    });
  });
}
