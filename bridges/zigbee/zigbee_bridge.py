"""
Zigbee Bridge — מחבר מכשירי Zigbee ל-MQTT hub.

טופיקים שמפרסם:
  devices/{ieee}/state   → {"state":"ON","brightness":80,...}
  devices/{ieee}/online  → true/false
  bridges/zigbee/status  → {"devices": N, "permit_join": false}

טופיקים שמאזין:
  bridges/zigbee/permit_join → true/false  (הכנס מכשיר חדש)
  devices/{ieee}/cmd         → {"state":"ON",...}
"""
import asyncio
import json
import os
import re
import threading
import time

import paho.mqtt.client as mqtt
from dotenv import load_dotenv

load_dotenv()

ZIGBEE_PORT  = os.getenv("ZIGBEE_PORT", "COM3")
ZIGBEE_RADIO = os.getenv("ZIGBEE_RADIO", "znp").lower()
MQTT_HOST    = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT    = int(os.getenv("MQTT_PORT", 1883))

# ─── MQTT ────────────────────────────────────────────────────────────────────

_mqtt: mqtt.Client | None = None
_controller = None


def mqtt_publish(topic: str, payload, retain: bool = False):
    if _mqtt:
        msg = json.dumps(payload) if isinstance(payload, dict) else str(payload)
        _mqtt.publish(topic, msg, retain=retain)


def on_mqtt_connect(client, userdata, flags, rc, props=None):
    print(f"[Zigbee Bridge] MQTT connected")
    client.subscribe("bridges/zigbee/permit_join")
    client.subscribe("devices/+/cmd")


def on_mqtt_message(client, userdata, msg):
    topic = msg.topic
    try:
        payload = json.loads(msg.payload.decode())
    except Exception:
        payload = msg.payload.decode()

    # permit join
    if topic == "bridges/zigbee/permit_join":
        enable = payload if isinstance(payload, bool) else str(payload).lower() == "true"
        if _controller:
            asyncio.run_coroutine_threadsafe(
                _controller.permit_joining(enable), asyncio.get_event_loop()
            )
        print(f"[Zigbee] Permit join: {enable}")

    # device command
    elif topic.startswith("devices/") and topic.endswith("/cmd"):
        ieee = topic.split("/")[1]
        if _controller:
            asyncio.run_coroutine_threadsafe(
                _send_to_device(ieee, payload), asyncio.get_event_loop()
            )


async def _send_to_device(ieee: str, payload: dict):
    """שלח פקודה למכשיר Zigbee לפי IEEE address."""
    if not _controller:
        return
    for dev in _controller.devices.values():
        if str(dev.ieee) == ieee:
            state = payload.get("state", "").upper()
            brightness = payload.get("brightness")
            color_temp = payload.get("color_temp")
            for ep in dev.endpoints.values():
                try:
                    if hasattr(ep, "on_off"):
                        if state == "ON":
                            await ep.on_off.on()
                        elif state == "OFF":
                            await ep.on_off.off()
                    if brightness is not None and hasattr(ep, "level"):
                        await ep.level.move_to_level(int(brightness), 10)
                    if color_temp is not None and hasattr(ep, "light_color"):
                        await ep.light_color.move_to_color_temp(int(color_temp), 10)
                except Exception as e:
                    print(f"[Zigbee] Command error: {e}")
            break


# ─── Zigbee callbacks ─────────────────────────────────────────────────────────

def on_device_joined(ieee, nwk):
    print(f"[Zigbee] Device joined: {ieee}")
    mqtt_publish(f"devices/{ieee}/online", True, retain=True)
    mqtt_publish("bridges/zigbee/status", _bridge_status())


def on_device_left(ieee, nwk):
    print(f"[Zigbee] Device left: {ieee}")
    mqtt_publish(f"devices/{ieee}/online", False, retain=True)
    mqtt_publish("bridges/zigbee/status", _bridge_status())


def on_attribute_updated(device, cluster, attribute_id, value):
    ieee = str(device.ieee)
    state = _build_state(device)
    mqtt_publish(f"devices/{ieee}/state", state, retain=True)


def _build_state(device) -> dict:
    state = {}
    for ep in device.endpoints.values():
        try:
            if hasattr(ep, "on_off"):
                val = ep.on_off.get("on_off")
                if val is not None:
                    state["state"] = "ON" if val else "OFF"
            if hasattr(ep, "level"):
                val = ep.level.get("current_level")
                if val is not None:
                    state["brightness"] = val
            if hasattr(ep, "temperature"):
                val = ep.temperature.get("measured_value")
                if val is not None:
                    state["temperature"] = round(val / 100, 1)
            if hasattr(ep, "humidity"):
                val = ep.humidity.get("measured_value")
                if val is not None:
                    state["humidity"] = round(val / 100, 1)
            if hasattr(ep, "occupancy"):
                val = ep.occupancy.get("occupancy")
                if val is not None:
                    state["occupancy"] = bool(val)
        except Exception:
            pass
    return state


def _bridge_status() -> dict:
    if not _controller:
        return {"devices": 0, "permit_join": False}
    return {
        "devices": len(_controller.devices),
        "permit_join": getattr(_controller, "_permit_join", False),
    }


def _publish_all_devices():
    if not _controller:
        return
    for dev in _controller.devices.values():
        ieee = str(dev.ieee)
        state = _build_state(dev)
        if state:
            mqtt_publish(f"devices/{ieee}/state", state, retain=True)
        mqtt_publish(f"devices/{ieee}/online", True, retain=True)
    mqtt_publish("bridges/zigbee/status", _bridge_status())


# ─── Main ─────────────────────────────────────────────────────────────────────

async def run_zigbee():
    global _controller

    if ZIGBEE_RADIO == "znp":
        from zigpy_znp.zigbee.application import ControllerApplication
        config = {
            "device": {"path": ZIGBEE_PORT},
            "database_path": "zigbee.db",
        }
    elif ZIGBEE_RADIO == "deconz":
        from zigpy_deconz.zigbee.application import ControllerApplication
        config = {
            "device": {"path": ZIGBEE_PORT},
            "database_path": "zigbee.db",
        }
    else:
        print(f"[Zigbee] Unknown radio type: {ZIGBEE_RADIO}")
        return

    print(f"[Zigbee] Starting on {ZIGBEE_PORT} ({ZIGBEE_RADIO})...")

    _controller = await ControllerApplication.new(
        config=ControllerApplication.SCHEMA(config),
        auto_form=True,
        start_radio=True,
    )

    _controller.add_listener(type("L", (), {
        "device_joined": lambda self, *a: on_device_joined(*a),
        "device_left":   lambda self, *a: on_device_left(*a),
        "attribute_updated": lambda self, *a: on_attribute_updated(*a),
    })())

    print(f"[Zigbee] Controller started. {len(_controller.devices)} devices known.")
    _publish_all_devices()

    # Keep running
    while True:
        await asyncio.sleep(30)
        _publish_all_devices()


def main():
    global _mqtt

    # Connect MQTT
    _mqtt = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    _mqtt.on_connect = on_mqtt_connect
    _mqtt.on_message = on_mqtt_message
    _mqtt.connect(MQTT_HOST, MQTT_PORT)
    _mqtt.loop_start()

    mqtt_publish("bridges/zigbee/status", {"status": "starting"})

    # Run Zigbee
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        loop.run_until_complete(run_zigbee())
    except KeyboardInterrupt:
        print("[Zigbee] Stopped.")
    finally:
        mqtt_publish("bridges/zigbee/status", {"status": "offline"})
        _mqtt.loop_stop()


if __name__ == "__main__":
    main()
