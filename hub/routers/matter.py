"""
Matter protocol support for Fantatech Hub.

Discovery  : mDNS scan — _matterc._udp (uncommissioned) + _matter._tcp (commissioned)
Commission : QR code / setup PIN via python-matter-server (optional)
Control    : On/Off, Brightness, Color Temp via matter-server WebSocket
Fallback   : Works without matter-server — shows discovered devices only

Dependencies (auto-install hint):
  pip install websockets          # WS client — already installed
  pip install python-matter-server  # optional, only for commissioning
"""

import asyncio
import json
import os
import socket
import threading
import time

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

MATTER_SERVER_URL = os.getenv("MATTER_SERVER_URL", "ws://localhost:5580/ws")

# ── Matter device type names (from CSA spec) ──────────────────────────────────
MATTER_DEVICE_TYPES = {
    0x0010: "On/Off Light",
    0x0011: "Dimmable Light",
    0x0012: "Color Temperature Light",
    0x0013: "Extended Color Light",
    0x0015: "On/Off Plug-in Unit",
    0x0101: "Door Lock",
    0x0202: "Window Covering",
    0x0300: "Heating/Cooling Unit",
    0x0301: "Thermostat",
    0x0302: "Temperature Sensor",
    0x0305: "Pressure Sensor",
    0x0306: "Flow Sensor",
    0x0307: "Humidity Sensor",
    0x0840: "On/Off Sensor",
    0x002B: "Fan",
    0x0022: "Speaker",
}


def _matter_type_to_hub_type(dt_id: int) -> str:
    if dt_id in (0x0010, 0x0011, 0x0012, 0x0013):
        return "light"
    if dt_id == 0x0015:
        return "switch"
    if dt_id == 0x0101:
        return "lock"
    if dt_id in (0x0300, 0x0301):
        return "ac"
    if dt_id in (0x0302, 0x0305, 0x0306, 0x0307, 0x0840):
        return "sensor"
    if dt_id == 0x002B:
        return "fan"
    return "switch"


# ── mDNS discovery ────────────────────────────────────────────────────────────

def _scan_matter_mdns(timeout: float = 4.0) -> dict:
    """Discover Matter devices via mDNS.
    Runs in a thread-pool executor — safe to call from async code.
    """
    uncommissioned: dict = {}
    commissioned:   dict = {}

    try:
        from zeroconf import Zeroconf, ServiceBrowser

        class _Listener:
            def __init__(self, target: dict, is_commissioned: bool):
                self.target = target
                self.is_commissioned = is_commissioned

            def add_service(self, zc, type_, name):
                try:
                    info = zc.get_service_info(type_, name)
                    if not info:
                        return
                    ip = socket.inet_ntoa(info.addresses[0]) if info.addresses else None
                    props = {}
                    for k, v in (info.properties or {}).items():
                        try:
                            key = k.decode() if isinstance(k, bytes) else str(k)
                            val = v.decode() if isinstance(v, bytes) else str(v)
                            props[key] = val
                        except Exception:
                            pass
                    device_name   = props.get("DN", name.split(".")[0])
                    vp            = props.get("VP", "")
                    vendor_id     = vp.split("+")[0] if "+" in vp else vp
                    product_id    = vp.split("+")[1] if "+" in vp else ""
                    discriminator = props.get("D", "")
                    dt_raw        = props.get("DT", "0")
                    try:
                        dt_id = int(dt_raw)
                    except ValueError:
                        dt_id = 0
                    dt_name = MATTER_DEVICE_TYPES.get(dt_id, "Matter Device")

                    self.target[name] = {
                        "name":              device_name or dt_name,
                        "ip":                ip,
                        "hostname":          info.server.rstrip(".") if info.server else ip,
                        "port":              info.port,
                        "vendor_id":         vendor_id,
                        "product_id":        product_id,
                        "discriminator":     discriminator,
                        "device_type_id":    dt_id,
                        "device_type_name":  dt_name,
                        "hub_type":          _matter_type_to_hub_type(dt_id),
                        "commissioned":      self.is_commissioned,
                        "props":             props,
                    }
                except Exception as e:
                    print(f"[Matter] mDNS listener error: {e}")

            def remove_service(self, *_): pass
            def update_service(self, *_): pass

        zc = Zeroconf()
        ServiceBrowser(zc, "_matterc._udp.local.", _Listener(uncommissioned, False))
        ServiceBrowser(zc, "_matter._tcp.local.",  _Listener(commissioned,   True))
        # Block this thread (safe — running in executor) for mDNS responses
        import time as _time; _time.sleep(timeout)
        zc.close()

    except Exception as e:
        print(f"[Matter] mDNS scan error: {e}")

    return {
        "uncommissioned": list(uncommissioned.values()),
        "commissioned":   list(commissioned.values()),
        "total":          len(uncommissioned) + len(commissioned),
    }


# ── python-matter-server WebSocket client (uses websockets, not aiohttp) ──────

async def _matter_server_available() -> bool:
    try:
        import websockets
        async with websockets.connect(
            MATTER_SERVER_URL,
            open_timeout=2,
            close_timeout=2,
        ) as ws:
            await asyncio.wait_for(ws.recv(), timeout=2)
            return True
    except Exception:
        return False


async def _matter_cmd(command: str, args: dict | None = None, timeout: float = 15.0):
    """Send command to python-matter-server, return result."""
    try:
        import websockets
    except ImportError:
        raise HTTPException(
            503,
            "websockets לא מותקן. הרץ: pip install websockets"
        )

    # Check if server is even running first
    try:
        import socket as _sock
        host = MATTER_SERVER_URL.split("//")[1].split(":")[0]
        port_str = MATTER_SERVER_URL.split(":")[2].split("/")[0]
        with _sock.create_connection((host, int(port_str)), timeout=1.5):
            pass
    except Exception:
        raise HTTPException(
            503,
            f"Matter Server לא פועל.\n"
            f"הפעל בפקודה:\n"
            f"  pip install python-matter-server\n"
            f"  python -m matter_server --storage-path ./matter_data\n"
            f"(ברירת מחדל: {MATTER_SERVER_URL})"
        )

    msg_id  = str(int(time.time() * 1000))
    payload = {"message_id": msg_id, "command": command}
    if args:
        payload["args"] = args

    try:
        async with websockets.connect(
            MATTER_SERVER_URL,
            open_timeout=5,
            close_timeout=3,
        ) as ws:
            # First message from server is server-info — skip it
            try:
                await asyncio.wait_for(ws.recv(), timeout=3)
            except Exception:
                pass

            await ws.send(json.dumps(payload))

            deadline = time.time() + timeout
            while time.time() < deadline:
                remaining = max(0.5, deadline - time.time())
                raw = await asyncio.wait_for(ws.recv(), timeout=remaining)
                data = json.loads(raw)
                if str(data.get("message_id")) == msg_id:
                    if data.get("error_code"):
                        raise HTTPException(
                            400,
                            f"Matter Server error: {data.get('details', data['error_code'])}"
                        )
                    return data.get("result")

        raise HTTPException(408, "Matter Server לא ענה בזמן")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            503,
            f"שגיאת Matter Server: {e}"
        )


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/status")
async def matter_status():
    available = await _matter_server_available()
    nodes = []
    if available:
        try:
            nodes = await _matter_cmd("get_nodes") or []
        except Exception:
            pass
    return {
        "server_available": available,
        "server_url":       MATTER_SERVER_URL,
        "node_count":       len(nodes),
        "nodes":            nodes,
        "install_hint": (
            None if available else
            "הפעל: pip install python-matter-server && "
            "python -m matter_server --storage-path ./matter_data"
        ),
    }


@router.get("/scan")
async def matter_scan():
    loop = asyncio.get_running_loop()
    result = await asyncio.wait_for(
        loop.run_in_executor(None, _scan_matter_mdns, 4.0),
        timeout=7.0,
    )
    return result


class CommissionIn(BaseModel):
    code:     str
    name:     str = ""
    room:     str = ""
    dev_type: str = "switch"


@router.post("/commission")
async def matter_commission(data: CommissionIn):
    code = data.code.strip()
    if not code:
        raise HTTPException(400, "קוד צימוד חסר")

    result  = await _matter_cmd("commission_with_code", {"code": code})
    node_id = (result or {}).get("node_id") if isinstance(result, dict) else result
    if node_id is None:
        raise HTTPException(500, "הצימוד נכשל — לא התקבל node_id")

    from database import upsert_device
    device_id = f"matter_{node_id}"
    await upsert_device({
        "id":          device_id,
        "name":        data.name or f"Matter Device {node_id}",
        "protocol":    "matter",
        "type":        data.dev_type,
        "topic_state": f"matter/{node_id}/state",
        "topic_cmd":   f"matter/{node_id}/cmd",
        "room":        data.room,
        "config":      {"node_id": node_id, "source": "matter"},
        "state":       {},
        "online":      True,
        "pinned":      False,
        "label":       "Matter",
        "created_at":  int(time.time()),
    })
    return {"ok": True, "node_id": node_id, "device_id": device_id}


class MatterControlIn(BaseModel):
    command:     str
    endpoint_id: int  = 1
    value:       dict = {}


@router.post("/control/{node_id}")
async def matter_control(node_id: int, data: MatterControlIn):
    cmd = data.command.lower()

    if cmd in ("on", "off", "toggle"):
        result = await _matter_cmd("device_command", {
            "node_id":      node_id,
            "endpoint_id":  data.endpoint_id,
            "cluster_id":   6,
            "command_name": cmd,
            "payload":      {},
        })

    elif cmd == "set_level":
        level = max(0, min(254, int(data.value.get("level", 128))))
        result = await _matter_cmd("device_command", {
            "node_id":      node_id,
            "endpoint_id":  data.endpoint_id,
            "cluster_id":   8,
            "command_name": "move_to_level",
            "payload":      {
                "level": level, "transition_time": 0,
                "options_mask": 0, "options_override": 0,
            },
        })

    elif cmd == "set_color_temp":
        mireds = max(153, min(500, int(data.value.get("mireds", 300))))
        result = await _matter_cmd("device_command", {
            "node_id":      node_id,
            "endpoint_id":  data.endpoint_id,
            "cluster_id":   768,
            "command_name": "move_to_color_temperature",
            "payload":      {
                "color_temperature_mireds": mireds, "transition_time": 0,
                "options_mask": 0, "options_override": 0,
            },
        })

    else:
        raise HTTPException(400, f"פקודה לא נתמכת: {cmd}")

    return {"ok": True, "result": result}


@router.get("/nodes")
async def matter_nodes():
    return await _matter_cmd("get_nodes") or []


@router.delete("/nodes/{node_id}")
async def matter_remove_node(node_id: int):
    await _matter_cmd("remove_node", {"node_id": node_id})
    from database import delete_device
    await delete_device(f"matter_{node_id}")
    return {"ok": True}


@router.get("/install-guide")
def matter_install_guide():
    return {
        "steps": [
            {
                "step": 1,
                "title": "התקן python-matter-server",
                "cmd": "pip install python-matter-server",
            },
            {
                "step": 2,
                "title": "הפעל Matter Server",
                "cmd": "python -m matter_server --storage-path ./matter_data",
                "note": "השאר חלון זה פתוח — Matter Server חייב לרוץ ברקע",
            },
            {
                "step": 3,
                "title": "צמד מכשיר",
                "note": "סרוק קוד QR על המכשיר ← לחץ 'צמד' בדף המכשירים",
            },
        ],
        "server_url": MATTER_SERVER_URL,
        "pip_package": "python-matter-server",
        "min_python": "3.10",
    }
