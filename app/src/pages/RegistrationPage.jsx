/**
 * RegistrationPage — First-launch onboarding screen.
 * Shows plan selection (Free / Basic / Enhanced / Unlimited) + registration form.
 * On submit: saves user object to localStorage('fantatech_user') and calls onComplete().
 */
import { useState } from 'react'
import { useLang } from '../context/LangContext'

/* ─── Plan definitions ───────────────────────────────────────────────── */
// Features left intentionally minimal — to be filled in a future update.
const PLANS = [
  {
    id: 'free',
    icon: '🆓',
    color: '#475569',
    features: ['—'],
  },
  {
    id: 'basic',
    icon: '⭐',
    color: '#2563eb',
    features: ['—'],
  },
  {
    id: 'enhanced',
    icon: '🚀',
    color: '#7c3aed',
    popular: true,
    features: ['—'],
  },
  {
    id: 'unlimited',
    icon: '♾️',
    color: '#0e9f6e',
    features: ['—'],
  },
]

/* ─── Plan card ──────────────────────────────────────────────────────── */
function PlanCard({ plan, selected, onSelect, t, rtl }) {
  const label = t[`reg_plan_${plan.id}`]      ?? plan.id
  const desc  = t[`reg_plan_${plan.id}_desc`] ?? ''

  return (
    <div
      onClick={() => onSelect(plan.id)}
      style={{
        position: 'relative',
        background: selected ? plan.color + '22' : '#1e293b',
        border: `2px solid ${selected ? plan.color : '#334155'}`,
        borderRadius: 16,
        padding: '16px 14px',
        cursor: 'pointer',
        transition: 'all 0.18s',
        flex: '1 1 140px',
        minWidth: 130,
        maxWidth: 220,
        textAlign: rtl ? 'right' : 'left',
        boxShadow: selected ? `0 0 0 1px ${plan.color}55` : 'none',
      }}
    >
      {plan.popular && (
        <div style={{
          position: 'absolute', top: -11, left: '50%', transform: 'translateX(-50%)',
          background: plan.color, color: '#fff', fontSize: 10, fontWeight: 700,
          borderRadius: 20, padding: '2px 10px', whiteSpace: 'nowrap',
        }}>
          {t.reg_most_popular ?? 'Most Popular'}
        </div>
      )}

      <div style={{ fontSize: 26, marginBottom: 6 }}>{plan.icon}</div>
      <div style={{
        fontSize: 15, fontWeight: 700,
        color: selected ? plan.color : '#f1f5f9',
        marginBottom: 4,
      }}>{label}</div>
      <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.5 }}>{desc}</div>

      {/* Selection indicator */}
      <div style={{
        marginTop: 12,
        width: 18, height: 18,
        borderRadius: '50%',
        border: `2px solid ${selected ? plan.color : '#475569'}`,
        background: selected ? plan.color : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginLeft: rtl ? 0 : 'auto',
        marginRight: rtl ? 'auto' : 0,
        transition: 'all 0.18s',
      }}>
        {selected && (
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#fff' }} />
        )}
      </div>
    </div>
  )
}

/* ─── Input row ──────────────────────────────────────────────────────── */
function Field({ label, type = 'text', value, onChange, placeholder, error, rtl }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <label style={{ fontSize: 12, color: '#94a3b8', fontWeight: 600 }}>{label}</label>
      <input
        type={type}
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        dir={rtl ? 'rtl' : 'ltr'}
        style={{
          background: '#1e293b',
          border: `1px solid ${error ? '#ef4444' : '#334155'}`,
          borderRadius: 10,
          padding: '10px 14px',
          color: '#f1f5f9',
          fontSize: 14,
          outline: 'none',
          width: '100%',
          boxSizing: 'border-box',
        }}
      />
      {error && (
        <span style={{ fontSize: 11, color: '#ef4444' }}>{error}</span>
      )}
    </div>
  )
}

/* ─── Main component ─────────────────────────────────────────────────── */
export default function RegistrationPage({ onComplete }) {
  const { t, rtl } = useLang()

  const [plan,   setPlan]   = useState('free')
  const [name,   setName]   = useState('')
  const [email,  setEmail]  = useState('')
  const [phone,  setPhone]  = useState('')
  const [terms,  setTerms]  = useState(false)
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)

  const validate = () => {
    const e = {}
    if (!name.trim())  e.name  = t.reg_name_req     ?? 'Full name is required'
    if (!email.trim()) e.email = t.reg_email_req     ?? 'Email is required'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
                       e.email = t.reg_email_invalid ?? 'Enter a valid email'
    if (!terms)        e.terms = t.reg_terms_req     ?? 'You must accept the terms'
    return e
  }

  const handleSubmit = () => {
    const e = validate()
    if (Object.keys(e).length) { setErrors(e); return }
    setSubmitting(true)
    const user = { name: name.trim(), email: email.trim(), phone: phone.trim(), plan, registeredAt: Date.now() }
    try { localStorage.setItem('fantatech_user', JSON.stringify(user)) } catch {}
    // Brief delay for visual feedback
    setTimeout(() => { setSubmitting(false); onComplete(user) }, 320)
  }

  const handleSkip = () => {
    const user = { name: '', email: '', phone: '', plan: 'free', registeredAt: Date.now(), skipped: true }
    try { localStorage.setItem('fantatech_user', JSON.stringify(user)) } catch {}
    onComplete(user)
  }

  const currentPlan = PLANS.find(p => p.id === plan)

  return (
    <div style={{
      minHeight: '100vh',
      background: '#0f172a',
      color: '#f1f5f9',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      padding: '32px 16px 48px',
      overflowY: 'auto',
    }} dir={rtl ? 'rtl' : 'ltr'}>

      {/* ── Header ── */}
      <div style={{ textAlign: 'center', marginBottom: 32 }}>
        <div style={{ fontSize: 56, marginBottom: 8 }}>🏠</div>
        <h1 style={{
          margin: 0, fontSize: 24, fontWeight: 800,
          background: 'linear-gradient(135deg, #38bdf8, #818cf8)',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
        }}>
          {t.reg_welcome ?? 'Welcome to FantaTech'}
        </h1>
        <p style={{ margin: '8px 0 0', fontSize: 13, color: '#64748b' }}>
          {t.reg_subtitle ?? 'Smart Home Hub — choose your plan to get started'}
        </p>
      </div>

      {/* ── Plan selection ── */}
      <div style={{
        width: '100%', maxWidth: 560,
        background: '#0f172a',
        borderRadius: 20,
        marginBottom: 28,
      }}>
        <h2 style={{
          margin: '0 0 16px',
          fontSize: 15, fontWeight: 700, color: '#94a3b8',
          textAlign: rtl ? 'right' : 'left',
        }}>
          {t.reg_choose_plan ?? 'Choose your plan'}
        </h2>

        {/* Cards row — wraps on small screens */}
        <div style={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: 12,
          justifyContent: 'center',
        }}>
          {PLANS.map(p => (
            <PlanCard
              key={p.id}
              plan={p}
              selected={plan === p.id}
              onSelect={setPlan}
              t={t}
              rtl={rtl}
            />
          ))}
        </div>
      </div>

      {/* ── Registration form ── */}
      <div style={{
        width: '100%', maxWidth: 420,
        background: '#1e293b',
        borderRadius: 20,
        padding: '24px 20px',
        border: `1px solid ${currentPlan ? currentPlan.color + '44' : '#334155'}`,
        display: 'flex', flexDirection: 'column', gap: 16,
      }}>

        <Field
          label={t.reg_name  ?? 'Full Name'}
          value={name}
          onChange={v => { setName(v); setErrors(er => ({ ...er, name: undefined })) }}
          placeholder={t.reg_name ?? 'Full Name'}
          error={errors.name}
          rtl={rtl}
        />
        <Field
          label={t.reg_email ?? 'Email Address'}
          type="email"
          value={email}
          onChange={v => { setEmail(v); setErrors(er => ({ ...er, email: undefined })) }}
          placeholder="name@example.com"
          error={errors.email}
          rtl={rtl}
        />
        <Field
          label={`${t.reg_phone ?? 'Phone'} (${t.optional ?? 'optional'})`}
          type="tel"
          value={phone}
          onChange={setPhone}
          placeholder="+972 50 000 0000"
          rtl={rtl}
        />

        {/* Terms */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <label style={{
            display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer',
            flexDirection: rtl ? 'row-reverse' : 'row',
          }}>
            <input
              type="checkbox"
              checked={terms}
              onChange={e => { setTerms(e.target.checked); setErrors(er => ({ ...er, terms: undefined })) }}
              style={{ marginTop: 2, accentColor: currentPlan?.color ?? '#38bdf8', cursor: 'pointer' }}
            />
            <span style={{ fontSize: 12, color: '#94a3b8', lineHeight: 1.6 }}>
              {t.reg_terms ?? 'I agree to the Terms of Use and Privacy Policy'}
            </span>
          </label>
          {errors.terms && (
            <span style={{ fontSize: 11, color: '#ef4444' }}>{errors.terms}</span>
          )}
        </div>

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={submitting}
          style={{
            background: submitting
              ? '#334155'
              : `linear-gradient(135deg, ${currentPlan?.color ?? '#1d4ed8'}, ${currentPlan?.color ?? '#1d4ed8'}cc)`,
            border: 'none',
            borderRadius: 12,
            padding: '14px',
            color: '#fff',
            fontSize: 15,
            fontWeight: 700,
            cursor: submitting ? 'default' : 'pointer',
            transition: 'background 0.2s',
            boxShadow: submitting ? 'none' : `0 4px 24px ${currentPlan?.color ?? '#1d4ed8'}55`,
          }}
        >
          {submitting ? '⏳' : (t.reg_start ?? 'Get Started')}
        </button>

        {/* Skip */}
        <button
          onClick={handleSkip}
          style={{
            background: 'none', border: 'none',
            color: '#475569', fontSize: 12, cursor: 'pointer',
            padding: '4px', textDecoration: 'underline',
            textAlign: 'center',
          }}
        >
          {t.reg_skip ?? 'Skip for now'}
        </button>
      </div>

      {/* ── Version watermark ── */}
      <div style={{ marginTop: 32, fontSize: 10, color: '#1e293b' }}>
        FantaTech Home v2.0
      </div>
    </div>
  )
}
