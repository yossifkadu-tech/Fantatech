import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
} from "react";
import { mqttService, TOPICS } from "../services/MqttService";

const MqttContext = createContext(null);

// Room/device keys must match the room segment used in your MQTT topics.
// e.g. lights.livingroom → subscribes to home/livingroom/light
const INITIAL_LIGHTS  = { livingroom: "OFF", bedroom: "OFF", kitchen: "OFF" };
const INITIAL_AC      = { bedroom: { on: false, temp: 22 } };
const INITIAL_BLINDS  = { kitchen: "CLOSE" };
const INITIAL_LOCKS   = { entrance: "LOCK" };
const INITIAL_CAMERAS = { salon: "OFFLINE", exterior: "OFFLINE" };

export function MqttProvider({ children }) {
  const [connected, setConnected]     = useState(false);
  const [homeStatus, setHomeStatus]   = useState("SECURED");
  const [alarmActive, setAlarmActive] = useState(false);
  const [lights,  setLights]          = useState(INITIAL_LIGHTS);
  const [ac,      setAc]              = useState(INITIAL_AC);
  const [blinds,  setBlinds]          = useState(INITIAL_BLINDS);
  const [locks,   setLocks]           = useState(INITIAL_LOCKS);
  const [cameras, setCameras]         = useState(INITIAL_CAMERAS);
  const [alerts,  setAlerts]          = useState([]);

  useEffect(() => {
    mqttService.connect();

    const pollConnection = setInterval(
      () => setConnected(mqttService.connected),
      1000
    );

    const unsubs = [
      // Home status
      mqttService.subscribe(TOPICS.homeStatus, setHomeStatus),

      // Alarm — payload: ACTIVE | INACTIVE
      mqttService.subscribe(TOPICS.alarm, (msg) =>
        setAlarmActive(msg === "ACTIVE")
      ),

      // Lights — payload: ON | OFF
      ...Object.keys(INITIAL_LIGHTS).map((room) =>
        mqttService.subscribe(TOPICS.light(room), (msg) =>
          setLights((prev) => ({ ...prev, [room]: msg }))
        )
      ),

      // AC power — payload: ON | OFF
      ...Object.keys(INITIAL_AC).map((room) =>
        mqttService.subscribe(TOPICS.ac(room), (msg) =>
          setAc((prev) => ({
            ...prev,
            [room]: { ...prev[room], on: msg === "ON" },
          }))
        )
      ),

      // AC temperature — payload: numeric string e.g. "22"
      ...Object.keys(INITIAL_AC).map((room) =>
        mqttService.subscribe(TOPICS.acTemp(room), (msg) => {
          const temp = parseFloat(msg);
          if (!isNaN(temp))
            setAc((prev) => ({ ...prev, [room]: { ...prev[room], temp } }));
        })
      ),

      // Blinds — payload: OPEN | CLOSE | STOP
      ...Object.keys(INITIAL_BLINDS).map((room) =>
        mqttService.subscribe(TOPICS.blinds(room), (msg) =>
          setBlinds((prev) => ({ ...prev, [room]: msg }))
        )
      ),

      // Locks — payload: LOCK | UNLOCK
      ...Object.keys(INITIAL_LOCKS).map((door) =>
        mqttService.subscribe(TOPICS.lock(door), (msg) =>
          setLocks((prev) => ({ ...prev, [door]: msg }))
        )
      ),

      // Cameras — payload: ONLINE | OFFLINE
      ...Object.keys(INITIAL_CAMERAS).map((name) =>
        mqttService.subscribe(TOPICS.camera(name), (msg) =>
          setCameras((prev) => ({ ...prev, [name]: msg }))
        )
      ),

      // Alerts — payload: JSON { type, message, ts }
      mqttService.subscribe(TOPICS.alerts, (msg) => {
        try {
          const alert = JSON.parse(msg);
          setAlerts((prev) => [alert, ...prev].slice(0, 20));
        } catch {}
      }),
    ];

    return () => {
      clearInterval(pollConnection);
      unsubs.forEach((fn) => fn());
      mqttService.disconnect();
    };
  }, []);

  // ── Actions ────────────────────────────────────────────────────
  const toggleLight = useCallback((room) => {
    setLights((prev) => {
      const next = prev[room] === "ON" ? "OFF" : "ON";
      mqttService.publish(TOPICS.light(room), next);
      return { ...prev, [room]: next };
    });
  }, []);

  const setAcPower = useCallback((room, on) => {
    mqttService.publish(TOPICS.ac(room), on ? "ON" : "OFF");
    setAc((prev) => ({ ...prev, [room]: { ...prev[room], on } }));
  }, []);

  const setAcTemp = useCallback((room, temp) => {
    mqttService.publish(TOPICS.acTemp(room), String(temp));
    setAc((prev) => ({ ...prev, [room]: { ...prev[room], temp } }));
  }, []);

  const toggleBlinds = useCallback((room) => {
    setBlinds((prev) => {
      const next = prev[room] === "OPEN" ? "CLOSE" : "OPEN";
      mqttService.publish(TOPICS.blinds(room), next);
      return { ...prev, [room]: next };
    });
  }, []);

  const toggleLock = useCallback((door) => {
    setLocks((prev) => {
      const next = prev[door] === "LOCK" ? "UNLOCK" : "LOCK";
      mqttService.publish(TOPICS.lock(door), next);
      return { ...prev, [door]: next };
    });
  }, []);

  const triggerAlarm = useCallback(() => {
    mqttService.publish(TOPICS.alarm, "ACTIVE");
    setAlarmActive(true);
  }, []);

  const disarmAlarm = useCallback(() => {
    mqttService.publish(TOPICS.alarm, "INACTIVE");
    setAlarmActive(false);
  }, []);

  const turnAllOff = useCallback(() => {
    mqttService.publish(TOPICS.allOff, "ON");
    setLights(Object.fromEntries(Object.keys(INITIAL_LIGHTS).map((r) => [r, "OFF"])));
  }, []);

  return (
    <MqttContext.Provider
      value={{
        connected,
        homeStatus,
        alarmActive,
        lights,
        ac,
        blinds,
        locks,
        cameras,
        alerts,
        toggleLight,
        setAcPower,
        setAcTemp,
        toggleBlinds,
        toggleLock,
        triggerAlarm,
        disarmAlarm,
        turnAllOff,
      }}
    >
      {children}
    </MqttContext.Provider>
  );
}

export function useMqtt() {
  const ctx = useContext(MqttContext);
  if (!ctx) throw new Error("useMqtt must be used inside <MqttProvider>");
  return ctx;
}
