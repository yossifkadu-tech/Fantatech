"""Rule engine — מנוע אוטומציות: אם X קרה → בצע Y."""
import asyncio
import time
import threading
import math
from croniter import croniter
from database import get_all_rules, update_rule_last_run, add_history
from mqtt_client import publish

# ── Sun-rise / sun-set calculation (no external lib needed) ──────────────────
_LOCATION = {"lat": 31.77, "lon": 35.21}   # ירושלים — ניתן לשנות דרך SettingsPage


def _set_location(lat: float, lon: float):
    _LOCATION["lat"] = lat
    _LOCATION["lon"] = lon


def _sun_times(date_ts: float) -> tuple:
    """Returns (sunrise_ts, sunset_ts) in UTC epoch for the day containing date_ts."""
    import datetime
    d = datetime.datetime.utcfromtimestamp(date_ts).date()
    lat = math.radians(_LOCATION["lat"])
    lon_deg = _LOCATION["lon"]

    n = d.timetuple().tm_yday
    lw   = math.radians(-lon_deg)
    dl   = 0.0172 * (n - 80)
    eot  = -7.655 * math.sin(dl) + 9.873 * math.sin(2 * dl + 3.588) + 0.439
    dec  = math.radians(23.45 * math.sin(math.radians(360 / 365 * (n - 80))))
    cos_h = (math.cos(math.radians(90.833)) - math.sin(lat) * math.sin(dec)) / (math.cos(lat) * math.cos(dec))
    cos_h = max(-1.0, min(1.0, cos_h))
    h    = math.degrees(math.acos(cos_h))

    noon_utc = 12 + lw * (180 / math.pi) / 15 - eot / 60
    rise_utc = noon_utc - h / 15
    set_utc  = noon_utc + h / 15

    base = datetime.datetime(d.year, d.month, d.day, tzinfo=datetime.timezone.utc).timestamp()
    return base + rise_utc * 3600, base + set_utc * 3600


async def execute_actions(actions: list):
    """מבצע רשימת פעולות."""
    for action in actions:
        atype = action.get("type")
        device_id = action.get("device_id", "")
        payload = action.get("payload", {})

        if atype == "mqtt":
            topic = action.get("topic", f"devices/{device_id}/cmd")
            publish(topic, payload)

        elif atype == "delay":
            await asyncio.sleep(action.get("seconds", 1))

        elif atype == "scene":
            # הפעל סצנה (רשימת פעולות)
            scene_actions = action.get("actions", [])
            await execute_actions(scene_actions)


async def check_device_trigger(rule: dict, topic: str, payload) -> bool:
    """בודק אם הטריגר של הכלל התרחש."""
    trigger = rule["trigger"]
    ttype   = trigger.get("type")
    state   = payload if isinstance(payload, dict) else {}

    # ── device_state ────────────────────────────────────────────────────────
    if ttype == "device_state":
        expected = trigger.get("device_id")
        if topic != f"devices/{expected}/state":
            return False
        condition = rule.get("condition", {})
        for key, val in condition.items():
            if str(state.get(key)) != str(val):
                return False
        return True

    # ── sensor_threshold ────────────────────────────────────────────────────
    if ttype == "sensor_threshold":
        expected = trigger.get("device_id")
        if topic != f"devices/{expected}/state":
            return False
        prop     = trigger.get("property")           # e.g. "temperature"
        operator = trigger.get("operator", ">")      # >, <, >=, <=, ==, !=
        value    = trigger.get("value")
        if prop is None or value is None:
            return False
        actual = state.get(prop)
        if actual is None:
            return False
        try:
            a, v = float(actual), float(value)
            return (operator == ">"  and a >  v) or \
                   (operator == "<"  and a <  v) or \
                   (operator == ">=" and a >= v) or \
                   (operator == "<=" and a <= v) or \
                   (operator == "==" and a == v) or \
                   (operator == "!=" and a != v)
        except (ValueError, TypeError):
            if operator == "==": return str(actual) == str(value)
            if operator == "!=": return str(actual) != str(value)
            return False

    # ── device_online ───────────────────────────────────────────────────────
    if ttype == "device_online":
        expected = trigger.get("device_id")
        if topic != f"devices/{expected}/online":
            return False
        want_online = trigger.get("online", True)   # True = fire when comes online
        return bool(state.get("online")) == bool(want_online)

    return False


async def handle_mqtt_message(topic: str, payload):
    """נקרא לכל הודעת MQTT — בודק אם כלל כלשהו מופעל."""
    rules = await get_all_rules()
    now   = int(time.time())

    for rule in rules:
        if not rule["enabled"]:
            continue
        triggered = await check_device_trigger(rule, topic, payload)
        if triggered:
            print(f"[Rules] Rule '{rule['name']}' triggered by MQTT!")
            await execute_actions(rule["actions"])
            await update_rule_last_run(rule["id"], now)
            await add_history("system", "Rule Engine", f"rule:{rule['name']}", None)


def _run_time_scheduler(loop: asyncio.AbstractEventLoop):
    """רץ ב-thread נפרד — בודק כל דקה אם יש כללים מבוססי זמן."""
    while True:
        now = time.time()
        rules_future = asyncio.run_coroutine_threadsafe(get_all_rules(), loop)
        try:
            rules = rules_future.result(timeout=5)
        except Exception:
            time.sleep(30)
            continue

        for rule in rules:
            if not rule["enabled"]:
                continue
            trigger  = rule["trigger"]
            ttype    = trigger.get("type")
            last_run = rule.get("last_run", 0)

            # ── time (cron) ──────────────────────────────────────────────
            if ttype == "time":
                cron_expr = trigger.get("cron", "")
                if not cron_expr:
                    continue
                try:
                    cron = croniter(cron_expr, now - 60)
                    next_run = cron.get_next(float)
                    if next_run <= now and (now - last_run) > 58:
                        print(f"[Rules] Time rule '{rule['name']}' firing!")
                        asyncio.run_coroutine_threadsafe(execute_actions(rule["actions"]), loop)
                        asyncio.run_coroutine_threadsafe(update_rule_last_run(rule["id"], int(now)), loop)
                except Exception as e:
                    print(f"[Rules] Cron error: {e}")

            # ── sunrise ──────────────────────────────────────────────────
            elif ttype == "sunrise":
                try:
                    offset_min = trigger.get("offset_minutes", 0)
                    rise, _    = _sun_times(now)
                    fire_at    = rise + offset_min * 60
                    if abs(now - fire_at) <= 55 and (now - last_run) > 300:
                        print(f"[Rules] Sunrise rule '{rule['name']}' firing!")
                        asyncio.run_coroutine_threadsafe(execute_actions(rule["actions"]), loop)
                        asyncio.run_coroutine_threadsafe(update_rule_last_run(rule["id"], int(now)), loop)
                except Exception as e:
                    print(f"[Rules] Sunrise error: {e}")

            # ── sunset ───────────────────────────────────────────────────
            elif ttype == "sunset":
                try:
                    offset_min = trigger.get("offset_minutes", 0)
                    _, sset    = _sun_times(now)
                    fire_at    = sset + offset_min * 60
                    if abs(now - fire_at) <= 55 and (now - last_run) > 300:
                        print(f"[Rules] Sunset rule '{rule['name']}' firing!")
                        asyncio.run_coroutine_threadsafe(execute_actions(rule["actions"]), loop)
                        asyncio.run_coroutine_threadsafe(update_rule_last_run(rule["id"], int(now)), loop)
                except Exception as e:
                    print(f"[Rules] Sunset error: {e}")

        time.sleep(55)  # 55s — stays within 1-minute cron resolution without double-fire


def start(loop: asyncio.AbstractEventLoop):
    from mqtt_client import register_handler

    async def handler(topic, payload):
        await handle_mqtt_message(topic, payload)

    register_handler(handler)

    t = threading.Thread(target=_run_time_scheduler, args=(loop,), daemon=True)
    t.start()
    print("[Rules] Rule engine started")
