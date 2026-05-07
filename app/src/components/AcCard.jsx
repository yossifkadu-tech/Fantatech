/**
 * AcCard — full AC control card with timer support.
 * Supports: Sensibo, MQTT, Tuya protocols.
 * Brands: Tadiran, Electra, General, Mitsubishi, Daikin, LG, Samsung, Gree, Haier…
 */
import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

export default function AcCard({ device, onUpdate, roomName }) {
  const { t } = useLang()

  const MODES = [
    { id: 'cool', label: t.ac_mode_cool, icon: '❄️' },
    { id: 'heat', label: t.ac_mode_heat, icon: '🔥' },
    { id: 'fan',  label: t.ac_mode_fan,  icon: '💨' },
    { id: 'dry',  label: t.ac_mode_dry,  icon: '💧' },
    { id: 'auto', label: t.ac_mode_auto, icon: '🔄' },
  ]

  const FANS = [
    { id: 'auto',   label: t.fan_auto   },
    { id: 'quiet',  label: t.fan_quiet  },
    { id: 'low',    label: t.fan_low    },
    { id: 'medium', label: t.fan_medium },
    { id: 'high',   label: t.fan_high   },
  ]

  const TIMER_OPTIONS = [
    { label: t.ac_timer_30min, min: 30  },
    { label: t.ac_timer_1h,    min: 60  },
    { label: t.ac_timer_2h,    min: 120 },
    { label: t.ac_timer_3h,    min: 180 },
  ]

  const state      = device.state || {}
  const isOn       = state.state === 'ON'
  const online     = device.online
  const [busy, setBusy]           = useState(false)
  const [showTimer, setShowTimer] = useState(false)
  const [activeTimers, setActiveTimers] = useState([])
  const [timerLoading, setTimerLoading] = useState(false)
  const [customMin, setCustomMin] = useState('')

  useEffect(() => {
    loadTimers()
  }, [device.id])

  const loadTimers = async () => {
    try {
      const r = await api.get(`/timers/device/${device.id}`)
      setActiveTimers(r.data || [])
    } catch {}
  }

  const send = async (patch) => {
    if (busy) return
    setBusy(true)
    try {
      await api.post(`/ac/control/${device.id}`, patch)
      onUpdate?.()
    } catch {}
    setBusy(false)
  }

  const togglePower = () => send({ state: isOn ? 'OFF' : 'ON' })
  const setMode     = (mode) => { if (isOn) send({ mode }) }
  const setFan      = (fan)  => { if (isOn) send({ fan  }) }
  const adjustTemp  = (delta) => {
    const cur = state.temperature || 24
    send({ temperature: Math.max(16, Math.min(30, cur + delta)) })
  }

  const setTimer = async (delayMin) => {
    if (!delayMin || delayMin < 1) return
    setTimerLoading(true)
    try {
      await api.post('/timers/', {
        device_id: device.id,
        action:    'off',
        delay_min: parseInt(delayMin),
      })
      await loadTimers()
      setShowTimer(false)
      setCustomMin('')
    } catch (e) {
      alert(e?.response?.data?.detail || t.ac_timer_error)
    }
    setTimerLoading(false)
  }

  const cancelTimer = async (timerId) => {
    try {
      await api.delete(`/timers/${timerId}`)
      await loadTimers()
    } catch {}
  }

  const currentMode = state.mode || 'cool'
  const currentFan  = state.fan  || 'auto'
  const temp        = state.temperature || 24
  const curTemp     = state.current_temp
  const curHumidity = state.current_humidity

  const hasTimer = activeTimers.length > 0

  const fmtRemaining = (firesAt) => {
    const diff = firesAt - Math.floor(Date.now() / 1000)
    if (diff <= 0) return t.ac_timer_off_soon
    const h = Math.floor(diff / 3600)
    const m = Math.floor((diff % 3600) / 60)
    if (h > 0) return `${h}${t.ac_timer_h} ${m}${t.ac_timer_m}`
    return `${m} ${t.ac_timer_min}`
  }

  return (
    <div style={{
      background: isOn ? '#0c2340' : '#1e293b',
      border: `1px solid ${hasTimer ? '#f59e0b' : isOn ? '#1d4ed8' : '#334155'}`,
      borderRadius: 16, padding: 14,
      opacity: online ? 1 : 0.55,
      transition: 'all 0.25s',
    }}>

      {/* Header row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 20 }}>❄️</span>
            <div>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#e2e8f0' }}>
                {device.pinned && <span style={{ fontSize: 11 }}>📌 </span>}
                {device.name}
              </div>
              {device.label && (
                <div style={{ fontSize: 10, color: '#38bdf8' }}>{device.label}</div>
              )}
              <div style={{ fontSize: 10, color: '#475569' }}>
                {roomName || t.no_room} · {device.protocol}
              </div>
            </div>
          </div>
        </div>

        {/* Power button */}
        <button
          onClick={togglePower}
          disabled={!online || busy}
          style={{
            width: 44, height: 44, borderRadius: '50%',
            background: isOn ? '#1d4ed8' : '#334155',
            border: `2px solid ${isOn ? '#60a5fa' : '#475569'}`,
            color: isOn ? '#fff' : '#94a3b8',
            fontSize: 18, cursor: online ? 'pointer' : 'not-allowed',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'all 0.2s', opacity: busy ? 0.6 : 1,
          }}>
          ⏻
        </button>
      </div>

      {/* Active timer banner */}
      {hasTimer && activeTimers.map(timer => (
        <div key={timer.id} style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          background: '#1c1007', border: '1px solid #f59e0b',
          borderRadius: 8, padding: '5px 10px', marginBottom: 8,
        }}>
          <span style={{ fontSize: 12, color: '#fcd34d' }}>
            {t.ac_timer_auto_off} {fmtRemaining(timer.fires_at)}
          </span>
          <button onClick={() => cancelTimer(timer.id)} style={{
            background: 'none', border: 'none', color: '#f59e0b', cursor: 'pointer', fontSize: 12,
          }}>{t.ac_timer_cancel}</button>
        </div>
      ))}

      {/* Current conditions (Sensibo measurements) */}
      {(curTemp != null || curHumidity != null) && (
        <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
          {curTemp != null && <Chip icon="🌡️" value={`${curTemp}°C`} color="#f59e0b" />}
          {curHumidity != null && <Chip icon="💧" value={`${curHumidity}%`} color="#38bdf8" />}
        </div>
      )}

      {/* Temperature control */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        gap: 16, marginBottom: 12, opacity: isOn ? 1 : 0.4,
      }}>
        <button onClick={() => adjustTemp(-1)} disabled={!isOn || busy} style={tempBtn}>−</button>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 36, fontWeight: 800, color: isOn ? '#38bdf8' : '#475569', lineHeight: 1 }}>
            {temp}°
          </div>
          <div style={{ fontSize: 10, color: '#475569' }}>16° — 30°</div>
        </div>
        <button onClick={() => adjustTemp(+1)} disabled={!isOn || busy} style={tempBtn}>+</button>
      </div>

      {/* Mode selector */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 8, opacity: isOn ? 1 : 0.35 }}>
        {MODES.map(m => (
          <button key={m.id} onClick={() => setMode(m.id)} disabled={!isOn || busy} style={{
            flex: 1, padding: '5px 2px', borderRadius: 8,
            background: isOn && currentMode === m.id ? '#1d4ed8' : '#1e293b',
            border: `1px solid ${isOn && currentMode === m.id ? '#3b82f6' : '#334155'}`,
            cursor: isOn ? 'pointer' : 'default',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1,
          }}>
            <span style={{ fontSize: 14 }}>{m.icon}</span>
            <span style={{ fontSize: 8.5, color: isOn && currentMode === m.id ? '#fff' : '#64748b', fontWeight: 600 }}>
              {m.label}
            </span>
          </button>
        ))}
      </div>

      {/* Fan speed */}
      <div style={{ display: 'flex', gap: 3, marginBottom: 10, opacity: isOn ? 1 : 0.35 }}>
        {FANS.map(f => (
          <button key={f.id} onClick={() => setFan(f.id)} disabled={!isOn || busy} style={{
            flex: 1, padding: '4px 2px', borderRadius: 6,
            fontSize: 9, fontWeight: 600,
            background: isOn && currentFan === f.id ? '#0f4c81' : '#0f172a',
            border: `1px solid ${isOn && currentFan === f.id ? '#3b82f6' : '#1e293b'}`,
            color: isOn && currentFan === f.id ? '#93c5fd' : '#475569',
            cursor: isOn ? 'pointer' : 'default',
          }}>
            {f.id === 'auto' ? '💨' : ''}  {f.label}
          </button>
        ))}
      </div>

      {/* Timer button */}
      <button
        onClick={() => setShowTimer(v => !v)}
        style={{
          width: '100%', padding: '6px 0', borderRadius: 8,
          background: showTimer ? '#451a03' : '#1e293b',
          border: `1px solid ${showTimer ? '#f59e0b' : '#334155'}`,
          color: showTimer ? '#fcd34d' : '#64748b',
          fontSize: 11, cursor: 'pointer', fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
        }}>
        ⏰ {hasTimer ? t.ac_timer_active : t.ac_timer_set_label}
      </button>

      {/* Timer panel */}
      {showTimer && (
        <div style={{
          marginTop: 8, background: '#0f172a', border: '1px solid #334155',
          borderRadius: 10, padding: 12,
        }}>
          <div style={{ fontSize: 12, color: '#94a3b8', marginBottom: 8, fontWeight: 600 }}>
            {t.ac_timer_panel_title}
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
            {TIMER_OPTIONS.map(opt => (
              <button key={opt.min} onClick={() => setTimer(opt.min)} disabled={timerLoading} style={{
                padding: '7px 12px', borderRadius: 8, border: '1px solid #334155',
                background: '#1e293b', color: '#f1f5f9', cursor: 'pointer',
                fontSize: 12, fontWeight: 600, opacity: timerLoading ? 0.6 : 1,
              }}>
                {opt.label}
              </button>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <input
              type="number"
              value={customMin}
              onChange={e => setCustomMin(e.target.value)}
              placeholder={t.ac_timer_minutes_ph}
              min={1} max={480}
              style={{
                flex: 1, padding: '7px 10px', borderRadius: 8,
                border: '1px solid #334155', background: '#1e293b',
                color: '#f1f5f9', fontSize: 12,
              }}
            />
            <button
              onClick={() => setTimer(customMin)}
              disabled={!customMin || timerLoading}
              style={{
                padding: '7px 14px', borderRadius: 8, border: 'none',
                background: customMin ? '#1d4ed8' : '#334155',
                color: '#fff', cursor: customMin ? 'pointer' : 'default',
                fontSize: 12, fontWeight: 600,
              }}>
              {t.ac_timer_set_btn}
            </button>
          </div>
        </div>
      )}

      {/* Offline */}
      {!online && (
        <div style={{ fontSize: 11, color: '#ef4444', marginTop: 8, textAlign: 'center' }}>
          {t.ac_offline}
        </div>
      )}
    </div>
  )
}

function Chip({ icon, value, color }) {
  return (
    <div style={{
      background: '#0f172a', border: '1px solid #334155',
      borderRadius: 8, padding: '3px 8px',
      fontSize: 12, color, display: 'flex', gap: 4, alignItems: 'center',
    }}>
      {icon} {value}
    </div>
  )
}

const tempBtn = {
  width: 40, height: 40, borderRadius: '50%',
  background: '#1e293b', border: '1px solid #334155',
  color: '#38bdf8', fontSize: 22, fontWeight: 700,
  cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
  transition: 'all 0.15s',
}
