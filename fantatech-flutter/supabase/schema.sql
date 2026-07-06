-- ─────────────────────────────────────────────────────────────────────────────
-- FantaTech — Supabase schema (Postgres) + Row-Level Security
--
-- Run in the Supabase SQL editor, or via the CLI:
--   supabase db push
--
-- Security model: every row is scoped to a home; a user may only read/write
-- rows for homes they are a member of. Enforced by RLS, not by the client.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Homes ─────────────────────────────────────────────────────────────────────
create table if not exists homes (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users (id) on delete cascade,
  name        text not null default 'My Home',
  created_at  timestamptz not null default now()
);

-- ── Home membership (manager / member / guest) ────────────────────────────────
create table if not exists home_members (
  home_id   uuid not null references homes (id) on delete cascade,
  user_id   uuid not null references auth.users (id) on delete cascade,
  role      text not null default 'member' check (role in ('manager','member','guest')),
  joined_at timestamptz not null default now(),
  primary key (home_id, user_id)
);

-- ── Rooms ─────────────────────────────────────────────────────────────────────
create table if not exists rooms (
  id        uuid primary key default gen_random_uuid(),
  home_id   uuid not null references homes (id) on delete cascade,
  key       text not null,
  name      text not null,
  icon_code int,
  sort      int default 0,
  unique (home_id, key)
);

-- ── Devices ───────────────────────────────────────────────────────────────────
create table if not exists devices (
  id         text primary key,                 -- e.g. 'wiz_192.168.1.42'
  home_id    uuid not null references homes (id) on delete cascade,
  name       text not null default '',
  type       text not null,                    -- DeviceType.name
  status     text not null default 'online',
  is_on      boolean not null default false,
  room_key   text,
  battery    int,
  attributes jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create index if not exists devices_home_idx on devices (home_id);

-- ── Automations ───────────────────────────────────────────────────────────────
create table if not exists automations (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references homes (id) on delete cascade,
  name       text not null,
  enabled    boolean not null default true,
  trigger    jsonb not null default '{}'::jsonb,
  actions    jsonb not null default '[]'::jsonb
);

-- ── Security events (immutable audit log) ─────────────────────────────────────
create table if not exists security_events (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references homes (id) on delete cascade,
  type       text not null,                    -- 'door_open','motion','panic',...
  device_id  text,
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists sec_events_home_idx on security_events (home_id, created_at desc);

-- ── Push tokens (for FCM / APNs) ──────────────────────────────────────────────
create table if not exists push_tokens (
  user_id    uuid not null references auth.users (id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('android','ios','web')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

-- ── Subscriptions (Free / Pro) ────────────────────────────────────────────────
create table if not exists subscriptions (
  user_id   uuid primary key references auth.users (id) on delete cascade,
  tier      text not null default 'free' check (tier in ('free','pro')),
  renews_at timestamptz,
  provider  text
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Row-Level Security
-- ─────────────────────────────────────────────────────────────────────────────
alter table homes           enable row level security;
alter table home_members    enable row level security;
alter table rooms           enable row level security;
alter table devices         enable row level security;
alter table automations     enable row level security;
alter table security_events enable row level security;
alter table push_tokens     enable row level security;
alter table subscriptions   enable row level security;

-- Helper: is the current user a member of :home_id ?
create or replace function is_home_member(h uuid)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from home_members m
    where m.home_id = h and m.user_id = auth.uid()
  );
$$;

-- Homes: members can read; owner can write.
create policy homes_read   on homes for select using (is_home_member(id) or owner_id = auth.uid());
create policy homes_insert on homes for insert with check (owner_id = auth.uid());
create policy homes_update on homes for update using (owner_id = auth.uid());

-- Membership: a user sees their own membership rows.
create policy members_self on home_members for select using (user_id = auth.uid() or is_home_member(home_id));

-- Generic per-home tables: full access to members of the home.
create policy rooms_rw    on rooms          for all using (is_home_member(home_id)) with check (is_home_member(home_id));
create policy devices_rw  on devices        for all using (is_home_member(home_id)) with check (is_home_member(home_id));
create policy autos_rw    on automations    for all using (is_home_member(home_id)) with check (is_home_member(home_id));
create policy events_read on security_events for select using (is_home_member(home_id));
create policy events_ins  on security_events for insert with check (is_home_member(home_id));

-- Per-user tables.
create policy push_self on push_tokens   for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy subs_self on subscriptions for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── Realtime: broadcast device + event changes ────────────────────────────────
alter publication supabase_realtime add table devices;
alter publication supabase_realtime add table security_events;
