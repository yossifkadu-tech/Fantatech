import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device.dart';
import 'package:fantatech/services/control/device_commander.dart';
import 'package:fantatech/services/gateways/gateway_manager.dart';
import 'package:fantatech/services/gateways/gateway_model.dart';
import 'package:fantatech/services/gateways/gateway_types.dart';

/// These tests exercise DeviceCommander's routing/guard logic only — the
/// paths that return `false` before any network call would be made (no
/// matching id prefix, no connected gateway, missing required attributes).
/// They do not hit real hardware or gateway clients.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Device device(String id, {Map<String, dynamic> attrs = const {}}) => Device(
        id: id,
        name: 'Test Device',
        type: DeviceType.light,
        attributes: Map<String, dynamic>.from(attrs),
      );

  group('DeviceCommander.setOnOff', () {
    test('unrecognized id prefix returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setOnOff(
        device('unknown_1'),
        true,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('ha_ device with no connected HA gateway returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setOnOff(
        device('ha_light.kitchen', attrs: {'entityId': 'light.kitchen'}),
        true,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('ha_ device with connected gateway but missing entityId returns false', () async {
      final gateways = GatewayManager();
      gateways.connections.add(GatewayConnection(
        id: 'gw1',
        type: GatewayType.homeAssistant,
        displayName: 'HA',
        credentials: {'ip': '192.168.1.10', 'token': 'abc'},
        isConnected: true,
      ));
      final result = await DeviceCommander.setOnOff(
        device('ha_light.kitchen'),
        true,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('dirigera_ device with no connected gateway returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setOnOff(
        device('dirigera_abc123'),
        true,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('govee_ device with no ip attribute returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setOnOff(
        device('govee_1'),
        true,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('LAN-direct device with no ip and no known protocol returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setOnOff(
        device('plain_switch_1'),
        true,
        gateways: gateways,
      );
      expect(result, isFalse);
    });
  });

  group('DeviceCommander.setClimate', () {
    test('non-ha_ device returns false regardless of gateway state', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setClimate(
        device('dirigera_ac1'),
        hvacMode: 'cool',
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('ha_ device with no params set returns false even when connected', () async {
      final gateways = GatewayManager();
      gateways.connections.add(GatewayConnection(
        id: 'gw1',
        type: GatewayType.homeAssistant,
        displayName: 'HA',
        credentials: {'ip': '192.168.1.10', 'token': 'abc'},
        isConnected: true,
      ));
      final result = await DeviceCommander.setClimate(
        device('ha_climate.living', attrs: {'entityId': 'climate.living'}),
        gateways: gateways,
      );
      expect(result, isFalse);
    });
  });

  group('DeviceCommander.setCoverPosition / stopCover', () {
    test('setCoverPosition on non-ha_ device returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setCoverPosition(
        device('z2m_blind1'),
        50,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('stopCover on non-ha_ device returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.stopCover(
        device('z2m_blind1'),
        gateways: gateways,
      );
      expect(result, isFalse);
    });
  });

  group('DeviceCommander.vacuumCommand', () {
    test('irobot_ device with missing credentials returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.vacuumCommand(
        device('irobot_1'),
        VacuumAction.start,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('xiaomi_vacuum_ device with missing token returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.vacuumCommand(
        device('xiaomi_vacuum_1', attrs: {'ip': '192.168.1.20'}),
        VacuumAction.dock,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('unrecognized id prefix returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.vacuumCommand(
        device('unknown_vac'),
        VacuumAction.pause,
        gateways: gateways,
      );
      expect(result, isFalse);
    });
  });

  group('DeviceCommander.setBrightness', () {
    test('unrecognized id prefix returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setBrightness(
        device('unknown_1'),
        50,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('lifx_ device with no token returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setBrightness(
        device('lifx_1'),
        50,
        gateways: gateways,
      );
      expect(result, isFalse);
    });

    test('nanoleaf_ device with ip but no token returns false', () async {
      final gateways = GatewayManager();
      final result = await DeviceCommander.setBrightness(
        device('nanoleaf_1', attrs: {'ip': '192.168.1.30'}),
        50,
        gateways: gateways,
      );
      expect(result, isFalse);
    });
  });
}
