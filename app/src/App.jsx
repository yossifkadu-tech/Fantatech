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
import CalibrationScreen, { isCalibrated } from './pages/CalibrationScreen'
import SchedulerPage from './pages/SchedulerPage'
import StorePage, { STORE_URL } from './pages/StorePage'
import VoiceControl from './components/VoiceControl'
import { useNotifications } from './hooks/useNotifications'

const APP_VERSION = '2.16.0'

/* ── Promo popup — shows once every 10 min ────────────────────────────── */
const PROMO_DEALS = [
  { img: '/products/led-strip.svg', titleHe: 'FantaGlow Strip 5m', title: 'FantaGlow Strip 5m', priceHe: '₪129 במקום ₪179 — 28% הנחה!', price: '₪129 instead of ₪179 — 28% off!' },
  { img: '/products/starter-kit.svg', titleHe: 'חבילת התחלה', title: 'Starter Bundle', priceHe: '₪899 במקום ₪1,189 — חסוך ₪290', price: '₪899 instead of ₪1,189 — Save ₪290' },
  { img: '/products/camera.svg', titleHe: 'FantaCam Indoor — מבצע סוף עונה', title: 'FantaCam Indoor — Clearance', priceHe: '₪169 במקום ₪289 — 43% הנחה!', price: '₪169 instead of ₪289 — 43% off!' },
]

function PromoPopup({ lang, rtl, onClose, onShop }) {
  const isHe = lang === 'he'
  const deal = PROMO_DEALS[Math.floor(Math.random() * PROMO_DEALS.length)]
  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 400,
      background: 'rgba(0,0,0,0.7)', display: 'flex',
      alignItems: 'center', justifyContent: 'center', padding: 24,
    }} onClick={onClose}>
      <div
        onClick={e => e.stopPropagation()}
        style={{
          background: '#1e293b', borderRadius: 20,
          border: '1px solid #1d4ed8', padding: '24px 20px',
          maxWidth: 300, width: '100%', textAlign: 'center',
          direction: rtl ? 'rtl' : 'ltr',
          boxShadow: '0 0 60px rgba(29,78,216,0.3)',
          position: 'relative',
        }}
      >
        <button onClick={onClose} style={{
          position: 'absolute', top: 10, insetInlineEnd: 12,
          background: 'none', border: 'none', color: '#475569',
          fontSize: 18, cursor: 'pointer',
        }}>✕</button>

        <img src={deal.img} alt={deal.title} style={{ width: 80, height: 80, objectFit: 'contain', marginBottom: 10 }} />
        <div style={{ fontSize: 11, color: '#38bdf8', fontWeight: 800, marginBottom: 6, letterSpacing: 1 }}>
          {isHe ? '🔥 מבצע מיוחד לאפליקציה' : '🔥 EXCLUSIVE APP DEAL'}
        </div>
        <div style={{ fontSize: 17, fontWeight: 900, color: '#f1f5f9', marginBottom: 4 }}>
          {isHe ? deal.titleHe : deal.title}
        </div>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#fbbf24', marginBottom: 18 }}>
          {isHe ? deal.priceHe : deal.price}
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={onClose} style={{
            flex: 1, padding: '9px 0', borderRadius: 10, border: '1px solid #334155',
            background: 'transparent', color: '#64748b', fontSize: 12, cursor: 'pointer',
          }}>
            {isHe ? 'אחר כך' : 'Later'}
          </button>
          <button onClick={() => { onShop(); onClose() }} style={{
            flex: 2, padding: '9px 0', borderRadius: 10, border: 'none',
            background: 'linear-gradient(135deg,#1d4ed8,#3b82f6)',
            color: '#fff', fontWeight: 800, fontSize: 13, cursor: 'pointer',
          }}>
            {isHe ? '🛒 לרכישה' : '🛒 Shop Now'}
          </button>
        </div>
      </div>
    </div>
  )
}

/* ── Bottom promo banner ──────────────────────────────────────────────── */
function PromoBanner({ lang, rtl, onShop, onDismiss }) {
  const isHe = lang === 'he'
  return (
    <div style={{
      background: 'linear-gradient(90deg,#1d1b6e,#1d4ed8)',
      borderTop: '1px solid #3b82f6',
      padding: '8px 14px',
      display: 'flex', alignItems: 'center', gap: 10,
      direction: rtl ? 'rtl' : 'ltr',
      position: 'relative', zIndex: 85,
    }}>
      <span style={{ fontSize: 18, flexShrink: 0 }}>🎁</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontWeight: 800, color: '#fff', lineHeight: 1.3 }}>
          {isHe ? 'FantaTech Store — מוצרי בית חכם' : 'FantaTech Store — Smart Home Products'}
        </div>
        <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.65)', lineHeight: 1.3 }}>
          {isHe ? 'ערכת פתיחה ₪499 במקום ₪699 — מבצע לזמן מוגבל' : 'Starter Kit ₪499 instead of ₪699 — Limited offer'}
        </div>
      </div>
      <button onClick={onShop} style={{
        padding: '5px 12px', borderRadius: 8, border: 'none', flexShrink: 0,
        background: '#fff', color: '#1d4ed8',
        fontWeight: 800, fontSize: 11, cursor: 'pointer',
      }}>
        {isHe ? 'לחנות' : 'Shop'}
      </button>
      <button onClick={onDismiss} style={{
        background: 'none', border: 'none', color: 'rgba(255,255,255,0.5)',
        fontSize: 16, cursor: 'pointer', flexShrink: 0, lineHeight: 1,
      }}>✕</button>
    </div>
  )
}

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
  const [registered,  setRegistered]  = useState(() => !!localStorage.getItem('fantatech_user'))
  const [calibrated,  setCalibrated]  = useState(isCalibrated)
  const [unreadNotifs, setUnreadNotifs] = useState(0)
  const [showNotifBanner, setShowNotifBanner] = useState(false)
  const [showPromoPopup, setShowPromoPopup]   = useState(false)
  const [showPromoBanner, setShowPromoBanner] = useState(() => !localStorage.getItem('ft_banner_dismissed'))
  const { devices, loading, reload, updateDeviceState, setOnline } = useDevices()
  const { permission, requestPermission, notify } = useNotifications()

  // Reactive screen size + orientation — from ScaleContext (wraps AppInner)
  const { sp, spx, phone, tablet, desktop, landscape, scale, displayScale, w } = useScale()
  // Sidebar on desktop always; also on tablet when in landscape mode
  // (landscape tablet = more horizontal space → sidebar more ergonomic than bottom nav)
  const showSidebar = desktop || (tablet && landscape)

  // Keep screen on when running on a tablet/desktop
  useWakeLock(tablet)

  const onDeviceState  = useCallback(d => updateDeviceState(d.id, d.state), [updateDeviceState])
  const onDeviceOnline = useCallback(d => setOnline(d.id, d.online), [setOnline])

  // Show notification permission banner once (after 3 s, only if not yet decided)
  useEffect(() => {
    if (permission === 'default') {
      const id = setTimeout(() => setShowNotifBanner(true), 3000)
      return () => clearTimeout(id)
    }
  }, [permission])

  // Show promo popup every 10 minutes
  useEffect(() => {
    const id = setInterval(() => setShowPromoPopup(true), 10 * 60 * 1000)
    return () => clearInterval(id)
  }, [])

  // Handle incoming notification pushed over WS
  const onWsNotification = useCallback((n) => {
    setUnreadNotifs(c => c + 1)
    window.dispatchEvent(new Event('fantatech_notification'))
    // Use unified notify service for all alert types
    notify(
      n?.title || 'FantaTech Alert',
      n?.message || '',
      { type: n?.type || 'info' }
    )
  }, [notify])

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
    { id: 'scheduler',     label: t.scheduler_nav ?? 'Scheduler',  icon: '🗓️' },
    { id: 'security',      label: t.security,                      icon: '🔒' },
    { id: 'rooms',         label: t.rooms,                         icon: '🛋️' },
    { id: 'gps',           label: t.gps_nav ?? 'GPS',              icon: '📍' },
    { id: 'users',         label: t.users_nav ?? 'Users',           icon: '👥' },
    { id: 'notifications', label: t.notifications_tab,             icon: '🔔', badge: unreadNotifs },
    { id: 'store',         label: t.store_nav ?? 'חנות',           icon: '🛍️' },
    { id: 'settings',      label: t.settings,                      icon: '⚙️' },
  ]

  // 1. Registration — first ever launch
  if (!registered) {
    return <RegistrationPage onComplete={() => setRegistered(true)} />
  }

  // 2. Calibration — once after registration, detects screen & sets optimal size
  if (!calibrated) {
    return <CalibrationScreen onComplete={() => setCalibrated(true)} />
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

  // ── Layout values (v2.0 baseline) ──────────────────────────────────────────
  const maxW = desktop ? 1280 : tablet ? 900 : 480   // 480 matches original v2.0

  return (
    // Single root div — no zoom, no transform → position:fixed nav works perfectly
    <div style={{
      width: '100%', maxWidth: maxW, margin: '0 auto',
      minHeight: '100vh',
      background: '#0f172a', color: '#f1f5f9',
      direction: rtl ? 'rtl' : 'ltr',
      position: 'relative',
      overflowX: 'hidden',
    }}>

      {/* Header — v2.0 standard layout */}
      <div style={{
        background: '#1e293b', borderBottom: '1px solid #334155',
        padding: '10px 16px',
        position: 'sticky', top: 0, zIndex: 50,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>

          {/* Left: logo + name + cyber button */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 22 }}>🏠</span>
            <div>
              <div style={{ fontWeight: 900, fontSize: phone ? 15 : 17, color: '#38bdf8', lineHeight: 1, letterSpacing: '-0.3px', whiteSpace: 'nowrap' }}>
                FantaTech
              </div>
              {!phone && (
                <div style={{ fontSize: 10, color: '#94a3b8', marginTop: 1, lineHeight: 1, whiteSpace: 'nowrap' }}>
                  Smart Home & Security
                </div>
              )}
            </div>
            {/* Cyber security shortcut */}
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

            {/* Voice control */}
            <VoiceControl devices={devices} onReload={reload} />

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

            {/* WS dot (always) + status text (tablet+) + version (desktop) */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <div style={{
                width: 8, height: 8, borderRadius: '50%',
                background: wsConnected ? '#22c55e' : '#f59e0b',
                boxShadow: wsConnected ? '0 0 6px #22c55e' : '0 0 6px #f59e0b',
                flexShrink: 0,
              }} />
              {!phone && (
                <span style={{ fontSize: 10, fontWeight: 600, color: wsConnected ? '#22c55e' : '#f59e0b' }}>
                  {wsConnected ? t.connected : t.connecting}
                </span>
              )}
              {desktop && (
                <span style={{ fontSize: 9, color: '#334155', marginLeft: 4 }}>
                  v{APP_VERSION}
                </span>
              )}
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

        {/* Sidebar nav — desktop always; tablet in landscape */}
        {showSidebar && (
          <nav style={{
            // Tablet-landscape sidebar is slimmer (140 px) than full desktop (200 px)
            width: desktop ? 200 : 140, flexShrink: 0,
            background: '#1e293b', borderInlineEnd: '1px solid #334155',
            position: 'sticky', top: 56, height: 'calc(100vh - 56px)',
            overflowY: 'auto', padding: '8px 0',
            display: 'flex', flexDirection: 'column', gap: 2,
            direction: rtl ? 'rtl' : 'ltr',
          }}>
            {TABS.map(tabItem => (
              <button key={tabItem.id} onClick={() => setTab(tabItem.id)} style={{
                display: 'flex', alignItems: 'center', gap: desktop ? 10 : 7,
                padding: desktop ? '10px 16px' : '8px 10px', border: 'none',
                background: tab === tabItem.id ? 'rgba(56,189,248,0.12)' : 'transparent',
                color: tab === tabItem.id ? '#38bdf8' : '#64748b',
                cursor: 'pointer', borderRadius: 8,
                margin: desktop ? '0 6px' : '0 4px',
                fontSize: desktop ? 13 : 11, fontWeight: tab === tabItem.id ? 700 : 400,
                transition: 'all 0.15s', position: 'relative',
                textAlign: rtl ? 'right' : 'left',
                borderInlineStart: tab === tabItem.id ? '3px solid #38bdf8' : '3px solid transparent',
              }}>
                <span style={{ fontSize: desktop ? 18 : 16 }}>{tabItem.icon}</span>
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

        {/* Notification permission banner */}
        {showNotifBanner && permission === 'default' && (
          <div style={{
            background: '#1a1f3a', border: '1px solid #6366f1',
            borderRadius: 14, margin: '8px 14px 0',
            padding: '12px 14px', display: 'flex', gap: 10, alignItems: 'center',
          }}>
            <span style={{ fontSize: 22 }}>🔔</span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0' }}>
                {t.notif_enable_title ?? 'Enable Notifications'}
              </div>
              <div style={{ fontSize: 11, color: '#64748b' }}>
                {t.notif_enable_hint ?? 'Get alerts when devices change or automations trigger.'}
              </div>
            </div>
            <button onClick={async () => { await requestPermission(); setShowNotifBanner(false) }} style={{
              padding: '6px 14px', borderRadius: 8, border: 'none',
              background: '#6366f1', color: '#fff', cursor: 'pointer', fontWeight: 700, fontSize: 12, flexShrink: 0,
            }}>
              {t.notif_allow ?? 'Allow'}
            </button>
            <button onClick={() => setShowNotifBanner(false)} style={{
              background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 18, flexShrink: 0,
            }}>✕</button>
          </div>
        )}

        {/* Main content — v2.0 padding; 80px bottom clears the fixed nav */}
        <div style={{
          flex: 1,
          padding: showSidebar ? '20px 24px 32px' : `16px 14px calc(${showPromoBanner ? 112 : 80}px + env(safe-area-inset-bottom))`,
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
              {tab === 'scheduler'   && <SchedulerPage   devices={devices} />}
              {tab === 'security'    && <SecurityPage   devices={devices} onReload={reload} onNavigate={setTab} />}
              {tab === 'cyber'       && <CyberPage />}
              {tab === 'rooms'       && <RoomsPage />}
              {tab === 'network'     && <NetworkPage />}
              {tab === 'gps'         && <GpsPage />}
              {tab === 'gemini'      && <GeminiAssistant onDeviceAction={handleDeviceAction} inline />}
              {tab === 'store'          && <StorePage />}
              {tab === 'users'          && <UsersPage />}
              {tab === 'notifications'  && <NotificationsPage />}
              {tab === 'settings'       && <SettingsPage />}
            </>
          )}
        </div>
      </div>

      {/* ── Promo popup ───────────────────────────────────────────────────── */}
      {showPromoPopup && (
        <PromoPopup
          lang={lang} rtl={rtl}
          onClose={() => setShowPromoPopup(false)}
          onShop={() => { setTab('store'); setShowPromoPopup(false) }}
        />
      )}

      {/* ── Bottom promo banner (above nav) ───────────────────────────────── */}
      {showPromoBanner && !showSidebar && (
        <div style={{
          position: 'fixed', bottom: 'calc(56px + env(safe-area-inset-bottom))',
          left: '50%', transform: 'translateX(-50%)',
          width: '100%', maxWidth: maxW, zIndex: 79,
        }}>
          <PromoBanner
            lang={lang} rtl={rtl}
            onShop={() => setTab('store')}
            onDismiss={() => {
              setShowPromoBanner(false)
              localStorage.setItem('ft_banner_dismissed', '1')
            }}
          />
        </div>
      )}

      {/* ── Bottom Nav (v2.0 style) — flex:1 equal buttons, position:fixed ── */}
      {!showSidebar && (
        <nav style={{
          position: 'fixed', bottom: 0, left: '50%', transform: 'translateX(-50%)',
          width: '100%', maxWidth: maxW,
          background: '#1e293b', borderTop: '1px solid #334155',
          display: 'flex', zIndex: 80,
          direction: rtl ? 'rtl' : 'ltr',
          paddingBottom: 'env(safe-area-inset-bottom)',
        }}>
          {TABS.map(tabItem => {
            const active = tab === tabItem.id
            return (
              <button key={tabItem.id} onClick={() => setTab(tabItem.id)} style={{
                flex: 1, padding: '5px 1px 7px', border: 'none', background: 'none',
                color: active ? '#38bdf8' : '#64748b',
                cursor: 'pointer',
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1,
                position: 'relative', minWidth: 0,
                WebkitTapHighlightColor: 'transparent',
              }}>
                <span style={{ fontSize: 15, position: 'relative', lineHeight: 1 }}>
                  {tabItem.icon}
                  {tabItem.badge > 0 && (
                    <span style={{
                      position: 'absolute', top: -3, insetInlineEnd: -5,
                      background: '#ef4444', color: '#fff',
                      borderRadius: 10, fontSize: 8, fontWeight: 700,
                      padding: '1px 3px', lineHeight: 1.3,
                      minWidth: 12, textAlign: 'center',
                    }}>{tabItem.badge > 99 ? '99+' : tabItem.badge}</span>
                  )}
                </span>
                <span style={{ fontSize: 7.5, fontWeight: active ? 700 : 400, whiteSpace: 'nowrap', overflow: 'hidden', maxWidth: '100%', textOverflow: 'ellipsis' }}>
                  {tabItem.label}
                </span>
                {active && <div style={{ width: 3, height: 3, borderRadius: '50%', background: '#38bdf8' }} />}
              </button>
            )
          })}
        </nav>
      )}

    </div>
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
