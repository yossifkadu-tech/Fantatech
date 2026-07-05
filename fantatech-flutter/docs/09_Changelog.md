# 09 — Changelog

> Derived from `git log` on the `fantatech-flutter` history. This file should be updated with
> every release going forward — treat entries below "Unreleased" as historical record, not to be
> edited retroactively.

## Table of Contents

- [Unreleased](#unreleased)
- [v2.14.x — v2.15.0](#v214x--v2150)
- [v2.13.x](#v213x)
- [v2.10.x — v2.12.x](#v210x--v212x)
- [v2.0.0 — v2.9.0](#v200--v290)
- [Pre-v2.0 (SmartHomeHub era)](#pre-v20-smarthomehub-era)

---

## Unreleased

Work completed this session, not yet tagged as a release:

- **Icon system**: centralized `DeviceIcons` service (`theme/device_icons.dart`) replacing 4x
  duplicated icon/color switches across `device_card.dart`, `devices_screen.dart` (×2), and
  `notifications_screen.dart`; fixed a real color-drift bug found in the notifications screen's
  independent copy. Added state-aware icon variants (lock, door/window open, motion detected,
  smoke/leak active, light on/off, blind position). Added `DeviceIcons.forHaDeviceClass()` for
  temperature/humidity/pressure/etc. sensor sub-kinds (previously shown as emoji text, not icons).
  Restructured into a `DeviceIconSet` strategy pattern for future icon-library swapping without
  touching call sites.
- **Localization refactor (Phase 1+2)**: persisted locale choice to SharedPreferences (previously
  reset to Hebrew on every cold start); removed dead/unused Flutter gen-l10n scaffold (8 files +
  the triggering `pubspec.yaml` flag); converted `context.watch<AppState>()` → `context.select`
  for `.strings`/`.isRtl`-only consumers across multiple files. Renamed `שומר שבת` →
  `שומר מצוות` in the Hebrew locale.
- **Dashboard fixes**: root-caused and fixed a bug where changing `DashboardDefaults.home`'s
  order values never reached devices with an already-persisted layout (`syncNewItems()` only adds
  missing items, never corrects existing order/page) — replaced ad-hoc per-field swap fixes with
  one versioned migration. Added the energy/solar/breakers widget to the dashboard (it already
  existed as a bottom sheet, just wasn't wired into the reorderable layout). Replaced a duplicated
  "Air Conditioner" quick-stat on the Smart Home banner with Smart Switches. Made several
  previously-decorative stat icons (Security banner's sensors/locks/cameras/intercoms, Smart
  Home banner's lights/switches/plugs/water-heater, System Status's internet/sensors/cameras)
  actually navigate to their respective hub screens.
- **Matter fixes**: deleted `matter_repository.dart`, a dead/unused in-memory commissioning
  simulator that was never wired into the real flow; added
  `HaGatewayClient.removeDeviceByEntity()` — a real HA device-registry removal (decommissions a
  Matter device from its fabric), wired into the device delete flow for HA-sourced devices; added
  an explicit 30s timeout to `commissionMatter()`.

## v2.14.x — v2.15.0

- Full code-quality audit pass: `Colors.grey`/`Colors.red` → semantic `AppColors.*` tokens across
  40+ screens, `context.watch` → `context.select` project-wide for strings-only consumers (137
  sites), light-mode-aware pass across all screens, theme-aware bottom sheets/dialogs/dropdowns.
- Fixed real logout bug ("exit to menu" wasn't clearing the session).
- Fixed household login to list and enter real household members (was previously fake/broken).
- DIRIGERA (IKEA) integration: pairing fix, auto-connect, import diagnostic showing all
  hub-reported devices, water-leak (and other) sensor detection by attribute rather than name.
- Live water-leak monitoring + alert.
- Prominent full-width "import devices" button on gateway cards.
- Clearer Matter device discovery guidance.
- Custom accent color mixer; "remember last email" on login.
- iOS privacy usage strings + cloud iOS build workflow.

## v2.13.x

- **v2.13.5**: removed CSS zoom hack — fixed nav visibility and header alignment.
- **v2.13.4**: user-adjustable display size + tablet threshold fix.
- **v2.13.3**: fit-to-screen scaling for any phone resolution.
- **v2.13.2**: compact phone layout — smaller nav, tighter padding, no upscaling.
- **v2.13.1**: added Philips Hue and Home Assistant import integrations.
- **v2.13.0**: SmartLife / Tuya cloud import wizard.

## v2.10.x — v2.12.x

- **v2.12.1**: `ScaleContext` template + phone layout fix.
- **v2.12.0**: Users admin page + CSV user database.
- **v2.11.1**: tablet layout — always-bottom nav, correct sizing, rotation-safe.
- **v2.11.0**: login for returning users + sign-out in Settings.
- **v2.10.3**: app display name fixed to "FantaTech" (was "Fantatech Home & Security").
- **v2.10.2**: responsive auto-fill grids — fills screen on any tablet size/rotation.
- **v2.10.1**: full-screen tablet layout + rotation-aware sidebar/bottom-nav.
- **v2.10.0**: iOS support + reactive tablet layout + screen wake lock.

## v2.0.0 — v2.9.0

- **v2.9.0**: Amazon Alexa integration via Emulated Hue Bridge.
- **v2.8.0**: full registration form + Excel user export.
- **v2.7.0**: "Classic Trio" icon (green roof, blue body, indigo shield).
- **v2.6.0**: auto-detect device language + improved language switcher.
- **v2.5.0**: orange-roof icon; removed YouTube Music tab.
- **v2.4.0**: YouTube Music player + real Gemini AI connection.
- **v2.0.0**: network scan performance — cut scan time from ~25s to ~8s (later ~8s confirmed
  stable); real QR scanner + smart switch scan + cyber security page; custom FantaTech app icon.

## Pre-v2.0 (SmartHomeHub era)

- Full multilingual i18n overhaul + header redesign (the app was originally named
  "SmartHomeHub" before rebranding to FantaTech).
- Multilingual support, cameras page, language-fix across all screens.

---

### Notable Recurring Bug Classes (for pattern-recognition, not just history)

These bug types have recurred more than once across the project's history — worth checking for
proactively during review, per `07_Testing_Checklist.md §7`:

1. **Locale/i18n regressions** — missing translations for a specific screen shipped after the
   rest of the app was already localized (SchedulerPage Hebrew strings, nav translations).
2. **Layout persistence not respecting new defaults** — code-level default changes silently not
   reaching users with existing local state (dashboard order, and historically, layout/grid
   settings).
3. **Auth session state not fully clearing** — logout-adjacent bugs appearing more than once.
4. **Device classification by name instead of attribute** — vendor-inconsistent naming causing
   misclassified sensors (recently: DIRIGERA water-leak sensors).
