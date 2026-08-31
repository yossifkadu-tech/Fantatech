---
description: Enter plan mode for a FantaTech feature/change, grounded in this repo's rules
argument-hint: "<what to plan>"
---

Before designing anything, load `fantatech-flutter/docs/06_Development_Rules.md` and
`fantatech-flutter/docs/04_Architecture.md` so the plan respects this repo's dependency
direction (UI → State → Services → External) and naming conventions.

Then enter plan mode for: $ARGUMENTS

Follow the standing project mandate: do not rebuild working UI, do not remove business logic,
translations, MQTT/WebSocket/HA integration to make room for the new thing. Prefer additive,
reversible steps (a new scaffold/adapter/screen) over rewriting something that already works —
see the `device-adapter` skill if the request touches device/brand integration, since that
pattern (build isolated → migrate one pilot → keep the legacy path as fallback) is the house
style for anything risky. If the request is ambiguous or could have broad consequences, use
AskUserQuestion before finalizing the plan rather than guessing.
