"""WebSocket manager — שולח עדכונים real-time לכל הלקוחות המחוברים."""
import json
from fastapi import WebSocket


class WSManager:
    def __init__(self):
        self._clients: list[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self._clients.append(ws)
        print(f"[WS] Client connected. Total: {len(self._clients)}")

    def disconnect(self, ws: WebSocket):
        self._clients.remove(ws)
        print(f"[WS] Client disconnected. Total: {len(self._clients)}")

    async def broadcast(self, event: str, data: dict):
        if not self._clients:
            return
        msg = json.dumps({"event": event, "data": data})
        dead = []
        for ws in self._clients:
            try:
                await ws.send_text(msg)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self._clients.remove(ws)


manager = WSManager()
