# FantaTech - Claude Code Project Instructions

## 1. PROJECT IDENTITY

Project name: FantaTech

FantaTech is a smart home and security platform.

Main goals:

- Smart home control
- Security systems
- Cameras
- Alarm systems
- Sensors
- Automation
- Multi-brand device support
- FantaTech Gateway
- FantaTech Cloud
- Mobile application

Primary application technology:

- Flutter

Backend / infrastructure may include:

- Node.js
- Docker
- PostgreSQL
- MQTT
- Home Assistant
- Raspberry Pi / Linux Gateway

---

# 2. CRITICAL SAFETY RULES

These rules have the highest priority.

DO NOT rewrite the application.

DO NOT replace the existing architecture.

DO NOT delete working functionality.

DO NOT rename existing public APIs without approval.

DO NOT remove existing dependencies without approval.

DO NOT change working UI unnecessarily.

DO NOT modify authentication unless the task explicitly requires it.

DO NOT modify database schema unless explicitly required.

DO NOT make large refactors when a small change is sufficient.

Prefer additive changes.

Prefer adapters, plugins and isolated modules.

---

# 3. BEFORE CHANGING CODE

For every non-trivial task:

1. Inspect the relevant files.
2. Understand the existing implementation.
3. Identify dependencies.
4. Identify possible regression risks.
5. Explain the intended change briefly.
6. Make the smallest safe change.

Do not scan the entire repository unless necessary.

Only inspect files relevant to the task.

---

# 4. EXISTING FUNCTIONALITY

Treat existing functionality as protected.

If existing code already solves the problem:

USE IT.

Do not create a second implementation unnecessarily.

Before creating a new service, controller, repository or provider:

Search the project for an existing implementation.

---

# 5. ARCHITECTURE PRINCIPLE

FantaTech should use a modular architecture.

The application should not directly depend on individual device manufacturers.

Use:

Application
    ↓
FantaTech Device Model
    ↓
Device Adapter
    ↓
Protocol / Manufacturer
    ↓
Physical Device

Examples:

FantaTech
    ↓
Device Adapter
    ↓
Tuya
    ↓
MOES Switch

FantaTech
    ↓
Device Adapter
    ↓
Matter
    ↓
Matter Device

FantaTech
    ↓
Device Adapter
    ↓
ONVIF
    ↓
IP Camera

---

# 6. DEVICE CAPABILITY MODEL

Every device integration should expose a normalized device model.

Example:

Device:

- id
- name
- manufacturer
- model
- protocol
- category
- capabilities
- state
- availability
- metadata

Capabilities may include:

- on_off
- brightness
- color
- temperature
- humidity
- motion
- contact
- power
- energy
- lock
- alarm
- camera
- microphone
- speaker
- battery

The UI should work with capabilities rather than manufacturer-specific APIs.

---

# 7. SUPPORTED / PLANNED PROTOCOLS

FantaTech is designed to support:

- Tuya
- Smart Life
- Matter
- Zigbee
- Z-Wave
- MQTT
- Home Assistant
- ONVIF
- Wi-Fi devices
- LAN devices

Future manufacturers must preferably be implemented through adapters.

---

# 8. TUYA

Tuya must be isolated behind a Tuya adapter.

Do not spread Tuya-specific code throughout Flutter UI.

Do not make the application depend directly on Tuya-specific data structures.

Normalize Tuya devices into the FantaTech Device Model.

---

# 9. MATTER

Matter must be treated as a protocol adapter.

Do not assume that all Matter devices expose identical capabilities.

Use discovery and capability mapping.

---

# 10. ZIGBEE

Zigbee integrations must be isolated.

Potential implementations:

- Zigbee2MQTT
- Home Assistant
- direct gateway integration

Do not hard-code a single Zigbee manufacturer into the core application.

---

# 11. Z-WAVE

Z-Wave must use an adapter.

Potential integration:

Home Assistant / Z-Wave JS.

Keep protocol-specific code outside the core device model.

---

# 12. MQTT

MQTT is an infrastructure transport.

Do not expose MQTT implementation details directly to the UI.

Use services/adapters.

---

# 13. HOME ASSISTANT

Home Assistant can act as an integration layer for supported devices.

FantaTech should not become tightly coupled to Home Assistant internals.

Use a clear integration boundary.

---

# 14. CAMERAS

Camera integrations should support:

- ONVIF
- RTSP where appropriate
- Home Assistant camera entities where appropriate

Camera credentials must never be logged.

Never expose passwords or tokens in UI logs.

---

# 15. GATEWAY

FantaTech Gateway is responsible for local device communication.

Possible components:

- Home Assistant
- MQTT
- Zigbee
- Z-Wave
- Matter
- ONVIF
- local device discovery
- local automation

The Gateway should continue working when Internet connectivity is unavailable whenever technically possible.

---

# 16. CLOUD

FantaTech Cloud may provide:

- user accounts
- authentication
- device metadata
- remote access
- synchronization
- notifications
- automation
- logs
- subscription / account services

Do not move local device control to the cloud unless explicitly required.

---

# 17. SECURITY

Never:

- hard-code passwords
- expose API keys
- print access tokens
- log camera credentials
- commit secrets
- disable TLS for convenience
- disable authentication to solve a development problem

Use environment variables or secure configuration.

---

# 18. TESTING

After modifying code:

1. Run the smallest relevant test.
2. Check compilation.
3. Check static analysis where available.
4. Check affected functionality.
5. Report failures.

Do not run the entire test suite unnecessarily.

---

# 19. GIT

Before significant changes:

Create a Git checkpoint.

Example:

git status
git add .
git commit -m "checkpoint before <task>"

Never destroy uncommitted user work.

Do not reset or checkout user changes without permission.

---

# 20. TOKEN EFFICIENCY

Be concise.

Do not repeat project architecture in every response.

Do not reread unrelated files.

Do not scan the entire repository unless necessary.

Prefer targeted searches.

When reporting results:

- What changed
- Files changed
- Tests performed
- Problems found
- Next step

Avoid long explanations unless requested.

---

# 21. WORK MODES

When the user says:

AUDIT

Only inspect and report.

When the user says:

PLAN

Analyze and create a plan.

Do not modify files.

When the user says:

IMPLEMENT

Implement the approved plan.

When the user says:

SAFE CHANGE

Make the smallest possible change.

When the user says:

TEST

Run relevant tests only.

When the user says:

STATUS

Report project status.

When the user says:

CHECKPOINT

Create a Git checkpoint if there are changes.

---

# 22. CHANGE CONTROL

If a requested change could affect:

- authentication
- database
- architecture
- device core
- gateway
- cloud
- security
- existing public APIs

STOP before implementation and explain the impact.

Do not silently make high-risk architectural changes.

---

# 23. FINAL REPORT FORMAT

After implementation use:

CHANGED:
- ...

FILES:
- ...

TESTED:
- ...

ISSUES:
- ...

NEXT:
- ...

Keep the report concise.
