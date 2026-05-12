"""
alexa.py — Emulated Philips Hue Bridge for Amazon Alexa
────────────────────────────────────────────────────────
Alexa discovers the hub as a Hue Bridge on the local network via SSDP/UPnP.
Every FantaTech device (light / switch / dimmer / fan / ac) appears as a
Hue "light" that Alexa can control by voice.

Voice commands that work once set up:
  "Alexa, turn on the living room light"
  "Alexa, turn off all lights"
  "Alexa, dim the bedroom to 50%"
  "Alexa, discover devices"

Endpoints served:
  GET  /description.xml           ← UPnP device description
  POST /api                       ← Hue pairing (accept any username)
  GET  /api/{user}                ← full bridge config
  GET  /api/{user}/lights         ← all lights (= all devices)
  GET  /api/{user}/lights/{id}    ← single light
  PUT  /api/{user}/lights/{id}/state ← control light (Alexa sends this)
  GET  /api/{user}/groups         ← empty groups (required by Alexa)
  GET  /api/{user}/config         ← bridge config
"""

import socket
import threading
import time
import os
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse, Response

from database import get_all_devices, update_device_state, get_device
from ws_manager import manager

router = APIRouter()

# ── Constants ────────────────────────────────────────────────────────────────
HUE_UUID    = "2f402f80-da50-11e1-9b23-fantatech001"
HUE_SERIAL  = "fantatech001"
HUB_PORT    = int(os.getenv("HUB_PORT", "8080"))

# Device types that we expose to Alexa
CONTROLLABLE_TYPES = {"light", "switch", "dimmer", "fan", "ac", "relay", "plug"}

_ssdp_thread = None


# ── Helper: get local IP ─────────────────────────────────────────────────────
def _local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


# ── Device → Hue light conversion ────────────────────────────────────────────
def _device_to_hue(dev: dict, hue_id: int) -> dict:
    state    = dev.get("state", {}) or {}
    is_on    = str(state.get("state", "OFF")).upper() == "ON"
    bri_pct  = int(state.get("brightness", 100) or 100)
    bri      = max(1, min(254, int(bri_pct * 254 / 100)))
    dev_type = dev.get("type", "light").lower()

    hue_type   = "Extended color light" if dev_type in ("light", "dimmer") else "On/Off plug-in unit"
    model_id   = "LCT001" if dev_type in ("light", "dimmer") else "LOM001"

    return {
        "state": {
            "on":        is_on,
            "bri":       bri,
            "hue":       0,
            "sat":       0,
            "effect":    "none",
            "ct":        370,
            "alert":     "none",
            "colormode": "ct",
            "reachable": dev.get("online", True),
        },
        "type":             hue_type,
        "name":             dev.get("name", f"Device {hue_id}"),
        "modelid":          model_id,
        "manufacturername": "FantaTech",
        "productname":      dev.get("name", "FantaTech Device"),
        "uniqueid":         f"00:17:88:01:00:{hue_id:02x}:00:00-0b",
        "swversion":        "1.46.13_r26312",
        "_fantatech_id":    dev["id"],   # internal — used for state updates
    }


async def _get_hue_lights() -> dict:
    """Return all controllable devices as a Hue lights dict {str(n): light_obj}."""
    devices = await get_all_devices()
    lights  = {}
    idx     = 1
    for dev in devices:
        if dev.get("type", "").lower() in CONTROLLABLE_TYPES:
            lights[str(idx)] = _device_to_hue(dev, idx)
            idx += 1
    return lights


def _hue_config() -> dict:
    ip = _local_ip()
    return {
        "name":            "FantaTech Hub",
        "datastoreversion": "119",
        "swversion":       "1946054080",
        "apiversion":      "1.46.0",
        "mac":             "00:17:88:01:00:01",
        "bridgeid":        "001788FFFE000001",
        "factorynew":      False,
        "replacesbridgeid": None,
        "modelid":         "BSB002",
        "starterkitid":    "",
        "ipaddress":       ip,
        "netmask":         "255.255.255.0",
        "gateway":         ip,
        "dhcp":            True,
        "linkbutton":      True,   # always "pressed" so pairing always works
        "portalservices":  False,
        "UTC":             "2024-01-01T00:00:00",
        "localtime":       "2024-01-01T00:00:00",
        "timezone":        "Asia/Jerusalem",
    }


# ── UPnP description XML ──────────────────────────────────────────────────────
@router.get("/description.xml", response_class=Response)
async def description_xml():
    ip = _local_ip()
    xml = f"""<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <specVersion><major>1</major><minor>0</minor></specVersion>
  <URLBase>http://{ip}:{HUB_PORT}</URLBase>
  <device>
    <deviceType>urn:schemas-upnp-org:device:Basic:1</deviceType>
    <friendlyName>FantaTech Hub ({ip})</friendlyName>
    <manufacturer>Royal Philips Electronics</manufacturer>
    <manufacturerURL>http://www.philips.com</manufacturerURL>
    <modelDescription>Philips hue Personal Wireless Lighting</modelDescription>
    <modelName>Philips hue bridge 2015</modelName>
    <modelNumber>BSB002</modelNumber>
    <modelURL>http://www.meethue.com</modelURL>
    <serialNumber>{HUE_SERIAL}</serialNumber>
    <UDN>uuid:{HUE_UUID}</UDN>
    <presentationURL>index.html</presentationURL>
  </device>
</root>"""
    return Response(content=xml, media_type="application/xml")


# ── Pairing: POST /api  (Alexa creates a username here) ──────────────────────
@router.post("/api")
async def hue_pair(request: Request):
    # Accept any pairing request — link button is always "pressed"
    body = {}
    try:
        body = await request.json()
    except Exception:
        pass
    username = body.get("devicetype", "fantatech#alexa").replace(" ", "_")
    return JSONResponse([{"success": {"username": username}}])


# ── Full bridge state ─────────────────────────────────────────────────────────
@router.get("/api/{username}")
async def hue_full_state(username: str):
    lights = await _get_hue_lights()
    return JSONResponse({
        "lights":   lights,
        "groups":   {},
        "config":   _hue_config(),
        "schedules":{},
        "scenes":   {},
        "rules":    {},
        "sensors":  {},
        "resourcelinks": {},
    })


# ── List lights ───────────────────────────────────────────────────────────────
@router.get("/api/{username}/lights")
async def hue_lights(username: str):
    return JSONResponse(await _get_hue_lights())


# ── Single light ──────────────────────────────────────────────────────────────
@router.get("/api/{username}/lights/{light_id}")
async def hue_light(username: str, light_id: str):
    lights = await _get_hue_lights()
    if light_id not in lights:
        return JSONResponse({"error": [{"type": 3, "description": "resource not available"}]}, status_code=404)
    return JSONResponse(lights[light_id])


# ── Control light  (Alexa sends PUT here) ────────────────────────────────────
@router.put("/api/{username}/lights/{light_id}/state")
async def hue_set_state(username: str, light_id: str, request: Request):
    try:
        body = await request.json()
    except Exception:
        return JSONResponse([{"error": {"type": 2, "description": "bad json"}}])

    lights = await _get_hue_lights()
    if light_id not in lights:
        return JSONResponse([{"error": {"type": 3, "description": "resource not available"}}])

    light    = lights[light_id]
    device_id = light["_fantatech_id"]
    dev       = await get_device(device_id)
    if not dev:
        return JSONResponse([{"error": {"type": 3, "description": "device not found"}}])

    # Build new state
    new_state = dict(dev.get("state", {}) or {})
    success   = []

    if "on" in body:
        new_state["state"] = "ON" if body["on"] else "OFF"
        success.append({f"success": {f"/lights/{light_id}/state/on": body["on"]}})

    if "bri" in body:
        pct = max(1, min(100, int(body["bri"] * 100 / 254)))
        new_state["brightness"] = pct
        success.append({"success": {f"/lights/{light_id}/state/bri": body["bri"]}})

    if "ct" in body:
        new_state["color_temp"] = body["ct"]
        success.append({"success": {f"/lights/{light_id}/state/ct": body["ct"]}})

    # Persist + broadcast
    await update_device_state(device_id, new_state, online=True)
    await manager.broadcast("device_state", {"id": device_id, "state": new_state, "online": True})

    print(f"[Alexa] '{dev['name']}' → {new_state.get('state','?')} bri={new_state.get('brightness','—')}")

    return JSONResponse(success)


# ── Groups (empty — required by Alexa) ───────────────────────────────────────
@router.get("/api/{username}/groups")
async def hue_groups(username: str):
    return JSONResponse({})


@router.get("/api/{username}/groups/{group_id}")
async def hue_group(username: str, group_id: str):
    return JSONResponse({})


# ── Config ────────────────────────────────────────────────────────────────────
@router.get("/api/{username}/config")
async def hue_config_endpoint(username: str):
    return JSONResponse(_hue_config())


# ── SSDP discovery responder ──────────────────────────────────────────────────
def _ssdp_worker(port: int):
    """
    Listens for Alexa M-SEARCH multicast packets and replies with
    a Hue-compatible SSDP response so Alexa can find the bridge.
    Must run with elevated privileges to bind port 1900.
    """
    MCAST_GRP  = "239.255.255.250"
    MCAST_PORT = 1900

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("", MCAST_PORT))
        mreq = socket.inet_aton(MCAST_GRP) + socket.inet_aton("0.0.0.0")
        sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
        sock.settimeout(1.5)
        print(f"[Alexa/SSDP] Listening on {MCAST_GRP}:{MCAST_PORT} — Alexa discovery active ✅")
    except OSError as e:
        print(f"[Alexa/SSDP] ⚠️  Could not bind port 1900: {e}")
        print("[Alexa/SSDP] ➜  Run hub as Administrator for automatic Alexa discovery")
        print("[Alexa/SSDP] ➜  Alternative: in Alexa app → Add Device → Philips Hue → enter IP manually")
        return

    ip = _local_ip()
    while True:
        try:
            data, addr = sock.recvfrom(2048)
            text = data.decode("utf-8", errors="ignore")
            if "M-SEARCH" in text and any(k in text for k in ("ssdp:all", "Basic:1", "IpBridge", "upnp:rootdevice")):
                response = (
                    "HTTP/1.1 200 OK\r\n"
                    "CACHE-CONTROL: max-age=100\r\n"
                    "EXT:\r\n"
                    f"LOCATION: http://{ip}:{port}/description.xml\r\n"
                    "SERVER: Linux/3.14.0 UPnP/1.0 IpBridge/1.24.0\r\n"
                    "ST: urn:schemas-upnp-org:device:Basic:1\r\n"
                    f"USN: uuid:{HUE_UUID}::urn:schemas-upnp-org:device:Basic:1\r\n"
                    "\r\n"
                )
                rs = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                rs.sendto(response.encode(), addr)
                rs.close()
                print(f"[Alexa/SSDP] Responded to discovery from {addr[0]}")
        except socket.timeout:
            continue
        except Exception:
            continue


def start_ssdp(port: int = 8080):
    global _ssdp_thread
    if _ssdp_thread and _ssdp_thread.is_alive():
        return
    _ssdp_thread = threading.Thread(target=_ssdp_worker, args=(port,), daemon=True, name="AlexaSSDPThread")
    _ssdp_thread.start()
