const express  = require("express");
const cors     = require("cors");
const http     = require("http");
const WebSocket = require("ws");
const { MatterClient } = require("./matter/client");
const devicesRouter    = require("./routes/devices");

const PORT = process.env.PORT || 3000;

const app    = express();
const server = http.createServer(app);

// ── Middleware ───────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── REST routes ──────────────────────────────────────────────
app.use("/devices", devicesRouter);

app.get("/health", (_req, res) => res.json({ ok: true }));

// ── WebSocket server (real-time push to the app) ─────────────
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws) => {
  console.log("[WS] App client connected");
  ws.on("close", () => console.log("[WS] App client disconnected"));
});

function broadcast(data) {
  const msg = JSON.stringify(data);
  wss.clients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) ws.send(msg);
  });
}

// ── Matter Server connection ─────────────────────────────────
const matter = new MatterClient();
app.locals.matter = matter;

// Forward Matter events → connected app clients
matter.onEvent((event) => {
  broadcast({ type: "matter_event", event });
});

// ── Boot ─────────────────────────────────────────────────────
async function start() {
  try {
    await matter.connect();
  } catch (err) {
    console.warn("[Matter] Could not connect at startup — will retry:", err.message);
  }

  server.listen(PORT, () => {
    console.log(`FantaTech Backend running on http://localhost:${PORT}`);
    console.log(`WebSocket push      on ws://localhost:${PORT}`);
  });
}

start();
