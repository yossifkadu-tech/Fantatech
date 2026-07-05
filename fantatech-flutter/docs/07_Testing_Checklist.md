# 07 — Testing Checklist

> Run through this before every release build, and before marking any non-trivial task "done."

## Table of Contents

1. [Pre-Commit Checklist](#1-pre-commit-checklist)
2. [Pre-Release Checklist](#2-pre-release-checklist)
3. [Screen Audit Checklist](#3-screen-audit-checklist)
4. [Icon/Color Consistency Checklist](#4-iconcolor-consistency-checklist)
5. [Localization & RTL Checklist](#5-localization--rtl-checklist)
6. [Manual QA Matrix](#6-manual-qa-matrix)
7. [Regression Watchlist](#7-regression-watchlist)

---

## 1. Pre-Commit Checklist

- [ ] `flutter analyze` → **0 errors** (info-level lints acceptable, don't introduce new ones on
      files you touched)
- [ ] No new hardcoded UI strings — grep the diff for quoted Hebrew/English literals in `screens/`
      and `widgets/` that aren't already inside `l10n/strings.dart`
- [ ] No new inline `Symbols.*` for a device/entity concept outside `theme/device_icons.dart`
- [ ] No new inline `Color(0xFF...)` or `Colors.*` outside `theme/app_theme.dart`
- [ ] Every new `StreamSubscription` / `WebSocket` / `HttpClient` / `AnimationController` /
      `TextEditingController` has a matching `dispose()`

## 2. Pre-Release Checklist

- [ ] `flutter analyze` clean project-wide (not just changed files)
- [ ] `flutter build apk --split-per-abi --release --no-tree-shake-icons` succeeds for all 3 ABIs
- [ ] Cold-start test: fresh install, confirm locale defaults to Hebrew and persists after
      force-quit + reopen (regression check for the locale-persistence bug)
- [ ] Dashboard order test: confirm home screen page 1/2 order matches the current
      `DashboardDefaults.home` on a device with a *pre-existing* persisted layout, not just a
      fresh install (regression check for the `syncNewItems` order-migration gap)
- [ ] Gateway connectivity smoke test: connect to at least one real HA instance, confirm device
      list populates and toggling a light reflects in HA within a few seconds
- [ ] Matter commissioning smoke test (if HA + a real/simulated Matter device available): full
      QR or manual-code flow end to end, confirm success state and that the device later appears
      in the device list
- [ ] Version bump: `pubspec.yaml` `version:` field, `AndroidManifest.xml` / `Info.plist` if
      display name changed

## 3. Screen Audit Checklist

Apply this to every screen before considering it "audited" (tracker table lives in
`08_Roadmap.md`, migrated from the legacy `ROADMAP.md`):

1. [ ] `context.watch<AppState>()` → `context.select` where only `.strings` is used
2. [ ] `Colors.grey` / `Colors.grey.shade*` → `AppColors.statusOffline`
3. [ ] `Colors.red` / `Colors.red.shade*` → `AppColors.statusAlarm`
4. [ ] `.withOpacity(x)` → `.withValues(alpha: x)`
5. [ ] `Switch(activeColor:)` → `Switch(activeThumbColor:, activeTrackColor:)`
6. [ ] `Theme.of(context).colorScheme.primary` → `AppColors.primary`
7. [ ] Hardcoded `const Color(0xFF...)` → matching `AppColors.*` token
8. [ ] `theme.cardColor` → `context.tCard`
9. [ ] `Semantics(label:, button:)` present on every interactive element

## 4. Icon/Color Consistency Checklist

When touching any screen that displays a `Device`:

- [ ] Icon comes from `DeviceIcons.icon()` or `DeviceIcons.forDevice()` — not a local switch
- [ ] Color comes from `DeviceIcons.color()` — not a local switch or hardcoded value
- [ ] If the screen shows lock/door/window/blind/motion/smoke/leak state, confirm it uses the
      state-aware variant (`forDevice`), not the static base icon
- [ ] Cross-check against `05_Device_Support.md`'s table — a mismatch here previously caused a
      real, silent color drift bug (notifications screen vs. everywhere else) that went
      unnoticed until an explicit audit

## 5. Localization & RTL Checklist

- [ ] New/changed string exists in all 7 locale blocks with an actual translation, not a copy of
      the English/Hebrew text
- [ ] RTL layout: test the screen with Hebrew or Arabic active — check `Row` ordering,
      `PositionedDirectional` usage, and that direction-sensitive icons flip correctly
- [ ] Locale switch on this screen doesn't cause a visible layout "pop" — if it's part of the main
      shell, confirm the fade-mask (`_localeFadeCtrl`) still covers it

## 6. Manual QA Matrix

| Dimension | Values to test |
|---|---|
| Screen size | Small phone (360dp), large phone (430dp), 7" tablet, 10" tablet |
| Orientation | Portrait, landscape |
| Theme | Light, Dark, Auto (ambient light), custom accent color |
| Locale | Hebrew (RTL), English (LTR), at minimum one more RTL (Arabic) and one more LTR |
| Network | Wi-Fi, cellular, offline (gateway disconnected mid-session) |
| Gateway state | HA connected, HA disconnected, no gateway configured at all |

## 7. Regression Watchlist

Bugs that were found and fixed once — verify they haven't crept back in:

- [ ] Locale resets to Hebrew on every cold start (should persist the user's choice)
- [ ] Household login shows a fake/empty member list instead of real household members
- [ ] "Exit to menu" doesn't actually clear the session (fake logout)
- [ ] Dashboard `ad_banner`/`store` or `system_status`/`home_management` order reverts on some
      devices after a code change (persisted-layout migration gap)
- [ ] `mjpeg_view.dart`-style `HttpClient` left open after leaving a camera screen
- [ ] AC quick-action duplicated across "Smart Home" banner and "Home Management" banner with no
      differentiation (should show Smart Switches on one, not AC on both)
- [ ] Notification icons/colors drifting from the canonical `DeviceIcons` mapping
