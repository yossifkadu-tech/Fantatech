// FantaTech Backend address — change to your server's local IP
const BASE_URL = "http://192.168.1.100:3000";
const WS_URL   = "ws://192.168.1.100:3000";

// ── REST helpers ─────────────────────────────────────────────

async function post(path, body) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method:  "POST",
    headers: { "Content-Type": "application/json" },
    body:    JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${path} failed: ${res.status}`);
  return res.json();
}

export const api = {
  getDevices: ()              => fetch(`${BASE_URL}/devices`).then((r) => r.json()),
  light:      (nodeId, on)    => post(`/devices/${nodeId}/light`,      { on }),
  lock:       (nodeId, lock)  => post(`/devices/${nodeId}/lock`,       { lock }),
  blinds:     (nodeId, open)  => post(`/devices/${nodeId}/blinds`,     { open }),
  thermostat: (nodeId, temp)  => post(`/devices/${nodeId}/thermostat`, { temp }),
  command:    (nodeId, body)  => post(`/devices/${nodeId}/command`,    body),
};

// ── WebSocket — real-time Matter events ──────────────────────

export function connectEventStream(onEvent) {
  const ws = new WebSocket(WS_URL);

  ws.onopen    = ()    => console.log("[API] Event stream connected");
  ws.onmessage = (e)  => {
    try { onEvent(JSON.parse(e.data)); } catch {}
  };
  ws.onclose   = ()    => {
    console.warn("[API] Event stream closed — retrying in 4s");
    setTimeout(() => connectEventStream(onEvent), 4000);
  };

  return () => ws.close();
}
