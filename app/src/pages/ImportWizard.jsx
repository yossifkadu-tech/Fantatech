/**
 * ImportWizard.jsx — Import devices from external smart-home apps
 *
 * Supported now : SmartLife / Tuya Smart  (via Tuya IoT Cloud API)
 * Coming soon   : Philips Hue · IKEA Trådfri · Home Assistant · eWeLink
 *
 * Flow:
 *   Step 0 → choose source app
 *   Step 1 → enter Tuya IoT credentials (with step-by-step guide)
 *   Step 2 → fetched device list + checkboxes
 *   Step 3 → import result summary
 */
import { useState } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'
import { useScale } from '../context/ScaleContext'

/* ── Type icons ───────────────────────────────────────────────────────────── */
const TYPE_ICON = {
  light: '💡', switch: '🔌', dimmer: '🔆', sensor: '🌡️',
  motion: '👤', door: '🚪', smoke: '🔥', lock: '🔒',
  fan: '🌀', camera: '📷', gateway: '📡', ac: '❄️',
}
const typeIcon = (t) => TYPE_ICON[t] ?? '🔧'

/* ── Regions ─────────────────────────────────────────────────────────────── */
const REGIONS = [
  { value: 'eu',   label: 'Europe (EU)' },
  { value: 'us',   label: 'Americas (US)' },
  { value: 'cn',   label: 'China (CN)' },
  { value: 'in',   label: 'India (IN)' },
  { value: 'us-e', label: 'US East' },
  { value: 'eu-w', label: 'EU West' },
]

/* ── Sources ─────────────────────────────────────────────────────────────── */
const SOURCES = [
  {
    id:      'smartlife',
    name:    'SmartLife / Tuya Smart',
    icon:    '🌐',
    ready:   true,
    color:   '#f97316',
    desc:    'Import all devices linked to your SmartLife or Tuya Smart account',
  },
  { id: 'hue',  name: 'Philips Hue',      icon: '💡', ready: false, color: '#fbbf24', desc: 'Coming soon' },
  { id: 'ikea', name: 'IKEA Trådfri',     icon: '🏮', ready: false, color: '#4ade80', desc: 'Coming soon' },
  { id: 'ha',   name: 'Home Assistant',   icon: '🏠', ready: false, color: '#38bdf8', desc: 'Coming soon' },
  { id: 'ewe',  name: 'eWeLink / Sonoff', icon: '⚡', ready: false, color: '#a78bfa', desc: 'Coming soon' },
]

/* ── Shared helpers ───────────────────────────────────────────────────────── */
const LINK = 'https://iot.tuya.com'

function Field({ label, value, onChange, type = 'text', placeholder = '' }) {
  return (
    <label style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
      <span style={{ fontSize: 11, color: '#94a3b8', fontWeight: 700 }}>{label}</span>
      <input
        value={value}
        onChange={e => onChange(e.target.value)}
        type={type}
        placeholder={placeholder}
        autoCapitalize="off"
        autoCorrect="off"
        style={{
          background: '#0f172a', border: '1px solid #334155', borderRadius: 8,
          padding: '9px 12px', color: '#e2e8f0', fontSize: 13, outline: 'none',
          width: '100%', boxSizing: 'border-box',
        }}
      />
    </label>
  )
}

/* ─────────────────────────────────────────────────────────────────────────── */

export default function ImportWizard({ onClose, onImported }) {
  const { t } = useLang()
  const { sp, spx, phone } = useScale()

  const [step,     setStep]     = useState(0)
  const [source,   setSource]   = useState(null)
  const [region,   setRegion]   = useState('eu')
  const [accessId, setAccessId] = useState('')
  const [secret,   setSecret]   = useState('')
  const [loading,  setLoading]  = useState(false)
  const [error,    setError]    = useState('')
  const [devices,  setDevices]  = useState([])    // fetched from cloud
  const [selected, setSelected] = useState({})    // id → bool
  const [result,   setResult]   = useState(null)  // import result
  const [showGuide, setShowGuide] = useState(false)

  /* ── step handlers ────────────────────────────────────────────────────── */

  const handleFetch = async () => {
    if (!accessId.trim() || !secret.trim()) {
      setError(t.import_creds_required ?? 'Access ID and Secret are required')
      return
    }
    setLoading(true); setError('')
    try {
      const res = await api.post('/tuya/cloud-fetch', {
        region, access_id: accessId.trim(), access_secret: secret.trim(),
      })
      const devs = res.data.devices ?? []
      setDevices(devs)
      // Pre-select all online devices
      const sel = {}
      devs.forEach(d => { sel[d.id] = d.online })
      setSelected(sel)
      setStep(2)
    } catch (e) {
      const msg = e?.response?.data?.detail ?? e.message ?? 'Connection error'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }

  const handleImport = async () => {
    const toImport = devices.filter(d => selected[d.id])
    if (!toImport.length) {
      setError(t.import_none_selected ?? 'Select at least one device')
      return
    }
    setLoading(true); setError('')
    try {
      const res = await api.post('/tuya/cloud-import', {
        region, access_id: accessId.trim(), access_secret: secret.trim(),
        devices: toImport,
      })
      setResult(res.data)
      setStep(3)
      onImported?.()
    } catch (e) {
      setError(e?.response?.data?.detail ?? e.message ?? 'Import failed')
    } finally {
      setLoading(false)
    }
  }

  const toggleAll = (val) => {
    const sel = {}
    devices.forEach(d => { sel[d.id] = val })
    setSelected(sel)
  }
  const selectedCount = Object.values(selected).filter(Boolean).length

  /* ── render helpers ───────────────────────────────────────────────────── */

  const modalW = Math.min(phone ? 360 : 500, window.innerWidth - 24)

  const btnPrimary = {
    background: loading ? '#334155' : '#2563eb', color: '#fff',
    border: 'none', borderRadius: sp(10), padding: `${spx(11)} ${spx(20)}`,
    cursor: loading ? 'default' : 'pointer', fontWeight: 700, fontSize: spx(14),
    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: sp(6),
    WebkitTapHighlightColor: 'transparent',
  }
  const btnGhost = {
    background: 'transparent', border: '1px solid #334155', color: '#94a3b8',
    borderRadius: sp(10), padding: `${spx(10)} ${spx(16)}`,
    cursor: 'pointer', fontWeight: 600, fontSize: spx(13),
    WebkitTapHighlightColor: 'transparent',
  }

  /* ── Step 0: Source selection ─────────────────────────────────────────── */
  const renderStep0 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: sp(10) }}>
      <p style={{ margin: 0, fontSize: spx(13), color: '#94a3b8', lineHeight: 1.6 }}>
        {t.import_choose_source ?? 'Choose the app you want to import devices from:'}
      </p>
      {SOURCES.map(src => (
        <button
          key={src.id}
          onClick={() => { if (src.ready) { setSource(src.id); setStep(1) } }}
          style={{
            display: 'flex', alignItems: 'center', gap: sp(12),
            padding: `${spx(12)} ${spx(14)}`,
            background: src.ready ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.2)',
            border: `1px solid ${src.ready ? '#334155' : '#1e293b'}`,
            borderRadius: sp(12), cursor: src.ready ? 'pointer' : 'default',
            opacity: src.ready ? 1 : 0.45, textAlign: 'left',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          <span style={{
            fontSize: spx(28), width: sp(44), height: sp(44), borderRadius: sp(10),
            background: `${src.color}22`, border: `1px solid ${src.color}44`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>{src.icon}</span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: spx(14), fontWeight: 700, color: src.ready ? '#e2e8f0' : '#475569' }}>
              {src.name}
            </div>
            <div style={{ fontSize: spx(11), color: src.ready ? '#64748b' : '#334155', marginTop: 2 }}>
              {src.ready ? src.desc : (t.import_coming_soon ?? 'Coming soon')}
            </div>
          </div>
          {src.ready && <span style={{ fontSize: spx(16), color: '#334155' }}>›</span>}
        </button>
      ))}
    </div>
  )

  /* ── Step 1: Credentials ──────────────────────────────────────────────── */
  const renderStep1 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: sp(16) }}>

      {/* Region */}
      <label style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
        <span style={{ fontSize: spx(11), color: '#94a3b8', fontWeight: 700 }}>
          {t.import_region ?? 'Region'}
        </span>
        <select
          value={region}
          onChange={e => setRegion(e.target.value)}
          style={{
            background: '#0f172a', border: '1px solid #334155', borderRadius: 8,
            padding: '9px 12px', color: '#e2e8f0', fontSize: spx(13), outline: 'none',
          }}
        >
          {REGIONS.map(r => (
            <option key={r.value} value={r.value}>{r.label}</option>
          ))}
        </select>
      </label>

      <Field
        label={t.import_access_id ?? 'Access ID (apiKey)'}
        value={accessId} onChange={setAccessId}
        placeholder="xxxxxxxxxxxxxxxxxxxx"
      />
      <Field
        label={t.import_access_secret ?? 'Access Secret (apiSecret)'}
        value={secret} onChange={setSecret}
        type="password"
        placeholder="••••••••••••••••••••"
      />

      {/* How-to guide toggle */}
      <div>
        <button
          onClick={() => setShowGuide(v => !v)}
          style={{ ...btnGhost, fontSize: spx(12), padding: `${spx(7)} ${spx(12)}` }}
        >
          {showGuide ? '▲' : '▼'} {t.import_how_to ?? 'How to get these credentials'}
        </button>

        {showGuide && (
          <div style={{
            marginTop: sp(10), background: '#0f172a', border: '1px solid #1e3a5f',
            borderRadius: sp(10), padding: `${spx(12)} ${spx(14)}`,
            fontSize: spx(12), color: '#94a3b8', lineHeight: 1.8,
          }}>
            {[
              ['1', t.import_step1 ?? 'Open iot.tuya.com and sign in (or create a free account)'],
              ['2', t.import_step2 ?? 'Click "Create Project" → choose "Smart Home" protocol'],
              ['3', t.import_step3 ?? 'On the project page, copy the Access ID and Access Secret'],
              ['4', t.import_step4 ?? 'In the project: click "Link Tuya App Account" → scan the QR with SmartLife app'],
              ['5', t.import_step5 ?? 'Come back here and paste the credentials above'],
            ].map(([n, text]) => (
              <div key={n} style={{ display: 'flex', gap: sp(8), marginBottom: sp(6) }}>
                <span style={{
                  flexShrink: 0, width: sp(20), height: sp(20), borderRadius: '50%',
                  background: '#1e3a5f', color: '#38bdf8',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: spx(10), fontWeight: 800,
                }}>{n}</span>
                <span>{text}</span>
              </div>
            ))}
            <a
              href={LINK} target="_blank" rel="noreferrer"
              style={{ color: '#38bdf8', fontSize: spx(12), marginTop: sp(6), display: 'block' }}
            >
              🌐 iot.tuya.com →
            </a>
          </div>
        )}
      </div>

      {error && <ErrorBox msg={error} />}

      <div style={{ display: 'flex', gap: sp(8) }}>
        <button style={{ ...btnGhost, flex: 1 }} onClick={() => setStep(0)}>← {t.back ?? 'Back'}</button>
        <button style={{ ...btnPrimary, flex: 2 }} onClick={handleFetch} disabled={loading}>
          {loading ? <Spinner /> : `🔍 ${t.import_fetch ?? 'Fetch My Devices'}`}
        </button>
      </div>
    </div>
  )

  /* ── Step 2: Device list + checkboxes ─────────────────────────────────── */
  const renderStep2 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: sp(12) }}>

      {/* Summary row */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        background: '#0f172a', borderRadius: sp(10), padding: `${spx(10)} ${spx(14)}`,
        border: '1px solid #334155',
      }}>
        <span style={{ fontSize: spx(13), color: '#94a3b8' }}>
          {devices.length} {t.import_devices_found ?? 'devices found'}
        </span>
        <div style={{ display: 'flex', gap: sp(8) }}>
          <button style={{ ...btnGhost, fontSize: spx(11), padding: `${spx(5)} ${spx(10)}` }}
            onClick={() => toggleAll(true)}>
            {t.import_select_all ?? 'All'}
          </button>
          <button style={{ ...btnGhost, fontSize: spx(11), padding: `${spx(5)} ${spx(10)}` }}
            onClick={() => toggleAll(false)}>
            {t.import_deselect_all ?? 'None'}
          </button>
        </div>
      </div>

      {/* Scrollable device list */}
      <div style={{ maxHeight: 320, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: sp(6) }}
        className="ft-scroll">
        {devices.map(dev => {
          const checked = !!selected[dev.id]
          return (
            <label key={dev.id} style={{
              display: 'flex', alignItems: 'center', gap: sp(10),
              background: checked ? 'rgba(37,99,235,0.08)' : '#0f172a',
              border: `1px solid ${checked ? '#2563eb44' : '#1e293b'}`,
              borderRadius: sp(10), padding: `${spx(10)} ${spx(12)}`,
              cursor: 'pointer',
            }}>
              <input
                type="checkbox"
                checked={checked}
                onChange={e => setSelected(s => ({ ...s, [dev.id]: e.target.checked }))}
                style={{ width: sp(16), height: sp(16), accentColor: '#2563eb', flexShrink: 0 }}
              />
              <span style={{ fontSize: spx(20), flexShrink: 0 }}>{typeIcon(dev.type)}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: spx(13), fontWeight: 600, color: '#e2e8f0',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>
                  {dev.name}
                </div>
                <div style={{ fontSize: spx(10), color: '#475569', marginTop: 1 }}>
                  {dev.type}
                  {dev.category ? ` · ${dev.category}` : ''}
                  {dev.ip ? ` · ${dev.ip}` : ''}
                </div>
              </div>
              <span style={{
                fontSize: spx(9), fontWeight: 700, padding: '2px 7px',
                borderRadius: 20, flexShrink: 0,
                background: dev.online ? 'rgba(34,197,94,0.1)' : 'rgba(100,116,139,0.1)',
                color: dev.online ? '#22c55e' : '#64748b',
                border: `1px solid ${dev.online ? '#22c55e44' : '#33415544'}`,
              }}>
                {dev.online ? '● Online' : '○ Offline'}
              </span>
            </label>
          )
        })}
      </div>

      {error && <ErrorBox msg={error} />}

      <div style={{ display: 'flex', gap: sp(8) }}>
        <button style={{ ...btnGhost, flex: 1 }} onClick={() => setStep(1)}>← {t.back ?? 'Back'}</button>
        <button
          style={{ ...btnPrimary, flex: 2 }} disabled={loading || !selectedCount}
          onClick={handleImport}
        >
          {loading
            ? <Spinner />
            : `📥 ${t.import_btn ?? 'Import'} (${selectedCount})`}
        </button>
      </div>
    </div>
  )

  /* ── Step 3: Result ───────────────────────────────────────────────────── */
  const renderStep3 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: sp(16), alignItems: 'center', textAlign: 'center' }}>
      <span style={{ fontSize: spx(52) }}>🎉</span>
      <div>
        <div style={{ fontSize: spx(20), fontWeight: 800, color: '#22c55e', marginBottom: sp(4) }}>
          {result?.imported ?? 0} {t.import_success_count ?? 'devices imported!'}
        </div>
        <div style={{ fontSize: spx(12), color: '#64748b', lineHeight: 1.6 }}>
          {t.import_success_hint ??
            'Devices have been added to your hub. If a device shows as offline, make sure it is on the same Wi-Fi network as this PC.'}
        </div>
      </div>

      {/* Per-device result */}
      {result?.devices?.length > 0 && (
        <div style={{
          width: '100%', maxHeight: 200, overflowY: 'auto',
          display: 'flex', flexDirection: 'column', gap: sp(4),
        }} className="ft-scroll">
          {result.devices.map((d, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              background: '#0f172a', borderRadius: sp(8), padding: `${spx(7)} ${spx(12)}`,
              fontSize: spx(11), color: '#94a3b8',
            }}>
              <span style={{ fontWeight: 600, color: '#e2e8f0' }}>{d.name}</span>
              <div style={{ display: 'flex', gap: sp(8) }}>
                <span style={{ color: d.ip ? '#22c55e' : '#f59e0b' }}>
                  {d.ip ? `📡 ${d.ip}` : '📡 No IP yet'}
                </span>
                <span style={{ color: d.has_key ? '#22c55e' : '#ef4444' }}>
                  {d.has_key ? '🔑 Key ✓' : '🔑 No key'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {!result?.devices?.some(d => d.ip) && (
        <div style={{
          background: '#1c0f00', border: '1px solid #f59e0b', borderRadius: sp(10),
          padding: `${spx(10)} ${spx(14)}`, fontSize: spx(12), color: '#fcd34d',
          textAlign: 'left', width: '100%',
        }}>
          ⚠️ {t.import_no_ip_hint ??
            'No devices were found on the local network. Make sure your hub PC and all Tuya devices are connected to the same Wi-Fi, then go to Devices → Tuya scan to detect IPs.'}
        </div>
      )}

      <div style={{ display: 'flex', gap: sp(8), width: '100%' }}>
        <button style={{ ...btnGhost, flex: 1 }} onClick={() => { setStep(0); setResult(null); setDevices([]) }}>
          {t.import_more ?? '+ Import More'}
        </button>
        <button style={{ ...btnPrimary, flex: 2 }} onClick={onClose}>
          {t.import_done ?? 'Go to Devices ›'}
        </button>
      </div>
    </div>
  )

  /* ── Modal shell ──────────────────────────────────────────────────────── */
  const stepTitles = [
    t.import_title       ?? '📥 Import Devices',
    t.import_creds_title ?? '🔑 Tuya IoT Credentials',
    t.import_select_title ?? `📋 Select Devices to Import`,
    t.import_done_title  ?? '✅ Import Complete',
  ]

  return (
    <div
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 400, padding: sp(12),
      }}
      onClick={e => e.target === e.currentTarget && onClose()}
    >
      <div style={{
        background: '#1e293b', border: '1px solid #334155', borderRadius: sp(16),
        padding: `${spx(18)} ${spx(20)}`,
        width: '100%', maxWidth: modalW,
        display: 'flex', flexDirection: 'column', gap: sp(16),
        maxHeight: '92vh', overflowY: 'auto',
      }} className="ft-scroll">

        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: spx(16), fontWeight: 800, color: '#e2e8f0' }}>
              {stepTitles[step]}
            </div>
            {/* Progress dots */}
            <div style={{ display: 'flex', gap: sp(5), marginTop: sp(5) }}>
              {[0,1,2,3].map(i => (
                <div key={i} style={{
                  width: sp(i === step ? 16 : 6), height: sp(6),
                  borderRadius: sp(3),
                  background: i === step ? '#2563eb' : i < step ? '#22c55e' : '#334155',
                  transition: 'all 0.25s',
                }} />
              ))}
            </div>
          </div>
          <button
            onClick={onClose}
            style={{ ...btnGhost, padding: `${spx(5)} ${spx(10)}`, fontSize: spx(16) }}
          >✕</button>
        </div>

        {/* Step content */}
        {step === 0 && renderStep0()}
        {step === 1 && renderStep1()}
        {step === 2 && renderStep2()}
        {step === 3 && renderStep3()}
      </div>
    </div>
  )
}

/* ── Tiny sub-components ─────────────────────────────────────────────────── */

function Spinner() {
  return (
    <span style={{
      width: 16, height: 16, border: '2px solid #ffffff44',
      borderTop: '2px solid #fff', borderRadius: '50%',
      display: 'inline-block',
      animation: 'spin 0.7s linear infinite',
    }}>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </span>
  )
}

function ErrorBox({ msg }) {
  return (
    <div style={{
      background: '#450a0a', border: '1px solid #ef4444', borderRadius: 8,
      padding: '9px 12px', fontSize: 12, color: '#fca5a5',
    }}>
      ⚠️ {msg}
    </div>
  )
}
