---
name: home-assistant
description: Integrate Home Assistant as a device/integration layer, keeping HA-specific structures out of the UI — plus the real client, its outsized role as the only brand with full command coverage today, and the reconnect pattern worth reusing. Load when working on HA integration or generalizing HA-only features to other brands.
---

# FantaTech Home Assistant Skill

## Purpose

Integrate Home Assistant as a device/integration layer.

Home Assistant may provide:

- device discovery
- entities
- automations
- Zigbee
- Z-Wave
- Matter
- MQTT
- cameras

FantaTech must maintain its own normalized device model.

Do not expose Home Assistant-specific structures throughout the UI.

Keep the integration boundary clear.

---

## Current implementation (search here before creating anything new)

`lib/services/gateways/clients/ha_gateway_client.dart` (largest client in the codebase, ~500
lines) is the real HA integration — REST + WebSocket.

**Where the integration boundary is currently thinner than it should be**: HA is the **only**
brand with working `setClimate`/`setCoverPosition`/`stopCover`/`vacuumCommand` paths in
`device_commander.dart` — every other brand that could support these (DIRIGERA blinds, Z2M
covers, Aqara) has no command path at all, purely because nobody added the branch, not because
it's technically impossible. `vacuumCommand` even routes non-HA-native vacuum entities through
HA's `vacuum` domain service calls, because that was the only vacuum control path that existed
before direct iRobot/Xiaomi adapters were added. This is exactly the kind of HA-structure leakage
the "keep the boundary clear" rule above is meant to prevent — closing it (giving other brands
their own climate/cover/vacuum command paths) is exactly what the `device-adapter` scaffold is
for; a `DeviceCommand` with those actions already exists in its vocabulary.

**WebSocket reconnect (reference pattern)**: `lib/services/ha/ha_provider.dart` implements real
exponential backoff (5s→10s→20s→40s, capped at 60s) — copy this pattern for any other live
connection needing backoff rather than inventing a new one (see `mqtt` skill).
