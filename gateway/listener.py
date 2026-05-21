import paho.mqtt.client as mqtt

BROKER   = "localhost"
PORT     = 1883
KEEPALIVE = 60

# Add every topic the gateway should act on
TOPICS = [
    "home/livingroom/light",
    "home/bedroom/light",
    "home/kitchen/light",
    "home/bedroom/ac",
    "home/bedroom/ac/temperature",
    "home/kitchen/blinds",
    "home/entrance/lock",
    "home/security/alarm",
    "home/all/off",
]


def handle_light(room, payload):
    if payload == "ON":
        print(f"[LIGHT] {room} → ON")
        # gpio.output(PIN_MAP[room], gpio.HIGH)
    elif payload == "OFF":
        print(f"[LIGHT] {room} → OFF")
        # gpio.output(PIN_MAP[room], gpio.LOW)


def handle_ac(room, payload):
    if payload in ("ON", "OFF"):
        print(f"[AC] {room} power → {payload}")
        # send to ESP32 / IR blaster
    else:
        print(f"[AC] {room} temperature → {payload}°C")


def handle_blinds(room, payload):
    print(f"[BLINDS] {room} → {payload}")
    # relay: OPEN / CLOSE / STOP


def handle_lock(door, payload):
    print(f"[LOCK] {door} → {payload}")
    # gpio or smart-lock API call


def handle_alarm(payload):
    print(f"[ALARM] → {payload}")
    # trigger siren / notify


def handle_all_off():
    print("[ALL-OFF] Turning everything off")
    for room in ("livingroom", "bedroom", "kitchen"):
        handle_light(room, "OFF")


def on_message(client, userdata, msg):
    topic   = msg.topic
    payload = msg.payload.decode().upper()
    print(f"← {topic}  {payload}")

    # ── Lights ──────────────────────────────────────────────────
    if topic == "home/livingroom/light":
        handle_light("livingroom", payload)
    elif topic == "home/bedroom/light":
        handle_light("bedroom", payload)
    elif topic == "home/kitchen/light":
        handle_light("kitchen", payload)

    # ── AC ──────────────────────────────────────────────────────
    elif topic == "home/bedroom/ac":
        handle_ac("bedroom", payload)
    elif topic == "home/bedroom/ac/temperature":
        handle_ac("bedroom", payload)

    # ── Blinds ──────────────────────────────────────────────────
    elif topic == "home/kitchen/blinds":
        handle_blinds("kitchen", payload)

    # ── Lock ────────────────────────────────────────────────────
    elif topic == "home/entrance/lock":
        handle_lock("entrance", payload)

    # ── Alarm ───────────────────────────────────────────────────
    elif topic == "home/security/alarm":
        handle_alarm(payload)

    # ── All off ─────────────────────────────────────────────────
    elif topic == "home/all/off" and payload == "ON":
        handle_all_off()


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"[MQTT] Connected to {BROKER}:{PORT}")
        for topic in TOPICS:
            client.subscribe(topic)
            print(f"  subscribed → {topic}")
    else:
        print(f"[MQTT] Connection failed (rc={rc})")


def on_disconnect(client, userdata, rc):
    print(f"[MQTT] Disconnected (rc={rc})")


client = mqtt.Client()
client.on_connect    = on_connect
client.on_message    = on_message
client.on_disconnect = on_disconnect

client.connect(BROKER, PORT, KEEPALIVE)
client.loop_forever()
