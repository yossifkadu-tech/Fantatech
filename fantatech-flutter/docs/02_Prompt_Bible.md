# 02 — FantaTech Prompt Bible

> **The official prompt reference for building FantaTech with Claude Code.**
> Every prompt below is written to be copy-pasted directly into a Claude Code session in the
> `fantatech-flutter/` repo. They assume the standing project rules in `06_Development_Rules.md`
> are already in force (do not repeat them in every prompt — they're implicit).

## Table of Contents

1. [UI / UX Prompts](#1-ui--ux-prompts)
2. [Smart Home](#2-smart-home)
3. [Security](#3-security)
4. [AI Assistant](#4-ai-assistant)
5. [Device Discovery](#5-device-discovery)
6. [Backend](#6-backend)
7. [Flutter Components](#7-flutter-components)
8. [Prompt Library — Past Requests Converted](#8-prompt-library--past-requests-converted)
9. [Best Practices](#9-best-practices)
10. [Missing Features](#10-missing-features)

---

## 1. UI / UX Prompts

### 1.1 Dashboard

```text
Add a new dashboard section to the home screen following the existing ReorderableDashboard
pattern (widgets/edit_mode/reorderable_dashboard.dart). Requirements:
- Add a new LayoutItem to DashboardDefaults.home with a unique id/type, correct page (0 or 1),
  and an order value that doesn't collide with existing items.
- Add name/icon entries to DashboardDefaults.nameOf / .iconOf.
- Add the new type to home_screen.dart's _buildItem() switch, returning the new banner widget.
- Add a one-time migration in _migrateLayout() (bump the ft_home_order_migrated_v* key) so
  existing installs pick up the new item and correct ordering — syncNewItems() only ADDS new
  items, it never fixes order/page on already-persisted layouts.
- The new banner must follow the existing hero-card pattern: gradient Container, icon avatar,
  title + status line, optional stats strip, chevron, single GestureDetector wrapping the whole
  card that navigates to the feature's full screen.
- Do NOT touch Phase 3 concerns (AppState splitting, the locale fade overlay) unless asked.
```

### 1.2 Cards

```text
Create/modify a device or feature card following the existing DeviceCard pattern
(widgets/device_card.dart). Requirements:
- Icon and accent color MUST come from theme/device_icons.dart (DeviceIcons.forDevice /
  DeviceIcons.color) — never hardcode a Symbols.* icon or AppColors.* value inline.
- Status glow: showGlow = isOn || isAlerted || status.isAlert, gradient uses color at 0.15/0.04
  alpha, border at 0.42 alpha when glowing.
- Respect DeviceStatus (online/offline/warning/alert/alarm) via the existing _cardColor switch
  pattern — offline always renders desaturated regardless of isOn.
- Support optional battery badge (DeviceIcons.batteryIcon) and signal bars — both hidden when
  the underlying value is null, never shown as "0".
```

### 1.3 Widgets

```text
Extract [describe the repeated UI] into a reusable widget in lib/widgets/. Requirements:
- Check first whether an equivalent already exists (FtButton, FtCard, StatusDot, StatusChip,
  FtSectionHeader, FtIconBadge, FtBackButton, FtModalHandle, FtScreenHeader) — reuse instead of
  duplicating.
- Pure UI only — no context.watch<AppState>() inside a widget meant for reuse across screens
  with different state needs; accept data via constructor params instead.
- Theme-aware: use context.tText / context.tCard / context.tBorder / context.isLight, never
  Theme.of(context).colorScheme.* or hardcoded Colors.*.
```

### 1.4 Navigation

```text
Add a new screen and wire its navigation. Requirements:
- Use FtScreenHeader (widgets/ft_nav.dart) for the standard back-button + centered title pattern
  unless the screen needs a custom app bar.
- Navigate via Navigator.push(context, MaterialPageRoute(builder: (_) => const NewScreen())) —
  this app does not use go_router for screen-to-screen navigation despite it being a dependency
  (go_router is present in pubspec.yaml but the actual navigation pattern is MaterialPageRoute;
  confirm current usage before assuming go_router is wired up).
- If the screen is reachable from a dashboard banner, wrap the whole banner in one
  GestureDetector — do not add per-element taps that fight with the card-level tap.
```

### 1.5 Animations

```text
Add a transition/animation to [widget]. Requirements:
- Prefer AnimatedContainer / AnimatedSize / AnimatedSwitcher over manual AnimationController
  unless you need precise control (e.g. the existing _localeFadeCtrl pattern in main.dart).
- Standard duration: 200ms for micro-interactions (button press, selection), 300ms for card
  state changes, 400ms for icon/avatar transitions matching AC hub existing patterns.
- Curve: Curves.easeOutCubic for entrance, Curves.easeInOut for size changes.
- Never animate a locale/RTL change with a full subtree rebuild — mask with an overlay fade
  (see main.dart's _triggerLocaleFlash pattern) instead of remounting widgets.
```

### 1.6 Material 3

```text
Audit [screen] for Material 3 / design-token compliance. Replace:
- Colors.grey / Colors.grey.shade* → AppColors.statusOffline
- Colors.red / Colors.red.shade* → AppColors.statusAlarm
- .withOpacity(x) → .withValues(alpha: x)
- Switch(activeColor:) → Switch(activeThumbColor:, activeTrackColor:)
- Theme.of(context).colorScheme.primary → AppColors.primary
- hardcoded const Color(0xFF...) → the matching AppColors.* token (add a new token to
  theme/app_theme.dart if none matches — do not invent a new raw hex inline)
- theme.cardColor → context.tCard
Icons must come from package:material_symbols_icons (Symbols.*) exclusively — never the built-in
Icons.* class, and never a raw emoji character in place of an icon.
```

### 1.7 Responsive Layout

```text
Make [screen] responsive across phone/tablet and portrait/landscape. Requirements:
- Wrap screen content in OrientationBuilder where the home_screen.dart pattern already does this
  (landscape centers content in a 600px-max ConstrainedBox).
- Use MediaQuery.of(context).viewInsets.bottom for bottom-sheet keyboard avoidance, not a fixed
  padding value.
- Test at minimum: small phone (360dp width), large phone (430dp), 7" tablet, 10" tablet, both
  orientations. Do not assume a single fixed grid column count — use LayoutBuilder or
  MediaQuery.size.width breakpoints matching existing tablet threshold logic.
```

---

## 2. Smart Home

### 2.1 Matter

```text
[Any Matter-related change] — before writing code, re-read 05_Device_Support.md's Matter section.
Ground rules:
- FantaTech does NOT embed a Matter SDK. All commissioning goes through
  HaGatewayClient.commissionMatter() → HA's /api/services/matter/commission_with_code.
- Never reintroduce a local "simulated commissioning" fallback — it was deleted from
  matter_repository.dart specifically because it silently faked success with no real device.
- Device removal/decommissioning MUST call HaGatewayClient.removeDeviceByEntity() (HA device
  registry removal), not just AppState.removeDevice() (which only removes it from the local
  list — HA would just re-sync it back).
- If a task requires real Thread/fabric/certificate support, stop and flag it as a Priority-3
  architecture decision (embedding python-matter-server or a native SDK) — do not attempt it as
  a routine code change.
```

### 2.2 Thread

```text
Thread support does not exist beyond mDNS recognition of Thread-capable devices
(services/discovery/matter_discovery.dart). Do not implement Thread Border Router pairing,
credential exchange, or radio management without first confirming the phone/target platform can
actually access a Thread radio — most consumer Android/iOS devices cannot without a paired
Border Router SDK. Treat any Thread request as a research spike, not a direct implementation task.
```

### 2.3 Zigbee

```text
Add/modify Zigbee device support via [Zigbee2MQTT | deCONZ]. Requirements:
- Zigbee2MQTT devices go through services/gateways/clients/z2m_client.dart (REST over the
  Zigbee2MQTT HTTP API, not raw MQTT from the Flutter app).
- deCONZ devices go through services/gateways/clients/deconz_client.dart.
- New device types must be classified by attribute inspection (see the water-leak sensor fix:
  detecting sensor type by reported attribute rather than trusting the device name), because
  Zigbee vendors report inconsistent device_class/model strings.
- Map to the existing DeviceType enum — do not invent a parallel type system for Zigbee-specific
  concepts.
```

### 2.4 Z-Wave

```text
Z-Wave support exists via services/gateways/clients/zwave_client.dart. Before extending it,
read the existing client fully — confirm whether it talks to a Z-Wave JS UI instance or a
different bridge, and match its existing request/response pattern exactly rather than
introducing a second HTTP client style in the same file.
```

### 2.5 Bluetooth

```text
Add BLE-based device support using flutter_blue_plus (already a dependency). Requirements:
- BLE scanning must request runtime permissions via permission_handler first — check
  services/discovery/ for the existing scan-engine permission-request pattern before adding a
  new one.
- Never hold a BLE connection open longer than the active screen — dispose it in the screen's
  dispose() to avoid battery drain and the kind of leak fixed in mjpeg_view.dart's HttpClient.
```

### 2.6 Wi-Fi

```text
Add support for a new Wi-Fi-local device brand (Shelly/Sonoff/Tapo-style). Requirements:
- Discovery happens via direct LAN scan (services/discovery/), not cloud — match the existing
  smart_switch_scanner.dart pattern (subnet sweep + protocol-specific probe).
- Control happens via the device's local HTTP/CoAP API directly from the phone — do not route
  Wi-Fi-local device control through any cloud service.
- Encryption: if the brand uses Tuya Local Protocol 3.3, reuse services/gateways/clients/
  tuya_cloud_client.dart's AES-128-ECB pattern (encrypt/pointycastle packages already added)
  rather than adding a new crypto dependency.
```

### 2.7 MQTT

```text
Add an MQTT-based integration. Requirements:
- Use mqtt_client (already a dependency, v10.2.1) — do not add a second MQTT package.
- Route through services/gateways/clients/mqtt_gateway_client.dart if the integration is
  gateway-shaped (multiple devices behind one broker connection); create a narrowly-scoped new
  service only if it's a single-purpose one-off.
- Always handle broker disconnect/reconnect explicitly — MQTT connections silently drop on
  mobile network changes (backgrounding, wifi↔cellular handoff); test that path, don't assume
  the package auto-recovers cleanly.
```

### 2.8 Home Assistant

```text
Add or modify a Home Assistant-backed feature. Requirements:
- REST control goes through HaGatewayClient (services/gateways/clients/ha_gateway_client.dart) —
  callService() for the generic case, or add a named helper method following the existing
  setOnOff/setBrightness/setCoverPosition pattern for anything called from more than one place.
- Real-time state comes from the WebSocket listener (HaGatewayClient.connectLive) which is
  already wired into HaSyncService — do not poll REST for state that's already pushed via WS.
- One-shot admin operations (registry lookups, device removal) use the short-lived
  request/response _wsCommand() pattern, NOT the long-lived connectLive() listener — opening a
  second permanent listener per admin call would leak connections.
- New entity domain → DeviceType mappings go in HaSyncService._domainToType() — check it's a
  `switch` STATEMENT with a default case (safe to extend) before adding a case; if you're adding
  a genuinely new DeviceType (not just a domain mapping), see 06_Development_Rules.md's note on
  exhaustive-switch blast radius across 14+ files first.
- HA's own dedicated screens live under screens/ha/ (9 screens: shell, dashboard, rooms,
  security, cameras, camera_viewer, automations, push_settings, settings) — a generic
  "add an HA feature" request usually belongs in one of these, not in the generic screens.
```

---

## 3. Security

### 3.1 Alarm

```text
Modify the security/alarm system (screens/security/security_screen.dart). Requirements:
- Arm/disarm state lives in AppState (SecurityMode enum) — never store armed state locally in
  a screen's State object.
- Alarm panel brands (Ajax, PIMA, Risco) each have a dedicated client under
  services/gateways/clients/ — route brand-specific commands through those, not through a
  generic HA-only path, since not every user has these panels behind Home Assistant.
- Zone/sensor status icons must use DeviceIcons.forDevice() for state-awareness (open/closed,
  triggered/normal) — do not hardcode a second lock/sensor icon ternary; see the note in
  06_Development_Rules.md about the 5th "action icon" exception in smart_lock_hub_screen.dart
  before assuming every icon ternary is a state-indicator bug.
```

### 3.2 Cameras

```text
Add or modify camera functionality (screens/cameras/, services/cameras/). Requirements:
- Support ONVIF discovery + RTSP/MJPEG/HLS/snapshot stream types (CameraStreamType enum in
  models/device.dart already covers this) — check which stream type a camera reports before
  assuming RTSP.
- Any HttpClient/socket opened for a stream (see mjpeg_view.dart) MUST be closed in dispose() —
  this was a real leak found and fixed once already; don't reintroduce it.
- Face enrollment/analysis routes through services matching face_enrollment_screen.dart /
  face_analysis_screen.dart, backed by Azure Face API (needs AZURE_FACE_API_KEY /
  AZURE_FACE_API_ENDPOINT via --dart-define) — guard all calls so a missing key degrades
  gracefully instead of crashing.
```

### 3.3 Sensors

```text
Add a new sensor type or fix sensor classification. Requirements:
- Classify by reported ATTRIBUTE, not device name or model string — vendor naming is
  inconsistent (this is exactly the bug class fixed for DIRIGERA water-leak detection).
- Map to the closest existing DeviceType (motionSensor, doorSensor, windowSensor, smokeSensor,
  gasSensor, waterLeakSensor, glassBreakSensor) rather than inventing a new type unless truly
  no existing type fits — adding a DeviceType has a real blast radius, see
  06_Development_Rules.md.
- Temperature/humidity/pressure/etc. sensor sub-kinds without a distinct DeviceType route
  through DeviceIcons.forHaDeviceClass(device_class) for their icon, not a new enum value.
```

### 3.4 Locks

```text
Add or modify lock functionality (screens/security/smart_lock_hub_screen.dart). Requirements:
- State icon: DeviceIcons.lockIcon(isLocked) — locked shows Symbols.lock, unlocked shows
  Symbols.lock_open.
- EXCEPTION: an action button showing "what will happen if you tap" (e.g. a big "Unlock" button
  while currently locked) intentionally shows the OPPOSITE icon paired with its action label —
  do not "fix" this into lockIcon(), it is correct as an action affordance, not a state bug.
- Full decommission of a lock (Matter or HA-registry-backed) must call
  HaGatewayClient.removeDeviceByEntity(), not just the local list removal.
```

### 3.5 Sirens

```text
Siren devices have NO dedicated DeviceType today — they are not currently modeled as a distinct
device in models/device.dart, and HA's `siren` domain is not mapped in
HaSyncService._domainToType() (falls through to null / dropped). Before implementing siren
control, this is a genuine gap: see 10_Missing-Features-equivalent in 08_Roadmap.md. Do not add
a partial/cosmetic siren icon without wiring the underlying DeviceType end-to-end — that produces
dead, unreachable code.
```

### 3.6 Notifications

```text
Add a new notification category (screens/notifications/notifications_screen.dart). Requirements:
- Icon/color for the notification's deviceType MUST come from DeviceIcons.icon() /
  DeviceIcons.color() — this screen previously had its OWN independent copy of the icon/color
  switch that had silently drifted (different colors for solar/lock/gas-sensor than the
  canonical mapping used elsewhere) until it was consolidated. Never re-add a local copy.
- Push delivery goes through Firebase Cloud Messaging (flutter_local_notifications +
  firebase_messaging) — requires google-services.json / GoogleService-Info.plist to actually
  fire; code gracefully no-ops without them, preserve that behavior.
```

---

## 4. AI Assistant

### 4.1 AI Chat

```text
Modify the Fanta AI screen (screens/ai/fanta_ai_screen.dart). Requirements:
- Match the existing "Design 4" visual language: _kAiBlue/_kAiBlueDark accent constants,
  soundwave-bar avatar (not an eyes/orb avatar — that was explicitly replaced), 2x2
  _SuggestionCard grid on the landing state.
- All new user-facing strings need entries across all 7 locale blocks in l10n/strings.dart —
  follow the aiSugDesc1-4 / aiPrivacyNote naming pattern already established for this screen.
- Settings sheet actions (e.g. "Clear conversation") go in _showSettingsSheet() — don't scatter
  chat-management actions across multiple entry points.
```

### 4.2 Voice Assistant

```text
Extend voice control. Requirements:
- STT is on-device via speech_to_text (already a dependency) — no cloud STT service, no added
  cost, keep it that way unless explicitly asked to change the architecture.
- Voice command parsing should map recognized phrases to existing AppState actions
  (toggleDevice, activateScene, etc.) — do not build a second command-execution path parallel to
  the UI's existing action methods.
```

### 4.3 Automation Suggestions

```text
Add an AI-driven automation suggestion. Requirements:
- Suggestions are presentational cards that, when accepted, call the SAME AppState.addAutomation
  path a manually-created automation would use — a suggestion is not a different code path from
  a user-authored automation, just a different origin for the same Automation object.
- Do not silently auto-enable a suggested automation — always require explicit user confirmation
  before it becomes active.
```

### 4.4 Device Recommendations

```text
Add a device-recommendation feature (e.g. "you have no water-leak sensor in the kitchen").
Requirements:
- Base recommendations on gaps in the user's actual state.devices list (by room + DeviceType),
  not a static hardcoded list — otherwise it'll recommend devices the user already owns.
- Route the follow-through action to the existing AddDeviceScreen catalog, filtered to the
  relevant category — don't build a second device catalog for recommendations.
```

---

## 5. Device Discovery

### 5.1 Scan Devices

```text
Modify the discovery scan flow (services/discovery/discovery_manager.dart +
screens/smarthome/scan_discovery_screen.dart). Requirements:
- DiscoveryManager orchestrates per-protocol scanners (matter_discovery.dart,
  smart_switch_scanner.dart, etc.) that each emit ScannerLogEvent / DeviceFoundEvent /
  ScannerDoneEvent / ScannerErrorEvent — a new protocol scanner must emit the same event shapes
  so the aggregating UI doesn't need protocol-specific branches.
- Protocol tabs (_Protocol enum in scan_discovery_screen.dart: all/wifi/ble/matter/zigbee) each
  need an icon from the existing set — reuse Symbols.wifi / Symbols.bluetooth / Symbols.hub /
  Symbols.settings_input_antenna, don't invent new ones inconsistent with this set.
```

### 5.2 Pair Devices

```text
Implement a pairing flow for [protocol/brand]. Requirements:
- Success MUST result in a real Device added to AppState via a real network-confirmed
  operation — never a fabricated success path (this is exactly the anti-pattern removed from
  the old matter_repository.dart simulator).
- Show explicit progress states (idle → scanning/entering-code → committing → success/error),
  matching the _CommState enum pattern in matter_commission_screen.dart — don't collapse pairing
  into a single blocking spinner with no intermediate feedback.
```

### 5.3 Manual Add

```text
Extend the manual device catalog (screens/smarthome/add_device_screen.dart). Requirements:
- Each catalog entry needs its OWN specific icon — a light strip and a light bulb are both
  DeviceType.light but should render visually distinct catalog icons (the catalog is
  product-level, more specific than the DeviceType-level DeviceIcons default).
- New catalog sections need an entry in _iconForCategory() with a section icon, plus real
  devices added to _items().
```

### 5.4 QR Code

```text
Add/modify QR-code-based pairing. Requirements:
- Use mobile_scanner (already a dependency) — it's currently used exclusively for Matter
  commissioning; if reusing it for a new purpose, follow the existing
  MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates) pattern and the
  permission-denied error UI in _MatterScannerScreen, don't build a second bespoke scanner UI.
- Always provide a manual-entry fallback alongside any QR flow — not every user can scan
  (damaged label, no camera permission, printed code only).
```

### 5.5 Discovery Flow

```text
[End-to-end discovery flow change] — trace the full path before editing:
AddDeviceScreen / ScanDiscoveryScreen → DiscoveryManager → per-protocol scanner → DeviceFoundEvent
→ AppState.upsertDevice / addDevice → dashboard re-render via context.watch<AppState>().
Confirm which layer your change belongs in — most "discovery" bugs are actually in the
scanner layer (wrong classification) or the AppState layer (dedup/merge logic), not the UI layer.
```

---

## 6. Backend

### 6.1 API

```text
[Backend API change] — FantaTech's Flutter app has no custom REST API of its own for core
smart-home features; it talks directly to gateways (HA, DIRIGERA, etc.) and to Supabase for
account/cloud features. Before adding a new "backend endpoint", confirm whether this belongs in:
(a) a gateway client (services/gateways/clients/) for device control,
(b) Supabase (backend/data/, supabase/schema.sql) for account/cloud data, or
(c) the separate Node.js backend/ directory (e.g. backend/matter/client.js, a python-matter-server
    WebSocket bridge) — which is NOT currently wired into the Flutter app's Matter flow (HA is),
    so confirm with the user before assuming it's the live path.
```

### 6.2 WebSocket

```text
Add/modify a WebSocket integration. Requirements:
- Long-lived state listeners (continuous updates) use a persistent connection like
  HaGatewayClient.connectLive() — one connection, auth handshake, subscribe, dispatch callback
  per message.
- One-shot admin commands use a short-lived connect→auth→send→await-response→close pattern like
  HaGatewayClient._wsCommand() — do NOT open a permanent listener just to send one command, and
  do not reuse a persistent listener's connection for a request/response call (message IDs will
  collide).
- Always handle auth_invalid and connection-drop paths explicitly with a null/error return, not
  an uncaught exception.
```

### 6.3 Authentication

```text
Modify auth (screens/auth/, services/auth/). Requirements:
- Supports email/password (persisted via household CSV per current auth screens), Google
  Sign-In, Sign in with Apple, and biometric unlock (local_auth) as a secondary unlock after
  initial login — biometric is not a replacement for the primary auth method.
- Household login must list REAL household members and let the user pick who's logging in — do
  not fake a member list; this was a real bug fixed once (household login now lists & enters
  real home members).
- Logout must fully clear the session (was also a real bug — "exit to menu" not actually
  logging out) — verify session state is gone, not just navigation back to a login-looking screen.
```

### 6.4 Database

```text
Modify persistence. Requirements:
- Local device-list persistence: SharedPreferences via AppState (_saveDevicesToPrefs pattern) —
  simple key-value, not a local SQL database, for the device list.
- Cloud/account data: Supabase (see supabase/schema.sql for the schema) — requires
  SUPABASE_URL / SUPABASE_ANON_KEY via --dart-define; the whole backend module gracefully
  no-ops when these are absent — preserve that, never make Supabase a hard dependency for core
  device control.
- Any new persisted field needs both a toJson AND fromJson update in the same commit — check
  models/device.dart's pattern (including the defensive `orElse` fallback for enum parsing) as
  the template.
```

### 6.5 Docker

```text
[Docker/deployment change] — check smarthome-hub/ root for existing infra before adding new
containers: mosquitto/ (MQTT broker), gateway/, hub/, raspberry-pi/, zigbee2mqtt/ directories
already exist as separate deployable units outside the Flutter app. A "Docker" request almost
always belongs in one of these, not inside fantatech-flutter/.
```

### 6.6 Logging

```text
Add logging/observability. Requirements:
- Client-side: use debugPrint/print sparingly and only behind a debug flag for anything that
  runs in release — this app has no centralized logging framework today; don't silently add one
  dependency-heavy solution (e.g. Sentry) without confirming that's wanted first, since it's a
  monitoring/cost decision, not just a code change.
- Server-side error visibility for gateway connections should surface to the UI via existing
  connection-status indicators (GatewayManager.connections[].isConnected) rather than only to a
  console log the user never sees.
```

---

## 7. Flutter Components

### 7.1 Buttons

```text
Use/extend FtButton (widgets/ft_button.dart) for any new button — it already supports variants
(primary/secondary/neutral), sizes (sm/lg), leading icons, and an icon-only constructor. Do not
create a bespoke ElevatedButton/OutlinedButton style unless FtButton genuinely cannot express the
needed variant — if so, add the variant to FtButton rather than a one-off local widget.
```

### 7.2 Cards

```text
See §1.2 (Dashboard → Cards) above for the DeviceCard pattern. For non-device informational
cards, check FtCard family widgets before creating a new Container-with-BoxDecoration card —
FtCard already encodes the app's standard radius/shadow/border tokens.
```

### 7.3 Dialogs

```text
Add a confirmation/alert dialog. Requirements:
- Use showDialog with AlertDialog, backgroundColor: context.tCard (never a raw white/dark
  hardcoded value) — theme-aware dialogs was a real fix applied across the app once
  ("theme-aware bottom sheets, dialogs & dropdowns").
- Destructive actions (delete/remove) always need a confirm dialog with a clearly differently
  colored confirm button (AppColors.statusAlarm) — see _confirmDelete in devices_screen.dart as
  the template.
```

### 7.4 Bottom Sheets

```text
Add a bottom sheet. Requirements:
- showModalBottomSheet(context: context, backgroundColor: context.tCard, isScrollControlled:
  true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top:
  Radius.circular(22 or 28)))) — match the existing radius used by sibling sheets in the same
  feature area (22 for compact sheets, 24-28 for full DraggableScrollableSheet-style sheets).
- Always start with a drag handle — use the shared FtModalHandle widget
  (widgets/ft_nav.dart), do not redraw the 40×4 rounded-rect handle inline.
- Use DraggableScrollableSheet instead of a fixed-height sheet when content is long/variable
  (see the _EnergySheet pattern).
```

### 7.5 Forms

```text
Add a form/input screen. Requirements:
- TextField styling: filled: true, fillColor: context.tText2(0.05), OutlineInputBorder with
  BorderRadius.circular(12-14) — match existing input styling, don't introduce Material's
  default underline-style TextField anywhere in this app.
- Validate before submit; disable the submit button or show inline error rather than allowing a
  round-trip to a backend with obviously-invalid input (e.g. the 11-digit Matter pairing code
  format check happens client-side before any network call).
```

### 7.6 Themes

```text
Modify theming (theme/app_theme.dart). Requirements:
- All colors are named tokens on AppColors — a new semantic color (e.g. a new device category)
  gets a new named constant with a one-line comment describing what it represents, following the
  existing `// orange motion` style comments.
- context.tText / .tCard / .tBorder / .tTextSecondary / .isLight are the theme-aware accessors —
  use them instead of Theme.of(context).colorScheme.* so light/dark/auto-theme and the
  ambient-light auto-theme feature keep working consistently.
- Custom accent color mixer and per-user theme choice live in AppState — don't add a second,
  parallel theme-state mechanism.
```

### 7.7 Icons

```text
Use theme/device_icons.dart for ANY device/entity icon — never inline a Symbols.* icon for a
DeviceType, HA device_class, lock state, or blind position. Available entry points:
- DeviceIcons.icon(type) — static icon for a DeviceType
- DeviceIcons.color(type) — matching accent color
- DeviceIcons.forDevice(device) — STATE-AWARE icon (locked/unlocked, open/closed, on/off, etc.)
- DeviceIcons.forHaDeviceClass(deviceClass) — for sensor sub-kinds with no distinct DeviceType
  (temperature, humidity, pressure, illuminance, co2, etc.)
- DeviceIcons.lockIcon(isLocked) / .blindIcon(position) / .batteryIcon(level)
To swap the entire icon library in the future, implement a new DeviceIconSet and call
DeviceIcons.use(NewIconSet()) once — do not touch call sites.
```

---

## 8. Prompt Library — Past Requests Converted

Real requests from this project's history, generalized into reusable prompts.

```text
[Localization audit] Before writing code, perform a full audit of the localization system.
Explain: what causes locale-switch jank, which widgets rebuild on locale change, which Provider
causes the rebuild, and which parts can be optimized. Then propose a phased refactor plan
(persist-locale-choice / remove-dead-codegen-scaffold / context.select conversions /
provider-splitting), and wait for approval on which phases to implement before writing code.
```

```text
[Dashboard reorder request] I want page 1 of the home dashboard to show exactly this order:
[list items]. Page 2: [list items]. If any listed item doesn't exist as a widget yet, tell me
before writing code — specify whether it's a rename of an existing widget, a brand-new widget
(and what content it should contain), or an item being removed. Also check whether the ordering
change will actually reach devices with an already-persisted layout (see the syncNewItems
limitation in 06_Development_Rules.md) and add a migration if needed.
```

```text
[Feature audit request] Analyze the entire FantaTech codebase and verify the current support for
[Matter/Thread/any protocol]. Check whether the app fully implements: [list capabilities].
Report back in four sections: Already implemented / Partially implemented / Missing / Step-by-
step implementation plan with priorities. Do not implement anything yet — audit only.
```

```text
[Fix a duplicated-icon-category device] I noticed [device type] shows up inconsistently across
screens (e.g. appears twice with different icons/colors, or is missing from a summary card).
Investigate every place this device type is displayed, determine the single correct canonical
representation, and consolidate through DeviceIcons rather than fixing each screen individually.
```

```text
[Centralize a duplicated pattern] Search the codebase for every place [X pattern] is implemented
(e.g. an icon+color switch, a state-check ternary, a bottom-sheet header). Report every
duplicate location with file:line. Create ONE centralized implementation, then update every call
site to use it — do not leave any of the original duplicates in place, and flag if any duplicate
had silently drifted from the others (different value for the same logical case).
```

```text
[New DeviceType consideration] I want to add support for [Fan/Siren/other] as a real device type.
Before adding it to the DeviceType enum, grep for every exhaustive `switch` statement over
DeviceType across the codebase and report the blast radius (how many files would fail to compile
or need a new case). If the blast radius is large, propose the safe rollout order (add enum value
→ fix each exhaustive switch → wire HA domain mapping → add icon mapping → add UI entry points)
rather than doing it as a single opportunistic edit.
```

```text
[Documentation generation — this very prompt] Analyze all previous conversations and
implementation requests for [project]. Create a professional documentation set that organizes
everything into reusable prompts and implementation instructions, not just a summary. Structure
as [N] separate files: [list]. Ground every claim in the actual current codebase (grep/read
before writing), not just what was verbally discussed — flag anywhere the two disagree.
```

---

## 9. Best Practices

See `06_Development_Rules.md` for the full standalone rules document. Summary:

- **State**: `AppState` is the single source of truth. UI never holds device data in local
  `State`. All mutation goes through `AppState` methods, never direct field writes from a screen.
- **Rebuilds**: `context.watch<AppState>()` only when you genuinely need multiple fields:
  otherwise `context.select((AppState st) => st.field)`.
- **Icons**: always `DeviceIcons.*`, never inline `Symbols.*` for a device/entity.
- **Strings**: always `S` (`l10n/strings.dart`) across all 7 locales, never a hardcoded literal.
- **Colors**: always `AppColors.*` / `context.t*`, never raw `Colors.*` or inline hex.
- **Backends**: every optional backend (Supabase, Firebase, Azure Face API) must no-op
  gracefully when unconfigured — never a hard crash on missing credentials.
- **Verification**: `flutter analyze` clean (0 errors) + a release build before calling a task done.

## 10. Missing Features

See `08_Roadmap.md` for the full prioritized roadmap. Headline gaps:

- **Siren** and **Fan** have no `DeviceType` — control is not possible today even though icons
  could trivially be added (a purely cosmetic icon with no backing device would be dead code).
- **Matter**: no local controller, no fabric management, no Thread Border Router support, no
  device attestation/certificate handling — fully delegated to Home Assistant.
- **Marketplace backend**: `MockMarketplaceRepository` only — no real purchase flow.
- **CI/CD**: no `.github/workflows/` pipeline for analyze/test/build.
- **Supabase & Firebase**: coded but unconfigured — need real project credentials to activate
  auth, cloud sync, analytics, and push notifications.
- **Accessibility**: `Semantics` wrappers exist on only a handful of audited screens.
