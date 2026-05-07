/**
 * AcPage — dashboard for all AC / air-conditioner devices.
 * Shows every device with type === 'ac' in full AcCard format,
 * plus a summary bar and "All ON / All OFF" master controls.
 */
import { useMemo, useState, useEffect } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'
import AcCard from '../components/AcCard'

export default function AcPage({ devices, onReload }) {
  const [rooms, setRooms] = useState([])
  useEffect(() => {
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
  }, [])
  const { t, rtl } = useLang()

  const acDevices = useMemo(
    () => (devices || []).filter(d => d.type === 'ac'),
    [devices]
  )

  const totalOn  = acDevices.filter(d => d.state?.state === 'ON').length
  const totalOff = acDevices.length - totalOn

  const roomName = (d) => {
    if (!rooms || !d.room) return t.no_room
    return rooms.find(r => r.id === d.room)?.name || t.no_room
  }

  const allOff = async () => {
    await Promise.allSettled(
      acDevices
        .filter(d => d.state?.state === 'ON')
        .map(d => api.post(`/ac/control/${d.id}`, { state: 'OFF' }))
    )
    onReload?.()
  }

  const allOn = async () => {
    await Promise.allSettled(
      acDevices
        .filter(d => d.state?.state !== 'ON')
        .map(d => api.post(`/ac/control/${d.id}`, { state: 'ON' }))
    )
    onReload?.()
  }

  // ── No ACs ──────────────────────────────────────────────────────────────────
  if (acDevices.length === 0) {
    return (
      <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>
        <h2 style={{ margin: '0 0 6px', color: '#e2e8f0', fontSize: 18 }}>
          ❄️ {t.ac_page_title ?? 'Air Conditioners'}
        </h2>
        <div style={{
          background: '#1e293b', border: '1px solid #334155',
          borderRadius: 14, padding: 32,
          textAlign: 'center', marginTop: 16,
        }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>❄️</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#e2e8f0', marginBottom: 8 }}>
            {t.ac_no_acs ?? 'No ACs added'}
          </div>
          <div style={{ fontSize: 13, color: '#475569', lineHeight: 1.6 }}>
            {t.ac_no_acs_hint ?? 'Go to Devices → + Add → ❄️ Add AC'}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>

      {/* ── Page title ── */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div>
          <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>
            ❄️ {t.ac_page_title ?? 'Air Conditioners'}
          </h2>
          <div style={{ fontSize: 12, color: '#475569', marginTop: 2 }}>
            {acDevices.length} {t.ac_units_word ?? 'units'} ·{' '}
            <span style={{ color: '#22c55e' }}>
              {totalOn} {t.ac_on_word ?? 'on'}
            </span>
            {totalOff > 0 && (
              <span style={{ color: '#475569' }}>
                {' '}· {totalOff} {t.ac_off_word ?? 'off'}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* ── Master controls ── */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <button onClick={allOn} style={{
          flex: 1, padding: '10px 0', borderRadius: 10,
          background: '#14532d', border: '1px solid #22c55e44',
          color: '#22c55e', fontWeight: 700, fontSize: 13, cursor: 'pointer',
        }}>
          🟢 {t.ac_all_on ?? 'All ON'}
        </button>
        <button onClick={allOff} style={{
          flex: 1, padding: '10px 0', borderRadius: 10,
          background: '#1e293b', border: '1px solid #334155',
          color: '#94a3b8', fontWeight: 700, fontSize: 13, cursor: 'pointer',
        }}>
          ⏹ {t.ac_all_off ?? 'All OFF'}
        </button>
      </div>

      {/* ── AC cards ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {acDevices.map(d => (
          <AcCard
            key={d.id}
            device={d}
            roomName={roomName(d)}
            onUpdate={onReload}
          />
        ))}
      </div>
    </div>
  )
}
