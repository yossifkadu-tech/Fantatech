from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import get_all_devices, get_device, upsert_device, delete_device, add_history, pin_device, rename_device, add_notification
from mqtt_client import publish

router = APIRouter()


class DeviceIn(BaseModel):
    id: str
    name: str
    protocol: str        # wifi | zigbee | zwave | matter | camera | custom
    type: str            # light | switch | dimmer | sensor | camera | lock | ac | fan
    topic_state: str     # e.g. "devices/living_light/state"
    topic_cmd: str       # e.g. "devices/living_light/cmd"
    room: str = ""
    label: str = ""
    config: dict = {}


class CommandIn(BaseModel):
    payload: dict


class PinIn(BaseModel):
    pinned: bool


class RenameIn(BaseModel):
    name: str
    label: str = ""


@router.get("/")
async def list_devices():
    return await get_all_devices()


@router.get("/{device_id}")
async def get_one(device_id: str):
    d = await get_device(device_id)
    if not d:
        raise HTTPException(404, "Device not found")
    return d


@router.post("/")
async def add_device(d: DeviceIn):
    existing = await get_device(d.id)
    await upsert_device(d.model_dump())
    if not existing:
        await add_notification(
            type_="info", category="install",
            title=f"Device added: {d.name}",
            message=f"Type: {d.type} · Protocol: {d.protocol}{' · ' + d.label if d.label else ''}",
            device_id=d.id, device_name=d.name,
        )
    return await get_device(d.id)


@router.put("/{device_id}")
async def update_device(device_id: str, d: DeviceIn):
    await upsert_device({**d.model_dump(), "id": device_id})
    return await get_device(device_id)


@router.delete("/{device_id}")
async def remove_device(device_id: str):
    d = await get_device(device_id)
    name = d["name"] if d else device_id
    await delete_device(device_id)
    await add_notification(
        type_="warning", category="install",
        title=f"Device removed: {name}",
        message=f"Device '{name}' (id: {device_id}) was deleted from the system.",
        device_id=device_id, device_name=name,
    )
    return {"ok": True}


@router.post("/{device_id}/cmd")
async def send_command(device_id: str, cmd: CommandIn):
    d = await get_device(device_id)
    if not d:
        raise HTTPException(404, "Device not found")
    publish(d["topic_cmd"], cmd.payload)
    await add_history(device_id, d["name"], "cmd", str(cmd.payload))
    return {"ok": True, "topic": d["topic_cmd"], "payload": cmd.payload}


@router.post("/{device_id}/pin")
async def pin(device_id: str, p: PinIn):
    await pin_device(device_id, p.pinned)
    return {"ok": True, "pinned": p.pinned}


@router.put("/{device_id}/rename")
async def rename(device_id: str, r: RenameIn):
    await rename_device(device_id, r.name, r.label)
    return await get_device(device_id)


@router.post("/{device_id}/toggle")
async def toggle(device_id: str):
    d = await get_device(device_id)
    if not d:
        raise HTTPException(404, "Device not found")
    current = d["state"].get("state", "OFF")
    new_state = "OFF" if current == "ON" else "ON"
    publish(d["topic_cmd"], {"state": new_state})
    await add_history(device_id, d["name"], "toggle", new_state)
    return {"ok": True, "state": new_state}
