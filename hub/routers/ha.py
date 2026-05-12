"""
ha.py — Home Assistant REST API integration
Imports entities from a running HA instance via a Long-Lived Access Token.

Endpoints:
  POST /api/ha/fetch   → list all importable entities
  POST /api/ha/import  → save selected entities to hub database

Requirements:
  - Home Assistant reachable from this PC (same LAN or port-forwarded)
  - A Long-Lived Access Token created in HA Profile → Security
"""
import re
import time
from typing import List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import upsert_device

router = APIRouter()

# ── Domain → hub type mapping ─────────────────────────────────────────────────

_TYPE_MAP = {
    "light":          "light",
    "switch":         "switch",
    "input_boolean":  "switch",
    "automation":     "switch",
    "script":         "switch",
    "scene":          "switch",
    "cover":          "switch",
    "fan":            "fan",
    "lock":           "lock",
    "climate":        "ac",
    "camera":         "camera",
    "binary_sensor":  "sensor",
    "sensor":         "sensor",
    "media_player":   "switch",
}

# Only these domains are offered for import
IMPORTABLE = frozenset({
    "light", "switch", "fan", "lock", "climate", "camera",
    "binary_sensor", "sensor", "cover", "input_boolean", "media_player",
})

def _ha_type(entity_id: str) -> str:
    domain = entity_id.split(".")[0]
    return _TYPE_MAP.get(domain, "switch")


# ── Models ────────────────────────────────────────────────────────────────────

class FetchIn(BaseModel):
    ha_url: str   # e.g. "http://homeassistant.local:8123" or "http://192.168.1.x:8123"
    token:  str   # Long-Lived Access Token from HA Profile → Security

class HaEntity(BaseModel):
    entity_id: str
    name:      str
    type:      str  = "switch"
    state:     str  = "off"

class ImportIn(BaseModel):
    ha_url:   str
    token:    str
    entities: List[HaEntity]


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/fetch")
async def ha_fetch(data: FetchIn):
    """
    Fetch all importable entity states from Home Assistant.
    Filters to domains that map to real controllable devices.
    """
    try:
        import httpx
        base    = data.ha_url.rstrip("/")
        headers = {
            "Authorization": f"Bearer {data.token}",
            "Content-Type":  "application/json",
        }
        async with httpx.AsyncClient(timeout=12, verify=False) as c:
            r = await c.get(f"{base}/api/states", headers=headers)
    except Exception as e:
        raise HTTPException(503, f"Cannot reach Home Assistant at {data.ha_url}: {e}")

    if r.status_code == 401:
        raise HTTPException(401, "Invalid token — generate a Long-Lived Access Token in HA: Profile → Security → Long-Lived Access Tokens")
    if r.status_code == 403:
        raise HTTPException(403, "Token does not have permission to read states")
    if r.status_code != 200:
        raise HTTPException(r.status_code, f"Home Assistant returned HTTP {r.status_code}")

    states = r.json()
    if not isinstance(states, list):
        raise HTTPException(502, "Unexpected response format from HA")

    devices = []
    for s in states:
        entity_id = s.get("entity_id", "")
        domain    = entity_id.split(".")[0]
        if domain not in IMPORTABLE:
            continue

        attrs   = s.get("attributes", {}) or {}
        name    = (attrs.get("friendly_name") or entity_id).strip()
        state   = s.get("state", "unknown")
        online  = state not in ("unavailable", "unknown", "none", "")

        devices.append({
            "entity_id": entity_id,
            "name":      name,
            "type":      _ha_type(entity_id),
            "state":     state,
            "online":    online,
            "domain":    domain,
            "category":  domain,
        })

    # Sort: online first, then by domain, then by name
    devices.sort(key=lambda d: (not d["online"], d["domain"], d["name"].lower()))

    return {"devices": devices, "count": len(devices)}


@router.post("/import")
async def ha_import(data: ImportIn):
    """Save selected HA entities into the hub database."""
    imported = []
    for ent in data.entities:
        safe  = re.sub(r"[^a-zA-Z0-9]", "_", ent.entity_id)
        dev_id = f"ha_{safe}"
        on     = ent.state.lower() in ("on", "true", "1", "home", "open", "locked")

        await upsert_device({
            "id":          dev_id,
            "name":        ent.name,
            "protocol":    "ha",
            "type":        ent.type,
            "topic_state": f"devices/{dev_id}/state",
            "topic_cmd":   f"devices/{dev_id}/cmd",
            "room":        "",
            "label":       "Home Assistant",
            "config": {
                "ha_entity_id": ent.entity_id,
                "ha_url":       data.ha_url,
                "ha_token":     data.token,
                "source":       "home_assistant",
            },
            "state":      {"state": "ON" if on else "OFF"},
            "online":     ent.state not in ("unavailable", "unknown", "none"),
            "pinned":     False,
            "created_at": int(time.time()),
        })
        imported.append({"hub_id": dev_id, "name": ent.name})

    return {"ok": True, "imported": len(imported), "devices": imported}
