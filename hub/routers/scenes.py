"""
Scenes — save a collection of device actions and execute them with one tap.
e.g. "Movie Night" = dim lights to 30% + AC to 22° cool + lock front door
"""
import json
import time
import uuid
import os
import aiosqlite
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()
DB_PATH = os.getenv("DB_PATH", "smarthome.db")

SCENE_ICONS = ["🎬", "🌙", "☀️", "🏠", "🎮", "🍽️", "🛏️", "🏋️", "🎉", "🌿", "❄️", "🔥", "💡", "🔒", "🌅"]


# ── DB helpers ────────────────────────────────────────────────────────────────

async def _ensure_table():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS scenes (
                id         TEXT PRIMARY KEY,
                name       TEXT NOT NULL,
                icon       TEXT DEFAULT '🎬',
                actions    TEXT DEFAULT '[]',
                created_at INTEGER DEFAULT 0
            )
        """)
        await db.commit()


async def _get_all_scenes() -> list:
    await _ensure_table()
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM scenes ORDER BY name") as cur:
            rows = await cur.fetchall()
            result = []
            for r in rows:
                d = dict(r)
                d["actions"] = json.loads(d.get("actions") or "[]")
                result.append(d)
            return result


async def _upsert_scene(s: dict):
    await _ensure_table()
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            INSERT INTO scenes (id, name, icon, actions, created_at)
            VALUES (:id, :name, :icon, :actions, :created_at)
            ON CONFLICT(id) DO UPDATE SET
                name=excluded.name, icon=excluded.icon, actions=excluded.actions
        """, {
            "id":         s["id"],
            "name":       s["name"],
            "icon":       s.get("icon", "🎬"),
            "actions":    json.dumps(s.get("actions", [])),
            "created_at": s.get("created_at", int(time.time())),
        })
        await db.commit()


# ── Models ────────────────────────────────────────────────────────────────────

class SceneAction(BaseModel):
    device_id: str
    type:      str        # "on" | "off" | "toggle" | "brightness" | "ac" | "lock" | "unlock"
    params:    dict = {}  # extra params e.g. brightness, temperature, mode


class SceneIn(BaseModel):
    name:    str
    icon:    str = "🎬"
    actions: list[SceneAction] = []


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/icons")
async def list_icons():
    return SCENE_ICONS


@router.get("/")
async def list_scenes():
    return await _get_all_scenes()


@router.post("/")
async def create_scene(body: SceneIn):
    s = {
        "id":         str(uuid.uuid4())[:8],
        "name":       body.name.strip(),
        "icon":       body.icon,
        "actions":    [a.dict() for a in body.actions],
        "created_at": int(time.time()),
    }
    await _upsert_scene(s)
    return s


@router.put("/{scene_id}")
async def update_scene(scene_id: str, body: SceneIn):
    scenes = await _get_all_scenes()
    existing = next((s for s in scenes if s["id"] == scene_id), None)
    if not existing:
        raise HTTPException(404, "סצנה לא נמצאה")
    updated = {
        **existing,
        "name":    body.name.strip(),
        "icon":    body.icon,
        "actions": [a.dict() for a in body.actions],
    }
    await _upsert_scene(updated)
    return updated


@router.delete("/{scene_id}")
async def remove_scene(scene_id: str):
    await _ensure_table()
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM scenes WHERE id=?", (scene_id,))
        await db.commit()
    return {"ok": True}


@router.post("/{scene_id}/execute")
async def execute_scene(scene_id: str):
    """Run all actions in a scene."""
    scenes = await _get_all_scenes()
    scene = next((s for s in scenes if s["id"] == scene_id), None)
    if not scene:
        raise HTTPException(404, "סצנה לא נמצאה")

    from database import get_device, update_device_state, add_history
    from mqtt_client import publish
    from ws_manager import manager

    results = []
    for action in scene.get("actions", []):
        device_id   = action.get("device_id")
        action_type = action.get("type", "on")
        params      = action.get("params", {})

        device = await get_device(device_id)
        if not device:
            results.append({"device_id": device_id, "ok": False, "error": "not found"})
            continue

        try:
            state = dict(device.get("state", {}))

            # ── AC devices — delegate to ac router ──────────────────────────
            if device["type"] == "ac" and action_type in ("on", "off", "ac"):
                from routers.ac import control_ac, AcCommand
                cmd_data = {}
                if action_type in ("on", "off"):
                    cmd_data["state"] = action_type.upper()
                cmd_data.update(params)
                await control_ac(device_id, AcCommand(**cmd_data))
                results.append({"device_id": device_id, "ok": True})
                continue

            # ── Regular devices ──────────────────────────────────────────────
            if action_type == "on":
                state["state"] = "ON"
            elif action_type == "off":
                state["state"] = "OFF"
            elif action_type == "toggle":
                state["state"] = "OFF" if state.get("state") == "ON" else "ON"
            elif action_type == "brightness":
                state["brightness"] = params.get("brightness", 128)
                state["state"] = "ON"
            elif action_type == "lock":
                state["state"] = "LOCKED"
            elif action_type == "unlock":
                state["state"] = "UNLOCKED"
            elif action_type == "color":
                state.update(params)
                state["state"] = "ON"

            await update_device_state(device_id, state)

            # Publish to MQTT
            topic = device.get("topic_cmd", "")
            if topic:
                publish(topic, state)

            await manager.broadcast("device_state", {"id": device_id, "state": state, "online": True})
            await add_history(device_id, device["name"], "scene", scene["name"])
            results.append({"device_id": device_id, "ok": True})

        except Exception as e:
            results.append({"device_id": device_id, "ok": False, "error": str(e)})

    ok_count = sum(1 for r in results if r["ok"])
    return {
        "ok":      ok_count > 0,
        "scene":   scene["name"],
        "results": results,
        "message": f"✅ {scene['icon']} {scene['name']} — {ok_count}/{len(results)} מכשירים הופעלו",
    }
