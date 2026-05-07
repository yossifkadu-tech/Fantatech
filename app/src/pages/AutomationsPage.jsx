import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

/* ── Trigger types ─────────────────────────────────────────────────── */
const TRIGGER_TYPES = [
  { value: 'time',             icon: '⏰', label: 'לפי שעה' },
  { value: 'device_state',     icon: '💡', label: 'מצב מכשיר' },
  { value: 'sensor_threshold', icon: '🌡️', label: 'ערך חיישן' },
  { value: 'device_online',    icon: '📶', label: 'מכשיר מחובר/מנותק' },
  { value: 'sunrise',          icon: '🌅', label: 'זריחה' },
  { value: 'sunset',           icon: '🌇', label: 'שקיעה' },
]

const ACTION_TYPES = [
  { value: 'device_cmd', icon: '💡', label: 'פקודה למכשיר' },
  { value: 'delay',      icon: '⏱️', label: 'המתן (שניות)' },
  { value: 'scene',      icon: '🎬', label: 'הפעל סצנה' },
]

const CRON_PRESETS = [
  { label: '🌙 כל יום 22:00',  value: '0 22 * * *' },
  { label: '☀️ כל יום 07:00',  value: '0 7 * * *' },
  { label: '🍽️ כל יום 13:00',  value: '0 13 * * *' },
  { label: '🛏️ כל יום 23:30',  value: '30 23 * * *' },
  { label: '📅 שישי 22:00',    value: '0 22 * * 5' },
  { label: '📅 שבת 10:00',     value: '0 10 * * 6' },
  { label: '🔁 כל שעה',        value: '0 * * * *' },
  { label: '✏️ מותאם אישית',   value: 'custom' },
]

const OPERATORS = [
  { value: 'gt',  label: 'גדול מ-' },
  { value: 'gte', label: 'גדול או שווה ל-' },
  { value: 'lt',  label: 'קטן מ-' },
  { value: 'lte', label: 'קטן או שווה ל-' },
  { value: 'eq',  label: 'שווה ל-' },
]

const SENSOR_PROPS = [
  { value: 'temperature', label: '🌡️ טמפרטורה (°C)' },
  { value: 'humidity',    label: '💧 לחות (%)' },
  { value: 'occupancy',   label: '👤 תנועה' },
  { value: 'contact',     label: '🚪 דלת/חלון' },
  { value: 'smoke',       label: '🔥 עשן' },
  { value: 'power_w',     label: '⚡ צריכת חשמל (W)' },
]

const EMPTY_FORM = {
  name:    '',
  enabled: true,
  trigger: { type: 'time', cron: '0 22 * * *', preset: '0 22 * * *' },
  condition: {},
  actions: [{ type: 'device_cmd', device_id: '', payload: { state: 'OFF' } }],
}

/* ── Summary line for a rule ───────────────────────────────────────── */
function ruleSummary(rule, devices) {
  const t = rule.trigger
  let trigger = ''
  if (t.type === 'time')             trigger = `⏰ ${t.cron}`
  else if (t.type === 'sunrise')     trigger = `🌅 זריחה${t.offset_min ? ` +${t.offset_min} דקות` : ''}`
  else if (t.type === 'sunset')      trigger = `🌇 שקיעה${t.offset_min ? ` +${t.offset_min} דקות` : ''}`
  else if (t.type === 'device_state') {
    const dev = devices.find(d => d.id === t.device_id)
    trigger = `💡 ${dev?.name || t.device_id} = ${t.state || 'כל שינוי'}`
  }
  else if (t.type === 'sensor_threshold') {
    const dev = devices.find(d => d.id === t.device_id)
    const op  = OPERATORS.find(o => o.value === t.operator)
    trigger = `🌡️ ${dev?.name || t.device_id} ${op?.label || ''}${t.value}`
  }
  else if (t.type === 'device_online') {
    const dev = devices.find(d => d.id === t.device_id)
    trigger = `📶 ${dev?.name || t.device_id} ${t.online ? 'מחובר' : 'מנותק'}`
  }

  const actions = rule.actions.map(a => {
    if (a.type === 'delay') return `⏱️ ${a.seconds}s`
    if (a.type === 'scene') return '🎬 סצנה'
    const dev = devices.find(d => d.id === a.device_id)
    const st  = a.payload?.state
    return `${dev?.name || a.device_id || '?'} → ${st || JSON.stringify(a.payload)}`
  }).join(' · ')

  return { trigger, actions }
}

/* ═══════════════════════════════════════════════════════════════════════
   Main Component
═══════════════════════════════════════════════════════════════════════ */
export default function AutomationsPage({ devices }) {
  const { t, rtl, locale } = useLang()
  const [rules, setRules]       = useState([])
  const [showForm, setShowForm] = useState(false)
  const [editId, setEditId]     = useState(null)
  const [form, setForm]         = useState(EMPTY_FORM)
  const [saving, setSaving]     = useState(false)
  const [err, setErr]           = useState('')

  const load = () => api.get('/rules/').then(r => setRules(r.data)).catch(() => {})
  useEffect(() => { load() }, [])

  const openNew = () => {
    setForm(EMPTY_FORM)
    setEditId(null)
    setErr('')
    setShowForm(true)
  }

  const openEdit = (rule) => {
    setForm({
      name:      rule.name,
      enabled:   rule.enabled,
      trigger:   { ...rule.trigger, preset: rule.trigger.cron || rule.trigger.type },
      condition: rule.condition || {},
      actions:   rule.actions.length ? rule.actions : EMPTY_FORM.actions,
    })
    setEditId(rule.id)
    setErr('')
    setShowForm(true)
  }

  const save = async () => {
    if (!form.name.trim()) { setErr(t.fill_rule_name); return }
    if (!form.actions.length) { setErr(t.add_min_one_action); return }
    setSaving(true); setErr('')
    try {
      const body = {
        name:      form.name.trim(),
        enabled:   form.enabled,
        trigger:   form.trigger,
        condition: form.condition,
        actions:   form.actions,
      }
      if (editId) await api.put(`/rules/${editId}`, body)
      else        await api.post('/rules/', body)
      setShowForm(false)
      load()
    } catch (e) {
      setErr(e?.response?.data?.detail || t.unknown_error)
    }
    setSaving(false)
  }

  const toggleRule = async (rule) => {
    try {
      await api.put(`/rules/${rule.id}`, { ...rule, enabled: !rule.enabled })
      load()
    } catch {}
  }

  const runNow = async (id) => {
    try { await api.post(`/rules/${id}/run`) } catch {}
    load()
  }

  const remove = async (id) => {
    if (!confirm(t.delete_rule + '?')) return
    try { await api.delete(`/rules/${id}`) } catch {}
    load()
  }

  /* ── Action helpers ── */
  const setAction = (idx, patch) =>
    setForm(f => ({ ...f, actions: f.actions.map((a, i) => i === idx ? { ...a, ...patch } : a) }))
  const addAction  = () =>
    setForm(f => ({ ...f, actions: [...f.actions, { type: 'device_cmd', device_id: '', payload: { state: 'OFF' } }] }))
  const removeAction = (idx) =>
    setForm(f => ({ ...f, actions: f.actions.filter((_, i) => i !== idx) }))

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>⚡ {t.rules_title}</h2>
          <div style={{ fontSize: 11, color: '#475569', marginTop: 2 }}>{rules.length} {t.rules_count}</div>
        </div>
        <button onClick={openNew} style={btn('#7c3aed')}>{t.add_rule}</button>
      </div>

      {/* Empty state */}
      {rules.length === 0 && (
        <div style={{ textAlign: 'center', padding: '60px 20px', color: '#475569' }}>
          <div style={{ fontSize: 56 }}>⚡</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: '#64748b', marginTop: 12 }}>{t.no_rules}</div>
          <div style={{ fontSize: 13, marginTop: 6, lineHeight: 1.6 }}>
            {t.no_rules_hint}
          </div>
          <button onClick={openNew} style={{ ...btn('#7c3aed'), margin: '20px auto 0', display: 'block', padding: '12px 28px' }}>
            {t.create_first_rule}
          </button>
        </div>
      )}

      {/* Rules list */}
      {rules.map(rule => {
        const { trigger, actions } = ruleSummary(rule, devices)
        return (
          <div key={rule.id} style={{
            background: '#1e293b', border: `1px solid ${rule.enabled ? '#334155' : '#1e293b'}`,
            borderRadius: 14, padding: '14px 16px', marginBottom: 10,
            opacity: rule.enabled ? 1 : 0.6,
          }}>
            {/* Top row */}
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
              {/* Enable toggle */}
              <div onClick={() => toggleRule(rule)} style={{
                width: 40, height: 22, borderRadius: 11, marginTop: 2, flexShrink: 0,
                background: rule.enabled ? '#7c3aed' : '#334155', cursor: 'pointer',
                position: 'relative', transition: 'background .2s',
              }}>
                <div style={{
                  position: 'absolute', top: 3,
                  left: rule.enabled ? 21 : 3, width: 16, height: 16,
                  borderRadius: '50%', background: '#fff', transition: 'left .2s',
                }} />
              </div>

              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#f1f5f9', marginBottom: 6 }}>
                  {rule.name}
                </div>
                {/* IF/THEN visual */}
                <div style={{
                  background: '#0f172a', borderRadius: 8, padding: '8px 12px',
                  fontSize: 12, lineHeight: 1.8,
                }}>
                  <span style={{ color: '#7c3aed', fontWeight: 700 }}>{t.rule_if}</span>
                  <span style={{ color: '#94a3b8' }}>{trigger}</span>
                  <br/>
                  <span style={{ color: '#22c55e', fontWeight: 700 }}>{t.rule_then}</span>
                  <span style={{ color: '#94a3b8' }}>{actions}</span>
                </div>
                {rule.last_run > 0 && (
                  <div style={{ fontSize: 10, color: '#334155', marginTop: 6 }}>
                    {t.last_fired}: {new Date(rule.last_run * 1000).toLocaleString(locale)}
                  </div>
                )}
              </div>

              {/* Action buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 5, flexShrink: 0 }}>
                <button onClick={() => runNow(rule.id)} title="הפעל עכשיו"
                  style={{ ...iconBtn('#1d4ed8') }}>▶</button>
                <button onClick={() => openEdit(rule)} title="ערוך"
                  style={{ ...iconBtn('#334155') }}>✏️</button>
                <button onClick={() => remove(rule.id)} title="מחק"
                  style={{ ...iconBtn('#7f1d1d') }}>🗑️</button>
              </div>
            </div>
          </div>
        )
      })}

      {/* ══ Create / Edit Modal ══ */}
      {showForm && (
        <div style={overlay}>
          <div style={{ ...modal, direction: rtl ? 'rtl' : 'ltr' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <h3 style={{ margin: 0, color: '#f1f5f9', fontSize: 17 }}>
                {editId ? t.edit_rule_title : t.new_rule}
              </h3>
              <button onClick={() => setShowForm(false)}
                style={{ background: 'none', border: 'none', color: '#64748b', fontSize: 22, cursor: 'pointer' }}>✕</button>
            </div>

            {/* Name */}
            <label style={lbl}>{t.rule_name}</label>
            <input value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder="לדוגמה: כבה אורות בלילה"
              style={inp} autoFocus />

            {/* ── TRIGGER ── */}
            <div style={section}>
              <div style={sectionTitle}>🔵 {t.trigger}</div>

              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 12 }}>
                {TRIGGER_TYPES.map(t => (
                  <button key={t.value}
                    onClick={() => setForm(f => ({ ...f, trigger: { type: t.value, cron: '0 22 * * *', preset: '0 22 * * *' } }))}
                    style={{
                      padding: '6px 12px', borderRadius: 8, border: 'none', cursor: 'pointer',
                      fontSize: 12, fontWeight: 600,
                      background: form.trigger.type === t.value ? '#7c3aed' : '#0f172a',
                      color: form.trigger.type === t.value ? '#fff' : '#64748b',
                    }}>
                    {t.icon} {t.label}
                  </button>
                ))}
              </div>

              {/* Time trigger */}
              {form.trigger.type === 'time' && (
                <>
                  <label style={lbl}>בחר שעה</label>
                  <select value={form.trigger.preset || form.trigger.cron}
                    onChange={e => {
                      const v = e.target.value
                      if (v === 'custom') setForm(f => ({ ...f, trigger: { ...f.trigger, preset: 'custom' } }))
                      else setForm(f => ({ ...f, trigger: { ...f.trigger, cron: v, preset: v } }))
                    }} style={inp}>
                    {CRON_PRESETS.map(p => <option key={p.value} value={p.value}>{p.label}</option>)}
                  </select>
                  {form.trigger.preset === 'custom' && (
                    <input value={form.trigger.cron}
                      onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, cron: e.target.value } }))}
                      placeholder="0 22 * * * (cron expression)"
                      style={{ ...inp, direction: 'ltr' }} />
                  )}
                </>
              )}

              {/* Sunrise/Sunset offset */}
              {(form.trigger.type === 'sunrise' || form.trigger.type === 'sunset') && (
                <>
                  <label style={lbl}>הסטה בדקות (אופציונלי)</label>
                  <input type="number" value={form.trigger.offset_min || 0}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, offset_min: parseInt(e.target.value) || 0 } }))}
                    placeholder="0" style={{ ...inp, direction: 'ltr' }} />
                </>
              )}

              {/* Device state trigger */}
              {form.trigger.type === 'device_state' && (
                <>
                  <label style={lbl}>מכשיר</label>
                  <select value={form.trigger.device_id || ''}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, device_id: e.target.value } }))}
                    style={inp}>
                    <option value="">-- בחר מכשיר --</option>
                    {devices.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                  </select>
                  <label style={lbl}>מצב</label>
                  <select value={form.trigger.state || 'ON'}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, state: e.target.value } }))}
                    style={inp}>
                    <option value="ON">הופעל (ON)</option>
                    <option value="OFF">כובה (OFF)</option>
                    <option value="">כל שינוי</option>
                  </select>
                </>
              )}

              {/* Sensor threshold trigger */}
              {form.trigger.type === 'sensor_threshold' && (
                <>
                  <label style={lbl}>חיישן</label>
                  <select value={form.trigger.device_id || ''}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, device_id: e.target.value } }))}
                    style={inp}>
                    <option value="">-- בחר חיישן --</option>
                    {devices.filter(d => d.type === 'sensor' || d.state?.temperature !== undefined || d.state?.humidity !== undefined)
                      .map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                  </select>
                  <label style={lbl}>מאפיין</label>
                  <select value={form.trigger.property || 'temperature'}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, property: e.target.value } }))}
                    style={inp}>
                    {SENSOR_PROPS.map(p => <option key={p.value} value={p.value}>{p.label}</option>)}
                  </select>
                  <label style={lbl}>תנאי</label>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <select value={form.trigger.operator || 'gt'}
                      onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, operator: e.target.value } }))}
                      style={{ ...inp, flex: 1, marginBottom: 0 }}>
                      {OPERATORS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                    </select>
                    <input type="number" value={form.trigger.value || 0}
                      onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, value: parseFloat(e.target.value) } }))}
                      style={{ ...inp, width: 80, marginBottom: 0, direction: 'ltr' }} />
                  </div>
                  <div style={{ height: 10 }} />
                </>
              )}

              {/* Device online trigger */}
              {form.trigger.type === 'device_online' && (
                <>
                  <label style={lbl}>מכשיר</label>
                  <select value={form.trigger.device_id || ''}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, device_id: e.target.value } }))}
                    style={inp}>
                    <option value="">-- בחר מכשיר --</option>
                    {devices.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                  </select>
                  <label style={lbl}>אירוע</label>
                  <select value={form.trigger.online !== false ? 'true' : 'false'}
                    onChange={e => setForm(f => ({ ...f, trigger: { ...f.trigger, online: e.target.value === 'true' } }))}
                    style={inp}>
                    <option value="true">✅ התחבר לרשת</option>
                    <option value="false">❌ התנתק מהרשת</option>
                  </select>
                </>
              )}
            </div>

            {/* ── ACTIONS ── */}
            <div style={section}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                <div style={sectionTitle}>🟢 {t.actions_label}</div>
                <button onClick={addAction} style={{ ...btn('#22c55e'), padding: '4px 12px', fontSize: 12 }}>
                  {t.add_action}
                </button>
              </div>

              {form.actions.map((action, idx) => (
                <div key={idx} style={{
                  background: '#0f172a', borderRadius: 10, padding: '12px',
                  marginBottom: 8, border: '1px solid #1e293b',
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                    <div style={{ fontSize: 12, color: '#64748b', fontWeight: 600 }}>פעולה {idx + 1}</div>
                    {form.actions.length > 1 && (
                      <button onClick={() => removeAction(idx)}
                        style={{ background: 'none', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: 16 }}>✕</button>
                    )}
                  </div>

                  <label style={lbl}>סוג פעולה</label>
                  <select value={action.type}
                    onChange={e => setAction(idx, { type: e.target.value, device_id: '', payload: { state: 'OFF' }, seconds: 5 })}
                    style={inp}>
                    {ACTION_TYPES.map(t => <option key={t.value} value={t.value}>{t.icon} {t.label}</option>)}
                  </select>

                  {action.type === 'device_cmd' && (
                    <>
                      <label style={lbl}>מכשיר</label>
                      <select value={action.device_id}
                        onChange={e => setAction(idx, { device_id: e.target.value })}
                        style={inp}>
                        <option value="">-- בחר מכשיר --</option>
                        {devices.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                      </select>
                      <label style={lbl}>פקודה</label>
                      <select value={action.payload?.state || 'OFF'}
                        onChange={e => setAction(idx, { payload: { state: e.target.value } })}
                        style={inp}>
                        <option value="ON">💡 הדלק (ON)</option>
                        <option value="OFF">🌙 כבה (OFF)</option>
                        <option value="TOGGLE">🔄 החלף מצב</option>
                      </select>
                    </>
                  )}

                  {action.type === 'delay' && (
                    <>
                      <label style={lbl}>המתן (שניות)</label>
                      <input type="number" min={1} max={3600}
                        value={action.seconds || 5}
                        onChange={e => setAction(idx, { seconds: parseInt(e.target.value) || 5 })}
                        style={{ ...inp, direction: 'ltr' }} />
                    </>
                  )}
                </div>
              ))}
            </div>

            {/* Enabled toggle */}
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', marginBottom: 16 }}>
              <div onClick={() => setForm(f => ({ ...f, enabled: !f.enabled }))} style={{
                width: 44, height: 24, borderRadius: 12,
                background: form.enabled ? '#22c55e' : '#334155', cursor: 'pointer',
                position: 'relative', transition: 'background .2s',
              }}>
                <div style={{
                  position: 'absolute', top: 3,
                  left: form.enabled ? 23 : 3, width: 18, height: 18,
                  borderRadius: '50%', background: '#fff', transition: 'left .2s',
                }} />
              </div>
              <span style={{ fontSize: 13, color: form.enabled ? '#22c55e' : '#64748b' }}>
                {form.enabled ? t.rule_enabled : t.rule_disabled}
              </span>
            </label>

            {err && (
              <div style={{ background: '#7f1d1d', border: '1px solid #ef4444', borderRadius: 8, padding: '8px 12px', fontSize: 13, color: '#fca5a5', marginBottom: 12 }}>
                {err}
              </div>
            )}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={save} disabled={saving}
                style={{ ...btn('#7c3aed'), flex: 1, opacity: saving ? 0.7 : 1 }}>
                {saving ? `⏳ ${t.saving}` : editId ? t.edit_rule : t.save_rule}
              </button>
              <button onClick={() => setShowForm(false)} style={btn('#334155')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const btn = (bg, color = '#fff') => ({
  padding: '9px 18px', borderRadius: 9, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 700, fontSize: 13,
})
const iconBtn = (bg) => ({
  width: 32, height: 32, borderRadius: 8, border: 'none',
  background: bg, color: '#fff', cursor: 'pointer', fontSize: 13,
  display: 'flex', alignItems: 'center', justifyContent: 'center',
})
const section = {
  background: '#0f172a', border: '1px solid #1e293b',
  borderRadius: 12, padding: '14px', marginBottom: 14,
}
const sectionTitle = {
  fontSize: 13, fontWeight: 700, color: '#94a3b8', marginBottom: 10,
}
const inp = {
  width: '100%', padding: '9px 12px', marginBottom: 10, borderRadius: 8,
  border: '1px solid #334155', background: '#1e293b', color: '#f1f5f9',
  fontSize: 14, boxSizing: 'border-box', direction: 'rtl',
}
const lbl = { display: 'block', fontSize: 12, color: '#64748b', marginBottom: 4 }
const overlay = { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: 16 }
const modal = { background: '#1e293b', border: '1px solid #334155', borderRadius: 18, padding: 24, width: '100%', maxWidth: 420, maxHeight: '90vh', overflowY: 'auto' }
