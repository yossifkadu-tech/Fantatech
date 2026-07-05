# 03 — UI Design Guide

> Source of truth: `lib/theme/app_theme.dart` and `lib/theme/device_icons.dart`. This document
> explains the *why* behind the tokens; the code is the *what*. If they ever disagree, the code
> wins — update this doc, don't fight the code.

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Color System](#2-color-system)
3. [Typography Scale](#3-typography-scale)
4. [Spacing Scale](#4-spacing-scale)
5. [Border Radius](#5-border-radius)
6. [Shadows & Elevation](#6-shadows--elevation)
7. [Icons](#7-icons)
8. [Component Patterns](#8-component-patterns)
9. [Dark / Light / Auto Theme](#9-dark--light--auto-theme)
10. [RTL & Localization Layout Rules](#10-rtl--localization-layout-rules)

---

## 1. Design Philosophy

FantaTech follows **Material Design 3** as an icon/interaction baseline, but with a fully custom
visual identity layered on top via design tokens — it does not look like a stock Material app.
Every color, spacing value, radius, and shadow used anywhere in the UI must trace back to a named
token in `theme/app_theme.dart`. This is enforced, not aspirational — see `06_Development_Rules.md`.

## 2. Color System

### Brand

| Token | Hex | Use |
|---|---|---|
| `AppColors.primary` | `#FF6B00` | Signature orange — CTAs, active states, brand accents |
| `AppColors.primaryDark` | `#CC6200` | Pressed state |
| `AppColors.primaryLight` | `#FF9533` | Hover / light variant |
| `AppColors.secondary` | `#003399` | Dark blue accent/CTA |

### Semantic Status

| Token | Hex | Meaning |
|---|---|---|
| `AppColors.success` / `secured` | `#16A34A` | Armed, on, healthy |
| `AppColors.warning` | `#D97706` | Needs attention |
| `AppColors.alert` / `unsecured` / `danger` | `#DC2626` | Disarmed, danger, destructive action |

### Six-State Device Status Palette

Every `Device.status` (`online / offline / warning / alert / alarm / info`) maps through
`AppStatusColors`, never a raw color:

```dart
AppStatusColors.dot(device.status)        // vivid dot/icon color
AppStatusColors.surface(device.status)    // light-theme pastel chip background
AppStatusColors.darkSurface(device.status)// dark-theme translucent chip background
AppStatusColors.adaptiveSurface(status, context) // picks the right one automatically
AppStatusColors.icon(device.status)       // representative Symbols icon
```

| Status | Dot color | Icon |
|---|---|---|
| online | `#26A69A` turquoise | `Symbols.check_circle` |
| offline | `#757575` gray | `Symbols.wifi_off` |
| warning | `#FB8C00` orange | `Symbols.warning` |
| alert | `#FFD54F` yellow | `Symbols.notifications_active` |
| alarm | `#E53935` red | `Symbols.crisis_alert` |
| info | `#1E88E5` blue | `Symbols.info` |

### Device-Type Accent Colors

These pair 1:1 with `DeviceIcons.icon()` via `DeviceIcons.color()` — see `05_Device_Support.md`
for the full table. Never assign a device-type color inline; always call `DeviceIcons.color(type)`.

### Adding a New Color Token

```dart
// theme/app_theme.dart, inside AppColors — one line, one comment:
static const fooColor = Color(0xFF112233); // short description of what it represents
```
Never add a raw `const Color(0xFF...)` at a call site "just this once" — it will drift the moment
a second screen needs the same color and copies the hex instead of the token.

## 3. Typography Scale

`AppTypography` — Display → Headline → Title → Subtitle → Body → Caption/Label, each in
Large/Medium/Small. Always use the named style + `.copyWith(color: ...)`, never a raw `TextStyle`:

```dart
Text('18.7 kWh', style: AppTypography.displaySm.copyWith(color: context.tText))
```

| Tier | Size | Weight | Use |
|---|---|---|---|
| `displayLg/Md/Sm` | 48/36/28 | 800/800/700 | Hero numbers, bento tiles |
| `headlineLg/Md/Sm` | 24/20/18 | 700/700/600 | Screen titles |
| `titleLg/Md/Sm` | 16/14/13 | 600 | Card titles, section headers |
| `subtitleLg/Md` | 15/13 | 500 | Secondary text under a title |
| `bodyLg/Md/Sm` | 15/13/12 | 400 | Paragraph text |
| `caption`, `labelLg/Md/Sm` | 11/13/11/10 | 500/700/700/600 | Chips, badges, tiny UI text |

## 4. Spacing Scale

`AppSpacing` — **only** these values anywhere in the app: `s4 s8 s12 s16 s20 s24 s32 s48`.
Common `EdgeInsets` shortcuts: `p4/p8/p12/p16/p24/p32`, `h16/h24`, `v8/v16`, `card` (16 all),
`cardLg` (24 all), `screen` (16 horizontal / 8 vertical). Never write `EdgeInsets.all(17)` or
similar arbitrary numbers.

## 5. Border Radius

`AppBorderRadius` — raw radii `r4 r8 r12 r16 r20 r24`, and semantic shortcuts:

| Token | Radius | Use |
|---|---|---|
| `card` | 16 | Standard card |
| `cardLg` | 20 | Hero banners |
| `chip` | 24 | Pills, badges |
| `button` | 12 | Buttons |
| `input` | 12 | Text fields |
| `sheet` | 24 top corners only | Bottom sheets |

## 6. Shadows & Elevation

`AppShadows.sm/md/lg/xl` — pre-built `List<BoxShadow>` for increasing elevation. For an active/on
device's colored glow, use `AppShadows.glow(color, intensity: 1.0)` rather than a manual
`BoxShadow` — it already tunes alpha/blur/spread to look correct against both themes.

## 7. Icons

Full detail in `05_Device_Support.md` and `02_Prompt_Bible.md §7.7`. Summary rules:

- **Library**: `package:material_symbols_icons` (`Symbols.*`) exclusively — never `Icons.*`,
  never an emoji character standing in for an icon.
- **Source**: `theme/device_icons.dart`'s `DeviceIcons` — never an inline per-screen switch.
- **State-awareness**: use `DeviceIcons.forDevice(device)` wherever a live `Device` is available,
  so locked/unlocked, open/closed, on/off, and similar states render the correct variant
  automatically.
- **Swappability**: the whole icon set is behind `DeviceIconSet` — implementing a new icon pack
  never requires touching call sites (see `04_Architecture.md`).

## 8. Component Patterns

### Hero Banner (dashboard cards: Security, Smart Home, Home Management, Store, Media)

```
Padding(horizontal: 16)
  └─ Semantics(button: true, label: ...)
       └─ GestureDetector(onTap: → full screen)
            └─ Container(gradient, AppBorderRadius.cardLg, boxShadow: 2-layer colored shadow)
                 └─ Column
                      ├─ Row: icon avatar (circle, white 15% overlay) + title/status text +
                      │        optional gear button + chevron circle
                      └─ optional stats strip: Container(black 20% overlay, AppBorderRadius.card)
                                                 Row of stat mini-widgets, each independently
                                                 tappable → its own hub screen
```

### Device Card (grid tile)

See `02_Prompt_Bible.md §1.2` — icon/color from `DeviceIcons`, glow only when
`isOn && !offline && !alerted`, battery/signal badges hidden when null.

### Bottom Sheet

`showModalBottomSheet` + `context.tCard` background + `FtModalHandle` drag handle + rounded top
corners (22 compact / 24-28 full). Use `DraggableScrollableSheet` for variable-height content.

## 9. Dark / Light / Auto Theme

Three modes: Light, Dark, Auto (ambient-light sensor-driven via the `light` package). Users can
also pick a custom accent color (color mixer in settings) instead of the default orange. Always
read colors through `context.tText / .tCard / .tBorder / .tTextSecondary / .isLight` so a screen
automatically respects whichever mode + custom accent is active — never branch on
`Theme.of(context).brightness` directly in feature code.

## 10. RTL & Localization Layout Rules

The app supports 7 locales; Hebrew and Arabic are RTL. Rules:

- Use `PositionedDirectional` / `EdgeInsetsDirectional` / `AlignmentDirectional` instead of their
  non-directional counterparts wherever left/right matters.
- Icons that encode direction (e.g. back-chevron) must flip per `state.isRtl` — see
  `FtBackButton` for the canonical pattern (`Symbols.chevron_right` in RTL, `chevron_left` in LTR).
- Never hardcode `TextDirection.ltr` for user-facing text — derive it from `state.isRtl`.
- A locale switch must not cause a jarring instant layout flip — see the `_localeFadeCtrl` mask
  pattern in `main.dart` (`04_Architecture.md` has the full explanation).
