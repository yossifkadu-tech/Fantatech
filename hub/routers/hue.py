"""
hue.py — Philips Hue Bridge integration
Discovers bridge on LAN, pairs via button press, imports lights & sensors.

Endpoints:
  GET  /api/hue/discover       → auto-detect bridge via Philips cloud
  POST /api/hue/pair           → create API user (bridge button must be pressed)
  POST /api/hue/fetch          → list all lights + sensors from bridge
  POST /api/hue/import         → save selected devices to hub database
"""
import re
import time
from typing import List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import upsert_device

router = APIRouter()

# ── Type mapping ──────────────────────────────────────────────────────────────

_TYPE_MAP = {
    "extended color light":       "light",
    "color light":                "light",
    "dimmable light":             "dimmer",
    "color temperature light":    "dimmer",
    "on/off light":               "switch",
    "on/off plug-in unit":        "switch",
    "smart plug":                 "switch",
    "zllswitch":                  "switch",
    "zgpswitch":                  "switch",
    "zllpresence":                "motion",
    "zlllightlevel":              "sensor",
    "zlltemperature":             "sensor",
}

def _hue_type(raw: str) -> str:
    key = raw.strip().lower()
    return _TYPE_MAP.get(key, "light")

def _base(bridge_ip: str, username: str = "") -> str:
    ip = bridge_ip.strip().rstrip("/")
    if not ip.startswith("http"):
        ip = f"http://{ip}"
    return f"{ip}/api/{username}" if username else f"{ip}/api"


# ── Models ───────────────────────────────────────────────────────────────────

class PairIn(BaseModel):
    bridge_ip: str

class FetchIn(BaseModel):
    bridge_ip: str
    username:  str

class HueDev(BaseModel):
    hue_id:  str
    name:    str
    type:    str    = "light"
    on:      bool   = False
    online:  bool   = True

class ImportIn(BaseModel):
    bridge_ip: str
    username:  str
    devices:   List[HueDev]


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/discover")
async def discover():
    """
    Ask the Philips cloud discovery service for bridges on this network.
    Falls back gracefully if the PC has no internet access.
    """
    try:
        import httpx
        async with httpx.AsyncClient(timeout=5) as c:
            r = await c.get("https://discovery.meethue.com/")
        return {"bridges": r.json()}
    except Exception as e:
        return {"bridges": [], "note": str(e)}


@router.post("/pair")
async def pair(data: PairIn):
    """
    Create a Hue API username.
    The big button on the top of the bridge MUST be pressed ≤30 s before calling this.
    Returns { username } on success.
    """
    try:
        import httpx
        async with httpx.AsyncClient(timeout=8, verify=False) as c:
            r = await c.post(
                _base(data.bridge_ip),
                json={"devicetype": "fantatech#hub"},
            )
        result = r.json()
        if isinstance(result, list) and result:
            first = result[0]
            if "success" in first:
                return {"ok": True, "username": first["success"]["username"]}
            if "error" in first:
                err = first["error"]
                if err.get("type") == 101:
                    raise HTTPException(
                        401,
                        "Link button not pressed — press the round button on top of the bridge, then try again within 30 seconds",
                    )
                raise HTTPException(400, err.get("description", "Hue bridge error"))
        raise HTTPException(400, "Unexpected response from bridge")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Cannot reach bridge at {data.bridge_ip}: {e}")


@router.post("/fetch")
async def fetch(data: FetchIn):
    """Return all lights and relevant sensors from the bridge."""
    try:
        import httpx
        base = _base(data.bridge_ip, data.username)
        async with httpx.AsyncClient(timeout=8, verify=False) as c:
            lr = await c.get(f"{base}/lights")
            sr = await c.get(f"{base}/sensors")
    except Exception as e:
        raise HTTPException(500, f"Cannot reach bridge: {e}")

    lights  = lr.json()  if lr.status_code  == 200 else {}
    sensors = sr.json()  if sr.status_code  == 200 else {}

    # Detect bad username
    if isinstance(lights, list) and lights and "error" in lights[0]:
        raise HTTPException(401, "Invalid API username — re-pair the bridge")

    out = []

    for hue_id, info in (lights  if isinstance(lights,  dict) else {}).items():
        st = info.get("state", {})
        out.append({
            "hue_id":   hue_id,
            "name":     info.get("name", f"Hue Light {hue_id}"),
            "type":     _hue_type(info.get("type", "")),
            "on":       bool(st.get("on", False)),
            "online":   bool(st.get("reachable", True)),
            "model":    info.get("modelid", ""),
            "category": "light",
        })

    SENSOR_TYPES = {"zllpresence", "zlllightlevel", "zlltemperature", "zllswitch"}
    for hue_id, info in (sensors if isinstance(sensors, dict) else {}).items():
        raw_type = info.get("type", "").lower()
        if raw_type not in SENSOR_TYPES:
            continue
        st = info.get("state", {})
        cfg = info.get("config", {})
        out.append({
            "hue_id":   f"s{hue_id}",
            "name":     info.get("name", f"Hue Sensor {hue_id}"),
            "type":     _hue_type(info.get("type", "")),
            "on":       True,
            "online":   bool(cfg.get("reachable", True)),
            "model":    info.get("modelid", ""),
            "category": "sensor",
        })

    return {"devices": out, "count": len(out)}


@router.post("/import")
async def import_devices(data: ImportIn):
    """Save selected Hue lights/sensors into the hub database."""
    imported = []
    for dev in data.devices:
        safe_id = f"hue_{re.sub(r'[^a-zA-Z0-9]', '_', dev.hue_id)}"
        await upsert_device({
            "id":          safe_id,
            "name":        dev.name,
            "protocol":    "hue",
            "type":        dev.type,
            "topic_state": f"devices/{safe_id}/state",
            "topic_cmd":   f"devices/{safe_id}/cmd",
            "room":        "",
            "label":       "Philips Hue",
            "config": {
                "hue_id":       dev.hue_id,
                "bridge_ip":    data.bridge_ip,
                "hue_username": data.username,
                "source":       "philips_hue",
            },
            "state":      {"state": "ON" if dev.on else "OFF"},
            "online":     dev.online,
            "pinned":     False,
            "created_at": int(time.time()),
        })
        imported.append({"hub_id": safe_id, "name": dev.name})
    return {"ok": True, "imported": len(imported), "devices": imported}
