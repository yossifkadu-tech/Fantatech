import { useState, useEffect } from 'react'
import { api, getHubUrl, setHubUrl, clearHubUrl, testHubUrl, discoverHub } from '../hooks/useHub'
import { useLang, LANG_META, detectDeviceLang } from '../context/LangContext'
import { useScale, DISPLAY_STEPS, DISPLAY_LABELS } from '../context/ScaleContext'
import { loadAds, saveAds, loc as locAd } from '../components/SponsoredBanner'

const APP_VERSION = '2.0.0'

export default function SettingsPage() {
  const { lang, t, setLang, resetToDevice, rtl } = useLang()
  const { displayIdx, setDisplayIdx, phone, tablet, desktop } = useScale()
  const deviceLang = detectDeviceLang()            // what device would pick right now
  // Hub connection
  const [hubUrl, setHubUrlState]        = useState(getHubUrl)
  const [newHubIp, setNewHubIp]         = useState('')
  const [hubTestMsg, setHubTestMsg]     = useState(null)
  const [hubTesting, setHubTesting]     = useState(false)
  const [discovering, setDiscovering]   = useState(false)
  const [discoverProgress, setDiscoverProgress] = useState('')
  const [diagRunning, setDiagRunning]   = useState(false)
  const [diagResult, setDiagResult]     = useState(null)

  const [sensiboKey, setSensiboKey]     = useState('')
  const [sensiboSaved, setSensiboSaved] = useState(false)
  const [sensiboStatus, setSensiboStatus] = useState(null)
  const [geminiKey, setGeminiKey]       = useState('')
  const [geminiSaved, setGeminiSaved]   = useState(false)
  const [geminiStatus, setGeminiStatus] = useState(null)
  const [geminiTesting, setGeminiTesting] = useState(false)
  const [geminiTestMsg, setGeminiTestMsg] = useState(null)
  const [ads, setAdsState]              = useState(() => loadAds())
  const [adForm, setAdForm]             = useState(null) // null or ad object being edited
  const [haUrl, setHaUrl]               = useState('')
  const [haToken, setHaToken]       = useState('')
  const [importing, setImporting]   = useState(false)
  const [importMsg, setImportMsg]   = useState(null)
  const [hubVersion, setHubVersion] = useState('…')

  useEffect(() => {
    api.get('/version').then(r => setHubVersion(r.data.version)).catch(() => {})
    api.get('/ac/sensibo/status').then(r => setSensiboStatus(r.data.configured)).catch(() => {})
    api.get('/ai/status').then(r => setGeminiStatus(r.data.configured)).catch(() => {})
    setHaUrl(localStorage.getItem('ha_url') || '')
    setHaToken(localStorage.getItem('ha_token') || '')
  }, [])

  /* ── Hub connection ── */
  const saveNewHub = async () => {
    const ip = newHubIp.trim()
    if (!ip) return
    const url = ip.startsWith('http') ? ip : `http://${ip}:8080`
    setHubTesting(true); setHubTestMsg(null)
    const ok = await testHubUrl(url)
    setHubTesting(false)
    if (ok) {
      setHubUrl(url)
      setHubUrlState(url)
      setNewHubIp('')
      setHubTestMsg({ text: `${t.hub_conn_ok_prefix} ${url}`, ok: true })
    } else {
      setHubTestMsg({ text: `${t.hub_conn_fail_prefix} ${url}`, ok: false })
    }
  }

  /* ── Connectivity Diagnose ── */
  const runDiagnose = async () => {
    setDiagRunning(true); setDiagResult(null)
    try {
      const r = await api.get('/network/diagnose', { timeout: 20000 })
      setDiagResult(r.data)
    } catch {
      setDiagResult({
        overall: 'fail',
        summary: `${t.hub_conn_fail_prefix} Hub`,
        checks: [],
      })
    }
    setDiagRunning(false)
  }

  const runDiscover = async () => {
    setDiscovering(true); setHubTestMsg(null); setDiscoverProgress(t.hub_discover_starting)
    const found = await discoverHub(msg => setDiscoverProgress(msg))
    setDiscovering(false); setDiscoverProgress('')
    if (found) {
      setHubUrl(found)
      setHubUrlState(found)
      setHubTestMsg({ text: `${t.hub_discover_found_prefix} ${found}`, ok: true })
    } else {
      setHubTestMsg({ text: t.hub_discover_not_found, ok: false })
    }
  }

  /* ── Gemini key ── */
  const testGeminiConnection = async () => {
    setGeminiTesting(true); setGeminiTestMsg(null)
    try {
      const r = await api.post('/ai/chat', { message: 'Hello, reply with just "OK"', lang: 'en', history: [] })
      setGeminiTestMsg({ ok: true, text: `✅ Gemini connected — "${r.data.reply?.slice(0, 60)}"` })
      setGeminiStatus(true)
    } catch (e) {
      const msg = e?.response?.data?.detail || e?.message || 'Connection failed'
      setGeminiTestMsg({ ok: false, text: `❌ ${msg}` })
    }
    setGeminiTesting(false)
  }

  const saveGeminiKey = async () => {
    try {
      await api.post('/ai/set-key', { key: geminiKey.trim() })
      setGeminiSaved(true)
      setGeminiStatus(true)
      setTimeout(() => setGeminiSaved(false), 3000)
    } catch {
      setHubTestMsg({ text: t.gemini_key_err, ok: false })
      setTimeout(() => setHubTestMsg(null), 4000)
    }
  }

  /* ── Sensibo key ── */
  const saveSensiboKey = async () => {
    try {
      await api.post('/ac/sensibo/set-key', { key: sensiboKey.trim() })
      setSensiboSaved(true)
      setSensiboStatus(true)
      setTimeout(() => setSensiboSaved(false), 3000)
    } catch {
      setHubTestMsg({ text: t.sensibo_key_err, ok: false })
      setTimeout(() => setHubTestMsg(null), 4000)
    }
  }

  /* ── Ads management ── */
  const saveAdEdit = () => {
    if (!adForm) return
    const updated = adForm.id
      ? ads.map(a => a.id === adForm.id ? adForm : a)
      : [...ads, { ...adForm, id: `ad-${Date.now()}` }]
    setAdsState(updated)
    saveAds(updated)
    setAdForm(null)
  }
  const deleteAd = (id) => {
    const updated = ads.filter(a => a.id !== id)
    setAdsState(updated)
    saveAds(updated)
  }
  const toggleAdActive = (id) => {
    const updated = ads.map(a => a.id === id ? { ...a, active: !a.active } : a)
    setAdsState(updated)
    saveAds(updated)
  }
  const BLANK_AD = { id: null, title: '', desc: '', imageUrl: '', url: '', btnLabel: t.details_btn ?? 'Details ›', color: '#1d4ed8', active: true, sponsored: true }

  const resetAdsToDefaults = () => {
    localStorage.removeItem('fantatech_ads')
    const fresh = loadAds()
    setAdsState(fresh)
  }

  /* ── Export devices ── */
  const exportDevices = async () => {
    try {
      const r = await api.get('/devices/')
      const json = JSON.stringify(r.data, null, 2)
      const blob = new Blob([json], { type: 'application/json' })
      const url  = URL.createObjectURL(blob)
      const a    = document.createElement('a')
      a.href = url; a.download = 'fantatech-devices.json'; a.click()
      URL.revokeObjectURL(url)
    } catch { alert(t.export_err) }
  }

  /* ── Import devices from JSON file ── */
  const importFromFile = (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = async (ev) => {
      try {
        const devices = JSON.parse(ev.target.result)
        if (!Array.isArray(devices)) throw new Error('invalid')
        setImporting(true); setImportMsg(null)
        let ok = 0, fail = 0
        for (const d of devices) {
          try { await api.post('/devices/', d); ok++ } catch { fail++ }
        }
        setImportMsg({ text: `${ok} ${t.devices} ${t.import_devices.toLowerCase()}${fail ? ` | ${fail} ${t.error.toLowerCase()}` : ''}`, ok: ok > 0 })
      } catch (err) {
        setImportMsg({ text: `${t.error}: ${err.message}`, ok: false })
      }
      setImporting(false)
    }
    reader.readAsText(file)
    e.target.value = ''
  }

  /* ── Import from Home Assistant ── */
  const importFromHA = async () => {
    if (!haUrl || !haToken) { setImportMsg({ text: t.ha_required, ok: false }); return }
    localStorage.setItem('ha_url', haUrl)
    localStorage.setItem('ha_token', haToken)
    setImporting(true); setImportMsg(null)
    try {
      const r = await api.post('/ai/import-ha', { url: haUrl, token: haToken })
      setImportMsg({ text: r.data.message || t.import_ha_success, ok: true })
    } catch (e) {
      setImportMsg({ text: e?.response?.data?.detail || t.import_ha_failed, ok: false })
    }
    setImporting(false)
  }

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>
      <h2 style={{ margin: '0 0 20px', color: '#e2e8f0', fontSize: 18 }}>{t.settings}</h2>

      {/* ── Screen Settings — calibration reset (all devices) ── */}
      <Section title={`🖥️ ${t.screen_settings ?? 'Screen Settings'}`}>
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 14, lineHeight: 1.7 }}>
          {t.screen_settings_hint ?? 'Reset the screen calibration to re-detect your device and set the optimal display size.'}
        </div>

        {/* Current device info */}
        <div style={{
          background: '#0f172a', borderRadius: 8, padding: '8px 12px',
          fontSize: 12, color: '#94a3b8', marginBottom: 14,
          display: 'flex', gap: 16, flexWrap: 'wrap',
        }}>
          <span>📐 {window.innerWidth} × {window.innerHeight} px</span>
          <span>⚡ ×{(window.devicePixelRatio || 1).toFixed(1)} DPR</span>
          <span>{phone ? '📱 Phone' : tablet ? '📲 Tablet' : '🖥️ Desktop'}</span>
        </div>

        {/* Reset calibration button */}
        <button
          onClick={() => {
            localStorage.removeItem('fantatech_calibrated')
            localStorage.removeItem('fantatech_display_scale')
            window.location.reload()
          }}
          style={{
            width: '100%', padding: '12px',
            background: 'linear-gradient(90deg,#0ea5e9,#6366f1)',
            border: 'none', borderRadius: 10,
            color: '#fff', fontSize: 14, fontWeight: 700,
            cursor: 'pointer',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          🔄 {t.screen_recalibrate ?? 'Re-calibrate Screen'}
        </button>
      </Section>

      {/* ── Display Size — tablet & desktop only (phone is always 1:1) ── */}
      {!phone && (
        <Section title={`🔡 ${t.display_size ?? 'Display Size'}`}>
          <div style={{ fontSize: 12, color: '#64748b', marginBottom: 12, lineHeight: 1.6 }}>
            {t.display_size_hint ?? 'Adjust text and element size to fit your screen.'}
          </div>
          {/* 5-step size buttons */}
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            {DISPLAY_LABELS.map((label, idx) => {
              const active = idx === displayIdx
              const pct    = Math.round(DISPLAY_STEPS[idx] * 100)
              return (
                <button
                  key={idx}
                  onClick={() => setDisplayIdx(idx)}
                  style={{
                    flex: 1, padding: '10px 4px',
                    border: `2px solid ${active ? '#38bdf8' : '#334155'}`,
                    borderRadius: 10,
                    background: active ? 'rgba(56,189,248,0.12)' : '#0f172a',
                    color: active ? '#38bdf8' : '#64748b',
                    cursor: 'pointer',
                    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
                    WebkitTapHighlightColor: 'transparent',
                    transition: 'all 0.15s',
                  }}
                >
                  <span style={{ fontSize: 10 + idx * 3, fontWeight: 800, lineHeight: 1, color: active ? '#38bdf8' : '#64748b' }}>A</span>
                  <span style={{ fontSize: 9, fontWeight: 700 }}>{label}</span>
                  <span style={{ fontSize: 8, color: active ? '#7dd3fc' : '#475569' }}>{pct}%</span>
                </button>
              )
            })}
          </div>
          <div style={{ marginTop: 10, fontSize: 11, color: '#475569', textAlign: 'center' }}>
            {tablet  ? `📲 ${t.display_device_tablet  ?? 'Tablet — adjust to fit your screen size'}` : ''}
            {desktop ? `🖥️ ${t.display_device_desktop ?? 'Desktop — size preference only'}`          : ''}
          </div>
        </Section>
      )}

      {/* ── Hub Connection ── */}
      <Section title={t.hub_conn_section}>
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
          {t.hub_current_addr_label}
        </div>
        <div style={{
          background: '#0f172a', borderRadius: 8, padding: '8px 12px',
          fontSize: 12, color: '#38bdf8', marginBottom: 12,
          wordBreak: 'break-all', direction: 'ltr',
        }}>
          {hubUrl || t.hub_not_set}
        </div>

        {/* Auto-discover */}
        <button onClick={runDiscover} disabled={discovering}
          style={{ ...btn('#22c55e'), width: '100%', marginBottom: 8, opacity: discovering ? 0.7 : 1 }}>
          {discovering ? `🔍 ${discoverProgress}` : t.hub_auto_discover_btn}
        </button>

        {/* Manual */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
          <input
            value={newHubIp}
            onChange={e => setNewHubIp(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && saveNewHub()}
            placeholder="192.168.1.x"
            style={{ ...inp, flex: 1, direction: 'ltr', marginBottom: 0 }}
          />
          <button onClick={saveNewHub} disabled={hubTesting}
            style={{ ...btn('#1d4ed8'), padding: '10px 14px', opacity: hubTesting ? 0.7 : 1 }}>
            {hubTesting ? '...' : t.save}
          </button>
        </div>

        {hubTestMsg && (
          <div style={{
            padding: '8px 12px', borderRadius: 8, fontSize: 12,
            background: hubTestMsg.ok ? '#14532d' : '#7f1d1d',
            border: `1px solid ${hubTestMsg.ok ? '#22c55e' : '#ef4444'}`,
            color: '#f1f5f9', marginTop: 8,
          }}>{hubTestMsg.text}</div>
        )}

        {/* ── Diagnose button ── */}
        <button onClick={runDiagnose} disabled={diagRunning} style={{
          ...btn('#334155'), width: '100%', marginTop: 10,
          opacity: diagRunning ? 0.7 : 1, fontSize: 13,
        }}>
          {diagRunning ? t.hub_diag_running_label : t.hub_diag_btn_label}
        </button>

        {/* ── Diagnose results ── */}
        {diagResult && (
          <div style={{ marginTop: 10 }}>
            <div style={{
              padding: '10px 14px', borderRadius: 10, fontSize: 13, fontWeight: 700,
              marginBottom: 8,
              background: diagResult.overall === 'ok' ? '#14532d'
                        : diagResult.overall === 'warn' ? '#451a03' : '#7f1d1d',
              border: `1px solid ${diagResult.overall === 'ok' ? '#22c55e'
                        : diagResult.overall === 'warn' ? '#f59e0b' : '#ef4444'}`,
              color: '#f1f5f9',
            }}>
              {diagResult.summary}
            </div>

            {diagResult.checks?.map((c, i) => (
              <div key={i} style={{
                background: '#0f172a',
                border: `1px solid ${c.status === 'ok' ? '#22c55e33'
                          : c.status === 'warn' ? '#f59e0b33' : '#ef444433'}`,
                borderRadius: 8, padding: '8px 12px', marginBottom: 6,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: 16 }}>
                    {c.status === 'ok' ? '✅' : c.status === 'warn' ? '⚠️' : '❌'}
                  </span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: '#e2e8f0' }}>
                      {c.name}
                    </div>
                    <div style={{ fontSize: 11, color: '#64748b', direction: 'ltr' }}>
                      {c.value}
                    </div>
                  </div>
                </div>
                {c.fix && (
                  <div style={{
                    marginTop: 6, fontSize: 11, color: '#fcd34d',
                    background: '#1c1007', borderRadius: 6,
                    padding: '6px 10px', lineHeight: 1.6,
                  }}>
                    🔧 {c.fix}
                  </div>
                )}
              </div>
            ))}

            {/* AP Isolation specific help */}
            {diagResult.checks?.some(c => c.fix?.includes('AP Isolation')) && (
              <div style={{
                background: '#1c1007', border: '1px solid #f59e0b',
                borderRadius: 10, padding: '10px 14px', marginTop: 6, fontSize: 11,
                color: '#fcd34d', lineHeight: 1.8,
              }}>
                <b>{t.ap_isolation_title}</b><br/>
                1. {t.ap_step_open_browser} <b style={{ direction: 'ltr', display: 'inline-block' }}>{diagResult.gateway || '192.168.1.1'}</b><br/>
                2. {t.ap_step_login}<br/>
                3. {t.ap_step_wireless}<br/>
                4. {t.ap_step_find}<br/>
                5. {t.ap_step_disable}
              </div>
            )}
          </div>
        )}
      </Section>

      {/* ── Language ── */}
      <Section title={`🌍 ${t.language}`}>
        {/* Device-detected language indicator */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          background: '#0f172a', borderRadius: 10, padding: '8px 12px', marginBottom: 12,
          border: '1px solid #1e3a5f',
        }}>
          <div style={{ fontSize: 12, color: '#94a3b8' }}>
            📱 {t.lang_device_detected ?? 'Device language'}:{' '}
            <span style={{ color: '#38bdf8', fontWeight: 700 }}>
              {LANG_META[deviceLang]?.name ?? deviceLang}
            </span>
          </div>
          {lang !== deviceLang && (
            <button
              onClick={resetToDevice}
              style={{
                background: '#1e3a5f', border: '1px solid #38bdf8',
                borderRadius: 8, padding: '4px 10px',
                color: '#38bdf8', fontSize: 11, fontWeight: 700,
                cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
              }}
            >
              {t.lang_reset ?? 'Reset'}
            </button>
          )}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {Object.entries(LANG_META).map(([code, meta]) => {
            const active = lang === code
            const isDevice = code === deviceLang
            const LANG_COLORS = {
              he: '#1d4ed8', en: '#dc2626', ar: '#15803d',
              ru: '#7c3aed', es: '#d97706', fr: '#0284c7',
              de: '#475569', pt: '#059669', am: '#b91c1c',
            }
            const color = LANG_COLORS[code] || '#1d4ed8'
            return (
              <button key={code} onClick={() => setLang(code)} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center',
                gap: 6, padding: '12px 4px', borderRadius: 12,
                border: `2px solid ${active ? color : isDevice ? '#334155' : '#1e293b'}`,
                background: active ? color + '22' : '#0f172a',
                cursor: 'pointer', transition: 'all .15s',
                WebkitTapHighlightColor: 'transparent',
                position: 'relative',
              }}>
                {/* Device language subtle badge */}
                {isDevice && !active && (
                  <div style={{
                    position: 'absolute', top: 4, insetInlineEnd: 4,
                    width: 7, height: 7, borderRadius: '50%',
                    background: '#38bdf8', opacity: 0.7,
                  }} />
                )}
                {/* Colored circle with 2-letter code — works on all Android */}
                <div style={{
                  width: 36, height: 36, borderRadius: '50%',
                  background: active ? color : '#1e293b',
                  border: `2px solid ${active ? color : '#334155'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 12, fontWeight: 800, color: active ? '#fff' : '#64748b',
                  letterSpacing: 0.5,
                }}>
                  {code.toUpperCase()}
                </div>
                <span style={{
                  fontSize: 11, fontWeight: active ? 700 : 400,
                  textAlign: 'center', color: active ? '#f1f5f9' : '#64748b',
                  lineHeight: 1.3,
                }}>
                  {meta.name}
                </span>
                {active && (
                  <div style={{ width: 6, height: 6, borderRadius: '50%', background: color }} />
                )}
              </button>
            )
          })}
        </div>
      </Section>

      {/* ── Alexa / Emulated Hue ── */}
      <Section title="🔵 Amazon Alexa">
        <div style={{ fontSize: 12, color: '#94a3b8', lineHeight: 1.8, marginBottom: 12 }}>
          {t.alexa_desc ?? 'The hub runs an emulated Philips Hue bridge. Alexa discovers all your devices automatically on the local network.'}
        </div>

        {/* Setup steps */}
        <div style={{ background: '#0f172a', borderRadius: 10, padding: '12px 14px', fontSize: 12, color: '#64748b', lineHeight: 2.2, marginBottom: 12 }}>
          <div style={{ fontWeight: 700, color: '#e2e8f0', marginBottom: 4 }}>🔧 {t.alexa_setup ?? 'Setup steps:'}</div>
          <div>1. {t.alexa_step1 ?? 'Make sure the hub (start-hub.bat) is running'}</div>
          <div>2. {t.alexa_step2 ?? 'Open the Alexa app on your phone'}</div>
          <div>3. {t.alexa_step3 ?? 'Devices → Add Device → Philips Hue'}</div>
          <div>4. {t.alexa_step4 ?? 'Tap "Search" — Alexa will find all your devices'}</div>
          <div style={{ color: '#38bdf8' }}>5. 🗣️ {t.alexa_step5 ?? '"Alexa, turn on the living room light"'}</div>
        </div>

        {/* Manual discovery tip */}
        <div style={{ background: 'rgba(56,189,248,0.07)', border: '1px solid #1e3a5f', borderRadius: 10, padding: '10px 14px', fontSize: 11, color: '#64748b', lineHeight: 1.7 }}>
          <span style={{ color: '#38bdf8', fontWeight: 700 }}>💡 {t.alexa_tip_title ?? 'Voice shortcut:'}</span>
          <br/>
          <span style={{ fontStyle: 'italic', color: '#94a3b8' }}>"Alexa, discover devices"</span>
          {' — '}{t.alexa_tip_desc ?? 'rescans the network for new devices'}
        </div>

        {/* Note about admin */}
        <div style={{ marginTop: 10, background: 'rgba(245,158,11,0.07)', border: '1px solid #78350f', borderRadius: 10, padding: '10px 14px', fontSize: 11, color: '#92400e' }}>
          ⚠️ {t.alexa_admin_note ?? 'For automatic discovery, run start-hub.bat as Administrator (right-click → Run as administrator). This allows SSDP port 1900.'}
        </div>
      </Section>

      {/* ── Gemini AI ── */}
      <Section title={`✨ ${t.gemini_section_title}`}>
        {/* Status row */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{
              width: 10, height: 10, borderRadius: '50%', flexShrink: 0,
              background: geminiStatus ? '#22c55e' : '#ef4444',
              boxShadow: geminiStatus ? '0 0 6px #22c55e' : 'none',
            }} />
            <span style={{ fontSize: 12, fontWeight: 600, color: geminiStatus ? '#22c55e' : '#ef4444' }}>
              {geminiStatus ? `Gemini AI ${t.connected ?? 'Connected'} ✓` : `Gemini AI ${t.disconnected ?? 'Disconnected'}`}
            </span>
          </div>
          {/* Test button */}
          <button onClick={testGeminiConnection} disabled={geminiTesting} style={{
            padding: '5px 12px', borderRadius: 8, border: '1px solid #334155',
            background: 'transparent', color: '#38bdf8', fontSize: 11,
            fontWeight: 600, cursor: 'pointer',
          }}>
            {geminiTesting ? '⏳ Testing…' : '🔌 Test'}
          </button>
        </div>

        {/* Test result */}
        {geminiTestMsg && (
          <div style={{
            background: geminiTestMsg.ok ? '#14532d' : '#450a0a',
            border: `1px solid ${geminiTestMsg.ok ? '#22c55e' : '#ef4444'}`,
            borderRadius: 8, padding: '8px 12px', fontSize: 12,
            color: geminiTestMsg.ok ? '#86efac' : '#fca5a5', marginBottom: 10,
          }}>
            {geminiTestMsg.text}
          </div>
        )}

        {/* How to get key */}
        {!geminiStatus && (
          <div style={{ background: '#0f172a', borderRadius: 10, padding: '10px 12px', marginBottom: 10, fontSize: 11, color: '#64748b', lineHeight: 1.8 }}>
            <div style={{ fontWeight: 700, color: '#94a3b8', marginBottom: 4 }}>
              {t.gemini_how_to ?? 'How to get a free Gemini API key:'}
            </div>
            1. {t.gemini_step1 ?? 'Go to'} <span style={{ color: '#38bdf8', direction: 'ltr', display: 'inline-block' }}>aistudio.google.com</span><br/>
            2. {t.gemini_step2 ?? 'Sign in with Google'}<br/>
            3. {t.gemini_step3 ?? 'Click "Get API key" → Create API key'}<br/>
            4. {t.gemini_step4 ?? 'Paste the key below and save'}
          </div>
        )}

        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
          {t.gemini_hint}
        </div>
        <input
          type="password"
          value={geminiKey}
          onChange={e => setGeminiKey(e.target.value)}
          placeholder="AIzaSy..."
          style={inp}
        />
        <button onClick={saveGeminiKey} style={{ ...btn('#7c3aed'), width: '100%' }}>
          {geminiSaved ? `✅ ${t.save}!` : `💾 ${t.save} Gemini Key`}
        </button>
        <div style={{ fontSize: 11, color: '#475569', marginTop: 8 }}>
          {t.gemini_api_hint}
        </div>
      </Section>

      {/* ── Sensibo AC ── */}
      <Section title={`❄️ ${t.sensibo_section_title}`}>
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
          {t.sensibo_hint}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
          <div style={{
            width: 8, height: 8, borderRadius: '50%',
            background: sensiboStatus ? '#22c55e' : '#ef4444',
            flexShrink: 0,
          }} />
          <span style={{ fontSize: 11, color: sensiboStatus ? '#22c55e' : '#ef4444' }}>
            {sensiboStatus ? `Sensibo ${t.connected} ✓` : t.disconnected}
          </span>
        </div>
        <input
          type="password"
          value={sensiboKey}
          onChange={e => setSensiboKey(e.target.value)}
          placeholder="sensibo_api_key_..."
          style={inp}
        />
        <button onClick={saveSensiboKey} style={{ ...btn('#0891b2'), width: '100%' }}>
          {sensiboSaved ? `✅ ${t.save}!` : `💾 ${t.save} Sensibo`}
        </button>
        <div style={{ fontSize: 11, color: '#475569', marginTop: 8 }}>
          {t.gemini_after_save}
        </div>
      </Section>

      {/* ── Import / Export ── */}
      <Section title={`📦 ${t.import_export}`}>
        {/* Export */}
        <button onClick={exportDevices} style={{ ...btn('#334155'), width: '100%', marginBottom: 8 }}>
          📤 {t.export_devices} (JSON)
        </button>

        {/* Import from file */}
        <label style={{ ...btn('#334155'), width: '100%', marginBottom: 14, display: 'block', textAlign: 'center', cursor: 'pointer' }}>
          📥 {t.import_devices} (JSON)
          <input type="file" accept=".json" onChange={importFromFile} style={{ display: 'none' }} />
        </label>

        {/* Import from HA */}
        <div style={{ borderTop: '1px solid #1e293b', paddingTop: 12 }}>
          <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>🏠 {t.import_ha}</div>
          <input value={haUrl} onChange={e => setHaUrl(e.target.value)}
            placeholder="http://homeassistant.local:8123"
            style={{ ...inp, direction: 'ltr' }} />
          <input type="password" value={haToken} onChange={e => setHaToken(e.target.value)}
            placeholder="eyJ0eXAiOi..."
            style={{ ...inp, direction: 'ltr' }} />
          <button onClick={importFromHA} disabled={importing}
            style={{ ...btn('#7c3aed'), width: '100%', opacity: importing ? 0.7 : 1 }}>
            {importing ? t.importing_label : `🏠 ${t.import_ha}`}
          </button>
        </div>

        {importMsg && (
          <div style={{
            marginTop: 10, padding: '8px 12px', borderRadius: 8, fontSize: 13,
            background: importMsg.ok ? '#14532d' : '#7f1d1d',
            border: `1px solid ${importMsg.ok ? '#22c55e' : '#ef4444'}`,
            color: '#f1f5f9',
          }}>{importMsg.text}</div>
        )}
      </Section>

      {/* ── Ads management ── */}
      <Section title={t.ads_section_title}>
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 10 }}>
          {t.ads_section_hint}
        </div>

        {/* Ad list */}
        {ads.map(ad => (
          <div key={ad.id} style={{
            background: '#0f172a', border: '1px solid #334155',
            borderRadius: 10, padding: '10px 12px', marginBottom: 8,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: ad.active ? '#e2e8f0' : '#475569' }}>
                {locAd(ad.title, lang) || t.ads_no_name}
              </div>
              <div style={{ fontSize: 11, color: '#475569', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {ad.url || t.ads_no_link}
              </div>
            </div>
            <button onClick={() => toggleAdActive(ad.id)} style={{
              padding: '4px 8px', borderRadius: 6, border: 'none', fontSize: 11, cursor: 'pointer',
              background: ad.active ? '#14532d' : '#334155',
              color: ad.active ? '#22c55e' : '#64748b',
            }}>{ad.active ? t.ads_active_badge : t.ads_inactive_badge}</button>
            <button onClick={() => setAdForm({ ...ad })} style={{
              padding: '4px 8px', borderRadius: 6, border: 'none', fontSize: 11, cursor: 'pointer',
              background: '#1e3a5f', color: '#38bdf8',
            }}>✏️</button>
            <button onClick={() => deleteAd(ad.id)} style={{
              padding: '4px 8px', borderRadius: 6, border: 'none', fontSize: 11, cursor: 'pointer',
              background: '#7f1d1d', color: '#fca5a5',
            }}>🗑️</button>
          </div>
        ))}

        <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
          <button onClick={() => setAdForm(BLANK_AD)} style={{ ...btn('#1d4ed8'), flex: 1 }}>
            {t.ads_add_btn}
          </button>
          <button onClick={resetAdsToDefaults} style={{ ...btn('#334155'), fontSize: 11, padding: '9px 12px' }}
            title={t.ads_reset_hint ?? 'Reset to multilingual defaults'}>
            🔄 {t.ads_reset ?? 'Reset'}
          </button>
        </div>

        {/* Ad editor modal */}
        {adForm && (
          <div style={{
            position: 'fixed', inset: 0, background: '#000a', zIndex: 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16,
          }}>
            <div style={{
              background: '#1e293b', border: '1px solid #334155', borderRadius: 16,
              padding: 20, width: '100%', maxWidth: 440, maxHeight: '90vh', overflowY: 'auto',
            }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: '#e2e8f0', marginBottom: 14 }}>
                {adForm.id ? t.ads_edit_title : t.ads_new_title}
              </div>

              {[
                { field: 'title',    label: t.ads_f_title,  placeholder: 'Fantatech — Smart Home Setup' },
                { field: 'desc',     label: t.ads_f_desc,   placeholder: 'Short business description...' },
                { field: 'imageUrl', label: t.ads_f_image,  placeholder: 'https://example.com/logo.png' },
                { field: 'url',      label: t.ads_f_url,    placeholder: 'https://example.com' },
                { field: 'btnLabel', label: t.ads_f_btn,    placeholder: 'Details ›' },
                { field: 'color',    label: t.ads_f_color,  placeholder: '#1d4ed8' },
              ].map(({ field, label, placeholder }) => {
                // Resolve the current value — could be a multilingual object or plain string
                const rawVal = adForm[field]
                const displayVal = typeof rawVal === 'object' && rawVal !== null
                  ? (locAd(rawVal, lang) || '')
                  : (rawVal || '')
                return (
                  <div key={field} style={{ marginBottom: 10 }}>
                    <div style={{ fontSize: 11, color: '#64748b', marginBottom: 4 }}>{label}</div>
                    <input
                      value={displayVal}
                      onChange={e => setAdForm(f => ({ ...f, [field]: e.target.value }))}
                      placeholder={placeholder}
                      style={{ ...inp, marginBottom: 0, direction: field === 'url' || field === 'imageUrl' || field === 'color' ? 'ltr' : 'inherit' }}
                    />
                  </div>
                )
              })}

              {/* Preview of the color */}
              <div style={{
                height: 4, borderRadius: 2, marginBottom: 14,
                background: adForm.color || '#1d4ed8',
              }} />

              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={saveAdEdit} style={{ ...btn('#22c55e'), flex: 1 }}>{t.ads_save_btn}</button>
                <button onClick={() => setAdForm(null)} style={{ ...btn('#334155'), flex: 1 }}>{t.cancel}</button>
              </div>
            </div>
          </div>
        )}
      </Section>

      {/* ── About ── */}
      <Section title={`ℹ️ ${t.about}`}>
        <div style={{ fontSize: 13, color: '#64748b', lineHeight: 1.8 }}>
          <div>App {t.version}: <b style={{ color: '#38bdf8' }}>v{APP_VERSION}</b></div>
          <div>Hub {t.version}: <b style={{ color: '#38bdf8' }}>v{hubVersion}</b></div>
          <div style={{ marginTop: 4, fontSize: 11 }}>FantaTech</div>
        </div>
      </Section>

      {/* ── Account / Sign out ── */}
      <Section title={`👤 ${t.account_section ?? 'Account'}`}>
        {/* Current user info */}
        {(() => {
          try {
            const u = JSON.parse(localStorage.getItem('fantatech_user') || '{}')
            if (u.username) return (
              <div style={{
                background: '#0f172a', border: '1px solid #334155',
                borderRadius: 10, padding: '12px 14px', marginBottom: 14,
                fontSize: 13, color: '#94a3b8',
              }}>
                <div style={{ fontWeight: 700, color: '#f1f5f9', marginBottom: 2 }}>
                  👤 {u.name || u.username}
                </div>
                {u.email && <div style={{ fontSize: 11 }}>✉️ {u.email}</div>}
                {u.plan  && <div style={{ fontSize: 11 }}>⭐ {t[`reg_plan_${u.plan}`] ?? u.plan}</div>}
                {u.restoredAt && (
                  <div style={{ fontSize: 10, color: '#334155', marginTop: 4 }}>
                    🔑 {t.login_success ?? 'Restored'} {new Date(u.restoredAt).toLocaleDateString()}
                  </div>
                )}
              </div>
            )
          } catch {}
          return null
        })()}

        {/* Update hint */}
        <div style={{
          background: 'rgba(56,189,248,0.07)', border: '1px solid #38bdf822',
          borderRadius: 10, padding: '10px 12px', marginBottom: 14,
          fontSize: 11, color: '#475569', lineHeight: 1.6,
        }}>
          📦 {t.update_hint ?? 'To update without losing data, install the new APK directly over the existing one — Android keeps all your data.'}
        </div>

        {/* Sign out button */}
        <button
          onClick={() => {
            if (window.confirm(t.signout_confirm ?? 'Sign out and clear local data?')) {
              localStorage.removeItem('fantatech_user')
              window.location.reload()
            }
          }}
          style={{
            width: '100%', padding: '11px 0', borderRadius: 10,
            background: '#1e293b', border: '1px solid #ef444444',
            color: '#ef4444', fontSize: 14, fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          🚪 {t.signout_btn ?? 'Sign Out'}
        </button>
      </Section>
    </div>
  )
}

function Section({ title, children }) {
  return (
    <div style={{
      background: '#1e293b', border: '1px solid #334155',
      borderRadius: 14, padding: 16, marginBottom: 14,
    }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0', marginBottom: 12 }}>{title}</div>
      {children}
    </div>
  )
}

const btn = (bg) => ({
  padding: '10px 18px', borderRadius: 8, border: 'none',
  background: bg, color: '#fff', cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const inp = {
  width: '100%', padding: '10px 12px', marginBottom: 10, borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 13, boxSizing: 'border-box',
}
