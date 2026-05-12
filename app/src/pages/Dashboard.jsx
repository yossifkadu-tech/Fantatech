import { useState, useEffect } from 'react'
import { api, getHubUrl } from '../hooks/useHub'
import DeviceCard from '../components/DeviceCard'
import PromoCarousel from '../components/PromoCarousel'
import SponsoredBanner from '../components/SponsoredBanner'
import { useLang } from '../context/LangContext'

export default function Dashboard({ devices, wsConnected, onNavigate, onReload, tablet, landscape }) {
  const { t, locale } = useLang()
  const [history, setHistory]         = useState([])
  const [rulesCount, setRulesCount]   = useState('…')
  const [rooms, setRooms]             = useState([])
  const [showBanner, setShowBanner]   = useState(false)

  const online = devices.filter(d => d.online).length

  useEffect(() => {
    api.get('/history/?limit=6').then(r => setHistory(r.data)).catch(() => {})
    api.get('/rules/').then(r => setRulesCount(r.data.length)).catch(() => setRulesCount('—'))
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
  }, [])

  // Delay banner so it doesn't flash on startup while WS is connecting
  useEffect(() => {
    if (wsConnected) { setShowBanner(false); return }
    const t = setTimeout(() => setShowBanner(true), 5000)
    return () => clearTimeout(t)
  }, [wsConnected])

  const roomMap = rooms.reduce((m, r) => { m[r.id] = r; return m }, {})

  const stats = [
    { label: t.devices_count,     value: devices.length, icon: '💡', color: '#38bdf8', tab: 'devices' },
    { label: t.connected_count,   value: online,          icon: '✅', color: '#22c55e', tab: 'devices' },
    { label: t.rooms_count,       value: rooms.length,    icon: '🏡', color: '#a78bfa', tab: 'rooms'   },
    { label: t.automations_count, value: rulesCount,      icon: '⚙️', color: '#fb923c', tab: 'automations' },
  ]

  const pinned   = devices.filter(d => d.pinned && d.online)
  const active   = devices.filter(d => d.online && d.state?.state === 'ON')
  const featured = pinned.length ? pinned : active.slice(0, 6)

  return (
    <div>
      {/* Stats grid — always 4 tiles side by side */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 24 }}>
        {stats.map(s => (
          <div key={s.label} onClick={() => onNavigate(s.tab)}
            style={{ ...card, cursor: 'pointer', transition: 'opacity .15s' }}
            onMouseDown={e => e.currentTarget.style.opacity = '.7'}
            onMouseUp={e => e.currentTarget.style.opacity = '1'}
            onTouchEnd={e => e.currentTarget.style.opacity = '1'}>
            <span style={{ fontSize: 22 }}>{s.icon}</span>
            <div>
              <div style={{ fontSize: 22, fontWeight: 800, color: s.color, lineHeight: 1 }}>{s.value}</div>
              <div style={{ fontSize: 12, color: '#64748b', marginTop: 2 }}>{s.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Hub connection status — shown only after 5 s to avoid startup flash */}
      {showBanner && !wsConnected && (
        <div style={{
          background: '#1c0f00', border: '1px solid #f59e0b', borderRadius: 12,
          padding: '12px 14px', marginBottom: 16, fontSize: 13, color: '#fcd34d',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontSize: 18 }}>⚠️</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700 }}>{t.hub_not_connected}</div>
              {getHubUrl() && (
                <div style={{ fontSize: 11, color: '#92400e', marginTop: 2, direction: 'ltr' }}>
                  {getHubUrl()}
                </div>
              )}
            </div>
          </div>
          <div style={{ fontSize: 11, color: '#a16207', marginBottom: 10, lineHeight: 1.7 }}>
            {t.hub_banner_hint}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => onNavigate('settings')} style={{
              flex: 1, padding: '8px 0', borderRadius: 8, border: 'none',
              background: '#78350f', color: '#fcd34d', cursor: 'pointer',
              fontWeight: 700, fontSize: 12,
            }}>
              {t.hub_settings}
            </button>
            <button onClick={() => onNavigate('network')} style={{
              flex: 1, padding: '8px 0', borderRadius: 8, border: 'none',
              background: '#1e3a5f', color: '#38bdf8', cursor: 'pointer',
              fontWeight: 700, fontSize: 12,
            }}>
              {t.network_diag}
            </button>
          </div>
        </div>
      )}

      {/* Featured devices */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <h3 style={{ margin: 0, color: '#e2e8f0', fontSize: 15 }}>
          {pinned.length ? t.pinned_devices : t.active_now}
        </h3>
        {featured.length > 0 && (
          <button onClick={async () => {
            await Promise.allSettled(featured.map(d =>
              d.type === 'ac'
                ? api.post(`/ac/control/${d.id}`, { state: 'OFF' })
                : api.post(`/devices/${d.id}/cmd`, { payload: { state: 'OFF' } })
            ))
            onReload()
          }} style={btn('#ef4444')}>{t.turn_all_off}</button>
        )}
      </div>

      {featured.length === 0 ? (
        <div style={{ ...card, justifyContent: 'center', flexDirection: 'column', gap: 10, padding: 36, textAlign: 'center' }}>
          <span style={{ fontSize: 40 }}>🌙</span>
          <span style={{ color: '#475569', fontSize: 14 }}>{t.no_active_devices}</span>
          <button onClick={() => onNavigate('devices')} style={btn('#38bdf8', '#0f172a')}>
            {t.go_to_devices}
          </button>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(210px, 1fr))', gap: 10, marginBottom: 24 }}>
          {featured.map(d => {
            const room = d.room ? roomMap[d.room] : null
            return (
              <DeviceCard key={d.id} device={d} onUpdate={onReload}
                roomName={room ? `${room.icon} ${room.name}` : undefined} />
            )
          })}
        </div>
      )}

      {/* Sponsored / paid ads corner — shown first */}
      <SponsoredBanner />

      {/* Promo carousel below ads */}
      <PromoCarousel />

      {/* Recent history */}
      {history.length > 0 && (
        <>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <h3 style={{ margin: 0, color: '#e2e8f0', fontSize: 15 }}>{t.recent_activity}</h3>
            <button onClick={() => onNavigate('history')}
              style={{ ...btn('#1e293b', '#94a3b8'), fontSize: 11, padding: '4px 10px' }}>
              {t.see_all}
            </button>
          </div>
          {history.map((h, i) => (
            <div key={i} style={{ ...card, marginBottom: 6, padding: '10px 14px' }}>
              <span style={{ fontSize: 16 }}>
                {h.action === 'toggle' && h.value === 'ON'  ? '💡'
                : h.action === 'toggle' && h.value === 'OFF' ? '🌙'
                : h.action === 'cmd' ? '🎛️' : '⚡'}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {h.device_name}
                </div>
                <div style={{ fontSize: 11, color: '#64748b' }}>
                  {h.action === 'toggle' && h.value === 'ON'  ? t.turned_on
                  : h.action === 'toggle' && h.value === 'OFF' ? t.turned_off
                  : h.action === 'cmd' ? `${t.command_sent}: ${h.value || ''}`
                  : h.action}
                </div>
              </div>
              <div style={{ fontSize: 11, color: '#475569', flexShrink: 0 }}>
                {new Date(h.ts * 1000).toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })}
              </div>
            </div>
          ))}
        </>
      )}
    </div>
  )
}

const card = {
  display: 'flex', alignItems: 'center', gap: 12,
  background: '#1e293b', border: '1px solid #334155',
  borderRadius: 12, padding: '14px 16px',
}
const btn = (bg, color = '#fff') => ({
  padding: '6px 14px', borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
