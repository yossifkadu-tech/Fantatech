"""MQTT client — מחבר את הבאקנד לכל המכשירים דרך MQTT broker."""
import asyncio
import json
import os
import threading
import paho.mqtt.client as mqtt

MQTT_HOST = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))

_client: mqtt.Client | None = None
_loop: asyncio.AbstractEventLoop | None = None
_message_handlers: list = []


def on_connect(client, userdata, flags, rc, props=None):
    print(f"[MQTT] Connected (rc={rc})")
    # Generic device topics
    client.subscribe("devices/+/state")
    client.subscribe("devices/+/online")
    client.subscribe("bridges/+/status")
    # Tasmota topics (tele/TOPIC/STATE, tele/TOPIC/SENSOR, stat/TOPIC/POWER)
    client.subscribe("tele/+/STATE")
    client.subscribe("tele/+/SENSOR")
    client.subscribe("stat/+/POWER")
    # Zigbee2MQTT topics
    client.subscribe("zigbee2mqtt/bridge/devices")
    client.subscribe("zigbee2mqtt/bridge/info")
    client.subscribe("zigbee2mqtt/+")


def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
    except Exception:
        payload = msg.payload.decode()

    topic = msg.topic

    if _loop and not _loop.is_closed():
        asyncio.run_coroutine_threadsafe(
            _dispatch(topic, payload), _loop
        )


async def _dispatch(topic: str, payload):
    for handler in _message_handlers:
        try:
            await handler(topic, payload)
        except Exception as e:
            print(f"[MQTT] Handler error: {e}")


def register_handler(fn):
    """Register an async function(topic, payload) to handle incoming messages."""
    _message_handlers.append(fn)


def subscribe(topic: str):
    """Subscribe to an additional MQTT topic at runtime."""
    if _client is not None:
        _client.subscribe(topic)


def publish(topic: str, payload: dict | str, retain: bool = False):
    if _client is None:
        return
    msg = json.dumps(payload) if isinstance(payload, dict) else payload
    _client.publish(topic, msg, retain=retain)


def start(loop: asyncio.AbstractEventLoop):
    global _client, _loop
    _loop = loop
    _client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    _client.on_connect = on_connect
    _client.on_message = on_message

    def _run():
        try:
            _client.connect(MQTT_HOST, MQTT_PORT, keepalive=60)
            _client.loop_forever()
        except Exception as e:
            print(f"[MQTT] Connection failed: {e}")

    t = threading.Thread(target=_run, daemon=True)
    t.start()
    print(f"[MQTT] Connecting to {MQTT_HOST}:{MQTT_PORT}...")
