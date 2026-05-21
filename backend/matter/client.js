const WebSocket = require("ws");
const { v4: uuid } = require("uuid");

// python-matter-server default WebSocket endpoint
const MATTER_SERVER_URL = process.env.MATTER_SERVER_URL || "ws://localhost:5580/ws";

// Matter cluster IDs used by this system
const CLUSTERS = {
  ON_OFF:      6,    // lights, plugs
  LEVEL:       8,    // dimmer
  DOOR_LOCK:   257,  // locks
  THERMOSTAT:  513,  // AC / thermostat
  WINDOW_COV:  258,  // blinds / shades
};

class MatterClient {
  constructor() {
    this.ws = null;
    this.pending = new Map();   // messageId → { resolve, reject }
    this.listeners = new Set(); // event listeners for the backend
    this.nodes = new Map();     // nodeId → node state cache
    this.ready = false;
  }

  connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(MATTER_SERVER_URL);

      this.ws.on("open", () => {
        console.log("[Matter] Connected to python-matter-server");
        this._subscribeEvents().then(() => {
          this.ready = true;
          resolve();
        });
      });

      this.ws.on("message", (data) => this._handleMessage(JSON.parse(data)));

      this.ws.on("close", () => {
        this.ready = false;
        console.warn("[Matter] Disconnected — retrying in 5s");
        setTimeout(() => this.connect(), 5000);
      });

      this.ws.on("error", (err) => {
        console.error("[Matter] WS error:", err.message);
        reject(err);
      });
    });
  }

  // ── Send a command and await its response ────────────────────
  _send(command, args = {}) {
    return new Promise((resolve, reject) => {
      const messageId = uuid();
      this.pending.set(messageId, { resolve, reject });
      this.ws.send(JSON.stringify({ messageId, command, args }));
      // Timeout after 10 s
      setTimeout(() => {
        if (this.pending.has(messageId)) {
          this.pending.delete(messageId);
          reject(new Error(`Timeout: ${command}`));
        }
      }, 10_000);
    });
  }

  _handleMessage(msg) {
    // Resolve a pending command response
    if (msg.messageId && this.pending.has(msg.messageId)) {
      const { resolve, reject } = this.pending.get(msg.messageId);
      this.pending.delete(msg.messageId);
      if (msg.errorCode) reject(new Error(msg.details || msg.errorCode));
      else resolve(msg.result);
      return;
    }

    // Push event from Matter Server (attribute change, node added, etc.)
    if (msg.event) {
      this.listeners.forEach((fn) => fn(msg));
      // Update node state cache on attribute changes
      if (msg.event === "attribute_updated") {
        const { node_id, endpoint_id, cluster_id, attribute_name, value } = msg.data;
        if (!this.nodes.has(node_id)) this.nodes.set(node_id, {});
        const node = this.nodes.get(node_id);
        const key = `${endpoint_id}/${cluster_id}/${attribute_name}`;
        node[key] = value;
      }
    }
  }

  _subscribeEvents() {
    return this._send("subscribe_events");
  }

  // ── Public API ───────────────────────────────────────────────

  getNodes() {
    return this._send("get_nodes");
  }

  // Generic device command
  // cluster: CLUSTERS.ON_OFF etc.
  // command: "on" | "off" | "toggle" | "lockDoor" | "unlockDoor" ...
  sendCommand(nodeId, endpointId, cluster, command, payload = {}) {
    return this._send("device_command", {
      node_id:      nodeId,
      endpoint_id:  endpointId,
      cluster_id:   cluster,
      command_name: command,
      payload,
    });
  }

  // ── Convenience helpers ──────────────────────────────────────

  setLight(nodeId, on) {
    return this.sendCommand(nodeId, 1, CLUSTERS.ON_OFF, on ? "on" : "off");
  }

  setLock(nodeId, lock) {
    return this.sendCommand(nodeId, 1, CLUSTERS.DOOR_LOCK, lock ? "lockDoor" : "unlockDoor");
  }

  setBlinds(nodeId, open) {
    // WindowCovering: upOrOpen / downOrClose / stopMotion
    const cmd = open ? "upOrOpen" : "downOrClose";
    return this.sendCommand(nodeId, 1, CLUSTERS.WINDOW_COV, cmd);
  }

  setThermostat(nodeId, tempCelsius) {
    // Matter uses temp × 100 (centi-degrees)
    return this.sendCommand(nodeId, 1, CLUSTERS.THERMOSTAT, "setpointRaiseLower", {
      mode: 0,
      amount: tempCelsius * 100,
    });
  }

  onEvent(fn) {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }
}

module.exports = { MatterClient, CLUSTERS };
