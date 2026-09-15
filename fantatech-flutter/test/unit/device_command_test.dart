import 'package:flutter_test/flutter_test.dart';
import 'package:fantatech/models/device_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// sendDeviceCommand's full dispatch needs a live AppState, which this
// project's existing test suite deliberately avoids instantiating directly
// (see device_commander_test.dart's own comment on that) — so, matching
// that convention, only the pure, AppState-free offline guard is unit
// tested here. It's the piece that actually satisfies "never resend
// endlessly / never fake success while offline": a single check, no loop,
// no network call attempted.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('resolveOfflineGuard', () {
    test('returns an offline CommandResult when the device is offline', () {
      final result = resolveOfflineGuard(false);

      expect(result, isNotNull);
      expect(result!.outcome, CommandOutcome.offline);
      expect(result.success, isFalse);
      expect(result.isOffline, isTrue);
      expect(result.message, isNotNull);
    });

    test('returns null (proceed) when the device is online', () {
      expect(resolveOfflineGuard(true), isNull);
    });
  });

  group('CommandResult', () {
    test('success is true only for CommandOutcome.success', () {
      expect(const CommandResult(CommandOutcome.success).success, isTrue);
      expect(const CommandResult(CommandOutcome.offline).success, isFalse);
      expect(const CommandResult(CommandOutcome.failed).success, isFalse);
    });
  });
}
