import asyncio
import json
import os
import socket
import subprocess
import platform
import threading
import time
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

from routers import devices, rules, history, rooms, ws, network, ai, ac, matter, zigbee, tuya, scenes, timers, camera, notifications as notif_router
from database import init_db, update_device_state, get_device, get_all_devices, add_history, get_wifi_profiles, add_notification
from mqtt_client import start as mqtt_start, register_handler, publish
from rule_engine import start as rules_start
from ws_manager import manager

HUB_VERSION = "1.9.0"
IS_WIN = platform.system() == "Windows"

app = FastAPI(title="Fantatech Home & Security", version=HUB_VERSION)

app.add_middleware(
    CORSMiddleware, allow_origins=["*"],
    allow_methods=["*"], allow_headers=["*"],
)

app.include_router(devices.router, prefix="/api/devices",  tags=["devices"])
app.include_router(rules.router,   prefix="/api/rules",    tags=["rules"])
app.include_router(history.router, prefix="/api/history",  tags=["history"])
app.include_router(rooms.router,   prefix="/api/rooms",    tags=["rooms"])
app.include_router(ws.router,                              tags=["ws"])
app.include_router(network.router, prefix="/api/network",  tags=["network"])
app.include_router(ai.router,      prefix="/api/ai",       tags=["ai"])
app.include_router(ac.router,      prefix="/api/ac",       tags=["ac"])
app.include_router(matter.router,  prefix="/api/matter",   tags=["matter"])
app.include_router(zigbee.router,  prefix="/api/zigbee",   tags=["zigbee"])
app.include_router(tuya.router,    prefix="/api/tuya",     tags=["tuya"])
app.include_router(scenes.router,  prefix="/api/scenes",   tags=["scenes"])
app.include_router(timers.router,  prefix="/api/timers",   tags=["timers"])
app.include_router(camera.router,       prefix="/api/camera",        tags=["camera"])
app.include_router(notif_router.router, prefix="/api/notifications", tags=["notifications"])


# ג”€ג”€ MQTT broker auto-start ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€

def _is_port_open(port: int) -> bool:
    """Check if something is already listening on a port."""
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=1):
            return True
    except OSError:
        return False


def _start_mqtt_broker():
    """Start MQTT broker automatically if not already running.
    Priority: 1) already running  2) Mosquitto  3) amqtt (Python)"""

    if _is_port_open(1883):
        print("[MQTT] Broker already running on port 1883")
        return

    # --- Try Mosquitto ---
    mosquitto_found = False
    try:
        check_cmd = ["where", "mosquitto"] if IS_WIN else ["which", "mosquitto"]
        r = subprocess.run(check_cmd, capture_output=True, timeout=3)
        mosquitto_found = (r.returncode == 0)
    except Exception:
        pass

    if mosquitto_found:
        try:
            conf = os.path.join(os.path.dirname(__file__), "mosquitto.conf")
            cmd = ["mosquitto", "-c", conf] if os.path.exists(conf) else ["mosquitto"]
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(1.5)
            if _is_port_open(1883):
                print("[MQTT] Mosquitto broker started on port 1883")
                return
        except Exception as e:
            print(f"[MQTT] Mosquitto failed: {e}")

    # --- Try amqtt (pure Python) ---
    try:
        import amqtt
        subprocess.Popen(
            ["python", "-m", "amqtt", "--host", "0.0.0.0", "--port", "1883"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        time.sleep(2)
        if _is_port_open(1883):
            print("[MQTT] amqtt broker started on port 1883")
            return
    except Exception as e:
        print(f"[MQTT] amqtt failed: {e}")

    print("[MQTT] WARNING: No MQTT broker could be started.")
    print("[MQTT] Install Mosquitto from https://mosquitto.org/download/")
    print("[MQTT] Hub will still work ג€” real-time device updates disabled until MQTT is running.")


# ג”€ג”€ MQTT message handler ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€

async def on_mqtt_message(topic: str, payload):
    parts = topic.split("/")

    # ג”€ג”€ devices/{id}/state ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    if len(parts) == 3 and parts[0] == "devices" and parts[2] == "state":
        device_id = parts[1]
        state = payload if isinstance(payload, dict) else {}
        await update_device_state(device_id, state, online=True)
        await manager.broadcast("device_state", {
            "id": device_id, "state": state, "online": True
        })

    # ג”€ג”€ devices/{id}/online ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif len(parts) == 3 and parts[0] == "devices" and parts[2] == "online":
        device_id = parts[1]
        online = payload if isinstance(payload, bool) else str(payload).lower() == "true"
        d = await get_device(device_id)
        if d:
            prev_online = d.get("online", True)
            await update_device_state(device_id, d["state"], online=online)
            await manager.broadcast("device_online", {"id": device_id, "online": online})
            if prev_online and not online:
                await add_notification(
                    type_="warning", category="device",
                    title=f"Device offline: {d['name']}",
                    message=f"Lost connection to '{d['name']}' ({device_id})",
                    device_id=device_id, device_name=d["name"],
                )
            elif not prev_online and online:
                await add_notification(
                    type_="info", category="device",
                    title=f"Device online: {d['name']}",
                    message=f"'{d['name']}' reconnected",
                    device_id=device_id, device_name=d["name"],
                )

    # ג”€ג”€ Tasmota: tele/{topic}/STATE ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif len(parts) == 3 and parts[0] == "tele" and parts[2] == "STATE":
        tasmota_topic = parts[1]
        # Find device by topic stored in config or id
        all_devs = await get_all_devices()
        device = next(
            (d for d in all_devs
             if d.get("config", {}).get("source") == "tasmota"
             and (d["id"] == tasmota_topic.replace(".", "_")
                  or d.get("topic_state", "").endswith(f"/{tasmota_topic}/STATE"))),
            None
        )
        if device:
            power = None
            if isinstance(payload, dict):
                power = payload.get("POWER") or payload.get("Power")
            elif isinstance(payload, str):
                power = payload
            if power is not None:
                state = {"state": "ON" if str(power).upper() in ("ON", "1", "TRUE") else "OFF"}
                await update_device_state(device["id"], state, online=True)
                await manager.broadcast("device_state", {
                    "id": device["id"], "state": state, "online": True
                })

    # ג”€ג”€ Tasmota: stat/{topic}/POWER ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif len(parts) == 3 and parts[0] == "stat" and parts[2] == "POWER":
        tasmota_topic = parts[1]
        all_devs = await get_all_devices()
        device = next(
            (d for d in all_devs
             if d.get("config", {}).get("source") == "tasmota"
             and (d["id"] == tasmota_topic.replace(".", "_")
                  or d.get("topic_cmd", "").endswith(f"/{tasmota_topic}/Power"))),
            None
        )
        if device:
            power_val = payload if isinstance(payload, str) else str(payload)
            state = {"state": "ON" if power_val.upper() in ("ON", "1", "TRUE") else "OFF"}
            await update_device_state(device["id"], state, online=True)
            await manager.broadcast("device_state", {
                "id": device["id"], "state": state, "online": True
            })

    # ג”€ג”€ zigbee2mqtt/bridge/devices ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif topic == "zigbee2mqtt/bridge/devices":
        zigbee.update_z2m_devices(payload)
        await manager.broadcast("zigbee_devices", {"count": len(payload) if isinstance(payload, list) else 0})

    # ג”€ג”€ zigbee2mqtt/bridge/info ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif topic == "zigbee2mqtt/bridge/info":
        zigbee.update_z2m_bridge_info(payload)

    # ג”€ג”€ zigbee2mqtt/{name} ג€” per-device state from Z2M ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif len(parts) == 2 and parts[0] == "zigbee2mqtt" and parts[1] not in ("bridge",):
        friendly_name = parts[1]
        # Find matching hub device by friendly_name in config
        all_devs = await get_all_devices()
        dev = next(
            (d for d in all_devs
             if d.get("protocol") == "zigbee"
             and d.get("config", {}).get("friendly_name") == friendly_name),
            None
        )
        if dev:
            state = payload if isinstance(payload, dict) else {}
            # Normalize ON/OFF
            if "state" in state:
                state["state"] = "ON" if str(state["state"]).upper() in ("ON", "1", "TRUE") else "OFF"
            await update_device_state(dev["id"], state, online=True)
            await manager.broadcast("device_state", {
                "id": dev["id"], "state": state, "online": True
            })

    # ג”€ג”€ bridges/{name}/status ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
    elif len(parts) == 3 and parts[0] == "bridges":
        await manager.broadcast("bridge_status", {
            "bridge": parts[1], "status": payload
        })


# ג”€ג”€ Startup ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€

def get_local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


# Keep the Zeroconf instance alive for the lifetime of the process
_zeroconf_instance = None


def _register_mdns(ip: str):
    """Register Hub on mDNS so fantatech-hub.local resolves automatically."""
    global _zeroconf_instance
    try:
        from zeroconf import Zeroconf, ServiceInfo
        info = ServiceInfo(
            "_fantatech._tcp.local.",
            "Fantatech-Hub._fantatech._tcp.local.",
            addresses=[socket.inet_aton(ip)],
            port=8080,
            properties={b"version": HUB_VERSION.encode(), b"path": b"/api"},
            server="fantatech-hub.local.",
        )
        zc = Zeroconf()
        zc.register_service(info)
        _zeroconf_instance = zc          # keep alive ג€” do NOT let it be GC'd
        print(f"[mDNS] Registered: fantatech-hub.local -> {ip}:8080")
    except Exception as e:
        print(f"[mDNS] Registration failed (non-critical): {e}")


@app.on_event("startup")
async def startup():
    await init_db()

    # Start MQTT broker in background thread (non-blocking)
    threading.Thread(target=_start_mqtt_broker, daemon=True).start()
    # Give broker a moment to start before connecting client
    await asyncio.sleep(2)

    loop = asyncio.get_running_loop()
    register_handler(on_mqtt_message)
    mqtt_start(loop)
    rules_start(loop)

    ip   = get_local_ip()
    port = os.getenv("HUB_PORT", "8080")
    print(f"\n{'='*55}")
    print(f"  Fantatech Home & Security  v{HUB_VERSION}")
    print(f"  API:       http://{ip}:{port}/api")
    print(f"  Docs:      http://{ip}:{port}/docs")
    print(f"  WebSocket: ws://{ip}:{port}/ws")
    print(f"  Enter in app settings: {ip}")
    print(f"{'='*55}\n")

    # Register mDNS so app can find Hub by name (fantatech-hub.local)
    threading.Thread(target=_register_mdns, args=(ip,), daemon=True).start()

    await _auto_connect_wifi()
    await _subscribe_zigbee_devices()

    # Log hub startup as a system notification
    await add_notification(
        type_="info", category="system",
        title=f"Hub started v{HUB_VERSION}",
        message=f"Fantatech Hub is running at {ip}:{port}",
    )


async def _subscribe_zigbee_devices():
    """Subscribe MQTT to all already-imported Zigbee device topics."""
    try:
        devs = await get_all_devices()
        for d in devs:
            if d.get("protocol") == "zigbee" and d.get("topic_state"):
                from mqtt_client import subscribe as mqtt_sub
                mqtt_sub(d["topic_state"])
    except Exception:
        pass


async def _auto_connect_wifi():
    try:
        profiles = await get_wifi_profiles()
        auto = [p for p in profiles if p.get("auto_connect", 1)]
        for p in auto:
            try:
                if IS_WIN:
                    from routers.network import _connect_windows
                    _connect_windows(p["ssid"], p["password"])
                else:
                    subprocess.run(
                        ["nmcli", "dev", "wifi", "connect", p["ssid"],
                         "password", p["password"]],
                        check=True, capture_output=True, timeout=10,
                    )
                print(f"  [WiFi] Auto-connected to: {p['ssid']}")
                break
            except Exception:
                continue
    except Exception:
        pass


# ג”€ג”€ Endpoints ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€

@app.get("/")
def root():
    return {
        "status": "ok",
        "version": HUB_VERSION,
        "ip": get_local_ip(),
    }


@app.get("/api/version")
def api_version():
    return {"version": HUB_VERSION, "app": "Fantatech Home & Security"}


@app.get("/ping")
def ping():
    return {"pong": True}

