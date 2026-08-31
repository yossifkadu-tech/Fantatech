---
name: testing
description: Prevent regressions — targeted-test-first discipline, plus what's actually tested in this codebase today (7 files), the real coverage gaps, known pre-existing failures, and the adapter-test template. Load before writing tests or making claims about test coverage.
---

# FantaTech Testing Skill

## Goal

Prevent regressions.

For every change:

1. Identify affected component.
2. Run targeted test.
3. Run static analysis if relevant.
4. Compile/build affected target.
5. Verify existing behavior.

Prefer targeted tests over full repository tests.

When an integration is added, test:

- discovery
- authentication
- device creation
- capability mapping
- state reading
- command execution
- errors
- unavailable device

---

## Current state (search here before writing a test or claiming coverage)

`fantatech-flutter/test/` has 8 files:
- `unit/device_model_test.dart` — `Device`/`DeviceType` model only.
- `unit/gateway_credentials_test.dart` — credential storage only, not connect/import logic.
- `unit/ha_config_test.dart`, `unit/ha_entity_test.dart`, `unit/ha_push_rule_test.dart` — HA-
  specific.
- `widget/ha_automations_screen_test.dart`, `widget/ha_cameras_screen_test.dart` — widget tests
  for `lib/screens/ha/`.
- `unit/device_adapter_registry_test.dart` — the device-platform scaffold's registry +
  capability model, via a `_FakeAdapter` test double — **the template to copy** when a real
  adapter needs tests (implement the abstract `DeviceAdapter` directly for the fake; no mocking
  package is a project dependency, don't add one).

**Real gap**: no coverage exists for `device_commander.dart`'s dispatch logic,
`gateway_manager.dart`'s `_doConnect`/`_doImport` switches, or any individual brand client (Tuya,
Shelly, DIRIGERA, deCONZ, Z2M, SmartThings, Aqara, Ajax/Risco/PIMA, Z-Wave, IFTTT, iRobot, Xiaomi,
ONVIF). Don't claim something is "tested" or "verified" off `flutter analyze` alone — that checks
types compile, not that behavior is correct. The "discovery / authentication / device creation /
capability mapping / state reading / command execution / errors / unavailable device" checklist
above is exactly what's missing for these — apply it when an integration actually gets adapter-
migrated (see `device-adapter` skill), don't try to backfill all of it speculatively first.

**Known pre-existing failures** (as of this skill's writing): `ha_automations_screen_test.dart`
and `ha_cameras_screen_test.dart` have failing tests unrelated to any current work on
`lib/screens/ha/`. Before treating any failure as a regression: `git diff --stat` on the source
file under test — if untouched, it's pre-existing debt, say so explicitly rather than letting it
read as a new bug you introduced.

## Verification discipline

`flutter analyze lib/` → 0 errors, then a targeted `flutter test` on the affected file(s) — full
suite only when the change touches shared dispatch code (`device_commander.dart`,
`gateway_manager.dart`) or the device-platform scaffold, per the "prefer targeted tests" rule
above. See the `test` and `safe-change` commands for the exact sequence.
