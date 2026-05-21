import mqtt from "mqtt";

// Mosquitto must have WebSocket listener enabled (default port 9001).
// Change BROKER_URL to your Raspberry Pi / mini-PC IP in production.
const BROKER_URL = "ws://localhost:9001";

const OPTIONS = {
  clientId: `fantatech-app-${Math.random().toString(16).slice(2, 8)}`,
  clean: true,
  reconnectPeriod: 3000,
  connectTimeout: 10000,
};

// Topic map — format: home/{room}/{device}
// Payloads follow HA convention: ON/OFF, OPEN/CLOSE, LOCK/UNLOCK
export const TOPICS = {
  // ── Home status ──────────────────────────────────────────────
  homeStatus: "home/status",                      // SECURED | UNSECURED | ALARM

  // ── Lights ───────────────────────────────────────────────────
  // e.g. home/livingroom/light  payload: ON | OFF
  light: (room) => `home/${room}/light`,

  // ── AC ───────────────────────────────────────────────────────
  // e.g. home/bedroom/ac  payload: ON | OFF
  //      home/bedroom/ac/temperature  payload: 22
  ac:          (room) => `home/${room}/ac`,
  acTemp:      (room) => `home/${room}/ac/temperature`,

  // ── Blinds ───────────────────────────────────────────────────
  // e.g. home/kitchen/blinds  payload: OPEN | CLOSE | STOP
  blinds: (room) => `home/${room}/blinds`,

  // ── Locks ────────────────────────────────────────────────────
  // e.g. home/entrance/lock  payload: LOCK | UNLOCK
  lock: (door) => `home/${door}/lock`,

  // ── Security / Alarm ─────────────────────────────────────────
  alarm:  "home/security/alarm",                  // ACTIVE | INACTIVE
  allOff: "home/all/off",                         // payload: ON

  // ── Cameras ──────────────────────────────────────────────────
  // e.g. home/cameras/salon  payload: ONLINE | OFFLINE
  camera: (name) => `home/cameras/${name}`,

  // ── Alerts ───────────────────────────────────────────────────
  alerts: "home/alerts",                          // JSON { type, message, ts }
};

class MqttService {
  constructor() {
    this.client = null;
    this.listeners = new Map(); // topic → Set<callback>
    this.connected = false;
  }

  connect() {
    if (this.client) return;

    this.client = mqtt.connect(BROKER_URL, OPTIONS);

    this.client.on("connect", () => {
      this.connected = true;
      console.log("[MQTT] Connected to broker");
      // Re-subscribe to all previously registered topics after reconnect
      for (const topic of this.listeners.keys()) {
        this.client.subscribe(topic);
      }
    });

    this.client.on("disconnect", () => {
      this.connected = false;
      console.log("[MQTT] Disconnected");
    });

    this.client.on("error", (err) => {
      console.warn("[MQTT] Error:", err.message);
    });

    this.client.on("message", (topic, payload) => {
      const message = payload.toString().toUpperCase();
      const callbacks = this.listeners.get(topic);
      if (callbacks) {
        callbacks.forEach((cb) => cb(message, topic));
      }
    });
  }

  disconnect() {
    this.client?.end(true);
    this.client = null;
    this.connected = false;
  }

  // Subscribe to a topic and call cb(message, topic) on each message.
  // Returns an unsubscribe function.
  subscribe(topic, cb) {
    if (!this.listeners.has(topic)) {
      this.listeners.set(topic, new Set());
      if (this.connected) this.client.subscribe(topic);
    }
    this.listeners.get(topic).add(cb);

    return () => {
      const cbs = this.listeners.get(topic);
      if (!cbs) return;
      cbs.delete(cb);
      if (cbs.size === 0) {
        this.listeners.delete(topic);
        this.client?.unsubscribe(topic);
      }
    };
  }

  publish(topic, payload, opts = { qos: 1 }) {
    const message =
      typeof payload === "object" ? JSON.stringify(payload) : String(payload);
    this.client?.publish(topic, message, opts);
  }
}

// Singleton — import this everywhere instead of creating new instances
export const mqttService = new MqttService();
