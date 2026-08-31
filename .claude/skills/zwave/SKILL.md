---
name: zwave
description: Support Z-Wave devices via a Z-Wave JS UI bridge, not a native radio client — the real setup requirement this implies, plus the id-prefix landmine. Load when working on Z-Wave integration.
---

# FantaTech Z-Wave Skill

## Purpose

Support Z-Wave devices.

Preferred integration:

Home Assistant / Z-Wave JS where appropriate.

Keep Z-Wave implementation outside the FantaTech core.

Normalize device capabilities.

Pay special attention to:

- locks
- sensors
- switches
- thermostats
- alarm devices

Never expose security credentials.

---

## Current implementation (search here before creating anything new)

`lib/services/gateways/clients/zwave_client.dart` is a REST client for a **Z-Wave JS UI**
(zwavejs2mqtt) server — FantaTech does not talk to a Z-Wave radio/controller directly, it talks
to that self-hosted bridge, which talks to the controller. Don't build a native Z-Wave radio
client; extend this bridge client instead.

**Implication for setup/support conversations**: Z-Wave support requires the user to already be
running Z-Wave JS UI somewhere on their network (commonly a Home Assistant add-on, or standalone
on the same Pi/server as everything else) — it is not a "plug in a USB stick and go" integration
the way the local-LAN brands (Shelly/Sonoff) are. Set expectations accordingly.

**Device mapping**: `_zwaveClassToDeviceType()` in `gateway_manager.dart` maps Z-Wave device
classes to `DeviceType` — check it before assuming a category isn't supported.

**Id-prefix landmine**: Z-Wave devices use `zwave-` (dash), not `zwave_` (underscore) — see the
`device-adapter` skill's note on this inconsistency before writing any prefix-matching code.
