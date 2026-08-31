---
name: cloud
description: Develop FantaTech cloud services — auth/security requirements, and the real footprint (Supabase, Firebase, Tuya Cloud) this maps onto, including sizing guidance for scaling questions. Load when asked about hosting, scaling, cloud costs, or auth/backend work.
---

# FantaTech Cloud Skill

## Purpose

Develop FantaTech cloud services.

Potential responsibilities:

- authentication
- users
- devices
- gateways
- remote access
- synchronization
- notifications
- automation
- logs
- account management

Security requirements:

- TLS
- JWT where appropriate
- refresh tokens
- secure password handling
- authorization
- rate limiting
- audit logging

Never store plaintext passwords.

Never log authentication tokens.

---

## Current implementation (search here before creating anything new)

FantaTech does **not** run its own backend server for end users — most of the "Purpose" list
above is already handled by managed services, not custom infrastructure to build:

| Service | Covers from the list above | File |
|---|---|---|
| **Supabase** | authentication, users, account management, logs (via Postgres) | `lib/backend/supabase_config.dart`, `lib/backend/auth/auth_repository.dart` |
| **Firebase** (`firebase_messaging`) | notifications | pubspec dependency |
| **Tuya Cloud** | devices/gateways (for Tuya-powered devices specifically) | see `tuya` skill |

**Security requirements already satisfied by Supabase, don't rebuild**: TLS (managed), JWT +
refresh tokens (Supabase Auth issues both natively — this is not something FantaTech needs to
implement), secure password handling (Supabase Auth hashes/stores, the app never sees plaintext).

**What's genuinely FantaTech's responsibility, not Supabase's**: **Row-Level Security policies**
— `supabase_config.dart`'s own doc comment confirms the shipped anon key is safe *only because*
RLS is assumed to gate every table server-side. Any new table/query path needs RLS coverage
confirmed before shipping, not assumed. This is the actual "authorization" item from the list
above that requires real FantaTech-side work.

**Not part of the cloud footprint** — don't confuse with it: the local `hub/` (Python/FastAPI)
runs per-installation on each customer's own Raspberry Pi/PC, not centrally. "Remote access" to
a customer's devices, if implemented, goes through their own hub instance, not a shared server.

## Sizing guidance (for "how many users can we support" questions)

Supabase is managed — there's no VPS/EC2 to size. For early-stage user counts (low thousands),
**Supabase Pro** (verify current pricing — don't quote stale numbers) comfortably covers it: no
auto-pause on inactivity, daily backups, generous headroom. Avoid the Free tier for anything with
real customers — it pauses after a week of inactivity and has no backups, a data-loss risk, not
a cost-saving. Firebase Cloud Messaging is free at any realistic scale for this app. If asked
"what cloud computer do I need," the honest answer is usually "you don't need a server — you need
the right Supabase tier" — say so rather than defaulting to unnecessary infrastructure advice.
