import aiosqlite
import os
import json
import time

DB_PATH = os.getenv("DB_PATH", "smarthome.db")


async def init_db():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.executescript("""
            CREATE TABLE IF NOT EXISTS devices (
                id          TEXT PRIMARY KEY,
                name        TEXT NOT NULL,
                protocol    TEXT NOT NULL,
                type        TEXT NOT NULL,
                topic_state TEXT NOT NULL,
                topic_cmd   TEXT NOT NULL,
                room        TEXT DEFAULT '',
                config      TEXT DEFAULT '{}',
                state       TEXT DEFAULT '{}',
                online      INTEGER DEFAULT 0,
                pinned      INTEGER DEFAULT 0,
                label       TEXT DEFAULT '',
                created_at  INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS history (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id   TEXT NOT NULL,
                device_name TEXT NOT NULL,
                action      TEXT NOT NULL,
                value       TEXT,
                ts          INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS rules (
                id          TEXT PRIMARY KEY,
                name        TEXT NOT NULL,
                enabled     INTEGER DEFAULT 1,
                trigger     TEXT NOT NULL,
                condition   TEXT DEFAULT '{}',
                actions     TEXT NOT NULL,
                last_run    INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS rooms (
                id   TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT DEFAULT '🏠'
            );

            CREATE TABLE IF NOT EXISTS wifi_profiles (
                ssid        TEXT PRIMARY KEY,
                password    TEXT DEFAULT '',
                room        TEXT DEFAULT '',
                saved_at    INTEGER DEFAULT 0,
                priority    INTEGER DEFAULT 0,
                auto_connect INTEGER DEFAULT 1
            );

            CREATE TABLE IF NOT EXISTS notifications (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                type        TEXT NOT NULL DEFAULT 'info',
                category    TEXT NOT NULL DEFAULT 'system',
                title       TEXT NOT NULL,
                message     TEXT NOT NULL DEFAULT '',
                device_id   TEXT DEFAULT '',
                device_name TEXT DEFAULT '',
                read        INTEGER DEFAULT 0,
                ts          INTEGER NOT NULL
            );
        """)
        await db.commit()

        # ── migrations: add columns that may be missing in older DBs ──────
        migrations = [
            ("devices",       "pinned",       "INTEGER DEFAULT 0"),
            ("devices",       "label",        "TEXT DEFAULT ''"),
            ("devices",       "created_at",   "INTEGER DEFAULT 0"),
            ("wifi_profiles", "room",         "TEXT DEFAULT ''"),
            ("wifi_profiles", "priority",     "INTEGER DEFAULT 0"),
            ("wifi_profiles", "auto_connect", "INTEGER DEFAULT 1"),
            ("notifications", "device_id",    "TEXT DEFAULT ''"),
            ("notifications", "device_name",  "TEXT DEFAULT ''"),
        ]
        for table, col, defn in migrations:
            try:
                await db.execute(f"ALTER TABLE {table} ADD COLUMN {col} {defn}")
                await db.commit()
            except Exception:
                pass  # column already exists


async def get_all_devices() -> list:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM devices ORDER BY room, name") as cur:
            rows = await cur.fetchall()
            return [_parse_device(dict(r)) for r in rows]


async def get_device(device_id: str) -> dict | None:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM devices WHERE id=?", (device_id,)) as cur:
            row = await cur.fetchone()
            return _parse_device(dict(row)) if row else None


async def upsert_device(d: dict):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            INSERT INTO devices (id, name, protocol, type, topic_state, topic_cmd, room, config, state, online, pinned, label, created_at)
            VALUES (:id,:name,:protocol,:type,:topic_state,:topic_cmd,:room,:config,:state,:online,:pinned,:label,:created_at)
            ON CONFLICT(id) DO UPDATE SET
                name=excluded.name, protocol=excluded.protocol, type=excluded.type,
                topic_state=excluded.topic_state, topic_cmd=excluded.topic_cmd,
                room=excluded.room, config=excluded.config,
                state=excluded.state, online=excluded.online,
                pinned=excluded.pinned, label=excluded.label
        """, {
            "id": d["id"], "name": d["name"], "protocol": d["protocol"],
            "type": d["type"], "topic_state": d["topic_state"],
            "topic_cmd": d["topic_cmd"], "room": d.get("room", ""),
            "config": json.dumps(d.get("config", {})),
            "state": json.dumps(d.get("state", {})),
            "online": int(d.get("online", False)),
            "pinned": int(d.get("pinned", False)),
            "label": d.get("label", ""),
            "created_at": int(time.time()),
        })
        await db.commit()


async def pin_device(device_id: str, pinned: bool):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE devices SET pinned=? WHERE id=?", (int(pinned), device_id))
        await db.commit()


async def rename_device(device_id: str, name: str, label: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE devices SET name=?, label=? WHERE id=?", (name, label, device_id))
        await db.commit()


async def update_device_state(device_id: str, state: dict, online: bool = True):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "UPDATE devices SET state=?, online=? WHERE id=?",
            (json.dumps(state), int(online), device_id)
        )
        await db.commit()


async def delete_device(device_id: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM devices WHERE id=?", (device_id,))
        await db.commit()


async def add_history(device_id: str, device_name: str, action: str, value=None):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO history (device_id, device_name, action, value, ts) VALUES (?,?,?,?,?)",
            (device_id, device_name, action, str(value) if value is not None else None, int(time.time()))
        )
        await db.commit()


async def get_history(limit: int = 100) -> list:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT * FROM history ORDER BY ts DESC LIMIT ?", (limit,)
        ) as cur:
            return [dict(r) for r in await cur.fetchall()]


async def clear_history():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM history")
        await db.commit()


async def get_all_rules() -> list:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM rules") as cur:
            rows = await cur.fetchall()
            return [_parse_rule(dict(r)) for r in rows]


async def upsert_rule(r: dict):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            INSERT INTO rules (id, name, enabled, trigger, condition, actions)
            VALUES (:id,:name,:enabled,:trigger,:condition,:actions)
            ON CONFLICT(id) DO UPDATE SET
                name=excluded.name, enabled=excluded.enabled,
                trigger=excluded.trigger, condition=excluded.condition,
                actions=excluded.actions
        """, {
            "id": r["id"], "name": r["name"],
            "enabled": int(r.get("enabled", True)),
            "trigger": json.dumps(r["trigger"]),
            "condition": json.dumps(r.get("condition", {})),
            "actions": json.dumps(r["actions"]),
        })
        await db.commit()


async def delete_rule(rule_id: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM rules WHERE id=?", (rule_id,))
        await db.commit()


async def update_rule_last_run(rule_id: str, ts: int):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE rules SET last_run=? WHERE id=?", (ts, rule_id))
        await db.commit()


async def get_all_rooms() -> list:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM rooms") as cur:
            return [dict(r) for r in await cur.fetchall()]


async def upsert_room(r: dict):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO rooms (id,name,icon) VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name, icon=excluded.icon",
            (r["id"], r["name"], r.get("icon", "🏠"))
        )
        await db.commit()


async def delete_room(room_id: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM rooms WHERE id=?", (room_id,))
        # Remove room from all devices in that room
        await db.execute("UPDATE devices SET room='' WHERE room=?", (room_id,))
        await db.commit()


async def get_wifi_profiles() -> list:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT * FROM wifi_profiles ORDER BY priority DESC, saved_at DESC"
        ) as cur:
            return [dict(r) for r in await cur.fetchall()]


async def save_wifi_profile(ssid: str, password: str, room: str = "", auto_connect: bool = True):
    async with aiosqlite.connect(DB_PATH) as db:
        # New profile gets priority = max(existing) + 1 so it's tried first
        async with db.execute("SELECT MAX(priority) FROM wifi_profiles") as cur:
            row = await cur.fetchone()
            next_priority = (row[0] or 0) + 1
        await db.execute(
            "INSERT INTO wifi_profiles (ssid, password, room, saved_at, priority, auto_connect) "
            "VALUES (?,?,?,?,?,?) "
            "ON CONFLICT(ssid) DO UPDATE SET "
            "  password=excluded.password, room=excluded.room, "
            "  saved_at=excluded.saved_at, auto_connect=excluded.auto_connect",
            (ssid, password, room, int(time.time()), next_priority, int(auto_connect))
        )
        await db.commit()


async def update_wifi_priority(ssid: str, priority: int):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "UPDATE wifi_profiles SET priority=? WHERE ssid=?", (priority, ssid)
        )
        await db.commit()


async def update_wifi_auto_connect(ssid: str, auto_connect: bool):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "UPDATE wifi_profiles SET auto_connect=? WHERE ssid=?",
            (int(auto_connect), ssid)
        )
        await db.commit()


async def delete_wifi_profile(ssid: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM wifi_profiles WHERE ssid=?", (ssid,))
        await db.commit()


async def add_notification(
    type_: str, category: str, title: str,
    message: str = "", device_id: str = "", device_name: str = ""
):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO notifications (type,category,title,message,device_id,device_name,read,ts) "
            "VALUES (?,?,?,?,?,?,0,?)",
            (type_, category, title, message, device_id, device_name, int(time.time()))
        )
        await db.commit()


async def get_notifications(limit: int = 200, unread_only: bool = False) -> list:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        q = "SELECT * FROM notifications"
        if unread_only:
            q += " WHERE read=0"
        q += " ORDER BY ts DESC LIMIT ?"
        async with db.execute(q, (limit,)) as cur:
            return [dict(r) for r in await cur.fetchall()]


async def get_unread_count() -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT COUNT(*) FROM notifications WHERE read=0") as cur:
            row = await cur.fetchone()
            return row[0] if row else 0


async def mark_notification_read(notif_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE notifications SET read=1 WHERE id=?", (notif_id,))
        await db.commit()


async def mark_all_notifications_read():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE notifications SET read=1")
        await db.commit()


async def clear_notifications():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM notifications")
        await db.commit()


def _parse_device(r: dict) -> dict:
    r["config"] = json.loads(r.get("config") or "{}")
    r["state"] = json.loads(r.get("state") or "{}")
    r["online"] = bool(r.get("online", 0))
    r["pinned"] = bool(r.get("pinned", 0))
    r["label"] = r.get("label", "")
    return r


def _parse_rule(r: dict) -> dict:
    r["trigger"] = json.loads(r.get("trigger") or "{}")
    r["condition"] = json.loads(r.get("condition") or "{}")
    r["actions"] = json.loads(r.get("actions") or "[]")
    r["enabled"] = bool(r.get("enabled", 1))
    return r
