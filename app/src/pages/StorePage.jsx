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

/* ── Real product catalogue from fantatech.co.il ─────────────────────── */
const PRODUCTS = [
  {
    id: 1, category: 'אבטחה',
    img: '/products/camera.svg', name: 'FantaCam Pro 2K', nameHe: 'FantaCam Pro 2K',
    price: '₪479', oldPrice: '₪589', off: '−19%',
    desc: 'מצלמה חיצונית עם ראיית לילה צבעונית וזיהוי AI של אנשים וחבילות.',
    badge: 'new', stars: 4.7, reviews: 612,
    slug: '/products',
  },
  {
    id: 2, category: 'אבטחה',
    img: '/products/doorbell.svg', name: 'FantaBell Video Doorbell', nameHe: 'FantaBell Video Doorbell',
    price: '₪549',
    desc: 'שיחה דו־כיוונית, ראייה מהראש לרגליים, שמירה על חבילות.',
    badge: null, stars: 4.5, reviews: 389,
    slug: '/products',
  },
  {
    id: 3, category: 'אבטחה',
    img: '/products/alarm-hub.svg', name: 'FantaGuard Alarm Hub', nameHe: 'FantaGuard Alarm Hub',
    price: '₪699',
    desc: 'המוח של הבית — סירנות, חיישנים ומעקב מקצועי לבחירה.',
    badge: null, stars: 4.6, reviews: 214,
    slug: '/products',
  },
  {
    id: 4, category: 'מנעולים',
    img: '/products/lock.svg', name: 'FantaLock Touch', nameHe: 'FantaLock Touch',
    price: '₪729',
    desc: 'טביעת אצבע, קוד, אפליקציה ומפתח — ארבע דרכי כניסה. תומך ב־Matter.',
    badge: null, stars: 4.8, reviews: 429,
    slug: '/products',
  },
  {
    id: 5, category: 'מנעולים',
    img: '/products/lock-retrofit.svg', name: 'FantaLock Retrofit', nameHe: 'FantaLock Retrofit',
    price: '₪479', oldPrice: '₪549', off: '−13%',
    desc: 'הופך את המנעול הקיים לחכם תוך 10 דקות — בלי החלפת מפתח.',
    badge: null, stars: 4.6, reviews: 278,
    slug: '/products',
  },
  {
    id: 6, category: 'תאורה',
    img: '/products/led-strip.svg', name: 'FantaGlow Strip 5m', nameHe: 'FantaGlow Strip 5m',
    price: '₪129', oldPrice: '₪179', off: '−28%',
    desc: 'רצועת LED עם 16 מיליון צבעים, סנכרון מוזיקה ומצב חוץ.',
    badge: 'hot', stars: 4.6, reviews: 1284,
    slug: '/products',
  },
  {
    id: 7, category: 'תאורה',
    img: '/products/bulb.svg', name: 'FantaBulb E27 (4-pack)', nameHe: 'FantaBulb E27 (4-pack)',
    price: '₪169',
    desc: 'נורות לבנות מתכווננות — ארוחות חמות, בקרים פוקוסים.',
    badge: null, stars: 4.5, reviews: 968,
    slug: '/products',
  },
  {
    id: 8, category: 'אקלים',
    img: '/products/thermostat.svg', name: 'FantaClime Thermostat', nameHe: 'FantaClime Thermostat',
    price: '₪439',
    desc: 'לומד את השגרה וחוסך עד 23% מחשבונות החימום.',
    badge: null, stars: 4.7, reviews: 356,
    slug: '/products',
  },
  {
    id: 9, category: 'אקלים',
    img: '/products/purifier.svg', name: 'FantaAir Mini Purifier', nameHe: 'FantaAir Mini Purifier',
    price: '₪289',
    desc: 'פילטר HEPA-13, שקט כמעט מוחלט בלילה, מצב אלרגיות.',
    badge: null, stars: 4.4, reviews: 512,
    slug: '/products',
  },
  {
    id: 10, category: 'חיישנים',
    img: '/products/motion.svg', name: 'FantaSense Motion 3-pack', nameHe: 'FantaSense Motion 3-pack',
    price: '₪179',
    desc: 'חיישן ידידותי לחיות מחמד, שנתיים על סוללת מטבע, Matter על Thread.',
    badge: 'new', stars: 4.7, reviews: 187,
    slug: '/products',
  },
  {
    id: 11, category: 'חיישנים',
    img: '/products/leak.svg', name: 'FantaSense Leak Detector', nameHe: 'FantaSense Leak Detector',
    price: '₪89',
    desc: 'מזהה דליפה איטית לפני שהרצפה נהרסת.',
    badge: null, stars: 4.8, reviews: 801,
    slug: '/products',
  },
  {
    id: 12, category: 'חיישנים',
    img: '/products/smoke.svg', name: 'FantaSense Smoke', nameHe: 'FantaSense Smoke',
    price: '₪239',
    desc: 'גלאי עשן פוטו-אלקטרי עם חיבור חכם — כל הגלאים מתריעים יחד.',
    badge: null, stars: 4.5, reviews: 143,
    slug: '/products',
  },
  {
    id: 13, category: 'חיישנים',
    img: '/products/climate-sensor.svg', name: 'FantaSense Climate', nameHe: 'FantaSense Climate',
    price: '₪89',
    desc: 'חיישן זעיר לטמפרטורה ולחות עם תצוגת דיו אלקטרוני. סוללה לשנתיים.',
    badge: null, stars: 4.6, reviews: 220,
    slug: '/products',
  },
  {
    id: 14, category: 'אודיו',
    img: '/products/speaker.svg', name: 'FantaSound Mini', nameHe: 'FantaSound Mini',
    price: '₪329',
    desc: 'צליל שממלא חדר, שליטה בקול, סנכרון רב־חדרי.',
    badge: null, stars: 4.5, reviews: 643,
    slug: '/products',
  },
  {
    id: 15, category: 'מפסקים',
    img: '/products/switch.svg', name: 'FantaSwitch Solo', nameHe: 'FantaSwitch Solo',
    price: '₪129',
    desc: 'להחליף כל מפסק קיר — מגע, קול או אפליקציה. עובד גם בלי חוט אפס.',
    badge: 'new', stars: 4.5, reviews: 98,
    slug: '/products',
  },
  {
    id: 16, category: 'שקעים',
    img: '/products/socket-wall.svg', name: 'FantaPlug Wall', nameHe: 'FantaPlug Wall',
    price: '₪89',
    desc: 'שקע קיר חכם עם USB-A ו-USB-C. תזמונים, מעקב צריכה, נעילת ילדים.',
    badge: 'new', stars: 4.4, reviews: 75,
    slug: '/products',
  },
  {
    id: 17, category: 'לוח בקרה',
    img: '/products/panel.svg', name: 'FantaPanel 7"', nameHe: 'FantaPanel 7"',
    price: '₪729',
    desc: 'מסך מגע זכוכית 7 אינץ׳ שמפעיל את כל הבית. הזנת PoE או USB-C, התקנה על הקיר.',
    badge: 'new', stars: 4.7, reviews: 52,
    slug: '/products',
  },
  {
    id: 18, category: 'מבצע',
    img: '/products/camera.svg', name: 'FantaCam Indoor 1080p', nameHe: 'FantaCam Indoor 1080p',
    price: '₪169', oldPrice: '₪289', off: '−43%',
    desc: 'מצלמת פנים קומפקטית עם תריס פרטיות והתראות לחיות מחמד.',
    badge: 'sale', stars: 4.4, reviews: 892,
    slug: '/clearance',
  },
  {
    id: 19, category: 'מבצע',
    img: '/products/plug.svg', name: 'FantaPlug Mini (3-pack)', nameHe: 'FantaPlug Mini (3-pack)',
    price: '₪119', oldPrice: '₪189', off: '−36%',
    desc: 'שקעים חכמים עם מעקב צריכה — חבילה של שלושה.',
    badge: 'sale', stars: 4.6, reviews: 1532,
    slug: '/clearance',
  },
  {
    id: 20, category: 'מבצע',
    img: '/products/starter-kit.svg', name: 'Starter Bundle', nameHe: 'חבילת התחלה',
    price: '₪899', oldPrice: '₪1,189', off: '−24%',
    desc: 'מצלמה + מנעול + מרכזת — חיסכון של 15% על הכל יחד.',
    badge: 'hot', stars: 4.9, reviews: 341,
    slug: '/clearance',
  },
]

const CATEGORIES = ['הכל', 'מבצע', ...Array.from(new Set(PRODUCTS.filter(p => p.category !== 'מבצע').map(p => p.category)))]

const BADGE_STYLE = {
  sale: { bg: '#dc2626', label: '🔥 מבצע' },
  new:  { bg: '#059669', label: '✨ חדש'  },
  hot:  { bg: '#d97706', label: '⭐ פופולרי' },
}

function Stars({ rating, reviews }) {
  const full = Math.round(rating)
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
      <div style={{ display: 'flex', gap: 1 }}>
        {[1,2,3,4,5].map(i => (
          <span key={i} style={{ fontSize: 10, color: i <= full ? '#fbbf24' : '#334155' }}>★</span>
        ))}
      </div>
      <span style={{ fontSize: 10, color: '#475569' }}>({reviews?.toLocaleString()})</span>
    </div>
  )
}

function ProductCard({ product, lang, onBuy }) {
  const isHe = lang === 'he'
  const name = isHe ? product.nameHe : product.name
  const badge = product.badge ? BADGE_STYLE[product.badge] : null

  return (
    <div style={{
      background: '#1e293b', borderRadius: 16,
      border: '1px solid #334155', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Product image */}
      <div style={{
        background: 'linear-gradient(135deg,#0f172a,#0f2a4a)',
        padding: '16px 20px',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', minHeight: 100,
      }}>
        <img
          src={product.img}
          alt={name}
          style={{ width: 72, height: 72, objectFit: 'contain' }}
          onError={e => { e.target.style.display = 'none' }}
        />
        {badge && (
          <div style={{
            position: 'absolute', top: 8, insetInlineStart: 8,
            background: badge.bg, borderRadius: 8,
            padding: '2px 8px', fontSize: 9, fontWeight: 800, color: '#fff',
          }}>
            {badge.label}
          </div>
        )}
        {product.off && (
          <div style={{
            position: 'absolute', top: 8, insetInlineEnd: 8,
            background: '#dc2626', borderRadius: 8,
            padding: '2px 7px', fontSize: 9, fontWeight: 800, color: '#fff',
          }}>
            {product.off}
          </div>
        )}
      </div>

      {/* Info */}
      <div style={{ padding: '12px 12px 14px', flex: 1, display: 'flex', flexDirection: 'column', gap: 5 }}>
        <div style={{ fontSize: 10, color: '#64748b', fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5 }}>
          {product.category}
        </div>
        <div style={{ fontSize: 13, fontWeight: 800, color: '#f1f5f9', lineHeight: 1.3 }}>{name}</div>
        <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.5, flex: 1 }}>{product.desc}</div>

        <Stars rating={product.stars} reviews={product.reviews} />

        {/* Price row */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 17, fontWeight: 900, color: '#38bdf8' }}>{product.price}</span>
          {product.oldPrice && (
            <span style={{ fontSize: 11, color: '#475569', textDecoration: 'line-through' }}>{product.oldPrice}</span>
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
  const { lang, rtl } = useLang()
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
