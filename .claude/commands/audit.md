---
description: Audit which brands/protocols have real integration code vs. UI-only
argument-hint: "[category, e.g. cameras | lights | vacuums — omit for everything]"
---

Audit brand/protocol support for: $ARGUMENTS (or the whole app if no argument given).

For each brand or device category in scope, classify as:
- **(a) Real** — an actual API/protocol client exists under `lib/services/` and is wired into
  `DeviceCommander` or `GatewayManager`, not just recognized by name.
- **(b) UI-only** — appears in a picker/catalog screen with pairing-step text, but no backend
  client (e.g. voice-assistant entries in `gateway_types.dart` with no client file).
- **(c) Name-heuristic only** — matched by a string-contains check (e.g. `add_device_screen.dart`'s
  barcode resolver) purely to pick a catalog icon/category, with no control path behind it.

Cross-check against `fantatech-flutter/docs/05_Device_Support.md` and flag if the doc is stale
(claims (a) where the code is actually (b)/(c), or vice versa) — update the doc if you find drift,
but don't touch anything else. Report as a table, most-supported first. Read-only otherwise.
