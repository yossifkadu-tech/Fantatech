# 08 — Roadmap

> Consolidates the legacy root-level `ROADMAP.md` (screen-by-screen quality audit) with the
> feature-gap analysis from this doc set. Update the tracker tables here going forward — treat
> the root `ROADMAP.md` as historical once this file is adopted.

## Table of Contents

1. [Current State Summary](#1-current-state-summary)
2. [Priority 1 — Critical (Blocking Production)](#2-priority-1--critical-blocking-production)
3. [Priority 2 — High (Quality & Performance)](#3-priority-2--high-quality--performance)
4. [Priority 3 — Medium (Commercial Readiness)](#4-priority-3--medium-commercial-readiness)
5. [Priority 4 — Low (Polish & Future-Proofing)](#5-priority-4--low-polish--future-proofing)
6. [Feature Gaps (Not Yet Discussed)](#6-feature-gaps-not-yet-discussed)
7. [Owner Tasks (Cannot Be Done by Claude)](#7-owner-tasks-cannot-be-done-by-claude)

---

## 1. Current State Summary

| Area | Status |
|---|---|
| Icon system | ✅ Centralized (`DeviceIcons`), swappable icon-set architecture |
| Dashboard layout | ✅ Reorderable, paginated, versioned migration in place |
| Localization | ⚠️ 7 locales exist; a handful of screens may still have hardcoded strings — audit needed |
| Home Assistant integration | ✅ Full WS + REST + FCM push — 9 dedicated screens |
| Matter | ⚠️ Commissioning UI works via HA delegation; no local controller, fabric mgmt, Thread, or certs |
| MQTT / WebSocket | ✅ `mqtt_client`, `ha_ws_service` |
| Supabase backend | ⚠️ Coded, not configured (needs real credentials) |
| Firebase FCM | ⚠️ Coded, not configured (needs `google-services.json` / `GoogleService-Info.plist`) |
| Marketplace / Store | ❌ Mock only (`MockMarketplaceRepository`) |
| CI/CD | ❌ No `.github/workflows/` pipeline |
| Dart Analysis | ✅ Clean, 0 errors |
| Fan / Siren device types | ❌ Not modeled at all |

## 2. Priority 1 — Critical (Blocking Production)

### P1-A: Configure Firebase FCM
**Effort:** 2–4h. Needs `google-services.json` / `GoogleService-Info.plist`, then
`flutterfire configure`, then end-to-end push test (HA → phone).

### P1-B: Configure Supabase Backend
**Effort:** 4–8h. Needs a real Supabase project, tables (`users`, `households`, `devices`,
`rooms`, `automations`, `analytics_events`), RLS policies, and build-time
`--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

### P1-C: Final Hardcoded-String Sweep
**Effort:** 1h. Grep every `screens/` file for quoted Hebrew/English literals not routed through
`s.<key>` — the security screen previously had ~5 such strings; re-check it plus any screen
touched since.

## 3. Priority 2 — High (Quality & Performance)

### P2-A: Screen Quality Audit — Remaining Screens
Apply the checklist in `07_Testing_Checklist.md §3` to every screen not yet marked audited.
Highest-impact first: `profile_screen.dart`, `gateway_connect_sheet.dart`,
`sensor_hub_screen.dart`, `camera_player_screen.dart`, `automations_screen.dart`,
`discovery_sheet.dart`.

### P2-B: Accessibility (Semantics)
**Effort:** 3–5h. Only a handful of screens have `Semantics` wrappers today. Priority order:
auth screens, home screen, device cards, security panel.

### P2-C: Remaining Legacy Color/API Issues
`.withOpacity()` → `.withValues(alpha:)` (~15 remaining instances, mostly energy/solar screens),
`Switch(activeColor:)` → `activeThumbColor`/`activeTrackColor` (~8 instances).

## 4. Priority 3 — Medium (Commercial Readiness)

### P3-A: Real Marketplace Backend
**Effort:** 8–16h. `MarketplaceRepository` interface exists; implement
`SupabaseMarketplaceRepository`, wire via DI, add a real purchase flow (`in_app_purchase` or
Stripe), enforce the existing 5-tier plan gates.

### P3-B: CI/CD Pipeline
**Effort:** 4–6h. Minimum viable: `.github/workflows/ci.yml` running `flutter analyze`,
`flutter test`, `flutter build apk --release` on push/PR.

### P3-C: Fix Pre-existing Dart Warnings
Unnecessary casts, unused imports/parameters — see root `ROADMAP.md` P3-D for the exact file
list at time of writing; re-run `flutter analyze` to get the current list.

## 5. Priority 4 — Low (Polish & Future-Proofing)

- **Matter/Thread validation** — real-device commissioning test on Android 8.1+.
- **Azure Face API production key** — `AZURE_FACE_API_KEY` / `AZURE_FACE_API_ENDPOINT`.
- **Biometric auth edge cases** — no-biometric-hardware fallback to PIN, tested on real devices.
- **Performance profiling** — frame rate with 20+ live devices, memory with 4+ ONVIF streams,
  rebuild count under MQTT burst.
- **RTL layout validation** — full pass across all screens with Hebrew/Arabic active.

## 6. Feature Gaps (Not Yet Discussed)

Features and hardening work not covered by any prior conversation, surfaced by this audit:

### Device Model Gaps
- **Fan** and **Siren** `DeviceType`s — no representation at all today; see
  `06_Development_Rules.md §9` for why this isn't a trivial add.
- **Thermostat-only** devices (climate control without an attached AC unit) — currently forced
  into `airConditioner`.
- Matter-specific device metadata (node ID, fabric ID, vendor ID) is discarded — even a read-only
  "device info" screen showing this (when HA exposes it) would be a meaningful upgrade with no
  architecture risk.

### Matter / Protocol Depth
- Real Matter fabric management / multi-admin UI (even read-only, listing HA's known fabrics).
- Thread Border Router discovery and pairing.
- OTA firmware update flow for Matter devices (BDX transfer).
- Device attestation certificate validation surfaced to the user (currently silent, HA-side only).

### Reliability / Ops
- No centralized crash reporting (Sentry/Crashlytics) — currently nothing catches and reports
  unhandled exceptions in production.
- No structured logging — `debugPrint` only, nothing persisted or shippable for support
  diagnostics.
- No automated integration tests exercising a real (or mocked) HA WebSocket connection —
  `integration_test/` exists but coverage should be confirmed.

### UX Gaps
- No in-app changelog / "what's new" screen shown after an update.
- No offline-mode indicator distinguishing "gateway unreachable" from "app has no network at all."
- No bulk device management (rename/move-room/delete multiple devices at once).
- No export/backup of the local device list + automations (useful before a factory reset or
  phone migration).

### Backend / Data
- No server-side automation engine — automations only execute while the app itself evaluates
  them (or via HA's own automation engine for HA-sourced ones); a phone-off automation for a
  purely local/manual device would not run.
- No audit log of who-did-what in a multi-user household (relevant once household member
  management matures).

## 7. Owner Tasks (Cannot Be Done by Claude)

| Task | Why | Est. Time |
|---|---|---|
| Create Supabase project + tables | Backend for auth, sync, analytics | 2–4h |
| Get Firebase project credentials | FCM push notifications | 1h |
| Get Azure Face API key | Face enrollment feature | 30min |
| Confirm Apple Developer account status | iOS build + App Store | — |
| Decide in-app purchase provider | Marketplace monetization | 1h planning |
| Set up GitHub repository secrets | CI/CD pipeline | 30min |
| Test on real Android + iOS devices | QA validation | Ongoing |
| Decide whether `backend/matter/client.js` should be wired in, or removed as dead scaffolding | Architecture decision — currently unused by the Flutter app | 30min discussion |
