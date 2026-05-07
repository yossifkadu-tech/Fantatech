import { useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import DeviceCard from '../components/DeviceCard'
import AcCard from '../components/AcCard'
import QrScanner from '../components/QrScanner'
import { useLang } from '../context/LangContext'

const TYPES = [
  { value: 'switch', label: 'מתג/שקע', icon: '🔌' },
  { value: 'light',  label: 'נורה',    icon: '💡' },
  { value: 'dimmer', label: 'דימר',    icon: '🔆' },
  { value: 'color',  label: 'RGB',     icon: '🎨' },
  { value: 'ac',     label: 'מזגן',    icon: '❄️' },
  { value: 'sensor', label: 'חיישן',   icon: '🌡️' },
  { value: 'camera', label: 'מצלמה',   icon: '📷' },
  { value: 'lock',   label: 'מנעול',   icon: '🔒' },
  { value: 'fan',    label: 'מאוורר',  icon: '🌀' },
]
const PROTOCOLS = ['wifi', 'zigbee', 'zwave', 'matter', 'custom']
const EMPTY_FORM = { id: '', name: '', protocol: 'wifi', type: 'switch',
                     topic_state: '', topic_cmd: '', room: '', label: '', config: {} }

export default function DevicesPage({ devices, onReload }) {
  const { t }                        = useLang()
  const [rooms, setRooms]           = useState([])
  const [filter, setFilter]         = useState('all')
  const [search, setSearch]         = useState('')
  const [addMode, setAddMode]       = useState(null) // null | 'menu' | 'manual' | 'qr' | 'network' | 'ac' | 'moes'
  const [showAdd, setShowAdd]       = useState(false)
  const [addForm, setAddForm]       = useState(EMPTY_FORM)
  const [renameTarget, setRenameTarget] = useState(null)   // full device object
  const [renameName, setRenameName] = useState('')
  const [renameLabel, setRenameLabel] = useState('')
  const [saving, setSaving]         = useState(false)
  const [error, setError]           = useState('')

  useEffect(() => {
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
  }, [])

  const roomMap = rooms.reduce((m, r) => { m[r.id] = r; return m }, {})

  /* ── QR result handler ──────────────────────────────────────────────────── */
  const handleQrResult = (parsed) => {
    if (parsed._type === 'wifi') {
      // WiFi QR → show in network page (just alert for now)
      alert(`רשת WiFi נמצאה:\nSSID: ${parsed.ssid}\nסיסמה: ${parsed.password || '(פתוחה)'}`)
      setAddMode(null)
      return
    }
    if (parsed._type === 'device' || parsed._type === 'unknown') {
      const ip = parsed.ip || ''
      const id = ip.replace(/\./g, '_') || `device_${Date.now()}`
      setAddForm(f => ({
        ...EMPTY_FORM,
        id,
        name:  parsed.name || parsed.raw || ip,
        label: parsed.type || '',
        protocol: 'wifi',
        type:  parsed.dev_type || 'switch',
        topic_state: `devices/${id}/state`,
        topic_cmd:   `devices/${id}/cmd`,
      }))
      setAddMode('manual')
      setShowAdd(true)
    }
  }

  /* ── Import JSON file ──────────────────────────────────────────────────── */
  const handleImportFile = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ''
    const reader = new FileReader()
    reader.onload = async (ev) => {
      try {
        const importedDevices = JSON.parse(ev.target.result)
        if (!Array.isArray(importedDevices)) throw new Error('הקובץ אינו מערך JSON')
        let ok = 0, fail = 0
        for (const d of importedDevices) {
          try { await api.post('/devices/', d); ok++ } catch { fail++ }
        }
        alert(`יובאו ${ok} מכשירים${fail ? `, ${fail} נכשלו` : ''} ✅`)
        setAddMode(null)
        onReload()
      } catch (err) {
        alert(`שגיאה: ${err.message}`)
      }
    }
    reader.readAsText(file)
  }

  /* ── Add device ─────────────────────────────────────────────────────────── */
  const addDevice = async () => {
    if (!addForm.id || !addForm.name) { setError('מלא ID ושם'); return }
    const data = {
      ...addForm,
      topic_state: addForm.topic_state || `devices/${addForm.id}/state`,
      topic_cmd:   addForm.topic_cmd   || `devices/${addForm.id}/cmd`,
    }
    try {
      await api.post('/devices/', data)
      setShowAdd(false)
      setAddMode(null)
      setAddForm(EMPTY_FORM)
      setError('')
      onReload()
    } catch (e) { setError(e?.response?.data?.detail || 'שגיאה') }
  }

  /* ── Delete device ──────────────────────────────────────────────────────── */
  const deleteDevice = async (device) => {
    if (!confirm(`למחוק את "${device.name}"?`)) return
    try {
      await api.delete(`/devices/${device.id}`)
      onReload()
    } catch {}
  }

  /* ── Pin device ─────────────────────────────────────────────────────────── */
  const togglePin = async (device) => {
    await api.post(`/devices/${device.id}/pin`, { pinned: !device.pinned })
    onReload()
  }

  /* ── Open rename ────────────────────────────────────────────────────────── */
  const openRename = (device) => {
    setRenameTarget(device)
    setRenameName(device.name)
    setRenameLabel(device.label || '')
    setError('')
  }

  /* ── Save rename ────────────────────────────────────────────────────────── */
  const saveRename = async () => {
    if (!renameName.trim()) { setError('שם לא יכול להיות ריק'); return }
    setSaving(true)
    try {
      await api.put(`/devices/${renameTarget.id}/rename`, {
        name:  renameName.trim(),
        label: renameLabel.trim(),
      })
      setRenameTarget(null)
      setError('')
      onReload()
    } catch (e) {
      setError(e?.response?.data?.detail || 'שגיאה בשמירה')
    }
    setSaving(false)
  }

  /* ── Filter & sort ──────────────────────────────────────────────────────── */
  const q = search.trim().toLowerCase()
  const filtered = devices.filter(d => {
    if (q && !d.name.toLowerCase().includes(q) && !(d.label || '').toLowerCase().includes(q)) return false
    if (filter === 'all') return true
    return d.room === filter
  })
  const sorted = [...filtered].sort((a, b) => {
    if (b.pinned !== a.pinned) return (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0)
    if (b.online !== a.online) return (b.online ? 1 : 0) - (a.online ? 1 : 0)
    return a.name.localeCompare(b.name)
  })

  const pinned = sorted.filter(d => d.pinned)
  const rest   = sorted.filter(d => !d.pinned)
  const connected = devices.filter(d => d.online).length

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>מכשירים</h2>
          <div style={{ fontSize: 12, color: connected > 0 ? '#22c55e' : '#475569', marginTop: 2 }}>
            ● {connected} מחוברים מתוך {devices.length}
          </div>
        </div>
        <button onClick={() => setAddMode('menu')} style={btn('#38bdf8', '#0f172a')}>
          + הוסף
        </button>
      </div>

      {/* Search */}
      <input value={search} onChange={e => setSearch(e.target.value)}
        placeholder="🔍 חיפוש לפי שם או ספק..."
        style={{ ...inp, marginBottom: 10 }} />

      {/* Room filter */}
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 18, paddingBottom: 4 }}>
        {[{ value: 'all', label: 'הכל' }, ...rooms.map(r => ({ value: r.id, label: `${r.icon} ${r.name}` }))].map(f => (
          <button key={f.value} onClick={() => setFilter(f.value)} style={{
            padding: '6px 14px', borderRadius: 20, border: 'none', whiteSpace: 'nowrap', cursor: 'pointer',
            background: filter === f.value ? '#38bdf8' : '#1e293b',
            color:      filter === f.value ? '#0f172a' : '#94a3b8',
            fontWeight: filter === f.value ? 700 : 400, fontSize: 13,
          }}>{f.label}</button>
        ))}
      </div>

      {/* Empty */}
      {sorted.length === 0 && (
        <div style={{ textAlign: 'center', padding: 60, color: '#475569' }}>
          <div style={{ fontSize: 48 }}>💡</div>
          <p style={{ marginTop: 12 }}>{devices.length === 0 ? 'אין מכשירים — לחץ הוסף' : 'לא נמצאו תוצאות'}</p>
        </div>
      )}

      {/* Pinned section */}
      {pinned.length > 0 && (
        <GroupSection title="📌 מוצמדים" items={pinned} roomMap={roomMap}
          onPin={togglePin} onRename={openRename} onDelete={deleteDevice} onReload={onReload} />
      )}

      {/* Rest */}
      {rest.length > 0 && (
        <GroupSection title={pinned.length > 0 ? 'שאר המכשירים' : null} items={rest} roomMap={roomMap}
          onPin={togglePin} onRename={openRename} onDelete={deleteDevice} onReload={onReload} />
      )}

      {/* ── Add Method Menu ─────────────────────────────────────────────────── */}
      {addMode === 'menu' && (
        <div style={overlay}>
          <div style={{ ...modal, padding: 20 }}>
            <h3 style={{ margin: '0 0 16px', color: '#e2e8f0', textAlign: 'center' }}>➕ הוסף מכשיר</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {[
                { icon: '❄️', title: 'הוסף מזגן', sub: 'Sensibo / MQTT / Tuya', action: () => setAddMode('ac') },
                { icon: '📡', title: 'Moes Gateway', sub: 'Zigbee / BLE / Tuya', action: () => setAddMode('moes') },
                { icon: '📷', title: 'סרוק QR', sub: 'קוד QR של מכשיר', action: () => setAddMode('qr') },
                { icon: '🔍', title: 'סרוק רשת', sub: 'חיפוש ברשת המקומית', action: () => setAddMode('network') },
                { icon: '✏️', title: 'ידנית', sub: 'הגדר מכשיר חדש', action: () => { setAddMode('manual'); setShowAdd(true); setAddForm(EMPTY_FORM); setError('') } },
                { icon: '📥', title: 'יבא JSON', sub: 'טען קובץ גיבוי', action: () => { document.getElementById('dev-import-input').click() } },
              ].map(item => (
                <button key={item.title} onClick={item.action} style={{
                  background: '#1e3a5f', border: '1px solid #3b82f6', borderRadius: 12,
                  padding: '16px 8px', cursor: 'pointer', textAlign: 'center',
                  display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
                }}>
                  <span style={{ fontSize: 28 }}>{item.icon}</span>
                  <span style={{ color: '#e2e8f0', fontWeight: 700, fontSize: 13 }}>{item.title}</span>
                  <span style={{ color: '#64748b', fontSize: 11 }}>{item.sub}</span>
                </button>
              ))}
            </div>
            <button onClick={() => setAddMode(null)} style={{ ...btn('#334155'), width: '100%', marginTop: 12 }}>ביטול</button>
            <input id="dev-import-input" type="file" accept=".json" style={{ display: 'none' }} onChange={handleImportFile} />
          </div>
        </div>
      )}

      {/* ── QR Scanner modal ────────────────────────────────────────────────── */}
      {addMode === 'qr' && (
        <div style={overlay}>
          <div style={modal}>
            <h3 style={{ marginTop: 0, marginBottom: 4 }}>📷 סריקת QR</h3>
            <p style={{ fontSize: 12, color: '#64748b', marginBottom: 12 }}>סרוק קוד QR של מכשיר חכם, כתובת IP, או רשת WiFi</p>
            <QrScanner onResult={handleQrResult} onClose={() => setAddMode(null)} />
          </div>
        </div>
      )}

      {/* ── Network Scan modal ──────────────────────────────────────────────── */}
      {addMode === 'network' && (
        <NetworkScanModal
          rooms={rooms}
          onAddDevice={async (dev) => {
            await api.post('/devices/', dev)
            onReload()   // reload in background — modal stays open for more adds
          }}
          onClose={() => setAddMode(null)}
        />
      )}

      {/* ── AC Add modal ────────────────────────────────────────────────────── */}
      {addMode === 'ac' && (
        <AcAddModal
          rooms={rooms}
          onClose={() => setAddMode(null)}
          onAdded={() => { setAddMode(null); onReload() }}
        />
      )}

      {/* ── Moes / Tuya Gateway modal ────────────────────────────────────────── */}
      {addMode === 'moes' && (
        <MoesGatewayModal
          rooms={rooms}
          onClose={() => setAddMode(null)}
          onAdded={() => { setAddMode(null); onReload() }}
        />
      )}

      {/* ── Add manual modal ────────────────────────────────────────────────── */}
      {showAdd && addMode === 'manual' && (
        <div style={overlay}>
          <div style={modal}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
              <h3 style={{ margin: 0 }}>מכשיר חדש ✏️</h3>
              <button onClick={() => { setAddMode('menu'); setShowAdd(false) }} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 13 }}>← חזור</button>
            </div>

            <label style={lbl}>ID ייחודי</label>
            <input value={addForm.id}
              onChange={e => setAddForm({ ...addForm, id: e.target.value.toLowerCase().replace(/\s/g, '_') })}
              placeholder="living_room_light" style={inp} autoFocus />

            <label style={lbl}>שם</label>
            <input value={addForm.name}
              onChange={e => setAddForm({ ...addForm, name: e.target.value })}
              placeholder="נורה סלון" style={inp} />

            <label style={lbl}>ספק / תווית (אופציונלי)</label>
            <input value={addForm.label}
              onChange={e => setAddForm({ ...addForm, label: e.target.value })}
              placeholder="Tasmota, Sonoff..." style={inp} />

            <label style={lbl}>פרוטוקול</label>
            <select value={addForm.protocol} onChange={e => setAddForm({ ...addForm, protocol: e.target.value })} style={inp}>
              {PROTOCOLS.map(p => <option key={p} value={p}>{p}</option>)}
            </select>

            <label style={lbl}>סוג</label>
            <select value={addForm.type} onChange={e => setAddForm({ ...addForm, type: e.target.value })} style={inp}>
              {TYPES.map(typ => <option key={typ.value} value={typ.value}>{typ.icon} {typ.label}</option>)}
            </select>

            <label style={lbl}>חדר</label>
            <select value={addForm.room} onChange={e => setAddForm({ ...addForm, room: e.target.value })} style={inp}>
              <option value="">ללא חדר</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {error && <div style={errBox}>{error}</div>}

            <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
              <button onClick={addDevice} style={{ ...btn('#22c55e'), flex: 1 }}>שמור</button>
              <button onClick={() => { setShowAdd(false); setAddMode(null); setError('') }} style={btn('#475569')}>ביטול</button>
            </div>
          </div>
        </div>
      )}

      {/* ── Rename modal ────────────────────────────────────────────────────── */}
      {renameTarget && (
        <div style={overlay}>
          <div style={modal}>
            <h3 style={{ marginTop: 0, marginBottom: 6 }}>עריכת מכשיר</h3>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 16 }}>
              {renameTarget.id}
            </div>

            <label style={lbl}>שם מכשיר</label>
            <input
              value={renameName}
              onChange={e => setRenameName(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && saveRename()}
              style={inp}
              autoFocus
            />

            <label style={lbl}>ספק / אלמנט</label>
            <input
              value={renameLabel}
              onChange={e => setRenameLabel(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && saveRename()}
              placeholder="Tasmota, Sonoff, Philips Hue..."
              style={inp}
            />

            {error && <div style={errBox}>{error}</div>}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={saveRename} disabled={saving}
                style={{ ...btn('#22c55e'), flex: 1, opacity: saving ? 0.7 : 1 }}>
                {saving ? 'שומר...' : '💾 שמור שינויים'}
              </button>
              <button onClick={() => { setRenameTarget(null); setError('') }}
                style={btn('#475569')}>ביטול</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/* ── Device item: card + action bar below ─────────────────────────────────── */
function DeviceItem({ device, roomMap, onPin, onRename, onDelete, onReload }) {
  const room = device.room ? roomMap[device.room] : null

  return (
    <div style={{ marginBottom: 10 }}>
      {/* Card — use AcCard for AC type */}
      <div style={{ position: 'relative' }}>
        {device.type === 'ac'
          ? <AcCard device={device} onUpdate={onReload} roomName={room ? `${room.icon} ${room.name}` : undefined} />
          : <DeviceCard device={device} onUpdate={onReload} roomName={room ? `${room.icon} ${room.name}` : undefined} />
        }
        {/* Room badge */}
        {room && (
          <div style={{
            position: 'absolute', bottom: 8, right: 8,
            background: 'rgba(15,23,42,0.85)', border: '1px solid #1e3a5f',
            borderRadius: 6, padding: '2px 7px', fontSize: 10, color: '#38bdf8',
            pointerEvents: 'none',
          }}>
            {room.icon} {room.name}
          </div>
        )}
      </div>

      {/* Action bar — full width, clearly visible below card */}
      <div style={{
        display: 'flex', gap: 1, borderRadius: '0 0 12px 12px',
        overflow: 'hidden', marginTop: -1,
      }}>
        <ActionBtn
          onClick={() => onPin(device)}
          bg={device.pinned ? '#1d4ed8' : '#1e293b'}
          border={device.pinned ? '#3b82f6' : '#334155'}
          title={device.pinned ? 'בטל הצמדה' : 'הצמד'}>
          {device.pinned ? '📌 מוצמד' : '📌 הצמד'}
        </ActionBtn>
        <ActionBtn
          onClick={() => onRename(device)}
          bg="#1e293b" border="#334155"
          title="שנה שם">
          ✏️ ערוך
        </ActionBtn>
        <ActionBtn
          onClick={() => onDelete(device)}
          bg="#1e293b" border="#334155"
          color="#ef4444"
          title="מחק מכשיר">
          🗑️ מחק
        </ActionBtn>
      </div>
    </div>
  )
}

function ActionBtn({ onClick, bg, border, color = '#94a3b8', title, children }) {
  return (
    <button onClick={onClick} title={title} style={{
      flex: 1, padding: '7px 4px', border: `1px solid ${border}`,
      background: bg, color, cursor: 'pointer',
      fontSize: 11, fontWeight: 600, textAlign: 'center',
    }}>
      {children}
    </button>
  )
}

function GroupSection({ title, items, roomMap, onPin, onRename, onDelete, onReload }) {
  const acItems    = items.filter(d => d.type === 'ac')
  const otherItems = items.filter(d => d.type !== 'ac')
  return (
    <div style={{ marginBottom: 24 }}>
      {title && <div style={{ fontSize: 12, color: '#64748b', marginBottom: 10, fontWeight: 600 }}>{title}</div>}
      {/* AC devices — full width, one per row */}
      {acItems.map(d => (
        <DeviceItem key={d.id} device={d} roomMap={roomMap}
          onPin={onPin} onRename={onRename} onDelete={onDelete} onReload={onReload} />
      ))}
      {/* Regular devices — 2-column grid */}
      {otherItems.length > 0 && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {otherItems.map(d => (
            <DeviceItem key={d.id} device={d} roomMap={roomMap}
              onPin={onPin} onRename={onRename} onDelete={onDelete} onReload={onReload} />
          ))}
        </div>
      )}
    </div>
  )
}

/* ── AC Add Modal ──────────────────────────────────────────────────────────── */
const AC_BRANDS = [
  { id: 'tadiran',    name: 'תדיראן (Tadiran)'         },
  { id: 'electra',   name: 'אלקטרה (Electra)'          },
  { id: 'general',   name: 'גנרל (General / Fujitsu)'  },
  { id: 'mitsubishi',name: 'מיצובישי (Mitsubishi)'     },
  { id: 'daikin',    name: 'דייקין (Daikin)'           },
  { id: 'lg',        name: 'LG'                        },
  { id: 'samsung',   name: 'Samsung'                   },
  { id: 'gree',      name: 'Gree / AUX'               },
  { id: 'haier',     name: 'Haier'                     },
  { id: 'carrier',   name: 'Carrier'                   },
  { id: 'toshiba',   name: 'Toshiba'                   },
  { id: 'panasonic', name: 'Panasonic'                 },
  { id: 'sharp',     name: 'Sharp'                     },
  { id: 'other',     name: 'אחר'                      },
]

function AcAddModal({ rooms, onClose, onAdded }) {
  const [tab, setTab]               = useState('sensibo')
  const [name, setName]             = useState('')
  const [brand, setBrand]           = useState('tadiran')
  const [room, setRoom]             = useState('')
  const [saving, setSaving]         = useState(false)
  const [err, setErr]               = useState('')
  const [topicCmd, setTopicCmd]     = useState('')
  const [topicState, setTopicState] = useState('')

  // Sensibo state
  const [sensiboOk, setSensiboOk]       = useState(null)  // null=loading, true, false
  const [pods, setPods]                 = useState(null)  // null=not fetched yet
  const [loadingPods, setLoadingPods]   = useState(false)
  const [podsErr, setPodsErr]           = useState('')
  const [podBrands, setPodBrands]       = useState({})    // uid → brand
  const [podRooms, setPodRooms]         = useState({})    // uid → room id
  const [selected, setSelected]         = useState({})    // uid → bool
  const [importing, setImporting]       = useState(false)
  const [importResult, setImportResult] = useState(null)
  const [importedUids, setImportedUids] = useState({})   // uid → bool

  useEffect(() => {
    api.get('/ac/sensibo/status')
      .then(r => setSensiboOk(r.data.configured))
      .catch(() => setSensiboOk(false))
  }, [])

  const fetchPods = async () => {
    setLoadingPods(true); setPodsErr(''); setPods(null); setImportResult(null)
    try {
      const r = await api.get('/ac/sensibo/devices')
      setPods(r.data)
      const sel = {}, brands = {}, rms = {}
      r.data.forEach(d => { sel[d.uid] = true; brands[d.uid] = 'other'; rms[d.uid] = '' })
      setSelected(sel); setPodBrands(brands); setPodRooms(rms)
    } catch (e) {
      setPodsErr(e?.response?.data?.detail || 'שגיאה בטעינת מכשירים מ-Sensibo')
    }
    setLoadingPods(false)
  }

  const importSelected = async () => {
    const toImport = (pods || []).filter(p => selected[p.uid] && !importedUids[p.uid])
    if (!toImport.length) { setPodsErr('בחר לפחות מכשיר אחד'); return }
    setImporting(true); setImportResult(null); setPodsErr('')
    let ok = 0, fail = 0
    for (const pod of toImport) {
      try {
        await api.post('/ac/add', {
          name:        pod.name,
          brand:       podBrands[pod.uid] || 'other',
          protocol:    'sensibo',
          room:        podRooms[pod.uid]  || '',
          sensibo_uid: pod.uid,
        })
        setImportedUids(prev => ({ ...prev, [pod.uid]: true }))
        ok++
      } catch { fail++ }
    }
    setImportResult({ ok: ok > 0, text: `✅ יובאו ${ok} מזגנים${fail ? ` | ${fail} נכשלו` : ''}` })
    setImporting(false)
    if (ok > 0) setTimeout(onAdded, 1500)
  }

  const saveMqtt = async () => {
    if (!name.trim()) { setErr('הכנס שם למזגן'); return }
    setSaving(true)
    try {
      await api.post('/ac/add', {
        name: name.trim(), brand, protocol: 'mqtt', room,
        topic_cmd:   topicCmd   || `devices/ac_${brand}/cmd`,
        topic_state: topicState || `devices/ac_${brand}/state`,
      })
      onAdded()
    } catch (e) { setErr(e?.response?.data?.detail || 'שגיאה') }
    setSaving(false)
  }

  const saveManual = async () => {
    if (!name.trim()) { setErr('הכנס שם למזגן'); return }
    setSaving(true)
    try {
      await api.post('/ac/add', { name: name.trim(), brand, protocol: 'custom', room })
      onAdded()
    } catch (e) { setErr(e?.response?.data?.detail || 'שגיאה') }
    setSaving(false)
  }

  const selectedCount = Object.values(selected).filter(Boolean).length - Object.keys(importedUids).length

  return (
    <div style={overlay}>
      <div style={{ ...modal, maxHeight: '90vh' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <h3 style={{ margin: 0 }}>❄️ הוסף מזגן</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 20 }}>✕</button>
        </div>

        {/* Tab switcher */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 16, background: '#0f172a', borderRadius: 10, padding: 4 }}>
          {[
            { id: 'sensibo', label: '📡 Sensibo' },
            { id: 'mqtt',    label: '🔧 MQTT/IR'  },
            { id: 'manual',  label: '✏️ ידנית'    },
          ].map(t => (
            <button key={t.id} onClick={() => { setTab(t.id); setErr('') }} style={{
              flex: 1, padding: '7px 4px', borderRadius: 8, border: 'none',
              background: tab === t.id ? '#1d4ed8' : 'transparent',
              color: tab === t.id ? '#fff' : '#64748b',
              fontWeight: tab === t.id ? 700 : 400, fontSize: 12, cursor: 'pointer',
            }}>{t.label}</button>
          ))}
        </div>

        {/* ── Sensibo tab ── */}
        {tab === 'sensibo' && (
          <div>
            <div style={{ background: '#0f2d4a', border: '1px solid #1d4ed8', borderRadius: 10, padding: 12, marginBottom: 12, fontSize: 12, color: '#93c5fd' }}>
              <b>📡 Sensibo</b> מחבר כל מזגן לרשת דרך IR.<br />
              תואם: <b>תדיראן, אלקטרה, גנרל, LG, Samsung, Daikin, Mitsubishi</b> ועוד.
            </div>

            {/* Key status */}
            {sensiboOk === false && (
              <div style={{ background: '#7f1d1d', border: '1px solid #ef4444', borderRadius: 8, padding: '10px 12px', fontSize: 12, color: '#fca5a5', marginBottom: 12 }}>
                ⚠️ מפתח Sensibo לא מוגדר.<br />
                עבור ל-<b>⚙️ הגדרות → ❄️ Sensibo</b> כדי להגדיר מפתח API.
              </div>
            )}
            {sensiboOk === true && !pods && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10, fontSize: 12, color: '#22c55e' }}>
                <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#22c55e', flexShrink: 0, display: 'inline-block' }} />
                מפתח Sensibo מוגדר ✓
              </div>
            )}

            {/* Fetch button */}
            {sensiboOk && !pods && (
              <button onClick={fetchPods} disabled={loadingPods}
                style={{ ...btn('#1d4ed8'), width: '100%', opacity: loadingPods ? 0.7 : 1 }}>
                {loadingPods ? '⏳ מחפש מזגנים...' : '🔍 גלה מזגני Sensibo'}
              </button>
            )}

            {podsErr && <div style={errBox}>{podsErr}</div>}

            {/* Devices list */}
            {pods && (
              <div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                  <span style={{ fontSize: 12, color: '#64748b' }}>
                    נמצאו <b style={{ color: '#38bdf8' }}>{pods.length}</b> מזגנים בחשבון
                  </span>
                  <button onClick={fetchPods} disabled={loadingPods}
                    style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 11 }}>
                    🔄 רענן
                  </button>
                </div>

                {pods.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: 20, color: '#475569', fontSize: 13 }}>
                    לא נמצאו מזגנים בחשבון Sensibo
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: '35vh', overflowY: 'auto', marginBottom: 10 }}>
                    {pods.map(pod => {
                      const isImported = importedUids[pod.uid]
                      const isSel      = !!selected[pod.uid]
                      return (
                        <div key={pod.uid} style={{
                          background: isImported ? '#14532d' : '#0f172a',
                          border: `1px solid ${isImported ? '#22c55e' : isSel ? '#1d4ed8' : '#334155'}`,
                          borderRadius: 10, padding: 10,
                        }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: isSel && !isImported ? 8 : 0 }}>
                            <input
                              type="checkbox"
                              checked={isSel}
                              disabled={isImported}
                              onChange={() => setSelected(p => ({ ...p, [pod.uid]: !p[pod.uid] }))}
                              style={{ width: 16, height: 16, cursor: isImported ? 'default' : 'pointer', flexShrink: 0 }}
                            />
                            <div style={{ flex: 1, minWidth: 0 }}>
                              <div style={{ fontSize: 13, fontWeight: 700, color: '#f1f5f9' }}>❄️ {pod.name}</div>
                              <div style={{ fontSize: 11, color: '#64748b', direction: 'ltr' }}>
                                {pod.model}
                                {pod.state?.current_temp     != null && ` · ${pod.state.current_temp}°C`}
                                {pod.state?.current_humidity != null && ` · 💧${pod.state.current_humidity}%`}
                                {pod.state?.state && ` · ${pod.state.state === 'ON' ? '🟢 פועל' : '⚫ כבוי'}`}
                              </div>
                            </div>
                            {isImported && <span style={{ fontSize: 10, color: '#22c55e', flexShrink: 0 }}>✅ יובא</span>}
                          </div>
                          {isSel && !isImported && (
                            <div style={{ display: 'flex', gap: 6 }}>
                              <select
                                value={podBrands[pod.uid] || 'other'}
                                onChange={e => setPodBrands(p => ({ ...p, [pod.uid]: e.target.value }))}
                                style={{ ...inp, flex: 1, marginBottom: 0, fontSize: 11, padding: '5px 8px' }}>
                                {AC_BRANDS.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                              </select>
                              <select
                                value={podRooms[pod.uid] || ''}
                                onChange={e => setPodRooms(p => ({ ...p, [pod.uid]: e.target.value }))}
                                style={{ ...inp, flex: 1, marginBottom: 0, fontSize: 11, padding: '5px 8px' }}>
                                <option value="">ללא חדר</option>
                                {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
                              </select>
                            </div>
                          )}
                        </div>
                      )
                    })}
                  </div>
                )}

                {pods.length > 0 && (
                  <button
                    onClick={importSelected}
                    disabled={importing || selectedCount <= 0}
                    style={{ ...btn('#1d4ed8'), width: '100%', opacity: (importing || selectedCount <= 0) ? 0.6 : 1 }}>
                    {importing ? '⏳ מייבא...' : `📥 יבא נבחרים (${Math.max(0, selectedCount)})`}
                  </button>
                )}

                {importResult && (
                  <div style={{
                    marginTop: 8, padding: '8px 12px', borderRadius: 8, fontSize: 13,
                    background: importResult.ok ? '#14532d' : '#7f1d1d',
                    border: `1px solid ${importResult.ok ? '#22c55e' : '#ef4444'}`,
                    color: '#f1f5f9',
                  }}>{importResult.text}</div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ── MQTT/IR tab ── */}
        {tab === 'mqtt' && (
          <div>
            <div style={{ background: '#1a2c1a', border: '1px solid #22c55e', borderRadius: 10, padding: 12, marginBottom: 14, fontSize: 12, color: '#86efac' }}>
              <b>🔧 MQTT/IR</b> — מתאים ל-ESPHome עם IR transmitter או Tasmota עם irhvac.<br />
              תואם לכל ברנד עם שלט IR.
            </div>

            <label style={lbl}>שם המזגן</label>
            <input value={name} onChange={e => setName(e.target.value)} placeholder="מזגן סלון" style={inp} autoFocus />

            <label style={lbl}>ברנד</label>
            <select value={brand} onChange={e => setBrand(e.target.value)} style={inp}>
              {AC_BRANDS.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>

            <label style={lbl}>Topic פקודה (cmd)</label>
            <input value={topicCmd} onChange={e => setTopicCmd(e.target.value)}
              placeholder={`devices/ac_${brand}/cmd`} style={{ ...inp, direction: 'ltr' }} />

            <label style={lbl}>Topic מצב (state)</label>
            <input value={topicState} onChange={e => setTopicState(e.target.value)}
              placeholder={`devices/ac_${brand}/state`} style={{ ...inp, direction: 'ltr' }} />

            <label style={lbl}>חדר</label>
            <select value={room} onChange={e => setRoom(e.target.value)} style={inp}>
              <option value="">ללא חדר</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {err && <div style={errBox}>{err}</div>}
            <button onClick={saveMqtt} disabled={saving} style={{ ...btn('#22c55e'), width: '100%', opacity: saving ? 0.7 : 1 }}>
              {saving ? '⏳ שומר...' : '✅ הוסף מזגן'}
            </button>
          </div>
        )}

        {/* ── Manual tab ── */}
        {tab === 'manual' && (
          <div>
            <div style={{ background: '#1a1a2c', border: '1px solid #7c3aed', borderRadius: 10, padding: 12, marginBottom: 14, fontSize: 12, color: '#c4b5fd' }}>
              <b>✏️ הוספה ידנית</b> — צור רשומת מזגן ידנית ב-Hub (ללא חיבור אוטומטי).
            </div>

            <label style={lbl}>שם המזגן</label>
            <input value={name} onChange={e => setName(e.target.value)} placeholder="מזגן חדר שינה" style={inp} autoFocus />

            <label style={lbl}>ברנד</label>
            <select value={brand} onChange={e => setBrand(e.target.value)} style={inp}>
              {AC_BRANDS.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>

            <label style={lbl}>חדר</label>
            <select value={room} onChange={e => setRoom(e.target.value)} style={inp}>
              <option value="">ללא חדר</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {err && <div style={errBox}>{err}</div>}
            <button onClick={saveManual} disabled={saving} style={{ ...btn('#7c3aed'), width: '100%', opacity: saving ? 0.7 : 1 }}>
              {saving ? '⏳ שומר...' : '✅ הוסף מזגן'}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

/* ── Network Scan Modal ────────────────────────────────────────────────────── */
function NetworkScanModal({ rooms, onAddDevice, onClose }) {
  const [scanning, setScanning] = useState(false)
  const [results, setResults]   = useState([])
  const [adding, setAdding]     = useState(null)
  const [added, setAdded]       = useState({})
  const [err, setErr]           = useState('')

  const runScan = async () => {
    setScanning(true); setResults([]); setErr('')
    try {
      const r = await api.get('/network/scan-devices')
      setResults(r.data || [])
      if (!r.data?.length) setErr('לא נמצאו מכשירים ברשת. ודא שאתה מחובר לרשת המקומית.')
    } catch (e) {
      setErr(e?.response?.data?.detail || 'שגיאה בסריקת רשת')
    }
    setScanning(false)
  }

  const addFound = async (dev) => {
    const id = (dev.ip || dev.name || '').replace(/[\s.]/g, '_') || `net_${Date.now()}`
    // Map device_type → UI type
    const typeMap = { tasmota: 'switch', shelly: 'switch', esphome: 'switch',
                      light: 'light', sensor: 'sensor', router: 'switch', media: 'switch' }
    const record = {
      id,
      name:        dev.name || dev.ip || 'מכשיר רשת',
      protocol:    'wifi',
      type:        typeMap[dev.device_type] || 'switch',
      label:       dev.device_type || '',
      topic_state: `devices/${id}/state`,
      topic_cmd:   `devices/${id}/cmd`,
      room:        '',
      config:      { ip: dev.ip, source: 'network_scan', device_type: dev.device_type },
    }
    setAdding(id)
    try {
      await onAddDevice(record)
      setAdded(prev => ({ ...prev, [id]: true }))
    } catch {}
    setAdding(null)
  }

  return (
    <div style={overlay}>
      <div style={{ ...modal, maxHeight: '85vh' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <h3 style={{ margin: 0 }}>📡 סריקת רשת</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 20 }}>✕</button>
        </div>

        <p style={{ fontSize: 12, color: '#64748b', margin: '0 0 14px' }}>
          מחפש מכשירים חכמים, ראוטרים ושרתים ברשת המקומית
        </p>

        <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
          <button onClick={runScan} disabled={scanning} style={{ ...btn('#1d4ed8'), flex: 1, opacity: scanning ? 0.7 : 1 }}>
            {scanning ? '⏳ סורק...' : '🔍 התחל סריקה'}
          </button>
          <button onClick={onClose} style={btn('#475569')}>סגור</button>
        </div>

        {scanning && (
          <div style={{ textAlign: 'center', marginBottom: 12 }}>
            <div style={{ display: 'flex', gap: 6, justifyContent: 'center', flexWrap: 'wrap', fontSize: 12, color: '#64748b' }}>
              {['ARP', 'mDNS', 'SSDP', 'HTTP probe'].map(s => (
                <span key={s} style={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 6, padding: '2px 8px' }}>
                  ⏳ {s}
                </span>
              ))}
            </div>
          </div>
        )}

        {err && <div style={errBox}>{err}</div>}

        {results.length > 0 && (
          <div style={{ marginTop: 4 }}>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
              נמצאו {results.length} מכשירים:
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: '45vh', overflowY: 'auto' }}>
              {results.map((dev, i) => {
                const id = (dev.ip || dev.name || '').replace(/[\s.]/g, '_') || `net_${i}`
                const isAdded = added[id]
                return (
                  <div key={i} style={{
                    background: '#0f172a', border: '1px solid #334155', borderRadius: 10,
                    padding: '10px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8,
                  }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                        <span style={{ fontWeight: 700, color: '#e2e8f0', fontSize: 13 }}>
                          {dev.device_type === 'router' || dev.is_gateway ? '🌐'
                            : dev.device_type === 'tasmota' || dev.device_type === 'shelly' ? '🔌'
                            : dev.device_type === 'esphome' ? '⚡'
                            : dev.device_type === 'media' ? '📺'
                            : dev.device_type === 'mdns' ? '📡'
                            : '📱'} {dev.name || dev.ip}
                        </span>
                        {dev.device_type && (
                          <span style={{ fontSize: 10, background: '#1e3a5f', border: '1px solid #3b82f6', borderRadius: 4, padding: '1px 6px', color: '#93c5fd' }}>
                            {dev.device_type}
                          </span>
                        )}
                        {dev.auto_pair && (
                          <span style={{ fontSize: 10, background: '#14532d', border: '1px solid #22c55e', borderRadius: 4, padding: '1px 6px', color: '#86efac' }}>
                            ✓ auto-pair
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 11, color: '#475569', marginTop: 2 }}>
                        {dev.ip && <span>{dev.ip}</span>}
                        {dev.info?.ssdp_server && <span style={{ marginRight: 8 }}>{dev.info.ssdp_server}</span>}
                        {dev.already_paired && <span style={{ marginRight: 8, color: '#f59e0b' }}>⚠️ כבר מוגדר</span>}
                      </div>
                    </div>
                    <button
                      onClick={() => addFound(dev)}
                      disabled={adding === id || isAdded}
                      style={{
                        ...btn(isAdded ? '#14532d' : '#1d4ed8'),
                        padding: '6px 12px', fontSize: 12, flexShrink: 0,
                        opacity: adding === id ? 0.7 : 1,
                      }}>
                      {isAdded ? '✅ נוסף' : adding === id ? '...' : '+ הוסף'}
                    </button>
                  </div>
                )
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

/* ── Moes / Tuya Gateway Modal ────────────────────────────────────────────── */
const SUB_TYPES = [
  { value: 'switch', label: '🔌 מתג' },
  { value: 'light',  label: '💡 נורה' },
  { value: 'sensor', label: '🌡️ חיישן' },
  { value: 'motion', label: '👤 תנועה' },
  { value: 'door',   label: '🚪 דלת' },
  { value: 'smoke',  label: '🔥 עשן' },
  { value: 'lock',   label: '🔒 מנעול' },
]

function MoesGatewayModal({ rooms, onClose, onAdded }) {
  const [tab, setTab]         = useState('scan')  // scan | pair | subs | help
  const [scanning, setScanning] = useState(false)
  const [found, setFound]     = useState([])      // LAN scan results
  const [scanErr, setScanErr] = useState('')

  // pair form
  const [pairIp, setPairIp]       = useState('')
  const [pairId, setPairId]       = useState('')
  const [pairKey, setPairKey]     = useState('')
  const [pairName, setPairName]   = useState('Moes Gateway')
  const [pairVer, setPairVer]     = useState('3.3')
  const [pairing, setPairing]     = useState(false)
  const [pairOk, setPairOk]       = useState(false)
  const [pairErr, setPairErr]     = useState('')
  const [pairDps, setPairDps]     = useState(null)
  const [pairRoom, setPairRoom]   = useState('')

  // sub-devices
  const [subs, setSubs]           = useState([])
  const [subsLoading, setSubsL]   = useState(false)
  const [subsErr, setSubsErr]     = useState('')
  const [subNames, setSubNames]   = useState({})
  const [subTypes, setSubTypes]   = useState({})
  const [adding, setAdding]       = useState({})
  const [addedSubs, setAddedSubs] = useState({})

  // help
  const [helpSteps, setHelpSteps] = useState([])

  /* ── Load help ── */
  useEffect(() => {
    api.get('/tuya/help').then(r => setHelpSteps(r.data.steps || [])).catch(() => {})
  }, [])

  /* ── LAN Scan ── */
  const runScan = async () => {
    setScanning(true); setFound([]); setScanErr('')
    try {
      const r = await api.get('/tuya/scan?force=true')
      const devs = r.data.devices || []
      setFound(devs)
      if (!devs.length) setScanErr('לא נמצאו מכשירי Tuya. ודא שאתה על אותה רשת WiFi.')
    } catch (e) {
      setScanErr(e?.response?.data?.detail || 'שגיאה בסריקה')
    }
    setScanning(false)
  }

  /* ── Pair ── */
  const runPair = async () => {
    if (!pairIp || !pairId || !pairKey) { setPairErr('מלא IP, Device ID ו-Local Key'); return }
    setPairing(true); setPairErr(''); setPairOk(false); setPairDps(null)
    try {
      const r = await api.post('/tuya/pair', {
        ip: pairIp, device_id: pairId, local_key: pairKey,
        name: pairName, version: parseFloat(pairVer),
      })
      setPairOk(true)
      setPairDps(r.data.dps || {})
    } catch (e) {
      setPairErr(e?.response?.data?.detail || 'חיבור נכשל — בדוק IP ו-Local Key')
    }
    setPairing(false)
  }

  /* ── Import Gateway ── */
  const importGateway = async () => {
    try {
      await api.post('/tuya/import-gateway', {
        device_id: pairId, ip: pairIp, local_key: pairKey,
        name: pairName, room: pairRoom, version: parseFloat(pairVer),
      })
      onAdded()
    } catch (e) {
      setPairErr(e?.response?.data?.detail || 'שגיאה בייבוא')
    }
  }

  /* ── Load sub-devices ── */
  const loadSubs = async () => {
    if (!pairIp || !pairId || !pairKey) { setSubsErr('קודם חבר בטאב "חיבור"'); return }
    setSubsL(true); setSubsErr('')
    try {
      const r = await api.get(`/tuya/subdevices/${pairId}?ip=${pairIp}&local_key=${pairKey}`)
      setSubs(r.data.subdevices || [])
      if (!r.data.subdevices?.length) setSubsErr('לא נמצאו מכשירי-תת. ודא שמכשירים צמודים ל-Gateway בSmart Life.')
    } catch (e) {
      setSubsErr(e?.response?.data?.detail || 'שגיאה')
    }
    setSubsL(false)
  }

  /* ── Import sub-device ── */
  const importSub = async (sub) => {
    const name = (subNames[sub.node_id] || sub.name || `מכשיר ${sub.node_id}`).trim()
    const type = subTypes[sub.node_id] || 'switch'
    setAdding(p => ({ ...p, [sub.node_id]: true }))
    try {
      await api.post('/tuya/import-subdevice', {
        gateway_device_id: pairId,
        gateway_ip: pairIp,
        gateway_local_key: pairKey,
        node_id: sub.node_id,
        name, hub_type: type, room: pairRoom,
      })
      setAddedSubs(p => ({ ...p, [sub.node_id]: true }))
    } catch (e) {
      alert(e?.response?.data?.detail || 'שגיאה')
    }
    setAdding(p => ({ ...p, [sub.node_id]: false }))
  }

  /* ── Select gateway from scan and fill pair form ── */
  const pickFromScan = (dev) => {
    setPairIp(dev.ip || '')
    setPairId(dev.device_id || '')
    setPairName(dev.name || 'Moes Gateway')
    setPairVer(dev.version || '3.3')
    setTab('pair')
  }

  return (
    <div style={overlay}>
      <div style={{ ...modal, maxHeight: '90vh' }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 24 }}>📡</span>
            <div>
              <div style={{ fontWeight: 700, fontSize: 14, color: '#38bdf8' }}>Moes Multi Mode Gateway</div>
              <div style={{ fontSize: 10, color: '#475569' }}>Tuya Zigbee / BLE / WiFi</div>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 20 }}>✕</button>
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', gap: 4, background: '#0f172a', borderRadius: 10, padding: 4, marginBottom: 16 }}>
          {[
            { id: 'scan', label: '🔍 גילוי' },
            { id: 'pair', label: '🔗 חיבור' },
            { id: 'subs', label: '📋 מכשירים' },
            { id: 'help', label: '❓ מדריך' },
          ].map(t => (
            <button key={t.id} onClick={() => setTab(t.id)} style={{
              flex: 1, padding: '7px 2px', borderRadius: 8, border: 'none',
              background: tab === t.id ? '#1d4ed8' : 'transparent',
              color: tab === t.id ? '#fff' : '#64748b',
              fontWeight: tab === t.id ? 700 : 400, fontSize: 11, cursor: 'pointer',
            }}>{t.label}</button>
          ))}
        </div>

        {/* ── Scan tab ── */}
        {tab === 'scan' && (
          <div>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 12 }}>
              מחפש מכשירי Tuya ברשת (UDP 6666/6667 + ARP)
            </div>
            <button onClick={runScan} disabled={scanning} style={{ ...btn('#1d4ed8'), width: '100%', opacity: scanning ? 0.7 : 1, marginBottom: 12 }}>
              {scanning ? '⏳ סורק רשת...' : '🔍 חפש מכשירי Tuya'}
            </button>

            {scanErr && <div style={errBox}>{scanErr}</div>}

            {found.length > 0 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <div style={{ fontSize: 12, color: '#64748b' }}>נמצאו {found.length} מכשירים:</div>
                {found.map((d, i) => (
                  <div key={i} style={{
                    background: '#0f172a', border: `1px solid ${d.is_gateway ? '#38bdf8' : '#334155'}`,
                    borderRadius: 10, padding: '10px 12px',
                    display: 'flex', alignItems: 'center', gap: 10,
                  }}>
                    <span style={{ fontSize: 20 }}>{d.is_gateway ? '📡' : '🔌'}</span>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 12, fontWeight: 600, color: '#f1f5f9', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {d.name}
                      </div>
                      <div style={{ fontSize: 10, color: '#475569', direction: 'ltr' }}>
                        {d.ip} · v{d.version}
                        {d.is_gateway && <span style={{ color: '#38bdf8' }}> · Gateway</span>}
                        {d.already_paired && <span style={{ color: '#f59e0b' }}> · מחובר</span>}
                      </div>
                    </div>
                    <button onClick={() => pickFromScan(d)} style={{ ...btn('#1d4ed8'), padding: '6px 10px', fontSize: 11 }}>
                      בחר
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ── Pair tab ── */}
        {tab === 'pair' && (
          <div>
            <div style={{ background: '#0c2340', border: '1px solid #1d4ed8', borderRadius: 10, padding: 10, marginBottom: 14, fontSize: 11, color: '#93c5fd', lineHeight: 1.7 }}>
              💡 <b>Device ID</b> + <b>Local Key</b> ← ראה לשונית מדריך<br/>
              או: Smart Life App → Gateway → עריכה → פרטים נוספים
            </div>

            <label style={lbl}>שם</label>
            <input value={pairName} onChange={e => setPairName(e.target.value)} style={inp} placeholder="Moes Gateway" />

            <label style={lbl}>כתובת IP</label>
            <input value={pairIp} onChange={e => setPairIp(e.target.value)} style={{ ...inp, direction: 'ltr' }} placeholder="192.168.10.50" />

            <label style={lbl}>Device ID</label>
            <input value={pairId} onChange={e => setPairId(e.target.value)} style={{ ...inp, direction: 'ltr' }} placeholder="bf1234567890abcdef" />

            <label style={lbl}>Local Key</label>
            <input value={pairKey} onChange={e => setPairKey(e.target.value)} style={{ ...inp, direction: 'ltr' }} placeholder="AbCdEfGh12345678" />

            <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
              <div style={{ flex: 1 }}>
                <label style={lbl}>גרסת פרוטוקול</label>
                <select value={pairVer} onChange={e => setPairVer(e.target.value)} style={inp}>
                  <option value="3.3">3.3 (מוצגי Moes, בדרך כלל)</option>
                  <option value="3.4">3.4</option>
                  <option value="3.5">3.5 (חדש)</option>
                  <option value="3.1">3.1 (ישן)</option>
                </select>
              </div>
            </div>

            <label style={lbl}>חדר (אופציונלי)</label>
            <select value={pairRoom} onChange={e => setPairRoom(e.target.value)} style={inp}>
              <option value="">ללא חדר</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {pairErr && <div style={errBox}>{pairErr}</div>}

            {pairOk && pairDps && (
              <div style={{ background: '#14532d', border: '1px solid #22c55e', borderRadius: 10, padding: 12, marginBottom: 12 }}>
                <div style={{ fontSize: 12, color: '#86efac', fontWeight: 700, marginBottom: 6 }}>✅ Gateway מחובר!</div>
                <div style={{ fontSize: 10, color: '#4ade80', direction: 'ltr', fontFamily: 'monospace', maxHeight: 80, overflowY: 'auto' }}>
                  DPS: {JSON.stringify(pairDps)}
                </div>
              </div>
            )}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={runPair} disabled={pairing} style={{ ...btn('#1d4ed8'), flex: 1, opacity: pairing ? 0.7 : 1 }}>
                {pairing ? '⏳ מתחבר...' : '🔗 בדוק חיבור'}
              </button>
              {pairOk && (
                <button onClick={importGateway} style={{ ...btn('#22c55e'), flex: 1 }}>
                  📥 יבא Gateway
                </button>
              )}
            </div>
          </div>
        )}

        {/* ── Sub-devices tab ── */}
        {tab === 'subs' && (
          <div>
            {(!pairIp || !pairId || !pairKey) ? (
              <div style={{ textAlign: 'center', padding: 20, color: '#475569' }}>
                <div style={{ fontSize: 32, marginBottom: 8 }}>🔗</div>
                <div style={{ fontSize: 12 }}>קודם חבר את ה-Gateway בלשונית "חיבור"</div>
                <button onClick={() => setTab('pair')} style={{ ...btn('#1d4ed8'), marginTop: 12 }}>
                  עבור לחיבור
                </button>
              </div>
            ) : (
              <>
                <div style={{ fontSize: 12, color: '#64748b', marginBottom: 10, lineHeight: 1.6 }}>
                  מכשירי Zigbee/BLE הצמודים ל-<b style={{ color: '#38bdf8' }}>{pairName}</b>
                </div>
                <button onClick={loadSubs} disabled={subsLoading} style={{ ...btn('#1d4ed8'), width: '100%', marginBottom: 12, opacity: subsLoading ? 0.7 : 1 }}>
                  {subsLoading ? '⏳ טוען...' : '📋 טען מכשירים'}
                </button>

                {subsErr && <div style={errBox}>{subsErr}</div>}

                {subs.length > 0 && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {subs.map((sub, i) => {
                      const isAdded = addedSubs[sub.node_id]
                      return (
                        <div key={i} style={{
                          background: '#0f172a', border: `1px solid ${isAdded ? '#166534' : '#334155'}`,
                          borderRadius: 10, padding: 10,
                        }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                            <span style={{ fontSize: 16 }}>🔌</span>
                            <div style={{ fontSize: 11, color: '#64748b' }}>Node: {sub.node_id}</div>
                            {isAdded && <span style={{ fontSize: 10, color: '#22c55e', marginRight: 'auto' }}>✅ נוסף</span>}
                          </div>
                          <input
                            value={subNames[sub.node_id] ?? sub.name}
                            onChange={e => setSubNames(p => ({ ...p, [sub.node_id]: e.target.value }))}
                            placeholder="שם המכשיר"
                            style={{ ...inp, marginBottom: 6, fontSize: 12 }}
                          />
                          <div style={{ display: 'flex', gap: 6 }}>
                            <select
                              value={subTypes[sub.node_id] || 'switch'}
                              onChange={e => setSubTypes(p => ({ ...p, [sub.node_id]: e.target.value }))}
                              style={{ ...inp, marginBottom: 0, flex: 1 }}
                            >
                              {SUB_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                            </select>
                            <button
                              onClick={() => importSub(sub)}
                              disabled={adding[sub.node_id] || isAdded}
                              style={{ ...btn(isAdded ? '#14532d' : '#22c55e'), padding: '8px 12px', fontSize: 12, flexShrink: 0, opacity: adding[sub.node_id] ? 0.7 : 1 }}>
                              {isAdded ? '✅' : adding[sub.node_id] ? '...' : '+ הוסף'}
                            </button>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                )}
              </>
            )}
          </div>
        )}

        {/* ── Help tab ── */}
        {tab === 'help' && (
          <div>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#38bdf8', marginBottom: 12 }}>
              📖 איך לקבל Device ID ו-Local Key
            </div>
            {helpSteps.map((s, i) => (
              <div key={i} style={{
                background: '#0f172a', border: '1px solid #334155', borderRadius: 10,
                padding: 12, marginBottom: 8,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                  <div style={{ width: 22, height: 22, borderRadius: '50%', background: '#1d4ed8', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 700, color: '#fff', flexShrink: 0 }}>{s.step}</div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: '#f1f5f9' }}>{s.title}</div>
                </div>
                <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.7, whiteSpace: 'pre-line', paddingRight: 30 }}>
                  {s.detail}
                </div>
              </div>
            ))}
            <a href="https://iot.tuya.com" target="_blank" rel="noreferrer"
              style={{ display: 'block', textAlign: 'center', marginTop: 8, fontSize: 12, color: '#38bdf8' }}>
              🌐 פתח Tuya IoT Platform
            </a>
          </div>
        )}
      </div>
    </div>
  )
}

const btn = (bg, color = '#fff') => ({
  padding: '9px 18px', borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const inp = {
  width: '100%', padding: '10px 12px', marginBottom: 12, borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 14, boxSizing: 'border-box', direction: 'rtl',
}
const lbl     = { display: 'block', fontSize: 12, color: '#94a3b8', marginBottom: 5 }
const errBox  = { background: '#7f1d1d', border: '1px solid #ef4444', color: '#fca5a5', borderRadius: 8, padding: '8px 12px', fontSize: 13, marginBottom: 12 }
const overlay = { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }
const modal   = { background: '#1e293b', border: '1px solid #334155', borderRadius: 16, padding: 24, width: '90%', maxWidth: 400, direction: 'rtl', maxHeight: '90vh', overflowY: 'auto' }
