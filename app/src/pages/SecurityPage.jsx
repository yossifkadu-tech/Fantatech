import { useState, useEffect, useRef } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

const ALARM_MODE_IDS = ['disarmed', 'home', 'armed', 'night']
const ALARM_ICONS    = { disarmed: '🔓', home: '🏠', armed: '🔒', night: '🌙' }
const ALARM_COLORS   = { disarmed: '#22c55e', home: '#f59e0b', armed: '#ef4444', night: '#a78bfa' }
const ALARM_BG       = { disarmed: '#14532d', home: '#451a03', armed: '#450a0a', night: '#2e1065' }

const SEC_TYPES = ['motion', 'door', 'smoke', 'lock', 'camera', 'sensor']

/* ── helpers ── */
function deviceAlert(device, t) {
  const s = device.state || {}
  if (s.smoke)              return { level: 'critical', text: t.smoke_alert_banner, icon: '🔥', color: '#ef4444' }
  if (s.occupancy)          return { level: 'warn',     text: t.motion_alert_banner, icon: '👤', color: '#f59e0b' }
  if (s.contact === false)  return { level: 'info',     text: t.door_open_banner,   icon: '🚪', color: '#f59e0b' }
  return null
}

function secDevices(devices) {
  return devices.filter(d => SEC_TYPES.includes(d.type))
}

function fmtTime(ts, locale) {
  if (!ts) return ''
  const d = new Date(ts * 1000)
  return d.toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })
}

function fmtSecAction(h, t) {
  const a = (h.action || '').toLowerCase()
  const v = (h.value  || '').toUpperCase()
  if (a === 'toggle' && v === 'ON')           return t.hist_action_on
  if (a === 'toggle' && v === 'OFF')          return t.hist_action_off
  if (a === 'cmd')                             return t.hist_action_cmd
  if (a.includes('motion'))                    return t.hist_action_motion
  if (a.includes('smoke'))                     return t.hist_action_smoke
  if (a.includes('door') && (a.includes('open') || a.includes('פתח')))  return t.hist_action_door_open
  if (a.includes('door') && (a.includes('close') || a.includes('סגר'))) return t.hist_action_door_close
  if (a === 'lock'   || a === 'locked')        return t.hist_action_lock
  if (a === 'unlock' || a === 'unlocked')      return t.hist_action_unlock
  if (a.includes('arm') && !a.includes('dis')) return t.hist_action_armed
  if (a.includes('disarm'))                    return t.hist_action_disarmed
  return h.action
}

export default function SecurityPage({ devices = [], onReload }) {
  const { t, locale } = useLang()

  const ALARM_MODES = ALARM_MODE_IDS.map(id => ({
    id,
    label: t[id === 'disarmed' ? 'disarmed' : id === 'home' ? 'home_mode' : id === 'armed' ? 'armed' : 'night_mode'],
    icon:  ALARM_ICONS[id],
    color: ALARM_COLORS[id],
    bg:    ALARM_BG[id],
  }))

  const [alarmMode, setAlarmMode] = useState(
    () => localStorage.getItem('fantatech_alarm') || 'disarmed'
  )
  const [armCountdown, setArmCountdown] = useState(null)
  const ivRef = useRef(null)
  const [history, setHistory]   = useState([])
  const [histLoading, setHL]    = useState(false)
  const [lockLoading, setLL]    = useState({})

  const sec = secDevices(devices)
  const alerts = sec.map(d => ({ device: d, alert: deviceAlert(d, t) })).filter(x => x.alert)

  const currentMode = ALARM_MODES.find(m => m.id === alarmMode) || ALARM_MODES[0]

  /* load recent security history */
  useEffect(() => {
    setHL(true)
    api.get('/history?limit=50')
      .then(r => {
        const rows = (r.data || []).filter(h =>
          SEC_TYPES.some(t => h.device_type === t || h.action?.includes('smoke') ||
            h.action?.includes('motion') || h.action?.includes('door') ||
            h.action?.includes('lock'))
        )
        setHistory(rows.slice(0, 20))
      })
      .catch(() => {})
      .finally(() => setHL(false))
  }, [])

  /* arm with countdown */
  const armSystem = (mode) => {
    if (mode === alarmMode) return
    // cancel any existing countdown before starting a new one
    if (ivRef.current) { clearInterval(ivRef.current); ivRef.current = null }
    if (mode !== 'disarmed' && alarmMode === 'disarmed') {
      let count = 30
      setArmCountdown(count)
      ivRef.current = setInterval(() => {
        count--
        if (count <= 0) {
          clearInterval(ivRef.current)
          ivRef.current = null
          setArmCountdown(null)
          setAlarmMode(mode)
          localStorage.setItem('fantatech_alarm', mode)
        } else {
          setArmCountdown(count)
        }
      }, 1000)
    } else {
      setAlarmMode(mode)
      localStorage.setItem('fantatech_alarm', mode)
    }
  }

  const disarm = () => {
    if (ivRef.current) { clearInterval(ivRef.current); ivRef.current = null }
    setArmCountdown(null)
    setAlarmMode('disarmed')
    localStorage.setItem('fantatech_alarm', 'disarmed')
  }

  /* lock/unlock */
  const toggleLock = async (device) => {
    const locked = device.state?.state !== 'UNLOCKED'
    setLL(p => ({ ...p, [device.id]: true }))
    try {
      await api.post(`/devices/${device.id}/cmd`, {
        payload: { state: locked ? 'UNLOCK' : 'LOCK' }
      })
      onReload?.()
    } catch {}
    setLL(p => ({ ...p, [device.id]: false }))
  }

  /* group security devices */
  const locks   = sec.filter(d => d.type === 'lock')
  const motions = sec.filter(d => d.type === 'motion')
  const doors   = sec.filter(d => d.type === 'door')
  const smokes  = sec.filter(d => d.type === 'smoke')
  const cameras = sec.filter(d => d.type === 'camera')

  return (
    <div style={{ paddingBottom: 20 }}>

      {/* ── Alarm Panel ── */}
      <div style={{
        background: alarmMode === 'disarmed' ? '#1e293b' : currentMode.bg,
        border: `2px solid ${currentMode.color}`,
        borderRadius: 18, padding: 20, marginBottom: 16, textAlign: 'center',
        transition: 'all .4s',
        boxShadow: alarmMode !== 'disarmed' ? `0 0 30px ${currentMode.color}44` : 'none',
      }}>
        <div style={{ fontSize: 48, marginBottom: 6 }}>{currentMode.icon}</div>
        <div style={{ fontSize: 22, fontWeight: 700, color: currentMode.color }}>
          {armCountdown ? `${t.arming_in} ${armCountdown}${t.seconds_abbr}...` : currentMode.label}
        </div>
        <div style={{ fontSize: 12, color: '#94a3b8', marginBottom: 16 }}>{t.alarm_system}</div>

        {armCountdown ? (
          <button onClick={disarm} style={{
            padding: '10px 30px', borderRadius: 12, border: 'none',
            background: '#ef4444', color: '#fff', fontSize: 15, fontWeight: 700, cursor: 'pointer',
          }}>{t.cancel_arm} ({armCountdown})</button>
        ) : (
          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', flexWrap: 'wrap' }}>
            {ALARM_MODES.map(m => (
              <button key={m.id} onClick={() => m.id === 'disarmed' ? disarm() : armSystem(m.id)} style={{
                padding: '8px 14px', borderRadius: 10, border: `1px solid ${alarmMode === m.id ? m.color : '#334155'}`,
                background: alarmMode === m.id ? m.bg : '#1e293b',
                color: alarmMode === m.id ? m.color : '#64748b',
                fontSize: 12, fontWeight: 600, cursor: 'pointer', transition: 'all .2s',
              }}>
                {m.icon} {m.label}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* ── Active Alerts ── */}
      {alerts.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="⚠️" title={t.active_alerts} count={alerts.length} countColor="#ef4444" />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {alerts.map(({ device, alert }) => (
              <div key={device.id} style={{
                background: alert.color + '18',
                border: `1px solid ${alert.color}`,
                borderRadius: 12, padding: '10px 14px',
                display: 'flex', alignItems: 'center', gap: 10,
                animation: alert.level === 'critical' ? 'pulse 1.2s infinite' : 'none',
              }}>
                <style>{`@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.6} }`}</style>
                <span style={{ fontSize: 22 }}>{alert.icon}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 700, fontSize: 13, color: alert.color }}>{alert.text}</div>
                  <div style={{ fontSize: 11, color: '#94a3b8' }}>{device.name}</div>
                </div>
                <div style={{ fontSize: 10, color: '#475569' }}>{fmtTime(device.state?.last_seen, locale)}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Summary stats ── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 16 }}>
        <StatCard icon="💡" label={t.security_devices} value={sec.length} color="#38bdf8" />
        <StatCard icon="📡" label={t.connected_devices} value={sec.filter(d => d.online).length} color="#22c55e" />
        <StatCard icon="⚠️" label={t.alerts_count}      value={alerts.length} color={alerts.length ? '#ef4444' : '#475569'} />
      </div>

      {/* ── Locks ── */}
      {locks.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="🔒" title={t.locks_section} count={locks.length} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            {locks.map(d => {
              const locked = d.state?.state !== 'UNLOCKED'
              return (
                <div key={d.id} style={{
                  background: locked ? '#1c0a00' : '#0f2818',
                  border: `1px solid ${locked ? '#ef4444' : '#22c55e'}`,
                  borderRadius: 12, padding: 12,
                  opacity: d.online ? 1 : 0.5,
                }}>
                  <div style={{ fontSize: 22, marginBottom: 4 }}>{locked ? '🔒' : '🔓'}</div>
                  <div style={{ fontSize: 12, fontWeight: 600, color: '#f1f5f9', marginBottom: 8 }}>{d.name}</div>
                  <button onClick={() => toggleLock(d)}
                    disabled={!d.online || lockLoading[d.id]}
                    style={{
                      width: '100%', padding: '6px 0', borderRadius: 8, border: 'none',
                      background: locked ? '#ef4444' : '#22c55e',
                      color: '#fff', fontSize: 12, fontWeight: 700, cursor: d.online ? 'pointer' : 'not-allowed',
                    }}>
                    {lockLoading[d.id] ? '...' : locked ? t.unlock_btn : t.lock_btn}
                  </button>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* ── Motion sensors ── */}
      {motions.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="👤" title={t.motion_sensors} count={motions.length} />
          <SensorGrid sensors={motions} renderBadge={d => (
            <span style={{
              fontSize: 11, padding: '2px 8px', borderRadius: 20, fontWeight: 700,
              background: d.state?.occupancy ? '#451a03' : '#1e293b',
              color: d.state?.occupancy ? '#f59e0b' : '#475569',
            }}>
              {d.state?.occupancy ? t.motion_detected_badge : t.quiet_badge}
            </span>
          )} />
        </div>
      )}

      {/* ── Door / window sensors ── */}
      {doors.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="🚪" title={t.door_sensors} count={doors.length} />
          <SensorGrid sensors={doors} renderBadge={d => {
            const open = d.state?.contact === false
            return (
              <span style={{
                fontSize: 11, padding: '2px 8px', borderRadius: 20, fontWeight: 700,
                background: open ? '#451a03' : '#14532d',
                color: open ? '#f59e0b' : '#22c55e',
              }}>
                {open ? t.door_open_badge : t.door_closed_badge}
              </span>
            )
          }} />
        </div>
      )}

      {/* ── Smoke detectors ── */}
      {smokes.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="🔥" title={t.smoke_detectors} count={smokes.length} />
          <SensorGrid sensors={smokes} renderBadge={d => (
            <span style={{
              fontSize: 11, padding: '2px 8px', borderRadius: 20, fontWeight: 700,
              background: d.state?.smoke ? '#450a0a' : '#14532d',
              color: d.state?.smoke ? '#ef4444' : '#22c55e',
            }}>
              {d.state?.smoke ? t.smoke_alert_badge : t.smoke_ok_badge}
            </span>
          )} />
        </div>
      )}

      {/* ── Cameras ── */}
      {cameras.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="📷" title={t.cameras_section} count={cameras.length} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            {cameras.map(d => (
              <div key={d.id} style={{
                background: '#1e293b', border: `1px solid ${d.online ? '#334155' : '#ef444444'}`,
                borderRadius: 12, padding: 12, textAlign: 'center',
                opacity: d.online ? 1 : 0.5,
              }}>
                <div style={{ fontSize: 32 }}>📷</div>
                <div style={{ fontSize: 11, fontWeight: 600, color: '#f1f5f9', margin: '6px 0 4px' }}>{d.name}</div>
                <div style={{ fontSize: 10, color: d.online ? '#22c55e' : '#ef4444' }}>
                  {d.online ? t.connected : t.offline_badge}
                </div>
                {d.state?.stream_url && (
                  <a href={d.state.stream_url} target="_blank" rel="noreferrer"
                    style={{ fontSize: 10, color: '#38bdf8', display: 'block', marginTop: 4 }}>
                    {t.view_stream}
                  </a>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Security History ── */}
      <div>
        <SectionTitle icon="📋" title={t.security_history_title} />
        {histLoading ? (
          <div style={{ textAlign: 'center', padding: 20, color: '#475569', fontSize: 12 }}>{t.loading}</div>
        ) : history.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 20, color: '#475569', fontSize: 12 }}>
            {t.no_recent_events}
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            {history.map((h, i) => (
              <div key={i} style={{
                background: '#1e293b', borderRadius: 8, padding: '8px 12px',
                display: 'flex', alignItems: 'center', gap: 10,
              }}>
                <span style={{ fontSize: 16 }}>
                  {h.device_type === 'smoke' ? '🔥' :
                   h.device_type === 'motion' ? '👤' :
                   h.device_type === 'door' ? '🚪' :
                   h.device_type === 'lock' ? '🔒' :
                   h.device_type === 'camera' ? '📷' : '🔔'}
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12, color: '#f1f5f9', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {h.device_name || h.device_id}
                  </div>
                  <div style={{ fontSize: 10, color: '#64748b' }}>{fmtSecAction(h, t)}</div>
                </div>
                <div style={{ fontSize: 10, color: '#475569', whiteSpace: 'nowrap', flexShrink: 0 }}>
                  {fmtTime(h.ts, locale)}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Empty state */}
      {sec.length === 0 && (
        <div style={{ textAlign: 'center', padding: '40px 20px', color: '#475569' }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>🔐</div>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 6 }}>{t.no_security_devices}</div>
          <div style={{ fontSize: 12 }}>{t.no_security_hint}</div>
        </div>
      )}
    </div>
  )
}

/* ── Sub-components ── */

function SectionTitle({ icon, title, count, countColor }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
      <span style={{ fontSize: 16 }}>{icon}</span>
      <span style={{ fontSize: 13, fontWeight: 700, color: '#f1f5f9' }}>{title}</span>
      {count !== undefined && (
        <span style={{
          fontSize: 10, fontWeight: 700, padding: '2px 7px', borderRadius: 10,
          background: '#1e293b', color: countColor || '#64748b',
          border: `1px solid ${countColor || '#334155'}`,
        }}>{count}</span>
      )}
    </div>
  )
}

function StatCard({ icon, label, value, color }) {
  return (
    <div style={{
      background: '#1e293b', borderRadius: 12, padding: '12px 8px', textAlign: 'center',
      border: '1px solid #334155',
    }}>
      <div style={{ fontSize: 20 }}>{icon}</div>
      <div style={{ fontSize: 20, fontWeight: 700, color, margin: '4px 0 2px' }}>{value}</div>
      <div style={{ fontSize: 9, color: '#64748b' }}>{label}</div>
    </div>
  )
}

function SensorGrid({ sensors, renderBadge }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {sensors.map(d => (
        <div key={d.id} style={{
          background: '#1e293b', border: '1px solid #334155', borderRadius: 10,
          padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 10,
          opacity: d.online ? 1 : 0.5,
        }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#f1f5f9', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {d.name}
            </div>
            {d.room_name && (
              <div style={{ fontSize: 10, color: '#475569' }}>{d.room_name}</div>
            )}
          </div>
          {!d.online && <span style={{ fontSize: 10, color: '#ef4444' }}>●</span>}
          {renderBadge(d)}
        </div>
      ))}
    </div>
  )
}
