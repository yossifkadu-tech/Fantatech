import { useState, useEffect, useCallback, useRef } from 'react'
import { useDevices, useWebSocket, api, getHubUrl } from './hooks/useHub'
import { LangProvider, useLang, LANG_META } from './context/LangContext'
import { ScaleProvider, useScale } from './context/ScaleContext'
import Dashboard from './pages/Dashboard'
import DevicesPage from './pages/DevicesPage'
import AutomationsPage from './pages/AutomationsPage'
import HistoryPage from './pages/HistoryPage'
import NotificationsPage from './pages/NotificationsPage'
import RoomsPage from './pages/RoomsPage'
import NetworkPage from './pages/NetworkPage'
import AcPage from './pages/AcPage'
import SettingsPage from './pages/SettingsPage'
import HubSetup from './pages/HubSetup'
import SecurityPage from './pages/SecurityPage'
import ScenesPage from './pages/ScenesPage'
import CamerasPage from './pages/CamerasPage'
import CyberPage from './pages/CyberPage'
import GpsPage from './pages/GpsPage'
import RegistrationPage from './pages/RegistrationPage'
import GeminiAssistant from './components/GeminiAssistant'
import UsersPage from './pages/UsersPage'

const APP_VERSION = '2.13.1'

/* ── Wake-lock hook (keeps screen on while mounted) ─────────────────── */
function useWakeLock(enabled) {
  const lockRef = useRef(null)
  useEffect(() => {
    if (!enabled) return
    let released = false

    const acquire = async () => {
      // 1. Try Capacitor native plugin (Android + iOS)
      try {
        const { KeepAwake } = await import('@capacitor-community/keep-awake')
        await KeepAwake.keepAwake()
        console.log('[WakeLock] KeepAwake (native) active')
        return
      } catch {}

      // 2. Fallback: Web Wake Lock API (Chrome/Edge)
      try {
        if ('wakeLock' in navigator) {
          lockRef.current = await navigator.wakeLock.request('screen')
          console.log('[WakeLock] Web WakeLock API active')
        }
      } catch {}
    }

    acquire()

    // Re-acquire after page visibility change (browser may release it)
    const onVisible = () => { if (document.visibilityState === 'visible') acquire() }
    document.addEventListener('visibilitychange', onVisible)

    return () => {
      released = true
      document.removeEventListener('visibilitychange', onVisible)
      import('@capacitor-community/keep-awake')
        .then(({ KeepAwake }) => KeepAwake.allowSleep())
        .catch(() => {})
      if (lockRef.current) { lockRef.current.release(); lockRef.current = null }
    }
  }, [enabled])
}

function AppInner() {
  const { t, lang, rtl, setLang } = useLang()
  const [langPickerOpen, setLangPickerOpen] = useState(false)

  const LANG_CODES = Object.keys(LANG_META)
  const [tab, setTab]           = useState('dashboard')
  const [hubVersion, setHubVersion] = useState(null)
  const [hubReady, setHubReady] = useState(null)   // null=checking, true, false
  const [registered, setRegistered] = useState(() => !!localStorage.getItem('fantatech_user'))
  const [unreadNotifs, setUnreadNotifs] = useState(0)
  const { devices, loading, reload, updateDeviceState, setOnline } = useDevices()

  // Reactive screen size + orientation — from ScaleContext (wraps AppInner)
  const { sp, spx, phone, tablet, desktop, landscape, scale } = useScale()
  // Sidebar ONLY on desktop — phone and tablet always use bottom nav
  const showSidebar = desktop

  // Keep screen on when running on a tablet/desktop
  useWakeLock(tablet)

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
    if (tab === 'notifications') setUnreadNotifs(0)
    setLangPickerOpen(false)          // close lang picker on any tab change
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
    { id: 'dashboard',     label: t.home,                          icon: '🏠' },
    { id: 'devices',       label: t.devices,                       icon: '💡' },
    { id: 'ac',            label: t.ac_page_title ?? 'מזגנים',     icon: '❄️' },
    { id: 'gemini',        label: t.gemini_nav ?? 'Gemini',        icon: '✨' },
    { id: 'cameras',       label: t.cameras_title,                 icon: '📷' },
    { id: 'automations',   label: t.automations,                   icon: '⚡' },
    { id: 'security',      label: t.security,                      icon: '🔒' },
    { id: 'rooms',         label: t.rooms,                         icon: '🛋️' },
    { id: 'gps',           label: t.gps_nav ?? 'GPS',              icon: '📍' },
    { id: 'users',         label: t.users_nav ?? 'Users',           icon: '👥' },
    { id: 'notifications', label: t.notifications_tab,             icon: '🔔', badge: unreadNotifs },
    { id: 'settings',      label: t.settings,                      icon: '⚙️' },
  ]

  // Show registration on first launch (before hub check)
  if (!registered) {
    return (
      <RegistrationPage onComplete={() => setRegistered(true)} />
    )
  }

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

  // Responsive layout values
  const maxW      = desktop ? 1280 : tablet ? 900 : 480
  // Font scaling: only desktop gets a slight bump; phone uses scale from ScaleContext
  const fontScale = desktop ? 1.05 : 1
  // Bottom nav height — scaled on phone so it shrinks on small screens
  const navH      = !desktop ? (landscape ? sp(44) : sp(56)) : 0

  return (
    <div style={{
      minHeight: '100vh', background: '#0f172a', color: '#f1f5f9',
      direction: rtl ? 'rtl' : 'ltr',
      maxWidth: maxW, width: '100%', margin: '0 auto',
      position: 'relative', fontSize: `${fontScale}rem`,
      // Ensure content never hides under fixed bottom nav
      paddingBottom: navH > 0 ? `calc(${navH}px + env(safe-area-inset-bottom))` : 0,
    }}>

      {/* Header — compact in landscape to maximise content area */}
      <div style={{
        background: '#1e293b', borderBottom: '1px solid #334155',
        padding: landscape ? `${sp(6)}px ${sp(14)}px`
               : desktop  ? '12px 28px'
               : tablet   ? '10px 20px'
               :             `${sp(10)}px ${sp(14)}px`,
        position: 'sticky', top: 0, zIndex: 50,
        paddingLeft:  `max(${sp(landscape ? 14 : desktop ? 28 : tablet ? 20 : 14)}px, env(safe-area-inset-left))`,
        paddingRight: `max(${sp(landscape ? 14 : desktop ? 28 : tablet ? 20 : 14)}px, env(safe-area-inset-right))`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>

          {/* Left: logo + name + cyber button */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: spx(22) }}>🏠</span>
            <div>
              <div style={{ fontWeight: 900, fontSize: spx(17), color: '#38bdf8', lineHeight: 1, letterSpacing: '-0.3px' }}>
                FantaTech
              </div>
              <div style={{ fontSize: spx(10), color: '#94a3b8', marginTop: 1, lineHeight: 1 }}>
                Smart Home & Security
              </div>
            </div>
            {/* Cyber security shortcut — lives next to the brand name */}
            <button
              onClick={() => setTab('cyber')}
              title={t.cyber_nav ?? 'Cyber'}
              style={{
                background: tab === 'cyber' ? 'rgba(99,102,241,0.18)' : 'transparent',
                border: `1px solid ${tab === 'cyber' ? '#6366f1' : '#334155'}`,
                borderRadius: 8, padding: '5px 8px', cursor: 'pointer',
                fontSize: 16, lineHeight: 1,
                WebkitTapHighlightColor: 'transparent',
                transition: 'all 0.15s',
              }}
            >🛡️</button>
          </div>

          {/* Right: lang + network icon + server status + version */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {/* Quick language switcher */}
            <div style={{ position: 'relative' }}>
              <button
                onClick={() => setLangPickerOpen(v => !v)}
                title={t.language ?? 'Language'}
                style={{
                  background: langPickerOpen ? 'rgba(56,189,248,0.12)' : 'transparent',
                  border: `1px solid ${langPickerOpen ? '#38bdf8' : '#334155'}`,
                  borderRadius: 8, padding: '4px 8px', cursor: 'pointer',
                  fontSize: 12, fontWeight: 700,
                  color: langPickerOpen ? '#38bdf8' : '#94a3b8',
                  lineHeight: 1, letterSpacing: 0.5,
                  WebkitTapHighlightColor: 'transparent',
                  transition: 'all 0.15s',
                }}
              >
                🌍 {lang.toUpperCase()}
              </button>

              {/* Mini language picker dropdown */}
              {langPickerOpen && (
                <div style={{
                  position: 'absolute', top: '110%', insetInlineEnd: 0,
                  background: '#1e293b', border: '1px solid #334155',
                  borderRadius: 12, padding: 8, zIndex: 200,
                  display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 4,
                  minWidth: 180, boxShadow: '0 8px 24px rgba(0,0,0,0.5)',
                }}>
                  {LANG_CODES.map(code => {
                    const meta = LANG_META[code]
                    const active = lang === code
                    return (
                      <button key={code} onClick={() => { setLang(code); setLangPickerOpen(false) }} style={{
                        display: 'flex', flexDirection: 'column', alignItems: 'center',
                        gap: 3, padding: '8px 4px', borderRadius: 8,
                        border: `1px solid ${active ? '#38bdf8' : '#334155'}`,
                        background: active ? 'rgba(56,189,248,0.15)' : 'transparent',
                        cursor: 'pointer',
                        WebkitTapHighlightColor: 'transparent',
                      }}>
                        <span style={{ fontSize: 10, fontWeight: 800, color: active ? '#38bdf8' : '#64748b' }}>
                          {code.toUpperCase()}
                        </span>
                        <span style={{ fontSize: 9, color: active ? '#e2e8f0' : '#475569', lineHeight: 1.2, textAlign: 'center' }}>
                          {meta.name}
                        </span>
                      </button>
                    )
                  })}
                </div>
              )}
            </div>

            {/* Network scan icon button */}
            <button
              onClick={() => setTab('network')}
              title={t.network ?? 'Network'}
              style={{
                background: tab === 'network' ? 'rgba(56,189,248,0.15)' : 'transparent',
                border: `1px solid ${tab === 'network' ? '#38bdf8' : '#334155'}`,
                borderRadius: 8, padding: '4px 8px', cursor: 'pointer',
                fontSize: 16, lineHeight: 1,
                WebkitTapHighlightColor: 'transparent',
              }}
            >
              📶
            </button>

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
        </div>

        {versionMismatch && (
          <div style={{ marginTop: 6, background: '#451a03', border: '1px solid #f59e0b', borderRadius: 6, padding: '4px 10px', fontSize: 11, color: '#fcd34d' }}>
            ⚠️ {(t.hub_version_mismatch || 'Hub version ({hub}) differs from app — restart start-hub.bat').replace('{hub}', hubVersion)}
          </div>
        )}
      </div>

      {/* ── Layout: desktop = sidebar + content, phone/tablet = content + fixed bottom nav ── */}
      <div style={{ display: 'flex', minHeight: 'calc(100vh - 56px)' }}>

        {/* Sidebar nav — desktop ONLY */}
        {showSidebar && (
          <nav style={{
            width: 200, flexShrink: 0,
            background: '#1e293b', borderInlineEnd: '1px solid #334155',
            position: 'sticky', top: 56, height: 'calc(100vh - 56px)',
            overflowY: 'auto', padding: '12px 0',
            display: 'flex', flexDirection: 'column', gap: 2,
            direction: rtl ? 'rtl' : 'ltr',
          }}>
            {TABS.map(tabItem => (
              <button key={tabItem.id} onClick={() => setTab(tabItem.id)} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                padding: '10px 16px', border: 'none',
                background: tab === tabItem.id ? 'rgba(56,189,248,0.12)' : 'transparent',
                color: tab === tabItem.id ? '#38bdf8' : '#64748b',
                cursor: 'pointer', borderRadius: 8, margin: '0 6px',
                fontSize: 13, fontWeight: tab === tabItem.id ? 700 : 400,
                transition: 'all 0.15s', position: 'relative',
                textAlign: rtl ? 'right' : 'left',
                borderInlineStart: tab === tabItem.id ? '3px solid #38bdf8' : '3px solid transparent',
              }}>
                <span style={{ fontSize: 18 }}>{tabItem.icon}</span>
                <span style={{ flex: 1 }}>{tabItem.label}</span>
                {tabItem.badge > 0 && (
                  <span style={{
                    background: '#ef4444', color: '#fff',
                    borderRadius: 10, fontSize: 9, fontWeight: 700,
                    padding: '1px 5px', lineHeight: 1.4, minWidth: 16, textAlign: 'center',
                  }}>{tabItem.badge > 99 ? '99+' : tabItem.badge}</span>
                )}
              </button>
            ))}
          </nav>
        )}

        {/* Main content */}
        <div style={{
          flex: 1,
          padding: showSidebar
            ? '20px 28px 32px'
            : landscape
              ? `${sp(8)}px ${sp(12)}px ${sp(10)}px`
              : tablet
                ? '16px 18px 12px'
                : `${sp(12)}px ${sp(14)}px ${sp(10)}px`,
          minWidth: 0,
          overflowX: 'hidden',
        }}>
          {loading ? (
            <div style={{ textAlign: 'center', padding: 60, color: '#475569' }}>
              <div style={{ fontSize: 36 }}>⏳</div>
              <p style={{ marginTop: 12 }}>{t.loading}</p>
            </div>
          ) : (
            <>
              {tab === 'dashboard'   && <Dashboard     devices={devices} wsConnected={wsConnected} onNavigate={setTab} onReload={reload} tablet={tablet} landscape={landscape} />}
              {tab === 'devices'     && <DevicesPage    devices={devices} onReload={reload} tablet={tablet} landscape={landscape} />}
              {tab === 'ac'          && <AcPage         devices={devices} onReload={reload} tablet={tablet} landscape={landscape} />}
              {tab === 'scenes'      && <ScenesPage     devices={devices} tablet={tablet} landscape={landscape} />}
              {tab === 'cameras'     && <CamerasPage    devices={devices} />}
              {tab === 'automations' && <AutomationsPage devices={devices} />}
              {tab === 'security'    && <SecurityPage   devices={devices} onReload={reload} onNavigate={setTab} />}
              {tab === 'cyber'       && <CyberPage />}
              {tab === 'rooms'       && <RoomsPage />}
              {tab === 'network'     && <NetworkPage />}
              {tab === 'gps'         && <GpsPage />}
              {tab === 'gemini'      && <GeminiAssistant onDeviceAction={handleDeviceAction} inline />}
              {tab === 'users'          && <UsersPage />}
              {tab === 'notifications'  && <NotificationsPage />}
              {tab === 'settings'       && <SettingsPage />}
            </>
          )}
        </div>
      </div>

      {/* ── Bottom Nav — phone + tablet; hidden on desktop ──────────────────── */}
      {!desktop && <BottomNav
        tabs={TABS} activeTab={tab} onSelect={setTab}
        navH={navH} maxW={maxW} rtl={rtl}
        landscape={landscape} tablet={tablet}
        sp={sp} spx={spx}
      />}
    </div>
  )
}

/**
 * BottomNav — horizontally scrollable bottom navigation.
 *
 * On phones with many tabs the buttons have a minimum touch width (minWidth).
 * If all tabs together exceed the screen width the nav scrolls horizontally
 * with no visible scrollbar. The active tab is always scrolled into view.
 */
function BottomNav({ tabs, activeTab, onSelect, navH, maxW, rtl, landscape, tablet, sp, spx }) {
  const navRef = useRef(null)

  // Auto-scroll active tab into view when tab changes
  useEffect(() => {
    if (!navRef.current) return
    const btn = navRef.current.querySelector('[data-active="true"]')
    btn?.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' })
  }, [activeTab])

  // Per-button minimum width — touch-friendly but allows scrolling
  const btnMin = tablet ? 64 : sp(52)  // px number

  return (
    <nav
      ref={navRef}
      className="ft-bottom-nav"
      style={{
        position: 'fixed', bottom: 0,
        left: '50%', transform: 'translateX(-50%)',
        width: '100%', maxWidth: maxW,
        background: '#1e293b', borderTop: '1px solid #334155',
        display: 'flex', zIndex: 100,
        direction: rtl ? 'rtl' : 'ltr',
        height: navH,
        boxSizing: 'border-box',
        alignItems: 'center',
        paddingBottom: 'env(safe-area-inset-bottom)',
        paddingLeft:   'env(safe-area-inset-left)',
        paddingRight:  'env(safe-area-inset-right)',
        // Horizontal scroll when tabs don't fit
        overflowX: 'auto',
        overflowY: 'hidden',
        scrollbarWidth: 'none',             // Firefox
        WebkitOverflowScrolling: 'touch',   // iOS momentum
      }}
    >
      {tabs.map(tabItem => {
        const active = activeTab === tabItem.id
        return (
          <button
            key={tabItem.id}
            data-active={active}
            onClick={() => onSelect(tabItem.id)}
            style={{
              // flex: none + minWidth → buttons have guaranteed width, nav scrolls
              flex: 'none',
              minWidth: btnMin,
              height: '100%',
              padding: landscape
                ? `${sp(4)}px ${sp(2)}px`
                : tablet
                  ? `${sp(5)}px ${sp(3)}px ${sp(7)}px`
                  : `${sp(4)}px ${sp(2)}px ${sp(6)}px`,
              border: 'none', background: 'none',
              color: active ? '#38bdf8' : '#64748b',
              cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              justifyContent: 'center', gap: sp(1),
              position: 'relative',
              WebkitTapHighlightColor: 'transparent',
              borderTop: active ? '2px solid #38bdf8' : '2px solid transparent',
              transition: 'color 0.15s',
            }}
          >
            {/* Icon + optional badge */}
            <span style={{ fontSize: spx(landscape ? 17 : tablet ? 20 : 18), position: 'relative', lineHeight: 1 }}>
              {tabItem.icon}
              {tabItem.badge > 0 && (
                <span style={{
                  position: 'absolute', top: -4, insetInlineEnd: -6,
                  background: '#ef4444', color: '#fff',
                  borderRadius: 10, fontSize: spx(8), fontWeight: 700,
                  padding: '1px 4px', lineHeight: 1.3, minWidth: 14, textAlign: 'center',
                }}>
                  {tabItem.badge > 99 ? '99+' : tabItem.badge}
                </span>
              )}
            </span>
            {/* Label — hidden in landscape */}
            {!landscape && (
              <span style={{
                fontSize: spx(tablet ? 9.5 : 8),
                fontWeight: active ? 700 : 400,
                whiteSpace: 'nowrap',
                lineHeight: 1,
              }}>
                {tabItem.label}
              </span>
            )}
          </button>
        )
      })}
    </nav>
  )
}

export default function App() {
  return (
    <ScaleProvider>
      <LangProvider>
        <AppInner />
      </LangProvider>
    </ScaleProvider>
  )
}
