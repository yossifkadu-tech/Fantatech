import { useState, useRef, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

/**
 * GeminiAssistant
 *
 * Props:
 *   onDeviceAction — callback when AI returns a device action
 *   inline         — when true, renders as a full tab-content card (no floating button)
 *                    when false/undefined, renders as the classic floating button + panel
 */
/* ── Voice-to-text locale map ── */
const VOICE_LOCALES = {
  he: 'he-IL', en: 'en-US', ar: 'ar-SA',
  ru: 'ru-RU', es: 'es-ES', fr: 'fr-FR',
  de: 'de-DE', pt: 'pt-BR', am: 'am-ET',
}

export default function GeminiAssistant({ onDeviceAction, inline = false }) {
  const { t, lang, rtl } = useLang()
  // In inline mode the chat is always open; in floating mode it starts closed
  const [open, setOpen]         = useState(inline)
  const [messages, setMessages] = useState([])
  const [input, setInput]       = useState('')
  const [loading, setLoading]   = useState(false)
  const [configured, setConfigured] = useState(null)
  const [listening, setListening]   = useState(false)
  const bottomRef = useRef(null)
  const recognizerRef = useRef(null)

  /* ── Voice input ── */
  const startVoice = () => {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SR) { alert(t.gemini_voice_unsupported ?? 'Voice not supported'); return }
    if (listening) { recognizerRef.current?.stop(); return }
    const rec = new SR()
    rec.lang = VOICE_LOCALES[lang] || 'en-US'
    rec.interimResults = false
    rec.maxAlternatives = 1
    rec.onstart  = () => setListening(true)
    rec.onend    = () => setListening(false)
    rec.onerror  = () => setListening(false)
    rec.onresult = (e) => {
      const transcript = e.results[0][0].transcript
      setInput(transcript)
    }
    recognizerRef.current = rec
    rec.start()
  }

  useEffect(() => {
    api.get('/ai/status').then(r => setConfigured(r.data.configured)).catch(() => setConfigured(false))
  }, [])

  // Keep open=true when switching into inline mode
  useEffect(() => { if (inline) setOpen(true) }, [inline])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const send = async () => {
    const text = input.trim()
    if (!text || loading) return
    setInput('')
    const userMsg = { role: 'user', text }
    setMessages(prev => [...prev, userMsg])
    setLoading(true)
    try {
      const history = messages.slice(-6).map(m => ({ role: m.role, text: m.text }))
      const r = await api.post('/ai/chat', { message: text, lang, history })
      const { reply, action } = r.data
      setMessages(prev => [...prev, { role: 'assistant', text: reply }])
      if (action && onDeviceAction) onDeviceAction(action)
    } catch (e) {
      const err = e?.response?.data?.detail || t.error
      setMessages(prev => [...prev, { role: 'assistant', text: `⚠️ ${err}`, error: true }])
    }
    setLoading(false)
  }

  const clearChat = () => setMessages([])

  /* ── Inline (tab) mode ─────────────────────────────────────────────── */
  if (inline) {
    return (
      <div style={{
        background: '#1e293b', border: '1px solid #334155',
        borderRadius: 16, overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
        height: 'calc(100vh - 160px)',   // fills tab content area
        direction: rtl ? 'rtl' : 'ltr',
      }}>
        {/* Header */}
        <div style={{
          background: '#1d4ed8', padding: '12px 16px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          flexShrink: 0,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 22 }}>✨</span>
            <div>
              <div style={{ fontWeight: 700, color: '#fff', fontSize: 15 }}>
                {t.ai_assistant ?? 'AI Assistant'} — Gemini
              </div>
              <div style={{ fontSize: 10, color: '#93c5fd', marginTop: 1 }}>
                {t.gemini_hint ?? 'Powered by Google Gemini'}
              </div>
            </div>
            {configured === false && (
              <span style={{ fontSize: 10, background: '#f59e0b', color: '#000', borderRadius: 4, padding: '1px 6px' }}>
                ⚠️ {t.ai_not_configured ?? 'Not configured'}
              </span>
            )}
          </div>
          <button onClick={clearChat} style={{
            background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.2)',
            borderRadius: 8, color: '#e0f2fe', cursor: 'pointer', fontSize: 12,
            padding: '4px 10px', fontWeight: 600,
          }}>{t.clear ?? 'Clear'}</button>
        </div>

        {/* Messages */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {messages.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px 20px', color: '#475569', fontSize: 13, lineHeight: 1.7 }}>
              <div style={{ fontSize: 40, marginBottom: 12 }}>✨</div>
              {configured === false ? t.ai_not_configured : (t.gemini_hint_smart ?? 'Ask me anything about your smart home…')}
            </div>
          )}
          {messages.map((m, i) => (
            <div key={i} style={{
              alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start',
              maxWidth: '85%',
            }}>
              <div style={{
                background: m.role === 'user' ? '#1d4ed8' : m.error ? '#7f1d1d' : '#334155',
                color: m.error ? '#fca5a5' : '#f1f5f9',
                borderRadius: m.role === 'user' ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                padding: '10px 14px', fontSize: 13, lineHeight: 1.6,
                whiteSpace: 'pre-wrap', wordBreak: 'break-word',
              }}>
                {m.text}
              </div>
            </div>
          ))}
          {loading && (
            <div style={{ alignSelf: 'flex-start', color: '#64748b', fontSize: 13, fontStyle: 'italic', display: 'flex', gap: 6, alignItems: 'center' }}>
              <span style={{ animation: 'pulse 1s infinite' }}>✨</span> {t.saving ?? 'Thinking...'}
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div style={{
          padding: '10px 12px', borderTop: '1px solid #334155',
          display: 'flex', gap: 8, flexShrink: 0,
          background: '#1e293b',
        }}>
          {/* Mic button */}
          <button onClick={startVoice} title={listening ? (t.gemini_voice_listening ?? 'Listening...') : (t.gemini_voice ?? 'Voice')} style={{
            width: 44, height: 44, borderRadius: 12, border: 'none', flexShrink: 0,
            background: listening ? '#dc2626' : '#334155',
            color: '#fff', fontSize: 18, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'background 0.2s',
            animation: listening ? 'pulse 1s infinite' : 'none',
          }}>🎤</button>
          <input
            value={listening ? (t.gemini_voice_listening ?? 'Listening…') : input}
            onChange={e => !listening && setInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && !e.shiftKey && send()}
            placeholder={t.type_message ?? 'Type a message…'}
            disabled={loading || listening}
            style={{
              flex: 1, padding: '11px 14px', borderRadius: 12,
              border: `1px solid ${listening ? '#dc2626' : '#334155'}`,
              background: '#0f172a',
              color: listening ? '#94a3b8' : '#f1f5f9',
              fontSize: 14, outline: 'none',
              direction: rtl ? 'rtl' : 'ltr',
            }}
          />
          <button onClick={send} disabled={loading || !input.trim() || listening} style={{
            padding: '11px 18px', borderRadius: 12, border: 'none',
            background: input.trim() && !loading && !listening ? '#1d4ed8' : '#334155',
            color: '#fff', cursor: input.trim() && !loading ? 'pointer' : 'default',
            fontSize: 16, fontWeight: 700, transition: 'background 0.15s',
          }}>↑</button>
        </div>
      </div>
    )
  }

  /* ── Floating (legacy) mode ────────────────────────────────────────── */
  return (
    <>
      {/* Floating button */}
      <button
        onClick={() => setOpen(v => !v)}
        style={{
          position: 'fixed', bottom: 75, left: 16,
          width: 48, height: 48, borderRadius: '50%',
          background: open ? '#7c3aed' : '#1d4ed8',
          border: '2px solid #334155',
          color: '#fff', fontSize: 22, cursor: 'pointer',
          boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 90, transition: 'all 0.2s',
        }}
        title={t.ai_assistant}
      >
        {open ? '✕' : '✨'}
      </button>

      {/* Chat panel */}
      {open && (
        <div style={{
          position: 'fixed', bottom: 134, left: 10, right: 10,
          maxWidth: 460, margin: '0 auto',
          background: '#1e293b', border: '1px solid #334155',
          borderRadius: 16, overflow: 'hidden',
          boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
          display: 'flex', flexDirection: 'column',
          maxHeight: '55vh', zIndex: 89,
          direction: rtl ? 'rtl' : 'ltr',
        }}>
          {/* Header */}
          <div style={{
            background: '#1d4ed8', padding: '10px 14px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            flexShrink: 0,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 18 }}>✨</span>
              <span style={{ fontWeight: 700, color: '#fff', fontSize: 14 }}>
                {t.ai_assistant} — Gemini
              </span>
              {configured === false && (
                <span style={{ fontSize: 10, background: '#f59e0b', color: '#000', borderRadius: 4, padding: '1px 6px' }}>
                  ⚠️
                </span>
              )}
            </div>
            <button onClick={clearChat} style={{
              background: 'none', border: 'none', color: '#93c5fd',
              cursor: 'pointer', fontSize: 11,
            }}>{t.clear}</button>
          </div>

          {/* Messages */}
          <div style={{ flex: 1, overflowY: 'auto', padding: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
            {messages.length === 0 && (
              <div style={{ textAlign: 'center', padding: '20px 0', color: '#475569', fontSize: 13 }}>
                {configured === false ? t.ai_not_configured : t.gemini_hint_smart}
              </div>
            )}
            {messages.map((m, i) => (
              <div key={i} style={{
                alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start',
                maxWidth: '85%',
              }}>
                <div style={{
                  background: m.role === 'user' ? '#1d4ed8' : m.error ? '#7f1d1d' : '#334155',
                  color: m.error ? '#fca5a5' : '#f1f5f9',
                  borderRadius: m.role === 'user' ? '14px 14px 4px 14px' : '14px 14px 14px 4px',
                  padding: '8px 12px', fontSize: 13, lineHeight: 1.5,
                  whiteSpace: 'pre-wrap', wordBreak: 'break-word',
                }}>
                  {m.text}
                </div>
              </div>
            ))}
            {loading && (
              <div style={{ alignSelf: 'flex-start', color: '#64748b', fontSize: 13, fontStyle: 'italic' }}>
                ✨ {t.saving}
              </div>
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input */}
          <div style={{
            padding: '8px 10px', borderTop: '1px solid #334155',
            display: 'flex', gap: 8, flexShrink: 0,
          }}>
            <input
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && !e.shiftKey && send()}
              placeholder={t.type_message}
              disabled={loading}
              style={{
                flex: 1, padding: '9px 12px', borderRadius: 10,
                border: '1px solid #334155', background: '#0f172a',
                color: '#f1f5f9', fontSize: 13, outline: 'none',
                direction: rtl ? 'rtl' : 'ltr',
              }}
            />
            <button onClick={send} disabled={loading || !input.trim()} style={{
              padding: '9px 14px', borderRadius: 10, border: 'none',
              background: input.trim() && !loading ? '#1d4ed8' : '#334155',
              color: '#fff', cursor: 'pointer', fontSize: 15, fontWeight: 700,
            }}>↑</button>
          </div>
        </div>
      )}
    </>
  )
}
