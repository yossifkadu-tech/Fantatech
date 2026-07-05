# 10 — Claude Prompts Quick Reference

> A one-line-per-topic index into the full prompts in `02_Prompt_Bible.md`. Use this file to
> quickly find the right prompt; open `02_Prompt_Bible.md` at the referenced section for the full
> copy-pasteable text and surrounding rules.

## How to Use This Index

1. Find your topic tag below.
2. Jump to the referenced section in `02_Prompt_Bible.md`.
3. Copy the fenced prompt block, fill in the `[bracketed]` placeholders, paste into Claude Code.
4. Skim `06_Development_Rules.md` first if it's your first time touching that area this session —
   most prompts assume those rules are already known, not repeated inline.

## Index

| Tag | Topic | Prompt Bible Section |
|---|---|---|
| `#dashboard` | Add/modify a home-screen dashboard section | §1.1 |
| `#card` | Device or feature card styling | §1.2 |
| `#widget` | Extract a reusable widget | §1.3 |
| `#nav` | Screen navigation wiring | §1.4 |
| `#animation` | Transitions and animations | §1.5 |
| `#material3` | Design-token / Material 3 compliance audit | §1.6 |
| `#responsive` | Phone/tablet/orientation layout | §1.7 |
| `#matter` | Matter commissioning, control, or scope questions | §2.1 |
| `#thread` | Thread network questions | §2.2 |
| `#zigbee` | Zigbee2MQTT / deCONZ device work | §2.3 |
| `#zwave` | Z-Wave client work | §2.4 |
| `#bluetooth` | BLE scanning/pairing | §2.5 |
| `#wifi` | Direct Wi-Fi-local device support | §2.6 |
| `#mqtt` | MQTT integration work | §2.7 |
| `#homeassistant` | Any HA-backed feature | §2.8 |
| `#alarm` | Alarm/security system changes | §3.1 |
| `#cameras` | Camera streaming, ONVIF, face features | §3.2 |
| `#sensors` | New sensor type or sensor classification fix | §3.3 |
| `#locks` | Smart lock features | §3.4 |
| `#sirens` | Siren support (currently a gap — see §5 of the Bible) | §3.5 |
| `#notifications` | Notification categories and delivery | §3.6 |
| `#ai-chat` | Fanta AI chat screen | §4.1 |
| `#voice` | Voice assistant / STT | §4.2 |
| `#automation-suggestions` | AI-suggested automations | §4.3 |
| `#device-recommendations` | AI device recommendations | §4.4 |
| `#scan` | Device discovery scanning | §5.1 |
| `#pair` | Device pairing flow | §5.2 |
| `#manual-add` | Manual device catalog | §5.3 |
| `#qr` | QR-code-based pairing | §5.4 |
| `#discovery-flow` | End-to-end discovery flow tracing | §5.5 |
| `#api` | Backend API placement questions | §6.1 |
| `#websocket` | WebSocket patterns (persistent vs. one-shot) | §6.2 |
| `#auth` | Authentication and session handling | §6.3 |
| `#database` | Persistence (SharedPreferences vs. Supabase) | §6.4 |
| `#docker` | Deployment/infra outside the Flutter app | §6.5 |
| `#logging` | Logging/observability | §6.6 |
| `#buttons` | `FtButton` usage | §7.1 |
| `#cards-component` | `FtCard` family usage | §7.2 |
| `#dialogs` | Confirmation/alert dialogs | §7.3 |
| `#bottom-sheets` | Modal bottom sheets | §7.4 |
| `#forms` | Text input / form screens | §7.5 |
| `#themes` | Theming and dark/light/auto mode | §7.6 |
| `#icons` | The centralized icon system | §7.7 |
| `#audit-request` | "Audit X before writing code" pattern | §8 (Prompt Library) |
| `#reorder-request` | Dashboard/list reordering with migration awareness | §8 |
| `#dedupe-request` | Find and centralize a duplicated pattern | §8 |
| `#new-enum-value` | Considering a new `DeviceType` or similar enum value | §8, `06_Development_Rules.md §9` |
| `#docs-request` | Generating/updating this documentation set | §8 |

## Frequently-Needed Combinations

Some real requests span multiple tags — chain the relevant prompt sections rather than picking
just one:

- **"Add a new smart plug brand"** → `#wifi` (discovery) + `#pair` (pairing flow) +
  `#manual-add` (catalog entry) + `#icons` (confirm `DeviceType.smartPlug` icon already covers it).
- **"Fix inconsistent lock icons across screens"** → `#dedupe-request` + `#locks` + `#icons`.
- **"Add Fan support end-to-end"** → `#new-enum-value` (assess blast radius first) + `#icons` +
  `#homeassistant` (domain mapping) — this is a multi-file rollout, not a single prompt.
- **"New dashboard widget that doesn't exist yet"** → `#audit-request` (confirm scope with the
  user before coding, per the pattern in §8) + `#dashboard` + `#reorder-request`.
