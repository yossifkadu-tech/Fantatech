"""
Zigbee support for Fantatech Hub.

Discovery : ARP + port scan → Zigbee2MQTT (port 8080), deCONZ (port 80), Hue (port 80)
Devices   : Zigbee2MQTT → via MQTT (zigbee2mqtt/bridge/devices)
            deCONZ      → REST API (needs API key)
            Hue         → REST API (needs link-button press)
Control   : Zigbee2MQTT → MQTT publish to zigbee2mqtt/{name}/set
"""

import asyncio
import json
import platform
import re
import socket
import subprocess
import time
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

# ── Cached state ──────────────────────────────────────────────────────────────
_z2m_devices: list = []
_z2m_bridge_info: dict = {}
_last_devices_ts: float = 0   # epoch when cache was last written


# ── Device type helpers ───────────────────────────────────────────────────────

def _z2m_type_to_hub_type(definition: dict) -> str:
    exposes = (definition or {}).get("exposes", [])
    feature_names: set = set()
    for exp in exposes:
        t = exp.get("type", "")
        if t == "light":   return "light"
        if t == "switch":  return "switch"
        if t == "fan":     return "fan"
        if t == "lock":    return "lock"
        if t == "climate": return "ac"
        feature_names.add(exp.get("name", ""))
        for feat in exp.get("features", []):
            feature_names.add(feat.get("name", ""))
    if feature_names & {"brightness", "color_temp", "color_xy"}:
        return "light"
    if feature_names & {"temperature", "humidity", "contact",
                        "occupancy", "illuminance", "pressure"}:
        return "sensor"
    return "switch"


_ICON = {"light": "💡", "switch": "🔌", "sensor": "🌡️",
         "lock": "🔒", "fan": "🌀", "ac": "❄️"}


# ── MQTT state writers (called from main.py MQTT handler) ─────────────────────

def update_z2m_devices(payload):
    """Called when zigbee2mqtt/bridge/devices arrives."""
    global _z2m_devices, _last_devices_ts
    if isinstance(payload, list):
        _z2m_devices = payload
        _last_devices_ts = time.time()


def update_z2m_bridge_info(payload):
    """Called when zigbee2mqtt/bridge/info arrives."""
    global _z2m_bridge_info
    if isinstance(payload, dict):
        _z2m_bridge_info = payload


# ── Network helpers ───────────────────────────────────────────────────────────

def _local_subnet() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]; s.close()
        return ".".join(ip.split(".")[:3])
    except Exception:
        return "192.168.1"


def _arp_ips(subnet: str) -> list[str]:
    ips = []
    try:
        cmd = ["arp", "-a"] if platform.system() == "Windows" else ["arp", "-an"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=3).stdout
        for m in re.finditer(r'(\d{1,3}(?:\.\d{1,3}){3})', out):
            ip = m.group(1)
            if ip.startswith(subnet + "."):
                ips.append(ip)
    except Exception:
        pass
    return list(dict.fromkeys(ips))   # deduplicate, preserve order


def _tcp_open(ip: str, port: int, timeout: float = 0.7) -> bool:
    try:
        with socket.create_connection((ip, port), timeout=timeout):
            return True
    except OSError:
        return False


async def _port_open(ip: str, port: int, timeout: float = 0.7) -> bool:
    loop = asyncio.get_running_loop()
    try:
        return await asyncio.wait_for(
            loop.run_in_executor(None, _tcp_open, ip, port, timeout),
            timeout=timeout + 0.3
        )
    except Exception:
        return False


async def _http_get(url: str, timeout: float = 2.5) -> Optional[tuple[int, str]]:
    """Return (status, text) or None."""
    try:
        import aiohttp
        async with aiohttp.ClientSession() as s:
            async with s.get(url, timeout=aiohttp.ClientTimeout(total=timeout)) as r:
                return (r.status, await r.text())
    except Exception:
        return None


async def _identify(ip: str) -> Optional[dict]:
    """Probe a single IP for Zigbee bridges; return bridge dict or None."""
    open8080 = await _port_open(ip, 8080)
    open80   = await _port_open(ip, 80)

    if not open8080 and not open80:
        return None

    # ── Zigbee2MQTT (port 8080) ───────────────────────────────────────────────
    if open8080:
        res = await _http_get(f"http://{ip}:8080/")
        if res:
            status, text = res
            tl = text[:3000].lower()
            if status == 200 and ("zigbee2mqtt" in tl or "z2m" in tl or
                                   "bridge" in tl or "coordinator" in tl):
                return {
                    "type": "zigbee2mqtt", "confirmed": True,
                    "ip": ip, "port": 8080,
                    "url": f"http://{ip}:8080",
                    "name": "Zigbee2MQTT",
                    "icon": "🔶",
                    "hint": "מחובר דרך MQTT",
                }
            if status == 200:
                return {
                    "type": "zigbee2mqtt", "confirmed": False,
                    "ip": ip, "port": 8080,
                    "url": f"http://{ip}:8080",
                    "name": f"שירות לא מזוהה @ {ip}:8080",
                    "icon": "❓", "hint": "",
                }

    # ── deCONZ / Phoscon (port 80) ────────────────────────────────────────────
    if open80:
        res = await _http_get(f"http://{ip}/api/config")
        if res:
            status, text = res
            if status == 200:
                try:
                    data = json.loads(text)
                    if "bridgeid" in data or "apiversion" in data:
                        return {
                            "type": "deconz", "confirmed": True,
                            "ip": ip, "port": 80,
                            "url": f"http://{ip}",
                            "name": data.get("name", "deCONZ Gateway"),
                            "icon": "🟣",
                            "bridgeid": data.get("bridgeid", ""),
                            "hint": "נדרש API key",
                        }
                    # Philips Hue bridge
                    if "modelid" in data or data.get("swversion"):
                        return {
                            "type": "hue", "confirmed": True,
                            "ip": ip, "port": 80,
                            "url": f"http://{ip}",
                            "name": data.get("name", "Philips Hue Bridge"),
                            "icon": "🟡",
                            "modelid": data.get("modelid", ""),
                            "hint": "לחץ כפתור על הגשר לחיבור",
                        }
                except Exception:
                    pass

    return None


async def _scan_subnet(subnet: str) -> list[dict]:
    """Scan subnet; try ARP hosts + common IPs."""
    candidates = _arp_ips(subnet)
    for last in [1, 2, 100, 101, 105, 150, 200, 250, 254]:
        ip = f"{subnet}.{last}"
        if ip not in candidates:
            candidates.append(ip)

    results = await asyncio.gather(
        *[_identify(ip) for ip in candidates],
        return_exceptions=True
    )
    return [r for r in results if r and not isinstance(r, Exception)]


# ── Formatting ────────────────────────────────────────────────────────────────

def _format_z2m(raw_list: list) -> list:
    out = []
    for d in raw_list:
        if d.get("type") == "Coordinator":
            continue
        defn = d.get("definition") or {}
        hub_type = _z2m_type_to_hub_type(defn)
        out.append({
            "ieee_addr":      d.get("ieee_address", ""),
            "friendly_name":  d.get("friendly_name", d.get("ieee_address", "Unknown")),
            "model":          defn.get("model", ""),
            "vendor":         defn.get("vendor", ""),
            "description":    defn.get("description", ""),
            "hub_type":       hub_type,
            "icon":           _ICON.get(hub_type, "📡"),
            "supported":      d.get("supported", True),
            "interview_completed": d.get("interview_completed", True),
            "link_quality":   d.get("link_quality", 0),
            "last_seen":      d.get("last_seen", ""),
            "power_source":   d.get("power_source", ""),
            "mqtt_topic":     f"zigbee2mqtt/{d.get('friendly_name', '')}",
        })
    return out


# ── Endpoints ──────────────────────────────────────────────────────────────────

@router.get("/status")
async def zigbee_status():
    """Zigbee2MQTT live status (from MQTT)."""
    return {
        "z2m_active":       len(_z2m_devices) > 0,
        "z2m_device_count": len([d for d in _z2m_devices if d.get("type") != "Coordinator"]),
        "last_update":      _last_devices_ts,
        "bridge_info":      _z2m_bridge_info,
    }


@router.get("/scan")
async def zigbee_scan():
    """Scan local subnet for Zigbee bridges."""
    subnet = _local_subnet()
    bridges = await _scan_subnet(subnet)
    return {
        "bridges":         bridges,
        "total":           len(bridges),
        "subnet":          subnet,
        "z2m_mqtt_active": len(_z2m_devices) > 0,
        "z2m_device_count": len([d for d in _z2m_devices
                                 if d.get("type") != "Coordinator"]),
    }


@router.get("/devices")
async def zigbee_get_devices(bridge_type: str = "zigbee2mqtt", bridge_ip: str = ""):
    """
    Get device list from a Zigbee bridge.
    For Zigbee2MQTT: uses MQTT cache; requests fresh data if stale.
    """
    if bridge_type == "zigbee2mqtt":
        # Fresh enough — return cached
        if _z2m_devices and (time.time() - _last_devices_ts) < 60:
            return {"devices": _format_z2m(
                _z2m_devices), "source": "mqtt_cache", "hint": ""}

        # Request fresh list via MQTT
        try:
            from mqtt_client import publish
            publish("zigbee2mqtt/bridge/request/devices", "")
        except Exception:
            pass

        await asyncio.sleep(2.5)

        if _z2m_devices:
            return {"devices": _format_z2m(_z2m_devices), "source": "mqtt_fresh", "hint": ""}

        return {
            "devices": [],
            "source":  "mqtt",
            "hint":    "לא התקבלה תשובה מ-Zigbee2MQTT. ודא ש-Z2M פועל ומחובר ל-MQTT.",
        }

    elif bridge_type == "deconz":
        return {
            "devices": [],
            "hint":    (f"deCONZ ב-{bridge_ip} דורש API key. "
                        "פתח את Phoscon App → Settings → Gateway → Advanced → "
                        "Authentication → צור API key."),
        }

    elif bridge_type == "hue":
        return {
            "devices": [],
            "hint":    (f"Hue Bridge ב-{bridge_ip}. "
                        "לחץ את הכפתור הגדול על הגשר ואז נסה שוב."),
            "needs_link_button": True,
        }

    return {"devices": [], "hint": "סוג גשר לא נתמך"}


class ImportIn(BaseModel):
    ieee_addr:     str
    friendly_name: str
    hub_type:      str = "switch"
    room:          str = ""
    custom_name:   str = ""
    bridge_ip:     str = ""


@router.post("/import")
async def zigbee_import(data: ImportIn):
    """Import a Zigbee device into the hub database."""
    from database import upsert_device

    name = (data.custom_name.strip() or data.friendly_name).strip()
    if not name:
        raise HTTPException(400, "שם המכשיר חסר")

    safe = re.sub(r'[^a-zA-Z0-9]', '_', data.ieee_addr)
    device_id = f"zigbee_{safe}"
    topic_base = f"zigbee2mqtt/{data.friendly_name}"

    await upsert_device({
        "id":          device_id,
        "name":        name,
        "protocol":    "zigbee",
        "type":        data.hub_type,
        "topic_state": topic_base,
        "topic_cmd":   f"{topic_base}/set",
        "room":        data.room,
        "config":      {
            "ieee_addr":     data.ieee_addr,
            "friendly_name": data.friendly_name,
            "bridge_ip":     data.bridge_ip,
            "source":        "zigbee2mqtt",
        },
        "state":       {},
        "online":      True,
        "pinned":      False,
        "label":       "Zigbee",
        "created_at":  int(time.time()),
    })

    # Subscribe MQTT client to this device's state topic
    try:
        from mqtt_client import subscribe as mqtt_sub
        mqtt_sub(topic_base)
    except Exception:
        pass

    return {"ok": True, "device_id": device_id, "name": name}


class ControlIn(BaseModel):
    state:       Optional[str] = None   # ON / OFF / TOGGLE
    brightness:  Optional[int] = None   # 0-254
    color_temp:  Optional[int] = None   # mireds
    payload:     dict = {}              # raw Z2M payload


@router.post("/control/{device_id}")
async def zigbee_control(device_id: str, data: ControlIn):
    """Control a Zigbee device via Zigbee2MQTT MQTT."""
    from database import get_device
    from mqtt_client import publish

    dev = await get_device(device_id)
    if not dev:
        raise HTTPException(404, "מכשיר לא נמצא")

    friendly_name = dev.get("config", {}).get("friendly_name", "")
    if not friendly_name:
        raise HTTPException(400, "friendly_name חסר בהגדרות המכשיר")

    cmd: dict = dict(data.payload)
    if data.state:
        cmd["state"] = data.state.upper()
    if data.brightness is not None:
        cmd["brightness"] = max(0, min(254, data.brightness))
    if data.color_temp is not None:
        cmd["color_temp"] = max(153, min(500, data.color_temp))

    if not cmd:
        raise HTTPException(400, "אין פקודה לשליחה")

    publish(f"zigbee2mqtt/{friendly_name}/set", cmd)
    return {"ok": True, "sent": cmd}


# Optional: re-export subscribe helper so main.py can call zigbee.subscribe_topics()
def subscribe_topics():
    """Called from startup to subscribe to Z2M topics."""
    try:
        from mqtt_client import subscribe as mqtt_sub
        mqtt_sub("zigbee2mqtt/bridge/devices")
        mqtt_sub("zigbee2mqtt/bridge/info")
        mqtt_sub("zigbee2mqtt/+")          # per-device state updates
        print("[Zigbee] Subscribed to zigbee2mqtt/# topics")
    except Exception as e:
        print(f"[Zigbee] Subscribe failed: {e}")
