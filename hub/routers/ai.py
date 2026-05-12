"""
AI integrations — Gemini chat assistant + Home Assistant import.
Gemini can answer questions, control devices, and set timers.
"""
import os
import json
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


# ── Models ────────────────────────────────────────────────────────────────────

class ImportHAIn(BaseModel):
    url:   str
    token: str


class ChatIn(BaseModel):
    message: str
    lang:    str = "he"
    history: list = []


class SetKeyIn(BaseModel):
    key: str


# ── Gemini status & key ───────────────────────────────────────────────────────

@router.get("/status")
async def ai_status():
    key = os.getenv("GEMINI_API_KEY", "").strip()
    return {"configured": bool(key)}


@router.post("/set-key")
async def set_gemini_key(body: SetKeyIn):
    key = body.key.strip()
    env_path = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '.env'))
    try:
        lines = []
        try:
            with open(env_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except FileNotFoundError:
            pass
        new_lines, found = [], False
        for line in lines:
            if line.startswith('GEMINI_API_KEY='):
                new_lines.append(f'GEMINI_API_KEY={key}\n')
                found = True
            else:
                new_lines.append(line)
        if not found:
            new_lines.append(f'GEMINI_API_KEY={key}\n')
        with open(env_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        os.environ['GEMINI_API_KEY'] = key
    except Exception as e:
        raise HTTPException(500, f"שגיאה בשמירת המפתח: {e}")
    return {"ok": True}


# ── Gemini chat ───────────────────────────────────────────────────────────────

@router.post("/chat")
async def ai_chat(body: ChatIn):
    key = os.getenv("GEMINI_API_KEY", "").strip()
    if not key:
        raise HTTPException(503, "מפתח Gemini לא מוגדר — הגדר ב-⚙️ הגדרות → Gemini AI")

    from database import get_all_devices
    devices = await get_all_devices()

    # Build compact device list for context
    def _dev_summary(d):
        s = d.get("state", {})
        parts = [f"name='{d['name']}'", f"id={d['id']}", f"type={d['type']}",
                 f"state={s.get('state', '?')}", f"online={d['online']}"]
        if d.get("room"):
            parts.append(f"room={d['room']}")
        if d["type"] == "ac" and s:
            parts.append(f"temp={s.get('temperature','?')}° mode={s.get('mode','?')}")
        return "- " + " | ".join(parts)

    device_list = "\n".join(_dev_summary(d) for d in devices[:40])
    lang_str = "עברית" if body.lang == "he" else "English"

    system_prompt = f"""You are Fantatech — a smart home AI assistant.
Always reply in {lang_str}.
Be concise and friendly.

Current devices in the home:
{device_list}

When the user wants to CONTROL a device, respond with valid JSON only:
{{"reply": "short friendly message to user", "action": {{"type": "device_control", "device_id": "exact_id", "command": {{"state": "ON"}}}}}}

For AC control include ac params:
{{"reply": "...", "action": {{"type": "device_control", "device_id": "...", "command": {{"state": "ON", "temperature": 22, "mode": "cool"}}}}}}

For setting a timer:
{{"reply": "...", "action": {{"type": "set_timer", "device_id": "...", "delay_min": 60, "action": "off"}}}}

For questions / status / info — reply with plain text (not JSON).
When replying with JSON, output ONLY the JSON object, nothing else."""

    # Build conversation history
    contents = []
    for msg in body.history[-8:]:
        role = "user" if msg.get("role") == "user" else "model"
        contents.append({"role": role, "parts": [{"text": msg.get("text", "")}]})
    contents.append({"role": "user", "parts": [{"text": body.message}]})

    try:
        async with httpx.AsyncClient(timeout=20) as client:
            r = await client.post(
                f"{GEMINI_URL}?key={key}",
                json={
                    "system_instruction": {"parts": [{"text": system_prompt}]},
                    "contents": contents,
                    "generationConfig": {
                        "temperature":     0.65,
                        "maxOutputTokens": 512,
                        "topP":            0.9,
                    },
                }
            )

        if r.status_code == 400:
            raise HTTPException(400, f"Gemini: בקשה שגויה — {r.json().get('error', {}).get('message', r.text[:100])}")
        if r.status_code == 429:
            raise HTTPException(429, "Gemini: הגעת למגבלת בקשות — נסה שוב בעוד רגע")
        if r.status_code != 200:
            raise HTTPException(502, f"Gemini error {r.status_code}")

        data = r.json()
        candidates = data.get("candidates", [])
        if not candidates:
            raise HTTPException(502, "Gemini לא החזיר תשובה")

        text = candidates[0]["content"]["parts"][0]["text"].strip()

        # Try to parse as action JSON
        try:
            # Handle markdown code blocks
            clean = text.strip("` \n")
            if clean.startswith("json"):
                clean = clean[4:].strip()
            parsed = json.loads(clean)
            return {
                "reply":  parsed.get("reply", text),
                "action": parsed.get("action"),
            }
        except (json.JSONDecodeError, ValueError):
            return {"reply": text, "action": None}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"שגיאת Gemini: {e}")


# ── Home Assistant import ─────────────────────────────────────────────────────

@router.post("/import-ha")
async def import_from_ha(body: ImportHAIn):
    """Import devices from a Home Assistant instance via its REST API."""
    from database import upsert_device
    import time as _time

    base = body.url.rstrip('/')
    headers = {"Authorization": f"Bearer {body.token}", "Content-Type": "application/json"}

    async with httpx.AsyncClient(timeout=15, headers=headers, verify=False) as client:
        try:
            r = await client.get(f"{base}/api/states")
            r.raise_for_status()
        except Exception as e:
            raise HTTPException(400, f"לא ניתן להתחבר ל-Home Assistant: {e}")
        states = r.json()

    imported = 0
    for entity in states:
        entity_id: str = entity.get("entity_id", "")
        domain = entity_id.split(".")[0]
        if domain not in ("light", "switch", "sensor", "binary_sensor", "fan", "lock", "cover"):
            continue
        attrs = entity.get("attributes", {})
        name  = attrs.get("friendly_name") or entity_id.replace("_", " ").title()
        dev_type = {
            "light": "light", "switch": "switch", "sensor": "sensor",
            "binary_sensor": "sensor", "fan": "fan", "lock": "lock", "cover": "switch",
        }.get(domain, "switch")
        safe_id = f"ha_{entity_id.replace('.', '_')}"
        await upsert_device({
            "id":          safe_id,
            "name":        name,
            "protocol":    "custom",
            "type":        dev_type,
            "topic_state": f"homeassistant/{entity_id}/state",
            "topic_cmd":   f"homeassistant/{entity_id}/set",
            "room":        "",
            "config":      {"ha_entity_id": entity_id, "source": "homeassistant"},
            "state":       {"state": "ON" if str(entity.get("state", "off")).lower() in ("on", "true", "1") else "OFF"},
            "online":      True,
            "pinned":      False,
            "label":       f"HA · {domain}",
            "created_at":  int(_time.time()),
        })
        imported += 1

    return {"ok": True, "imported": imported,
            "message": f"✅ יובאו {imported} מכשירים מ-Home Assistant"}
