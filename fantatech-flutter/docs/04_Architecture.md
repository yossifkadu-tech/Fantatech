# 04 — Architecture

> This supersedes the "Gotchas" section of the legacy `ARCHITECTURE.md` at the repo root where
> they disagree — that file predates the `DeviceIcons` centralization. Keep both in sync when
> you change one; this file is the canonical English reference.

## Table of Contents

1. [Dependency Direction](#1-dependency-direction)
2. [Folder Structure](#2-folder-structure)
3. [State Management](#3-state-management)
4. [The Icon System](#4-the-icon-system)
5. ["Where does this go?" Quick Reference](#5-where-does-this-go-quick-reference)
6. [Gotchas](#6-gotchas)
7. [Monorepo Layout](#7-monorepo-layout)
8. [Build](#8-build)

---

## 1. Dependency Direction

```
   UI            screens/  ·  widgets/
    │  reads only ↓
   State         models/  (AppState, Device, MediaModule, CustomScene)
    │  reads only ↓
   Services      services/  (discovery, gateways, cameras, auth, sensors, switches)
    │            ↓
   External      gateways · devices · cloud · local network
```

UI talks to State. State talks to Services. Services talk to the outside world. Never skip a
layer upward — a `screens/` file must not call a `services/` client directly and bypass `AppState`
for anything that other screens also need to see.

## 2. Folder Structure

| Folder | Role | Allowed | Forbidden |
|---|---|---|---|
| `lib/main.dart` | Entry point, root navigation, Provider wiring | Bootstrapping | Business logic |
| `lib/models/` | Data + global state | Data classes, `AppState` | Importing `screens/` or Flutter UI |
| `lib/screens/` | Feature UI | Rendering, `context.watch/select` | Network calls, business logic |
| `lib/widgets/` | Reusable UI components | Pure UI | Holding global state |
| `lib/services/` | Logic + network | HTTP, discovery, protocol clients | Importing `screens/` |
| `lib/theme/` | Colors, typography, icons (`app_theme.dart`, `device_icons.dart`) | Style/token definitions only | — |
| `lib/l10n/` | Strings, 7 locales (`strings.dart`) | Text only | Logic |
| `lib/providers/` | Secondary `ChangeNotifier`s (`LayoutProvider`) | State scoped to one concern | — |
| `lib/backend/` | Supabase/cloud repository interfaces | Data access abstractions | UI |

## 3. State Management

**Provider (`ChangeNotifier`)**, three app-wide providers:

| Provider | Responsibility |
|---|---|
| `AppState` | Single source of truth: devices, rooms, media, scenes, locale, security, profile |
| `GatewayManager` | Gateway connections and imports (HA, Hue, DIRIGERA, deCONZ, SmartThings, Z2M, Tuya, Ajax, PIMA, Risco, Aqara, Z-Wave, MQTT) |
| `LayoutProvider` | Dashboard/layout persistence, edit mode, per-dashboard item order/page/size |

Update flow:
```
User → Screen → state.someAction() → notifyListeners() → every watcher rebuilds
```

**Rebuild discipline**: `context.watch<AppState>()` subscribes to *every* `notifyListeners()` call
anywhere in `AppState`, not just the field you read. If a widget only needs `.strings` (or any
single field), use `context.select((AppState st) => st.field)` instead — this was a real,
project-wide refactor (137 `strings`-only `watch` calls converted to `select`). Rule of thumb:

> If `context.watch<AppState>()` uses ONLY `.strings` (or `.isRtl` alone) → convert to `select`.
> If it also reads `.devices`, `.cameras`, `.locale`, `.isRtl` *alongside other fields*, or calls
> mutator methods → it's a legitimate multi-field watch, leave it.

## 4. The Icon System

Every device/entity icon in the app routes through `theme/device_icons.dart`:

```
DeviceIcons (static facade)
   │  delegates to
   ▼
DeviceIconSet (abstract interface)
   │  default implementation
   ▼
MaterialSymbolsIconSet (Symbols.* icons)
```

This exists because the same 28-case `DeviceType → Icon/Color` switch was independently
copy-pasted in four places (`device_card.dart`, `devices_screen.dart` ×2,
`notifications_screen.dart`) — one of which had already silently drifted to different colors for
the same device types. `DeviceIcons.use(SomeOtherIconSet())` swaps the whole icon library app-wide
with zero call-site changes, if that's ever needed.

**Adding a new `DeviceType` is NOT a small change.** Before adding one, `grep` for every
`switch (device.type)` / `switch (d.type)` / `switch (type)` across the codebase — some are
`switch` *expressions* (exhaustive, compile-error on a missing case) and some are `switch`
*statements* with a `default:` (safe, silently ignore new values). As of this writing there are
14+ files with such switches; check each one. This is why Fan and Siren support was deliberately
deferred rather than added opportunistically — see `08_Roadmap.md`.

## 5. "Where does this go?" Quick Reference

1. **New data field?** → `models/` (+ getter/setter on `AppState`)
2. **New logic / network call?** → `services/`
3. **New screen / view?** → `screens/` or `widgets/`
4. **New user-facing text?** → `l10n/strings.dart` (all 7 locales, no exceptions)
5. **New color / style?** → `theme/app_theme.dart`
6. **New device/entity icon?** → `theme/device_icons.dart` (never inline)

## 6. Gotchas

- **New `DeviceType`** → see §4 above; also update `HaSyncService._domainToType()` if it should
  be reachable from Home Assistant entities.
- **New locale** → `AppLocale` enum + `strings.dart` + `supportedLocales` in `main.dart`, and
  persist it (`AppState.setLocale` writes `ft_locale` to SharedPreferences; `_initFromPrefs`
  reads it back — don't reintroduce the old "always defaults to Hebrew on cold start" bug).
- **Dashboard layout changes** → changing `DashboardDefaults.home`'s `order`/`page` values does
  **not** retroactively fix a layout a device already has persisted — `LayoutProvider
  .syncNewItems()` only *adds* missing items, it never corrects existing ones. Add a versioned
  one-time migration (`ft_home_order_migrated_v*`, bump the version) in `_migrateLayout()`.
- **Hardcoded strings** → forbidden anywhere in UI. Always `s.<key>` from
  `context.watch<AppState>().strings` or `context.select((AppState st) => st.strings)`.
- **`const`** → `const Text(s.key)` will not compile (`s.key` isn't const) — drop the `const`.
- **WebSocket connections** → a long-lived listener (`HaGatewayClient.connectLive`) and a
  short-lived one-shot admin command (`HaGatewayClient._wsCommand`) are different patterns for
  different needs — don't conflate them (see `02_Prompt_Bible.md §6.2`).

## 7. Monorepo Layout

`fantatech-flutter/` is one part of a larger `smarthome-hub/` monorepo:

| Path | Purpose | Wired into the Flutter app? |
|---|---|---|
| `fantatech-flutter/` | This app | — |
| `backend/matter/client.js` | Node.js WebSocket bridge to `python-matter-server` | **No** — Matter commissioning goes through Home Assistant instead; confirm with the user before assuming this is the live path |
| `backend/` (Express + node_modules) | General backend scaffolding | Partial — check current usage before relying on it |
| `mosquitto/` | MQTT broker config | Indirectly, via `mqtt_client` connections |
| `gateway/`, `hub/`, `raspberry-pi/` | Deployable hub-side components | Not directly imported by the Flutter app |
| `zigbee2mqtt/` | Zigbee2MQTT config | Consumed via `z2m_client.dart`'s REST calls |
| `docs/` (repo root) | Legacy `.docx` documentation, changelog, analytics | Superseded by `fantatech-flutter/docs/` (this doc set) for anything about the app itself |

## 8. Build

```bash
flutter analyze                                     # must be 0 errors before any build
flutter build apk --split-per-abi --release --no-tree-shake-icons
# output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
