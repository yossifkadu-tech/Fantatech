/**
 * PremiumPage — subscription plans + monetization hub.
 * Includes: plan cards, affiliate links section, AdMob info.
 */
import { useState, useEffect } from 'react'
import { useLang } from '../context/LangContext'
import { useScale } from '../context/ScaleContext'
import { PLANS, getPlan, setPlan } from '../hooks/usePremium'
import { STORE_URL } from './StorePage'

/* ── Affiliate products (Amazon IL + AliExpress) ─────────────────────── */
const AFFILIATE_PRODUCTS = [
  {
    name: 'Sonoff Mini R2', nameHe: 'סונוף מיני R2',
    price: '₪45', site: 'AliExpress', emoji: '🔌',
    url: 'https://s.click.aliexpress.com/e/_sonoff-mini',
    desc: 'מפסק חכם WiFi — מתקין בקופסת חשמל',
  },
  {
    name: 'Shelly 1', nameHe: 'שלי 1',
    price: '₪55', site: 'Amazon IL', emoji: '🔌',
    url: 'https://www.amazon.co.il/s?k=shelly+1',
    desc: 'שליטה מקומית, ללא ענן, ישראלי',
  },
  {
    name: 'Aqara Motion Sensor', nameHe: 'חיישן תנועה Aqara',
    price: '₪69', site: 'Amazon IL', emoji: '👤',
    url: 'https://www.amazon.co.il/s?k=aqara+motion+sensor',
    desc: 'חיישן Zigbee, סוללה 2 שנה',
  },
  {
    name: 'Sonoff Zigbee Bridge', nameHe: 'גייטוויי Zigbee',
    price: '₪89', site: 'AliExpress', emoji: '📡',
    url: 'https://s.click.aliexpress.com/e/_sonoff-bridge',
    desc: 'חיבור עד 128 מכשירי Zigbee',
  },
  {
    name: 'Reolink RLC-810A', nameHe: 'מצלמה Reolink 4K',
    price: '₪299', site: 'Amazon IL', emoji: '📷',
    url: 'https://www.amazon.co.il/s?k=reolink+rlc-810a',
    desc: '4K, ראיית לילה צבעונית, RTSP',
  },
  {
    name: 'Sensibo Sky', nameHe: 'שלט מזגן Sensibo',
    price: '₪199', site: 'Amazon IL', emoji: '❄️',
    url: 'https://www.amazon.co.il/s?k=sensibo+sky',
    desc: 'הפוך כל מזגן לחכם — WiFi',
  },
]

/* ── AdMob test unit IDs (replace with real IDs from admob.google.com) ── */
export const ADMOB_IDS = {
  banner:       'ca-app-pub-3940256099942544/6300978111', // TEST
  interstitial: 'ca-app-pub-3940256099942544/1033173712', // TEST
  rewarded:     'ca-app-pub-3940256099942544/5224354917', // TEST
  // Replace above with your real IDs:
  // banner:       'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
  appId:        'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX', // your AdMob App ID
}

function PlanCard({ plan, current, onSelect, isHe }) {
  const active = current.id === plan.id
  const name = isHe ? plan.nameHe : plan.nameEn

  return (
    <div style={{
      background: active ? `${plan.color}18` : '#1e293b',
      border: `2px solid ${active ? plan.color : '#334155'}`,
      borderRadius: 20, padding: '20px 16px',
      position: 'relative', transition: 'all 0.2s',
    }}>
      {plan.popular && (
        <div style={{
          position: 'absolute', top: -12, left: '50%', transform: 'translateX(-50%)',
          background: plan.color, borderRadius: 20, padding: '3px 14px',
          fontSize: 10, fontWeight: 800, color: '#fff', whiteSpace: 'nowrap',
        }}>
          ⭐ {isHe ? 'הכי פופולרי' : 'Most Popular'}
        </div>
      )}

      <div style={{ textAlign: 'center', marginBottom: 14 }}>
        <div style={{ fontSize: 22, fontWeight: 900, color: plan.color }}>{name}</div>
        <div style={{ fontSize: 24, fontWeight: 900, color: '#f1f5f9', marginTop: 4 }}>
          {plan.priceLabel}
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 7, marginBottom: 16 }}>
        {plan.features.map((f, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 8, fontSize: 12, color: '#cbd5e1' }}>
            <span style={{ color: plan.color, flexShrink: 0, marginTop: 1 }}>✓</span>
            <span>{f}</span>
          </div>
        ))}
      </div>

      <button
        onClick={() => onSelect(plan.id)}
        style={{
          width: '100%', padding: '10px 0', borderRadius: 12, border: 'none',
          background: active ? plan.color : (plan.id === 'free' ? '#1e3a5f' : `linear-gradient(135deg,${plan.color}cc,${plan.color})`),
          color: '#fff', fontWeight: 800, fontSize: 13, cursor: 'pointer',
          WebkitTapHighlightColor: 'transparent',
        }}
      >
        {active ? (isHe ? '✓ התוכנית הנוכחית' : '✓ Current Plan') : (plan.id === 'free' ? (isHe ? 'שדרג חינם' : 'Downgrade') : (isHe ? 'בחר תוכנית' : 'Choose Plan'))}
      </button>
    </div>
  )
}

function AffiliateCard({ product, isHe }) {
  return (
    <div
      onClick={() => window.open(product.url, '_blank', 'noopener')}
      style={{
        background: '#1e293b', borderRadius: 14,
        border: '1px solid #334155', padding: '12px 12px 14px',
        cursor: 'pointer', display: 'flex', flexDirection: 'column', gap: 6,
      }}
    >
      <div style={{ fontSize: 28, textAlign: 'center' }}>{product.emoji}</div>
      <div style={{ fontSize: 11, color: '#64748b', fontWeight: 700 }}>{product.site}</div>
      <div style={{ fontSize: 13, fontWeight: 800, color: '#f1f5f9', lineHeight: 1.3 }}>
        {isHe ? product.nameHe : product.name}
      </div>
      <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.4, flex: 1 }}>{product.desc}</div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 15, fontWeight: 900, color: '#38bdf8' }}>{product.price}</span>
        <span style={{ fontSize: 10, background: '#0f172a', borderRadius: 6, padding: '3px 8px', color: '#64748b' }}>
          {isHe ? 'לרכישה ←' : '← Buy'}
        </span>
      </div>
    </div>
  )
}

export default function PremiumPage() {
  const { lang, rtl } = useLang()
  const { phone, tablet } = useScale()
  const isHe = lang === 'he'
  const [current, setCurrent] = useState(getPlan)
  const [tab, setTab] = useState('plans') // plans | affiliate | admob

  useEffect(() => {
    const onPlanChange = () => setCurrent(getPlan())
    window.addEventListener('fantatech_plan_change', onPlanChange)
    return () => window.removeEventListener('fantatech_plan_change', onPlanChange)
  }, [])

  const handleSelect = (planId) => {
    setPlan(planId)
    setCurrent(getPlan())
  }

  const cols = tablet ? 4 : phone ? 2 : 4

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>

      {/* Hero */}
      <div style={{
        background: 'linear-gradient(135deg,#1e1b4b,#312e81,#1d4ed8)',
        borderRadius: 20, padding: '22px 20px',
        textAlign: 'center', marginBottom: 20,
      }}>
        <div style={{ fontSize: 36, marginBottom: 8 }}>💎</div>
        <div style={{ fontSize: 20, fontWeight: 900, color: '#fff', marginBottom: 6 }}>
          {isHe ? 'FantaTech Premium' : 'FantaTech Premium'}
        </div>
        <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.75)' }}>
          {isHe ? 'שדרג לחוויית בית חכם מלאה' : 'Upgrade to the full smart home experience'}
        </div>
        <div style={{
          marginTop: 12, display: 'inline-block',
          background: 'rgba(255,255,255,0.15)', borderRadius: 10,
          padding: '6px 16px', fontSize: 12, color: '#fff', fontWeight: 700,
        }}>
          {isHe ? `תוכנית נוכחית: ${current.nameHe}` : `Current plan: ${current.nameEn}`}
        </div>
      </div>

      {/* Tab switcher */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {[
          { id: 'plans',     label: isHe ? '💎 מנויים' : '💎 Plans' },
          { id: 'affiliate', label: isHe ? '🛍️ שותפים' : '🛍️ Affiliate' },
          { id: 'admob',     label: isHe ? '📢 AdMob' : '📢 AdMob' },
        ].map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            flex: 1, padding: '8px 4px', borderRadius: 10, border: 'none',
            background: tab === t.id ? '#1d4ed8' : '#1e293b',
            color: tab === t.id ? '#fff' : '#64748b',
            fontWeight: 700, fontSize: 12, cursor: 'pointer',
            border: `1px solid ${tab === t.id ? '#3b82f6' : '#334155'}`,
            WebkitTapHighlightColor: 'transparent',
          }}>{t.label}</button>
        ))}
      </div>

      {/* ── Plans tab ── */}
      {tab === 'plans' && (
        <div style={{ display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 12 }}>
          {Object.values(PLANS).map(plan => (
            <PlanCard key={plan.id} plan={plan} current={current} onSelect={handleSelect} isHe={isHe} />
          ))}
        </div>
      )}

      {/* ── Affiliate tab ── */}
      {tab === 'affiliate' && (
        <div>
          <div style={{ fontSize: 12, color: '#475569', marginBottom: 14, textAlign: 'center' }}>
            {isHe
              ? '🤝 קישורי שותפים — קבל עמלה על כל קנייה דרך האפליקציה'
              : '🤝 Affiliate links — earn commission on every purchase'}
          </div>

          {/* Your store first */}
          <div
            onClick={() => window.open(STORE_URL, '_blank', 'noopener')}
            style={{
              background: 'linear-gradient(135deg,#1d1b6e,#1d4ed8)',
              borderRadius: 16, padding: '16px', marginBottom: 16,
              cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 14,
            }}
          >
            <span style={{ fontSize: 32 }}>🏠</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 900, color: '#fff' }}>
                {isHe ? 'חנות FantaTech שלך' : 'Your FantaTech Store'}
              </div>
              <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)' }}>
                {isHe ? 'המוצרים שלך — רווח מלא על כל מכירה' : 'Your products — full profit on every sale'}
              </div>
            </div>
            <span style={{ color: '#fff', fontSize: 18 }}>←</span>
          </div>

          <div style={{ fontSize: 11, fontWeight: 700, color: '#475569', marginBottom: 10 }}>
            {isHe ? 'מוצרים מומלצים — עמלת שותפים' : 'Recommended — Affiliate commission'}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: `repeat(${phone ? 2 : 3}, 1fr)`, gap: 10 }}>
            {AFFILIATE_PRODUCTS.map((p, i) => (
              <AffiliateCard key={i} product={p} isHe={isHe} />
            ))}
          </div>

          <div style={{ marginTop: 16, background: '#1e293b', borderRadius: 12, padding: 14, fontSize: 11, color: '#475569', lineHeight: 1.7 }}>
            💡 {isHe
              ? 'כדי לקבל עמלות אמיתיות: הירשם ל-Amazon Associates IL ול-AliExpress Portals, ועדכן את ה-URLs עם קוד השותף שלך בקובץ PremiumPage.jsx'
              : 'To earn real commissions: register for Amazon Associates IL & AliExpress Portals, then update URLs with your affiliate code in PremiumPage.jsx'}
          </div>
        </div>
      )}

      {/* ── AdMob tab ── */}
      {tab === 'admob' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>

          <div style={{ background: '#1e293b', borderRadius: 16, padding: 16 }}>
            <div style={{ fontSize: 14, fontWeight: 800, color: '#f1f5f9', marginBottom: 10 }}>
              📢 {isHe ? 'הגדרת Google AdMob' : 'Google AdMob Setup'}
            </div>

            {[
              { step: '1', text: isHe ? 'צור חשבון ב-admob.google.com' : 'Create account at admob.google.com' },
              { step: '2', text: isHe ? 'הוסף אפליקציה → Android → "FantaTech"' : 'Add App → Android → "FantaTech"' },
              { step: '3', text: isHe ? 'צור Ad Units: Banner + Interstitial' : 'Create Ad Units: Banner + Interstitial' },
              { step: '4', text: isHe ? 'העתק את ה-IDs לקובץ PremiumPage.jsx' : 'Copy IDs to PremiumPage.jsx → ADMOB_IDS' },
              { step: '5', text: isHe ? 'עדכן AndroidManifest.xml עם App ID' : 'Update AndroidManifest.xml with App ID' },
            ].map(s => (
              <div key={s.step} style={{ display: 'flex', gap: 10, marginBottom: 10, alignItems: 'flex-start' }}>
                <div style={{
                  width: 22, height: 22, borderRadius: '50%', background: '#1d4ed8',
                  color: '#fff', fontSize: 11, fontWeight: 800, flexShrink: 0,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>{s.step}</div>
                <div style={{ fontSize: 12, color: '#94a3b8', lineHeight: 1.5 }}>{s.text}</div>
              </div>
            ))}
          </div>

          {/* Current Test IDs */}
          <div style={{ background: '#0f172a', borderRadius: 12, padding: 14 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: '#475569', marginBottom: 10 }}>
              {isHe ? '🧪 IDs לבדיקה (כבר מוגדרים)' : '🧪 Test IDs (already configured)'}
            </div>
            {[
              ['Banner',       ADMOB_IDS.banner],
              ['Interstitial', ADMOB_IDS.interstitial],
              ['Rewarded',     ADMOB_IDS.rewarded],
            ].map(([label, id]) => (
              <div key={label} style={{ marginBottom: 8 }}>
                <div style={{ fontSize: 10, color: '#64748b', marginBottom: 2 }}>{label}</div>
                <div style={{ fontSize: 10, fontFamily: 'monospace', color: '#38bdf8', wordBreak: 'break-all' }}>{id}</div>
              </div>
            ))}
          </div>

          <div style={{ background: '#1e293b', borderRadius: 12, padding: 14 }}>
            <div style={{ fontSize: 13, fontWeight: 800, color: '#f1f5f9', marginBottom: 8 }}>
              {isHe ? '💰 הערכת הכנסה' : '💰 Revenue Estimate'}
            </div>
            {[
              { label: isHe ? 'CPM ישראל (banner)' : 'Israel CPM (banner)', val: '$1–3' },
              { label: isHe ? '1,000 משתמשים פעילים/יום' : '1,000 DAU', val: '$30–90/יום' },
              { label: isHe ? 'Interstitial (×2/יום)' : 'Interstitial (×2/day)', val: '$5–15/יום' },
            ].map(r => (
              <div key={r.label} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: '#94a3b8', marginBottom: 6 }}>
                <span>{r.label}</span>
                <span style={{ color: '#22c55e', fontWeight: 700 }}>{r.val}</span>
              </div>
            ))}
          </div>

          <button
            onClick={() => window.open('https://admob.google.com', '_blank', 'noopener')}
            style={{
              width: '100%', padding: '12px 0', borderRadius: 12, border: 'none',
              background: 'linear-gradient(135deg,#ea4335,#fbbc05)',
              color: '#fff', fontWeight: 800, fontSize: 14, cursor: 'pointer',
            }}
          >
            🚀 {isHe ? 'פתח AdMob' : 'Open AdMob'}
          </button>
        </div>
      )}
    </div>
  )
}
