import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

/* ── helpers ── */
const PLAN_OPTIONS = ['free', 'basic', 'standard', 'premium', 'unlimited']

function Avatar({ user }) {
  const typeIconMap = {
    admin: '👑', owner: '🏠', family: '👨‍👩‍👧', child: '🧒',
    guest: '🙋', caregiver: '🩺', technician: '🔧',
  }
  return (
    <span style={{ fontSize: 22, minWidth: 28, textAlign: 'center' }}>
      {typeIconMap[user.type] ?? '👤'}
    </span>
  )
}

function StatusPill({ status }) {
  const active  = status !== 'deleted' && status !== 'inactive'
  return (
    <span style={{
      fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 20,
      background: active ? 'rgba(34,197,94,0.12)' : 'rgba(100,116,139,0.12)',
      color: active ? '#22c55e' : '#64748b', border: `1px solid ${active ? '#22c55e44' : '#33415544'}`,
    }}>
      {status ?? 'active'}
    </span>
  )
}

/* ── Add / Edit modal ── */
function UserModal({ user, types, onClose, onSaved }) {
  const { t } = useLang()
  const isEdit = !!user?.id

  const [form, setForm] = useState({
    type:     user?.type     ?? (types[0]?.type ?? 'owner'),
    name:     user?.name     ?? '',
    username: user?.username ?? '',
    email:    user?.email    ?? '',
    address:  user?.address  ?? '',
    plan:     user?.plan     ?? 'free',
    pin:      '',
    notes:    user?.notes    ?? '',
  })
  const [saving, setSaving]   = useState(false)
  const [error,  setError]    = useState('')

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const handleSave = async () => {
    if (!form.name.trim())     { setError(t.users_name_required  ?? 'Name is required');     return }
    if (!isEdit && !form.username.trim()) { setError(t.users_username_required ?? 'Username is required'); return }
    setSaving(true); setError('')
    try {
      if (isEdit) {
        const payload = { type: form.type, name: form.name, email: form.email,
                          address: form.address, plan: form.plan, notes: form.notes }
        if (form.pin) payload.pin = form.pin
        await api.put(`/users/${user.id}`, payload)
      } else {
        await api.post('/users/add', { ...form, username: form.username.trim() })
      }
      onSaved()
      onClose()
    } catch (e) {
      setError(e?.response?.data?.detail ?? t.unknown_error ?? 'Error')
    } finally {
      setSaving(false)
    }
  }

  const field = (label, key, opts = {}) => (
    <label style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <span style={{ fontSize: 11, color: '#94a3b8', fontWeight: 600 }}>{label}</span>
      <input
        value={form[key]}
        onChange={e => set(key, e.target.value)}
        disabled={opts.disabled}
        placeholder={opts.placeholder ?? ''}
        type={opts.type ?? 'text'}
        style={{
          background: '#0f172a', border: '1px solid #334155', borderRadius: 8,
          padding: '8px 10px', color: '#e2e8f0', fontSize: 13,
          outline: 'none', width: '100%', boxSizing: 'border-box',
          opacity: opts.disabled ? 0.5 : 1,
        }}
      />
    </label>
  )

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 300, padding: 16,
    }} onClick={e => e.target === e.currentTarget && onClose()}>
      <div style={{
        background: '#1e293b', border: '1px solid #334155', borderRadius: 16,
        padding: 20, width: '100%', maxWidth: 460,
        display: 'flex', flexDirection: 'column', gap: 14,
        maxHeight: '90vh', overflowY: 'auto',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h3 style={{ margin: 0, color: '#e2e8f0', fontSize: 16 }}>
            {isEdit ? (t.users_edit ?? '✏️ Edit User') : (t.users_add ?? '➕ Add User')}
          </h3>
          <button onClick={onClose} style={ghostBtn}>✕</button>
        </div>

        {/* Type selector */}
        <label style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <span style={{ fontSize: 11, color: '#94a3b8', fontWeight: 600 }}>{t.users_type ?? 'User Type'}</span>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))', gap: 6 }}>
            {types.map(tp => (
              <button key={tp.type} onClick={() => set('type', tp.type)} style={{
                padding: '7px 4px', borderRadius: 8, cursor: 'pointer', fontSize: 12,
                border: `1px solid ${form.type === tp.type ? tp.color ?? '#38bdf8' : '#334155'}`,
                background: form.type === tp.type ? `${tp.color ?? '#38bdf8'}22` : 'transparent',
                color: form.type === tp.type ? (tp.color ?? '#38bdf8') : '#64748b',
                fontWeight: form.type === tp.type ? 700 : 400,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
              }}>
                <span>{tp.icon}</span>
                <span>{tp.label_en ?? tp.type}</span>
              </button>
            ))}
          </div>
        </label>

        {field(t.users_name ?? 'Full Name', 'name', { placeholder: 'John Doe' })}
        {field(t.users_username ?? 'Username', 'username', { disabled: isEdit, placeholder: 'john123' })}
        {field(t.users_email ?? 'Email', 'email', { type: 'email', placeholder: 'john@example.com' })}
        {field(t.users_address ?? 'Address', 'address', { placeholder: t.optional ?? 'Optional' })}

        {/* Plan selector */}
        <label style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <span style={{ fontSize: 11, color: '#94a3b8', fontWeight: 600 }}>{t.users_plan ?? 'Plan'}</span>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {PLAN_OPTIONS.map(p => (
              <button key={p} onClick={() => set('plan', p)} style={{
                padding: '5px 12px', borderRadius: 20, cursor: 'pointer', fontSize: 11,
                border: `1px solid ${form.plan === p ? '#38bdf8' : '#334155'}`,
                background: form.plan === p ? 'rgba(56,189,248,0.15)' : 'transparent',
                color: form.plan === p ? '#38bdf8' : '#64748b',
                fontWeight: form.plan === p ? 700 : 400,
              }}>{p}</button>
            ))}
          </div>
        </label>

        {field(t.users_pin ?? 'PIN (4–6 digits)', 'pin', { type: 'password', placeholder: isEdit ? t.users_pin_leave ?? 'Leave blank to keep' : '••••' })}
        {field(t.users_notes ?? 'Notes', 'notes', { placeholder: t.optional ?? 'Optional' })}

        {error && (
          <div style={{ background: '#450a0a', border: '1px solid #ef4444', borderRadius: 8, padding: '8px 12px', fontSize: 12, color: '#fca5a5' }}>
            {error}
          </div>
        )}

        <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
          <button onClick={onClose} style={{ ...ghostBtn, flex: 1, padding: '10px 0', borderRadius: 10, fontSize: 13 }}>
            {t.cancel ?? 'Cancel'}
          </button>
          <button onClick={handleSave} disabled={saving} style={{
            flex: 2, padding: '10px 0', borderRadius: 10, border: 'none',
            background: saving ? '#334155' : '#2563eb', color: '#fff',
            cursor: saving ? 'default' : 'pointer', fontWeight: 700, fontSize: 13,
          }}>
            {saving ? '…' : (isEdit ? (t.save_changes ?? 'Save') : (t.users_add_btn ?? 'Add User'))}
          </button>
        </div>
      </div>
    </div>
  )
}

/* ── Main page ── */
export default function UsersPage() {
  const { t } = useLang()
  const [users,    setUsers]    = useState([])
  const [types,    setTypes]    = useState([])
  const [loading,  setLoading]  = useState(true)
  const [search,   setSearch]   = useState('')
  const [filterType, setFilterType] = useState('all')
  const [modal,    setModal]    = useState(null)   // null | 'add' | {user obj}
  const [confirm,  setConfirm]  = useState(null)   // user to delete

  const load = async () => {
    setLoading(true)
    try {
      const [uRes, tRes] = await Promise.all([
        api.get('/users/list'),
        api.get('/users/types'),
      ])
      setUsers(uRes.data.users ?? [])
      setTypes(tRes.data.types ?? [])
    } catch {}
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  const handleDelete = async (user) => {
    try {
      await api.delete(`/users/${user.id}`)
      setConfirm(null)
      load()
    } catch {}
  }

  const typeMap = types.reduce((m, tp) => { m[tp.type] = tp; return m }, {})

  const filtered = users.filter(u => {
    const q = search.toLowerCase()
    const matchSearch = !q ||
      u.name?.toLowerCase().includes(q) ||
      u.username?.toLowerCase().includes(q) ||
      u.email?.toLowerCase().includes(q)
    const matchType = filterType === 'all' || u.type === filterType
    return matchSearch && matchType
  })

  const activeCount   = users.filter(u => u.status !== 'deleted').length
  const typeBreakdown = types.map(tp => ({
    ...tp,
    count: users.filter(u => u.type === tp.type && u.status !== 'deleted').length,
  }))

  return (
    <div>
      {/* Page header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>
            👥 {t.users_title ?? 'Users'}
          </h2>
          <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>
            {activeCount} {t.users_active ?? 'active users'}
          </div>
        </div>
        <button onClick={() => setModal('add')} style={{
          background: '#2563eb', color: '#fff', border: 'none', borderRadius: 10,
          padding: '9px 16px', cursor: 'pointer', fontWeight: 700, fontSize: 13,
        }}>
          ➕ {t.users_add_btn ?? 'Add User'}
        </button>
      </div>

      {/* Type stats strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(100px, 1fr))', gap: 8, marginBottom: 16 }}>
        {typeBreakdown.map(tp => (
          <div
            key={tp.type}
            onClick={() => setFilterType(prev => prev === tp.type ? 'all' : tp.type)}
            style={{
              background: filterType === tp.type ? `${tp.color ?? '#38bdf8'}22` : '#1e293b',
              border: `1px solid ${filterType === tp.type ? (tp.color ?? '#38bdf8') : '#334155'}`,
              borderRadius: 10, padding: '8px 10px', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            }}
          >
            <span style={{ fontSize: 18 }}>{tp.icon}</span>
            <span style={{ fontSize: 10, color: '#94a3b8', fontWeight: 600 }}>{tp.label_en ?? tp.type}</span>
            <span style={{ fontSize: 16, fontWeight: 800, color: tp.color ?? '#38bdf8', lineHeight: 1 }}>
              {tp.count}
            </span>
          </div>
        ))}
      </div>

      {/* Search bar */}
      <input
        value={search}
        onChange={e => setSearch(e.target.value)}
        placeholder={t.search ?? '🔍 Search...'}
        style={{
          width: '100%', boxSizing: 'border-box',
          background: '#0f172a', border: '1px solid #334155', borderRadius: 10,
          padding: '9px 14px', color: '#e2e8f0', fontSize: 13, marginBottom: 14,
          outline: 'none',
        }}
      />

      {/* User list */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: '#475569' }}>⏳</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: '#475569' }}>
          {t.no_results ?? 'No users found'}
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {filtered.map(user => {
            const tp = typeMap[user.type]
            return (
              <div key={user.id} style={{
                background: '#1e293b', border: '1px solid #334155', borderRadius: 12,
                padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
              }}>
                <Avatar user={user} />

                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                    <span style={{ fontSize: 14, fontWeight: 700, color: '#e2e8f0' }}>{user.name}</span>
                    <span style={{ fontSize: 11, color: tp?.color ?? '#94a3b8', fontWeight: 600 }}>
                      {tp?.label_en ?? user.type}
                    </span>
                    <StatusPill status={user.status} />
                  </div>
                  <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>
                    @{user.username}
                    {user.email ? ` · ${user.email}` : ''}
                    {user.plan  ? ` · ${user.plan}`  : ''}
                  </div>
                  {user.notes ? (
                    <div style={{ fontSize: 10, color: '#475569', marginTop: 2, fontStyle: 'italic' }}>
                      {user.notes}
                    </div>
                  ) : null}
                </div>

                <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                  <button onClick={() => setModal(user)} style={{ ...ghostBtn, fontSize: 14, padding: '5px 8px' }} title={t.edit ?? 'Edit'}>✏️</button>
                  <button onClick={() => setConfirm(user)} style={{ ...ghostBtn, fontSize: 14, padding: '5px 8px', color: '#ef4444', borderColor: '#ef444444' }} title={t.delete ?? 'Delete'}>🗑️</button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Export buttons */}
      <div style={{ display: 'flex', gap: 8, marginTop: 20 }}>
        <a href={`${import.meta.env.VITE_HUB_URL ?? localStorage.getItem('fantatech_hub_url') ?? ''}/api/users/export-csv`}
          download="fantatech-users.csv"
          style={{ ...exportBtn, color: '#22c55e', borderColor: '#22c55e44' }}>
          ⬇️ CSV
        </a>
        <a href={`${import.meta.env.VITE_HUB_URL ?? localStorage.getItem('fantatech_hub_url') ?? ''}/api/users/export`}
          download="fantatech-users.xlsx"
          style={{ ...exportBtn, color: '#38bdf8', borderColor: '#38bdf844' }}>
          📊 Excel
        </a>
      </div>

      {/* Add / Edit modal */}
      {(modal === 'add' || (modal && typeof modal === 'object')) && (
        <UserModal
          user={modal === 'add' ? null : modal}
          types={types}
          onClose={() => setModal(null)}
          onSaved={load}
        />
      )}

      {/* Delete confirmation */}
      {confirm && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 300, padding: 20,
        }} onClick={e => e.target === e.currentTarget && setConfirm(null)}>
          <div style={{
            background: '#1e293b', border: '1px solid #ef4444', borderRadius: 16,
            padding: 20, maxWidth: 340, width: '100%',
          }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#e2e8f0', marginBottom: 8 }}>
              🗑️ {t.users_delete_title ?? 'Remove User?'}
            </div>
            <div style={{ fontSize: 13, color: '#94a3b8', marginBottom: 16 }}>
              {(t.users_delete_confirm ?? 'This will deactivate {name}.')
                .replace('{name}', confirm.name)}
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => setConfirm(null)} style={{ ...ghostBtn, flex: 1, padding: '9px 0', borderRadius: 10, fontSize: 13 }}>
                {t.cancel ?? 'Cancel'}
              </button>
              <button onClick={() => handleDelete(confirm)} style={{
                flex: 1, padding: '9px 0', borderRadius: 10, border: 'none',
                background: '#ef4444', color: '#fff', cursor: 'pointer', fontWeight: 700, fontSize: 13,
              }}>
                {t.delete ?? 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const ghostBtn = {
  background: 'transparent', border: '1px solid #334155',
  borderRadius: 8, cursor: 'pointer', color: '#64748b',
  padding: '4px 10px', fontSize: 13,
  WebkitTapHighlightColor: 'transparent',
}

const exportBtn = {
  display: 'inline-flex', alignItems: 'center', gap: 6,
  padding: '7px 14px', borderRadius: 8,
  border: '1px solid', background: 'transparent',
  fontSize: 12, fontWeight: 600, textDecoration: 'none',
  cursor: 'pointer',
}
