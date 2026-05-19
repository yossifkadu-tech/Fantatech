/**
 * VoiceControl — mic button that listens, parses, and executes device commands.
 *
 * Supported command patterns (Hebrew + English):
 *   "כבה <device>"  /  "turn off <device>"
 *   "הדלק <device>" /  "turn on <device>"
 *   "החלף <device>" /  "toggle <device>"
 *   "כבה הכל"       /  "turn off all"
 *
 * Uses Web Speech API (SpeechRecognition) — available in Chrome + Android WebView.
 */
import { useState, useRef, useEffect, useLayoutEffect } from 'react'

/* inject keyframes once into document.head — avoids style tag inside flex */
function injectMicCSS() {
  if (document.getElementById('ft-mic-css')) return
  const s = document.createElement('style')
  s.id = 'ft-mic-css'
  s.textContent = `@keyframes mic-pulse{0%{transform:scale(1);opacity:.6}100%{transform:scale(2.2);opacity:0}}`
  document.head.appendChild(s)
}
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

/* ── Fuzzy device name match ─────────────────────────────────────────── */
function findDevice(transcript, devices) {
  const t = transcript.toLowerCase()
  // Exact match first
  let match = devices.find(d => t.includes(d.name.toLowerCase()))
  if (match) return match
  // Word-by-word partial match (≥ 3 chars)
  for (const d of devices) {
    const words = d.name.toLowerCase().split(/\s+/)
    if (words.some(w => w.length >= 3 && t.includes(w))) return d
  }
  return null
}

/* ── Parse transcript → command ──────────────────────────────────────── */
function parseCommand(transcript, devices, t) {
  const lower = transcript.toLowerCase()

  // "turn off all" / "כבה הכל"
  if (/turn off all|כבה הכל|כבו הכל/.test(lower)) {
    return { type: 'all_off' }
  }

  // Determine action
  let action = null
  if (/turn on|הדלק|הפעל|פתח/.test(lower))  action = 'ON'
  if (/turn off|כבה|סגור|עצור/.test(lower)) action = 'OFF'
  if (/toggle|החלף|שנה/.test(lower))         action = 'TOGGLE'

  if (!action) return null

  const device = findDevice(lower, devices)
  if (!device) return { type: 'no_device', action }

  return { type: 'device', action, device }
}

/* ── Pulsing mic animation ───────────────────────────────────────────── */
function MicPulse({ active }) {
  return (
    <div style={{ position: 'relative', width: 80, height: 80, margin: '0 auto' }}>
      {active && [1, 2, 3].map(i => (
        <div key={i} style={{
          position: 'absolute', inset: 0, borderRadius: '50%',
          border: '2px solid #ef4444',
          animation: `mic-pulse ${0.9 + i * 0.3}s ease-out infinite`,
          animationDelay: `${i * 0.2}s`,
          opacity: 0,
        }} />
      ))}
      <div style={{
        position: 'absolute', inset: 0,
        background: active ? 'rgba(239,68,68,0.15)' : 'rgba(56,189,248,0.1)',
        borderRadius: '50%',
        border: `2px solid ${active ? '#ef4444' : '#38bdf8'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 32,
        transition: 'all 0.2s',
      }}>
        🎤
      </div>
    </div>
  )
}

/* ─────────────────────────────────────────────────────────────────────── */
export default function VoiceControl({ devices, onReload }) {
  const { t, lang, rtl } = useLang()
  const [open,       setOpen]       = useState(false)
  const [listening,  setListening]  = useState(false)
  const [transcript, setTranscript] = useState('')
  const [status,     setStatus]     = useState('')   // 'success' | 'error' | 'info' | ''
  const [statusMsg,  setStatusMsg]  = useState('')
  const recognitionRef = useRef(null)

  useLayoutEffect(() => { injectMicCSS() }, [])

  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition

  const startListening = () => {
    if (!SpeechRecognition) {
      setStatus('error')
      setStatusMsg(t.voice_not_supported ?? 'Speech recognition not supported on this device.')
      return
    }

    const r = new SpeechRecognition()
    r.lang = lang === 'he' ? 'he-IL' : lang === 'ar' ? 'ar-SA' : 'en-US'
    r.interimResults = true
    r.maxAlternatives = 1
    recognitionRef.current = r

    r.onstart  = () => { setListening(true); setTranscript(''); setStatus(''); setStatusMsg('') }
    r.onend    = () => setListening(false)
    r.onerror  = (e) => {
      setListening(false)
      setStatus('error')
      setStatusMsg(e.error === 'no-speech' ? (t.voice_no_speech ?? 'Nothing heard. Try again.') : e.error)
    }

    r.onresult = async (e) => {
      const text = Array.from(e.results).map(r => r[0].transcript).join('')
      setTranscript(text)

      if (e.results[e.results.length - 1].isFinal) {
        await executeCommand(text)
      }
    }

    r.start()
  }

  const stopListening = () => {
    recognitionRef.current?.stop()
    setListening(false)
  }

  const executeCommand = async (text) => {
    const cmd = parseCommand(text, devices, t)

    if (!cmd) {
      setStatus('error')
      setStatusMsg(t.voice_unknown_cmd ?? `Unknown command: "${text}"`)
      return
    }

    if (cmd.type === 'all_off') {
      try {
        await Promise.allSettled(
          devices.filter(d => d.online).map(d =>
            api.post(`/devices/${d.id}/cmd`, { payload: { state: 'OFF' } })
          )
        )
        setStatus('success')
        setStatusMsg(t.voice_all_off ?? 'All devices turned OFF')
        onReload?.()
      } catch {
        setStatus('error'); setStatusMsg(t.voice_error ?? 'Error')
      }
      return
    }

    if (cmd.type === 'no_device') {
      setStatus('error')
      setStatusMsg(t.voice_device_not_found ?? 'Device not found.')
      return
    }

    // device command
    try {
      await api.post(`/devices/${cmd.device.id}/cmd`, { payload: { state: cmd.action } })
      setStatus('success')
      setStatusMsg(`${cmd.device.name} → ${cmd.action}`)
      onReload?.()
    } catch {
      setStatus('error'); setStatusMsg(t.voice_error ?? 'Error executing command')
    }
  }

  // Auto-close success after 2.5 s
  useEffect(() => {
    if (status === 'success') {
      const id = setTimeout(() => { setOpen(false); setStatus(''); setTranscript('') }, 2500)
      return () => clearTimeout(id)
    }
  }, [status])

  // Cleanup on unmount
  useEffect(() => () => recognitionRef.current?.stop(), [])

  const dir = rtl ? 'rtl' : 'ltr'

  return (
    <>
      {/* Trigger button (shown in header) */}
      <button
        onClick={() => setOpen(true)}
        title={t.voice_tap ?? 'Voice command'}
        style={{
          background: 'rgba(239,68,68,0.1)',
          border: '1px solid #ef444444',
          borderRadius: 8, padding: '4px 8px',
          cursor: 'pointer', fontSize: 16, lineHeight: 1,
          WebkitTapHighlightColor: 'transparent',
        }}
      >
        🎤
      </button>

      {/* Overlay */}
      {open && (
        <div style={{
          position: 'fixed', inset: 0,
          background: 'rgba(0,0,0,0.92)',
          display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center',
          zIndex: 300, direction: dir, gap: 24,
          padding: 24,
        }}>
          {/* Close */}
          <button onClick={() => { stopListening(); setOpen(false) }} style={{
            position: 'absolute', top: 20, insetInlineEnd: 20,
            background: '#1e293b', border: '1px solid #334155',
            borderRadius: 10, padding: '6px 12px',
            color: '#94a3b8', fontSize: 14, cursor: 'pointer',
          }}>✕</button>

          <div style={{ fontSize: 15, color: '#64748b', fontWeight: 600 }}>
            {t.voice_title ?? 'Voice Command'}
          </div>

          <MicPulse active={listening} />

          {/* Transcript */}
          <div style={{
            minHeight: 48, textAlign: 'center',
            fontSize: 18, fontWeight: 700, color: '#f1f5f9',
            maxWidth: 320,
          }}>
            {transcript || (listening
              ? (t.voice_listening ?? 'Listening…')
              : (t.voice_prompt ?? 'Tap mic to speak'))}
          </div>

          {/* Status */}
          {statusMsg && (
            <div style={{
              background: status === 'success' ? 'rgba(34,197,94,0.15)' : 'rgba(239,68,68,0.15)',
              border: `1px solid ${status === 'success' ? '#22c55e' : '#ef4444'}`,
              borderRadius: 12, padding: '10px 20px',
              fontSize: 14, fontWeight: 700,
              color: status === 'success' ? '#4ade80' : '#f87171',
              textAlign: 'center',
            }}>
              {status === 'success' ? '✓ ' : '✕ '}{statusMsg}
            </div>
          )}

          {/* Mic button */}
          <button
            onPointerDown={startListening}
            onPointerUp={stopListening}
            style={{
              width: 72, height: 72, borderRadius: '50%', border: 'none',
              background: listening
                ? 'linear-gradient(135deg,#dc2626,#ef4444)'
                : 'linear-gradient(135deg,#1d4ed8,#3b82f6)',
              color: '#fff', fontSize: 26,
              cursor: 'pointer', boxShadow: listening ? '0 0 30px rgba(239,68,68,0.5)' : '0 4px 20px rgba(59,130,246,0.4)',
              transition: 'all 0.2s',
              WebkitTapHighlightColor: 'transparent',
            }}
          >
            {listening ? '⏹' : '🎤'}
          </button>

          <div style={{ fontSize: 11, color: '#475569', textAlign: 'center', maxWidth: 280, lineHeight: 1.8 }}>
            {t.voice_hint ?? '"Turn on lights" · "Turn off all" · "Toggle AC"'}
          </div>

          {/* Example commands */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center', maxWidth: 340 }}>
            {[
              t.voice_ex1 ?? 'הדלק אורות',
              t.voice_ex2 ?? 'כבה הכל',
              t.voice_ex3 ?? 'הפעל מזגן',
            ].map(ex => (
              <div key={ex} style={{
                background: '#1e293b', border: '1px solid #334155',
                borderRadius: 20, padding: '4px 12px',
                fontSize: 12, color: '#64748b',
              }}>{ex}</div>
            ))}
          </div>
        </div>
      )}
    </>
  )
}
