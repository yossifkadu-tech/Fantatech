"""
WiFi Bridge — מגלה ושולט במכשירי WiFi חכמים.

תמיכה:
  - Tasmota  (HTTP + MQTT)
  - ESPHome  (HTTP + mDNS)
  - Generic  (HTTP REST)

טופיקים שמפרסם:
  devices/{id}/state    → {"state":"ON","power":120,...}
  devices/{id}/online   → true/false
  bridges/wifi/status   → {"devices": N}

טופיקים שמאזין:
  devices/{id}/cmd      → {"state":"ON"/"OFF","brightness":80}
  bridges/wifi/scan     → {} (הפעל סריקה ידנית)
"""
import asyncio
import json
import os
import socket
import time
import threading
from dataclasses import dataclass, field

import httpx
import paho.mqtt.client as mqtt
from dotenv import load_dotenv

load_dotenv()

MQTT_HOST      = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT      = int(os.getenv("MQTT_PORT", 1883))
SUBNET         = os.getenv("NETWORK_SUBNET", "192.168.10")
SCAN_INTERVAL  = int(os.getenv("SCAN_INTERVAL", 30))

# ─── Device registry ──────────────────────────────────────────────────────────

@dataclass
class WifiDevice:
    id: str
    ip: str
    firmware: str  # tasmota | esphome | generic
    name: str = ""
    online: bool = False
    state: dict = field(default_factory=dict)


_devices: dict[str, WifiDevice] = {}
_mqtt_client: mqtt.Client | None = None


# ─── MQTT ────────────────────────────────────────────────────────────────────

def pub(topic: str, payload, retain: bool = False):
    if _mqtt_client:
        msg = json.dumps(payload) if isinstance(payload, dict) else str(payload)
        _mqtt_client.publish(topic, msg, retain=retain)


def on_connect(client, userdata, flags, rc, props=None):
    print("[WiFi Bridge] MQTT connected")
    client.subscribe("devices/+/cmd")
    client.subscribe("bridges/wifi/scan")


def on_message(client, userdata, msg):
    topic = msg.topic
    try:
        payload = json.loads(msg.payload.decode())
    except Exception:
        payload = msg.payload.decode()

    if topic == "bridges/wifi/scan":
        threading.Thread(target=lambda: asyncio.run(scan_network()), daemon=True).start()

    elif topic.startswith("devices/") and topic.endswith("/cmd"):
        dev_id = topic.split("/")[1]
        if dev_id in _devices:
            dev = _devices[dev_id]
            asyncio.run_coroutine_threadsafe(
                send_command(dev, payload),
                asyncio.get_event_loop(),
            )


# ─── Tasmota ──────────────────────────────────────────────────────────────────

async def tasmota_get_state(ip: str) -> dict | None:
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            r = await c.get(f"http://{ip}/cm?cmnd=Status%200")
            data = r.json()
            status = data.get("StatusSTS", data.get("Status", {}))
            power = status.get("POWER", status.get("POWER1", ""))
            result = {"state": power if power else "UNKNOWN"}
            if "Wifi" in status:
                result["rssi"] = status["Wifi"].get("RSSI", 0)
            energy = status.get("ENERGY", {})
            if energy:
                result["power_w"] = energy.get("Power", 0)
                result["voltage"] = energy.get("Voltage", 0)
            return result
    except Exception:
        return None


async def tasmota_send(ip: str, payload: dict):
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            state = payload.get("state", "").upper()
            if state in ("ON", "OFF"):
                await c.get(f"http://{ip}/cm?cmnd=Power%20{state}")
            brightness = payload.get("brightness")
            if brightness is not None:
                pct = int(brightness / 2.55)
                await c.get(f"http://{ip}/cm?cmnd=Dimmer%20{pct}")
            color = payload.get("color")
            if color:
                await c.get(f"http://{ip}/cm?cmnd=Color%20{color}")
    except Exception as e:
        print(f"[WiFi] Tasmota cmd error {ip}: {e}")


async def tasmota_get_name(ip: str) -> str:
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            r = await c.get(f"http://{ip}/cm?cmnd=DeviceName")
            return r.json().get("DeviceName", ip)
    except Exception:
        return ip


# ─── ESPHome ──────────────────────────────────────────────────────────────────

async def esphome_get_state(ip: str) -> dict | None:
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            r = await c.get(f"http://{ip}/states")
            entities = r.json()
            state = {}
            for e in entities:
                if e.get("type") == "switch" or e.get("type") == "light":
                    state["state"] = "ON" if e.get("value") else "OFF"
                elif e.get("type") == "sensor":
                    state[e.get("id", "sensor")] = e.get("value")
            return state
    except Exception:
        return None


async def esphome_send(ip: str, payload: dict):
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            state = payload.get("state", "").lower()
            if state in ("on", "off"):
                await c.post(f"http://{ip}/switch/main_switch/{state}")
    except Exception as e:
        print(f"[WiFi] ESPHome cmd error {ip}: {e}")


# ─── Detection ────────────────────────────────────────────────────────────────

async def detect_firmware(ip: str) -> str | None:
    """מנסה לזהות סוג הקושחה של המכשיר."""
    async with httpx.AsyncClient(timeout=2) as c:
        # Tasmota
        try:
            r = await c.get(f"http://{ip}/cm?cmnd=Status")
            if "Status" in r.text or "StatusSTS" in r.text:
                return "tasmota"
        except Exception:
            pass

        # ESPHome
        try:
            r = await c.get(f"http://{ip}/")
            if "ESPHome" in r.text or "esphome" in r.text.lower():
                return "esphome"
        except Exception:
            pass

    return None


async def scan_host(ip: str):
    """בודק host אחד — אם מכשיר חכם, מוסיף למאגר."""
    firmware = await detect_firmware(ip)
    if not firmware:
        return

    dev_id = ip.replace(".", "_")
    name = ip

    if firmware == "tasmota":
        name = await tasmota_get_name(ip)
        state = await tasmota_get_state(ip)
    elif firmware == "esphome":
        state = await esphome_get_state(ip)
    else:
        state = {}

    if state is None:
        return

    dev = WifiDevice(id=dev_id, ip=ip, firmware=firmware, name=name, online=True, state=state)
    is_new = dev_id not in _devices
    _devices[dev_id] = dev

    pub(f"devices/{dev_id}/state", state, retain=True)
    pub(f"devices/{dev_id}/online", True, retain=True)

    if is_new:
        print(f"[WiFi] Found {firmware} device: {name} ({ip})")
        pub("bridges/wifi/status", _bridge_status())


async def scan_network():
    """סורק את כל ה-subnet."""
    print(f"[WiFi] Scanning {SUBNET}.1-254...")
    tasks = [scan_host(f"{SUBNET}.{i}") for i in range(1, 255)]
    await asyncio.gather(*tasks, return_exceptions=True)
    print(f"[WiFi] Scan done. Found {len(_devices)} devices.")
    pub("bridges/wifi/status", _bridge_status())


# ─── Polling ──────────────────────────────────────────────────────────────────

async def poll_devices():
    """מרענן סטטוס כל המכשירים הידועים."""
    for dev in list(_devices.values()):
        try:
            if dev.firmware == "tasmota":
                state = await tasmota_get_state(dev.ip)
            elif dev.firmware == "esphome":
                state = await esphome_get_state(dev.ip)
            else:
                state = None

            if state:
                if state != dev.state:
                    dev.state = state
                    pub(f"devices/{dev.id}/state", state, retain=True)
                if not dev.online:
                    dev.online = True
                    pub(f"devices/{dev.id}/online", True, retain=True)
            else:
                if dev.online:
                    dev.online = False
                    pub(f"devices/{dev.id}/online", False, retain=True)
        except Exception:
            pass


async def send_command(dev: WifiDevice, payload: dict):
    if dev.firmware == "tasmota":
        await tasmota_send(dev.ip, payload)
    elif dev.firmware == "esphome":
        await esphome_send(dev.ip, payload)


def _bridge_status() -> dict:
    return {
        "devices": len(_devices),
        "online":  sum(1 for d in _devices.values() if d.online),
    }


# ─── Main loop ────────────────────────────────────────────────────────────────

async def main_loop():
    # סריקה ראשונית
    await scan_network()

    # לולאת polling
    while True:
        await asyncio.sleep(SCAN_INTERVAL)
        await poll_devices()


def main():
    global _mqtt_client

    _mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    _mqtt_client.on_connect = on_connect
    _mqtt_client.on_message = on_message
    _mqtt_client.connect(MQTT_HOST, MQTT_PORT)
    _mqtt_client.loop_start()

    pub("bridges/wifi/status", {"status": "starting"})

    try:
        asyncio.run(main_loop())
    except KeyboardInterrupt:
        print("[WiFi Bridge] Stopped.")
    finally:
        pub("bridges/wifi/status", {"status": "offline"})
        _mqtt_client.loop_stop()


if __name__ == "__main__":
    main()
