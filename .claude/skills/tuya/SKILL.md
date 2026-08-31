---
name: tuya
description: Integrate Tuya / Smart Life devices — isolation rules, capability mapping, and the real client's auth flow and known import gotchas. Load when working on Tuya support or debugging a Tuya import.
---

# FantaTech Tuya Skill

## Purpose

Integrate Tuya / Smart Life devices.

## Rules

Tuya-specific code must remain inside the Tuya integration layer.

Never spread Tuya-specific API structures through the application.

Map Tuya devices to:

FantaTech Device

FantaTech Capability

FantaTech State

## Supported examples

- switches
- plugs
- lights
- sensors
- temperature sensors
- humidity sensors
- motion sensors
- contact sensors
- cameras
- alarms

## Safety

Never expose:

- access tokens
- API secrets
- user passwords

Never log credentials.

## Implementation principle

Use the existing FantaTech architecture.

Do not create a second device system.

---

## Current implementation (search here before creating anything new)

`lib/services/gateways/clients/tuya_cloud_client.dart` is the real, working Tuya integration
layer — don't build a second one. This is the **cloud API path** (OpenAPI v1.0,
HMAC-SHA256-signed), not local LAN control.

**Auth flow**: `GET /v1.0/token?grant_type=1` → access_token → `GET
/v1.0/iot-01/associated-users/devices` → `POST /v1.0/devices/{id}/commands`. `clientId`/
`clientSecret` come from one Tuya IoT Platform Cloud Project (developer identity: **ISV**),
created once by the app operator — each end customer links their own Smart Life account into
that same project via QR code, they don't get their own Access ID/Secret.

**Category → capability mapping**: `_categoryToType()` maps Tuya category codes (`kg`=switch,
`cz`=socket, `dj`=bulb, `pir`=motion, `sj`=water leak, etc.) to the FantaTech `DeviceType`. An
unmapped category now imports as `DeviceType.unknown` rather than being silently dropped — that
silent-drop behavior was a real bug, already fixed; don't reintroduce it if this mapping is
extended.

**The two things that actually cause "0 devices imported"** (not a mapping problem — check these
first):
1. **Data Center suspended** — API error code `28841107`. A project-level trial/subscription
   state on iot.tuya.com (Cloud → project → Service API → IoT Core → My Subscriptions), not a
   code bug. Extending a trial there is a manual-review request, not instant.
2. **Cloud Authorization IP Allowlist** — if enabled on the project, it can block requests from
   the app's variable mobile IP. HMAC signing already authenticates every request regardless of
   IP, so for an app with distributed end-customer devices this should be disabled or set to
   allow all.

`TuyaCloudClient.lastRawSummary` (populated by `fetchDevices()`) is a diagnostic dump of exactly
what the API returned per device, surfaced via a dialog in `gateway_hub_screen.dart` — check it
before guessing at an import failure.
