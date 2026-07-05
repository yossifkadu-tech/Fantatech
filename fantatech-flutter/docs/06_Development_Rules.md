# 06 — Development Rules

> Non-negotiable rules for anyone (human or Claude) making changes to `fantatech-flutter/`.
> If a request conflicts with one of these, flag the conflict and ask before proceeding — don't
> silently choose one over the other.

## Table of Contents

1. [Standing Project Mandate](#1-standing-project-mandate)
2. [Coding Standards](#2-coding-standards)
3. [Naming Conventions](#3-naming-conventions)
4. [State Management Rules](#4-state-management-rules)
5. [Localization Rules](#5-localization-rules)
6. [Icon & Color Rules](#6-icon--color-rules)
7. [Performance Guidelines](#7-performance-guidelines)
8. [UI Consistency Rules](#8-ui-consistency-rules)
9. [The Exhaustive-Switch Trap](#9-the-exhaustive-switch-trap)
10. [Git / Safety Rules](#10-git--safety-rules)

---

## 1. Standing Project Mandate

- **Do not rebuild the application.** Keep the current UI. Do not break existing code. Generate
  production-ready Flutter code only.
- Do not remove business logic, translations, MQTT, WebSocket, or Home Assistant integration.
- No duplicated widgets — create reusable widgets/themes where sensible (see `04_Architecture.md`
  for where things belong).
- Never commit, push, or open a PR without explicit confirmation of scope.
- When a request is ambiguous, or could have broad/destructive consequences, **stop and ask**
  rather than guessing.

## 2. Coding Standards

- `flutter analyze` must report **0 errors** before any build is considered done. Info-level
  lints are tracked as tech debt (`07_Testing_Checklist.md`), not blockers.
- Every new file needs the same license/import-order conventions as its neighbors — check 2-3
  sibling files before adding a new one.
- Don't introduce a new dependency for something an existing dependency already does (e.g. don't
  add a second HTTP client, a second MQTT package, a second QR scanner).

## 3. Naming Conventions

- Screens: `feature_name_screen.dart`, class `FeatureNameScreen`.
- Hub screens for a device category: `category_hub_screen.dart` (e.g. `lights_hub_screen.dart`,
  `smart_lock_hub_screen.dart`).
- Gateway clients: `brand_client.dart` under `services/gateways/clients/`, class `BrandClient`
  with static methods (matches `HaGatewayClient`'s pattern).
- Private widgets local to one screen: `_PascalCase`, defined below the screen's main class in
  the same file — don't promote a screen-local widget to `widgets/` unless it's reused elsewhere.
- Localization keys: `camelCase`, prefixed by feature when ambiguous (`aiSugDesc1`, `matterCommTitle`,
  `breakersTitle`).

## 4. State Management Rules

- `AppState` is the single source of truth for devices, rooms, media, scenes, locale, security
  mode, and user profile. A screen's local `State` object may hold *UI-only* state (e.g. which
  tab is selected, text field controllers) — never device/business data.
- All mutation goes through an `AppState` method (`toggleDevice`, `setLocale`, `addAutomation`,
  etc.) — never `device.isOn = true` directly from a screen.
- `context.watch<AppState>()` vs `context.select(...)`:
  - Only `.strings` (or `.isRtl` alone) needed → `context.select((AppState st) => st.field)`.
  - Multiple fields, or calling a mutator method → legitimate `context.watch<AppState>()`.
- `LayoutProvider` changes to `order`/`page` in `DashboardDefaults` do **not** retroactively apply
  to devices with an already-persisted layout — `syncNewItems()` only adds missing items. Any
  order/page change needs an accompanying versioned migration in the relevant screen's
  `_migrateLayout()`.

## 5. Localization Rules

- **7 locales**, in this exact order everywhere they're enumerated: Hebrew (default), English,
  Arabic, Amharic, Spanish, Russian, French.
- No hardcoded UI string, ever — always `s.<key>` from `S` (`l10n/strings.dart`).
- Adding a string: add the `final String` field, add it to the `required this.x` constructor
  list, and add a value in **all 7** locale blocks in the same commit — a missing locale value
  is a compile error (the constructor requires it), so this is self-enforcing, but don't rely on
  the compiler alone — actually translate, don't copy the English string into all 7 slots.
- Locale persistence: `AppState.setLocale()` writes to SharedPreferences (`ft_locale` key,
  storing the enum's `.name`); `_initFromPrefs()` reads it back **before** any logic that depends
  on locale (e.g. Shabbat-mode auto-enable). Don't reorder `_initFromPrefs()` without checking
  this dependency.
- RTL: see `03_UI_Design_Guide.md §10`.

## 6. Icon & Color Rules

- Every device/entity icon: `DeviceIcons.icon()` / `.color()` / `.forDevice()` /
  `.forHaDeviceClass()` / `.lockIcon()` / `.blindIcon()` / `.batteryIcon()` — never inline
  `Symbols.*` for a device concept, never an emoji standing in for an icon.
- Every color: a named `AppColors.*` token or a `context.t*` theme-aware accessor — never a raw
  `Colors.*` or an inline `Color(0xFF...)` at a call site.
- Before "fixing" an icon ternary that looks inconsistent, check whether it's an **action icon**
  (showing what tapping will do) rather than a **state icon** (showing current state) — these are
  legitimately opposite and must not be merged. Example: a "Lock" button shown while unlocked
  correctly displays a closed-lock icon (the action), while a state badge showing "currently
  unlocked" correctly displays an open-lock icon (the state) — same two icons, opposite mapping,
  both correct.

## 7. Performance Guidelines

- Prefer `context.select` over `context.watch` per §4 — this is the single biggest rebuild-count
  lever in this codebase (137 sites were converted in one pass with measurable jank reduction).
- Dispose every `HttpClient`, `StreamSubscription`, `WebSocket`, `AnimationController`, and
  `TextEditingController` in the owning widget's `dispose()`. A real leak (`mjpeg_view.dart`'s
  `HttpClient`) was found and fixed once — don't reintroduce the pattern.
- Avoid opening a new persistent WebSocket connection for a one-shot admin command — use a
  short-lived connect→send→await→close pattern instead (see `HaGatewayClient._wsCommand`).
- Batch related `setState`/`notifyListeners` calls — don't call `notifyListeners()` multiple times
  in the same synchronous block when one call at the end would do.

## 8. UI Consistency Rules

- All device/feature icons and colors flow through one central service — see `06.6` above and
  `04_Architecture.md §4`.
- All spacing/radius/shadow/typography values come from `AppSpacing` / `AppBorderRadius` /
  `AppShadows` / `AppTypography` — no arbitrary numeric literals in layout code.
- Hero banner cards, bottom sheets, dialogs, and buttons each have ONE canonical pattern (see
  `03_UI_Design_Guide.md §8` and `02_Prompt_Bible.md §7`) — match it, don't invent a variant
  per screen.

## 9. The Exhaustive-Switch Trap

Dart's `switch` used as a **value-returning expression** (arrow syntax, or a getter body that
returns from every branch with no `default`) requires exhaustive coverage of an enum — adding a
new enum value breaks compilation everywhere such a switch exists, until every one is updated.
`switch` used as a **statement** with a `default:` clause is safe to extend silently.

Before adding a new `DeviceType` (or any other enum used widely, e.g. `GatewayType`,
`DeviceStatus`):
1. `grep -rn "switch (.*\.type)" lib/` (adjust for the specific enum/variable name).
2. Classify each match: exhaustive expression (must fix) vs. statement-with-default (safe).
3. Only then decide whether the addition is a small change or a multi-file rollout.

This is why Fan/Siren support was deliberately deferred rather than added opportunistically while
building the icon system — the blast radius (14+ files) wasn't assessed as in-scope for what was
requested as an icon-mapping task.

## 10. Git / Safety Rules

- Never `git add -A` / `git add .` — stage files explicitly.
- Never force-push, never `git reset --hard`, never skip hooks, without explicit user request.
- Never commit or push without the user explicitly asking for that specific action in that turn.
- If `git status` reveals unexpected state (mass deletions of unrelated projects, hundreds of
  never-committed files that are clearly in active use) — **stop and report it**, don't attempt
  to "fix" the repo state unprompted. This exact situation occurred once in this project; the
  correct response was to report findings and wait, not to guess and act.
