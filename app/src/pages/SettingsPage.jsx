import { useState, useEffect } from 'react'
import { api, getHubUrl, setHubUrl, clearHubUrl, testHubUrl, discoverHub } from '../hooks/useHub'
import { useLang, LANG_META } from '../context/LangContext'
import { loadAds, saveAds } from '../components/SponsoredBanner'

const APP_VERSION = '1.9.0'

export default function SettingsPage() {
  const { lang, t, setLang, rtl } = useLang()
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
      setHubTestMsg({ text: `✅ מחובר ל-${url}`, ok: true })
    } else {
      setHubTestMsg({ text: `❌ לא ניתן להתחבר ל-${url}`, ok: false })
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
        summary: '❌ לא ניתן להתחבר ל-Hub — ודא ש-start-hub.bat פועל',
        checks: [],
      })
    }
    setDiagRunning(false)
  }

  const runDiscover = async () => {
    setDiscovering(true); setHubTestMsg(null); setDiscoverProgress('מתחיל...')
    const found = await discoverHub(msg => setDiscoverProgress(msg))
    setDiscovering(false); setDiscoverProgress('')
    if (found) {
      setHubUrl(found)
      setHubUrlState(found)
      setHubTestMsg({ text: `✅ נמצא ונשמר: ${found}`, ok: true })
    } else {
      setHubTestMsg({ text: '❌ לא נמצא Hub ברשת', ok: false })
    }
  }

  /* ── Gemini key ── */
  const saveGeminiKey = async () => {
    try {
      await api.post('/ai/set-key', { key: geminiKey.trim() })
      setGeminiSaved(true)
      setGeminiStatus(true)
      setTimeout(() => setGeminiSaved(false), 3000)
    } catch {
      setHubTestMsg({ text: 'שגיאה בשמירת מפתח Gemini — ודא שה-Hub פועל', ok: false })
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
      setHubTestMsg({ text: 'שגיאה בשמירת מפתח Sensibo — ודא שה-Hub פועל', ok: false })
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
  const BLANK_AD = { id: null, title: '', desc: '', imageUrl: '', url: '', btnLabel: 'לפרטים ›', color: '#1d4ed8', active: true, sponsored: true }

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
    } catch { alert('שגיאה בייצוא') }
  }

  /* ── Import devices from JSON file ── */
  const importFromFile = (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = async (ev) => {
      try {
        const devices = JSON.parse(ev.target.result)
        if (!Array.isArray(devices)) throw new Error('לא תקין')
        setImporting(true); setImportMsg(null)
        let ok = 0, fail = 0
        for (const d of devices) {
          try { await api.post('/devices/', d); ok++ } catch { fail++ }
        }
        setImportMsg({ text: `יובאו ${ok} מכשירים${fail ? `, ${fail} נכשלו` : ''}`, ok: ok > 0 })
      } catch (err) {
        setImportMsg({ text: `שגיאה: ${err.message}`, ok: false })
      }
      setImporting(false)
    }
    reader.readAsText(file)
    e.target.value = ''
  }

  /* ── Import from Home Assistant ── */
  const importFromHA = async () => {
    if (!haUrl || !haToken) { setImportMsg({ text: 'הכנס כתובת HA וטוקן', ok: false }); return }
    localStorage.setItem('ha_url', haUrl)
    localStorage.setItem('ha_token', haToken)
    setImporting(true); setImportMsg(null)
    try {
      const r = await api.post('/ai/import-ha', { url: haUrl, token: haToken })
      setImportMsg({ text: r.data.message || 'יובא בהצלחה', ok: true })
    } catch (e) {
      setImportMsg({ text: e?.response?.data?.detail || 'ייבוא נכשל', ok: false })
    }
    setImporting(false)
  }

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>
      <h2 style={{ margin: '0 0 20px', color: '#e2e8f0', fontSize: 18 }}>{t.settings}</h2>

      {/* ── Hub Connection ── */}
      <Section title="🔗 חיבור ל-Hub">
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
          כתובת ה-Hub הנוכחית:
        </div>
        <div style={{
          background: '#0f172a', borderRadius: 8, padding: '8px 12px',
          fontSize: 12, color: '#38bdf8', marginBottom: 12,
          wordBreak: 'break-all', direction: 'ltr',
        }}>
          {hubUrl || '(לא מוגדר)'}
        </div>

        {/* Auto-discover */}
        <button onClick={runDiscover} disabled={discovering}
          style={{ ...btn('#22c55e'), width: '100%', marginBottom: 8, opacity: discovering ? 0.7 : 1 }}>
          {discovering ? `🔍 ${discoverProgress}` : '🔍 אתר Hub אוטומטית'}
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
            {hubTesting ? '...' : 'שמור'}
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
          {diagRunning ? '⏳ בודק חיבור...' : '🔧 בדיקת חיבור מלאה (AC1200 / Dual-Band)'}
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
                <b>📡 איך לכבות AP Isolation בראוטר AC1200:</b><br/>
                1. פתח דפדפן → <b style={{ direction: 'ltr', display: 'inline-block' }}>{diagResult.gateway || '192.168.1.1'}</b><br/>
                2. היכנס עם סיסמת הניהול (ברירת מחדל: admin/admin)<br/>
                3. Advanced → Wireless → Wireless Settings<br/>
                4. חפש <b>"AP Isolation"</b> או <b>"Client Isolation"</b><br/>
                5. כבה → שמור → הפעל מחדש
              </div>
            )}
          </div>
        )}
      </Section>

      {/* ── Language ── */}
      <Section title={`🌍 ${t.language}`}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {Object.entries(LANG_META).map(([code, meta]) => {
            const active = lang === code
            return (
              <button key={code} onClick={() => setLang(code)} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center',
                gap: 4, padding: '10px 4px', borderRadius: 12,
                border: active ? '2px solid #1d4ed8' : '2px solid transparent',
                background: active ? '#1e3a5f' : '#1e293b',
                color: active ? '#e2e8f0' : '#64748b',
                cursor: 'pointer', transition: 'all .15s',
              }}>
                <span style={{ fontSize: 26, lineHeight: 1 }}>{meta.flag}</span>
                <span style={{ fontSize: 11, fontWeight: active ? 700 : 400, textAlign: 'center' }}>
                  {meta.name}
                </span>
              </button>
            )
          })}
        </div>
      </Section>

      {/* ── Gemini AI ── */}
      <Section title={`✨ ${t.gemini_section_title}`}>
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
          {t.gemini_hint}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
          <div style={{
            width: 8, height: 8, borderRadius: '50%',
            background: geminiStatus ? '#22c55e' : '#ef4444', flexShrink: 0,
          }} />
          <span style={{ fontSize: 11, color: geminiStatus ? '#22c55e' : '#ef4444' }}>
            {geminiStatus ? `Gemini ${t.connected} ✓` : t.disconnected}
          </span>
        </div>
        <input
          type="password"
          value={geminiKey}
          onChange={e => setGeminiKey(e.target.value)}
          placeholder="AIzaSy..."
          style={inp}
        />
        <button onClick={saveGeminiKey} style={{ ...btn('#7c3aed'), width: '100%' }}>
          {geminiSaved ? `✅ ${t.save}!` : `💾 ${t.save} Gemini`}
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
            {importing ? '⏳ מייבא...' : `🏠 ${t.import_ha}`}
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
      <Section title="📢 ניהול פרסומות">
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 10 }}>
          הפרסומות מוצגות בדף הבית. לחץ + כדי להוסיף מודעה חדשה.
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
                {ad.title || '(ללא שם)'}
              </div>
              <div style={{ fontSize: 11, color: '#475569', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {ad.url || 'אין קישור'}
              </div>
            </div>
            <button onClick={() => toggleAdActive(ad.id)} style={{
              padding: '4px 8px', borderRadius: 6, border: 'none', fontSize: 11, cursor: 'pointer',
              background: ad.active ? '#14532d' : '#334155',
              color: ad.active ? '#22c55e' : '#64748b',
            }}>{ad.active ? '✓ פעיל' : 'כבוי'}</button>
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

        <button onClick={() => setAdForm(BLANK_AD)} style={{ ...btn('#1d4ed8'), width: '100%', marginTop: 4 }}>
          + הוסף מודעה חדשה
        </button>

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
                {adForm.id ? '✏️ ערוך מודעה' : '➕ מודעה חדשה'}
              </div>

              {[
                { field: 'title',    label: 'כותרת',        placeholder: 'Fantatech — התקנת בית חכם' },
                { field: 'desc',     label: 'תיאור',        placeholder: 'פירוט קצר על העסק...' },
                { field: 'imageUrl', label: 'כתובת תמונה (URL)', placeholder: 'https://example.com/logo.png' },
                { field: 'url',      label: 'קישור לחיצה',  placeholder: 'https://example.com' },
                { field: 'btnLabel', label: 'טקסט כפתור',   placeholder: 'לפרטים ›' },
                { field: 'color',    label: 'צבע (HEX)',    placeholder: '#1d4ed8' },
              ].map(({ field, label, placeholder }) => (
                <div key={field} style={{ marginBottom: 10 }}>
                  <div style={{ fontSize: 11, color: '#64748b', marginBottom: 4 }}>{label}</div>
                  <input
                    value={adForm[field] || ''}
                    onChange={e => setAdForm(f => ({ ...f, [field]: e.target.value }))}
                    placeholder={placeholder}
                    style={{ ...inp, marginBottom: 0, direction: field === 'url' || field === 'imageUrl' || field === 'color' ? 'ltr' : 'rtl' }}
                  />
                </div>
              ))}

              {/* Preview of the color */}
              <div style={{
                height: 4, borderRadius: 2, marginBottom: 14,
                background: adForm.color || '#1d4ed8',
              }} />

              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={saveAdEdit} style={{ ...btn('#22c55e'), flex: 1 }}>✅ שמור</button>
                <button onClick={() => setAdForm(null)} style={{ ...btn('#334155'), flex: 1 }}>ביטול</button>
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
          <div style={{ marginTop: 4, fontSize: 11 }}>Fantatech Home & Security</div>
        </div>
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
