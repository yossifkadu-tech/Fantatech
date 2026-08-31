---
description: Security review pass for FantaTech — credentials, RLS, biometric, cloud auth
---

Load the `security` skill first, then review the current diff (or the whole app if no diff)
against this project's actual risk surface — not a generic checklist:

1. **Credentials**: any Tuya Access Secret, gateway token, MQTT password, or biometric-related
   value ever written to logs, error messages, or a widget's visible text? Gateway credentials
   belong in `GatewayConnection.credentials` (SharedPreferences-backed), never hardcoded.
2. **Supabase RLS**: any new query assumes row-level security is enforced server-side — flag if
   a new table/query path is added without confirming RLS policy coverage (this app's anon key
   is safe to ship only because RLS gates everything, per `lib/backend/supabase_config.dart`).
3. **Biometric gate**: `lib/services/auth/biometric_service.dart` — a real cold start / process
   kill must still re-prompt; only same-process resume should reuse `unlockedThisSession`. Flag
   any change that persists that flag or widens when it's trusted.
4. **Local network clients**: LAN-direct control (Shelly/Sonoff/Kasa/ESPHome via
   `SwitchController`, iRobot, Xiaomi Vacuum) sends unauthenticated/self-signed-cert traffic by
   design (that's the protocol) — don't "fix" this by weakening it further, but do flag if a new
   client trusts a cert or skips a step beyond what the brand's actual protocol requires.
5. **Guest mode / panic button**: `security_screen.dart` — any change to `state.isGuestMode` or
   the panic-activation path gets extra scrutiny; these are the two features where a bug is a
   physical-security bug, not just a UI bug.

Report findings by severity, with file:line. Don't fix anything unless asked — this is a review.
