import type { HAConfig, HAEntity } from '../types';

let ws: WebSocket | null = null;
let msgId = 1;
const callbacks = new Map<number, (result: unknown) => void>();
let stateListeners: ((entities: HAEntity[]) => void)[] = [];
let entities: HAEntity[] = [];

function getConfig(): HAConfig | null {
  const stored = localStorage.getItem('ha_config');
  return stored ? JSON.parse(stored) : null;
}

export function saveConfig(config: HAConfig) {
  localStorage.setItem('ha_config', JSON.stringify(config));
}

export function loadConfig(): HAConfig | null {
  return getConfig();
}

export function onStateChange(cb: (entities: HAEntity[]) => void) {
  stateListeners.push(cb);
  if (entities.length > 0) cb(entities);
  return () => {
    stateListeners = stateListeners.filter((l) => l !== cb);
  };
}

function notify() {
  stateListeners.forEach((cb) => cb([...entities]));
}

export function connectHA(config: HAConfig): Promise<void> {
  return new Promise((resolve, reject) => {
    if (ws) {
      ws.close();
      ws = null;
    }

    const wsUrl = config.url.replace(/^http/, 'ws') + '/api/websocket';
    ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      // HA sends auth_required on open
    };

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);

      if (msg.type === 'auth_required') {
        ws!.send(JSON.stringify({ type: 'auth', access_token: config.token }));
      } else if (msg.type === 'auth_ok') {
        // Subscribe to state changes
        const subId = msgId++;
        ws!.send(JSON.stringify({ id: subId, type: 'subscribe_events', event_type: 'state_changed' }));

        // Get all states
        const statesId = msgId++;
        callbacks.set(statesId, (result) => {
          entities = result as HAEntity[];
          notify();
          resolve();
        });
        ws!.send(JSON.stringify({ id: statesId, type: 'get_states' }));
      } else if (msg.type === 'auth_invalid') {
        reject(new Error('Token HA לא תקין'));
      } else if (msg.type === 'result') {
        const cb = callbacks.get(msg.id);
        if (cb) {
          cb(msg.result);
          callbacks.delete(msg.id);
        }
      } else if (msg.type === 'event' && msg.event?.event_type === 'state_changed') {
        const newState: HAEntity = msg.event.data.new_state;
        if (newState) {
          entities = entities.map((e) => (e.entity_id === newState.entity_id ? newState : e));
          notify();
        }
      }
    };

    ws.onerror = () => reject(new Error('שגיאת חיבור ל-Home Assistant'));
    ws.onclose = () => {
      // Auto reconnect after 5s
      setTimeout(() => {
        const cfg = getConfig();
        if (cfg) connectHA(cfg).catch(() => {});
      }, 5000);
    };
  });
}

export function callService(domain: string, service: string, data: Record<string, unknown>) {
  if (!ws || ws.readyState !== WebSocket.OPEN) return;
  ws.send(JSON.stringify({ id: msgId++, type: 'call_service', domain, service, service_data: data }));
}

export function getEntities(): HAEntity[] {
  return entities;
}

export function isConnected(): boolean {
  return ws !== null && ws.readyState === WebSocket.OPEN;
}
