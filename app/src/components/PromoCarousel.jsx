import { useState, useRef, useEffect } from 'react'
import { useLang } from '../context/LangContext'

/* ── Product catalogue ─────────────────────────────────────────────────────── */
const PROMOS = [
  {
    id: 'moes-gw',
    icon: '📡',
    imageUrl: 'https://www.moes-smarthome.com/wp-content/uploads/2022/06/ZB-GW04.jpg',
    badge: '🔥 HOT',
    badgeColor: '#ef4444',
    title: 'Moes Multi Gateway',
    subtitle: 'Zigbee 3.0 + BLE + WiFi',
    desc: 'גייטווי כל-בשלושה — שולט על עשרות מכשירי Zigbee, חיישנים ונורות בבית החכם.',
    price: '₪79–120',
    tag: 'Tuya',
    tagColor: '#f59e0b',
    search: 'Moes ZB-GW04 Zigbee Gateway',
    bg: 'linear-gradient(135deg,#1c1007 0%,#1a1200 100%)',
    border: '#f59e0b',
    aff: 'https://www.aliexpress.com/w/wholesale-moes-zigbee-gateway.html',
  },
  {
    id: 'sonoff-basic',
    icon: '🔌',
    imageUrl: 'https://itead.cc/wp-content/uploads/2022/12/BASIC-R4-1.jpg',
    badge: '⚡ פופולרי',
    badgeColor: '#1d4ed8',
    title: 'Sonoff BASIC R4',
    subtitle: 'מפסק WiFi חכם',
    desc: 'מפסק WiFi לחיתוך גחלת — תואם Tasmota, ESPHome, MQTT. הכי נמכר בקטגוריה.',
    price: '₪25–45',
    tag: 'WiFi',
    tagColor: '#22c55e',
    search: 'Sonoff BASIC R4 WiFi switch',
    bg: 'linear-gradient(135deg,#0c1a0c 0%,#0a1f0a 100%)',
    border: '#22c55e',
    aff: 'https://itead.cc/product/sonoff-basic-wifi-smart-switch/',
  },
  {
    id: 'ezviz-cam',
    icon: '📷',
    imageUrl: 'https://image.ezviz.com/upload/product/2022/images/c6cn/01-D.jpg',
    badge: '🛡️ אבטחה',
    badgeColor: '#7c3aed',
    title: 'EZVIZ C6 Pro',
    subtitle: 'מצלמת אבטחה 360°',
    desc: 'מצלמת 4MP עם Pan/Tilt 360°, ראיית לילה, זיהוי תנועה AI וצפייה מכל מקום.',
    price: '₪150–220',
    tag: 'Smart Cam',
    tagColor: '#7c3aed',
    search: 'EZVIZ C6 Pro smart camera',
    bg: 'linear-gradient(135deg,#1a0c2e 0%,#120a22 100%)',
    border: '#7c3aed',
    aff: 'https://www.ezviz.com/product/c6-pro/1284',
  },
  {
    id: 'aqara-motion',
    icon: '👤',
    imageUrl: 'https://www.aqara.com/media/media_gallery/FP2_400x400.webp',
    badge: '🌟 מומלץ',
    badgeColor: '#38bdf8',
    title: 'Aqara Motion Sensor P2',
    subtitle: 'חיישן תנועה + מרחק',
    desc: 'חיישן עם גלאי רדאר mmWave — מזהה נוכחות ברדיוס 7 מטר, תואם HomeKit / Z2M.',
    price: '₪90–140',
    tag: 'Zigbee',
    tagColor: '#38bdf8',
    search: 'Aqara FP2 motion presence sensor',
    bg: 'linear-gradient(135deg,#0c1d29 0%,#0a1722 100%)',
    border: '#38bdf8',
    aff: 'https://www.aqara.com/en/product/presence-sensor-fp2',
  },
  {
    id: 'smart-lock',
    icon: '🔒',
    imageUrl: 'https://images.tuyaeu.com/smart/product-img/B2B/2022/02/17/bcf61fa8-3494-4834-95a6-7a6f3bf35f02.jpg',
    badge: '🏠 אבטחה',
    badgeColor: '#ef4444',
    title: 'Tuya Smart Lock',
    subtitle: 'מנעול טביעת אצבע + קוד + מפתח',
    desc: 'מנעול חכם עם 5 שיטות פתיחה: אצבע, קוד, כרטיס, מפתח ואפליקציה. IP65.',
    price: '₪280–450',
    tag: 'Smart Lock',
    tagColor: '#ef4444',
    search: 'Tuya fingerprint smart lock door',
    bg: 'linear-gradient(135deg,#1c0a0a 0%,#180808 100%)',
    border: '#ef4444',
    aff: 'https://www.aliexpress.com/w/wholesale-tuya-smart-lock-fingerprint.html',
  },
  {
    id: 'tp-link-cam',
    icon: '🎥',
    imageUrl: 'https://static.tp-link.com/upload/product-overview/2022/202209/20220913/C520WS_v1_1_normal_20220913090600r.jpg',
    badge: '💎 פרימיום',
    badgeColor: '#a78bfa',
    title: 'TP-Link Tapo C520WS',
    subtitle: 'מצלמה חיצונית 4K',
    desc: 'מצלמה 4K עמידת מזג אויר, ראיית לילה צבעונית, איתור רכבים + אנשים AI.',
    price: '₪250–380',
    tag: '4K Outdoor',
    tagColor: '#a78bfa',
    search: 'TP-Link Tapo C520WS outdoor camera',
    bg: 'linear-gradient(135deg,#1a1029 0%,#120a20 100%)',
    border: '#a78bfa',
    aff: 'https://www.tp-link.com/en/home-networking/cloud-camera/tapo-c520ws/',
  },
  {
    id: 'shelly-plus',
    icon: '💡',
    imageUrl: 'https://www.shelly.com/en/media/catalog/product/cache/c46e0d65fa10c4e40cf7f5d5c8e54a78/p/l/plus1pm.png',
    badge: '🔧 Pro',
    badgeColor: '#fb923c',
    title: 'Shelly Plus 1PM',
    subtitle: 'מפסק + מד חשמל WiFi',
    desc: 'מפסק WiFi בגודל אגוז עם מדידת צריכת חשמל בזמן אמת. מתחבר ישירות לרשת.',
    price: '₪55–80',
    tag: 'WiFi',
    tagColor: '#fb923c',
    search: 'Shelly Plus 1PM smart switch energy monitor',
    bg: 'linear-gradient(135deg,#1c1007 0%,#160e04 100%)',
    border: '#fb923c',
    aff: 'https://www.shelly.com/en/products/shop/shelly-plus-1-pm',
  },
  {
    id: 'door-sensor',
    icon: '🚪',
    imageUrl: 'https://www.aqara.com/media/media_gallery/Door_and_Window_Sensor_E1_400x400.webp',
    badge: '🔔 חיישן',
    badgeColor: '#22c55e',
    title: 'Aqara Door Sensor E1',
    subtitle: 'חיישן דלת/חלון Zigbee',
    desc: 'חיישן מגנטי קטנטן ל-Zigbee — מתריע בפתיחה/סגירה, סוללה שנה, תואם Z2M.',
    price: '₪35–55',
    tag: 'Zigbee',
    tagColor: '#22c55e',
    search: 'Aqara door window sensor E1 Zigbee',
    bg: 'linear-gradient(135deg,#0c1f0c 0%,#081508 100%)',
    border: '#22c55e',
    aff: 'https://www.aqara.com/en/product/door-and-window-sensor-e1',
  },
  {
    id: 'bulb-rgb',
    icon: '🎨',
    imageUrl: 'https://www.moes-smarthome.com/wp-content/uploads/2021/11/QA67.jpg',
    badge: '🌈 RGB',
    badgeColor: '#ec4899',
    title: 'Moes Zigbee Bulb RGBCW',
    subtitle: 'נורה חכמה 10W צבעונית',
    desc: 'נורה Zigbee 10W עם 16M צבעים + טמפ\' צבע + עמעום. תואמת Fantatech Hub.',
    price: '₪30–55',
    tag: 'Zigbee',
    tagColor: '#ec4899',
    search: 'Moes Zigbee RGBCW smart bulb E27',
    bg: 'linear-gradient(135deg,#1c0a1c 0%,#150815 100%)',
    border: '#ec4899',
    aff: 'https://www.aliexpress.com/w/wholesale-moes-zigbee-bulb-rgbcw.html',
  },
  {
    id: 'smoke-detector',
    icon: '🔥',
    imageUrl: 'https://ae01.alicdn.com/kf/Sc6e8ce65e5234fca9a9f7a3c50c90e2bN.jpg',
    badge: '🆘 בטיחות',
    badgeColor: '#ef4444',
    title: 'Zigbee Smoke Detector',
    subtitle: 'גלאי עשן חכם Zigbee',
    desc: 'גלאי עשן אלקטרוכימי עם התראה קולית 85dB + שליחת התראה לאפליקציה בזמן אמת.',
    price: '₪45–80',
    tag: 'Safety',
    tagColor: '#ef4444',
    search: 'Zigbee smoke detector sensor smart home',
    bg: 'linear-gradient(135deg,#1c0a00 0%,#180800 100%)',
    border: '#ef4444',
    aff: 'https://www.aliexpress.com/w/wholesale-zigbee-smoke-detector.html',
  },
]

/* ── URL builder — prefers affiliate link if set ──────────────────────────── */
function buildUrl(promo) {
  if (promo.aff) return promo.aff
  return `https://www.amazon.com/s?k=${encodeURIComponent(promo.search)}&tag=fantatech-20`
}

/* ── Product image with emoji fallback ───────────────────────────────────── */
function ProductImage({ src, icon, size = 70, radius = 12 }) {
  const [err, setErr] = useState(false)
  return (
    <div style={{
      width: size, height: size, borderRadius: radius,
      background: '#0f172a', flexShrink: 0,
      overflow: 'hidden', display: 'flex',
      alignItems: 'center', justifyContent: 'center',
    }}>
      {err || !src
        ? <span style={{ fontSize: size * 0.5 }}>{icon}</span>
        : <img
            src={src} alt=""
            onError={() => setErr(true)}
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />
      }
    </div>
  )
}

/* ── Main component ─────────────────────────────────────────────────────── */
export default function PromoCarousel() {
  const { t } = useLang()
  const [active, setActive] = useState(0)
  const [dismissed, setDismissed] = useState(
    () => localStorage.getItem('promo_dismissed') === '1'
  )
  const [expanded, setExpanded] = useState(false)
  const scrollRef = useRef(null)
  const autoRef   = useRef(null)

  useEffect(() => {
    if (dismissed) return
    autoRef.current = setInterval(() => {
      setActive(p => (p + 1) % PROMOS.length)
    }, 5000)
    return () => clearInterval(autoRef.current)
  }, [dismissed])

  useEffect(() => {
    if (!scrollRef.current) return
    const card = scrollRef.current.children[active]
    if (card) card.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' })
  }, [active])

  const dismiss = () => {
    setDismissed(true)
    localStorage.setItem('promo_dismissed', '1')
  }
  const restore = () => {
    setDismissed(false)
    localStorage.removeItem('promo_dismissed')
  }

  if (dismissed) {
    return (
      <div style={{ textAlign: 'center', marginBottom: 16 }}>
        <button onClick={restore} style={{
          background: 'none', border: '1px solid #334155', borderRadius: 8,
          color: '#475569', fontSize: 11, cursor: 'pointer', padding: '4px 12px',
        }}>
          {t.show_recommendations}
        </button>
      </div>
    )
  }

  const p = PROMOS[active]

  return (
    <div style={{ marginBottom: 24 }}>
      {/* Section title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <h3 style={{ margin: 0, fontSize: 14, color: '#e2e8f0' }}>{t.recommended_products}</h3>
        <div style={{ display: 'flex', gap: 6 }}>
          <button onClick={() => setExpanded(!expanded)} style={{
            background: 'none', border: '1px solid #334155', borderRadius: 6,
            color: '#64748b', fontSize: 11, cursor: 'pointer', padding: '3px 8px',
          }}>
            {expanded ? t.show_less : t.show_all}
          </button>
          <button onClick={dismiss} style={{
            background: 'none', border: 'none', color: '#334155',
            fontSize: 16, cursor: 'pointer', lineHeight: 1, padding: '0 2px',
          }} title="הסתר">✕</button>
        </div>
      </div>

      {/* ── Carousel (default view) ── */}
      {!expanded && (
        <>
          {/* Featured card */}
          <a
            href={buildUrl(p)}
            target="_blank"
            rel="noreferrer"
            style={{ textDecoration: 'none', display: 'block' }}
          >
            <div style={{
              background: p.bg,
              border: `1px solid ${p.border}`,
              borderRadius: 16, padding: '14px 16px', marginBottom: 10,
              position: 'relative', overflow: 'hidden',
              transition: 'all 0.4s',
            }}>
              {/* Glow */}
              <div style={{
                position: 'absolute', top: -30, right: -30,
                width: 100, height: 100, borderRadius: '50%',
                background: p.border + '22', filter: 'blur(20px)',
                pointerEvents: 'none',
              }} />

              {/* Badge */}
              <span style={{
                position: 'absolute', top: 10, left: 10,
                fontSize: 10, fontWeight: 700, padding: '2px 8px',
                borderRadius: 20, background: p.badgeColor + '33',
                border: `1px solid ${p.badgeColor}`, color: p.badgeColor,
              }}>{p.badge}</span>

              <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
                <ProductImage src={p.imageUrl} icon={p.icon} size={80} radius={12} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 700, fontSize: 14, color: '#f1f5f9', marginBottom: 2 }}>{p.title}</div>
                  <div style={{ fontSize: 11, color: p.border, marginBottom: 6, fontWeight: 600 }}>{p.subtitle}</div>
                  <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.6, marginBottom: 10 }}>{p.desc}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{
                      fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 20,
                      background: p.tagColor + '22', border: `1px solid ${p.tagColor}`, color: p.tagColor,
                    }}>{p.tag}</span>
                    <span style={{ fontSize: 13, fontWeight: 800, color: '#22c55e' }}>{p.price}</span>
                    <span style={{
                      marginRight: 'auto', padding: '5px 14px', borderRadius: 8,
                      background: p.border, color: '#fff', fontWeight: 700,
                      fontSize: 12, flexShrink: 0,
                    }}>
                      {t.buy_now}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </a>

          {/* Thumbnail strip */}
          <div ref={scrollRef} style={{
            display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 4,
            scrollbarWidth: 'none',
          }}>
            {PROMOS.map((item, i) => (
              <button key={item.id} onClick={() => {
                clearInterval(autoRef.current)
                setActive(i)
              }} style={{
                flexShrink: 0, width: 52, height: 52, borderRadius: 12, padding: 0,
                border: `2px solid ${i === active ? item.border : '#334155'}`,
                background: '#0f172a',
                cursor: 'pointer', overflow: 'hidden',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'all .2s',
              }}>
                <ProductImage src={item.imageUrl} icon={item.icon} size={50} radius={10} />
              </button>
            ))}
          </div>
        </>
      )}

      {/* ── Expanded grid ── */}
      {expanded && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {PROMOS.map((item) => (
            <a key={item.id} href={buildUrl(item)} target="_blank" rel="noreferrer"
              style={{
                background: item.bg, border: `1px solid ${item.border}`,
                borderRadius: 14, padding: 12, textDecoration: 'none',
                display: 'flex', flexDirection: 'column', gap: 6,
              }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <ProductImage src={item.imageUrl} icon={item.icon} size={44} radius={8} />
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: '#f1f5f9', lineHeight: 1.3 }}>{item.title}</div>
                  <div style={{ fontSize: 10, color: item.border }}>{item.subtitle}</div>
                </div>
              </div>
              <div style={{ fontSize: 10, color: '#64748b', lineHeight: 1.5 }}>{item.desc}</div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 2 }}>
                <span style={{ fontSize: 12, fontWeight: 700, color: '#22c55e' }}>{item.price}</span>
                <span style={{
                  fontSize: 9, fontWeight: 700, padding: '2px 6px', borderRadius: 20,
                  background: item.tagColor + '22', border: `1px solid ${item.tagColor}`, color: item.tagColor,
                }}>{item.tag}</span>
              </div>
            </a>
          ))}
        </div>
      )}
    </div>
  )
}
