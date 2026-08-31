---
description: Quick project status — git state, app version, analyze/test health
---

Inspect only relevant project metadata. Do not modify files. Keep the response concise.

Run in parallel:

1. `git status` and `git log --oneline -8` (repo root) — uncommitted changes, recent commits.
2. Current app version: `grep "^version:" fantatech-flutter/pubspec.yaml`.
3. `cd fantatech-flutter && flutter analyze lib/ 2>&1 | tail -5` — error count (must be 0),
   info-lint count.
4. `flutter test 2>&1 | tail -10` — pass/fail counts, only if the last status check found source
   changes since the tests last ran; skip if nothing changed (targeted, not habitual, per the
   `testing` skill's "prefer targeted over full" rule).
5. Whether an Android device is attached: `flutter devices` filtered to mobile.

Report in exactly this format:

```
PROJECT STATUS
CURRENT BRANCH
UNCOMMITTED CHANGES
RECENT COMMITS
CURRENT DEVELOPMENT AREA
KNOWN ISSUES
NEXT RECOMMENDED STEP
```

- **KNOWN ISSUES** should distinguish pre-existing failures (e.g. the `ha_automations_screen_test`/
  `ha_cameras_screen_test` failures — check `git diff --stat` on the source file under test before
  calling anything a regression) from anything the current branch's changes actually caused.
- **NEXT RECOMMENDED STEP** is one concrete action, not a list of options.

This command is read-only reconnaissance — don't fix anything found here.
