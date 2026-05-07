import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

const SCENE_ICONS = ['🎬', '🌙', '☀️', '🏠', '🎮', '🍽️', '🛏️', '🏋️', '🎉', '🌿', '❄️', '🔥', '💡', '🔒', '🌅']

const ACTION_TYPES = [
  { id: 'on',         label: '▶ הדלק',        forTypes: ['light','switch','dimmer','color','fan','lock','ac'] },
  { id: 'off',        label: '⏹ כבה',          forTypes: ['light','switch','dimmer','color','fan','lock','ac'] },
  { id: 'toggle',     label: '🔀 החלף',        forTypes: ['light','switch','dimmer','color','fan'] },
  { id: 'brightness', label: '🔆 בהירות',       forTypes: ['dimmer','color','light'] },
  { id: 'lock',       label: '🔒 נעל',          forTypes: ['lock'] },
  { id: 'unlock',     label: '🔓 פתח',          forTypes: ['lock'] },
  { id: 'ac',         label: '❄️ הגדר מזגן',   forTypes: ['ac'] },
]

const DEVICE_ICONS = {
  light: '💡', switch: '🔌', dimmer: '🔆', color: '🎨',
  sensor: '🌡️', camera: '📷', lock: '🔒', fan: '🌀', ac: '❄️',
}

export default function ScenesPage({ devices }) {
  const { t, lang } = useLang()
  const [scenes, setScenes]     = useState([])
  const [loading, setLoading]   = useState(true)
  const [running, setRunning]   = useState({})   // scene_id → bool
  const [runMsg, setRunMsg]     = useState({})   // scene_id → msg
  const [editScene, setEditScene] = useState(null) // null | scene object
  const [showEditor, setShowEditor] = useState(false)

  const load = async () => {
    try {
      const r = await api.get('/scenes/')
      setScenes(r.data)
    } catch {}
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  const runScene = async (scene) => {
    setRunning(p => ({ ...p, [scene.id]: true }))
    setRunMsg(p => ({ ...p, [scene.id]: null }))
    try {
      const r = await api.post(`/scenes/${scene.id}/execute`)
      setRunMsg(p => ({ ...p, [scene.id]: { ok: true, text: r.data.message } }))
    } catch (e) {
      setRunMsg(p => ({ ...p, [scene.id]: { ok: false, text: e?.response?.data?.detail || 'שגיאה בהפעלת הסצנה' } }))
    }
    setRunning(p => ({ ...p, [scene.id]: false }))
    setTimeout(() => setRunMsg(p => ({ ...p, [scene.id]: null })), 3500)
  }

  const deleteScene = async (scene) => {
    if (!confirm(`למחוק את הסצנה "${scene.name}"?`)) return
    try {
      await api.delete(`/scenes/${scene.id}`)
      load()
    } catch {}
  }

  const openNew = () => {
    setEditScene({ id: null, name: '', icon: '🎬', actions: [] })
    setShowEditor(true)
  }

  const openEdit = (scene) => {
    setEditScene({ ...scene, actions: scene.actions.map(a => ({ ...a, params: { ...a.params } })) })
    setShowEditor(true)
  }

  if (loading) return (
    <div style={{ textAlign: 'center', padding: 60, color: '#475569' }}>
      <div style={{ fontSize: 36 }}>⏳</div>
      <p style={{ marginTop: 12 }}>טוען סצנות...</p>
    </div>
  )

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>🎬 {t.scenes_title}</h2>
          <div style={{ fontSize: 12, color: '#475569', marginTop: 2 }}>{t.scenes_hint}</div>
        </div>
        <button onClick={openNew} style={btn('#1d4ed8')}>+ {t.new_scene}</button>
      </div>

      {scenes.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '50px 20px', color: '#475569' }}>
          <div style={{ fontSize: 52 }}>🎬</div>
          <p style={{ marginTop: 12, fontSize: 14 }}>{t.no_scenes}</p>
          <p style={{ fontSize: 12, marginTop: 4 }}>{t.no_scenes_hint}</p>
          <button onClick={openNew} style={{ ...btn('#1d4ed8'), marginTop: 16 }}>+ {t.create_first_scene}</button>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {scenes.map(scene => (
            <SceneCard
              key={scene.id}
              scene={scene}
              devices={devices}
              running={running[scene.id]}
              runMsg={runMsg[scene.id]}
              onRun={() => runScene(scene)}
              onEdit={() => openEdit(scene)}
              onDelete={() => deleteScene(scene)}
            />
          ))}
        </div>
      )}

      {showEditor && editScene && (
        <SceneEditor
          scene={editScene}
          devices={devices}
          onSave={async (data) => {
            try {
              if (data.id) {
                await api.put(`/scenes/${data.id}`, data)
              } else {
                await api.post('/scenes/', data)
              }
              setShowEditor(false)
              setEditScene(null)
              load()
            } catch (e) {
              alert(e?.response?.data?.detail || 'שגיאה בשמירה')
            }
          }}
          onClose={() => { setShowEditor(false); setEditScene(null) }}
        />
      )}
    </div>
  )
}

/* ── Scene card ─────────────────────────────────────────────────────────────── */
function SceneCard({ scene, devices, running, runMsg, onRun, onEdit, onDelete }) {
  const devMap = Object.fromEntries(devices.map(d => [d.id, d]))

  return (
    <div style={{
      background: '#1e293b', border: '1px solid #334155',
      borderRadius: 16, padding: 14, transition: 'border-color 0.2s',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
        <span style={{ fontSize: 32, lineHeight: 1 }}>{scene.icon}</span>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 700, fontSize: 15, color: '#f1f5f9' }}>{scene.name}</div>
          <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>
            {scene.actions.length} פעולות
            {scene.actions.slice(0, 3).map((a, i) => {
              const dev = devMap[a.device_id]
              return dev ? (
                <span key={i} style={{ marginRight: 6 }}>
                  {DEVICE_ICONS[dev.type] || '🔌'} {dev.name}
                  <span style={{ color: '#334155' }}> ·</span>
                </span>
              ) : null
            })}
          </div>
        </div>
        <button onClick={onRun} disabled={running} style={{
          ...btn('#22c55e'), padding: '8px 16px', flexShrink: 0,
          opacity: running ? 0.6 : 1, minWidth: 64, fontSize: 13,
        }}>
          {running ? '⏳' : '▶ הפעל'}
        </button>
      </div>

      {runMsg && (
        <div style={{
          padding: '6px 10px', borderRadius: 8, fontSize: 12, marginBottom: 8,
          background: runMsg.ok ? '#14532d' : '#7f1d1d',
          border: `1px solid ${runMsg.ok ? '#22c55e' : '#ef4444'}`,
          color: '#f1f5f9',
        }}>
          {runMsg.text}
        </div>
      )}

      <div style={{ display: 'flex', gap: 1, borderRadius: '0 0 8px 8px', overflow: 'hidden', marginTop: 4 }}>
        <button onClick={onEdit} style={{ flex: 1, padding: '6px 4px', border: '1px solid #334155', background: '#1e293b', color: '#94a3b8', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
          ✏️ ערוך
        </button>
        <button onClick={onDelete} style={{ flex: 1, padding: '6px 4px', border: '1px solid #334155', background: '#1e293b', color: '#ef4444', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
          🗑️ מחק
        </button>
      </div>
    </div>
  )
}

/* ── Scene editor modal ─────────────────────────────────────────────────────── */
function SceneEditor({ scene, devices, onSave, onClose }) {
  const [name, setName]       = useState(scene.name)
  const [icon, setIcon]       = useState(scene.icon)
  const [actions, setActions] = useState(scene.actions || [])
  const [saving, setSaving]   = useState(false)
  const [err, setErr]         = useState('')

  const controllable = devices.filter(d => !['sensor', 'motion', 'door', 'smoke', 'camera'].includes(d.type))

  const addAction = () => {
    if (!controllable.length) return
    const first = controllable[0]
    setActions(prev => [...prev, { device_id: first.id, type: 'on', params: {} }])
  }

  const updateAction = (idx, patch) => {
    setActions(prev => prev.map((a, i) => i === idx ? { ...a, ...patch } : a))
  }

  const removeAction = (idx) => {
    setActions(prev => prev.filter((_, i) => i !== idx))
  }

  const save = async () => {
    if (!name.trim()) { setErr('הכנס שם לסצנה'); return }
    setSaving(true)
    await onSave({ id: scene.id, name: name.trim(), icon, actions })
    setSaving(false)
  }

  return (
    <div style={overlay}>
      <div style={{ ...modal, maxHeight: '92vh' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <h3 style={{ margin: 0 }}>{scene.id ? '✏️ ערוך סצנה' : '🎬 סצנה חדשה'}</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 20 }}>✕</button>
        </div>

        {/* Name */}
        <label style={lbl}>שם הסצנה</label>
        <input value={name} onChange={e => setName(e.target.value)} placeholder="לילה, בוקר, סרט..." style={inp} autoFocus />

        {/* Icon picker */}
        <label style={lbl}>אייקון</label>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 14 }}>
          {SCENE_ICONS.map(ic => (
            <button key={ic} onClick={() => setIcon(ic)} style={{
              width: 38, height: 38, borderRadius: 10, border: 'none',
              background: icon === ic ? '#1d4ed8' : '#0f172a',
              fontSize: 20, cursor: 'pointer',
              boxShadow: icon === ic ? '0 0 0 2px #60a5fa' : 'none',
            }}>{ic}</button>
          ))}
        </div>

        {/* Actions */}
        <label style={lbl}>פעולות ({actions.length})</label>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 10, maxHeight: '35vh', overflowY: 'auto' }}>
          {actions.map((action, idx) => (
            <ActionRow
              key={idx}
              action={action}
              devices={controllable}
              onChange={patch => updateAction(idx, patch)}
              onRemove={() => removeAction(idx)}
            />
          ))}
          {actions.length === 0 && (
            <div style={{ textAlign: 'center', padding: '16px 0', color: '#475569', fontSize: 12 }}>
              אין פעולות — לחץ הוסף
            </div>
          )}
        </div>

        <button onClick={addAction} style={{ ...btn('#334155'), width: '100%', marginBottom: 14, fontSize: 12 }}>
          + הוסף פעולה
        </button>

        {err && <div style={errBox}>{err}</div>}

        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={save} disabled={saving} style={{ ...btn('#22c55e'), flex: 1, opacity: saving ? 0.7 : 1 }}>
            {saving ? '⏳ שומר...' : scene.id ? '💾 שמור שינויים' : '✅ צור סצנה'}
          </button>
          <button onClick={onClose} style={btn('#475569')}>ביטול</button>
        </div>
      </div>
    </div>
  )
}

/* ── Single action row ──────────────────────────────────────────────────────── */
function ActionRow({ action, devices, onChange, onRemove }) {
  const device = devices.find(d => d.id === action.device_id) || devices[0]
  const availableTypes = ACTION_TYPES.filter(t => !device || t.forTypes.includes(device.type))
  const currentType = availableTypes.find(t => t.id === action.type) || availableTypes[0]

  return (
    <div style={{ background: '#0f172a', border: '1px solid #334155', borderRadius: 10, padding: 10 }}>
      <div style={{ display: 'flex', gap: 6, marginBottom: currentType?.id === 'brightness' || currentType?.id === 'ac' ? 8 : 0 }}>
        {/* Device picker */}
        <select
          value={action.device_id}
          onChange={e => {
            const dev = devices.find(d => d.id === e.target.value)
            const defaultType = dev?.type === 'ac' ? 'ac' : dev?.type === 'lock' ? 'lock' : 'on'
            onChange({ device_id: e.target.value, type: defaultType, params: {} })
          }}
          style={{ ...inp, flex: 2, marginBottom: 0, fontSize: 11, padding: '5px 8px' }}>
          {devices.map(d => (
            <option key={d.id} value={d.id}>{DEVICE_ICONS[d.type] || '🔌'} {d.name}</option>
          ))}
        </select>

        {/* Action type */}
        <select
          value={action.type}
          onChange={e => onChange({ type: e.target.value, params: {} })}
          style={{ ...inp, flex: 1, marginBottom: 0, fontSize: 11, padding: '5px 8px' }}>
          {availableTypes.map(t => (
            <option key={t.id} value={t.id}>{t.label}</option>
          ))}
        </select>

        <button onClick={onRemove} style={{ background: '#7f1d1d', border: 'none', color: '#ef4444', borderRadius: 6, padding: '0 10px', cursor: 'pointer', fontSize: 13, flexShrink: 0 }}>✕</button>
      </div>

      {/* Brightness param */}
      {action.type === 'brightness' && (
        <div>
          <div style={{ fontSize: 10, color: '#64748b', marginBottom: 3 }}>בהירות: {action.params?.brightness || 128}</div>
          <input type="range" min={1} max={255}
            value={action.params?.brightness || 128}
            onChange={e => onChange({ params: { brightness: parseInt(e.target.value) } })}
            style={{ width: '100%', accentColor: '#38bdf8' }} />
        </div>
      )}

      {/* AC params */}
      {action.type === 'ac' && (
        <div style={{ display: 'flex', gap: 6 }}>
          <select
            value={action.params?.mode || 'cool'}
            onChange={e => onChange({ params: { ...action.params, mode: e.target.value } })}
            style={{ ...inp, flex: 1, marginBottom: 0, fontSize: 11, padding: '4px 6px' }}>
            <option value="cool">❄️ קירור</option>
            <option value="heat">🔥 חימום</option>
            <option value="fan">💨 מאוורר</option>
            <option value="dry">💧 ייבוש</option>
            <option value="auto">🔄 אוטו</option>
          </select>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, background: '#1e293b', borderRadius: 8, padding: '4px 8px', border: '1px solid #334155' }}>
            <button onClick={() => onChange({ params: { ...action.params, temperature: Math.max(16, (action.params?.temperature || 24) - 1) } })}
              style={{ background: 'none', border: 'none', color: '#38bdf8', cursor: 'pointer', fontSize: 14, padding: 0 }}>−</button>
            <span style={{ fontSize: 13, color: '#f1f5f9', minWidth: 30, textAlign: 'center' }}>
              {action.params?.temperature || 24}°
            </span>
            <button onClick={() => onChange({ params: { ...action.params, temperature: Math.min(30, (action.params?.temperature || 24) + 1) } })}
              style={{ background: 'none', border: 'none', color: '#38bdf8', cursor: 'pointer', fontSize: 14, padding: 0 }}>+</button>
          </div>
        </div>
      )}
    </div>
  )
}

/* ── Styles ─────────────────────────────────────────────────────────────────── */
const btn = (bg, color = '#fff') => ({
  padding: '9px 18px', borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const inp = {
  width: '100%', padding: '10px 12px', marginBottom: 10, borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 13, boxSizing: 'border-box', direction: 'rtl',
}
const lbl     = { display: 'block', fontSize: 12, color: '#94a3b8', marginBottom: 5 }
const errBox  = { background: '#7f1d1d', border: '1px solid #ef4444', color: '#fca5a5', borderRadius: 8, padding: '8px 12px', fontSize: 13, marginBottom: 12 }
const overlay = { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }
const modal   = { background: '#1e293b', border: '1px solid #334155', borderRadius: 16, padding: 20, width: '92%', maxWidth: 420, direction: 'rtl', overflowY: 'auto' }
