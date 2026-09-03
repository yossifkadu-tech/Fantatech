import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/services/discovery/bthome_decoder.dart';

void main() {
  group('BtHomeDecoder', () {
    test('decodes an unencrypted temperature + humidity + battery payload', () {
      // info byte 0x40 (version 2, unencrypted), then:
      //   0x01 battery = 0x5A (90%)
      //   0x02 temperature = 0x00 0x03 -> wait, use a concrete known vector:
      // Battery 100%, Temperature 25.06°C, Humidity 50.55%
      //   0x01 0x64            -> battery = 100
      //   0x02 0x22 0x0A       -> temperature (sint16 LE) 0x0A22 = 2594 * 0.01 = 25.94
      //   0x03 0xC7 0x13       -> humidity (uint16 LE) 0x13C7 = 5063 * 0.01 = 50.63
      final bytes = [0x40, 0x01, 0x64, 0x02, 0x22, 0x0A, 0x03, 0xC7, 0x13];
      final decoded = BtHomeDecoder.decode(bytes);

      expect(decoded, isNotNull);
      expect(decoded!.encrypted, isFalse);
      expect(decoded.batteryPercent, 100);
      expect(decoded.temperature, closeTo(25.94, 0.001));
      expect(decoded.humidity, closeTo(50.63, 0.001));
    });

    test('flags an encrypted payload without attempting to parse it', () {
      final bytes = [0x41, 0x01, 0x02, 0x03]; // encryption bit set
      final decoded = BtHomeDecoder.decode(bytes);

      expect(decoded, isNotNull);
      expect(decoded!.encrypted, isTrue);
      expect(decoded.readings, isEmpty);
    });

    test('decodes a door-open event', () {
      final bytes = [0x40, 0x1A, 0x01]; // door object id, open
      final decoded = BtHomeDecoder.decode(bytes);

      expect(decoded, isNotNull);
      final door = decoded!.readings.firstWhere((r) => r.key == 'door');
      expect(door.value, 1);
    });

    test('returns empty readings for an empty measurement section', () {
      final decoded = BtHomeDecoder.decode([0x40]);
      expect(decoded, isNotNull);
      expect(decoded!.readings, isEmpty);
    });

    test('returns null for empty input', () {
      expect(BtHomeDecoder.decode([]), isNull);
    });

    test('stops cleanly at an unknown object id instead of misreading the rest', () {
      final bytes = [0x40, 0x01, 0x64, 0xEE, 0x99, 0x99]; // 0xEE is unrecognized
      final decoded = BtHomeDecoder.decode(bytes);

      expect(decoded, isNotNull);
      expect(decoded!.batteryPercent, 100);
      expect(decoded.readings.length, 1);
    });
  });
}
