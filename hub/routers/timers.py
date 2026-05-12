"""
Timers — one-shot scheduled actions (e.g. "turn AC off in 2 hours").
Timers live in memory; they reset on hub restart (by design — these are sleep timers).
"""
import asyncio
import time
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

# In-memory store: id → timer dict (task excluded from API responses)
_timers: dict[str, dict] = {}


class TimerIn(BaseModel):
    device_id: str
    action:    str = "off"    # "on" | "off"
    delay_min: int            # minutes from now (1–480)
    params:    dict = {}      # extra params for AC (temperature, mode, etc.)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/")
async def list_timers():
    now = int(time.time())
    return [
        {k: v for k, v in t.items() if k != "_task"}
        for t in _timers.values()
        if t["fires_at"] > now
    ]


@router.post("/")
async def create_timer(body: TimerIn):
    if not (1 <= body.delay_min <= 480):
        raise HTTPException(400, "delay_min חייב להיות בין 1 ל-480 דקות")

    timer_id = str(uuid.uuid4())[:8]
    fires_at = int(time.time()) + body.delay_min * 60

    async def _fire():
        await asyncio.sleep(body.delay_min * 60)
        from database import get_device, update_device_state, add_history
        from ws_manager import manager

        device = await get_device(body.device_id)
        if not device:
            _timers.pop(timer_id, None)
            return

        try:
            if device["type"] == "ac":
                from routers.ac import control_ac, AcCommand
                cmd_data = {"state": body.action.upper()}
                cmd_data.update(body.params)
                await control_ac(body.device_id, AcCommand(**{k: v for k, v in cmd_data.items() if v is not None}))
            else:
                state = dict(device.get("state", {}))
                state["state"] = body.action.upper()
                await update_device_state(body.device_id, state)
                await manager.broadcast("device_state", {"id": body.device_id, "state": state, "online": True})

            label = f"כיבוי בטיימר" if body.action == "off" else "הדלקה בטיימר"
            await add_history(body.device_id, device["name"], "timer", label)

        except Exception as e:
            print(f"[Timer] Error firing timer {timer_id}: {e}")

        _timers.pop(timer_id, None)

    task = asyncio.create_task(_fire())
    _timers[timer_id] = {
        "id":        timer_id,
        "device_id": body.device_id,
        "action":    body.action,
        "delay_min": body.delay_min,
        "fires_at":  fires_at,
        "params":    body.params,
        "_task":     task,
    }

    # Resolve device name for response
    from database import get_device
    device = await get_device(body.device_id)
    device_name = device["name"] if device else body.device_id

    return {
        "ok":          True,
        "id":          timer_id,
        "device_id":   body.device_id,
        "device_name": device_name,
        "action":      body.action,
        "delay_min":   body.delay_min,
        "fires_at":    fires_at,
    }


@router.delete("/{timer_id}")
async def cancel_timer(timer_id: str):
    t = _timers.get(timer_id)
    if not t:
        raise HTTPException(404, "טיימר לא נמצא")
    t["_task"].cancel()
    _timers.pop(timer_id, None)
    return {"ok": True, "cancelled": timer_id}


@router.get("/device/{device_id}")
async def get_device_timers(device_id: str):
    now = int(time.time())
    return [
        {k: v for k, v in t.items() if k != "_task"}
        for t in _timers.values()
        if t["device_id"] == device_id and t["fires_at"] > now
    ]
