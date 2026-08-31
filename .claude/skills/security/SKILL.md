---
name: security
description: Security-sensitive area checklist for FantaTech — plus the real biometric session bug already fixed once, RLS dependency, local-protocol trust boundaries, guest/panic scrutiny, and a network-flood pattern already found and fixed once. Load for any security review or auth/permission work.
---

# FantaTech Security Skill

Before modifying security-sensitive code:

STOP and inspect the current implementation.

Security-sensitive areas:

- authentication
- JWT
- refresh tokens
- passwords
- API keys
- camera credentials
- MQTT credentials
- Gateway access
- cloud APIs
- remote access
- device pairing

Rules:

Never hard-code secrets.

Never print secrets.

Never commit secrets.

Never disable authentication as a shortcut.

Never disable TLS simply to make development easier.

Prefer least privilege.

---

## Current implementation — real findings from this codebase, not generic advice

**Biometric session handling** (`lib/services/auth/biometric_service.dart`) —
`unlockedThisSession` is an **in-memory, non-persisted** flag set after a successful
`authenticate()`, checked by `main.dart`'s `_AuthGateState._maybeUnlock()` before re-prompting.
This exists because Android recreates the Activity (re-running `initState`) on a plain
background/foreground cycle — without it, an already-authenticated session got re-prompted for
no reason, a real bug already fixed once. **Never persist this flag** — a genuine cold start /
process kill must still re-prompt; only same-process resume should skip it. If you see it move
into SharedPreferences in a future change, that's a regression, not an improvement.

**Authentication/JWT/refresh-token/password-hashing are Supabase's job, not FantaTech's to
implement** — see `cloud` skill. The FantaTech-side responsibility is **Row-Level Security**
policy coverage on every table (the shipped anon key is safe only because RLS is assumed to gate
everything server-side), not building auth primitives from scratch.

**"Device pairing" credentials aren't uniformly secret-worthy** — treat differently by class:
- Tuya Access Secret, MQTT broker passwords, gateway API tokens: real secrets, never log/print/
  commit (see `tuya`/`mqtt`/`gateway` skills).
- Local-LAN device protocols (Shelly/Sonoff/Kasa/ESPHome via `SwitchController`, iRobot's
  self-signed-cert local MQTTS, Xiaomi Vacuum's pre-shared miIO token) are unauthenticated-by-
  design or self-signed by the *actual brand protocol*, not a shortcut this codebase took —
  don't "harden" a client past what its real protocol requires; do flag if a *new* client trusts
  something beyond what its protocol actually needs.

**Guest mode / panic button get extra scrutiny, not the default level**: `security_screen.dart`'s
`state.isGuestMode`/`cancelGuestMode`/`welcomeGuest()` and the panic-activation path are the two
places where a bug is a physical-security bug (a guest retaining access past their window; a
panic button failing silently), not just a UI bug.

**A "least privilege" failure mode already found once, not auth-related but still security-
adjacent**: `switch_scan_engine.dart`/`sensor_scan_engine.dart` auto-started 254-host LAN subnet
scans on screen open with no cancellation on navigate-away, letting scans keep running
unnecessarily — fixed via a cancellation flag checked in the loop, set in `dispose()`. Any new
scan/discovery engine should include this from the start (see `testing` skill for the pattern).
