/**
 * ImportWizard.jsx — Import devices from external smart-home apps
 *
 * Supported:  SmartLife / Tuya · Philips Hue · Home Assistant
 * Coming soon: IKEA Trådfri · eWeLink / Sonoff
 *
 * Shared 4-step flow:
 *   Step 0  → choose source app
 *   Step 1  → source-specific credentials / pairing
 *   Step 2  → fetched device list + checkboxes
 *   Step 3  → import result summary
 */
import { useState } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'
import { useScale } from '../context/ScaleContext'

/* ── Type icons ────────────────────────────────────────────────────────────── */
const TYPE_ICON = {
  light:'💡', dimmer:'🔆', switch:'🔌', sensor:'🌡️',
  motion:'👤', door:'🚪', smoke:'🔥', lock:'🔒',
  fan:'🌀', camera:'📷', gateway:'📡', ac:'❄️',
}
const typeIcon = t => TYPE_ICON[t] ?? '🔧'

/* ── Regions (Tuya) ────────────────────────────────────────────────────────── */
const REGIONS = [
  { value:'eu',   label:'Europe (EU)' },
  { value:'us',   label:'Americas (US)' },
  { value:'cn',   label:'China (CN)' },
  { value:'in',   label:'India (IN)' },
  { value:'us-e', label:'US East' },
  { value:'eu-w', label:'EU West' },
]

/* ── Source definitions ────────────────────────────────────────────────────── */
const SOURCES = [
  { id:'smartlife', name:'SmartLife / Tuya', icon:'🌐', ready:true,  color:'#f97316',
    desc:'Import all cloud devices at once' },
  { id:'hue',       name:'Philips Hue',      icon:'💡', ready:true,  color:'#fbbf24',
    desc:'Import lights & sensors from your Hue bridge' },
  { id:'ha',        name:'Home Assistant',   icon:'🏠', ready:true,  color:'#38bdf8',
    desc:'Import any entity from a running HA instance' },
  { id:'ikea',      name:'IKEA Trådfri',     icon:'🏮', ready:false, color:'#4ade80',
    desc:'Coming soon' },
  { id:'ewe',       name:'eWeLink / Sonoff', icon:'⚡', ready:false, color:'#a78bfa',
    desc:'Coming soon' },
]

/* ── Small shared components ───────────────────────────────────────────────── */
function Spinner() {
  return (
    <span style={{
      width:16, height:16, border:'2px solid #ffffff44',
      borderTop:'2px solid #fff', borderRadius:'50%',
      display:'inline-block', animation:'spin 0.7s linear infinite',
    }}>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </span>
  )
}

function Err({ msg }) {
  if (!msg) return null
  return (
    <div style={{
      background:'#450a0a', border:'1px solid #ef4444',
      borderRadius:8, padding:'9px 12px', fontSize:12, color:'#fca5a5',
    }}>⚠️ {msg}</div>
  )
}

function Field({ label, value, onChange, type='text', placeholder='', hint='' }) {
  return (
    <label style={{ display:'flex', flexDirection:'column', gap:4 }}>
      <span style={{ fontSize:11, color:'#94a3b8', fontWeight:700 }}>{label}</span>
      <input
        value={value} onChange={e => onChange(e.target.value)}
        type={type} placeholder={placeholder}
        autoCapitalize="off" autoCorrect="off" spellCheck={false}
        style={{
          background:'#0f172a', border:'1px solid #334155', borderRadius:8,
          padding:'9px 12px', color:'#e2e8f0', fontSize:13, outline:'none',
          width:'100%', boxSizing:'border-box',
        }}
      />
      {hint && <span style={{ fontSize:10, color:'#475569', lineHeight:1.4 }}>{hint}</span>}
    </label>
  )
}

function Guide({ toggle, open, onToggle, children }) {
  return (
    <div>
      <button onClick={onToggle} style={{
        background:'transparent', border:'1px solid #334155', borderRadius:8,
        padding:'6px 12px', cursor:'pointer', color:'#64748b', fontSize:12,
        WebkitTapHighlightColor:'transparent',
      }}>
        {open ? '▲' : '▼'} {toggle}
      </button>
      {open && (
        <div style={{
          marginTop:8, background:'#0f172a', border:'1px solid #1e3a5f',
          borderRadius:10, padding:'12px 14px', fontSize:12, color:'#94a3b8', lineHeight:1.8,
        }}>
          {children}
        </div>
      )}
    </div>
  )
}

function Step({ n, text }) {
  return (
    <div style={{ display:'flex', gap:8, marginBottom:6 }}>
      <span style={{
        flexShrink:0, width:20, height:20, borderRadius:'50%',
        background:'#1e3a5f', color:'#38bdf8',
        display:'flex', alignItems:'center', justifyContent:'center',
        fontSize:10, fontWeight:800,
      }}>{n}</span>
      <span>{text}</span>
    </div>
  )
}

/* ─────────────────────────────────────────────────────────────────────────── */

export default function ImportWizard({ onClose, onImported }) {
  const { t } = useLang()
  const { sp, spx, phone } = useScale()

  /* ── shared state ── */
  const [step,     setStep]     = useState(0)
  const [source,   setSource]   = useState(null)
  const [loading,  setLoading]  = useState(false)
  const [error,    setError]    = useState('')
  const [devices,  setDevices]  = useState([])
  const [selected, setSelected] = useState({})
  const [result,   setResult]   = useState(null)
  const [guide,    setGuide]    = useState(false)

  /* ── SmartLife / Tuya credentials ── */
  const [region,   setRegion]   = useState('eu')
  const [accessId, setAccessId] = useState('')
  const [secret,   setSecret]   = useState('')

  /* ── Philips Hue credentials ── */
  const [hueIp,       setHueIp]       = useState('')
  const [hueUsername, setHueUsername] = useState('')
  const [huePairing,  setHuePairing]  = useState(false)  // waiting for button press
  const [hueDiscovering, setHueDisc]  = useState(false)

  /* ── Home Assistant credentials ── */
  const [haUrl,   setHaUrl]   = useState('http://homeassistant.local:8123')
  const [haToken, setHaToken] = useState('')

  /* ── Style helpers ── */
  const btnP = (disabled) => ({
    background: disabled ? '#334155' : '#2563eb', color:'#fff',
    border:'none', borderRadius:sp(10), padding:`${spx(11)} ${spx(20)}`,
    cursor: disabled ? 'default' : 'pointer', fontWeight:700, fontSize:spx(14),
    display:'flex', alignItems:'center', justifyContent:'center', gap:sp(6),
    WebkitTapHighlightColor:'transparent',
  })
  const btnG = {
    background:'transparent', border:'1px solid #334155', color:'#94a3b8',
    borderRadius:sp(10), padding:`${spx(10)} ${spx(16)}`,
    cursor:'pointer', fontWeight:600, fontSize:spx(13),
    WebkitTapHighlightColor:'transparent',
  }

  /* ─────────────── Step 1 variants ─────────────── */

  /* ── TUYA fetch ── */
  const fetchTuya = async () => {
    if (!accessId.trim() || !secret.trim()) {
      setError(t.import_creds_required ?? 'Access ID and Secret are required'); return
    }
    setLoading(true); setError('')
    try {
      const r = await api.post('/tuya/cloud-fetch', {
        region, access_id: accessId.trim(), access_secret: secret.trim(),
      })
      initDeviceList(r.data.devices ?? [], d => d.online)
      setStep(2)
    } catch(e) { setError(e?.response?.data?.detail ?? e.message) }
    finally { setLoading(false) }
  }

  /* ── HUE: auto-discover bridge ── */
  const discoverHue = async () => {
    setHueDisc(true); setError('')
    try {
      const r = await api.get('/hue/discover')
      const bridges = r.data.bridges ?? []
      if (bridges.length > 0) {
        setHueIp(bridges[0].internalipaddress ?? bridges[0].ip ?? '')
      } else {
        setError('No bridge found automatically — enter the IP manually')
      }
    } catch { setError('Auto-detect failed — enter the bridge IP manually') }
    finally { setHueDisc(false) }
  }

  /* ── HUE: pair (needs button press) ── */
  const pairHue = async () => {
    if (!hueIp.trim()) { setError('Enter the bridge IP address first'); return }
    setLoading(true); setError('')
    try {
      const r = await api.post('/hue/pair', { bridge_ip: hueIp.trim() })
      setHueUsername(r.data.username)
      setHuePairing(false)
      // auto-fetch right after pairing
      await fetchHue(r.data.username)
    } catch(e) { setError(e?.response?.data?.detail ?? e.message) }
    finally { setLoading(false) }
  }

  /* ── HUE: fetch devices (given username) ── */
  const fetchHue = async (username) => {
    const u = username ?? hueUsername
    if (!hueIp.trim() || !u) return
    setLoading(true); setError('')
    try {
      const r = await api.post('/hue/fetch', { bridge_ip: hueIp.trim(), username: u })
      initDeviceList(r.data.devices ?? [], d => true)
      setStep(2)
    } catch(e) { setError(e?.response?.data?.detail ?? e.message) }
    finally { setLoading(false) }
  }

  /* ── HA: fetch entities ── */
  const fetchHa = async () => {
    if (!haUrl.trim() || !haToken.trim()) {
      setError('HA URL and token are required'); return
    }
    setLoading(true); setError('')
    try {
      const r = await api.post('/ha/fetch', { ha_url: haUrl.trim(), token: haToken.trim() })
      initDeviceList(r.data.devices ?? [], d => d.online)
      setStep(2)
    } catch(e) { setError(e?.response?.data?.detail ?? e.message) }
    finally { setLoading(false) }
  }

  /* ── import (all sources) ── */
  const handleImport = async () => {
    const toImport = devices.filter(d => selected[d._key])
    if (!toImport.length) { setError(t.import_none_selected ?? 'Select at least one device'); return }
    setLoading(true); setError('')
    try {
      let res
      if (source === 'smartlife') {
        res = await api.post('/tuya/cloud-import', {
          region, access_id: accessId.trim(), access_secret: secret.trim(),
          devices: toImport,
        })
      } else if (source === 'hue') {
        res = await api.post('/hue/import', {
          bridge_ip: hueIp.trim(), username: hueUsername,
          devices: toImport.map(d => ({
            hue_id: d.hue_id, name: d.name, type: d.type, on: d.on, online: d.online,
          })),
        })
      } else if (source === 'ha') {
        res = await api.post('/ha/import', {
          ha_url: haUrl.trim(), token: haToken.trim(),
          entities: toImport.map(d => ({
            entity_id: d.entity_id, name: d.name, type: d.type, state: d.state ?? 'off',
          })),
        })
      }
      setResult(res.data)
      setStep(3)
      onImported?.()
    } catch(e) { setError(e?.response?.data?.detail ?? e.message ?? 'Import failed') }
    finally { setLoading(false) }
  }

  /* ── helpers ── */
  const initDeviceList = (devs, defaultSel) => {
    const keyed = devs.map((d, i) => ({ ...d, _key: d.id ?? d.hue_id ?? d.entity_id ?? String(i) }))
    setDevices(keyed)
    const sel = {}
    keyed.forEach(d => { sel[d._key] = defaultSel(d) })
    setSelected(sel)
  }
  const toggleAll   = v => { const s={}; devices.forEach(d=>{s[d._key]=v}); setSelected(s) }
  const selCount    = Object.values(selected).filter(Boolean).length
  const modalW      = Math.min(phone ? 360 : 500, window.innerWidth - 24)

  /* ═══════════════ Step renderers ═══════════════ */

  /* ── Step 0: source picker ── */
  const renderStep0 = () => (
    <div style={{ display:'flex', flexDirection:'column', gap:sp(10) }}>
      <p style={{ margin:0, fontSize:spx(13), color:'#94a3b8', lineHeight:1.6 }}>
        {t.import_choose_source ?? 'Choose the app you want to import devices from:'}
      </p>
      {SOURCES.map(src => (
        <button key={src.id} onClick={() => { if(src.ready){ setSource(src.id); setStep(1); setError('') } }}
          style={{
            display:'flex', alignItems:'center', gap:sp(12),
            padding:`${spx(12)} ${spx(14)}`,
            background: src.ready ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.2)',
            border:`1px solid ${src.ready ? '#334155' : '#1e293b'}`,
            borderRadius:sp(12), cursor: src.ready ? 'pointer' : 'default',
            opacity: src.ready ? 1 : 0.4, textAlign:'left',
            WebkitTapHighlightColor:'transparent',
          }}>
          <span style={{
            fontSize:spx(26), width:sp(42), height:sp(42), borderRadius:sp(10),
            background:`${src.color}22`, border:`1px solid ${src.color}44`,
            display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0,
          }}>{src.icon}</span>
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontSize:spx(14), fontWeight:700, color: src.ready ? '#e2e8f0' : '#475569' }}>{src.name}</div>
            <div style={{ fontSize:spx(11), color: src.ready ? '#64748b' : '#334155', marginTop:2 }}>
              {src.ready ? src.desc : (t.import_coming_soon ?? 'Coming soon')}
            </div>
          </div>
          {src.ready && <span style={{ fontSize:spx(16), color:'#334155' }}>›</span>}
        </button>
      ))}
    </div>
  )

  /* ── Step 1A: SmartLife / Tuya ── */
  const renderStep1_smartlife = () => (
    <div style={{ display:'flex', flexDirection:'column', gap:sp(16) }}>
      <label style={{ display:'flex', flexDirection:'column', gap:4 }}>
        <span style={{ fontSize:spx(11), color:'#94a3b8', fontWeight:700 }}>
          {t.import_region ?? 'Server Region'}
        </span>
        <select value={region} onChange={e=>setRegion(e.target.value)}
          style={{ background:'#0f172a', border:'1px solid #334155', borderRadius:8,
                   padding:'9px 12px', color:'#e2e8f0', fontSize:spx(13), outline:'none' }}>
          {REGIONS.map(r=><option key={r.value} value={r.value}>{r.label}</option>)}
        </select>
      </label>
      <Field label={t.import_access_id ?? 'Access ID'} value={accessId} onChange={setAccessId} placeholder="xxxxxxxxxxxxxxxxxxxx" />
      <Field label={t.import_access_secret ?? 'Access Secret'} value={secret} onChange={setSecret} type="password" placeholder="••••••••••••••••••••" />
      <Guide toggle={t.import_how_to ?? 'How to get credentials'} open={guide} onToggle={()=>setGuide(v=>!v)}>
        <Step n="1" text={t.import_step1 ?? 'Open iot.tuya.com and sign in (free developer account)'} />
        <Step n="2" text={t.import_step2 ?? 'Create Project → choose "Smart Home" protocol'} />
        <Step n="3" text={t.import_step3 ?? 'Copy Access ID and Access Secret from the project overview'} />
        <Step n="4" text={t.import_step4 ?? 'In the project: Link Tuya App Account → scan QR with SmartLife'} />
        <Step n="5" text={t.import_step5 ?? 'Paste the credentials here and click Fetch'} />
        <a href="https://iot.tuya.com" target="_blank" rel="noreferrer"
           style={{ color:'#38bdf8', fontSize:spx(12), marginTop:sp(4), display:'block' }}>
          🌐 iot.tuya.com →
        </a>
      </Guide>
      <Err msg={error} />
      <div style={{ display:'flex', gap:sp(8) }}>
        <button style={{ ...btnG, flex:1 }} onClick={()=>setStep(0)}>← {t.back ?? 'Back'}</button>
        <button style={{ ...btnP(loading), flex:2 }} onClick={fetchTuya} disabled={loading}>
          {loading ? <Spinner /> : `🔍 ${t.import_fetch ?? 'Fetch My Devices'}`}
        </button>
      </div>
    </div>
  )

  /* ── Step 1B: Philips Hue ── */
  const renderStep1_hue = () => (
    <div style={{ display:'flex', flexDirection:'column', gap:sp(16) }}>

      {/* Bridge IP + auto-detect */}
      <div>
        <div style={{ display:'flex', gap:sp(8), alignItems:'flex-end' }}>
          <div style={{ flex:1 }}>
            <Field
              label={t.import_hue_ip ?? 'Hue Bridge IP Address'}
              value={hueIp} onChange={setHueIp}
              placeholder="192.168.1.xxx"
              hint={t.import_hue_ip_hint ?? 'Find it in the Philips Hue app → Settings → My Hue System'}
            />
          </div>
          <button
            onClick={discoverHue} disabled={hueDiscovering}
            style={{ ...btnG, whiteSpace:'nowrap', height:38, alignSelf:'flex-end',
                     borderColor:'#f59e0b44', color:'#fbbf24' }}>
            {hueDiscovering ? <Spinner /> : '🔍 Auto'}
          </button>
        </div>
      </div>

      {/* Press-button instructions */}
      <div style={{
        background:'#1c1100', border:'1px solid #f59e0b', borderRadius:sp(10),
        padding:`${spx(12)} ${spx(14)}`, fontSize:spx(12), color:'#fcd34d', lineHeight:1.7,
      }}>
        <div style={{ fontWeight:700, marginBottom:sp(4) }}>
          🔘 {t.import_hue_press_title ?? 'Press the button on your Hue bridge'}
        </div>
        {t.import_hue_press_hint ??
          'Press the round button on top of the physical Hue bridge, then click Connect within 30 seconds.'}
      </div>

      <Guide toggle={t.import_hue_guide ?? 'Where is the Hue bridge IP?'} open={guide} onToggle={()=>setGuide(v=>!v)}>
        <Step n="1" text="Open the Philips Hue app on your phone" />
        <Step n="2" text="Go to Settings → My Hue System" />
        <Step n="3" text="Tap your bridge → the IP address is listed there" />
        <Step n="4" text="Alternatively: check your router's device list for 'Philips-hue'" />
      </Guide>

      <Err msg={error} />

      <div style={{ display:'flex', gap:sp(8) }}>
        <button style={{ ...btnG, flex:1 }} onClick={()=>setStep(0)}>← {t.back ?? 'Back'}</button>
        <button style={{ ...btnP(loading || !hueIp.trim()), flex:2 }}
          onClick={pairHue} disabled={loading || !hueIp.trim()}>
          {loading ? <Spinner /> : `🔗 ${t.import_hue_connect ?? 'Connect Bridge'}`}
        </button>
      </div>
    </div>
  )

  /* ── Step 1C: Home Assistant ── */
  const renderStep1_ha = () => (
    <div style={{ display:'flex', flexDirection:'column', gap:sp(16) }}>
      <Field
        label={t.import_ha_url ?? 'Home Assistant URL'}
        value={haUrl} onChange={setHaUrl}
        placeholder="http://homeassistant.local:8123"
        hint={t.import_ha_url_hint ?? 'The address you use to open the HA dashboard'}
      />
      <Field
        label={t.import_ha_token ?? 'Long-Lived Access Token'}
        value={haToken} onChange={setHaToken}
        type="password"
        placeholder="eyJhbGciOiJIUzI1NiIs..."
      />
      <Guide toggle={t.import_ha_guide ?? 'How to create a token in HA'} open={guide} onToggle={()=>setGuide(v=>!v)}>
        <Step n="1" text="Open Home Assistant in your browser" />
        <Step n="2" text="Click your profile picture (bottom-left)" />
        <Step n="3" text="Scroll down to Security → Long-Lived Access Tokens" />
        <Step n="4" text='Click "Create Token", give it a name (e.g. FantaTech)' />
        <Step n="5" text="Copy the token and paste it above" />
      </Guide>
      <Err msg={error} />
      <div style={{ display:'flex', gap:sp(8) }}>
        <button style={{ ...btnG, flex:1 }} onClick={()=>setStep(0)}>← {t.back ?? 'Back'}</button>
        <button style={{ ...btnP(loading), flex:2 }} onClick={fetchHa} disabled={loading}>
          {loading ? <Spinner /> : `🔍 ${t.import_fetch ?? 'Fetch Entities'}`}
        </button>
      </div>
    </div>
  )

  /* ── Step 2: device checklist ── */
  const renderStep2 = () => (
    <div style={{ display:'flex', flexDirection:'column', gap:sp(12) }}>
      {/* Summary bar */}
      <div style={{
        display:'flex', alignItems:'center', justifyContent:'space-between',
        background:'#0f172a', borderRadius:sp(10), padding:`${spx(10)} ${spx(14)}`,
        border:'1px solid #334155',
      }}>
        <span style={{ fontSize:spx(13), color:'#94a3b8' }}>
          {devices.length} {t.import_devices_found ?? 'devices found'}
        </span>
        <div style={{ display:'flex', gap:sp(6) }}>
          <button style={{ ...btnG, fontSize:spx(11), padding:`${spx(5)} ${spx(10)}` }}
            onClick={()=>toggleAll(true)}>
            {t.import_select_all ?? 'All'}
          </button>
          <button style={{ ...btnG, fontSize:spx(11), padding:`${spx(5)} ${spx(10)}` }}
            onClick={()=>toggleAll(false)}>
            {t.import_deselect_all ?? 'None'}
          </button>
        </div>
      </div>

      {/* Device list */}
      <div style={{ maxHeight:320, overflowY:'auto', display:'flex', flexDirection:'column', gap:sp(6) }}
        className="ft-scroll">
        {devices.map(dev => {
          const checked = !!selected[dev._key]
          const label   = dev.name || dev.entity_id || dev._key
          const sub     = [dev.type, dev.category, dev.ip, dev.domain].filter(Boolean).join(' · ')
          const online  = dev.online ?? true
          return (
            <label key={dev._key} style={{
              display:'flex', alignItems:'center', gap:sp(10),
              background: checked ? 'rgba(37,99,235,0.08)' : '#0f172a',
              border:`1px solid ${checked ? '#2563eb44' : '#1e293b'}`,
              borderRadius:sp(10), padding:`${spx(10)} ${spx(12)}`,
              cursor:'pointer',
            }}>
              <input type="checkbox" checked={checked}
                onChange={e=>setSelected(s=>({...s,[dev._key]:e.target.checked}))}
                style={{ width:sp(16), height:sp(16), accentColor:'#2563eb', flexShrink:0 }} />
              <span style={{ fontSize:spx(20), flexShrink:0 }}>{typeIcon(dev.type)}</span>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ fontSize:spx(13), fontWeight:600, color:'#e2e8f0',
                  whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>
                  {label}
                </div>
                <div style={{ fontSize:spx(10), color:'#475569', marginTop:1 }}>{sub}</div>
              </div>
              <span style={{
                fontSize:spx(9), fontWeight:700, padding:'2px 7px', borderRadius:20, flexShrink:0,
                background: online ? 'rgba(34,197,94,0.1)'  : 'rgba(100,116,139,0.1)',
                color:      online ? '#22c55e'               : '#64748b',
                border:    `1px solid ${online ? '#22c55e44' : '#33415544'}`,
              }}>
                {online ? '● Online' : '○ Offline'}
              </span>
            </label>
          )
        })}
      </div>

      <Err msg={error} />

      <div style={{ display:'flex', gap:sp(8) }}>
        <button style={{ ...btnG, flex:1 }} onClick={()=>setStep(1)}>← {t.back ?? 'Back'}</button>
        <button style={{ ...btnP(loading || !selCount), flex:2 }}
          onClick={handleImport} disabled={loading || !selCount}>
          {loading ? <Spinner /> : `📥 ${t.import_btn ?? 'Import'} (${selCount})`}
        </button>
      </div>
    </div>
  )

  /* ── Step 3: result ── */
  const renderStep3 = () => (
    <div style={{ display:'flex', flexDirection:'column', gap:sp(16), alignItems:'center', textAlign:'center' }}>
      <span style={{ fontSize:spx(48) }}>🎉</span>
      <div>
        <div style={{ fontSize:spx(20), fontWeight:800, color:'#22c55e', marginBottom:sp(4) }}>
          {result?.imported ?? 0} {t.import_success_count ?? 'devices added!'}
        </div>
        <div style={{ fontSize:spx(12), color:'#64748b', lineHeight:1.6 }}>
          {t.import_success_hint ??
            'Devices are now in your hub. If one shows offline, make sure it is on the same network as this PC.'}
        </div>
      </div>

      {/* Per-device status */}
      {(result?.devices ?? []).length > 0 && (
        <div style={{ width:'100%', maxHeight:200, overflowY:'auto',
          display:'flex', flexDirection:'column', gap:sp(4) }} className="ft-scroll">
          {result.devices.map((d,i) => (
            <div key={i} style={{
              display:'flex', alignItems:'center', justifyContent:'space-between',
              background:'#0f172a', borderRadius:sp(8), padding:`${spx(7)} ${spx(12)}`,
              fontSize:spx(11), color:'#94a3b8',
            }}>
              <span style={{ fontWeight:600, color:'#e2e8f0', flex:1, textAlign:'left',
                overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>
                {d.name}
              </span>
              <span style={{ color:'#22c55e', flexShrink:0 }}>✓</span>
            </div>
          ))}
        </div>
      )}

      <div style={{ display:'flex', gap:sp(8), width:'100%' }}>
        <button style={{ ...btnG, flex:1 }}
          onClick={() => { setStep(0); setResult(null); setDevices([]) }}>
          {t.import_more ?? '+ Import More'}
        </button>
        <button style={{ ...btnP(false), flex:2 }} onClick={onClose}>
          {t.import_done ?? 'Go to Devices ›'}
        </button>
      </div>
    </div>
  )

  /* ═══════════════ Modal shell ═══════════════ */
  const sourceLabel = SOURCES.find(s=>s.id===source)?.name ?? ''
  const stepTitles  = [
    t.import_title        ?? '📥 Import Devices',
    source === 'hue'
      ? `💡 ${t.import_hue_title  ?? 'Philips Hue'}`
      : source === 'ha'
        ? `🏠 ${t.import_ha_title   ?? 'Home Assistant'}`
        : `🌐 ${t.import_creds_title ?? 'Tuya / SmartLife'}`,
    t.import_select_title ?? `📋 Select Devices`,
    t.import_done_title   ?? '✅ Import Complete',
  ]

  return (
    <div style={{
      position:'fixed', inset:0, background:'rgba(0,0,0,0.75)',
      display:'flex', alignItems:'center', justifyContent:'center',
      zIndex:400, padding:sp(12),
    }} onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div style={{
        background:'#1e293b', border:'1px solid #334155', borderRadius:sp(16),
        padding:`${spx(18)} ${spx(20)}`,
        width:'100%', maxWidth:modalW,
        display:'flex', flexDirection:'column', gap:sp(16),
        maxHeight:'92vh', overflowY:'auto',
      }} className="ft-scroll">

        {/* Header + progress */}
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
          <div>
            <div style={{ fontSize:spx(16), fontWeight:800, color:'#e2e8f0' }}>
              {stepTitles[step]}
            </div>
            <div style={{ display:'flex', gap:sp(5), marginTop:sp(5) }}>
              {[0,1,2,3].map(i=>(
                <div key={i} style={{
                  width:sp(i===step?16:6), height:sp(6), borderRadius:sp(3),
                  background: i===step ? '#2563eb' : i<step ? '#22c55e' : '#334155',
                  transition:'all 0.25s',
                }}/>
              ))}
            </div>
          </div>
          <button onClick={onClose} style={{ ...btnG, padding:`${spx(5)} ${spx(10)}`, fontSize:spx(16) }}>✕</button>
        </div>

        {/* Step content */}
        {step === 0 && renderStep0()}
        {step === 1 && source === 'smartlife' && renderStep1_smartlife()}
        {step === 1 && source === 'hue'       && renderStep1_hue()}
        {step === 1 && source === 'ha'        && renderStep1_ha()}
        {step === 2 && renderStep2()}
        {step === 3 && renderStep3()}
      </div>
    </div>
  )
}
