/**
 * SponsoredBanner — Sponsored / promoted content corner.
 * Ads are stored in localStorage as JSON array.
 * Each ad field (title, desc, btnLabel) can be:
 *   - a plain string  → shown as-is in all languages
 *   - a lang-keyed object  { he: '…', en: '…', ar: '…', … }  → localised
 */
import { useState, useEffect } from 'react'
import { useLang } from '../context/LangContext'

const STORAGE_KEY = 'fantatech_ads'

/* ── Localisation helper (shared with PromoCarousel) ──────────────────────── */
export function loc(field, lang) {
  if (!field) return ''
  if (typeof field === 'string') return field
  // Try current lang → English → Hebrew → first available → ''
  return field[lang] || field.en || field.he
    || Object.values(field).find(v => v) || ''
}

/* ── Default ads — fully multilingual ────────────────────────────────────── */
const DEFAULT_ADS = [
  {
    id: 'ad-fantatech',
    title: {
      he: 'Fantatech — התקנת בית חכם',
      en: 'Fantatech — Smart Home Installation',
      ar: 'Fantatech — تركيب المنزل الذكي',
      ru: 'Fantatech — Умный дом под ключ',
      es: 'Fantatech — Instalación de hogar inteligente',
      fr: 'Fantatech — Installation maison intelligente',
      de: 'Fantatech — Smart-Home-Installation',
      pt: 'Fantatech — Instalação de casa inteligente',
      am: 'Fantatech — Smart Home Installation',
    },
    desc: {
      he: 'מתקינים בית חכם מלא: Zigbee, WiFi, מצלמות, מנעולים חכמים. שירות מקצועי.',
      en: 'Full smart-home installations: Zigbee, WiFi, cameras, smart locks. Professional service.',
      ar: 'تركيب منزل ذكي كامل: Zigbee، WiFi، كاميرات، أقفال ذكية. خدمة احترافية.',
      ru: 'Полная установка умного дома: Zigbee, WiFi, камеры, умные замки.',
      es: 'Instalaciones completas de hogar inteligente: Zigbee, WiFi, cámaras, cerraduras.',
      fr: 'Installations complètes maison intelligente: Zigbee, WiFi, caméras, serrures.',
      de: 'Komplette Smart-Home-Installationen: Zigbee, WiFi, Kameras, smarte Schlösser.',
      pt: 'Instalações completas de casa inteligente: Zigbee, WiFi, câmeras, fechaduras.',
      am: 'Full smart-home installations: Zigbee, WiFi, cameras, smart locks.',
    },
    imageUrl: '',
    url: 'https://fantatech.co.il',
    btnLabel: {
      he: 'לפרטים ›',
      en: 'Learn More ›',
      ar: 'للتفاصيل ›',
      ru: 'Подробнее ›',
      es: 'Más info ›',
      fr: 'En savoir + ›',
      de: 'Mehr erfahren ›',
      pt: 'Saiba mais ›',
      am: 'Learn More ›',
    },
    color: '#1d4ed8',
    active: true,
    sponsored: false,
  },
  {
    id: 'ad-slot-1',
    title: {
      he: 'פרסם כאן',
      en: 'Advertise Here',
      ar: 'أعلن هنا',
      ru: 'Разместите рекламу',
      es: 'Anuncíate aquí',
      fr: 'Annoncez ici',
      de: 'Hier werben',
      pt: 'Anuncie aqui',
      am: 'Advertise Here',
    },
    desc: {
      he: 'הגע לאלפי משתמשי Fantatech Home. מקום הפרסום הזה פנוי — צור קשר.',
      en: 'Reach thousands of Fantatech Home users. This ad slot is open — contact us.',
      ar: 'تواصل مع آلاف مستخدمي Fantatech Home. هذه المساحة متاحة — تواصل معنا.',
      ru: 'Охватите тысячи пользователей Fantatech. Рекламное место свободно.',
      es: 'Llega a miles de usuarios de Fantatech. Este espacio está disponible.',
      fr: 'Atteignez des milliers d\'utilisateurs Fantatech. Espace disponible.',
      de: 'Erreichen Sie tausende Fantatech-Nutzer. Werbeplatz verfügbar.',
      pt: 'Alcance milhares de usuários Fantatech. Este espaço está disponível.',
      am: 'Reach thousands of Fantatech Home users. This ad slot is open.',
    },
    imageUrl: '',
    url: '',
    btnLabel: {
      he: 'צור קשר ›',
      en: 'Contact Us ›',
      ar: 'تواصل معنا ›',
      ru: 'Связаться ›',
      es: 'Contactar ›',
      fr: 'Contacter ›',
      de: 'Kontakt ›',
      pt: 'Contato ›',
      am: 'Contact Us ›',
    },
    color: '#475569',
    active: true,
    sponsored: false,
    placeholder: true,
  },
]

/**
 * Detect if saved ads are old-format (plain Hebrew strings).
 * If so, wipe them and return fresh multilingual defaults.
 */
function isLegacyAds(ads) {
  if (!Array.isArray(ads) || !ads.length) return false
  // Old format: title is a plain Hebrew string (not an object)
  const first = ads[0]
  return typeof first?.title === 'string' && /[֐-׿]/.test(first.title)
}

export function loadAds() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null')
    if (!saved) return DEFAULT_ADS
    // Auto-upgrade: if saved ads are Hebrew-only strings, replace with multilingual defaults
    if (isLegacyAds(saved)) {
      localStorage.removeItem(STORAGE_KEY)
      return DEFAULT_ADS
    }
    return saved
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
        background: color + '22', border: `1px solid ${color}44`,
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

/* ── Single ad card — language-aware ───────────────────────────────────── */
function AdCard({ ad }) {
  const { t, lang } = useLang()

  // Resolve all text fields using the current language
  const title    = loc(ad.title,    lang)
  const desc     = loc(ad.desc,     lang)
  const btnLabel = loc(ad.btnLabel, lang) || (t.details_btn ?? 'Details ›')

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
          <span style={{ fontSize: 12, fontWeight: 700, color: '#f1f5f9' }}>{title}</span>
          {!ad.placeholder && (
            <span style={{
              fontSize: 9, padding: '1px 5px', borderRadius: 4,
              background: '#334155', color: '#64748b', fontWeight: 600,
            }}>{t.sponsored}</span>
          )}
        </div>
        <div style={{ fontSize: 11, color: '#64748b', lineHeight: 1.5, marginBottom: 6 }}>{desc}</div>
        {btnLabel && (
          <span style={{
            display: 'inline-block', padding: '4px 12px', borderRadius: 8,
            background: ad.placeholder ? '#334155' : ad.color,
            color: ad.placeholder ? '#64748b' : '#fff',
            fontSize: 11, fontWeight: 700,
          }}>{btnLabel}</span>
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

  useEffect(() => { setAds(loadAds()) }, [])

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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
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
