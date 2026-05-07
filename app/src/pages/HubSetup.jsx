import { useState, useEffect } from 'react'
import { setHubUrl, testHubUrl, discoverHub } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

async function _getPhoneIp() {
  return new Promise(resolve => {
    try {
      const pc = new RTCPeerConnection({ iceServers: [] })
      pc.createDataChannel('')
      pc.createOffer().then(o => pc.setLocalDescription(o)).catch(() => {})
      const t = setTimeout(() => { pc.close(); resolve(null) }, 1500)
      pc.onicecandidate = e => {
        if (!e?.candidate) return
        const m = e.candidate.candidate.match(/(\d+\.\d+\.\d+\.\d+)/)
        if (m && !m[1].startsWith('127.')) { clearTimeout(t); pc.close(); resolve(m[1]) }
      }
    } catch { resolve(null) }
  })
}

export default function HubSetup({ currentUrl, onConnected }) {
  const { t, rtl } = useLang()
  const [mode, setMode]             = useState('menu')
  const [manualIp, setManualIp]     = useState('')
  const [manualPort, setManualPort] = useState('8080')
  const [testing, setTesting]       = useState(false)
  const [progress, setProgress]     = useState('')
  const [error, setError]           = useState('')
  const [diagStep, setDiagStep]     = useState(null)
  const [phoneIp, setPhoneIp]       = useState(null)

  useEffect(() => {
    _getPhoneIp().then(ip => {
      if (ip) setPhoneIp(ip)
    })
  }, [])

  /* ── Auto-discover ── */
  const runDiscover = async () => {
    setMode('discover'); setError(''); setDiagStep(null)
    const found = await discoverHub(msg => setProgress(msg))
    if (found) {
      setProgress(t.hub_found)
      setHubUrl(found)
      setTimeout(() => onConnected(found), 600)
    } else {
      setMode('failed')
      setProgress('')
    }
  }

  /* ── Manual connect ── */
  const runManual = async () => {
    const ip = manualIp.trim()
    if (!ip) { setError(t.hub_ip_label); return }
    let url = ip.startsWith('http') ? ip : `http://${ip}:${manualPort}`
    url = url.replace(/\/+$/, '')
    setTesting(true); setError('')
    const ok = await testHubUrl(url)
    setTesting(false)
    if (ok) {
      setHubUrl(url); onConnected(url)
    } else {
      setError(`❌ ${t.cannot_connect_error} ${url}\n\n${t.check_hub_running}`)
    }
  }

  return (
    <div style={{
      minHeight: '100vh', background: '#0f172a', color: '#f1f5f9',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'flex-start', padding: '32px 20px',
      direction: rtl ? 'rtl' : 'ltr', overflowY: 'auto',
    }}>

      {/* Logo */}
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ fontSize: 52 }}>🏡</div>
        <div style={{ fontSize: 20, fontWeight: 800, color: '#38bdf8', marginTop: 4 }}>
          {t.hub_setup_title}
        </div>
        <div style={{ fontSize: 12, color: '#475569', marginTop: 4 }}>
          {t.hub_setup_subtitle}
        </div>
      </div>

      {/* Previous URL warning */}
      {currentUrl && (
        <InfoBox color="#f59e0b" border="#78350f" bg="#1c1007" icon="⚠️"
          text={`${t.prev_url_warning} ${currentUrl}`} />
      )}

      {/* Phone IP display */}
      {phoneIp && (
        <div style={{
          width: '100%', maxWidth: 400, background: '#0f2818',
          border: '1px solid #166534', borderRadius: 10,
          padding: '8px 14px', marginBottom: 14, fontSize: 12, color: '#86efac',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <span>📱</span>
          <span>
            {t.phone_ip_hint} <b style={{ direction: 'ltr', display: 'inline-block' }}>{phoneIp}</b>
            {' '}{t.phone_subnet_hint}{' '}
            <b>{phoneIp.match(/(\d+\.\d+\.\d+)\./)?.[1]}.x</b>
          </span>
        </div>
      )}

      <div style={{ width: '100%', maxWidth: 400 }}>

        {/* ── MENU MODE ── */}
        {(mode === 'menu' || mode === 'failed') && (
          <>
            {/* Big discover button */}
            <button onClick={runDiscover} style={bigBtn('#1d4ed8')}>
              {t.discover_auto}
            </button>

            {/* Manual */}
            <button onClick={() => setMode('manual')} style={{
              ...bigBtn('transparent'), border: '1px solid #334155',
              color: '#94a3b8', marginTop: 10,
            }}>
              {t.enter_ip_manual}
            </button>

            {/* FAILED state — show checklist */}
            {mode === 'failed' && (
              <div style={{
                background: '#1c1007', border: '1px solid #f59e0b',
                borderRadius: 14, padding: 16, marginTop: 16,
              }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: '#f59e0b', marginBottom: 12 }}>
                  ❌ {t.hub_not_found_title}
                </div>
                {getChecklist(t).map((item, i) => (
                  <CheckItem key={i} {...item}
                    checked={diagStep === i}
                    onToggle={() => setDiagStep(diagStep === i ? null : i)} />
                ))}
              </div>
            )}

            {error && <ErrorBox text={error} />}

            {/* Instruction box */}
            <div style={{
              background: '#0f172a', border: '1px solid #1e3a5f',
              borderRadius: 12, padding: '12px 14px', marginTop: 16,
              fontSize: 12, lineHeight: 1.9, color: '#64748b',
            }}>
              <div style={{ color: '#38bdf8', fontWeight: 700, marginBottom: 6 }}>
                {t.instructions_title}
              </div>
              <div>1️⃣ &nbsp;{t.instr1}</div>
              <div>2️⃣ &nbsp;{t.instr2}</div>
              <div>3️⃣ &nbsp;{t.instr3}</div>
              <div>4️⃣ &nbsp;{t.instr4}</div>
            </div>
          </>
        )}

        {/* ── DISCOVER MODE ── */}
        {mode === 'discover' && (
          <div style={{
            background: '#0c2340', border: '1px solid #1d4ed8',
            borderRadius: 14, padding: 20, textAlign: 'center',
          }}>
            <div style={{ fontSize: 36, marginBottom: 12 }}>🔍</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: '#38bdf8', marginBottom: 8 }}>
              {t.hub_searching}
            </div>
            <div style={{ fontSize: 12, color: '#64748b', minHeight: 18 }}>{progress}</div>
            <ProgressBar />
            <button onClick={() => setMode('menu')} style={{
              marginTop: 16, padding: '8px 18px', borderRadius: 8,
              border: '1px solid #334155', background: 'transparent',
              color: '#64748b', cursor: 'pointer', fontSize: 12,
            }}>
              {t.stop}
            </button>
          </div>
        )}

        {/* ── MANUAL MODE ── */}
        {mode === 'manual' && (
          <div style={{
            background: '#1e293b', border: '1px solid #334155',
            borderRadius: 14, padding: 16,
          }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: '#f1f5f9', marginBottom: 4 }}>
              {t.hub_ip_label}
            </div>
            <div style={{ fontSize: 11, color: '#64748b', marginBottom: 12, lineHeight: 1.6 }}>
              {t.hub_ip_desc}
              <br />
              <span style={{ color: '#38bdf8', direction: 'ltr', display: 'inline-block' }}>
                Hub IP: 192.168.x.x
              </span>
            </div>
            <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
              <input
                value={manualIp}
                onChange={e => setManualIp(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && runManual()}
                placeholder="192.168.1.100"
                autoFocus
                style={{ ...inp, flex: 1, direction: 'ltr' }}
              />
              <input
                value={manualPort}
                onChange={e => setManualPort(e.target.value)}
                placeholder="8080"
                style={{ ...inp, width: 72, direction: 'ltr' }}
              />
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={runManual} disabled={testing}
                style={{ ...bigBtn('#1d4ed8'), flex: 1, padding: '11px 0', opacity: testing ? 0.7 : 1 }}>
                {testing ? '⏳...' : t.connect_btn2}
              </button>
              <button onClick={() => { setMode('menu'); setError('') }}
                style={{ padding: '11px 14px', borderRadius: 10, border: '1px solid #334155', background: 'transparent', color: '#64748b', cursor: 'pointer', fontSize: 13 }}>
                ✕
              </button>
            </div>
            {error && <ErrorBox text={error} />}
          </div>
        )}

      </div>
    </div>
  )
}

/* ── Checklist items ─────────────────────────────────────────────────────── */
function getChecklist(t) {
  return [
    { icon: '🖥️', title: t.checklist_bat,       detail: t.checklist_bat_detail },
    { icon: '📶', title: t.checklist_wifi,      detail: t.checklist_wifi_detail },
    { icon: '🔥', title: t.checklist_firewall,  detail: t.checklist_firewall_detail },
    { icon: '🚫', title: t.checklist_isolation, detail: t.checklist_isolation_detail },
    { icon: '🔌', title: t.checklist_ethernet,  detail: t.checklist_ethernet_detail },
  ]
}

function CheckItem({ icon, title, detail, checked, onToggle }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <div onClick={onToggle} style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '8px 10px', borderRadius: 8, cursor: 'pointer',
        background: checked ? '#0c2340' : '#0f172a',
        border: `1px solid ${checked ? '#1d4ed8' : '#1e293b'}`,
      }}>
        <span style={{ fontSize: 18 }}>{icon}</span>
        <span style={{ fontSize: 12, color: '#e2e8f0', flex: 1 }}>{title}</span>
        <span style={{ fontSize: 14, color: '#475569' }}>{checked ? '▲' : '▼'}</span>
      </div>
      {checked && (
        <div style={{
          background: '#0a1929', borderRadius: '0 0 8px 8px',
          padding: '10px 14px', fontSize: 11, color: '#94a3b8',
          lineHeight: 1.7, whiteSpace: 'pre-line',
          borderLeft: '1px solid #1d4ed8',
          borderRight: '1px solid #1d4ed8',
          borderBottom: '1px solid #1d4ed8',
        }}>
          {detail}
        </div>
      )}
    </div>
  )
}

/* ── Small helpers ───────────────────────────────────────────────────────── */
function InfoBox({ icon, text, color, border, bg }) {
  return (
    <div style={{
      width: '100%', maxWidth: 400, background: bg,
      border: `1px solid ${border}`, borderRadius: 10,
      padding: '8px 12px', marginBottom: 14, fontSize: 12,
      color, display: 'flex', gap: 8, alignItems: 'center',
    }}>
      <span>{icon}</span><span>{text}</span>
    </div>
  )
}

function ErrorBox({ text }) {
  return (
    <div style={{
      marginTop: 10, background: '#7f1d1d', border: '1px solid #ef4444',
      borderRadius: 10, padding: '10px 14px', fontSize: 12,
      color: '#fca5a5', whiteSpace: 'pre-line',
    }}>
      {text}
    </div>
  )
}

function ProgressBar() {
  return (
    <div style={{ height: 3, background: '#0f172a', borderRadius: 2, marginTop: 14, overflow: 'hidden' }}>
      <div style={{
        height: '100%', width: '35%', background: '#1d4ed8', borderRadius: 2,
        animation: 'slide 1.2s ease-in-out infinite',
      }} />
      <style>{`@keyframes slide{0%{margin-right:100%}100%{margin-right:-35%}}`}</style>
    </div>
  )
}

const bigBtn = (bg) => ({
  width: '100%', padding: '14px 0', borderRadius: 12, border: 'none',
  background: bg, color: '#fff', cursor: 'pointer',
  fontWeight: 700, fontSize: 15,
})
const inp = {
  padding: '10px 12px', borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a',
  color: '#f1f5f9', fontSize: 14, boxSizing: 'border-box',
}
