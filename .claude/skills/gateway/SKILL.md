---
name: gateway
description: The FantaTech local Gateway — local-first design principle, and how it maps to the two real pieces in this repo (the Flutter-side GatewayManager and the local hub/ FastAPI server). Load when adding a gateway/brand or touching connect/import flows.
---

# FantaTech Gateway Skill

## Purpose

Develop the FantaTech local Gateway.

Responsibilities may include:

- local device communication
- discovery
- MQTT
- Home Assistant
- Zigbee
- Z-Wave
- Matter
- ONVIF
- local automations
- local caching
- local state

Design principle:

LOCAL-FIRST.

If Internet connectivity fails, local device functionality should continue whenever possible.

Gateway must expose a stable API to the FantaTech application.

Do not expose internal protocol implementation unnecessarily.

---

## Current implementation — two real pieces, don't conflate them

**1. `hub/` (Python/FastAPI)** is the actual local-first Gateway described above — runs
per-installation on the customer's own Raspberry Pi/PC, not centrally (see `cloud` skill: this is
explicitly *not* part of FantaTech's shared cloud footprint). It exposes routers for devices,
rules, history, rooms, network, matter, zigbee, tuya, scenes, camera, and more (`hub/main.py`) —
this is the "stable API to the FantaTech application" the rule above asks for.

**2. `lib/services/gateways/gateway_manager.dart`** (Flutter side) is a *different* thing with a
similar name: the `ChangeNotifier` that manages the app's direct connections to brand
gateways/clouds (DIRIGERA, deCONZ, Tuya Cloud, etc.) — see the `gateway` details below. It's not
the local-first hub; it's the app's own connection-management layer, and can include direct cloud
paths (Tuya) alongside local ones (DIRIGERA).

## `GatewayManager` specifics (search here before creating anything new)

Two large `switch (GatewayType)` statements:
- **`_doConnect`** (~lines 101-542, ~19 cases) — auth/probe, build a `GatewayConnection`
  (credentials persisted via SharedPreferences).
- **`_doImport`** (~lines 590-855, ~15 cases) — fetch devices from a connected gateway, map to
  `Device`s. `default: return failure('Not supported yet')` **silently** swallows any
  `GatewayType` without an explicit case — a missing case is not a compile error. Always add both
  cases together when introducing a new `GatewayType`.

Adding a new `GatewayType`: enum value + `GatewayMeta` entry in `gateway_types.dart` (name, icon,
color, `GatewayFieldDef` list, `setupSteps`) — see the Aqara (local-LAN-with-token) vs. Tuya
(cloud-with-account-linking) entries for the two shapes this takes — then a case in both
`_doConnect` and `_doImport`.

**Relationship to the device-adapter platform**: not yet connected. A `DeviceAdapter`
implementation for a gateway-backed brand should wrap its `GatewayManager` case's logic rather
than duplicating auth/import code — see `device-adapter` skill.
