---
description: Load full FantaTech project context before starting real work
---

Read, in order, and hold in context for the rest of this session:

1. `CLAUDE.md` (repo root) — the entry point.
2. `fantatech-flutter/docs/06_Development_Rules.md` — the non-negotiable rules.
3. `fantatech-flutter/docs/04_Architecture.md` — folder structure and dependency direction.
4. `fantatech-flutter/docs/05_Device_Support.md` — real vs. UI-only brand support.

Then check for drift between docs and code:
- `grep "^version:" fantatech-flutter/pubspec.yaml` vs. what `docs/09_Changelog.md` claims as latest.
- Whether `lib/services/device_platform/` exists (the Multi-Brand Device Platform scaffold) —
  if it doesn't yet, the `device-adapter` skill's migration steps don't apply until it's built.

Summarize in under 200 words: what's current, what's stale, and anything that looks
inconsistent between the docs and the actual code. Don't make any edits.
