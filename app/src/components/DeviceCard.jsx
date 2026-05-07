import { useState } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

const TYPE_ICONS = {
  light: '💡', switch: '🔌', dimmer: '🔆', color: '🎨',
  sensor: '🌡️', camera: '📷', lock: '🔒', gateway: '📡',
  fan: '🌀', ac: '❄️', motion: '👤', door: '🚪', smoke: '🔥',
}

export default function DeviceCard({ device, onUpdate, roomName }) {
  const { t } = useLang()
  const [loading, setLoading]     = useState(false)
  const [showMore, setShowMore]   = useState(false)

  const state  = device.state || {}
  const isOn   = state.state === 'ON'
  const online = device.online

  const toggle = async () => {
    if (loading || !online) return
    setLoading(true)
    try {
      await api.post(`/devices/${device.id}/toggle`)
      onUpdate?.()
    } catch {}
    setLoading(false)
  }

  const sendCmd = async (payload) => {
    try {
      await api.post(`/devices/${device.id}/cmd`, { payload })
      onUpdate?.()
    } catch {}
  }

  const togglePin = async (e) => {
    e.stopPropagation()
    try {
      await api.put(`/devices/${device.id}`, { ...device, pinned: !device.pinned })
      onUpdate?.()
    } catch {}
  }

  /* ── Security sensor — door/motion/smoke ── */
  const isSensor  = ['sensor', 'motion', 'door', 'smoke'].includes(device.type)
  const isLock    = device.type === 'lock'
  const isRGB     = device.type === 'color'
  const isDimmer  = device.type === 'dimmer' || device.type === 'color'
  const hasPower  = state.power_w !== undefined
  const hasBat    = state.battery !== undefined

  /* sensor alert color */
  const alertColor = (() => {
    if (state.smoke)            return '#ef4444'
    if (state.occupancy)        return '#f59e0b'
    if (state.contact === false) return '#f59e0b'
    return null
  })()

  return (
    <div style={{
      background: alertColor ? '#1c0a00' : isOn ? '#1e3a5f' : '#1e293b',
      border: `1px solid ${alertColor || (isOn ? '#3b82f6' : '#334155')}`,
      borderRadius: 14, padding: 14, transition: 'all 0.2s',
      opacity: online ? 1 : 0.55,
      position: 'relative',
    }}>
      {/* Pin button */}
      <button onClick={togglePin} style={{
        position: 'absolute', top: 8, left: 8,
        background: 'none', border: 'none', cursor: 'pointer',
        fontSize: 14, opacity: device.pinned ? 1 : 0.25,
        transition: 'opacity .2s',
      }}>📌</button>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: 1, minWidth: 0 }}>
          <span style={{ fontSize: 22, flexShrink: 0 }}>
            {alertColor ? (state.smoke ? '🔥' : state.occupancy ? '👤' : '🚪') : (TYPE_ICONS[device.type] || '🔌')}
          </span>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontWeight: 600, fontSize: 13, color: '#f1f5f9', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {device.name}
            </div>
            {device.label && (
              <div style={{ fontSize: 10, color: '#38bdf8' }}>{device.label}</div>
            )}
            <div style={{ fontSize: 10, color: '#475569' }}>
              {roomName || t.no_room}
            </div>
          </div>
        </div>

        {/* Toggle / Lock / Sensor indicator */}
        {isLock ? (
          <LockBtn locked={state.state !== 'UNLOCKED'} loading={loading}
            onToggle={() => sendCmd({ state: state.state === 'UNLOCKED' ? 'LOCK' : 'UNLOCK' })} />
        ) : isSensor ? (
          <SensorBadge state={state} type={device.type} />
        ) : (
          <Toggle on={isOn} loading={loading} onChange={toggle} disabled={!online} />
        )}
      </div>

      {/* Alert banner */}
      {alertColor && (
        <div style={{
          background: alertColor + '22', border: `1px solid ${alertColor}`,
          borderRadius: 8, padding: '4px 10px', fontSize: 12,
          color: alertColor, fontWeight: 700, marginBottom: 8, textAlign: 'center',
        }}>
          {state.smoke ? t.smoke_alert_banner : state.occupancy ? t.motion_alert_banner : t.door_open_banner}
        </div>
      )}

      {/* Sensor values */}
      {(state.temperature !== undefined || state.humidity !== undefined) && (
        <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
          {state.temperature !== undefined && (
            <Pill icon="🌡️" value={`${state.temperature}°C`} color="#38bdf8" />
          )}
          {state.humidity !== undefined && (
            <Pill icon="💧" value={`${state.humidity}%`} color="#22c55e" />
          )}
        </div>
      )}

      {/* Brightness slider */}
      {isDimmer && isOn && (
        <div style={{ marginTop: 6 }}>
          <div style={{ fontSize: 10, color: '#94a3b8', marginBottom: 3 }}>
            {t.brightness} {state.brightness ? Math.round(state.brightness / 255 * 100) + '%' : ''}
          </div>
          <input type="range" min={1} max={255}
            defaultValue={state.brightness || 128}
            onChange={e => sendCmd({ brightness: parseInt(e.target.value) })}
            style={{ width: '100%', accentColor: '#38bdf8', cursor: 'pointer' }} />
        </div>
      )}

      {/* RGB color picker */}
      {isRGB && isOn && (
        <div style={{ marginTop: 6 }}>
          <div style={{ fontSize: 10, color: '#94a3b8', marginBottom: 4 }}>{t.color}</div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {['#ffffff', '#ff6b6b', '#ffd93d', '#6bcb77', '#4d96ff', '#ff922b', '#cc5de8', '#f06595'].map(c => (
              <div key={c} onClick={() => sendCmd({ color: { hex: c } })}
                style={{
                  width: 26, height: 26, borderRadius: '50%', background: c,
                  cursor: 'pointer', border: '2px solid #1e293b',
                  boxShadow: state.color?.hex === c ? `0 0 0 2px ${c}` : 'none',
                  transition: 'box-shadow .15s',
                }} />
            ))}
            <input type="color" defaultValue={state.color?.hex || '#ffffff'}
              onChange={e => sendCmd({ color: { hex: e.target.value } })}
              style={{ width: 26, height: 26, borderRadius: '50%', border: 'none', cursor: 'pointer', background: 'none', padding: 0 }}
              title="בחר צבע" />
          </div>
        </div>
      )}

      {/* Color temp (light only) */}
      {device.type === 'light' && isOn && state.color_temp !== undefined && (
        <div style={{ marginTop: 6 }}>
          <div style={{ fontSize: 10, color: '#94a3b8', marginBottom: 3 }}>{t.warm_cold}</div>
          <input type="range" min={153} max={500}
            defaultValue={state.color_temp || 300}
            onChange={e => sendCmd({ color_temp: parseInt(e.target.value) })}
            style={{ width: '100%', accentColor: '#fbbf24', cursor: 'pointer' }} />
        </div>
      )}

      {/* Power consumption */}
      {hasPower && (
        <div style={{ fontSize: 11, color: '#64748b', marginTop: 6, display: 'flex', gap: 10 }}>
          <span>⚡ {state.power_w}W</span>
          {state.voltage && <span>🔋 {state.voltage}V</span>}
          {state.current && <span>〰️ {state.current}A</span>}
        </div>
      )}

      {/* Battery */}
      {hasBat && (
        <div style={{ fontSize: 11, marginTop: 6 }}>
          <BatteryBar pct={state.battery} />
        </div>
      )}

      {/* Offline */}
      {!online && (
        <div style={{ fontSize: 10, color: '#ef4444', marginTop: 6 }}>{t.offline_badge}</div>
      )}
    </div>
  )
}

/* ── Sub-components ──────────────────────────────────────────────── */

function Toggle({ on, loading, onChange, disabled }) {
  return (
    <div onClick={disabled ? undefined : onChange} style={{
      width: 46, height: 26, borderRadius: 13, flexShrink: 0,
      background: on ? '#22c55e' : '#475569',
      cursor: disabled ? 'not-allowed' : 'pointer',
      position: 'relative', transition: 'background 0.2s',
      opacity: loading ? 0.6 : 1,
    }}>
      <div style={{
        position: 'absolute', top: 3,
        left: on ? 23 : 3, width: 20, height: 20,
        borderRadius: '50%', background: '#fff',
        transition: 'left 0.2s', boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
      }} />
    </div>
  )
}

function LockBtn({ locked, loading, onToggle }) {
  return (
    <button onClick={onToggle} disabled={loading} style={{
      padding: '5px 12px', borderRadius: 8, border: 'none',
      background: locked ? '#ef4444' : '#22c55e',
      color: '#fff', cursor: 'pointer', fontSize: 14, fontWeight: 700,
      flexShrink: 0,
    }}>
      {locked ? '🔒' : '🔓'}
    </button>
  )
}

function SensorBadge({ state, type }) {
  const { t } = useLang()
  if (type === 'door' || state.contact !== undefined) {
    const open = state.contact === false
    return (
      <span style={{
        fontSize: 11, padding: '3px 10px', borderRadius: 20, fontWeight: 700,
        background: open ? '#451a03' : '#14532d',
        color: open ? '#f59e0b' : '#22c55e',
      }}>
        {open ? t.door_open_badge : t.door_closed_badge}
      </span>
    )
  }
  if (type === 'motion' || state.occupancy !== undefined) {
    return (
      <span style={{
        fontSize: 11, padding: '3px 10px', borderRadius: 20, fontWeight: 700,
        background: state.occupancy ? '#451a03' : '#1e293b',
        color: state.occupancy ? '#f59e0b' : '#475569',
      }}>
        {state.occupancy ? t.motion_detected_badge : t.quiet_badge}
      </span>
    )
  }
  return null
}

function Pill({ icon, value, color }) {
  return (
    <div style={{
      background: '#0f172a', borderRadius: 8, padding: '4px 10px',
      fontSize: 12, color, display: 'flex', gap: 4, alignItems: 'center',
      flex: 1, justifyContent: 'center',
    }}>
      {icon} {value}
    </div>
  )
}

function BatteryBar({ pct }) {
  const color = pct > 50 ? '#22c55e' : pct > 20 ? '#f59e0b' : '#ef4444'
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <span style={{ fontSize: 10, color }}>🔋 {pct}%</span>
      <div style={{ flex: 1, height: 4, background: '#334155', borderRadius: 2, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 2, transition: 'width .3s' }} />
      </div>
    </div>
  )
}
