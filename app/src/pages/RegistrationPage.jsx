/**
 * RegistrationPage — First-launch onboarding.
 *
 * Two modes:
 *   register  — new user fills name / username / email / address + plan
 *   login     — returning user (after reinstall) enters username to restore session
 *
 * On register: saves to localStorage + syncs to hub POST /api/users/register
 * On login:    calls hub POST /api/users/login → restores saved record
 */
import { useState } from 'react'
import { useLang, LANG_META } from '../context/LangContext'
import { api } from '../hooks/useHub'

/* ── Plan definitions ───────────────────────────────────────────────────── */
const PLANS = [
  { id: 'free',      icon: '🆓', color: '#475569', paid: false },
  { id: 'basic',     icon: '⭐', color: '#2563eb', paid: true  },
  { id: 'enhanced',  icon: '🚀', color: '#7c3aed', paid: true, popular: true },
  { id: 'unlimited', icon: '♾️', color: '#0e9f6e', paid: true  },
]

const LANG_COLORS = {
  he: '#1d4ed8', en: '#dc2626', ar: '#15803d',
  ru: '#7c3aed', es: '#d97706', fr: '#0284c7',
  de: '#475569', pt: '#059669', am: '#b91c1c',
}

/* ── Plan card ──────────────────────────────────────────────────────────── */
function PlanCard({ plan, selected, onSelect, t }) {
  const label = t[`reg_plan_${plan.id}`] ?? plan.id
  const desc  = t[`reg_plan_${plan.id}_desc`] ?? ''
  const price = t[`reg_price_${plan.id}`] ?? ''
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
      <div style={{ fontSize: 13, fontWeight: 700, color: selected ? plan.color : '#f1f5f9', marginBottom: 2 }}>{label}</div>
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

/* ── Input field ────────────────────────────────────────────────────────── */
function Field({ label, type = 'text', value, onChange, placeholder, error, rtl, maxLength, icon }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <label style={{ fontSize: 11, color: '#94a3b8', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
        {icon && <span>{icon}</span>}{label}
      </label>
      <input
        type={type} value={value} maxLength={maxLength}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        dir={rtl ? 'rtl' : 'ltr'}
        style={{
          background: '#0f172a',
          border: `1px solid ${error ? '#ef4444' : '#334155'}`,
          borderRadius: 10, padding: '10px 14px',
          color: '#f1f5f9', fontSize: 14, outline: 'none',
          width: '100%', boxSizing: 'border-box', transition: 'border-color 0.15s',
        }}
        onFocus={e => e.target.style.borderColor = '#38bdf8'}
        onBlur={e  => e.target.style.borderColor = error ? '#ef4444' : '#334155'}
      />
      {error && <span style={{ fontSize: 11, color: '#ef4444' }}>{error}</span>}
    </div>
  )
}

function formatCard(v)   { return v.replace(/\D/g, '').slice(0, 16).replace(/(.{4})/g, '$1 ').trim() }
function formatExpiry(v) { const d = v.replace(/\D/g, '').slice(0, 4); return d.length > 2 ? d.slice(0,2)+'/'+d.slice(2) : d }

/* ══════════════════════════════════════════════════════════════════════════
   SIGN-IN panel (returning user after reinstall)
══════════════════════════════════════════════════════════════════════════ */
function LoginPanel({ onComplete, onSwitchMode, t, rtl }) {
  const [username,    setUsername]    = useState('')
  const [submitting,  setSubmitting]  = useState(false)
  const [errorMsg,    setErrorMsg]    = useState('')
  const [successMsg,  setSuccessMsg]  = useState('')

  const handleLogin = async () => {
    if (!username.trim()) { setErrorMsg(t.reg_username_req ?? 'Username required'); return }
    setSubmitting(true)
    setErrorMsg('')
    setSuccessMsg('')
    try {
      const res = await api.post('/users/login', { username: username.trim() })
      const user = { ...res.data.user, registeredAt: Date.now(), restoredAt: Date.now() }
      localStorage.setItem('fantatech_user', JSON.stringify(user))
      setSuccessMsg(t.login_success ?? 'Welcome back!')
      setTimeout(() => onComplete(user), 700)
    } catch (err) {
      if (err?.response?.status === 404) {
        setErrorMsg(t.login_not_found ?? 'Username not found.')
      } else if (!err?.response) {
        // Network error = hub offline
        setErrorMsg(t.login_hub_offline ?? 'Hub is offline. Connect to hub to sign in.')
      } else {
        setErrorMsg(err?.response?.data?.detail || 'Error')
      }
    }
    setSubmitting(false)
  }

  return (
    <div style={{
      width: '100%', maxWidth: 400,
      background: '#1e293b', borderRadius: 20,
      padding: '24px 20px', border: '1px solid #334155',
      display: 'flex', flexDirection: 'column', gap: 16,
    }}>
      {/* Icon + title */}
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 40, marginBottom: 6 }}>🔑</div>
        <div style={{ fontSize: 17, fontWeight: 800, color: '#f1f5f9' }}>
          {t.login_title ?? 'Welcome Back'}
        </div>
        <div style={{ fontSize: 12, color: '#475569', marginTop: 4, lineHeight: 1.5 }}>
          {t.login_subtitle ?? 'Enter your username to restore your account'}
        </div>
      </div>

      {/* Username field */}
      <Field
        label={t.login_username ?? 'Username'}
        icon="@"
        value={username}
        onChange={v => { setUsername(v.replace(/\s/g, '')); setErrorMsg('') }}
        placeholder="fantatech_user"
        rtl={false}
      />

      {/* Error / success messages */}
      {errorMsg && (
        <div style={{
          background: '#450a0a', border: '1px solid #ef444455',
          borderRadius: 10, padding: '10px 14px',
          fontSize: 12, color: '#fca5a5', lineHeight: 1.5,
        }}>
          ❌ {errorMsg}
        </div>
      )}
      {successMsg && (
        <div style={{
          background: '#14532d', border: '1px solid #22c55e55',
          borderRadius: 10, padding: '10px 14px',
          fontSize: 13, color: '#86efac', fontWeight: 600, textAlign: 'center',
        }}>
          ✅ {successMsg}
        </div>
      )}

      {/* Sign in button */}
      <button onClick={handleLogin} disabled={submitting} style={{
        background: submitting ? '#334155' : 'linear-gradient(135deg, #1d4ed8, #7c3aed)',
        border: 'none', borderRadius: 12, padding: '13px',
        color: '#fff', fontSize: 15, fontWeight: 700,
        cursor: submitting ? 'default' : 'pointer',
        boxShadow: submitting ? 'none' : '0 4px 20px #1d4ed844',
        transition: 'all 0.2s',
      }}>
        {submitting ? '⏳' : (t.login_submit ?? 'Sign In')}
      </button>

      {/* Switch to register */}
      <button onClick={onSwitchMode} style={{
        background: 'none', border: 'none', color: '#38bdf8',
        fontSize: 12, cursor: 'pointer', padding: '2px', textDecoration: 'underline',
      }}>
        {t.register_tab ?? 'New Account'} →
      </button>

      {/* Update hint */}
      <div style={{
        background: 'rgba(56,189,248,0.07)', border: '1px solid #38bdf822',
        borderRadius: 10, padding: '10px 12px',
        fontSize: 10, color: '#475569', lineHeight: 1.6,
      }}>
        💡 {t.update_hint ?? 'To update without losing data, install the new APK directly over the existing one.'}
      </div>
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════════════
   MAIN COMPONENT
══════════════════════════════════════════════════════════════════════════ */
export default function RegistrationPage({ onComplete }) {
  const { t, rtl, lang, setLang } = useLang()

  // 'register' or 'login'
  const [mode, setMode] = useState('register')

  // Register fields
  const [plan,       setPlan]       = useState('free')
  const [name,       setName]       = useState('')
  const [username,   setUsername]   = useState('')
  const [email,      setEmail]      = useState('')
  const [address,    setAddress]    = useState('')
  const [cardHolder, setCardHolder] = useState('')
  const [cardNumber, setCardNumber] = useState('')
  const [cardExpiry, setCardExpiry] = useState('')
  const [cardCvv,    setCardCvv]    = useState('')
  const [terms,      setTerms]      = useState(false)
  const [errors,     setErrors]     = useState({})
  const [submitting, setSubmitting] = useState(false)

  const currentPlan = PLANS.find(p => p.id === plan)
  const isPaid      = currentPlan?.paid ?? false
  const clearErr    = field => setErrors(e => ({ ...e, [field]: undefined }))

  const validate = () => {
    const e = {}
    if (!name.trim())     e.name     = t.reg_name_req     ?? 'Required'
    if (!username.trim()) e.username = t.reg_username_req ?? 'Required'
    if (!email.trim())    e.email    = t.reg_email_req    ?? 'Required'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
                          e.email    = t.reg_email_invalid ?? 'Invalid email'
    if (!address.trim())  e.address  = t.reg_address_req  ?? 'Required'
    if (isPaid) {
      if (!cardHolder.trim())              e.cardHolder = t.reg_card_req      ?? 'Required'
      if (cardNumber.replace(/\s/g,'').length < 16) e.cardNumber = t.reg_card_num_req ?? '16 digits required'
      if (cardExpiry.length < 5)           e.cardExpiry = t.reg_card_expiry_req ?? 'MM/YY required'
      if (cardCvv.length < 3)              e.cardCvv    = t.reg_card_cvv_req   ?? '3 digits required'
    }
    if (!terms) e.terms = t.reg_terms_req ?? 'Accept terms to continue'
    return e
  }

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
    try {
      await api.post('/users/register', {
        plan, name: name.trim(), username: username.trim(),
        email: email.trim(), address: address.trim(),
        card_holder: cardHolder.trim(),
        card_number: cardNumber.replace(/\s/g, ''),
        card_expiry: cardExpiry,
        card_cvv:    cardCvv,
      })
    } catch {}
    setTimeout(() => { setSubmitting(false); onComplete(user) }, 320)
  }

  const handleSkip = () => {
    const user = { name: '', username: '', email: '', address: '', plan: 'free', registeredAt: Date.now(), skipped: true }
    try { localStorage.setItem('fantatech_user', JSON.stringify(user)) } catch {}
    onComplete(user)
  }

  /* ── Tab bar ── */
  const TabBar = () => (
    <div style={{
      display: 'flex', gap: 4,
      background: '#0f172a', borderRadius: 12, padding: 4,
      width: '100%', maxWidth: 400, marginBottom: 20,
    }}>
      {[
        { id: 'register', label: t.register_tab ?? 'New Account', icon: '📝' },
        { id: 'login',    label: t.login_tab    ?? 'Sign In',     icon: '🔑' },
      ].map(tab => (
        <button key={tab.id} onClick={() => setMode(tab.id)} style={{
          flex: 1, padding: '9px 6px', borderRadius: 9,
          border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 700,
          background: mode === tab.id ? '#1e293b' : 'transparent',
          color:      mode === tab.id ? '#38bdf8' : '#475569',
          boxShadow:  mode === tab.id ? '0 1px 6px rgba(0,0,0,0.4)' : 'none',
          transition: 'all 0.15s',
        }}>
          {tab.icon} {tab.label}
        </button>
      ))}
    </div>
  )

  return (
    <div style={{
      minHeight: '100vh', background: '#0a0f1e',
      color: '#f1f5f9', display: 'flex', flexDirection: 'column',
      alignItems: 'center', padding: '28px 16px 56px', overflowY: 'auto',
    }} dir={rtl ? 'rtl' : 'ltr'}>

      {/* Language picker */}
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

      {/* Header */}
      <div style={{ textAlign: 'center', marginBottom: 22 }}>
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

      {/* Tab switcher */}
      <TabBar />

      {/* ── SIGN IN MODE ── */}
      {mode === 'login' && (
        <LoginPanel
          onComplete={onComplete}
          onSwitchMode={() => setMode('register')}
          t={t} rtl={rtl}
        />
      )}

      {/* ── REGISTER MODE ── */}
      {mode === 'register' && (<>

        {/* Plan cards */}
        <div style={{ width: '100%', maxWidth: 580, marginBottom: 24 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#64748b', marginBottom: 12, textAlign: rtl ? 'right' : 'left' }}>
            {t.reg_choose_plan ?? 'Choose your plan'}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, justifyContent: 'center' }}>
            {PLANS.map(p => (
              <PlanCard key={p.id} plan={p} selected={plan === p.id}
                onSelect={id => { setPlan(id); setErrors({}) }} t={t} />
            ))}
          </div>
        </div>

        {/* Form */}
        <div style={{
          width: '100%', maxWidth: 440,
          background: '#1e293b', borderRadius: 20, padding: '22px 18px',
          border: `1px solid ${currentPlan ? currentPlan.color + '55' : '#334155'}`,
          display: 'flex', flexDirection: 'column', gap: 14,
        }}>

          <div style={{ fontSize: 11, fontWeight: 800, color: '#64748b', letterSpacing: 1, textTransform: 'uppercase' }}>
            👤 {t.reg_personal ?? 'Personal Details'}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <Field label={t.reg_name ?? 'Full Name'} icon="🙍" value={name}
              onChange={v => { setName(v); clearErr('name') }}
              placeholder={t.reg_name ?? 'Full Name'} error={errors.name} rtl={rtl} />
            <Field label={t.reg_username ?? 'Username'} icon="@" value={username}
              onChange={v => { setUsername(v.replace(/\s/g,'')); clearErr('username') }}
              placeholder="fantatech_user" error={errors.username} rtl={rtl} />
          </div>

          <Field label={t.reg_email ?? 'Email'} icon="✉️" type="email" value={email}
            onChange={v => { setEmail(v); clearErr('email') }}
            placeholder="you@example.com" error={errors.email} rtl={rtl} />

          <Field label={t.reg_address ?? 'Address'} icon="📍" value={address}
            onChange={v => { setAddress(v); clearErr('address') }}
            placeholder={t.reg_address_placeholder ?? 'Street, City, Country'}
            error={errors.address} rtl={rtl} />

          {isPaid && (
            <>
              <div style={{
                fontSize: 11, fontWeight: 800, color: currentPlan.color,
                letterSpacing: 1, textTransform: 'uppercase',
                paddingTop: 8, borderTop: '1px solid #334155',
              }}>
                💳 {t.reg_payment ?? 'Payment Details'}
              </div>

              <Field label={t.reg_card_holder ?? 'Cardholder Name'} icon="👤" value={cardHolder}
                onChange={v => { setCardHolder(v); clearErr('cardHolder') }}
                placeholder={t.reg_name ?? 'Full Name'} error={errors.cardHolder} rtl={rtl} />

              <Field label={t.reg_card_number ?? 'Card Number'} icon="💳" value={cardNumber}
                onChange={v => { setCardNumber(formatCard(v)); clearErr('cardNumber') }}
                placeholder="0000 0000 0000 0000" error={errors.cardNumber} rtl={false} maxLength={19} />

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <Field label={t.reg_card_expiry ?? 'Expiry (MM/YY)'} icon="📅" value={cardExpiry}
                  onChange={v => { setCardExpiry(formatExpiry(v)); clearErr('cardExpiry') }}
                  placeholder="MM/YY" error={errors.cardExpiry} rtl={false} maxLength={5} />
                <Field label="CVV" icon="🔒" type="password" value={cardCvv}
                  onChange={v => { setCardCvv(v.replace(/\D/g,'').slice(0,4)); clearErr('cardCvv') }}
                  placeholder="•••" error={errors.cardCvv} rtl={false} maxLength={4} />
              </div>

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
            <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer', flexDirection: rtl ? 'row-reverse' : 'row' }}>
              <input type="checkbox" checked={terms}
                onChange={e => { setTerms(e.target.checked); clearErr('terms') }}
                style={{ marginTop: 2, accentColor: currentPlan?.color ?? '#38bdf8', cursor: 'pointer', flexShrink: 0 }} />
              <span style={{ fontSize: 11, color: '#64748b', lineHeight: 1.6 }}>
                {t.reg_terms ?? 'I agree to the Terms of Use and Privacy Policy'}
              </span>
            </label>
            {errors.terms && <span style={{ fontSize: 11, color: '#ef4444' }}>{errors.terms}</span>}
          </div>

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

          {/* Already have account */}
          <button onClick={() => setMode('login')} style={{
            background: 'none', border: 'none', color: '#38bdf8',
            fontSize: 12, cursor: 'pointer', padding: '2px',
            textDecoration: 'underline', textAlign: 'center',
          }}>
            🔑 {t.reg_already ?? 'Already registered?'} {t.login_tab ?? 'Sign In'}
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
      </>)}

      <div style={{ marginTop: 24, fontSize: 10, color: '#1e293b' }}>FantaTech v2.10</div>
    </div>
  )
}
