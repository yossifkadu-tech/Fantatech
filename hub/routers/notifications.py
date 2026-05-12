"""
Notifications router — connection errors, device installs, critical alerts.
All events are stored for Gemini AI learning & analysis.
"""
import os
import json
import time
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from database import (
    add_notification, get_notifications, get_unread_count,
    mark_notification_read, mark_all_notifications_read, clear_notifications,
)

router = APIRouter()

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


# ── Models ────────────────────────────────────────────────────────────────────

class NotifIn(BaseModel):
    type:        str   = "info"      # critical | warning | info
    category:    str   = "system"   # connection | device | install | system | ai
    title:       str
    message:     str   = ""
    device_id:   str   = ""
    device_name: str   = ""


# ── CRUD ──────────────────────────────────────────────────────────────────────

@router.get("/")
async def list_notifications(limit: int = 200, unread_only: bool = False):
    return await get_notifications(limit=limit, unread_only=unread_only)


@router.get("/unread-count")
async def unread_count():
    return {"count": await get_unread_count()}


@router.post("/")
async def create_notification(n: NotifIn):
    await add_notification(
        type_=n.type, category=n.category, title=n.title,
        message=n.message, device_id=n.device_id, device_name=n.device_name,
    )
    # Push via WebSocket so app updates instantly
    try:
        from ws_manager import manager
        await manager.broadcast("notification", {
            "type": n.type, "category": n.category,
            "title": n.title, "message": n.message,
        })
    except Exception:
        pass
    return {"ok": True}


@router.put("/{notif_id}/read")
async def read_one(notif_id: int):
    await mark_notification_read(notif_id)
    return {"ok": True}


@router.post("/read-all")
async def read_all():
    await mark_all_notifications_read()
    return {"ok": True}


@router.delete("/")
async def clear_all():
    await clear_notifications()
    return {"ok": True}


# ── Gemini AI Analysis ────────────────────────────────────────────────────────

class AnalyzeIn(BaseModel):
    lang: str = "he"


@router.post("/analyze")
async def analyze_notifications(body: AnalyzeIn):
    """Send recent notifications to Gemini for pattern analysis and insights."""
    key = os.getenv("GEMINI_API_KEY", "").strip()
    if not key:
        raise HTTPException(503, "Gemini key not configured — go to ⚙️ Settings → Gemini AI")

    notifs = await get_notifications(limit=50)
    if not notifs:
        return {"insights": "No notifications to analyze." if body.lang != "he" else "אין התראות לניתוח."}

    # Build a compact summary of recent notifications
    lines = []
    for n in notifs[:30]:
        ts_str = time.strftime("%d/%m %H:%M", time.localtime(n["ts"]))
        line = f"[{ts_str}] [{n['type'].upper()}] [{n['category']}] {n['title']}"
        if n.get("message"):
            line += f" — {n['message']}"
        if n.get("device_name"):
            line += f" (device: {n['device_name']})"
        lines.append(line)

    notif_text = "\n".join(lines)
    lang_str = "עברית" if body.lang == "he" else "English"

    prompt = f"""You are Fantatech — a smart home AI analyst.
Analyze the following system notification log from a smart home hub.
Always reply in {lang_str}.

Notifications log (newest first):
{notif_text}

Provide:
1. A short summary of what happened in the system
2. Any patterns you notice (repeated errors, devices with issues, etc.)
3. Actionable recommendations to improve reliability
4. Overall system health score (0–100)

Be concise and practical. Use bullet points."""

    try:
        async with httpx.AsyncClient(timeout=25) as client:
            r = await client.post(
                f"{GEMINI_URL}?key={key}",
                json={
                    "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.4,
                        "maxOutputTokens": 600,
                    },
                }
            )

        if r.status_code == 429:
            raise HTTPException(429, "Rate limit — try again in a moment")
        if r.status_code != 200:
            raise HTTPException(502, f"Gemini error {r.status_code}")

        data = r.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"].strip()

        # Store AI insight as a notification
        await add_notification(
            type_="info", category="ai",
            title="AI Analysis" if body.lang != "he" else "ניתוח AI",
            message=text[:300] + ("..." if len(text) > 300 else ""),
        )

        return {"insights": text}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Gemini error: {e}")
