# 05 — Device & Protocol Support

## Table of Contents

1. [Gateway / Hub Integrations](#1-gateway--hub-integrations)
2. [Direct Wi-Fi-Local Device Support](#2-direct-wi-fi-local-device-support)
3. [DeviceType Reference Table](#3-devicetype-reference-table)
4. [Matter Support — Detailed Status](#4-matter-support--detailed-status)
5. [Camera Protocol Support](#5-camera-protocol-support)
6. [Known Gaps](#6-known-gaps)

---

## 1. Gateway / Hub Integrations

Each gateway has a dedicated client under `services/gateways/clients/`:

| Client file | Brand / Protocol | Transport |
|---|---|---|
| `ha_gateway_client.dart` | Home Assistant | REST + WebSocket |
| `hue_client.dart` | Philips Hue Bridge | Local REST |
| `dirigera_client.dart` | IKEA DIRIGERA | Local REST (TLS + token) |
| `deconz_client.dart` | deCONZ (Zigbee) | Local REST |
| `z2m_client.dart` | Zigbee2MQTT | REST over HTTP (not raw MQTT from the app) |
| `zwave_client.dart` | Z-Wave (Z-Wave JS UI or similar) | Check current implementation before extending |
| `smartthings_client.dart` | Samsung SmartThings | Cloud REST |
| `tuya_cloud_client.dart` | Tuya / Smart Life cloud | Tuya OpenAPI + HMAC-SHA256 signing |
| `aqara_hub_client.dart` | Aqara Hub | Local |
| `ajax_client.dart` | Ajax alarm panels | Cloud/local (alarm-panel specific) |
| `pima_client.dart` | PIMA alarm panels | Alarm-panel specific |
| `risco_client.dart` | Risco alarm panels | Alarm-panel specific |
| `mqtt_gateway_client.dart` | Generic MQTT-based gateway | `mqtt_client` package |
| `ifttt_client.dart` | IFTTT | Webhook-based automation bridge |

All gateway connections are tracked by `GatewayManager` (`connections: List<GatewayConnection>`),
each with `type`, `isConnected`, and `credentials`.

## 2. Direct Wi-Fi-Local Device Support

Devices that don't need a hub — discovered directly on the LAN:

- **Shelly / Sonoff / Tapo-style** Wi-Fi switches/plugs — direct HTTP/CoAP control, discovered via
  subnet scan (`services/discovery/smart_switch_scanner.dart`).
- **Tuya Local Protocol 3.3** — AES-128-ECB encrypted local control (no cloud round-trip needed
  once paired), implemented alongside the cloud client using `encrypt` + `pointycastle`.
- **mDNS/DNS-SD discovery** (`services/discovery/matter_discovery.dart`) — despite the filename,
  this scanner also picks up `_hap._tcp` (HomeKit), `_esphomelib._tcp`, `_http._tcp`, `_mqtt._tcp`
  service types, not just Matter.

## 3. DeviceType Reference Table

Source of truth: `models/device.dart` enum + `theme/device_icons.dart`'s `MaterialSymbolsIconSet`.

| DeviceType | Icon | Accent Color | State-Aware? |
|---|---|---|---|
| `light` | `lightbulb` (on) / `lightbulb_outline` (off) | `lightColor` `#F59E0B` | ✅ on/off |
| `blind` | `blinds` / `blinds_closed` | `primary` | ✅ position |
| `airConditioner` | `hvac` | `acColor` `#06B6D4` | — |
| `smartPlug` | `power` | `plugColor` `#8B5CF6` | — |
| `smartSwitch` | `toggle_on` | `plugColor` | — |
| `motionSensor` | `sensors` / `directions_run` (detected) | `motionColor` `#F97316` | ✅ detected |
| `doorSensor` | `sensor_door` / `door_open` | `doorColor` `#38BDF8` | ✅ open/closed |
| `windowSensor` | `window` / `window_open` | `doorColor` | ✅ open/closed |
| `waterHeater` | `water_drop` | `acColor` | — |
| `camera` | `videocam` | `cameraColor` `#6366F1` | — |
| `intercom` | `doorbell` | `cameraColor` | — |
| `router` | `router` | `networkColor` `#00B4D8` | — |
| `gateway` | `hub` | `networkColor` | — |
| `circuitBreaker` | `electrical_services` | `circuitBreakerColor` `#7BB8FF` | — |
| `solar` | `wb_sunny` | `solarColor` `#EAB308` | — |
| `smokeSensor` | `local_fire_department` / `detector_smoke` | `smokeColor` `#FF6B35` | ✅ smoke active |
| `energyMeter` | `bolt` | `energyColor` `#FFD600` | — |
| `smartLock` | `lock` / `lock_open` | `lockColor` `#14B8A6` | ✅ locked/unlocked |
| `gasSensor` | `cloud` | `motionColor` | — |
| `waterLeakSensor` | `water_damage` / `water_drop` | `networkColor` | ✅ leak active |
| `glassBreakSensor` | `crisis_alert` | `smokeColor` | — |
| `matterDevice` | `hexagon` | `matterColor` `#7B6FCD` | — |
| `smartTv` | `tv` | `acColor` | — |
| `networkDevice` | `phone_android` | `networkDeviceColor` `#5C6BC0` | — |
| `printer` | `print` | `printerColor` `#78909C` | — |
| `garage` | `garage` | `garageColor` `#546E7A` | — |
| `alarmPanel` | `security` | `statusAlarm` | — |
| `unknown` | `device_unknown` | `plugColor` | — |

HA-only sensor sub-kinds (no distinct `DeviceType`, icon via `DeviceIcons.forHaDeviceClass()`):
`temperature` (thermometer), `humidity` (humidity_percentage), `pressure`, `illuminance`,
`battery`, `energy`, `power`, `voltage`, `current`, `co2`, `carbon_monoxide`, `pm25`/`pm10`,
`sound`, `vibration`, `weight`, `moisture`/`water`.

## 4. Matter Support — Detailed Status

Full architecture: mDNS discovery of Matter devices happens client-side
(`matter_discovery.dart`), but **commissioning and control are fully delegated to Home
Assistant's own Matter integration** — this app does not embed a Matter controller SDK.

| Capability | Status |
|---|---|
| QR code commissioning | ✅ Full UI (`matter_commission_screen.dart`, `mobile_scanner`) |
| Manual pairing code entry | ✅ Full (11-digit validation) |
| Local Matter Controller / SDK | ❌ None — delegated to HA via `commissionMatter()` |
| Matter Server (python-matter-server) integration | ⚠️ A Node.js bridge exists at `backend/matter/client.js` but is **not wired into the Flutter app** |
| Thread support | ⚠️ Recognized in discovery labels only, no credential/radio handling |
| Thread Border Router | ❌ Not implemented |
| Wi-Fi Matter devices | ⚠️ Generic discovery works; no Wi-Fi-specific provisioning step |
| Fabric management / multi-admin | ❌ None |
| OTA firmware updates | ❌ None |
| Device pairing | ✅ Via HA |
| Device unpairing | ✅ Real — `HaGatewayClient.removeDeviceByEntity()` removes it from HA's device registry (decommissions it from the fabric) |
| Device control (on/off, dimmer, cover, etc.) | ✅ Via HA entity passthrough |
| Device attestation / NOC / PAA / PAI certificates | ❌ Handled entirely server-side by HA, invisible to the app |
| State synchronization | ✅ Real-time via HA WebSocket |
| Matter-specific device metadata (node ID, fabric ID, vendor ID) | ❌ Not surfaced — devices appear as opaque HA entities |

## 5. Camera Protocol Support

`CameraStreamType` enum: `mjpeg`, `rtsp`, `hls`, `snapshot`, `unknown`. Discovery via ONVIF.
PTZ control supported (`isPtz`, `onvifProfileToken` fields on `Camera`). Face
enrollment/analysis via Azure Cognitive Services Face API (needs `AZURE_FACE_API_KEY` +
`AZURE_FACE_API_ENDPOINT`).

## 6. Known Gaps

- **Siren**: no `DeviceType`, HA `siren` domain not mapped — sirens cannot be represented today.
- **Fan**: no `DeviceType`, HA `fan` domain not mapped — same gap.
- **Thermostat as a distinct concept**: currently folded into `airConditioner` — there's no
  separate "thermostat-only" (no cooling/heating unit attached) representation.
- See `08_Roadmap.md` for prioritized next steps on all of the above.
