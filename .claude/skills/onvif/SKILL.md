---
name: onvif
description: Support IP security cameras via ONVIF/RTSP, kept independent of the smart-device core — the real generic (brand-agnostic) implementation, why camera support isn't per-brand, and discovery-scan safety. Load when working on camera discovery/streaming, or explaining which camera brands are supported.
---

# FantaTech ONVIF Skill

## Purpose

Support IP security cameras.

Capabilities may include:

- discovery
- device information
- profiles
- video
- PTZ
- events
- snapshots

Where appropriate support RTSP for media streams.

Security:

Never log camera username/password.

Never display credentials in error messages.

Prefer secure local communication where supported.

Camera integration must remain independent of the smart-device core.

---

## Current implementation (search here before creating anything new)

`lib/services/cameras/onvif_service.dart` (+ `onvif_ptz_service.dart`) implement the **ONVIF
protocol** generically — WS-Discovery (UDP multicast, `239.255.255.250:3702`), SOAP
`GetStreamUri`, and a port-scan fallback (80/554/8080/8081/8554). Camera brand support is
therefore protocol-level, not name-specific: any ONVIF-compliant camera works (Reolink,
Hikvision, Dahua, Tapo, Amcrest, Foscam, others) because they all speak the standard — this is
already exactly the "independent of the smart-device core" boundary the rule above asks for:
**cameras use a separate `Camera` model, not `Device`**, and are not routed through
`DeviceCommander` or the device-adapter platform. Don't assume camera work follows the same
patterns as light/switch/sensor integration.

**Brand-name matching elsewhere is UI convenience, not integration**: `add_device_screen.dart`'s
barcode/name-resolver recognizes strings like "reolink"/"hikvision"/"tapo" purely to route a
scanned label to the generic `'camera'` catalog category — don't cite it as evidence a specific
brand has dedicated support.

**Non-ONVIF camera clients present but not fully wired**: `arlo_client.dart`, `eufy_client.dart`,
`nest_cam_client.dart`, `ring_client.dart`, `wyze_client.dart` exist under `services/cameras/` for
their respective cloud APIs — verify current wiring status before assuming any is live
end-to-end.

**Discovery scan safety**: WS-Discovery is one-shot (5s timeout, socket closed after) — safe by
design already. If extending camera discovery, keep it user-initiated and bounded; see the
`security` skill's network-flood note for why unbounded/auto-triggered subnet scans are a real
(if minor) risk pattern already found once in this codebase.
