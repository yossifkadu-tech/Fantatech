/**
 * StorePage — FantaTech product catalogue.
 *
 * Replace STORE_URL with your actual website URL.
 * Products can be fetched from API by swapping PRODUCTS with an API call.
 */
import { useState, useMemo } from 'react'
import { useLang } from '../context/LangContext'
import { useScale } from '../context/ScaleContext'

/* ── Your website URL ─────────────────────────────────────────────────── */
export const STORE_URL = 'https://fantatech.co.il'

/* ── Product catalogue (replace or extend as needed) ─────────────────── */
const PRODUCTS = [
  {
    id: 1, category: 'תאורה',
    emoji: '💡', name: 'Smart Bulb Pro', nameHe: 'נורה חכמה פרו',
    price: '₪79', oldPrice: '₪99',
    desc: 'נורה חכמה 16M צבעים, 1000 lumen, WiFi, תואמת Alexa & Google',
    badge: 'bestseller', stars: 5,
    slug: '/products/smart-bulb-pro',
  },
  {
    id: 2, category: 'שליטה',
    emoji: '🔌', name: 'Smart Plug 16A', nameHe: 'שקע חכם 16A',
    price: '₪49',
    desc: 'שקע חכם עם מד צריכת חשמל, לוח זמנים, שליטה מרחוק',
    badge: null, stars: 4,
    slug: '/products/smart-plug-16a',
  },
  {
    id: 3, category: 'אקלים',
    emoji: '❄️', name: 'AC Smart Controller', nameHe: 'שלט מזגן חכם',
    price: '₪149', oldPrice: '₪199',
    desc: 'הפוך כל מזגן לחכם — שליטה מהאפליקציה, תזמון אוטומטי',
    badge: 'sale', stars: 5,
    slug: '/products/ac-smart-controller',
  },
  {
    id: 4, category: 'אבטחה',
    emoji: '📷', name: 'Fanta Cam 2K', nameHe: 'מצלמה Fanta Cam 2K',
    price: '₪249',
    desc: 'מצלמת אבטחה 2K, ראיית לילה, זיהוי תנועה, אחסון ענן',
    badge: 'new', stars: 4,
    slug: '/products/fanta-cam-2k',
  },
  {
    id: 5, category: 'אבטחה',
    emoji: '🔒', name: 'Smart Lock Pro', nameHe: 'מנעול חכם פרו',
    price: '₪399',
    desc: 'מנעול חכם טביעת אצבע + קוד + אפליקציה, ספריה Z-Wave',
    badge: null, stars: 5,
    slug: '/products/smart-lock-pro',
  },
  {
    id: 6, category: 'חיישנים',
    emoji: '🌡️', name: 'Temp & Humidity Sensor', nameHe: 'חיישן טמפ׳ ולחות',
    price: '₪39',
    desc: 'חיישן טמפרטורה ולחות Zigbee, דיוק ±0.3°C, סוללה 2 שנה',
    badge: null, stars: 4,
    slug: '/products/temp-humidity-sensor',
  },
  {
    id: 7, category: '허브',
    emoji: '🏠', name: 'FantaHub Pro', nameHe: 'FantaHub פרו',
    price: '₪349', oldPrice: '₪449',
    desc: 'הרכזת הביתית של FantaTech — WiFi, Zigbee, Z-Wave, BT, LAN',
    badge: 'bestseller', stars: 5,
    slug: '/products/fantahub-pro',
  },
  {
    id: 8, category: 'תאורה',
    emoji: '🔆', name: 'Smart Dimmer Switch', nameHe: 'מפסק עמעום חכם',
    price: '₪89',
    desc: 'מפסק עמעום חכם 3 כנופיות, תמיכת LED, WiFi + מגע',
    badge: null, stars: 4,
    slug: '/products/smart-dimmer',
  },
  {
    id: 9, category: 'חיישנים',
    emoji: '👤', name: 'Motion Sensor PIR', nameHe: 'חיישן תנועה PIR',
    price: '₪29',
    desc: 'חיישן תנועה PIR Zigbee, זווית 120°, טווח 8 מטר, סוללה 18 חודש',
    badge: 'sale', stars: 4,
    slug: '/products/motion-sensor',
  },
  {
    id: 10, category: 'חבילות',
    emoji: '🎁', name: 'Starter Kit', nameHe: 'ערכת פתיחה',
    price: '₪499', oldPrice: '₪699',
    desc: 'הכל בחבילה אחת: FantaHub + 3 נורות + 2 שקעים + חיישן תנועה',
    badge: 'hot', stars: 5,
    slug: '/products/starter-kit',
  },
]

const CATEGORIES = ['הכל', ...Array.from(new Set(PRODUCTS.map(p => p.category)))]

const BADGE_STYLE = {
  bestseller: { bg: '#1d4ed8', label: '⭐ נמכר ביותר' },
  sale:       { bg: '#dc2626', label: '🔥 מבצע' },
  new:        { bg: '#059669', label: '✨ חדש' },
  hot:        { bg: '#d97706', label: '🔥 חם' },
}

function Stars({ count }) {
  return (
    <div style={{ display: 'flex', gap: 1 }}>
      {[1,2,3,4,5].map(i => (
        <span key={i} style={{ fontSize: 10, color: i <= count ? '#fbbf24' : '#334155' }}>★</span>
      ))}
    </div>
  )
}

function ProductCard({ product, lang, phone, onBuy }) {
  const isHe = lang === 'he'
  const name = isHe ? product.nameHe : product.name
  const badge = product.badge ? BADGE_STYLE[product.badge] : null

  return (
    <div style={{
      background: '#1e293b', borderRadius: 16,
      border: '1px solid #334155', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      transition: 'border-color 0.2s',
    }}>
      {/* Image area */}
      <div style={{
        background: 'linear-gradient(135deg,#0f172a,#1e3a5f)',
        padding: '20px 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', minHeight: 90,
      }}>
        <span style={{ fontSize: 44 }}>{product.emoji}</span>
        {badge && (
          <div style={{
            position: 'absolute', top: 8, insetInlineStart: 8,
            background: badge.bg, borderRadius: 8,
            padding: '2px 8px', fontSize: 9, fontWeight: 800, color: '#fff',
          }}>
            {badge.label}
          </div>
        )}
      </div>

      {/* Info */}
      <div style={{ padding: '12px 12px 14px', flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
        <div style={{ fontSize: 12, color: '#64748b', fontWeight: 600 }}>{product.category}</div>
        <div style={{ fontSize: 14, fontWeight: 800, color: '#f1f5f9', lineHeight: 1.3 }}>{name}</div>
        <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.5, flex: 1 }}>{product.desc}</div>

        <Stars count={product.stars} />

        {/* Price */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 18, fontWeight: 900, color: '#38bdf8' }}>{product.price}</span>
          {product.oldPrice && (
            <span style={{ fontSize: 12, color: '#475569', textDecoration: 'line-through' }}>{product.oldPrice}</span>
          )}
        </div>

        <button
          onClick={() => onBuy(product)}
          style={{
            width: '100%', padding: '9px 0', borderRadius: 10, border: 'none',
            background: 'linear-gradient(135deg,#1d4ed8,#3b82f6)',
            color: '#fff', fontWeight: 800, fontSize: 13, cursor: 'pointer',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          {isHe ? '🛒 לרכישה' : '🛒 Buy Now'}
        </button>
      </div>
    </div>
  )
}

export default function StorePage() {
  const { t, lang, rtl } = useLang()
  const { phone, tablet } = useScale()
  const isHe = lang === 'he'
  const [category, setCategory] = useState('הכל')
  const [search, setSearch]     = useState('')

  const filtered = useMemo(() => {
    let list = category === 'הכל' ? PRODUCTS : PRODUCTS.filter(p => p.category === category)
    if (search.trim()) {
      const q = search.toLowerCase()
      list = list.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.nameHe.includes(q) ||
        p.category.includes(q) ||
        p.desc.includes(q)
      )
    }
    return list
  }, [category, search])

  const cols = tablet ? 3 : phone ? 2 : 4

  const openProduct = (product) => {
    window.open(STORE_URL + product.slug, '_blank', 'noopener')
  }

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>

      {/* Hero banner */}
      <div style={{
        background: 'linear-gradient(135deg,#1d1b6e,#1d4ed8,#0ea5e9)',
        borderRadius: 20, padding: '20px 20px 24px',
        marginBottom: 20, textAlign: 'center',
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{ fontSize: 36, marginBottom: 8 }}>🏠</div>
        <div style={{ fontSize: 20, fontWeight: 900, color: '#fff', marginBottom: 6 }}>
          {isHe ? 'חנות FantaTech' : 'FantaTech Store'}
        </div>
        <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.75)', marginBottom: 14 }}>
          {isHe ? 'מוצרי בית חכם מהמותג שלנו — במחירים מיוחדים לאפליקציה' : 'Smart home products — exclusive app prices'}
        </div>
        <button
          onClick={() => window.open(STORE_URL, '_blank', 'noopener')}
          style={{
            padding: '10px 24px', borderRadius: 12, border: '2px solid rgba(255,255,255,0.3)',
            background: 'rgba(255,255,255,0.15)', color: '#fff',
            fontWeight: 800, fontSize: 13, cursor: 'pointer', backdropFilter: 'blur(4px)',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          {isHe ? '🌐 לאתר המלא' : '🌐 Visit Website'}
        </button>
      </div>

      {/* Search */}
      <div style={{ marginBottom: 14 }}>
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder={isHe ? '🔍 חיפוש מוצר...' : '🔍 Search products...'}
          style={{
            width: '100%', padding: '10px 14px', borderRadius: 12,
            background: '#1e293b', border: '1px solid #334155',
            color: '#f1f5f9', fontSize: 13, outline: 'none',
            direction: rtl ? 'rtl' : 'ltr',
            boxSizing: 'border-box',
          }}
        />
      </div>

      {/* Category filter */}
      <div style={{
        display: 'flex', gap: 8, marginBottom: 18,
        overflowX: 'auto', paddingBottom: 4,
      }}>
        {CATEGORIES.map(cat => (
          <button key={cat} onClick={() => setCategory(cat)} style={{
            padding: '6px 14px', borderRadius: 20, border: 'none', flexShrink: 0,
            background: category === cat ? '#1d4ed8' : '#1e293b',
            color: category === cat ? '#fff' : '#64748b',
            fontSize: 12, fontWeight: 700, cursor: 'pointer',
            border: `1px solid ${category === cat ? '#3b82f6' : '#334155'}`,
            WebkitTapHighlightColor: 'transparent',
          }}>
            {cat}
          </button>
        ))}
      </div>

      {/* Result count */}
      <div style={{ fontSize: 12, color: '#475569', marginBottom: 12 }}>
        {isHe ? `${filtered.length} מוצרים` : `${filtered.length} products`}
      </div>

      {/* Product grid */}
      {filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: '#475569' }}>
          <div style={{ fontSize: 40 }}>🔍</div>
          <div style={{ marginTop: 12, fontSize: 14 }}>{isHe ? 'לא נמצאו מוצרים' : 'No products found'}</div>
        </div>
      ) : (
        <div style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${cols}, 1fr)`,
          gap: 12,
        }}>
          {filtered.map(product => (
            <ProductCard
              key={product.id}
              product={product}
              lang={lang}
              phone={phone}
              onBuy={openProduct}
            />
          ))}
        </div>
      )}

      {/* Footer link */}
      <div style={{ marginTop: 24, textAlign: 'center', paddingBottom: 8 }}>
        <button
          onClick={() => window.open(STORE_URL, '_blank', 'noopener')}
          style={{
            background: 'none', border: 'none', color: '#38bdf8',
            fontSize: 12, cursor: 'pointer', fontWeight: 700,
            textDecoration: 'underline',
          }}
        >
          {isHe ? 'לאתר fantatech.co.il ←' : '← fantatech.co.il'}
        </button>
      </div>
    </div>
  )
}
