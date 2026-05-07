import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

const ICONS = ['🏠','🛋️','🛏️','🍳','🚿','🏢','🌿','🚗','🎮','📚','🏋️','🌙','🔧','🎵','👶','🍽️']
const EMPTY_FORM = { name: '', icon: '🏠' }

export default function RoomsPage() {
  const { t, rtl } = useLang()
  const [rooms, setRooms]       = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm]         = useState(EMPTY_FORM)
  const [editId, setEditId]     = useState(null)
  const [saving, setSaving]     = useState(false)
  const [error, setError]       = useState('')

  const load = () => api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
  useEffect(() => { load() }, [])

  /* ── Open add ── */
  const openAdd = () => {
    setForm(EMPTY_FORM)
    setEditId(null)
    setError('')
    setShowForm(true)
  }

  /* ── Open edit ── */
  const openEdit = (room) => {
    setForm({ name: room.name, icon: room.icon || '🏠' })
    setEditId(room.id)
    setError('')
    setShowForm(true)
  }

  /* ── Save ── */
  const save = async () => {
    if (!form.name.trim()) { setError(t.room_name_required); return }
    setSaving(true)
    try {
      if (editId) {
        await api.put(`/rooms/${editId}`, { name: form.name.trim(), icon: form.icon })
      } else {
        await api.post('/rooms/', { name: form.name.trim(), icon: form.icon })
      }
      setShowForm(false)
      setEditId(null)
      setForm(EMPTY_FORM)
      setError('')
      load()
    } catch (e) {
      const status = e?.response?.status
      if (status === 404) {
        setError(t.room_hub_error)
      } else {
        setError(e?.response?.data?.detail || t.unknown_error)
      }
    }
    setSaving(false)
  }

  /* ── Delete ── */
  const remove = async (room) => {
    if (!confirm(`${t.delete} "${room.name}"?\n${t.confirm_delete_room}`)) return
    try {
      await api.delete(`/rooms/${room.id}`)
      load()
    } catch (e) {
      const status = e?.response?.status
      if (status === 404) {
        alert(t.room_hub_error)
      } else {
        alert(t.error + ': ' + (e?.response?.data?.detail || e.message || t.unknown_error))
      }
    }
  }

  const cancel = () => {
    setShowForm(false)
    setEditId(null)
    setForm(EMPTY_FORM)
    setError('')
  }

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>{t.rooms_title}</h2>
        <button onClick={openAdd} style={btn('#22c55e')}>{t.new_room}</button>
      </div>

      {/* Empty state */}
      {rooms.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#475569' }}>
          <div style={{ fontSize: 48 }}>🏠</div>
          <p style={{ marginTop: 12 }}>{t.no_rooms}</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
          {rooms.map(r => (
            <div key={r.id} style={{ marginBottom: 10 }}>
              {/* Room row */}
              <div style={card}>
                <span style={{ fontSize: 28, minWidth: 36 }}>{r.icon}</span>
                <span style={{ fontWeight: 600, fontSize: 15, flex: 1 }}>{r.name}</span>
              </div>
              {/* Action bar */}
              <div style={{
                display: 'flex', gap: 1,
                borderRadius: '0 0 10px 10px', overflow: 'hidden', marginTop: -1,
              }}>
                <button onClick={() => openEdit(r)} style={actionBtn('#1e293b', '#334155', '#38bdf8')}>
                  {t.edit_name}
                </button>
                <button onClick={() => remove(r)} style={actionBtn('#1e293b', '#334155', '#ef4444')}>
                  {t.delete_room}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal */}
      {showForm && (
        <div style={overlay}>
          <div style={{ ...modal, direction: rtl ? 'rtl' : 'ltr' }}>
            <h3 style={{ marginTop: 0, marginBottom: 16, color: '#f1f5f9' }}>
              {editId ? t.edit_room : t.create_room}
            </h3>

            <label style={lbl}>{t.room_name_label}</label>
            <input
              value={form.name}
              onChange={e => setForm({ ...form, name: e.target.value })}
              onKeyDown={e => e.key === 'Enter' && save()}
              placeholder={t.room_name_placeholder}
              style={{ ...inp, direction: rtl ? 'rtl' : 'ltr' }}
              autoFocus
            />

            <label style={lbl}>{t.room_icon_label}</label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 20 }}>
              {ICONS.map(ic => (
                <button key={ic} onClick={() => setForm({ ...form, icon: ic })} style={{
                  fontSize: 22,
                  background: form.icon === ic ? '#1d4ed8' : '#0f172a',
                  border: `2px solid ${form.icon === ic ? '#38bdf8' : '#334155'}`,
                  borderRadius: 8, padding: '6px 8px', cursor: 'pointer',
                  transition: 'all 0.15s',
                }}>{ic}</button>
              ))}
            </div>

            {error && (
              <div style={{
                background: '#7f1d1d', border: '1px solid #ef4444',
                color: '#fca5a5', borderRadius: 8,
                padding: '8px 12px', fontSize: 13, marginBottom: 14,
              }}>{error}</div>
            )}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={save} disabled={saving}
                style={{ ...btn('#22c55e'), flex: 1, opacity: saving ? 0.7 : 1 }}>
                {saving ? t.saving : (editId ? t.edit_room_save : t.save_room)}
              </button>
              <button onClick={cancel} style={btn('#475569')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const card = {
  display: 'flex', alignItems: 'center', gap: 12,
  background: '#1e293b', border: '1px solid #334155',
  borderRadius: '12px 12px 0 0', padding: '14px 16px',
}
const btn = (bg, color = '#fff') => ({
  padding: '10px 20px', borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 14,
})
const actionBtn = (bg, border, color) => ({
  flex: 1, padding: '8px 4px', border: `1px solid ${border}`,
  background: bg, color, cursor: 'pointer',
  fontSize: 12, fontWeight: 600, textAlign: 'center',
})
const inp = {
  width: '100%', padding: '10px 12px', marginBottom: 14, borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 14, boxSizing: 'border-box',
}
const lbl     = { display: 'block', fontSize: 12, color: '#94a3b8', marginBottom: 6 }
const overlay = { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }
const modal   = { background: '#1e293b', border: '1px solid #334155', borderRadius: 16, padding: 24, width: '90%', maxWidth: 400 }
