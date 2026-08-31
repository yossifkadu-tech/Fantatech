---
name: matter
description: Integrate Matter devices — protocol-not-manufacturer principle, cluster-to-capability mapping, and the real commissioning flow (Wi-Fi vs Thread) with its common failure modes. Load when working on Matter commissioning or explaining Matter setup to a user.
---

# FantaTech Matter Skill

## Purpose

Integrate Matter devices.

## Rules

Matter is a protocol.

Do not associate Matter with one manufacturer.

Use device discovery and capability mapping.

Normalize Matter clusters/features into FantaTech capabilities.

Examples:

OnOff
LevelControl
ColorControl
TemperatureMeasurement
RelativeHumidityMeasurement
OccupancySensing
DoorLock
WindowCovering

Do not assume every Matter device supports every capability.

Test discovery and command execution separately.

---

## Current implementation (search here before creating anything new)

`lib/services/discovery/matter_discovery.dart` + `MatterCommissionScreen` implement real, local
Matter commissioning — genuinely brand-agnostic, unlike most other integrations in this codebase
which are one-client-per-brand.

**Matter over Wi-Fi/Ethernet vs. Matter over Thread — the #1 support question**:
- **Wi-Fi/Ethernet**: device joins the home network directly, no extra hardware, pairs via the
  setup code/QR straight into the app.
- **Thread**: needs a **Thread Border Router** to bridge onto the network — not
  FantaTech-specific hardware. Many existing home devices already act as one: Apple HomePod
  mini/TV 4K, Google Nest Hub (2nd gen+), Amazon Echo (4th gen+), IKEA DIRIGERA, Aqara Hub M2/M3,
  SmartThings Hub. Check for one of these before recommending a purchase. A plain Zigbee dongle
  (SONOFF Dongle Max, ZBDongle-P) does **not** provide Thread — different radio, don't conflate.

**Commissioning flow**: scan/enter setup code → confirm the pairing device is on the same network
the target will join (for Wi-Fi-only devices, specifically the **2.4GHz** band — most cheap
Matter/Wi-Fi devices don't support 5GHz at all, a hardware limitation not a bug) →
`MatterCommissionScreen` handles the rest.

**Common failure**: router band-steers 2.4GHz/5GHz under one SSID → device can't see/join the
network during pairing. Fix: temporarily separate 2.4GHz SSID.
