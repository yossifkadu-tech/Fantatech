import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import get_all_rooms, upsert_room, delete_room

router = APIRouter()


class RoomIn(BaseModel):
    name: str
    icon: str = "🏠"


@router.get("/")
async def list_rooms():
    return await get_all_rooms()


@router.post("/")
async def create_room(r: RoomIn):
    room = {**r.model_dump(), "id": str(uuid.uuid4())}
    await upsert_room(room)
    return room


@router.put("/{room_id}")
async def update_room(room_id: str, r: RoomIn):
    room = {**r.model_dump(), "id": room_id}
    await upsert_room(room)
    return room


@router.delete("/{room_id}")
async def remove_room(room_id: str):
    await delete_room(room_id)
    return {"ok": True}
