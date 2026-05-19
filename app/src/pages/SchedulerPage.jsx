/**
 * SchedulerPage — visual weekly scheduler.
 *
 * Wraps the existing /rules/ API (trigger.type = 'time') with a friendly
 * time + days-of-week picker instead of raw cron expressions.
 *
 * Cron encoding:
 *   "every day at 22:00"              → "0 22 * * *"
 *   "Mon + Wed at 08:30"              → "30 8 * * 1,3"
 *   days[] uses 0=Sun … 6=Sat (JS Date.getDay convention)
 */
import { useState, useEffect, useCallback } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'
import { useScale } from '../context/ScaleContext'

/* ── Analyse history → schedule suggestions ──────────────────────────── */
async function analyseHistory(devices) {
  try {
    const { data } = await api.get('/history/?limit=200')
    // bucket: key = "device_id|action|hour" → count
    const buckets = {}
    for (const h of data) {
      if (h.action !== 'toggle' || !h.device_id) continue
      const ts   = new Date(h.ts * 1000)
      const hour = ts.getHours()
      const key  = `${h.device_id}|${h.value}|${hour}`
      buckets[key] = (buckets[key] || 0) + 1
    }
    // Keep only patterns seen ≥ 3 times
    return Object.entries(buckets)
      .filter(([, cnt]) => cnt >= 3)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([key, cnt]) => {
        const [deviceId, action, hour] = key.split('|')
        const device = devices.find(d => d.id === deviceId)
        return { deviceId, action, hour: parseInt(hour), minute: 0, cnt, device }
      })
      .filter(s => s.device)
  } catch { return [] }
}

const DAY_LABELS_EN = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const DAY_LABELS_HE = ['א׳',  'ב׳',  'ג׳',  'ד׳',  'ה׳',  'ו׳',  'ש׳']

const TYPE_ICONS = {
  light: '💡', switch: '🔌', dimmer: '🔆', color: '🎨',
  sensor: '🌡️', camera: '📷', lock: '🔒', ac: '❄️',
  fan: '🌀', motion: '👤', door: '🚪', smoke: '🔥',
}

/* ── cron ↔ {hour, minute, days} ──────────────────────────────────────── */
function toCron(hour, minute, days) {
  const d = days.length === 7 || days.length === 0 ? '*' : days.sort((a, b) => a - b).join(',')
  return `${minute} ${hour} * * ${d}`
}

function parseCron(cron = '') {
  const parts = cron.trim().split(/\s+/)
  if (parts.length < 5) return null
  const [min, hr, , , dayPart] = parts
  const hour   = parseInt(hr,  10)
  const minute = parseInt(min, 10)
  if (isNaN(hour) || isNaN(minute)) return null
  const days = dayPart === '*' ? [0,1,2,3,4,5,6]
             : dayPart.split(',').map(Number).filter(n => !isNaN(n))
  return { hour, minute, days }
}

function friendlyTime(hour, minute) {
  return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`
}

function friendlyDays(days, labels) {
  if (days.length === 7) return labels[0] === 'א׳' ? 'כל יום' : 'Every day'
  if (days.length === 0) return '—'
  return days.sort((a,b)=>a-b).map(d => labels[d]).join(', ')
}

const EMPTY = {
  name: '', deviceId: '', action: 'OFF', hour: 22, minute: 0,
  days: [0,1,2,3,4,5,6], enabled: true,
}

/* ── Weekly timeline strip ───────────────────────────────────────────── */
function WeekStrip({ schedules, rtl }) {
  const today = new Date().getDay()
  return (
    <div style={{
      display: 'flex', gap: 6, marginBottom: 20,
      direction: rtl ? 'rtl' : 'ltr',
    }}>
      {DAY_LABELS_EN.map((_, dayIdx) => {
        const isToday  = dayIdx === today
        const dayScheds = schedules.filter(s => s._days?.includes(dayIdx))
        return (
          <div key={dayIdx} style={{
            flex: 1, borderRadius: 12,
            background: isToday ? 'rgba(56,189,248,0.12)' : '#1e293b',
            border: `1px solid ${isToday ? '#38bdf8' : '#334155'}`,
            padding: '8px 4px', textAlign: 'center', minWidth: 0,
          }}>
            <div style={{ fontSize: 9, fontWeight: 700, color: isToday ? '#38bdf8' : '#64748b', marginBottom: 4 }}>
              {DAY_LABELS_EN[dayIdx]}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 2, alignItems: 'center' }}>
              {dayScheds.slice(0, 3).map((s, i) => (
                <div key={i} style={{
                  width: 6, height: 6, borderRadius: '50%',
                  background: s.enabled ? s._color : '#334155',
                }} />
              ))}
              {dayScheds.length === 0 && (
                <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#1e3a5f' }} />
              )}
              {dayScheds.length > 3 && (
                <div style={{ fontSize: 8, color: '#475569' }}>+{dayScheds.length - 3}</div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

const CARD_COLORS = ['#38bdf8','#a78bfa','#22c55e','#fb923c','#f43f5e','#fbbf24','#34d399']

/* ─────────────────────────────────────────────────────────────────────── */
export default function SchedulerPage({ devices }) {
  const { t, rtl, lang } = useLang()
  const { phone } = useScale()
  const isHe = lang === 'he'
  const dayLabels = isHe ? DAY_LABELS_HE : DAY_LABELS_EN

  const [schedules,    setSchedules]    = useState([])
  const [suggestions,  setSuggestions]  = useState([])
  const [loadingSugg,  setLoadingSugg]  = useState(false)
  const [suggDone,     setSuggDone]     = useState(false)
  const [showForm, setShowForm]   = useState(false)
  const [editId,   setEditId]     = useState(null)
  const [form, setForm]           = useState(EMPTY)
  const [saving, setSaving]       = useState(false)
  const [err, setErr]             = useState('')
  const dir = rtl ? 'rtl' : 'ltr'

  const load = async () => {
    try {
      const { data } = await api.get('/rules/')
      const timeBased = data
        .filter(r => r.trigger?.type === 'time')
        .map((r, i) => {
          const parsed = parseCron(r.trigger?.cron)
          return {
            ...r,
            _time:  parsed ? friendlyTime(parsed.hour, parsed.minute) : r.trigger?.cron,
            _days:  parsed?.days ?? [],
            _hour:  parsed?.hour ?? 0,
            _min:   parsed?.minute ?? 0,
            _color: CARD_COLORS[i % CARD_COLORS.length],
          }
        })
        .sort((a, b) => a._hour * 60 + a._min - (b._hour * 60 + b._min))
      setSchedules(timeBased)
    } catch {}
  }

  useEffect(() => { load() }, [])

  const loadSuggestions = useCallback(async () => {
    setLoadingSugg(true)
    const sugg = await analyseHistory(devices)
    setSuggestions(sugg)
    setSuggDone(true)
    setLoadingSugg(false)
  }, [devices])

  const applySuggestion = (s) => {
    setForm({
      name:     `${s.action === 'ON' ? (isHe ? 'הדלק' : 'Turn on') : (isHe ? 'כבה' : 'Turn off')} ${s.device.name}`,
      deviceId: s.deviceId,
      action:   s.action,
      hour:     s.hour,
      minute:   0,
      days:     [0,1,2,3,4,5,6],
      enabled:  true,
    })
    setEditId(null)
    setErr('')
    setShowForm(true)
  }

  const openNew = () => {
    setForm(EMPTY)
    setEditId(null)
    setErr('')
    setShowForm(true)
  }

  const openEdit = (s) => {
    setForm({
      name:     s.name,
      deviceId: s.actions[0]?.device_id || '',
      action:   s.actions[0]?.payload?.state || 'OFF',
      hour:     s._hour,
      minute:   s._min,
      days:     s._days,
      enabled:  s.enabled,
    })
    setEditId(s.id)
    setErr('')
    setShowForm(true)
  }

  const save = async () => {
    if (!form.name.trim())   { setErr(t.fill_rule_name   ?? 'Enter a name');   return }
    if (!form.deviceId)      { setErr(t.auto_select_device ?? 'Select a device'); return }
    setSaving(true); setErr('')
    try {
      const body = {
        name:    form.name.trim(),
        enabled: form.enabled,
        trigger: { type: 'time', cron: toCron(form.hour, form.minute, form.days) },
        condition: {},
        actions: [{ type: 'device_cmd', device_id: form.deviceId, payload: { state: form.action } }],
      }
      if (editId) await api.put(`/rules/${editId}`, body)
      else        await api.post('/rules/', body)
      setShowForm(false)
      load()
    } catch (e) {
      setErr(e?.response?.data?.detail || (t.unknown_error ?? 'Error'))
    }
    setSaving(false)
  }

  const toggle = async (s) => {
    try { await api.put(`/rules/${s.id}`, { ...s, enabled: !s.enabled }); load() } catch {}
  }

  const remove = async (id) => {
    if (!confirm((t.delete_rule ?? 'Delete') + '?')) return
    try { await api.delete(`/rules/${id}`); load() } catch {}
  }

  const runNow = async (id) => {
    try { await api.post(`/rules/${id}/run`) } catch {}
  }

  const toggleDay = (d) => setForm(f => ({
    ...f,
    days: f.days.includes(d) ? f.days.filter(x => x !== d) : [...f.days, d],
  }))

  return (
    <div style={{ direction: dir }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>
            🗓️ {t.scheduler_title ?? 'Scheduler'}
          </h2>
          <div style={{ fontSize: 11, color: '#475569', marginTop: 2 }}>
            {schedules.length} {t.scheduler_scheduled ?? 'scheduled tasks'}
          </div>
        </div>
        <button onClick={openNew} style={{
          padding: '9px 16px', borderRadius: 10, border: 'none',
          background: 'linear-gradient(90deg,#7c3aed,#6366f1)',
          color: '#fff', cursor: 'pointer', fontWeight: 700, fontSize: 13,
        }}>
          + {t.scheduler_add ?? 'Add'}
        </button>
      </div>

      {/* ── Smart suggestions ─────────────────────────────────────────── */}
      <div style={{
        background: 'linear-gradient(135deg,#1a1f3a,#1e293b)',
        border: '1px solid #334155', borderRadius: 14,
        padding: '12px 14px', marginBottom: 16,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: suggDone && suggestions.length > 0 ? 12 : 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#a78bfa' }}>
            🤖 {t.sched_suggest_title ?? 'Smart Suggestions'}
          </div>
          <button onClick={loadSuggestions} disabled={loadingSugg} style={{
            padding: '5px 12px', borderRadius: 8, border: 'none',
            background: loadingSugg ? '#334155' : 'rgba(167,139,250,0.2)',
            color: loadingSugg ? '#64748b' : '#a78bfa',
            fontSize: 11, fontWeight: 700, cursor: loadingSugg ? 'default' : 'pointer',
          }}>
            {loadingSugg ? '⏳ …' : (suggDone ? '🔄' : (t.sched_analyse ?? 'Analyse History'))}
          </button>
        </div>

        {suggDone && suggestions.length === 0 && (
          <div style={{ fontSize: 12, color: '#475569', marginTop: 8 }}>
            {t.sched_no_patterns ?? 'No patterns detected yet — use your devices for a few days first.'}
          </div>
        )}

        {suggestions.map((s, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: '#0f172a', borderRadius: 10, padding: '10px 12px',
            marginBottom: i < suggestions.length - 1 ? 8 : 0,
          }}>
            <span style={{ fontSize: 20 }}>{s.action === 'ON' ? '💡' : '🌙'}</span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0' }}>
                {s.device.name}
              </div>
              <div style={{ fontSize: 11, color: '#64748b' }}>
                {s.action === 'ON' ? (t.cmd_on_lbl ?? 'ON') : (t.cmd_off_lbl ?? 'OFF')}
                {' · '}{String(s.hour).padStart(2,'0')}:00
                {' · '}{s.cnt}× {t.sched_times ?? 'times'}
              </div>
            </div>
            <button onClick={() => applySuggestion(s)} style={{
              padding: '6px 12px', borderRadius: 8, border: 'none',
              background: 'rgba(167,139,250,0.2)', color: '#a78bfa',
              fontSize: 11, fontWeight: 700, cursor: 'pointer', flexShrink: 0,
            }}>
              + {t.sched_add ?? 'Add'}
            </button>
          </div>
        ))}
      </div>

      {/* Weekly strip */}
      <WeekStrip schedules={schedules} rtl={rtl} />

      {/* Empty state */}
      {schedules.length === 0 && (
        <div style={{ textAlign: 'center', padding: '50px 20px', color: '#475569' }}>
          <div style={{ fontSize: 52 }}>🗓️</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#64748b', marginTop: 12 }}>
            {t.scheduler_empty ?? 'No schedules yet'}
          </div>
          <div style={{ fontSize: 12, marginTop: 6, lineHeight: 1.7, maxWidth: 260, margin: '8px auto 0' }}>
            {t.scheduler_empty_hint ?? 'Add a schedule to automatically turn devices on or off at a specific time.'}
          </div>
          <button onClick={openNew} style={{
            marginTop: 20, padding: '12px 28px', borderRadius: 12, border: 'none',
            background: 'linear-gradient(90deg,#7c3aed,#6366f1)',
            color: '#fff', cursor: 'pointer', fontWeight: 700, fontSize: 14,
          }}>
            + {t.scheduler_add ?? 'Add Schedule'}
          </button>
        </div>
      )}

      {/* Schedule cards — sorted by time */}
      {schedules.map(s => {
        const dev    = devices.find(d => d.id === s.actions[0]?.device_id)
        const action = s.actions[0]?.payload?.state || '—'
        const actionColor = action === 'ON' ? '#22c55e' : action === 'OFF' ? '#ef4444' : '#f59e0b'

        return (
          <div key={s.id} style={{
            background: '#1e293b',
            border: `1px solid ${s.enabled ? '#334155' : '#1e3a5f'}`,
            borderRadius: 16, padding: '14px 16px', marginBottom: 10,
            opacity: s.enabled ? 1 : 0.55,
            position: 'relative', overflow: 'hidden',
          }}>
            {/* Color accent */}
            <div style={{
              position: 'absolute', top: 0, [rtl ? 'right' : 'left']: 0,
              width: 4, height: '100%', background: s._color, borderRadius: '4px 0 0 4px',
            }} />

            <div style={{ [rtl ? 'marginRight' : 'marginLeft']: 12 }}>
              {/* Time + name row */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
                  <span style={{ fontSize: 26, fontWeight: 900, color: '#f1f5f9', fontVariantNumeric: 'tabular-nums' }}>
                    {s._time}
                  </span>
                  <span style={{ fontSize: 12, color: '#64748b', fontWeight: 600 }}>
                    {friendlyDays(s._days, dayLabels)}
                  </span>
                </div>
                {/* Toggle + actions */}
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <div onClick={() => toggle(s)} style={{
                    width: 38, height: 20, borderRadius: 10, flexShrink: 0,
                    background: s.enabled ? '#7c3aed' : '#334155',
                    cursor: 'pointer', position: 'relative', transition: 'background .2s',
                  }}>
                    <div style={{
                      position: 'absolute', top: 2,
                      left: s.enabled ? 20 : 2, width: 16, height: 16,
                      borderRadius: '50%', background: '#fff', transition: 'left .2s',
                    }} />
                  </div>
                  <button onClick={() => runNow(s.id)} title={t.auto_run_title ?? 'Run now'}
                    style={iconBtnStyle('#1d4ed8')}>▶</button>
                  <button onClick={() => openEdit(s)}
                    style={iconBtnStyle('#334155')}>✏️</button>
                  <button onClick={() => remove(s.id)}
                    style={iconBtnStyle('#7f1d1d')}>🗑️</button>
                </div>
              </div>

              {/* Device + action pill */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontSize: 18 }}>{TYPE_ICONS[dev?.type] ?? '💡'}</span>
                <span style={{ fontSize: 13, color: '#cbd5e1', fontWeight: 600 }}>
                  {dev?.name ?? s.name}
                </span>
                <span style={{
                  marginLeft: 'auto', padding: '2px 10px', borderRadius: 20,
                  fontSize: 11, fontWeight: 700, color: actionColor,
                  background: `${actionColor}20`, border: `1px solid ${actionColor}50`,
                }}>
                  {action === 'ON' ? (t.cmd_on_lbl ?? 'ON') : action === 'OFF' ? (t.cmd_off_lbl ?? 'OFF') : action}
                </span>
              </div>
            </div>
          </div>
        )
      })}

      {/* ── Add / Edit Modal ─────────────────────────────────────────────── */}
      {showForm && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.85)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 100 }}>
          <div style={{
            background: '#1e293b', border: '1px solid #334155',
            borderRadius: '20px 20px 0 0', padding: '24px 20px',
            width: '100%', maxWidth: 480,
            maxHeight: '92vh', overflowY: 'auto',
            direction: dir,
          }}>
            {/* Handle bar */}
            <div style={{ width: 40, height: 4, background: '#334155', borderRadius: 2, margin: '0 auto 20px' }} />

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <h3 style={{ margin: 0, color: '#f1f5f9', fontSize: 17 }}>
                {editId ? (t.scheduler_edit ?? 'Edit Schedule') : (t.scheduler_new ?? 'New Schedule')}
              </h3>
              <button onClick={() => setShowForm(false)}
                style={{ background: 'none', border: 'none', color: '#64748b', fontSize: 22, cursor: 'pointer' }}>✕</button>
            </div>

            {/* Name */}
            <label style={lbl}>{t.rule_name ?? 'Name'}</label>
            <input value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder={t.scheduler_name_placeholder ?? 'e.g. Turn off lights at night'}
              style={{ ...inp, direction: dir }} autoFocus />

            {/* Time picker */}
            <label style={lbl}>{t.scheduler_time ?? 'Time'}</label>
            <div style={{ display: 'flex', gap: 10, marginBottom: 14, alignItems: 'center' }}>
              {/* Hour */}
              <div style={{ flex: 1, position: 'relative' }}>
                <div style={{ textAlign: 'center', fontSize: 9, color: '#64748b', marginBottom: 4 }}>
                  {t.hour ?? 'Hour'}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: '#0f172a', borderRadius: 12, padding: '10px 12px', border: '1px solid #334155' }}>
                  <button onClick={() => setForm(f => ({ ...f, hour: (f.hour - 1 + 24) % 24 }))}
                    style={arrowBtn}>‹</button>
                  <span style={{ flex: 1, textAlign: 'center', fontSize: 28, fontWeight: 900, color: '#38bdf8', fontVariantNumeric: 'tabular-nums' }}>
                    {String(form.hour).padStart(2, '0')}
                  </span>
                  <button onClick={() => setForm(f => ({ ...f, hour: (f.hour + 1) % 24 }))}
                    style={arrowBtn}>›</button>
                </div>
              </div>

              <span style={{ fontSize: 28, fontWeight: 900, color: '#38bdf8', flexShrink: 0, marginTop: 16 }}>:</span>

              {/* Minute */}
              <div style={{ flex: 1 }}>
                <div style={{ textAlign: 'center', fontSize: 9, color: '#64748b', marginBottom: 4 }}>
                  {t.minute ?? 'Min'}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: '#0f172a', borderRadius: 12, padding: '10px 12px', border: '1px solid #334155' }}>
                  <button onClick={() => setForm(f => ({ ...f, minute: (f.minute - 5 + 60) % 60 }))}
                    style={arrowBtn}>‹</button>
                  <span style={{ flex: 1, textAlign: 'center', fontSize: 28, fontWeight: 900, color: '#38bdf8', fontVariantNumeric: 'tabular-nums' }}>
                    {String(form.minute).padStart(2, '0')}
                  </span>
                  <button onClick={() => setForm(f => ({ ...f, minute: (f.minute + 5) % 60 }))}
                    style={arrowBtn}>›</button>
                </div>
              </div>
            </div>

            {/* Day picker */}
            <label style={lbl}>{t.scheduler_days ?? 'Days'}</label>
            <div style={{ display: 'flex', gap: 6, marginBottom: 14, flexWrap: 'wrap' }}>
              {/* "Every day" shortcut */}
              <button
                onClick={() => setForm(f => ({ ...f, days: f.days.length === 7 ? [] : [0,1,2,3,4,5,6] }))}
                style={{
                  padding: '6px 12px', borderRadius: 20, border: 'none', cursor: 'pointer',
                  fontSize: 11, fontWeight: 700,
                  background: form.days.length === 7 ? '#7c3aed' : '#0f172a',
                  color: form.days.length === 7 ? '#fff' : '#64748b',
                }}>
                {isHe ? 'כל יום' : 'Every day'}
              </button>
              {DAY_LABELS_EN.map((_, d) => (
                <button key={d} onClick={() => toggleDay(d)} style={{
                  width: 36, height: 36, borderRadius: '50%', border: 'none', cursor: 'pointer',
                  fontSize: 11, fontWeight: 700,
                  background: form.days.includes(d) ? '#7c3aed' : '#0f172a',
                  color: form.days.includes(d) ? '#fff' : '#64748b',
                }}>
                  {dayLabels[d]}
                </button>
              ))}
            </div>

            {/* Device */}
            <label style={lbl}>{t.auto_device_label ?? 'Device'}</label>
            <select value={form.deviceId} onChange={e => setForm(f => ({ ...f, deviceId: e.target.value }))}
              style={{ ...inp, direction: dir }}>
              <option value="">{t.auto_select_device ?? 'Select a device'}</option>
              {devices.filter(d => ['light','switch','dimmer','color','ac','fan','lock'].includes(d.type) || !d.type)
                .map(d => (
                  <option key={d.id} value={d.id}>
                    {TYPE_ICONS[d.type] ?? '💡'} {d.name}
                  </option>
                ))}
            </select>

            {/* Action */}
            <label style={lbl}>{t.auto_command_label ?? 'Action'}</label>
            <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
              {[
                { v: 'ON',     label: t.cmd_on_lbl     ?? 'Turn ON',  color: '#22c55e' },
                { v: 'OFF',    label: t.cmd_off_lbl    ?? 'Turn OFF', color: '#ef4444' },
                { v: 'TOGGLE', label: t.cmd_toggle_lbl ?? 'Toggle',   color: '#f59e0b' },
              ].map(opt => (
                <button key={opt.v} onClick={() => setForm(f => ({ ...f, action: opt.v }))}
                  style={{
                    flex: 1, padding: '10px 4px', border: 'none', borderRadius: 10, cursor: 'pointer',
                    fontSize: 12, fontWeight: 700,
                    background: form.action === opt.v ? `${opt.color}20` : '#0f172a',
                    color: form.action === opt.v ? opt.color : '#64748b',
                    outline: form.action === opt.v ? `2px solid ${opt.color}` : '2px solid transparent',
                    transition: 'all 0.15s',
                  }}>
                  {opt.label}
                </button>
              ))}
            </div>

            {/* Enabled */}
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', marginBottom: 18 }}>
              <div onClick={() => setForm(f => ({ ...f, enabled: !f.enabled }))} style={{
                width: 44, height: 24, borderRadius: 12,
                background: form.enabled ? '#22c55e' : '#334155',
                cursor: 'pointer', position: 'relative', transition: 'background .2s',
              }}>
                <div style={{
                  position: 'absolute', top: 3,
                  left: form.enabled ? 23 : 3, width: 18, height: 18,
                  borderRadius: '50%', background: '#fff', transition: 'left .2s',
                }} />
              </div>
              <span style={{ fontSize: 13, color: form.enabled ? '#22c55e' : '#64748b' }}>
                {form.enabled ? (t.rule_enabled ?? 'Active') : (t.rule_disabled ?? 'Disabled')}
              </span>
            </label>

            {err && (
              <div style={{ background: '#7f1d1d', border: '1px solid #ef4444', borderRadius: 8, padding: '8px 12px', fontSize: 13, color: '#fca5a5', marginBottom: 12 }}>
                {err}
              </div>
            )}

            {/* Preview */}
            <div style={{
              background: '#0f172a', borderRadius: 10, padding: '10px 14px',
              fontSize: 12, color: '#64748b', marginBottom: 16, lineHeight: 1.8,
            }}>
              <span style={{ color: '#7c3aed', fontWeight: 700 }}>⏰ </span>
              {friendlyTime(form.hour, form.minute)} · {friendlyDays(form.days, dayLabels)}
              {form.deviceId && devices.find(d => d.id === form.deviceId) && (
                <>
                  {' → '}
                  <span style={{ color: form.action === 'ON' ? '#22c55e' : form.action === 'OFF' ? '#ef4444' : '#f59e0b', fontWeight: 700 }}>
                    {form.action}
                  </span>
                  {' · '}
                  {devices.find(d => d.id === form.deviceId)?.name}
                </>
              )}
            </div>

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={save} disabled={saving} style={{
                flex: 1, padding: '13px 0', borderRadius: 12, border: 'none',
                background: saving ? '#334155' : 'linear-gradient(90deg,#7c3aed,#6366f1)',
                color: '#fff', cursor: saving ? 'default' : 'pointer', fontWeight: 700, fontSize: 15,
              }}>
                {saving ? `⏳ ${t.saving ?? 'Saving…'}` : (editId ? (t.scheduler_save_edit ?? 'Save Changes') : (t.scheduler_save ?? 'Add Schedule'))}
              </button>
              <button onClick={() => setShowForm(false)} style={{
                padding: '13px 18px', borderRadius: 12, border: 'none',
                background: '#334155', color: '#94a3b8', cursor: 'pointer', fontWeight: 700,
              }}>
                {t.cancel ?? 'Cancel'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const lbl = { display: 'block', fontSize: 12, color: '#64748b', marginBottom: 5 }
const inp = {
  width: '100%', padding: '10px 12px', marginBottom: 14,
  borderRadius: 10, border: '1px solid #334155',
  background: '#0f172a', color: '#f1f5f9', fontSize: 14, boxSizing: 'border-box',
}
const arrowBtn = {
  background: 'none', border: 'none', color: '#64748b',
  fontSize: 22, cursor: 'pointer', padding: '0 2px', lineHeight: 1,
}
const iconBtnStyle = (bg) => ({
  width: 30, height: 30, borderRadius: 8, border: 'none',
  background: bg, color: '#fff', cursor: 'pointer', fontSize: 12,
  display: 'flex', alignItems: 'center', justifyContent: 'center',
})
