"""
Tuya / Moes Multi-Mode Gateway driver for Fantatech Hub.

Discovery  : tinytuya LAN scanner (UDP 6666/6667)
Pairing    : device_id + local_key (from Tuya IoT Platform or Smart Life app)
Sub-devices: list Zigbee / BLE / WiFi devices paired to the gateway
Control    : tinytuya local protocol (port 6668, AES-encrypted)
Import     : saves sub-devices to hub DB
"""

import asyncio
import json
import time
import re
import socket
import platform
import subprocess
import threading
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import upsert_device, get_all_devices

router = APIRouter()
IS_WIN = platform.system() == "Windows"

# ── In-memory state ───────────────────────────────────────────────────────────
_scan_cache:   list  = []       # last LAN scan results
_scan_ts:      float = 0        # epoch of last scan
_paired:       dict  = {}       # device_id → {ip, local_key, name, ...}

TUYA_TYPE_MAP = {
    "gateway": "gateway", "hub": "gateway", "bridge": "gateway",
    "light": "light", "bulb": "light", "lamp": "light", "led": "light",
    "switch": "switch", "plug": "switch", "socket": "switch", "outlet": "switch",
    "dimmer": "dimmer",
    "sensor": "sensor", "temp": "sensor", "humidity": "sensor",
    "motion": "motion", "pir": "motion",
    "door": "door", "window": "door", "contact": "door",
    "smoke": "smoke",
    "lock": "lock",
    "fan": "fan",
    "curtain": "switch", "blind": "switch",
    "camera": "camera",
}


def _guess_type(product_name: str, category: str = "") -> str:
    text = (product_name + " " + category).lower()
    for key, hub_type in TUYA_TYPE_MAP.items():
        if key in text:
            return hub_type
    return "switch"


# ── LAN scan ─────────────────────────────────────────────────────────────────

def _do_scan(timeout: int = 8) -> list:
    """Blocking Tuya LAN scan. Run in executor."""
    try:
        import tinytuya
        devices = tinytuya.deviceScan(verbose=False, maxretry=timeout, color=False)
        if isinstance(devices, dict):
            devices = list(devices.values())
        return devices or []
    except Exception as e:
        print(f"[Tuya] Scan error: {e}")
        return []


async def _arp_tuya_ips() -> list:
    """Quick pre-check: return IPs that have port 6668 open."""
    try:
        cmd = ["arp", "-a"] if IS_WIN else ["arp", "-an"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=3).stdout
        ips = re.findall(r'(\d{1,3}(?:\.\d{1,3}){3})', out)
        results = []
        loop = asyncio.get_running_loop()
        async def _check(ip):
            try:
                await asyncio.wait_for(
                    loop.run_in_executor(None, lambda: socket.create_connection((ip, 6668), 0.4)),
                    timeout=0.6
                )
                return ip
            except Exception:
                return None
        tasks = await asyncio.gather(*[_check(ip) for ip in ips], return_exceptions=True)
        return [ip for ip in tasks if ip and isinstance(ip, str)]
    except Exception:
        return []


# ── Sub-device helpers ────────────────────────────────────────────────────────

def _get_subdevices_blocking(ip: str, device_id: str, local_key: str) -> list:
    """Fetch sub-device list from gateway using tinytuya."""
    try:
        import tinytuya
        gw = tinytuya.Device(device_id, ip, local_key, connection_timeout=5, version=3.3)
        # Try to get sub-device list via DPS 6 (gateway query)
        status = gw.status()
        if not status:
            return []
        dps = status.get("dps", {})
        # Sub-device info is sometimes in DPS 101 or returned as a separate query
        # Try generic approach: ask for child devices list
        try:
            resp = gw.sendrequest({"gwId": device_id, "devId": device_id})
        except Exception:
            resp = None

        # Build basic info from gateway status if no explicit child list
        sub = []
        for k, v in dps.items():
            if isinstance(v, bool) or isinstance(v, int) and k.isdigit():
                sub.append({
                    "node_id": k,
                    "name": f"מכשיר Zigbee {k}",
                    "online": True,
                    "state": {"state": "ON" if v else "OFF"},
                })
        return sub
    except Exception as e:
        print(f"[Tuya] Sub-device fetch failed: {e}")
        return []


def _control_device_blocking(ip: str, device_id: str, local_key: str,
                               payload: dict, version: float = 3.3) -> dict:
    """Send local command to Tuya device. Blocking — run in executor."""
    try:
        import tinytuya
        dev = tinytuya.Device(device_id, ip, local_key, connection_timeout=5, version=version)
        if "state" in payload:
            val = str(payload["state"]).upper() in ("ON", "1", "TRUE")
            dev.set_value(1, val)
        elif "brightness" in payload:
            dev.set_value(3, int(payload["brightness"]))
        elif "color_temp" in payload:
            dev.set_value(4, int(payload["color_temp"]))
        else:
            for k, v in payload.items():
                if str(k).isdigit():
                    dev.set_value(int(k), v)
        return {"ok": True}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def _get_status_blocking(ip: str, device_id: str, local_key: str) -> dict:
    """Get device status. Blocking."""
    try:
        import tinytuya
        dev = tinytuya.Device(device_id, ip, local_key, connection_timeout=5, version=3.3)
        return dev.status() or {}
    except Exception as e:
        return {"error": str(e)}


# ── Pydantic models ───────────────────────────────────────────────────────────

class PairIn(BaseModel):
    device_id: str
    local_key:  str
    ip:        str
    name:      str = "Moes Gateway"
    version:   float = 3.3

class ControlIn(BaseModel):
    device_id: str
    ip:        str
    local_key: str
    payload:   dict
    version:   float = 3.3

class ImportSubIn(BaseModel):
    gateway_device_id: str
    gateway_ip:        str
    gateway_local_key: str
    node_id:           str
    name:              str
    hub_type:          str = "switch"
    room:              str = ""

class ImportGatewayIn(BaseModel):
    device_id: str
    ip:        str
    local_key: str
    name:      str = "Moes Gateway"
    room:      str = ""
    version:   float = 3.3


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/scan")
async def tuya_scan(force: bool = False):
    """
    Discover Tuya devices on the LAN.
    Uses cached result unless force=true or cache is >60s old.
    """
    global _scan_cache, _scan_ts
    if not force and _scan_cache and (time.time() - _scan_ts) < 60:
        return {"devices": _scan_cache, "cached": True, "ts": _scan_ts}

    # First get ARP-visible IPs with port 6668 open (fast pre-check)
    arp_ips = await _arp_tuya_ips()

    # Full tinytuya scan in background executor
    loop = asyncio.get_running_loop()
    devices = await loop.run_in_executor(None, _do_scan, 6)

    # Enrich with ARP candidates that weren't found by scan
    found_ips = {d.get("ip") for d in devices if d.get("ip")}
    for ip in arp_ips:
        if ip not in found_ips:
            devices.append({
                "ip":       ip,
                "gwId":     "",
                "active":   1,
                "ability":  0,
                "encrypt":  True,
                "productKey": "",
                "version":  "3.3",
                "name":     f"Tuya Device @ {ip}",
            })

    # Normalize & annotate
    out = []
    existing_ids = {d.get("config", {}).get("tuya_device_id", "")
                    for d in await get_all_devices()}
    for d in devices:
        gw_id = d.get("gwId") or d.get("id") or ""
        out.append({
            "ip":         d.get("ip", ""),
            "device_id":  gw_id,
            "name":       d.get("name") or d.get("productKey") or f"Tuya @ {d.get('ip','')}",
            "version":    str(d.get("version", "3.3")),
            "encrypted":  d.get("encrypt", True),
            "product_key":d.get("productKey", ""),
            "is_gateway": ("gateway" in (d.get("name","") + d.get("productKey","")).lower()
                           or d.get("ability", 0) & 128 != 0),
            "already_paired": gw_id in _paired or gw_id in existing_ids,
        })

    _scan_cache = out
    _scan_ts    = time.time()
    return {"devices": out, "cached": False, "ts": _scan_ts}


@router.post("/pair")
async def tuya_pair(data: PairIn):
    """
    Save gateway credentials.
    Verifies connectivity before saving.
    """
    loop = asyncio.get_running_loop()
    status = await loop.run_in_executor(
        None, _get_status_blocking, data.ip, data.device_id, data.local_key
    )
    if "error" in status and not status.get("dps"):
        raise HTTPException(400, f"לא ניתן להתחבר: {status.get('error','שגיאה לא ידועה')}")

    _paired[data.device_id] = {
        "ip": data.ip, "local_key": data.local_key,
        "name": data.name, "version": data.version,
        "paired_at": time.time(),
    }
    return {"ok": True, "dps": status.get("dps", {})}


@router.get("/subdevices/{device_id}")
async def tuya_subdevices(device_id: str, ip: str, local_key: str):
    """List sub-devices (Zigbee/BLE) from a Moes/Tuya gateway."""
    loop = asyncio.get_running_loop()
    subs = await loop.run_in_executor(
        None, _get_subdevices_blocking, ip, device_id, local_key
    )
    return {"subdevices": subs, "count": len(subs)}


@router.get("/status/{device_id}")
async def tuya_status(device_id: str, ip: str, local_key: str):
    """Read live DPS status from a Tuya device."""
    loop = asyncio.get_running_loop()
    status = await loop.run_in_executor(
        None, _get_status_blocking, ip, device_id, local_key
    )
    return status


@router.post("/control")
async def tuya_control(data: ControlIn):
    """Send a local command to a Tuya device."""
    loop = asyncio.get_running_loop()
    result = await loop.run_in_executor(
        None, _control_device_blocking,
        data.ip, data.device_id, data.local_key, data.payload, data.version
    )
    if not result.get("ok"):
        raise HTTPException(500, result.get("error", "שגיאת שליטה"))
    return {"ok": True}


@router.post("/import-gateway")
async def import_gateway(data: ImportGatewayIn):
    """Import the gateway itself as a hub device."""
    dev_id = f"tuya_{re.sub(r'[^a-zA-Z0-9]', '_', data.device_id)}"
    await upsert_device({
        "id":          dev_id,
        "name":        data.name,
        "protocol":    "tuya",
        "type":        "gateway",
        "topic_state": f"devices/{dev_id}/state",
        "topic_cmd":   f"devices/{dev_id}/cmd",
        "room":        data.room,
        "label":       "Moes / Tuya",
        "config": {
            "tuya_device_id": data.device_id,
            "tuya_ip":        data.ip,
            "tuya_local_key": data.local_key,
            "tuya_version":   data.version,
            "source":         "tuya_gateway",
        },
        "state":    {"state": "ON"},
        "online":   True,
        "pinned":   False,
        "created_at": int(time.time()),
    })
    return {"ok": True, "device_id": dev_id}


@router.post("/import-subdevice")
async def import_subdevice(data: ImportSubIn):
    """Import a sub-device (Zigbee/BLE) paired to the gateway."""
    safe = re.sub(r'[^a-zA-Z0-9]', '_', f"{data.gateway_device_id}_{data.node_id}")
    dev_id = f"tuya_sub_{safe}"
    await upsert_device({
        "id":          dev_id,
        "name":        data.name,
        "protocol":    "tuya",
        "type":        data.hub_type,
        "topic_state": f"devices/{dev_id}/state",
        "topic_cmd":   f"devices/{dev_id}/cmd",
        "room":        data.room,
        "label":       "Moes Gateway",
        "config": {
            "tuya_device_id":      data.gateway_device_id,
            "tuya_ip":             data.gateway_ip,
            "tuya_local_key":      data.gateway_local_key,
            "tuya_node_id":        data.node_id,
            "source":              "tuya_subdevice",
        },
        "state":    {},
        "online":   True,
        "pinned":   False,
        "created_at": int(time.time()),
    })
    return {"ok": True, "device_id": dev_id}


@router.get("/help")
def tuya_help():
    """Returns step-by-step guide to get device_id and local_key."""
    return {
        "steps": [
            {
                "step": 1,
                "title": "התקן Smart Life / Tuya Smart",
                "detail": "הורד את Smart Life מחנות האפליקציות וצמד את ה-Gateway.",
            },
            {
                "step": 2,
                "title": "צור חשבון מפתח Tuya IoT",
                "detail": (
                    "כנס ל-https://iot.tuya.com ← Create Account\n"
                    "צור Cloud Project (Protocol: Smart Home)\n"
                    "קשר את Smart Life App לפרויקט (Link Account)"
                ),
            },
            {
                "step": 3,
                "title": "קבל Device ID",
                "detail": (
                    "ב-Smart Life App: לחץ על הGateway ← עריכה (עיפרון) ← "
                    "פרטים נוספים ← ID וירטואלי = Device ID"
                ),
            },
            {
                "step": 4,
                "title": "קבל Local Key",
                "detail": (
                    "ב-Tuya IoT Platform:\n"
                    "Cloud → Development → [הפרויקט שלך] → Devices\n"
                    "חפש את ה-Gateway לפי Device ID ← לחץ עליו ← "
                    "Device Secret = Local Key"
                ),
            },
            {
                "step": 5,
                "title": "חבר ב-Fantatech Hub",
                "detail": "הכנס IP + Device ID + Local Key בדף המכשירים.",
            },
        ]
    }
