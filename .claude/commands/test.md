---
description: Run only tests relevant to the current change
---

Run only tests relevant to the current change. Do not modify application behavior.

Check:

1. Compilation — `cd fantatech-flutter && flutter analyze <changed files> 2>&1 | tail -10`.
2. Static analysis — `flutter analyze lib/ 2>&1 | tail -5` (full-project error count must not
   exceed baseline outside the changed files).
3. Unit tests — `flutter test <changed test files or the relevant test/unit/*_test.dart>`, not
   the full suite, unless the change touched `device_commander.dart`, `gateway_manager.dart`, or
   `lib/services/device_platform/` (shared dispatch code — see `testing` skill).
4. Integration tests where relevant — none exist yet beyond the widget tests under
   `test/widget/`; run those specifically if the change touched a screen they cover.

For any failure: `git diff --stat -- <source file under test>` — if that source file wasn't
touched this session, it's pre-existing test debt (known: `ha_automations_screen_test.dart`,
`ha_cameras_screen_test.dart`), not a new failure — report it as such, don't let it read as a
regression you caused.

Report only:

```
PASSED
FAILED
WARNINGS
NEXT STEP
```
