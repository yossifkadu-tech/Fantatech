import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/services/ha/ha_entity.dart';

void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────

  HaEntity entity({
    String entityId = 'light.living_room',
    String state = 'on',
    Map<String, dynamic> attributes = const {},
    String? areaId,
    String? deviceId,
  }) =>
      HaEntity(
        entityId:   entityId,
        state:      state,
        attributes: attributes,
        areaId:     areaId,
        deviceId:   deviceId,
      );

  // ── Domain ────────────────────────────────────────────────────────────────

  group('domain', () {
    test('extracts domain from entity_id', () {
      expect(entity(entityId: 'light.kitchen').domain,             'light');
      expect(entity(entityId: 'binary_sensor.smoke').domain,       'binary_sensor');
      expect(entity(entityId: 'alarm_control_panel.home').domain,  'alarm_control_panel');
    });

    test('haDomain enum mapping', () {
      expect(entity(entityId: 'light.x').haDomain,             HaDomain.light);
      expect(entity(entityId: 'switch.x').haDomain,            HaDomain.switchDomain);
      expect(entity(entityId: 'climate.x').haDomain,           HaDomain.climate);
      expect(entity(entityId: 'cover.x').haDomain,             HaDomain.cover);
      expect(entity(entityId: 'lock.x').haDomain,              HaDomain.lock);
      expect(entity(entityId: 'media_player.x').haDomain,      HaDomain.mediaPlayer);
      expect(entity(entityId: 'fan.x').haDomain,               HaDomain.fan);
      expect(entity(entityId: 'vacuum.x').haDomain,            HaDomain.vacuum);
      expect(entity(entityId: 'unknown_domain.x').haDomain,    HaDomain.other);
    });
  });

  // ── isOn ──────────────────────────────────────────────────────────────────

  group('isOn', () {
    final truthy = ['on', 'open', 'unlocked', 'heat', 'cool', 'auto',
                    'fan_only', 'dry', 'home', 'playing', 'paused', 'cleaning'];
    final falsy  = ['off', 'closed', 'locked', 'unavailable', 'unknown'];

    for (final s in truthy) {
      test('"$s" is on', () => expect(entity(state: s).isOn, isTrue));
    }
    for (final s in falsy) {
      test('"$s" is off', () => expect(entity(state: s).isOn, isFalse));
    }

    test('positive numeric state is on', () {
      expect(entity(state: '100').isOn, isTrue);
      expect(entity(state: '0').isOn,   isFalse);
    });
  });

  // ── friendlyName ─────────────────────────────────────────────────────────

  group('friendlyName', () {
    test('returns friendly_name attribute', () {
      expect(
        entity(attributes: {'friendly_name': 'Kitchen Light'}).friendlyName,
        'Kitchen Light',
      );
    });

    test('falls back to entity_id when attribute missing', () {
      expect(entity(entityId: 'light.k', attributes: {}).friendlyName, 'light.k');
    });
  });

  // ── Light attributes ──────────────────────────────────────────────────────

  group('brightness', () {
    test('converts 0–255 → 0–100', () {
      expect(entity(attributes: {'brightness': 255.0}).brightness, 100);
      expect(entity(attributes: {'brightness': 128.0}).brightness, 50);
      expect(entity(attributes: {'brightness': 0.0}).brightness,   0);
    });

    test('returns null when missing', () {
      expect(entity(attributes: {}).brightness, isNull);
    });
  });

  group('rgbColor', () {
    test('parses [r,g,b] list', () {
      final e = entity(attributes: {'rgb_color': [255, 128, 0]});
      expect(e.rgbColor, [255, 128, 0]);
    });

    test('returns null for missing or malformed', () {
      expect(entity(attributes: {}).rgbColor, isNull);
      expect(entity(attributes: {'rgb_color': [1, 2]}).rgbColor, isNull);
    });
  });

  // ── Climate attributes ────────────────────────────────────────────────────

  group('climate attributes', () {
    test('currentTemperature parses num', () {
      expect(
        entity(attributes: {'current_temperature': 22.5}).currentTemperature,
        22.5,
      );
    });

    test('hvacModes returns list', () {
      final e = entity(attributes: {'hvac_modes': ['heat', 'cool', 'off']});
      expect(e.hvacModes, ['heat', 'cool', 'off']);
    });
  });

  // ── Cover attributes ──────────────────────────────────────────────────────

  group('coverPosition', () {
    test('returns current_position', () {
      expect(entity(attributes: {'current_position': 75}).coverPosition, 75);
    });
    test('returns null when missing', () {
      expect(entity(attributes: {}).coverPosition, isNull);
    });
  });

  // ── Lock attributes ───────────────────────────────────────────────────────

  group('lock state shortcuts', () {
    test('isLocked / isUnlocked', () {
      expect(entity(state: 'locked').isLocked,    isTrue);
      expect(entity(state: 'locked').isUnlocking, isFalse);
      expect(entity(state: 'unlocking').isUnlocking, isTrue);
      expect(entity(state: 'jammed').isJammed,    isTrue);
    });
  });

  // ── Copy ─────────────────────────────────────────────────────────────────

  group('copyWithState', () {
    test('changes state and attributes', () {
      final original = entity(
        entityId: 'light.x', state: 'off',
        attributes: {'brightness': 0.0},
        areaId: 'living', deviceId: 'dev1',
      );
      final updated = original.copyWithState('on', {'brightness': 200.0});

      expect(updated.state,                  'on');
      expect(updated.attributes['brightness'], 200.0);
      expect(updated.entityId,               original.entityId);
      expect(updated.areaId,                 original.areaId);
      expect(updated.deviceId,               original.deviceId);
    });

    test('preserves old attributes when newAttrs is null', () {
      final original = entity(attributes: {'brightness': 100.0});
      final updated  = original.copyWithState('off');
      expect(updated.attributes['brightness'], 100.0);
    });
  });

  group('copyWith', () {
    test('overrides only specified fields', () {
      final original = entity(
        entityId: 'light.x', state: 'on', areaId: 'a1', deviceId: 'd1',
      );
      final updated = original.copyWith(areaId: 'a2');

      expect(updated.areaId,   'a2');
      expect(updated.deviceId, 'd1'); // unchanged
      expect(updated.entityId, original.entityId);
      expect(updated.state,    original.state);
    });

    test('null preserves existing value', () {
      final original = entity(areaId: 'zone1', deviceId: 'dev9');
      final updated  = original.copyWith();
      expect(updated.areaId,   'zone1');
      expect(updated.deviceId, 'dev9');
    });
  });

  // ── Factory fromJson ──────────────────────────────────────────────────────

  group('HaEntity.fromJson', () {
    test('parses basic HA state payload', () {
      final json = {
        'entity_id':  'switch.fan',
        'state':      'on',
        'attributes': {'friendly_name': 'Fan', 'icon': 'mdi:fan'},
      };
      final e = HaEntity.fromJson(json, areaId: 'bedroom', deviceId: 'd42');

      expect(e.entityId,    'switch.fan');
      expect(e.state,       'on');
      expect(e.friendlyName, 'Fan');
      expect(e.areaId,      'bedroom');
      expect(e.deviceId,    'd42');
    });

    test('handles missing attributes gracefully', () {
      final e = HaEntity.fromJson({'entity_id': 'sensor.x', 'state': '21.5'});
      expect(e.attributes, isEmpty);
      expect(e.areaId,     isNull);
    });

    test('defaults state to "unknown" when missing from JSON', () {
      final e = HaEntity.fromJson({'entity_id': 'sensor.y'});
      expect(e.state, 'unknown');
    });
  });
}
