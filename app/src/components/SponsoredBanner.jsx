/**
 * SponsoredBanner — פינת פרסום ממון
 * Ads are stored in localStorage as JSON array.
 * Each ad: { id, title, desc, imageUrl, url, btnLabel, color, active }
 */
import { useState, useEffect } from 'react'
import { useLang } from '../context/LangContext'

const STORAGE_KEY = 'fantatech_ads'

const DEFAULT_ADS = [
  {
    id: 'ad-fantatech',
    title: 'Fantatech — התקנת בית חכם',
    desc: 'מתקינים בית חכם מלא: Zigbee, WiFi, מצלמות, מנעולים חכמים. שירות מקצועי.',
    imageUrl: '',
    url: 'https://fantatech.co.il',
    btnLabel: 'לפרטים ›',
    color: '#1d4ed8',
    active: true,
    sponsored: false,
  },
  {
    id: 'ad-slot-1',
    title: 'פרסם כאן',
    desc: 'הגע לאלפי משתמשי Fantatech Home. מקום הפרסום הזה פנוי — צור קשר.',
    imageUrl: '',
    url: '',
    btnLabel: 'צור קשר ›',
    color: '#475569',
    active: true,
    sponsored: false,
    placeholder: true,
  },
]

export function loadAds() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null')
    return saved || DEFAULT_ADS
  } catch { return DEFAULT_ADS }
}

export function saveAds(ads) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(ads)) } catch {}
}

/* ── Ad image with fallback ────────────────────────────────────────────── */
function AdImage({ src, color, size = 56 }) {
  const [err, setErr] = useState(false)
  if (err || !src) {
    return (
      <div style={{
        width: size, height: size, borderRadius: 10, flexShrink: 0,
        background: color + '22',
        border: `1px solid ${color}44`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: size * 0.45, color: color,
      }}>📢</div>
    )
  }
  return (
    <div style={{ width: size, height: size, borderRadius: 10, flexShrink: 0, overflow: 'hidden' }}>
      <img src={src} alt="" onError={() => setErr(true)}
        style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
    </div>
  )
}

/* ── Single ad card ────────────────────────────────────────────────────── */
function AdCard({ ad }) {
  const { t } = useLang()
  const content = (
    <div style={{
      background: '#1e293b',
      border: `1px solid ${ad.placeholder ? '#334155' : ad.color + '66'}`,
      borderRadius: 14, padding: '12px 14px',
      display: 'flex', gap: 12, alignItems: 'center',
      opacity: ad.placeholder ? 0.6 : 1,
    }}>
      <AdImage src={ad.imageUrl} color={ad.color} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
          <span style={{ fontSize: 12, fontWeight: 700, color: '#f1f5f9' }}>{ad.title}</span>
          {!ad.placeholder && (
            <span style={{
              fontSize: 9, padding: '1px 5px', borderRadius: 4,
              background: '#334155', color: '#64748b', fontWeight: 600,
            }}>{t.sponsored}</span>
          )}
        </div>
        <div style={{ fontSize: 11, color: '#64748b', lineHeight: 1.5, marginBottom: 6 }}>{ad.desc}</div>
        {ad.btnLabel && (
          <span style={{
            display: 'inline-block', padding: '4px 12px', borderRadius: 8,
            background: ad.placeholder ? '#334155' : ad.color,
            color: ad.placeholder ? '#64748b' : '#fff',
            fontSize: 11, fontWeight: 700,
          }}>{ad.btnLabel}</span>
        )}
      </div>
    </div>
  )

  if (!ad.url || ad.placeholder) return content
  return (
    <a href={ad.url} target="_blank" rel="noreferrer" style={{ textDecoration: 'none', display: 'block' }}>
      {content}
    </a>
  )
}

/* ── Main component ─────────────────────────────────────────────────────── */
export default function SponsoredBanner() {
  const { t, rtl } = useLang()
  const [ads, setAds] = useState(() => loadAds())
  const [dismissed, setDismissed] = useState(
    () => localStorage.getItem('ads_dismissed') === '1'
  )

  useEffect(() => {
    setAds(loadAds())
  }, [])

  const activeAds = ads.filter(a => a.active)
  if (activeAds.length === 0) return null

  if (dismissed) {
    return (
      <div style={{ textAlign: 'center', marginBottom: 16 }}>
        <button onClick={() => { setDismissed(false); localStorage.removeItem('ads_dismissed') }} style={{
          background: 'none', border: '1px solid #334155', borderRadius: 8,
          color: '#475569', fontSize: 11, cursor: 'pointer', padding: '4px 12px',
        }}>
          {t.show_ads ?? '📢 Show Ads'}
        </button>
      </div>
    )
  }

  return (
    <div style={{ marginBottom: 24 }} dir={rtl ? 'rtl' : 'ltr'}>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10,
      }}>
        <h3 style={{ margin: 0, fontSize: 14, color: '#94a3b8' }}>
          📢 {t.sponsored ?? 'Sponsored'}
        </h3>
        <button onClick={() => { setDismissed(true); localStorage.setItem('ads_dismissed', '1') }} style={{
          background: 'none', border: 'none', color: '#334155',
          fontSize: 16, cursor: 'pointer', padding: '0 2px',
        }} title={t.close}>✕</button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {activeAds.map(ad => <AdCard key={ad.id} ad={ad} />)}
      </div>
    </div>
  )
}
