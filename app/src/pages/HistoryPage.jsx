import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

export default function HistoryPage() {
  const { t, rtl, locale } = useLang()
  const [entries, setEntries] = useState([])
  const [filter, setFilter] = useState('')

  const load = () => api.get('/history/?limit=200').then(r => setEntries(r.data)).catch(() => {})
  useEffect(() => { load() }, [])

  const clear = async () => {
    if (!confirm(t.confirm_clear_history)) return
    try {
      await api.delete('/history/')
    } catch {}
    setEntries([])
  }

  const fmt = (ts) => new Date(ts * 1000).toLocaleString(locale, {
    day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit'
  })

  const filtered = filter
    ? entries.filter(e => e.device_name.includes(filter) || e.action.includes(filter))
    : entries

  const icon = (e) => {
    if (e.action.startsWith('rule:')) return '⚙️'
    if (e.value === 'ON') return '💡'
    if (e.value === 'OFF') return '🌑'
    return '⚡'
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>{t.history_title}</h2>
        {entries.length > 0 && (
          <button onClick={clear} style={btn('#ef4444')}>{t.clear}</button>
        )}
      </div>

      <input value={filter} onChange={e => setFilter(e.target.value)}
        placeholder={t.search_history} style={{
          ...inp, marginBottom: 16, direction: rtl ? 'rtl' : 'ltr',
        }} />

      {filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#475569' }}>
          <div style={{ fontSize: 48 }}>📋</div>
          <p style={{ marginTop: 12 }}>{t.no_history}</p>
        </div>
      ) : filtered.map((e, i) => (
        <div key={i} style={card}>
          <span style={{ fontSize: 18, minWidth: 24 }}>{icon(e)}</span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontWeight: 600, fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {e.device_name}
            </div>
            <div style={{ fontSize: 12, color: '#64748b' }}>
              {e.action}{e.value ? ` → ${e.value}` : ''}
            </div>
          </div>
          <div style={{ fontSize: 11, color: '#475569', flexShrink: 0 }}>{fmt(e.ts)}</div>
        </div>
      ))}
    </div>
  )
}

const card = {
  display: 'flex', alignItems: 'center', gap: 10,
  background: '#1e293b', border: '1px solid #334155',
  borderRadius: 10, padding: '10px 14px', marginBottom: 6,
}
const btn = (bg, color = '#fff') => ({
  padding: '6px 14px', borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const inp = {
  width: '100%', padding: '10px 14px', borderRadius: 10,
  border: '1px solid #334155', background: '#1e293b', color: '#f1f5f9',
  fontSize: 14, boxSizing: 'border-box',
}
