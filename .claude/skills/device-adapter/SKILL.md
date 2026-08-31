---
name: device-adapter
description: How to create integrations for different manufacturers and protocols — adapter responsibilities, boundaries, and the required normalization into the FantaTech Device Model. Load when adding a new brand or touching device dispatch.
---

# FantaTech Device Adapter Skill

## Purpose

Create integrations for different manufacturers and protocols.

## Architecture

FantaTech UI
↓
Device Service
↓
Device Adapter
↓
Protocol
↓
Device

## Adapter responsibilities

An adapter may provide:

- discovery
- pairing
- authentication
- device listing
- state reading
- command execution
- events
- availability
- capabilities

## Adapter must NOT

- modify unrelated UI
- contain business logic
- expose secrets
- change core architecture unnecessarily

## Required behavior

Normalize external device data into the FantaTech Device Model.

Each adapter must be independently testable.

---

## Current implementation (search here before creating anything new)

The scaffold described above already exists at `lib/services/device_platform/` — don't rebuild it:

- **`device_adapter.dart`** — `abstract class DeviceAdapter` (`id`, `canHandle(Device)`,
  `testConnection()`, `importDevices()`, `execute(Device, DeviceCommand)`, `capabilitiesFor()`).
- **`capability_model.dart`** — `CapabilityModel.resolve(device, {adapter})`, composes with the
  existing `DeviceCapabilities.of(device)` rather than replacing it.
- **`adapter_registry.dart`** — `DeviceAdapterRegistry.register()`/`adapterFor()`. As of now,
  nothing is registered — it's inert scaffold, not yet wired into `DeviceCommander`.

**Legacy state it will eventually replace**: today every brand is still routed by hand in
`lib/services/control/device_commander.dart` (15+ `if (device.id.startsWith('brand_'))` branches,
repeated across `setOnOff`/`setBrightness`/`setClimate`/`setCoverPosition`/`stopCover`/
`vacuumCommand`) and `lib/services/gateways/gateway_manager.dart` (`_doConnect`/`_doImport`,
one `switch (GatewayType)` case per brand). Migrating a brand onto the adapter model:

1. Write `<brand>_adapter.dart` implementing `DeviceAdapter`, wrapping the brand's *existing*
   client class — the adapter is a thin front door, not new protocol code.
2. Register it at app startup.
3. At the top of each relevant `DeviceCommander` method: `adapterFor(device)` → if non-null,
   `adapter.execute(...)`; otherwise fall through to the existing branch, unchanged.
4. Don't delete the legacy branch in the same change — verify the adapter end-to-end first.

**Known landmine**: device `id` prefixes aren't consistent — most brands use `brand_`
(underscore), but Aqara/Ajax/Risco/PIMA/Z-Wave use `brand-` (dash), set by `GatewayManager`.
Check the actual prefix a brand uses before writing `canHandle()`.
