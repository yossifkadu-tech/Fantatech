/**
 * RotatingAdBanner — auto-cycling promotional banner.
 *
 * Cycles through ADS_POOL every INTERVAL ms with a smooth fade transition.
 * Place anywhere: Dashboard widget, sticky bottom strip, sidebar card.
 *
 * Props:
 *   variant  — 'strip'  (thin horizontal bar, default)
 *              'card'   (tall card for Dashboard)
 *   onShop   — called with ad item when user taps CTA
 */
import { useState, useEffect, useRef } from 'react'
import { useLang } from '../context/LangContext'
import { STORE_URL } from '../pages/StorePage'

/* ── Ad pool — mix of own products + affiliate ─────────────────────── */
export const ADS_POOL = [
  // FantaTech own products
  { id: 'ft1', img: '/products/led-strip.svg',    nameHe: 'FantaGlow Strip 5m',     nameEn: 'FantaGlow Strip 5m',    price: '₪129', oldPrice: '₪179', labelHe: '🔥 מבצע', labelEn: '🔥 Sale',  url: STORE_URL + '/products', own: true },
  { id: 'ft2', img: '/products/camera.svg',       nameHe: 'FantaCam Pro 2K',         nameEn: 'FantaCam Pro 2K',       price: '₪479', oldPrice: '₪589', labelHe: '✨ חדש',  labelEn: '✨ New',   url: STORE_URL + '/products', own: true },
  { id: 'ft3', img: '/products/lock.svg',         nameHe: 'FantaLock Touch',         nameEn: 'FantaLock Touch',       price: '₪729', oldPrice: null,    labelHe: '⭐ פופולרי', labelEn: '⭐ Top', url: STORE_URL + '/products', own: true },
  { id: 'ft4', img: '/products/starter-kit.svg',  nameHe: 'חבילת התחלה',            nameEn: 'Starter Bundle',        price: '₪899', oldPrice: '₪1,189', labelHe: '🎁 חבילה', labelEn: '🎁 Bundle', url: STORE_URL + '/clearance', own: true },
  { id: 'ft5', img: '/products/thermostat.svg',   nameHe: 'FantaClime Thermostat',   nameEn: 'FantaClime Thermostat', price: '₪439', oldPrice: null,    labelHe: '🌡️ חכם', labelEn: '🌡️ Smart', url: STORE_URL + '/products', own: true },
  { id: 'ft6', img: '/products/panel.svg',        nameHe: 'FantaPanel 7"',           nameEn: 'FantaPanel 7"',         price: '₪729', oldPrice: null,    labelHe: '✨ חדש',  labelEn: '✨ New',   url: STORE_URL + '/products', own: true },
  { id: 'ft7', img: '/products/camera.svg',       nameHe: 'FantaCam Indoor — מבצע', nameEn: 'FantaCam Indoor Sale',  price: '₪169', oldPrice: '₪289', labelHe: '🔥 −43%', labelEn: '🔥 −43%', url: STORE_URL + '/clearance', own: true },
  // Affiliate products
  { id: 'af1', img: null, emoji: '🔌', nameHe: 'Sonoff Mini R2',         nameEn: 'Sonoff Mini R2',       price: '₪45',  oldPrice: null, labelHe: '🤝 שותף', labelEn: '🤝 Partner', url: 'https://www.amazon.co.il/s?k=sonoff+mini+r2', own: false },
  { id: 'af2', img: null, emoji: '🔌', nameHe: 'Shelly 1 — מפסק חכם',  nameEn: 'Shelly 1 Smart Switch', price: '₪55',  oldPrice: null, labelHe: '🤝 שותף', labelEn: '🤝 Partner', url: 'https://www.amazon.co.il/s?k=shelly+1', own: false },
  { id: 'af3', img: null, emoji: '👤', nameHe: 'Aqara חיישן תנועה',     nameEn: 'Aqara Motion Sensor',   price: '₪69',  oldPrice: null, labelHe: '🤝 שותף', labelEn: '🤝 Partner', url: 'https://www.amazon.co.il/s?k=aqara+motion', own: false },
  { id: 'af4', img: null, emoji: '❄️', nameHe: 'Sensibo Sky — מזגן חכם', nameEn: 'Sensibo Sky',          price: '₪199', oldPrice: null, labelHe: '🤝 שותף', labelEn: '🤝 Partner', url: 'https://www.amazon.co.il/s?k=sensibo+sky', own: false },
  { id: 'af5', img: null, emoji: '📷', nameHe: 'Reolink 4K מצלמה',      nameEn: 'Reolink 4K Camera',     price: '₪299', oldPrice: null, labelHe: '🤝 שותף', labelEn: '🤝 Partner', url: 'https://www.amazon.co.il/s?k=reolink+4k', own: false },
]

const INTERVAL = 5000   // ms between slides
const FADE_MS  = 350    // fade transition duration

export default function RotatingAdBanner({ variant = 'strip', onShop, dismissKey }) {
  const { lang, rtl } = useLang()
  const isHe = lang === 'he'

  const [idx,     setIdx]     = useState(0)
  const [visible, setVisible] = useState(true)   // fade state
  const [shown,   setShown]   = useState(true)   // dismissed?
  const timerRef = useRef(null)

  /* dismiss persisted per key */
  useEffect(() => {
    if (dismissKey && localStorage.getItem(`ft_ad_dismissed_${dismissKey}`)) {
      setShown(false)
    }
  }, [dismissKey])

  /* auto-advance */
  useEffect(() => {
    if (!shown) return
    timerRef.current = setInterval(() => {
      setVisible(false)
      setTimeout(() => {
        setIdx(i => (i + 1) % ADS_POOL.length)
        setVisible(true)
      }, FADE_MS)
    }, INTERVAL)
    return () => clearInterval(timerRef.current)
  }, [shown])

  const dismiss = () => {
    setShown(false)
    if (dismissKey) localStorage.setItem(`ft_ad_dismissed_${dismissKey}`, '1')
  }

  const handleShop = (ad) => {
    window.open(ad.url, '_blank', 'noopener')
    onShop?.(ad)
  }

  if (!shown) return null

  const ad = ADS_POOL[idx]
  const name = isHe ? ad.nameHe : ad.nameEn
  const label = isHe ? ad.labelHe : ad.labelEn

  /* ── dot indicator ── */
  const Dots = () => (
    <div style={{ display: 'flex', gap: 3, alignItems: 'center', flexShrink: 0 }}>
      {ADS_POOL.map((_, i) => (
        <div key={i} onClick={() => { clearInterval(timerRef.current); setVisible(false); setTimeout(() => { setIdx(i); setVisible(true) }, FADE_MS) }}
          style={{
            width: i === idx ? 12 : 5, height: 5, borderRadius: 3,
            background: i === idx ? '#38bdf8' : '#334155',
            transition: 'all 0.3s', cursor: 'pointer',
          }} />
      ))}
    </div>
  )

  /* ════════════ STRIP variant ════════════ */
  if (variant === 'strip') {
    return (
      <div style={{
        background: ad.own
          ? 'linear-gradient(90deg,#1d1b6e,#1d4ed8)'
          : 'linear-gradient(90deg,#14532d,#166534)',
        borderTop: `1px solid ${ad.own ? '#3b82f6' : '#22c55e'}`,
        padding: '7px 12px',
        display: 'flex', alignItems: 'center', gap: 10,
        direction: rtl ? 'rtl' : 'ltr',
        opacity: visible ? 1 : 0,
        transition: `opacity ${FADE_MS}ms ease`,
        position: 'relative',
      }}>
        {/* Image / emoji */}
        {ad.img
          ? <img src={ad.img} alt={name} style={{ width: 28, height: 28, objectFit: 'contain', flexShrink: 0 }} />
          : <span style={{ fontSize: 22, flexShrink: 0 }}>{ad.emoji}</span>
        }

        {/* Text */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            <span style={{ fontSize: 9, fontWeight: 800, background: 'rgba(255,255,255,0.15)', borderRadius: 4, padding: '1px 5px', color: '#fff' }}>
              {label}
            </span>
            <span style={{ fontSize: 11, fontWeight: 800, color: '#fff', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 140 }}>
              {name}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 13, fontWeight: 900, color: '#38bdf8' }}>{ad.price}</span>
            {ad.oldPrice && <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.4)', textDecoration: 'line-through' }}>{ad.oldPrice}</span>}
          </div>
        </div>

        <Dots />

        {/* CTA */}
        <button onClick={() => handleShop(ad)} style={{
          padding: '5px 10px', borderRadius: 8, border: 'none', flexShrink: 0,
          background: '#fff', color: ad.own ? '#1d4ed8' : '#166534',
          fontWeight: 800, fontSize: 10, cursor: 'pointer',
          WebkitTapHighlightColor: 'transparent',
        }}>
          {isHe ? 'קנה' : 'Buy'}
        </button>

        {/* dismiss */}
        <button onClick={dismiss} style={{
          background: 'none', border: 'none', color: 'rgba(255,255,255,0.4)',
          fontSize: 14, cursor: 'pointer', flexShrink: 0, lineHeight: 1, padding: 2,
        }}>✕</button>
      </div>
    )
  }

  /* ════════════ CARD variant (Dashboard) ════════════ */
  return (
    <div style={{
      background: ad.own
        ? 'linear-gradient(135deg,#1d1b6e,#1e3a8a)'
        : 'linear-gradient(135deg,#14532d,#166534)',
      borderRadius: 18,
      border: `1px solid ${ad.own ? '#3b82f6' : '#22c55e'}`,
      padding: '14px 14px 12px',
      direction: rtl ? 'rtl' : 'ltr',
      opacity: visible ? 1 : 0,
      transition: `opacity ${FADE_MS}ms ease`,
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* dismiss */}
      <button onClick={dismiss} style={{
        position: 'absolute', top: 8, insetInlineEnd: 10,
        background: 'rgba(255,255,255,0.1)', border: 'none',
        borderRadius: 6, color: 'rgba(255,255,255,0.6)',
        fontSize: 12, cursor: 'pointer', padding: '1px 6px', lineHeight: 1.5,
      }}>✕</button>

      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        {/* Image */}
        <div style={{ width: 56, height: 56, flexShrink: 0, background: 'rgba(255,255,255,0.08)', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {ad.img
            ? <img src={ad.img} alt={name} style={{ width: 44, height: 44, objectFit: 'contain' }} />
            : <span style={{ fontSize: 32 }}>{ad.emoji}</span>
          }
        </div>

        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 9, fontWeight: 800, color: 'rgba(255,255,255,0.6)', marginBottom: 2, textTransform: 'uppercase', letterSpacing: 0.5 }}>
            {label}
          </div>
          <div style={{ fontSize: 13, fontWeight: 800, color: '#fff', lineHeight: 1.3, marginBottom: 3 }}>{name}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 16, fontWeight: 900, color: '#38bdf8' }}>{ad.price}</span>
            {ad.oldPrice && <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.35)', textDecoration: 'line-through' }}>{ad.oldPrice}</span>}
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 12 }}>
        <Dots />
        <button onClick={() => handleShop(ad)} style={{
          padding: '7px 18px', borderRadius: 10, border: 'none',
          background: '#fff', color: ad.own ? '#1d4ed8' : '#166534',
          fontWeight: 800, fontSize: 12, cursor: 'pointer',
          WebkitTapHighlightColor: 'transparent',
        }}>
          {isHe ? '🛒 לרכישה' : '🛒 Buy Now'}
        </button>
      </div>
    </div>
  )
}
