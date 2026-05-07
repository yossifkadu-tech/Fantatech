import { useState, useEffect, useCallback } from 'react'
import { useDevices, useWebSocket, api, getHubUrl } from './hooks/useHub'
import { LangProvider, useLang } from './context/LangContext'
import Dashboard from './pages/Dashboard'
import DevicesPage from './pages/DevicesPage'
import AutomationsPage from './pages/AutomationsPage'
import HistoryPage from './pages/HistoryPage'
import NotificationsPage from './pages/NotificationsPage'
import RoomsPage from './pages/RoomsPage'
import NetworkPage from './pages/NetworkPage'
import SettingsPage from './pages/SettingsPage'
import HubSetup from './pages/HubSetup'
import SecurityPage from './pages/SecurityPage'
import ScenesPage from './pages/ScenesPage'
import CamerasPage from './pages/CamerasPage'
import GeminiAssistant from './components/GeminiAssistant'

const APP_VERSION = '1.9.0'

function AppInner() {
  const { t, lang, rtl } = useLang()
  const [tab, setTab]           = useState('dashboard')
  const [hubVersion, setHubVersion] = useState(null)
  const [hubReady, setHubReady] = useState(null)   // null=checking, true, false
  const [tablet]                = useState(() => window.innerWidth >= 600)
  const [unreadNotifs, setUnreadNotifs] = useState(0)
  const { devices, loading, reload, updateDeviceState, setOnline } = useDevices()

  const onDeviceState  = useCallback(d => updateDeviceState(d.id, d.state), [updateDeviceState])
  const onDeviceOnline = useCallback(d => setOnline(d.id, d.online), [setOnline])

  // Handle incoming notification pushed over WS
  const onWsNotification = useCallback((n) => {
    setUnreadNotifs(c => c + 1)
    // Dispatch custom event so NotificationsPage can reload
    window.dispatchEvent(new Event('fantatech_notification'))
    // Browser push for critical alerts
    if (n?.type === 'critical' && Notification?.permission === 'granted') {
      try {
        new Notification(`🔴 ${n.title || 'Critical Alert'}`, {
          body: n.message || '',
          icon: '/icons/icon-192x192.png',
        })
      } catch {}
    }
  }, [])

  const wsConnected = useWebSocket(onDeviceState, onDeviceOnline, null, onWsNotification)

  // Check hub reachability on startup — /ping is NOT under /api prefix
  useEffect(() => {
    const url = getHubUrl()
    import('axios').then(({ default: axios }) => {
      axios.get(`${url}/ping`, { timeout: 4000 })
        .then(() => setHubReady(true))
        .catch(() => setHubReady(false))
    })
  }, [])

  // Retry ping every 12 s while hub is not ready (e.g. Hub started after the app)
  useEffect(() => {
    if (hubReady === true || import.meta.env.VITE_HUB_URL) return
    const id = setInterval(() => {
      const url = getHubUrl()
      if (!url) return
      import('axios').then(({ default: axios }) => {
        axios.get(`${url}/ping`, { timeout: 3000 })
          .then(() => { setHubReady(true); reload() })
          .catch(() => {})
      })
    }, 12000)
    return () => clearInterval(id)
  }, [hubReady, reload])

  useEffect(() => {
    api.get('/version').then(r => setHubVersion(r.data.version)).catch(() => setHubVersion(null))
  }, [wsConnected])

  // Fetch unread notification count on load and every 30 s
  useEffect(() => {
    const fetchUnread = () =>
      api.get('/notifications/unread-count').then(r => setUnreadNotifs(r.data.count)).catch(() => {})
    fetchUnread()
    const id = setInterval(fetchUnread, 30_000)
    return () => clearInterval(id)
  }, [])

  // When tab switches TO notifications, clear badge
  useEffect(() => {
    if (tab === 'notifications') {
      setUnreadNotifs(0)
    }
  }, [tab])

  const versionMismatch = hubVersion && hubVersion !== APP_VERSION

  const handleDeviceAction = useCallback((action) => {
    if (!action) return
    if (action.type === 'device_control') {
      api.post(`/devices/${action.device_id}/state`, { state: action.state }).catch(() => {})
      reload()
    }
  }, [reload])

  const TABS = [
    { id: 'dashboard',     label: t.home,              icon: '🏠' },
    { id: 'devices',       label: t.devices,           icon: '💡' },
    { id: 'scenes',        label: t.scenes_title,      icon: '🎬' },
    { id: 'cameras',       label: t.cameras_title,     icon: '📷' },
    { id: 'automations',   label: t.automations,       icon: '⚡' },
    { id: 'security',      label: t.security,          icon: '🔒' },
    { id: 'rooms',         label: t.rooms,             icon: '🛋️' },
    { id: 'network',       label: t.network,           icon: '📶' },
    { id: 'notifications', label: t.notifications_tab, icon: '🔔', badge: unreadNotifs },
    { id: 'settings',      label: t.settings,          icon: '⚙️' },
  ]

  // Show setup screen if hub is unreachable (and we're not in dev with VITE_HUB_URL)
  if (hubReady === false && !import.meta.env.VITE_HUB_URL) {
    return (
      <HubSetup
        currentUrl={getHubUrl()}
        onConnected={() => {
          setHubReady(null)
          // Re-check after connecting — /ping is root level, NOT /api/ping
          import('axios').then(({ default: axios }) => {
            axios.get(`${getHubUrl()}/ping`, { timeout: 4000 })
              .then(() => { setHubReady(true); reload() })
              .catch(() => setHubReady(false))
          })
        }}
      />
    )
  }

  // Still checking
  if (hubReady === null) {
    return (
      <div style={{
        minHeight: '100vh', background: '#0f172a', color: '#f1f5f9',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', gap: 16,
      }}>
        <div style={{ fontSize: 48 }}>🏠</div>
        <div style={{ fontSize: 14, color: '#475569' }}>{t.connecting}</div>
        <div style={{ width: 200, height: 3, background: '#1e293b', borderRadius: 2, overflow: 'hidden' }}>
          <div style={{
            height: '100%', width: '40%', background: '#1d4ed8', borderRadius: 2,
            animation: 'slide 1.4s ease-in-out infinite',
          }} />
          <style>{`@keyframes slide { 0%{margin-right:100%} 100%{margin-right:-40%} }`}</style>
        </div>
      </div>
    )
  }

  return (
    <div style={{
      minHeight: '100vh', background: '#0f172a', color: '#f1f5f9',
      direction: rtl ? 'rtl' : 'ltr',
      maxWidth: tablet ? 900 : 480, margin: '0 auto', position: 'relative',
    }}>

      {/* Header */}
      <div style={{ background: '#1e293b', borderBottom: '1px solid #334155', padding: '10px 16px', position: 'sticky', top: 0, zIndex: 50 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>

          {/* Left: logo + name */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 22 }}>🏠</span>
            <div>
              <div style={{ fontWeight: 900, fontSize: 17, color: '#38bdf8', lineHeight: 1, letterSpacing: '-0.3px' }}>
                FantaTech
              </div>
              <div style={{ fontSize: 10, color: '#94a3b8', marginTop: 1, lineHeight: 1 }}>
                Smart Home & Security
              </div>
            </div>
          </div>

          {/* Right: server status + version */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 3 }}>
            {/* WS connection status */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 5,
              background: wsConnected ? 'rgba(34,197,94,0.1)' : 'rgba(245,158,11,0.1)',
              border: `1px solid ${wsConnected ? '#22c55e44' : '#f59e0b44'}`,
              borderRadius: 20, padding: '2px 8px',
            }}>
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: wsConnected ? '#22c55e' : '#f59e0b',
                boxShadow: wsConnected ? '0 0 6px #22c55e' : '0 0 6px #f59e0b',
              }} />
              <span style={{ fontSize: 10, fontWeight: 600, color: wsConnected ? '#22c55e' : '#f59e0b' }}>
                {wsConnected ? t.connected : t.connecting}
              </span>
            </div>
            {/* Version */}
            <div style={{ fontSize: 9, color: '#334155' }}>
              v{APP_VERSION}{hubVersion ? ` · Hub v${hubVersion}` : ''}
            </div>
          </div>
        </div>

        {versionMismatch && (
          <div style={{ marginTop: 6, background: '#451a03', border: '1px solid #f59e0b', borderRadius: 6, padding: '4px 10px', fontSize: 11, color: '#fcd34d' }}>
            ⚠️ {(t.hub_version_mismatch || 'Hub version ({hub}) differs from app — restart start-hub.bat').replace('{hub}', hubVersion)}
          </div>
        )}
      </div>

      {/* Content */}
      <div style={{ padding: '20px 16px 80px' }}>
        {loading ? (
          <div style={{ textAlign: 'center', padding: 60, color: '#475569' }}>
            <div style={{ fontSize: 36 }}>⏳</div>
            <p style={{ marginTop: 12 }}>{t.loading}</p>
          </div>
        ) : (
          <>
            {tab === 'dashboard'   && <Dashboard     devices={devices} wsConnected={wsConnected} onNavigate={setTab} onReload={reload} tablet={tablet} />}
            {tab === 'devices'     && <DevicesPage    devices={devices} onReload={reload} tablet={tablet} />}
            {tab === 'scenes'      && <ScenesPage     devices={devices} tablet={tablet} />}
            {tab === 'cameras'     && <CamerasPage    devices={devices} />}
            {tab === 'automations' && <AutomationsPage devices={devices} />}
            {tab === 'security'    && <SecurityPage   devices={devices} onReload={reload} />}
            {tab === 'rooms'       && <RoomsPage />}
            {tab === 'network'        && <NetworkPage />}
            {tab === 'notifications'  && <NotificationsPage />}
            {tab === 'settings'       && <SettingsPage />}
          </>
        )}
      </div>

      {/* Gemini AI floating assistant */}
      <GeminiAssistant onDeviceAction={handleDeviceAction} />

      {/* Bottom Nav */}
      <nav style={{
        position: 'fixed', bottom: 0, left: '50%', transform: 'translateX(-50%)',
        width: '100%', maxWidth: tablet ? 900 : 480,
        background: '#1e293b', borderTop: '1px solid #334155',
        display: 'flex', zIndex: 80,
        direction: rtl ? 'rtl' : 'ltr',
      }}>
        {TABS.map(tabItem => (
          <button key={tabItem.id} onClick={() => setTab(tabItem.id)} style={{
            flex: 1, padding: '7px 2px 10px', border: 'none', background: 'none',
            color: tab === tabItem.id ? '#38bdf8' : '#64748b', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            position: 'relative',
          }}>
            <span style={{ fontSize: 18, position: 'relative' }}>
              {tabItem.icon}
              {tabItem.badge > 0 && (
                <span style={{
                  position: 'absolute', top: -4, insetInlineEnd: -6,
                  background: '#ef4444', color: '#fff',
                  borderRadius: 10, fontSize: 9, fontWeight: 700,
                  padding: '1px 4px', lineHeight: 1.3,
                  minWidth: 14, textAlign: 'center',
                }}>
                  {tabItem.badge > 99 ? '99+' : tabItem.badge}
                </span>
              )}
            </span>
            <span style={{ fontSize: 8.5, fontWeight: tab === tabItem.id ? 700 : 400, whiteSpace: 'nowrap' }}>{tabItem.label}</span>
            {tab === tabItem.id && (
              <div style={{ width: 3, height: 3, borderRadius: '50%', background: '#38bdf8' }} />
            )}
          </button>
        ))}
      </nav>
    </div>
  )
}

export default function App() {
  return (
    <LangProvider>
      <AppInner />
    </LangProvider>
  )
}
