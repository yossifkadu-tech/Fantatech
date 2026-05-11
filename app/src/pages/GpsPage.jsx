/**
 * GpsPage — GPS geolocation + Device Drivers/Protocols status
 * Uses browser navigator.geolocation (works in Android WebView with location permission)
 */
import { useState, useEffect, useRef } from 'react'
import { useLang } from '../context/LangContext'
import { api } from '../hooks/useHub'

/* ── Haversine distance (metres) ── */
function haversine(lat1, lon1, lat2, lon2) {
  const R = 6371000
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

function fmtDist(m, t) {
  if (m < 1000) return `${Math.round(m)} ${t.gps_meters ?? 'm'}`
  return `${(m / 1000).toFixed(1)} ${t.gps_km ?? 'km'}`
}

/* ── Driver card ── */
function DriverCard({ icon, label, active, color }) {
  return (
    <div style={{
      background: '#1e293b', borderRadius: 12,
      border: `1px solid ${active ? color + '66' : '#334155'}`,
      padding: '12px 14px',
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{
        width: 38, height: 38, borderRadius: 10,
        background: active ? color + '22' : '#0f172a',
        border: `1px solid ${active ? color : '#334155'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 18, flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: '#e2e8f0' }}>{label}</div>
        <div style={{
          fontSize: 11, marginTop: 2,
          color: active ? color : '#475569',
        }}>
          {active ? '● Active' : '○ Not configured'}
        </div>
      </div>
      <div style={{
        width: 8, height: 8, borderRadius: '50%',
        background: active ? color : '#334155',
        boxShadow: active ? `0 0 6px ${color}` : 'none',
      }} />
    </div>
  )
}

export default function GpsPage() {
  const { t, rtl } = useLang()

  /* GPS state */
  const [pos, setPos]         = useState(null)   // { lat, lng, accuracy }
  const [homePos, setHomePos] = useState(() => {
    try { return JSON.parse(localStorage.getItem('fantatech_home_gps') || 'null') } catch { return null }
  })
  const [gpsStatus, setGpsStatus] = useState('idle')  // idle|getting|ok|denied|error
  const [savedMsg, setSavedMsg]   = useState('')
  const [radius, setRadius]       = useState(() => parseInt(localStorage.getItem('fantatech_gps_radius') || '200'))
  const watchRef = useRef(null)

  /* Driver statuses from hub */
  const [driverStatus, setDriverStatus] = useState({})
  useEffect(() => {
    api.get('/network/drivers-status').then(r => setDriverStatus(r.data || {})).catch(() => {})
  }, [])

  /* Start GPS watch */
  useEffect(() => {
    if (!navigator.geolocation) { setGpsStatus('error'); return }
    setGpsStatus('getting')
    watchRef.current = navigator.geolocation.watchPosition(
      (p) => {
        setPos({ lat: p.coords.latitude, lng: p.coords.longitude, accuracy: Math.round(p.coords.accuracy) })
        setGpsStatus('ok')
      },
      (err) => {
        setGpsStatus(err.code === 1 ? 'denied' : 'error')
      },
      { enableHighAccuracy: true, maximumAge: 10000, timeout: 15000 }
    )
    return () => navigator.geolocation.clearWatch(watchRef.current)
  }, [])

  const setHome = () => {
    if (!pos) return
    const h = { lat: pos.lat, lng: pos.lng }
    localStorage.setItem('fantatech_home_gps', JSON.stringify(h))
    setHomePos(h)
    setSavedMsg(t.gps_home_saved ?? 'Home location saved ✓')
    setTimeout(() => setSavedMsg(''), 3000)
  }

  const distance = pos && homePos ? haversine(pos.lat, pos.lng, homePos.lat, homePos.lng) : null
  const atHome   = distance !== null && distance <= radius

  const saveRadius = (v) => {
    setRadius(v)
    localStorage.setItem('fantatech_gps_radius', String(v))
  }

  /* Driver definitions */
  const DRIVERS = [
    { key: 'wifi',    icon: '📶', label: t.gps_driver_wifi    ?? 'WiFi / LAN',       color: '#38bdf8' },
    { key: 'zigbee',  icon: '🔷', label: t.gps_driver_zigbee  ?? 'Zigbee',            color: '#818cf8' },
    { key: 'tasmota', icon: '⚡', label: t.gps_driver_tasmota ?? 'Tasmota',           color: '#f59e0b' },
    { key: 'shelly',  icon: '🔴', label: t.gps_driver_shelly  ?? 'Shelly',            color: '#ef4444' },
    { key: 'ble',     icon: '🔵', label: t.gps_driver_ble     ?? 'Bluetooth BLE',     color: '#3b82f6' },
    { key: 'tuya',    icon: '☁️',  label: t.gps_driver_tuya    ?? 'Tuya Cloud',        color: '#f97316' },
    { key: 'mqtt',    icon: '📡', label: t.gps_driver_mqtt    ?? 'MQTT Broker',       color: '#22c55e' },
    { key: 'ha',      icon: '🏠', label: t.gps_driver_ha      ?? 'Home Assistant',    color: '#6366f1' },
  ]

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr', paddingBottom: 20 }}>
      <h2 style={{ margin: '0 0 4px', color: '#e2e8f0', fontSize: 18 }}>
        📍 {t.gps_title ?? 'Location & GPS'}
      </h2>
      <p style={{ margin: '0 0 20px', fontSize: 12, color: '#64748b' }}>
        {t.gps_subtitle ?? 'Geofencing & smart home location'}
      </p>

      {/* ── Status card ── */}
      <div style={{
        background: '#1e293b', borderRadius: 16,
        border: `2px solid ${atHome ? '#22c55e' : gpsStatus === 'ok' ? '#38bdf8' : '#334155'}`,
        padding: '18px 20px', marginBottom: 16,
        boxShadow: atHome ? '0 0 20px #22c55e33' : 'none',
        transition: 'all 0.3s',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 28 }}>{atHome ? '🏠' : gpsStatus === 'ok' ? '📍' : '🔄'}</div>
          </div>
          <div style={{ textAlign: rtl ? 'left' : 'right' }}>
            {gpsStatus === 'getting' && (
              <div style={{ color: '#64748b', fontSize: 13 }}>{t.gps_getting ?? 'Getting location...'}</div>
            )}
            {gpsStatus === 'denied' && (
              <div style={{ color: '#ef4444', fontSize: 12 }}>{t.gps_denied ?? 'Location permission denied'}</div>
            )}
            {gpsStatus === 'error' && (
              <div style={{ color: '#ef4444', fontSize: 12 }}>{t.gps_error ?? 'Could not get location'}</div>
            )}
            {gpsStatus === 'ok' && pos && (
              <div style={{ color: '#94a3b8', fontSize: 11 }}>
                {t.gps_accuracy ?? 'Accuracy'}: ±{pos.accuracy}m
              </div>
            )}
          </div>
        </div>

        {pos && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
            <div style={{ background: '#0f172a', borderRadius: 10, padding: '10px 12px' }}>
              <div style={{ fontSize: 10, color: '#64748b', marginBottom: 2 }}>{t.gps_current ?? 'Current'}</div>
              <div style={{ fontSize: 12, color: '#38bdf8', fontFamily: 'monospace' }}>
                {pos.lat.toFixed(5)}, {pos.lng.toFixed(5)}
              </div>
            </div>
            <div style={{ background: '#0f172a', borderRadius: 10, padding: '10px 12px' }}>
              <div style={{ fontSize: 10, color: '#64748b', marginBottom: 2 }}>{t.gps_home ?? 'Home'}</div>
              {homePos ? (
                <div style={{ fontSize: 12, color: '#22c55e', fontFamily: 'monospace' }}>
                  {homePos.lat.toFixed(5)}, {homePos.lng.toFixed(5)}
                </div>
              ) : (
                <div style={{ fontSize: 11, color: '#475569' }}>{t.gps_home_not_set ?? 'Not set'}</div>
              )}
            </div>
          </div>
        )}

        {/* Distance badge */}
        {distance !== null && (
          <div style={{
            background: atHome ? '#14532d' : '#1c1f2e',
            border: `1px solid ${atHome ? '#22c55e' : '#334155'}`,
            borderRadius: 10, padding: '8px 14px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginBottom: 12,
          }}>
            <span style={{ fontSize: 13, fontWeight: 600, color: atHome ? '#22c55e' : '#e2e8f0' }}>
              {atHome ? (t.gps_at_home ?? 'You are home 🏠') : (t.gps_away ?? 'Away from home')}
            </span>
            <span style={{ fontSize: 13, color: '#94a3b8', fontFamily: 'monospace' }}>
              {fmtDist(distance, t)}
            </span>
          </div>
        )}

        {/* Set home button */}
        {pos && (
          <button onClick={setHome} style={{
            width: '100%', padding: '10px', borderRadius: 10, border: 'none',
            background: '#1d4ed8', color: '#fff', fontSize: 13, fontWeight: 700,
            cursor: 'pointer',
          }}>
            📍 {t.gps_set_home ?? 'Set Current Location as Home'}
          </button>
        )}
        {savedMsg && (
          <div style={{ marginTop: 8, textAlign: 'center', fontSize: 12, color: '#22c55e' }}>{savedMsg}</div>
        )}
      </div>

      {/* ── Geofence radius ── */}
      <div style={{ background: '#1e293b', borderRadius: 14, border: '1px solid #334155', padding: '14px 16px', marginBottom: 16 }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0', marginBottom: 10 }}>
          🎯 {t.gps_geofence_radius ?? 'Geofence radius'}: {radius}m
        </div>
        <input type="range" min="50" max="2000" step="50" value={radius}
          onChange={e => saveRadius(parseInt(e.target.value))}
          style={{ width: '100%', accentColor: '#38bdf8' }}
        />
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: '#475569', marginTop: 4 }}>
          <span>50m</span><span>500m</span><span>1km</span><span>2km</span>
        </div>
      </div>

      {/* ── Device Drivers ── */}
      <div style={{ background: '#1e293b', borderRadius: 14, border: '1px solid #334155', padding: '14px 16px' }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#e2e8f0', marginBottom: 12 }}>
          🔌 {t.gps_drivers_title ?? 'Device Drivers & Protocols'}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {DRIVERS.map(d => (
            <DriverCard
              key={d.key}
              icon={d.icon}
              label={d.label}
              color={d.color}
              active={driverStatus[d.key] === true || driverStatus[d.key] === 'active'}
            />
          ))}
        </div>
        <div style={{ marginTop: 10, fontSize: 11, color: '#475569', textAlign: 'center' }}>
          Driver status is fetched live from the hub
        </div>
      </div>
    </div>
  )
}
