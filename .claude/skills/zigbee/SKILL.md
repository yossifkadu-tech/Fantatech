---
name: zigbee
description: Support Zigbee devices — integration boundaries (Zigbee2MQTT/HA/gateway), manufacturer isolation, and the four real gateway clients already in this codebase with their differing auth shapes. Load when working on Zigbee device/gateway integration.
---

# FantaTech Zigbee Skill

## Purpose

Support Zigbee devices.

Preferred integration boundaries:

- Zigbee2MQTT
- Home Assistant
- Zigbee gateway

Do not hard-code individual Zigbee manufacturers into FantaTech Core.

Normalize:

device
manufacturer
model
capabilities
state
battery
availability

Keep Zigbee protocol logic isolated.

---

## Current implementation (search here before creating anything new)

Four real gateway clients already exist under `lib/services/gateways/clients/` — each a
different auth/API shape, don't build a fifth without checking these first:

| Gateway | Client file | Auth | Notes |
|---|---|---|---|
| IKEA DIRIGERA | `dirigera_client.dart` | Local token pairing | Also a Thread border router — see `matter` skill |
| deCONZ/Phoscon | `deconz_client.dart` | API key via Phoscon UI authorize | ConBee/RaspBee USB coordinators |
| Zigbee2MQTT | `z2m_client.dart` | MQTT broker credentials | Devices reached via MQTT publish, not REST — see `mqtt` skill |
| Aqara Hub | `aqara_hub_client.dart` | Local API token from developer.aqara.com | M2/E1/M1S Gen2, local network port 80 |

**Hardware note for user-facing advice**: a USB Zigbee radio (SONOFF ZBDongle-E, SkyConnect) is
for Zigbee2MQTT/ZHA running on a local server (a Pi, Home Assistant) — it has no UI of its own. A
standalone appliance like SONOFF Dongle Max is a self-contained Zigbee gateway with its own
firmware. Different product categories; don't recommend one when the other is meant.

**Device-type mapping** is per-gateway (each client has its own model/category → `DeviceType`
table) — check the specific client before assuming a device isn't supported.

**"0 devices imported" diagnostic instinct**: same as the `tuya` skill — check for (or add,
following that pattern) a `lastRawSummary`-style diagnostic before assuming a category-mapping
gap. Silently dropping unmapped categories is a known anti-pattern in this codebase, already
fixed once for Tuya; don't reintroduce it here.
