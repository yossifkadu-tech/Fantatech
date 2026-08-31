---
description: Add or modify a device integration, using the Device Adapter architecture
argument-hint: "<brand/protocol name> — <local/cloud if known>"
---

Add or modify a device integration for: $ARGUMENTS

Use the Device Adapter architecture (see `device-adapter` skill for the exact scaffold and
migration recipe). First identify:

- manufacturer
- model
- protocol
- device category
- capabilities
- discovery method
- command method
- state/event method

Do not modify FantaTech Core unless necessary. Normalize the device into the FantaTech Device
Model. Do not implement unrelated features.

## This-repo specifics

1. Check `fantatech-flutter/docs/05_Device_Support.md` and the existing clients under
   `lib/services/gateways/clients/` for the closest analog — local-LAN brands (see `mqtt` skill's
   Shelly/Sonoff notes) and cloud-API brands (see `tuya` skill) use genuinely different shapes;
   match the right template rather than guessing.
2. If this is a **migration** of a brand already handled by `device_commander.dart`'s prefix
   chains or `gateway_manager.dart`'s switches, the legacy branch stays in place as the fallback
   — the adapter path is checked first, nothing is deleted until the adapter is verified
   end-to-end with a real device.
3. Naming: follow `06_Development_Rules.md` §3 (`brand_client.dart` under
   `services/gateways/clients/`, class `BrandClient`, or `<brand>_adapter.dart` under
   `services/device_platform/` for a full adapter).

Run targeted tests. If `device_commander.dart` or `gateway_manager.dart` was touched, run the
full suite (see `testing` skill) — those are shared dispatch code, not isolated to this brand.
