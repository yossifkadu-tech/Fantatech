import { useState, useEffect } from 'react'
import { api, getHubUrl } from '../hooks/useHub'
import DeviceCard from '../components/DeviceCard'
import { useLang } from '../context/LangContext'
import { useScale } from '../context/ScaleContext'
import RotatingAdBanner from '../components/RotatingAdBanner'

/* ── Greeting by time of day ─────────────────────────────────────────── */
function greeting(t) {
  const h = new Date().getHours()
  if (h < 12) return t.greet_morning  ?? 'Good morning'
  if (h < 17) return t.greet_afternoon ?? 'Good afternoon'
  return           t.greet_evening   ?? 'Good evening'
}

function useClock() {
  const [now, setNow] = useState(new Date())
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(id)
  }, [])
  return now
}

/* ── Mini progress arc (SVG) ─────────────────────────────────────────── */
function Arc({ pct, color, size = 52 }) {
  const r   = (size - 8) / 2
  const circ = 2 * Math.PI * r
  const dash = circ * Math.min(1, Math.max(0, pct))
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#1e3a5f" strokeWidth={5} />
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={5}
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"
        style={{ transition: 'stroke-dasharray 0.6s ease' }} />
    </svg>
  )
}

/* ── Sparkline (SVG mini chart) ──────────────────────────────────────── */
function Sparkline({ data, color, w = 64, h = 24 }) {
  if (!data || data.length < 2) return null
  const min = Math.min(...data)
  const max = Math.max(...data)
  const rng = max - min || 1
  const pts = data.map((v, i) => {
    const x = (i / (data.length - 1)) * w
    const y = h - ((v - min) / rng) * (h - 4) - 2
    return `${x},${y}`
  }).join(' ')
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      <polyline points={pts} fill="none" stroke={color} strokeWidth={1.5}
        strokeLinecap="round" strokeLinejoin="round" opacity={0.85} />
    </svg>
  )
}

/* ── Section header ──────────────────────────────────────────────────── */
function SectionHeader({ title, action, onAction }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
      <h3 style={{ margin: 0, color: '#e2e8f0', fontSize: 14, fontWeight: 700 }}>{title}</h3>
      {action && (
        <button onClick={onAction} style={{
          background: 'none', border: 'none', color: '#38bdf8',
          fontSize: 12, cursor: 'pointer', padding: '2px 6px',
        }}>{action} →</button>
      )}
    </div>
  )
}

/* ─────────────────────────────────────────────────────────────────────── */
export default function Dashboard({ devices, wsConnected, onNavigate, onReload }) {
  const { t, locale, rtl } = useLang()
  const { phone, tablet } = useScale()
  const now = useClock()

  const [history, setHistory]       = useState([])
  const [rulesCount, setRulesCount] = useState(null)
  const [rooms, setRooms]           = useState([])
  const [showBanner, setShowBanner] = useState(false)
  const [actHistory, setActHistory] = useState([])   // last 7 action counts for sparkline

  useEffect(() => {
    api.get('/history/?limit=7').then(r => {
      setHistory(r.data)
      // Build a simple sparkline: count events per hour bucket
      const buckets = Array(7).fill(0)
      r.data.forEach((h, i) => { buckets[i] = 1 })
      setActHistory(buckets.reverse())
    }).catch(() => {})
    api.get('/rules/').then(r => setRulesCount(r.data.length)).catch(() => setRulesCount(0))
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
  }, [])

  useEffect(() => {
    if (wsConnected) { setShowBanner(false); return }
    const timer = setTimeout(() => setShowBanner(true), 5000)
    return () => clearTimeout(timer)
  }, [wsConnected])

  // User info
  const user     = (() => { try { return JSON.parse(localStorage.getItem('fantatech_user') || '{}') } catch { return {} } })()
  const userName = user.name || user.username || ''

  // Device stats
  const online   = devices.filter(d => d.online).length
  const offline  = devices.length - online
  const active   = devices.filter(d => d.online && d.state?.state === 'ON').length
  const pinned   = devices.filter(d => d.pinned && d.online)
  const featured = pinned.length ? pinned : devices.filter(d => d.online && d.state?.state === 'ON').slice(0, 6)

  // Temperature sensor (first sensor device that has temperature)
  const tempDevice = devices.find(d => d.type === 'sensor' && d.state?.temperature != null)
  const tempVal    = tempDevice?.state?.temperature

  // Room map
  const roomMap = rooms.reduce((m, r) => { m[r.id] = r; return m }, {})

  // Time + date strings
  const timeStr = now.toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })
  const dateStr = now.toLocaleDateString(locale, { weekday: 'long', day: 'numeric', month: 'long' })

  /* ── Widget definitions ─────────────────────────────────────────────── */
  const widgets = [
    {
      id: 'devices',
      icon: '💡',
      label: t.devices_count ?? 'Devices',
      value: devices.length,
      sub: `${online} ${t.connected_count ?? 'online'}`,
      color: '#38bdf8',
      pct: devices.length ? online / devices.length : 0,
      spark: null,
      tab: 'devices',
    },
    {
      id: 'active',
      icon: '⚡',
      label: t.active_now ?? 'Active Now',
      value: active,
      sub: `${offline} ${t.offline ?? 'offline'}`,
      color: '#22c55e',
      pct: devices.length ? active / devices.length : 0,
      spark: null,
      tab: 'devices',
    },
    {
      id: 'rooms',
      icon: '🏡',
      label: t.rooms_count ?? 'Rooms',
      value: rooms.length,
      sub: rooms.slice(0, 2).map(r => r.name).join(', ') || '—',
      color: '#a78bfa',
      pct: rooms.length ? Math.min(1, rooms.length / 10) : 0,
      spark: null,
      tab: 'rooms',
    },
    {
      id: 'automations',
      icon: '🤖',
      label: t.automations_count ?? 'Automations',
      value: rulesCount ?? '…',
      sub: t.tap_to_manage ?? 'Tap to manage',
      color: '#fb923c',
      pct: rulesCount != null ? Math.min(1, rulesCount / 10) : 0,
      spark: actHistory,
      tab: 'automations',
    },
  ]

  const cols = phone ? 2 : 4

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>

      {/* ── Hero ──────────────────────────────────────────────────────────── */}
      <div style={{
        background: 'linear-gradient(135deg, #0c1a2e 0%, #1e3a5f 50%, #0f2744 100%)',
        border: '1px solid #1e3a5f',
        borderRadius: 20,
        padding: phone ? '18px 16px' : '22px 24px',
        marginBottom: 16,
        position: 'relative',
        overflow: 'hidden',
      }}>
        {/* Background glow */}
        <div style={{
          position: 'absolute', top: -40, right: rtl ? 'auto' : -40, left: rtl ? -40 : 'auto',
          width: 160, height: 160,
          background: 'radial-gradient(circle, rgba(56,189,248,0.12) 0%, transparent 70%)',
          pointerEvents: 'none',
        }} />

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12 }}>
          {/* Left: greeting + status */}
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, color: '#64748b', fontWeight: 600, marginBottom: 2 }}>
              {greeting(t)}{userName ? `, ${userName}` : ''} 👋
            </div>
            <div style={{ fontSize: phone ? 22 : 26, fontWeight: 900, color: '#f1f5f9', letterSpacing: '-0.5px', lineHeight: 1.1 }}>
              {timeStr}
            </div>
            <div style={{ fontSize: 11, color: '#64748b', marginTop: 3, marginBottom: 14 }}>
              {dateStr}
            </div>

            {/* Home status pills */}
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <span style={{
                background: online > 0 ? 'rgba(34,197,94,0.15)' : 'rgba(100,116,139,0.15)',
                border: `1px solid ${online > 0 ? '#16a34a' : '#475569'}`,
                borderRadius: 20, padding: '3px 10px',
                fontSize: 11, fontWeight: 700,
                color: online > 0 ? '#4ade80' : '#64748b',
              }}>
                ✦ {online} {t.connected_count ?? 'online'}
              </span>
              {active > 0 && (
                <span style={{
                  background: 'rgba(56,189,248,0.15)',
                  border: '1px solid #0ea5e9',
                  borderRadius: 20, padding: '3px 10px',
                  fontSize: 11, fontWeight: 700, color: '#38bdf8',
                }}>
                  ⚡ {active} {t.active_now ?? 'active'}
                </span>
              )}
              {offline > 0 && (
                <span style={{
                  background: 'rgba(239,68,68,0.12)',
                  border: '1px solid #dc2626',
                  borderRadius: 20, padding: '3px 10px',
                  fontSize: 11, fontWeight: 700, color: '#f87171',
                }}>
                  ✕ {offline} {t.offline ?? 'offline'}
                </span>
              )}
            </div>
          </div>

          {/* Right: temperature or hub status */}
          <div style={{ textAlign: 'center', flexShrink: 0 }}>
            {tempVal != null ? (
              <div style={{
                background: 'rgba(15,23,42,0.6)', border: '1px solid #334155',
                borderRadius: 14, padding: '10px 14px', minWidth: 70,
              }}>
                <div style={{ fontSize: 22 }}>🌡️</div>
                <div style={{ fontSize: 20, fontWeight: 900, color: '#fb923c', lineHeight: 1 }}>
                  {tempVal}°
                </div>
                <div style={{ fontSize: 9, color: '#64748b', marginTop: 2 }}>
                  {tempDevice.name}
                </div>
              </div>
            ) : (
              <div style={{
                background: wsConnected ? 'rgba(34,197,94,0.1)' : 'rgba(100,116,139,0.1)',
                border: `1px solid ${wsConnected ? '#16a34a' : '#334155'}`,
                borderRadius: 14, padding: '10px 14px', minWidth: 70,
              }}>
                <div style={{ fontSize: 22 }}>{wsConnected ? '🏠' : '📡'}</div>
                <div style={{ fontSize: 10, fontWeight: 700, color: wsConnected ? '#4ade80' : '#64748b', marginTop: 4 }}>
                  {wsConnected ? (t.hub_connected ?? 'Connected') : (t.hub_not_connected ?? 'Offline')}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── Hub disconnected banner ───────────────────────────────────────── */}
      {showBanner && !wsConnected && (
        <div style={{
          background: '#1c0f00', border: '1px solid #f59e0b',
          borderRadius: 14, padding: '12px 14px', marginBottom: 14,
          fontSize: 13, color: '#fcd34d',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontSize: 18 }}>⚠️</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700 }}>{t.hub_not_connected}</div>
              {getHubUrl() && (
                <div style={{ fontSize: 11, color: '#92400e', marginTop: 2, direction: 'ltr' }}>{getHubUrl()}</div>
              )}
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => onNavigate('settings')} style={{
              flex: 1, padding: '8px 0', borderRadius: 8, border: 'none',
              background: '#78350f', color: '#fcd34d', cursor: 'pointer', fontWeight: 700, fontSize: 12,
            }}>{t.hub_settings}</button>
            <button onClick={() => onNavigate('network')} style={{
              flex: 1, padding: '8px 0', borderRadius: 8, border: 'none',
              background: '#1e3a5f', color: '#38bdf8', cursor: 'pointer', fontWeight: 700, fontSize: 12,
            }}>{t.network_diag}</button>
          </div>
        </div>
      )}

      {/* ── Stat widgets ──────────────────────────────────────────────────── */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${cols}, 1fr)`,
        gap: 10, marginBottom: 18,
      }}>
        {widgets.map(w => (
          <div key={w.id} onClick={() => onNavigate(w.tab)}
            style={{
              background: 'linear-gradient(145deg, #1a2a3d, #1e293b)',
              border: '1px solid #334155',
              borderRadius: 16, padding: '14px 12px',
              cursor: 'pointer', position: 'relative', overflow: 'hidden',
              transition: 'transform 0.15s, box-shadow 0.15s',
            }}
            onMouseDown={e  => { e.currentTarget.style.transform = 'scale(0.97)' }}
            onMouseUp={e    => { e.currentTarget.style.transform = 'scale(1)'    }}
            onTouchEnd={e   => { e.currentTarget.style.transform = 'scale(1)'    }}
          >
            {/* Colored accent top bar */}
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0, height: 3,
              background: `linear-gradient(90deg, ${w.color}, transparent)`,
              borderRadius: '16px 16px 0 0',
            }} />

            {/* Icon + arc */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
              <span style={{ fontSize: phone ? 22 : 24 }}>{w.icon}</span>
              <Arc pct={w.pct} color={w.color} size={phone ? 42 : 48} />
            </div>

            {/* Value */}
            <div style={{
              fontSize: phone ? 24 : 28, fontWeight: 900,
              color: w.color, lineHeight: 1, marginBottom: 2,
            }}>
              {w.value}
            </div>

            {/* Label */}
            <div style={{ fontSize: 10, fontWeight: 700, color: '#94a3b8', marginBottom: 4 }}>
              {w.label}
            </div>

            {/* Sub or sparkline */}
            {w.spark && w.spark.some(v => v > 0) ? (
              <Sparkline data={w.spark} color={w.color} w={phone ? 60 : 72} h={20} />
            ) : (
              <div style={{
                fontSize: 9, color: '#475569',
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
              }}>
                {w.sub}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* ── Quick actions row ─────────────────────────────────────────────── */}
      <div style={{
        display: 'flex', gap: 8, marginBottom: 18,
        overflowX: 'auto', scrollbarWidth: 'none',
      }}>
        {[
          { label: t.devices ?? 'Devices',         icon: '💡', tab: 'devices'     },
          { label: t.scenes_title ?? 'Scenes',      icon: '🎭', tab: 'scenes'      },
          { label: t.security ?? 'Security',        icon: '🔒', tab: 'security'    },
          { label: t.cameras_title ?? 'Cameras',    icon: '📷', tab: 'cameras'     },
          { label: t.gps_nav ?? 'GPS',              icon: '📍', tab: 'gps'         },
          { label: t.settings ?? 'Settings',        icon: '⚙️', tab: 'settings'    },
        ].map(q => (
          <button key={q.tab} onClick={() => onNavigate(q.tab)} style={{
            flexShrink: 0,
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            background: '#1e293b', border: '1px solid #334155',
            borderRadius: 14, padding: '10px 14px',
            cursor: 'pointer', color: '#94a3b8',
            WebkitTapHighlightColor: 'transparent',
            transition: 'background 0.15s',
          }}
            onMouseEnter={e => e.currentTarget.style.background = '#263347'}
            onMouseLeave={e => e.currentTarget.style.background = '#1e293b'}
          >
            <span style={{ fontSize: 20 }}>{q.icon}</span>
            <span style={{ fontSize: 9, fontWeight: 600, whiteSpace: 'nowrap' }}>{q.label}</span>
          </button>
        ))}
      </div>

      {/* ── Rotating ad card ─────────────────────────────────────────────── */}
      <div style={{ marginBottom: 18 }}>
        <RotatingAdBanner variant="card" />
      </div>

      {/* ── Featured devices ──────────────────────────────────────────────── */}
      <SectionHeader
        title={pinned.length ? (t.pinned_devices ?? 'Pinned') : (t.active_now ?? 'Active Now')}
        action={featured.length > 0 ? (t.turn_all_off ?? 'Turn all off') : null}
        onAction={async () => {
          await Promise.allSettled(featured.map(d =>
            d.type === 'ac'
              ? api.post(`/ac/control/${d.id}`, { state: 'OFF' })
              : api.post(`/devices/${d.id}/cmd`, { payload: { state: 'OFF' } })
          ))
          onReload()
        }}
      />

      {featured.length === 0 ? (
        <div style={{
          background: '#1e293b', border: '1px solid #334155',
          borderRadius: 16, padding: 36,
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
          textAlign: 'center', marginBottom: 18,
        }}>
          <span style={{ fontSize: 36 }}>🌙</span>
          <span style={{ color: '#475569', fontSize: 14 }}>{t.no_active_devices ?? 'No active devices'}</span>
          <button onClick={() => onNavigate('devices')} style={{
            padding: '8px 20px', borderRadius: 10, border: 'none',
            background: '#38bdf8', color: '#0f172a', cursor: 'pointer', fontWeight: 700, fontSize: 13,
          }}>
            {t.go_to_devices ?? 'Go to Devices'}
          </button>
        </div>
      ) : (
        <div style={{
          display: 'grid',
          gridTemplateColumns: `repeat(auto-fill, minmax(${phone ? 160 : 190}px, 1fr))`,
          gap: 10, marginBottom: 20,
        }}>
          {featured.map(d => {
            const room = d.room ? roomMap[d.room] : null
            return (
              <DeviceCard key={d.id} device={d} onUpdate={onReload}
                roomName={room ? `${room.icon} ${room.name}` : undefined} />
            )
          })}
        </div>
      )}

      {/* ── Recent activity ───────────────────────────────────────────────── */}
      {history.length > 0 && (<>
        <SectionHeader
          title={t.recent_activity ?? 'Recent Activity'}
          action={t.see_all ?? 'See all'}
          onAction={() => onNavigate('history')}
        />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 20 }}>
          {history.map((h, i) => {
            const actionIcon = h.action === 'toggle' && h.value === 'ON'  ? '💡'
                             : h.action === 'toggle' && h.value === 'OFF' ? '🌙'
                             : h.action === 'cmd' ? '🎛️' : '⚡'
            const actionText = h.action === 'toggle' && h.value === 'ON'  ? t.turned_on
                             : h.action === 'toggle' && h.value === 'OFF' ? t.turned_off
                             : h.action === 'cmd' ? `${t.command_sent}: ${h.value || ''}` : h.action
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                background: '#1e293b', border: '1px solid #334155',
                borderRadius: 12, padding: '10px 14px',
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 10,
                  background: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 16, flexShrink: 0,
                }}>
                  {actionIcon}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {h.device_name}
                  </div>
                  <div style={{ fontSize: 11, color: '#64748b' }}>{actionText}</div>
                </div>
                <div style={{ fontSize: 11, color: '#475569', flexShrink: 0 }}>
                  {new Date(h.ts * 1000).toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })}
                </div>
              </div>
            )
          })}
        </div>
      </>)}

    </div>
  )
}
