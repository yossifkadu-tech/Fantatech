"""
AC (Air Conditioner) control router.
Supports:
  - Sensibo API  — works with ALL brands via IR (Tadiran, Electra, General, LG…)
  - MQTT         — ESPHome / Tasmota IR blasters
  - Tuya local   — Tuya-based AC controllers (generic)

Israeli brands supported via Sensibo / IR:
  תדיראן, אלקטרה, גנרל, מיצובישי, דייקין, LG, Samsung, Gree/AUX, Haier
"""
import os
import json
import time
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import get_all_devices, get_device, upsert_device, update_device_state, add_history
from mqtt_client import publish

router = APIRouter()

SENSIBO_BASE = "https://home.sensibo.com/api/v2"

# ── Supported brands ──────────────────────────────────────────────────────────

BRANDS = [
    {"id": "tadiran",    "name": "תדיראן (Tadiran)",          "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "electra",    "name": "אלקטרה (Electra)",          "icon": "❄️", "protocols": ["sensibo", "mqtt", "electra"]},
    {"id": "general",    "name": "גנרל (General / Fujitsu)",  "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "mitsubishi", "name": "מיצובישי (Mitsubishi)",     "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "daikin",     "name": "דייקין (Daikin)",           "icon": "❄️", "protocols": ["sensibo", "mqtt", "daikin"]},
    {"id": "lg",         "name": "LG",                        "icon": "❄️", "protocols": ["sensibo", "mqtt", "tuya"]},
    {"id": "samsung",    "name": "Samsung",                   "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "gree",       "name": "Gree / AUX",                "icon": "❄️", "protocols": ["sensibo", "mqtt", "tuya"]},
    {"id": "haier",      "name": "Haier",                     "icon": "❄️", "protocols": ["sensibo", "mqtt", "tuya"]},
    {"id": "carrier",    "name": "Carrier",                   "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "toshiba",    "name": "Toshiba",                   "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "panasonic",  "name": "Panasonic",                 "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "sharp",      "name": "Sharp",                     "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
    {"id": "other",      "name": "אחר / Other",               "icon": "❄️", "protocols": ["sensibo", "mqtt"]},
]

AC_MODES   = ["cool", "heat", "fan", "dry", "auto"]
FAN_LEVELS = ["auto", "quiet", "low", "medium", "high", "strong"]

DEFAULT_AC_STATE = {
    "state": "OFF",
    "mode": "cool",
    "temperature": 24,
    "fan": "auto",
    "swing": False,
    "current_temp": None,
    "current_humidity": None,
}


# ── Pydantic models ───────────────────────────────────────────────────────────

class SensiboKeyIn(BaseModel):
    key: str


class AcCommand(BaseModel):
    state:       str | None = None   # "ON" | "OFF"
    mode:        str | None = None   # cool | heat | fan | dry | auto
    temperature: int | None = None   # 16–30
    fan:         str | None = None   # auto | quiet | low | medium | high | strong
    swing:       bool | None = None


class AddAcIn(BaseModel):
    name:     str
    brand:    str = "other"
    protocol: str = "sensibo"    # sensibo | mqtt | tuya
    room:     str = ""
    # Sensibo-specific
    sensibo_uid: str = ""
    # MQTT-specific
    topic_cmd:   str = ""
    topic_state: str = ""
    # Tuya-specific
    tuya_device_id:  str = ""
    tuya_local_key:  str = ""
    tuya_ip:         str = ""


# ── Sensibo helpers ───────────────────────────────────────────────────────────

def _sensibo_key() -> str:
    key = os.getenv("SENSIBO_API_KEY", "").strip()
    if not key:
        raise HTTPException(503, "מפתח Sensibo לא מוגדר — הגדר ב-Settings")
    return key


async def _sensibo_get(path: str, key: str) -> dict:
    url = f"{SENSIBO_BASE}{path}?apiKey={key}"
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(url)
    if r.status_code != 200:
        raise HTTPException(502, f"Sensibo error {r.status_code}: {r.text[:200]}")
    return r.json()


async def _sensibo_post(path: str, key: str, body: dict) -> dict:
    url = f"{SENSIBO_BASE}{path}?apiKey={key}"
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(url, json=body)
    if r.status_code not in (200, 201):
        raise HTTPException(502, f"Sensibo error {r.status_code}: {r.text[:200]}")
    return r.json()


def _sensibo_to_ac_state(ac_state: dict, measurements: dict | None = None) -> dict:
    """Convert Sensibo acState + measurements → our AC state format."""
    fan_map = {"auto": "auto", "quiet": "quiet", "low": "low",
               "medium": "medium", "high": "high", "strong": "strong"}
    return {
        "state":            "ON" if ac_state.get("on") else "OFF",
        "mode":             ac_state.get("mode", "cool"),
        "temperature":      ac_state.get("targetTemperature", 24),
        "fan":              fan_map.get(ac_state.get("fanLevel", "auto"), "auto"),
        "swing":            ac_state.get("swing", "stopped") != "stopped",
        "current_temp":     measurements.get("temperature") if measurements else None,
        "current_humidity": measurements.get("humidity")    if measurements else None,
    }


def _ac_state_to_sensibo(ac_state: dict) -> dict:
    """Convert our AC state → Sensibo acState format."""
    return {
        "on":                ac_state.get("state") == "ON",
        "mode":              ac_state.get("mode", "cool"),
        "targetTemperature": ac_state.get("temperature", 24),
        "fanLevel":          ac_state.get("fan", "auto"),
        "swing":             "rangeFull" if ac_state.get("swing") else "stopped",
    }


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/brands")
async def list_brands():
    return BRANDS


@router.post("/sensibo/set-key")
async def set_sensibo_key(body: SensiboKeyIn):
    key = body.key.strip()
    env_path = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '.env'))
    try:
        with open(env_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        new_lines, found = [], False
        for line in lines:
            if line.startswith('SENSIBO_API_KEY='):
                new_lines.append(f'SENSIBO_API_KEY={key}\n')
                found = True
            else:
                new_lines.append(line)
        if not found:
            new_lines.append(f'SENSIBO_API_KEY={key}\n')
        with open(env_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        os.environ['SENSIBO_API_KEY'] = key
    except Exception as e:
        raise HTTPException(500, f"שגיאה בשמירת המפתח: {e}")
    return {"ok": True}


@router.get("/sensibo/status")
async def sensibo_status():
    key = os.getenv("SENSIBO_API_KEY", "").strip()
    return {"configured": bool(key)}


@router.get("/sensibo/devices")
async def sensibo_devices():
    """List all AC pods from the Sensibo account."""
    key = _sensibo_key()
    data = await _sensibo_get(
        "/users/me/pods?fields=id,room,acState,measurements,productModel,firmwareVersion",
        key
    )
    pods = data.get("result", [])
    result = []
    for pod in pods:
        measurements = pod.get("measurements", {}) or {}
        ac_state = pod.get("acState", {}) or {}
        result.append({
            "uid":   pod["id"],
            "name":  (pod.get("room") or {}).get("name", pod["id"]),
            "model": pod.get("productModel", "Sensibo"),
            "state": _sensibo_to_ac_state(ac_state, measurements),
        })
    return result


@router.post("/sensibo/import")
async def sensibo_import():
    """Import all Sensibo pods as AC devices into the hub DB."""
    key = _sensibo_key()
    pods = await sensibo_devices()
    imported = 0
    for pod in pods:
        device_id = f"ac_sensibo_{pod['uid']}"
        record = {
            "id":          device_id,
            "name":        pod["name"],
            "protocol":    "sensibo",
            "type":        "ac",
            "topic_state": f"devices/{device_id}/state",
            "topic_cmd":   f"devices/{device_id}/cmd",
            "room":        "",
            "label":       pod.get("model", "Sensibo"),
            "config":      {"sensibo_uid": pod["uid"], "source": "sensibo"},
            "state":       pod["state"],
            "online":      True,
            "pinned":      False,
            "created_at":  int(time.time()),
        }
        await upsert_device(record)
        imported += 1
    return {"ok": True, "imported": imported,
            "message": f"✅ יובאו {imported} מזגנים מ-Sensibo"}


@router.post("/add")
async def add_ac(data: AddAcIn):
    """Manually add an AC device."""
    device_id = f"ac_{data.brand}_{int(time.time())}"
    brand_info = next((b for b in BRANDS if b["id"] == data.brand), BRANDS[-1])

    topic_state = data.topic_state or f"devices/{device_id}/state"
    topic_cmd   = data.topic_cmd   or f"devices/{device_id}/cmd"

    record = {
        "id":          device_id,
        "name":        data.name,
        "protocol":    data.protocol,
        "type":        "ac",
        "topic_state": topic_state,
        "topic_cmd":   topic_cmd,
        "room":        data.room,
        "label":       brand_info["name"],
        "config":      {
            "brand":          data.brand,
            "sensibo_uid":    data.sensibo_uid,
            "tuya_device_id": data.tuya_device_id,
            "tuya_local_key": data.tuya_local_key,
            "tuya_ip":        data.tuya_ip,
        },
        "state":       dict(DEFAULT_AC_STATE),
        "online":      bool(data.sensibo_uid or data.topic_cmd),
        "pinned":      False,
        "created_at":  int(time.time()),
    }
    await upsert_device(record)
    return record


@router.post("/control/{device_id}")
async def control_ac(device_id: str, cmd: AcCommand):
    """Control an AC device — works with Sensibo, MQTT, or Tuya."""
    device = await get_device(device_id)
    if not device:
        raise HTTPException(404, "מזגן לא נמצא")

    # Merge new command into current state
    current = dict(DEFAULT_AC_STATE)
    current.update(device.get("state", {}))

    if cmd.state       is not None: current["state"]       = cmd.state
    if cmd.mode        is not None: current["mode"]        = cmd.mode
    if cmd.temperature is not None: current["temperature"] = max(16, min(30, cmd.temperature))
    if cmd.fan         is not None: current["fan"]         = cmd.fan
    if cmd.swing       is not None: current["swing"]       = cmd.swing

    protocol = device.get("protocol", "mqtt")
    config   = device.get("config", {})

    # ── Sensibo ───────────────────────────────────────────────────────────────
    if protocol == "sensibo":
        sensibo_uid = config.get("sensibo_uid", "")
        if not sensibo_uid:
            raise HTTPException(400, "Sensibo UID חסר בהגדרות המכשיר")
        key = _sensibo_key()
        sensibo_body = {"acState": _ac_state_to_sensibo(current)}
        await _sensibo_post(f"/pods/{sensibo_uid}/acStates", key, sensibo_body)

        # Re-fetch measurements from Sensibo to update current temp/humidity
        try:
            pod_data = await _sensibo_get(
                f"/pods/{sensibo_uid}?fields=acState,measurements", key
            )
            pod = pod_data.get("result", {})
            measurements = pod.get("measurements", {}) or {}
            current["current_temp"]     = measurements.get("temperature")
            current["current_humidity"] = measurements.get("humidity")
        except Exception:
            pass

    # ── MQTT (ESPHome / Tasmota IR / Generic) ─────────────────────────────────
    elif protocol in ("mqtt", "wifi", "custom"):
        # Build MQTT payload based on topic pattern
        topic = device.get("topic_cmd", f"devices/{device_id}/cmd")

        if "cmnd/" in topic:
            # Tasmota IR HVAC format
            payload = {
                "Vendor":       config.get("brand", "TADIRAN").upper(),
                "Power":        current["state"],
                "Mode":         current["mode"].capitalize(),
                "Celsius":      True,
                "Temp":         current["temperature"],
                "FanSpeed":     current["fan"].capitalize(),
                "SwingV":       "Auto" if current.get("swing") else "Off",
            }
        else:
            # Generic / ESPHome climate format
            payload = {
                "state":       current["state"],
                "mode":        current["mode"]   if current["state"] == "ON" else "off",
                "temperature": current["temperature"],
                "fan_mode":    current["fan"],
                "swing_mode":  "on" if current.get("swing") else "off",
            }
        publish(topic, payload)

    # ── Tuya (stub — needs tinytuya installed) ────────────────────────────────
    elif protocol == "tuya":
        try:
            import tinytuya
            d = tinytuya.Device(
                config.get("tuya_device_id"),
                config.get("tuya_ip"),
                config.get("tuya_local_key"),
                version=3.3,
            )
            # Map to Tuya DPS (device-specific, common for AC controllers)
            dps = {}
            if cmd.state is not None:
                dps["1"] = (current["state"] == "ON")
            if cmd.temperature is not None:
                dps["2"] = current["temperature"]
            if cmd.mode is not None:
                mode_map = {"cool": "cold", "heat": "hot", "fan": "wind", "dry": "wet", "auto": "auto"}
                dps["4"] = mode_map.get(current["mode"], "cold")
            if cmd.fan is not None:
                fan_map = {"auto": "auto", "low": "low", "medium": "middle", "high": "high"}
                dps["5"] = fan_map.get(current["fan"], "auto")
            if dps:
                d.set_multiple_values(dps)
        except ImportError:
            raise HTTPException(503, "tinytuya לא מותקן — הרץ: pip install tinytuya")
        except Exception as e:
            raise HTTPException(500, f"שגיאת Tuya: {e}")

    # ── Update DB + history ───────────────────────────────────────────────────
    await update_device_state(device_id, current, online=True)
    action_desc = f"{current['state']} {current['mode']} {current['temperature']}°"
    await add_history(device_id, device["name"], "ac_cmd", action_desc)

    return {"ok": True, "state": current}


@router.get("/status/{device_id}")
async def ac_status(device_id: str):
    """Get live status from Sensibo (or return cached state for other protocols)."""
    device = await get_device(device_id)
    if not device:
        raise HTTPException(404, "מזגן לא נמצא")

    protocol = device.get("protocol", "mqtt")
    config   = device.get("config", {})

    if protocol == "sensibo" and config.get("sensibo_uid"):
        try:
            key      = _sensibo_key()
            pod_data = await _sensibo_get(
                f"/pods/{config['sensibo_uid']}?fields=acState,measurements", key
            )
            pod   = pod_data.get("result", {})
            state = _sensibo_to_ac_state(
                pod.get("acState", {}),
                pod.get("measurements", {})
            )
            await update_device_state(device_id, state, online=True)
            return state
        except Exception:
            pass

    return device.get("state", DEFAULT_AC_STATE)


@router.get("/devices")
async def list_ac_devices():
    """Return all AC-type devices."""
    all_devices = await get_all_devices()
    return [d for d in all_devices if d.get("type") == "ac"]
