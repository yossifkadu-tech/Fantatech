# 01 — FantaTech Product Requirements Document (PRD)

> **Status:** Living document — reflects the actual state of the codebase as of v2.15.0.
> **Scope:** `fantatech-flutter/` — the FantaTech Smart Home & Security mobile app.

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Target Users](#2-target-users)
3. [Platform Support](#3-platform-support)
4. [Core Feature Areas](#4-core-feature-areas)
5. [Monetization — 5-Tier Plan Model](#5-monetization--5-tier-plan-model)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Out of Scope (Explicitly)](#7-out-of-scope-explicitly)

---

## 1. Product Vision

FantaTech is a single Flutter app that unifies smart-home control and home security under one
roof, for a household that owns devices from multiple ecosystems (Wi-Fi, Zigbee, Z-Wave, Matter,
cloud-based brands) and multiple hub brands (Home Assistant, IKEA DIRIGERA, deCONZ, Hue Bridge,
SmartThings, Zigbee2MQTT). The app does not require the user to pick one ecosystem — it imports
and controls devices across all of them from one dashboard, in Hebrew-first but fully
multi-locale UI.

## 2. Target Users

- Israeli households (Hebrew-first UX, Shabbat-mode automation, Hebrew calendar in the scheduler)
  who also need English/Arabic/Amharic/Spanish/Russian/French support for mixed-language homes.
- Users who already own a hub (HA, DIRIGERA, deCONZ, SmartThings) and want one polished mobile
  front-end instead of juggling 4 separate vendor apps.
- Users buying their first smart-home devices, guided through discovery/pairing without needing
  to know which protocol a device speaks.

## 3. Platform Support

| Platform | Status |
|---|---|
| Android | Primary target — `flutter build apk --split-per-abi` |
| iOS | Supported — cloud build workflow configured (`.github/workflows`) |
| Web | Present (`web/` dir exists) but not the primary target; used for Claude Preview testing only |

## 4. Core Feature Areas

Each area below is documented in depth in its own guide — this is the index.

| Area | Summary | Detail doc |
|---|---|---|
| Dashboard & Home | 2-page swipeable dashboard, drag-to-reorder edit mode, per-item resize/rename | `03_UI_Design_Guide.md` |
| Smart Home control | Lights, blinds, AC, plugs, switches, sensors, water heater, intercom — grouped by category | `05_Device_Support.md` |
| Security | Arm/disarm, zones, locks, sensors, event log, live camera grid | `02_Prompt_Bible.md §3` |
| Cameras | ONVIF / RTSP / MJPEG live view, motion log, face enrollment + Azure Face API analysis | `05_Device_Support.md` |
| Energy & Solar | Consumption tracking, solar production/battery/savings, circuit breaker panel | `02_Prompt_Bible.md §2` |
| Automations | Rule builder, HA automation import, weekly visual scheduler with Hebrew-calendar holidays | `02_Prompt_Bible.md §2` |
| Rooms | Per-room device grouping and control | `04_Architecture.md` |
| Media | Speaker/cast device control, now-playing | `02_Prompt_Bible.md §1` |
| AI Assistant (Fanta AI) | Chat-style assistant, suggestion cards, on-device STT voice control | `02_Prompt_Bible.md §4` |
| Store / Marketplace | Product catalogue synced from fantatech.co.il, plan-gated purchases | `08_Roadmap.md` (backend not yet live) |
| Auth & Household | Login/register, biometric unlock, household member management, PIN | `02_Prompt_Bible.md §6` |
| Notifications | In-app + Firebase Cloud Messaging push, filtered by category | `02_Prompt_Bible.md §3` |
| Home Assistant deep integration | 9 dedicated HA-specific screens (dashboard, rooms, security, cameras, automations, push settings) mirroring HA's own UI inside FantaTech | `05_Device_Support.md` |
| Matter commissioning | QR/manual pairing UI, delegated to HA's Matter integration | `05_Device_Support.md` |
| Theme customization | Light/Dark/Auto, custom accent color mixer, ambient-light auto-theme | `03_UI_Design_Guide.md` |
| Localization | 7 locales: Hebrew (default), English, Arabic, Amharic, Spanish, Russian, French — full RTL support | `06_Development_Rules.md` |

## 5. Monetization — 5-Tier Plan Model

The app enforces a 5-tier subscription model (referenced throughout `profile_screen.dart` and the
store). Plan-gated features include marketplace purchases and premium automation/AI capabilities.
Exact tier names and price points live in `models/app_state.dart` (`userPlan`) — treat that as the
source of truth, not this document, since pricing changes independently of features.

## 6. Non-Functional Requirements

- **Zero `flutter analyze` errors** before any release build (info-level lints tolerated, tracked
  as tech debt — see `07_Testing_Checklist.md`).
- **No hardcoded UI strings** — every user-facing string goes through `S` (`l10n/strings.dart`)
  across all 7 locales.
- **State management discipline** — `AppState` is the single source of truth; UI never holds
  device data locally (see `04_Architecture.md`).
- **Graceful degradation** — unconfigured backends (Supabase, Firebase, Azure Face API) must
  no-op silently rather than crash.

## 7. Out of Scope (Explicitly)

- FantaTech is **not** a certified Matter Controller. It delegates Matter commissioning to Home
  Assistant's own Matter integration rather than embedding a Matter SDK. See `05_Device_Support.md`
  for the full gap analysis.
- The Flutter app does not implement its own automation execution engine for non-HA devices;
  scenes/automations for directly-connected devices are evaluated client-side only.
