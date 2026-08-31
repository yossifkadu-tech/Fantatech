---
description: Make a change under the "don't break what works" discipline — smallest safe change, verified before and after
argument-hint: "<the change to make>"
---

Implement the smallest safe change: $ARGUMENTS

Rules:

- Do not rewrite existing code.
- Do not delete working functionality.
- Do not change unrelated files.
- Do not change public APIs unnecessarily.
- Preserve existing behavior.
- Follow the FantaTech Device Adapter architecture (see `device-adapter` skill) — if the change
  touches brand/device dispatch, wrap the existing client rather than rewriting it, and keep any
  legacy code path as a fallback until the new one is verified end-to-end.
- Run targeted tests, not the full suite, unless the change touches shared dispatch code
  (`device_commander.dart`, `gateway_manager.dart`) or the device-platform scaffold.

Before implementation, inspect the relevant code — identify the smallest set of files the change
actually requires; check 2-3 sibling files for the existing pattern to match (naming conventions
in `fantatech-flutter/docs/06_Development_Rules.md` §3). `flutter analyze` on the target files
first to record the baseline error count (should be 0).

If the change would require touching a working, unrelated code path just to make the new thing
fit, stop and ask rather than doing it — that's a sign the change needs its own isolated
module instead.

After implementation, `flutter analyze` on the changed files then on `lib/` in full — error count
must still be 0 and must not exceed baseline outside the intentionally-touched files. Report:

```
CHANGED
FILES
TESTS
ISSUES
NEXT
```
