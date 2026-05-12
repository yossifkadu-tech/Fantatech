from fastapi import APIRouter
from database import get_history, add_history, clear_history

router = APIRouter()


@router.get("/")
async def list_history(limit: int = 100):
    return await get_history(limit)


@router.delete("/")
async def delete_history():
    await clear_history()
    return {"ok": True}
