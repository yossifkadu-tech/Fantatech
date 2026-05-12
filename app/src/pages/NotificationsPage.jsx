import { useState, useEffect, useRef, useCallback } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

/* ── helpers ─────────────────────────────────────────────────────────────── */
const TYPE_META = {
  critical: { color: '#ef4444', bg: '#450a0a', border: '#ef4444', dot: '🔴', label_key: 'notif_tab_critical' },
  warning:  { color: '#f59e0b', bg: '#451a03', border: '#f59e0b', dot: '🟡', label_key: 'notif_tab_warning'  },
  info:     { color: '#38bdf8', bg: '#0c2340', border: '#1d4ed8', dot: '🔵', label_key: 'notif_tab_info'     },
}

const CAT_ICONS = {
  connection: '🌐',
  device:     '💡',
  install:    '🔧',
  system:     '⚙️',
  ai:         '✨',
}

function fmtTs(ts, locale) {
  const d = new Date(ts * 1000)
  const now = Date.now()
  const diff = now - d.getTime()
  if (diff < 60_000)  return '< 1m'
  if (diff < 3600_000) return `${Math.floor(diff / 60_000)}m`
  if (diff < 86400_000) return `${Math.floor(diff / 3600_000)}h`
  return d.toLocaleDateString(locale, { day: '2-digit', month: '2-digit' })
}

/* ── component ───────────────────────────────────────────────────────────── */
export default function NotificationsPage() {
  const { t, locale, rtl } = useLang()
  const [notifs, setNotifs]       = useState([])
  const [filter, setFilter]       = useState('all')   // all | critical | warning | info
  const [loading, setLoading]     = useState(false)
  const [analyzing, setAnalyzing] = useState(false)
  const [insights, setInsights]   = useState(null)
  const [pushEnabled, setPushEnabled] = useState(false)
  const [expandedId, setExpandedId]   = useState(null)
  const intervalRef = useRef(null)

  /* ── load ── */
  const load = useCallback(async () => {
    try {
      const r = await api.get('/notifications/?limit=200')
      setNotifs(r.data)
    } catch {}
  }, [])

  useEffect(() => {
    load()
    // Poll for new notifications every 15 s
    intervalRef.current = setInterval(load, 15_000)
    return () => clearInterval(intervalRef.current)
  }, [load])

  /* ── push notification permission ── */
  useEffect(() => {
    if ('Notification' in window) {
      setPushEnabled(Notification.permission === 'granted')
    }
  }, [])

  /* ── WS-pushed critical alert ── */
  // Handled by App.jsx ws event → re-fetch
  useEffect(() => {
    const handler = () => load()
    window.addEventListener('fantatech_notification', handler)
    return () => window.removeEventListener('fantatech_notification', handler)
  }, [load])

  /* ── mark read ── */
  const markRead = async (id) => {
    await api.put(`/notifications/${id}/read`).catch(() => {})
    setNotifs(prev => prev.map(n => n.id === id ? { ...n, read: 1 } : n))
  }

  const markAllRead = async () => {
    await api.post('/notifications/read-all').catch(() => {})
    setNotifs(prev => prev.map(n => ({ ...n, read: 1 })))
  }

  const clearAll = async () => {
    if (!confirm(t.confirm_clear_history)) return
    await api.delete('/notifications/').catch(() => {})
    setNotifs([])
    setInsights(null)
  }

  /* ── AI analysis ── */
  const analyze = async () => {
    setAnalyzing(true)
    try {
      const r = await api.post('/notifications/analyze', { lang: locale?.slice(0, 2) || 'he' })
      setInsights(r.data.insights)
      await load()   // reload to show AI insight notification
    } catch (e) {
      setInsights(`⚠️ ${e?.response?.data?.detail || t.error}`)
    }
    setAnalyzing(false)
  }

  /* ── request push permission ── */
  const requestPush = async () => {
    if (!('Notification' in window)) return
    const perm = await Notification.requestPermission()
    setPushEnabled(perm === 'granted')
  }

  /* ── filtered list ── */
  const filtered = filter === 'all'
    ? notifs
    : notifs.filter(n => n.type === filter)

  const unreadCount = notifs.filter(n => !n.read).length

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>

      {/* ── Header ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 14 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>{t.notif_page_title}</h2>
          {unreadCount > 0 && (
            <div style={{ fontSize: 12, color: '#f59e0b', marginTop: 2 }}>
              {unreadCount} {t.notif_unread_badge}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          {!pushEnabled && 'Notification' in window && (
            <button onClick={requestPush} style={btn('#1d4ed8', '#fff', 11)}>
              {t.notif_allow_push}
            </button>
          )}
          {pushEnabled && (
            <span style={{ fontSize: 10, color: '#22c55e', alignSelf: 'center' }}>
              {t.notif_push_enabled}
            </span>
          )}
          {unreadCount > 0 && (
            <button onClick={markAllRead} style={btn('#334155', '#94a3b8', 11)}>
              {t.notif_mark_all_read}
            </button>
          )}
          {notifs.length > 0 && (
            <button onClick={clearAll} style={btn('#7f1d1d', '#fca5a5', 11)}>
              {t.notif_clear_all}
            </button>
          )}
        </div>
      </div>

      {/* ── Filter chips ── */}
      <div style={{ display: 'flex', gap: 6, marginBottom: 14, overflowX: 'auto', paddingBottom: 2 }}>
        {['all', 'critical', 'warning', 'info'].map(f => {
          const count = f === 'all' ? notifs.length : notifs.filter(n => n.type === f).length
          return (
            <button key={f} onClick={() => setFilter(f)} style={{
              padding: '5px 12px', borderRadius: 20, cursor: 'pointer',
              whiteSpace: 'nowrap', fontSize: 12, fontWeight: filter === f ? 700 : 400,
              background: filter === f
                ? (f === 'critical' ? '#450a0a' : f === 'warning' ? '#451a03' : f === 'info' ? '#0c2340' : '#1e3a5f')
                : '#1e293b',
              color: filter === f
                ? (f === 'critical' ? '#ef4444' : f === 'warning' ? '#f59e0b' : f === 'info' ? '#38bdf8' : '#38bdf8')
                : '#64748b',
              border: `1px solid ${filter === f
                ? (f === 'critical' ? '#ef4444' : f === 'warning' ? '#f59e0b' : f === 'info' ? '#1d4ed8' : '#3b82f6')
                : '#334155'}`,
            }}>
              {f === 'all' ? t.notif_tab_all
               : f === 'critical' ? t.notif_tab_critical
               : f === 'warning'  ? t.notif_tab_warning
               : t.notif_tab_info}
              {count > 0 && (
                <span style={{
                  marginInlineStart: 6, background: 'rgba(255,255,255,0.12)',
                  borderRadius: 10, padding: '1px 6px', fontSize: 10,
                }}>{count}</span>
              )}
            </button>
          )
        })}
      </div>

      {/* ── AI Analyze button ── */}
      <button
        onClick={analyze}
        disabled={analyzing || notifs.length === 0}
        style={{
          ...btn('#7c3aed', '#c4b5fd', 13),
          width: '100%', marginBottom: 14,
          opacity: (analyzing || notifs.length === 0) ? 0.6 : 1,
        }}>
        {analyzing ? t.notif_analyzing : t.notif_analyze_btn}
      </button>

      {/* ── AI Insights panel ── */}
      {insights && (
        <div style={{
          background: '#1a0f2e', border: '1px solid #7c3aed', borderRadius: 12,
          padding: 14, marginBottom: 16,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontWeight: 700, color: '#c4b5fd', fontSize: 13 }}>{t.notif_ai_insights_title}</span>
            <button onClick={() => setInsights(null)} style={{
              background: 'none', border: 'none', color: '#64748b',
              cursor: 'pointer', fontSize: 11,
            }}>{t.notif_close_insights}</button>
          </div>
          <div style={{ fontSize: 12, color: '#e2e8f0', lineHeight: 1.7, whiteSpace: 'pre-wrap' }}>
            {insights}
          </div>
        </div>
      )}

      {/* ── Empty state ── */}
      {filtered.length === 0 && (
        <div style={{ textAlign: 'center', padding: 50, color: '#475569' }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>🔔</div>
          <p style={{ margin: 0 }}>
            {filter === 'all' ? t.notif_empty : t.notif_empty_filtered}
          </p>
        </div>
      )}

      {/* ── Notification list ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {filtered.map(n => {
          const meta   = TYPE_META[n.type] || TYPE_META.info
          const catIcon = CAT_ICONS[n.category] || '📌'
          const isExpanded = expandedId === n.id

          return (
            <div
              key={n.id}
              onClick={() => {
                setExpandedId(isExpanded ? null : n.id)
                if (!n.read) markRead(n.id)
              }}
              style={{
                background: n.read ? '#0f172a' : meta.bg,
                border: `1px solid ${n.read ? '#1e293b' : meta.border}`,
                borderRadius: 12, padding: '12px 14px',
                cursor: 'pointer', transition: 'opacity .15s',
                opacity: n.read ? 0.7 : 1,
              }}
            >
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                {/* Severity dot */}
                <div style={{ flexShrink: 0, marginTop: 2 }}>
                  <span style={{ fontSize: 14 }}>{meta.dot}</span>
                </div>

                {/* Content */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 700, color: n.read ? '#94a3b8' : '#f1f5f9', fontSize: 13 }}>
                      {n.title}
                    </span>
                    <span style={{
                      fontSize: 10, background: '#1e293b', border: '1px solid #334155',
                      borderRadius: 4, padding: '1px 6px', color: '#64748b',
                      flexShrink: 0,
                    }}>
                      {catIcon} {t[`notif_cat_${n.category}`] || n.category}
                    </span>
                    {!n.read && (
                      <span style={{
                        width: 7, height: 7, borderRadius: '50%',
                        background: meta.color, flexShrink: 0,
                        display: 'inline-block',
                      }} />
                    )}
                  </div>

                  {/* Message preview / expanded */}
                  {n.message && (
                    <div style={{
                      fontSize: 12, color: '#64748b', lineHeight: 1.5,
                      ...(!isExpanded ? {
                        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                        maxWidth: '100%',
                      } : {
                        whiteSpace: 'pre-wrap', wordBreak: 'break-word',
                      }),
                    }}>
                      {n.message}
                    </div>
                  )}

                  {/* Device name */}
                  {n.device_name && (
                    <div style={{ fontSize: 11, color: '#38bdf8', marginTop: 3 }}>
                      💡 {n.device_name}
                    </div>
                  )}
                </div>

                {/* Timestamp */}
                <div style={{ fontSize: 11, color: '#475569', flexShrink: 0, marginTop: 2, textAlign: 'end' }}>
                  {fmtTs(n.ts, locale)}
                </div>
              </div>
            </div>
          )
        })}
      </div>

    </div>
  )
}

const btn = (bg, color = '#fff', size = 13) => ({
  padding: `6px 12px`, borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: size,
})
