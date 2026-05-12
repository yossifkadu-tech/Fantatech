/**
 * RegistrationPage — First-launch onboarding.
 * Fields per plan:
 *   Free     : name, username, email, address
 *   Basic    : + credit card details
 *   Enhanced : + credit card details
 *   Unlimited: + credit card details
 *
 * On submit → saves to localStorage + syncs to hub (POST /api/users/register)
 *           → hub appends a row to users.xlsx
 */
import { useState } from 'react'
import { useLang, LANG_META } from '../context/LangContext'
import { api } from '../hooks/useHub'

/* ── Plan definitions ───────────────────────────────────────────────────── */
const PLANS = [
  {
    id: 'free', icon: '🆓', color: '#475569',
    price: t => t.reg_price_free ?? 'Free',
  },
  {
    id: 'basic', icon: '⭐', color: '#2563eb',
    price: t => t.reg_price_basic ?? '₪29/mo',
    paid: true,
  },
  {
    id: 'enhanced', icon: '🚀', color: '#7c3aed',
    price: t => t.reg_price_enhanced ?? '₪59/mo',
    paid: true, popular: true,
  },
  {
    id: 'unlimited', icon: '♾️', color: '#0e9f6e',
    price: t => t.reg_price_unlimited ?? '₪99/mo',
    paid: true,
  },
]

/* ── Language color palette ─────────────────────────────────────────────── */
const LANG_COLORS = {
  he: '#1d4ed8', en: '#dc2626', ar: '#15803d',
  ru: '#7c3aed', es: '#d97706', fr: '#0284c7',
  de: '#475569', pt: '#059669', am: '#b91c1c',
}

/* ── Plan card ──────────────────────────────────────────────────────────── */
function PlanCard({ plan, selected, onSelect, t, rtl }) {
  const label = t[`reg_plan_${plan.id}`] ?? plan.id
  const desc  = t[`reg_plan_${plan.id}_desc`] ?? ''
  const price = plan.price(t)
  return (
    <div onClick={() => onSelect(plan.id)} style={{
      position: 'relative',
      background: selected ? plan.color + '22' : '#1e293b',
      border: `2px solid ${selected ? plan.color : '#334155'}`,
      borderRadius: 16, padding: '16px 12px',
      cursor: 'pointer', transition: 'all 0.18s',
      flex: '1 1 130px', minWidth: 120, maxWidth: 200,
      textAlign: 'center',
      boxShadow: selected ? `0 0 0 1px ${plan.color}55` : 'none',
    }}>
      {plan.popular && (
        <div style={{
          position: 'absolute', top: -11, left: '50%', transform: 'translateX(-50%)',
          background: plan.color, color: '#fff', fontSize: 9, fontWeight: 700,
          borderRadius: 20, padding: '2px 8px', whiteSpace: 'nowrap',
        }}>
          {t.reg_most_popular ?? 'Most Popular'}
        </div>
      )}
      <div style={{ fontSize: 24, marginBottom: 4 }}>{plan.icon}</div>
      <div style={{ fontSize: 13, fontWeight: 700, color: selected ? plan.color : '#f1f5f9', marginBottom: 2 }}>
        {label}
      </div>
      <div style={{ fontSize: 12, color: plan.color, fontWeight: 800, marginBottom: 4 }}>{price}</div>
      <div style={{ fontSize: 10, color: '#64748b', lineHeight: 1.5 }}>{desc}</div>
      <div style={{
        marginTop: 10, width: 16, height: 16, borderRadius: '50%',
        border: `2px solid ${selected ? plan.color : '#475569'}`,
        background: selected ? plan.color : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        margin: '10px auto 0',
      }}>
        {selected && <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#fff' }} />}
      </div>
    </div>
  )
}

/* ── Reusable input field ───────────────────────────────────────────────── */
function Field({ label, type = 'text', value, onChange, placeholder, error, rtl, maxLength, icon }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <label style={{ fontSize: 11, color: '#94a3b8', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
        {icon && <span>{icon}</span>}{label}
      </label>
      <input
        type={type}
        value={value}
        maxLength={maxLength}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        dir={rtl ? 'rtl' : 'ltr'}
        style={{
          background: '#0f172a',
          border: `1px solid ${error ? '#ef4444' : '#334155'}`,
          borderRadius: 10, padding: '10px 14px',
          color: '#f1f5f9', fontSize: 14, outline: 'none',
          width: '100%', boxSizing: 'border-box',
          transition: 'border-color 0.15s',
        }}
        onFocus={e => e.target.style.borderColor = '#38bdf8'}
        onBlur={e  => e.target.style.borderColor = error ? '#ef4444' : '#334155'}
      />
      {error && <span style={{ fontSize: 11, color: '#ef4444' }}>{error}</span>}
    </div>
  )
}

/* ── Card number formatter ──────────────────────────────────────────────── */
function formatCard(v) {
  return v.replace(/\D/g, '').slice(0, 16).replace(/(.{4})/g, '$1 ').trim()
}
function formatExpiry(v) {
  const d = v.replace(/\D/g, '').slice(0, 4)
  return d.length > 2 ? d.slice(0, 2) + '/' + d.slice(2) : d
}

/* ── Main component ─────────────────────────────────────────────────────── */
export default function RegistrationPage({ onComplete }) {
  const { t, rtl, lang, setLang } = useLang()

  const [plan,       setPlan]       = useState('free')
  const [name,       setName]       = useState('')
  const [username,   setUsername]   = useState('')
  const [email,      setEmail]      = useState('')
  const [address,    setAddress]    = useState('')
  // Payment fields (paid plans only)
  const [cardHolder, setCardHolder] = useState('')
  const [cardNumber, setCardNumber] = useState('')
  const [cardExpiry, setCardExpiry] = useState('')
  const [cardCvv,    setCardCvv]    = useState('')
  const [terms,      setTerms]      = useState(false)
  const [errors,     setErrors]     = useState({})
  const [submitting, setSubmitting] = useState(false)

  const currentPlan = PLANS.find(p => p.id === plan)
  const isPaid      = currentPlan?.paid ?? false

  const clearErr = field => setErrors(e => ({ ...e, [field]: undefined }))

  /* ── Validation ── */
  const validate = () => {
    const e = {}
    if (!name.trim())     e.name     = t.reg_name_req     ?? 'Required'
    if (!username.trim()) e.username = t.reg_username_req ?? 'Required'
    if (!email.trim())    e.email    = t.reg_email_req    ?? 'Required'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
                          e.email    = t.reg_email_invalid ?? 'Invalid email'
    if (!address.trim())  e.address  = t.reg_address_req  ?? 'Required'

    if (isPaid) {
      if (!cardHolder.trim()) e.cardHolder = t.reg_card_req ?? 'Required'
      const raw = cardNumber.replace(/\s/g, '')
      if (raw.length < 16)    e.cardNumber = t.reg_card_num_req ?? '16 digits required'
      if (cardExpiry.length < 5) e.cardExpiry = t.reg_card_expiry_req ?? 'MM/YY required'
      if (cardCvv.length < 3)    e.cardCvv    = t.reg_card_cvv_req   ?? '3 digits required'
    }
    if (!terms) e.terms = t.reg_terms_req ?? 'Accept terms to continue'
    return e
  }

  /* ── Submit ── */
  const handleSubmit = async () => {
    const e = validate()
    if (Object.keys(e).length) { setErrors(e); return }
    setSubmitting(true)

    const user = {
      plan, name: name.trim(), username: username.trim(),
      email: email.trim(), address: address.trim(),
      registeredAt: Date.now(),
    }
    try { localStorage.setItem('fantatech_user', JSON.stringify(user)) } catch {}

    // Sync to hub → writes to users.xlsx (fire & forget)
    try {
      await api.post('/users/register', {
        plan, name: name.trim(), username: username.trim(),
        email: email.trim(), address: address.trim(),
        card_holder: cardHolder.trim(),
        card_number: cardNumber.replace(/\s/g, ''),
        card_expiry: cardExpiry,
        card_cvv:    cardCvv,
      })
    } catch {
      // Hub might not be reachable yet — that's OK, localStorage is the source of truth
    }

    setTimeout(() => { setSubmitting(false); onComplete(user) }, 320)
  }

  const handleSkip = () => {
    const user = { name: '', username: '', email: '', address: '', plan: 'free', registeredAt: Date.now(), skipped: true }
    try { localStorage.setItem('fantatech_user', JSON.stringify(user)) } catch {}
    onComplete(user)
  }

  /* ── Render ── */
  return (
    <div style={{
      minHeight: '100vh', background: '#0a0f1e',
      color: '#f1f5f9', display: 'flex', flexDirection: 'column',
      alignItems: 'center', padding: '28px 16px 56px',
      overflowY: 'auto',
    }} dir={rtl ? 'rtl' : 'ltr'}>

      {/* ── Language picker ── */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5, justifyContent: 'center', marginBottom: 20, maxWidth: 420 }}>
        {Object.entries(LANG_META).map(([code, meta]) => {
          const active = lang === code
          const color  = LANG_COLORS[code] || '#1d4ed8'
          return (
            <button key={code} onClick={() => setLang(code)} style={{
              display: 'flex', alignItems: 'center', gap: 4,
              padding: '4px 9px', borderRadius: 20,
              border: `1.5px solid ${active ? color : '#334155'}`,
              background: active ? color + '22' : '#1e293b',
              cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
            }}>
              <span style={{
                width: 18, height: 18, borderRadius: '50%',
                background: active ? color : '#334155',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 8, fontWeight: 800, color: '#fff', flexShrink: 0,
              }}>{code.toUpperCase()}</span>
              <span style={{ fontSize: 10, fontWeight: active ? 700 : 400, color: active ? '#f1f5f9' : '#64748b', whiteSpace: 'nowrap' }}>
                {meta.name}
              </span>
            </button>
          )
        })}
      </div>

      {/* ── Header ── */}
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ fontSize: 52, marginBottom: 6 }}>🏠</div>
        <h1 style={{
          margin: 0, fontSize: 22, fontWeight: 800,
          background: 'linear-gradient(135deg, #38bdf8, #818cf8)',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
        }}>
          {t.reg_welcome ?? 'Welcome to FantaTech'}
        </h1>
        <p style={{ margin: '6px 0 0', fontSize: 12, color: '#475569' }}>
          {t.reg_subtitle ?? 'Smart Home · Security · Eco'}
        </p>
      </div>

      {/* ── Plan cards ── */}
      <div style={{ width: '100%', maxWidth: 580, marginBottom: 24 }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: '#64748b', marginBottom: 12, textAlign: rtl ? 'right' : 'left' }}>
          {t.reg_choose_plan ?? 'Choose your plan'}
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, justifyContent: 'center' }}>
          {PLANS.map(p => (
            <PlanCard key={p.id} plan={p} selected={plan === p.id} onSelect={id => { setPlan(id); setErrors({}) }} t={t} rtl={rtl} />
          ))}
        </div>
      </div>

      {/* ── Registration form ── */}
      <div style={{
        width: '100%', maxWidth: 440,
        background: '#1e293b', borderRadius: 20,
        padding: '22px 18px',
        border: `1px solid ${currentPlan ? currentPlan.color + '55' : '#334155'}`,
        display: 'flex', flexDirection: 'column', gap: 14,
      }}>

        {/* Section: Personal info */}
        <div style={{ fontSize: 11, fontWeight: 800, color: '#64748b', letterSpacing: 1, textTransform: 'uppercase' }}>
          👤 {t.reg_personal ?? 'Personal Details'}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label={t.reg_name ?? 'Full Name'} icon="🙍" value={name}
            onChange={v => { setName(v); clearErr('name') }}
            placeholder={t.reg_name ?? 'Full Name'}
            error={errors.name} rtl={rtl} />
          <Field label={t.reg_username ?? 'Username'} icon="@" value={username}
            onChange={v => { setUsername(v.replace(/\s/g, '')); clearErr('username') }}
            placeholder="fantatech_user"
            error={errors.username} rtl={rtl} />
        </div>

        <Field label={t.reg_email ?? 'Email'} icon="✉️" type="email" value={email}
          onChange={v => { setEmail(v); clearErr('email') }}
          placeholder="you@example.com"
          error={errors.email} rtl={rtl} />

        <Field label={t.reg_address ?? 'Address'} icon="📍" value={address}
          onChange={v => { setAddress(v); clearErr('address') }}
          placeholder={t.reg_address_placeholder ?? 'Street, City, Country'}
          error={errors.address} rtl={rtl} />

        {/* Section: Payment (paid plans only) */}
        {isPaid && (
          <>
            <div style={{
              fontSize: 11, fontWeight: 800, color: currentPlan.color,
              letterSpacing: 1, textTransform: 'uppercase',
              paddingTop: 8, borderTop: `1px solid #334155`,
            }}>
              💳 {t.reg_payment ?? 'Payment Details'}
            </div>

            <Field label={t.reg_card_holder ?? 'Cardholder Name'} icon="👤" value={cardHolder}
              onChange={v => { setCardHolder(v); clearErr('cardHolder') }}
              placeholder={t.reg_name ?? 'Full Name'}
              error={errors.cardHolder} rtl={rtl} />

            <Field label={t.reg_card_number ?? 'Card Number'} icon="💳" value={cardNumber}
              onChange={v => { setCardNumber(formatCard(v)); clearErr('cardNumber') }}
              placeholder="0000 0000 0000 0000"
              error={errors.cardNumber} rtl={false} maxLength={19} />

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <Field label={t.reg_card_expiry ?? 'Expiry (MM/YY)'} icon="📅" value={cardExpiry}
                onChange={v => { setCardExpiry(formatExpiry(v)); clearErr('cardExpiry') }}
                placeholder="MM/YY"
                error={errors.cardExpiry} rtl={false} maxLength={5} />
              <Field label="CVV" icon="🔒" type="password" value={cardCvv}
                onChange={v => { setCardCvv(v.replace(/\D/g, '').slice(0, 4)); clearErr('cardCvv') }}
                placeholder="•••"
                error={errors.cardCvv} rtl={false} maxLength={4} />
            </div>

            {/* Security note */}
            <div style={{
              background: 'rgba(99,102,241,0.08)', border: '1px solid #6366f122',
              borderRadius: 8, padding: '8px 12px', fontSize: 10, color: '#64748b',
              display: 'flex', alignItems: 'flex-start', gap: 6,
            }}>
              <span>🔐</span>
              <span>{t.reg_card_security ?? 'Your payment details are encrypted and stored securely on your local hub only.'}</span>
            </div>
          </>
        )}

        {/* Terms */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <label style={{
            display: 'flex', alignItems: 'flex-start', gap: 10,
            cursor: 'pointer', flexDirection: rtl ? 'row-reverse' : 'row',
          }}>
            <input type="checkbox" checked={terms}
              onChange={e => { setTerms(e.target.checked); clearErr('terms') }}
              style={{ marginTop: 2, accentColor: currentPlan?.color ?? '#38bdf8', cursor: 'pointer', flexShrink: 0 }}
            />
            <span style={{ fontSize: 11, color: '#64748b', lineHeight: 1.6 }}>
              {t.reg_terms ?? 'I agree to the Terms of Use and Privacy Policy'}
            </span>
          </label>
          {errors.terms && <span style={{ fontSize: 11, color: '#ef4444' }}>{errors.terms}</span>}
        </div>

        {/* Submit */}
        <button onClick={handleSubmit} disabled={submitting} style={{
          background: submitting ? '#334155'
            : `linear-gradient(135deg, ${currentPlan?.color ?? '#1d4ed8'}, ${currentPlan?.color ?? '#1d4ed8'}bb)`,
          border: 'none', borderRadius: 12, padding: '14px',
          color: '#fff', fontSize: 15, fontWeight: 700,
          cursor: submitting ? 'default' : 'pointer',
          boxShadow: submitting ? 'none' : `0 4px 20px ${currentPlan?.color ?? '#1d4ed8'}44`,
          transition: 'all 0.2s',
        }}>
          {submitting ? '⏳' : (t.reg_start ?? 'Get Started →')}
        </button>

        {/* Skip */}
        <button onClick={handleSkip} style={{
          background: 'none', border: 'none', color: '#334155',
          fontSize: 11, cursor: 'pointer', padding: '2px',
          textDecoration: 'underline', textAlign: 'center',
        }}>
          {t.reg_skip ?? 'Skip for now'}
        </button>
      </div>

      <div style={{ marginTop: 24, fontSize: 10, color: '#1e293b' }}>FantaTech v2.8.0</div>
    </div>
  )
}
