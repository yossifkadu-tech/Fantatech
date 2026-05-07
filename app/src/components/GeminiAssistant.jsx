import { useState, useRef, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

export default function GeminiAssistant({ onDeviceAction }) {
  const { t, lang, rtl } = useLang()
  const [open, setOpen]       = useState(false)
  const [messages, setMessages] = useState([])
  const [input, setInput]     = useState('')
  const [loading, setLoading] = useState(false)
  const [configured, setConfigured] = useState(null)
  const bottomRef = useRef(null)

  useEffect(() => {
    api.get('/ai/status').then(r => setConfigured(r.data.configured)).catch(() => setConfigured(false))
  }, [])

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
                {configured === false
                  ? t.ai_not_configured
                  : t.gemini_hint_smart}
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
