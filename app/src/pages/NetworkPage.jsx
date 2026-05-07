import { useState, useEffect, useRef } from 'react'
import { api } from '../hooks/useHub'
import { BleClient } from '@capacitor-community/bluetooth-le'
import { useLang } from '../context/LangContext'

/* ── Helpers ────────────────────────────────────────────────────────────── */
const TYPE_META_BASE = {
  tasmota: { icon: '🟠', label: 'Tasmota',  autoPair: true  },
  shelly:  { icon: '🔴', label: 'Shelly',   autoPair: true  },
  esphome: { icon: '🔵', label: 'ESPHome',  autoPair: false },
  http:    { icon: '🌐', label: 'HTTP',     autoPair: false },
}

const getTypeMeta = (deviceType, t) =>
  TYPE_META_BASE[deviceType] ?? { icon: '❓', label: t.unknown_type, autoPair: false }

const getDevTypes = (t) => [
  { value: 'switch', label: t.dev_type_switch, icon: '🔌' },
  { value: 'light',  label: t.dev_type_light,  icon: '💡' },
  { value: 'dimmer', label: t.dev_type_dimmer, icon: '🔆' },
  { value: 'color',  label: 'RGB',             icon: '🎨' },
  { value: 'sensor', label: t.dev_type_sensor, icon: '🌡️' },
  { value: 'fan',    label: t.dev_type_fan,    icon: '🌀' },
  { value: 'lock',   label: t.dev_type_lock,   icon: '🔒' },
  { value: 'camera', label: t.dev_type_camera, icon: '📷' },
]

const getMatterTypes = (t) => [
  { value: 'switch', label: t.dev_type_switch, icon: '🔌' },
  { value: 'light',  label: t.dev_type_light,  icon: '💡' },
  { value: 'sensor', label: t.dev_type_sensor, icon: '🌡️' },
  { value: 'lock',   label: t.dev_type_lock,   icon: '🔒' },
  { value: 'fan',    label: t.dev_type_fan,    icon: '🌀' },
  { value: 'ac',     label: t.dev_type_ac,     icon: '❄️' },
]

const getBtTypeGuess = (name = '', t) => {
  const n = name.toLowerCase()
  if (n.includes('bulb') || n.includes('light') || n.includes('lamp') || n.includes('led'))
    return { type: 'light', icon: '💡', label: t.dev_type_light }
  if (n.includes('sensor') || n.includes('temp') || n.includes('hum') || n.includes('motion'))
    return { type: 'sensor', icon: '🌡️', label: t.dev_type_sensor }
  if (n.includes('switch') || n.includes('plug') || n.includes('socket') || n.includes('outlet'))
    return { type: 'switch', icon: '🔌', label: t.dev_type_switch }
  if (n.includes('lock') || n.includes('door'))
    return { type: 'lock', icon: '🔒', label: t.dev_type_lock }
  if (n.includes('fan') || n.includes('air'))
    return { type: 'fan', icon: '🌀', label: t.dev_type_fan }
  if (n.includes('cam') || n.includes('camera'))
    return { type: 'camera', icon: '📷', label: t.dev_type_camera }
  return { type: 'switch', icon: '🔵', label: 'BLE' }
}

const sigBar   = s => s >= 75 ? '▂▄▆█' : s >= 50 ? '▂▄▆' : s >= 25 ? '▂▄' : '▂'
const sigColor = s => s >= 65 ? '#22c55e' : s >= 35 ? '#f59e0b' : '#ef4444'

/* ══════════════════════════════════════════════════════════════════════════
   Root
══════════════════════════════════════════════════════════════════════════ */
export default function NetworkPage() {
  const { t } = useLang()
  const [tab, setTab] = useState('devices')

  const TABS = [
    { id: 'devices', label: '📡 WiFi' },
    { id: 'bt',      label: '🔵 BLE' },
    { id: 'zigbee',  label: '🔶 Zigbee' },
    { id: 'matter',  label: '🔷 Matter' },
    { id: 'wifi',    label: t.net_tab_wifi },
  ]

  return (
    <div>
      <h2 style={{ margin: '0 0 14px', color: '#e2e8f0', fontSize: 18 }}>{t.network_title}</h2>
      <div style={{ display: 'flex', gap: 6, marginBottom: 20 }}>
        {TABS.map(tb => (
          <button key={tb.id} onClick={() => setTab(tb.id)} style={{
            flex: 1, padding: '9px 0', borderRadius: 10, border: 'none',
            background: tab === tb.id ? '#1d4ed8' : '#1e293b',
            color: tab === tb.id ? '#fff' : '#64748b',
            fontWeight: tab === tb.id ? 700 : 400, fontSize: 11, cursor: 'pointer',
          }}>{tb.label}</button>
        ))}
      </div>
      {tab === 'devices' && <DeviceScanner />}
      {tab === 'bt'      && <BluetoothScanner />}
      {tab === 'zigbee'  && <ZigbeeScanner />}
      {tab === 'matter'  && <MatterScanner />}
      {tab === 'wifi'    && <WifiManager />}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════════════
   TAB 1 — Device Scanner with auto-pair
══════════════════════════════════════════════════════════════════════════ */
function DeviceScanner() {
  const { t, rtl } = useLang()
  const inp = makeInp(rtl)

  const [scanning, setScanning]   = useState(false)
  const [progress, setProgress]   = useState('')
  const [devices, setDevices]     = useState([])
  const [rooms, setRooms]         = useState([])
  const [netInfo, setNetInfo]     = useState(null)
  const [pairTarget, setPairTarget] = useState(null)
  const [pairForm, setPairForm]   = useState({})
  const [pairing, setPairing]     = useState(false)
  const [paired, setPaired]       = useState(new Set())
  const [msg, setMsg]             = useState(null)

  const DEV_TYPES = getDevTypes(t)

  useEffect(() => {
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
    api.get('/network/info').then(r => setNetInfo(r.data)).catch(() => {})
  }, [])

  const scan = async () => {
    setScanning(true)
    setDevices([])
    setMsg(null)
    setProgress(t.net_identifying)

    const hints = [
      t.net_hint_arp,
      t.net_hint_ping,
      t.net_hint_tasmota,
      t.net_hint_upnp,
      t.net_hint_almost,
    ]
    let hIdx = 0
    const hTimer = setInterval(() => {
      hIdx = (hIdx + 1) % hints.length
      setProgress(hints[hIdx])
    }, 1800)

    try {
      const r = await api.get('/network/scan-devices', { timeout: 15000 })
      clearInterval(hTimer)
      setDevices(r.data)
      setProgress('')
      if (!r.data.length) setMsg({ text: t.net_no_devices_found, ok: false })
    } catch {
      clearInterval(hTimer)
      setProgress('')
      setMsg({ text: t.net_scan_failed, ok: false })
    }
    setScanning(false)
  }

  const meta = dev => getTypeMeta(dev.device_type, t)

  const openPair = (dev) => {
    setPairTarget(dev)
    const m = meta(dev)
    setPairForm({
      name:     dev.name,
      dev_type: 'switch',
      room:     '',
      label:    m.label,
    })
    setMsg(null)
  }

  const doPair = async () => {
    setPairing(true)
    try {
      await api.post('/network/pair', {
        ip:          pairTarget.ip,
        name:        pairForm.name,
        device_type: pairTarget.device_type,
        dev_type:    pairForm.dev_type,
        room:        pairForm.room,
        label:       pairForm.label,
      })
      setPaired(prev => new Set([...prev, pairTarget.ip]))
      setPairTarget(null)
      setMsg({ text: `✓ "${pairForm.name}" ${t.net_paired_ok}`, ok: true })
    } catch (e) {
      setMsg({ text: e?.response?.data?.detail || t.net_pair_error, ok: false })
    }
    setPairing(false)
  }

  const autoPairDevices  = devices.filter(d => meta(d).autoPair  && !paired.has(d.ip))
  const manualDevices    = devices.filter(d => !meta(d).autoPair && !paired.has(d.ip))
  const pairedDevices    = devices.filter(d => paired.has(d.ip)  || d.already_paired)

  return (
    <div>
      {/* ── Network info card ── */}
      {netInfo && (
        <div style={{
          background: '#0f172a', border: '1px solid #1d4ed8',
          borderRadius: 12, padding: '10px 14px', marginBottom: 12,
        }}>
          <div style={{ fontSize: 11, color: '#38bdf8', fontWeight: 700, marginBottom: 6 }}>
            {t.net_info_title}
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <div>
              <div style={{ fontSize: 10, color: '#475569' }}>{t.net_hub_ip}</div>
              <div style={{ fontSize: 13, color: '#f1f5f9', fontWeight: 600 }}>{netInfo.hub_ip}</div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: '#475569' }}>{t.net_gateway}</div>
              <div style={{ fontSize: 13, color: '#f1f5f9', fontWeight: 600 }}>{netInfo.gateway || '—'}</div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: '#475569' }}>{t.net_subnet}</div>
              <div style={{ fontSize: 13, color: '#f1f5f9', fontWeight: 600 }}>{netInfo.subnet}</div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: '#475569' }}>{t.net_arp_count}</div>
              <div style={{ fontSize: 13, color: netInfo.arp_count > 0 ? '#22c55e' : '#f59e0b', fontWeight: 600 }}>
                {netInfo.arp_count}
              </div>
            </div>
          </div>
          {netInfo.arp_hosts?.length > 0 && (
            <div style={{ marginTop: 6, fontSize: 10, color: '#334155', lineHeight: 1.8 }}>
              {netInfo.arp_hosts.join(' · ')}
            </div>
          )}
        </div>
      )}

      {/* Scan button */}
      <button onClick={scan} disabled={scanning} style={{
        ...btn(scanning ? '#334155' : '#1d4ed8'), width: '100%', marginBottom: 12,
        fontSize: 15, opacity: scanning ? 0.85 : 1,
      }}>
        {scanning ? `⏳ ${t.scanning}` : t.net_scan_btn}
      </button>

      {scanning && (
        <div style={{ textAlign: 'center', color: '#64748b', fontSize: 12, marginBottom: 14 }}>
          {progress || t.net_identifying}
          <ProgressBar />
        </div>
      )}

      {msg && <Msg {...msg} />}

      {devices.length > 0 && (
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 12 }}>
          {t.net_found} <b style={{ color: '#f1f5f9' }}>{devices.length}</b> {t.net_devices_word} ·{' '}
          <span style={{ color: '#22c55e' }}>{autoPairDevices.length} {t.net_auto_pairable}</span>
        </div>
      )}

      {autoPairDevices.length > 0 && (
        <Section title={t.net_auto_pair}>
          {autoPairDevices.map(d => (
            <DeviceRow key={d.ip} dev={d} meta={meta(d)}
              onPair={() => openPair(d)} auto t={t} />
          ))}
        </Section>
      )}

      {manualDevices.length > 0 && (
        <Section title={t.net_manual_add_section}>
          {manualDevices.map(d => (
            <DeviceRow key={d.ip} dev={d} meta={meta(d)}
              onPair={() => openPair(d)} auto={false} t={t} />
          ))}
        </Section>
      )}

      {pairedDevices.length > 0 && (
        <Section title={t.net_paired_section}>
          {pairedDevices.map(d => (
            <DeviceRow key={d.ip} dev={d} meta={meta(d)} done t={t} />
          ))}
        </Section>
      )}

      {/* Pair modal */}
      {pairTarget && (
        <div style={overlay}>
          <div style={modal}>
            <div style={{ display: 'flex', align: 'center', gap: 8, marginBottom: 16 }}>
              <span style={{ fontSize: 28 }}>{meta(pairTarget).icon}</span>
              <div>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#f1f5f9' }}>{pairTarget.name}</div>
                <div style={{ fontSize: 12, color: '#64748b' }}>{pairTarget.ip} · {meta(pairTarget).label}</div>
              </div>
            </div>

            {meta(pairTarget).autoPair && (
              <div style={{
                background: '#14532d', border: '1px solid #22c55e',
                borderRadius: 8, padding: '8px 12px', fontSize: 12,
                color: '#86efac', marginBottom: 14,
              }}>
                {t.net_mqtt_auto}
              </div>
            )}

            <label style={lbl}>{t.device_name}</label>
            <input value={pairForm.name} autoFocus
              onChange={e => setPairForm({ ...pairForm, name: e.target.value })}
              style={inp} />

            <label style={lbl}>{t.device_type}</label>
            <select value={pairForm.dev_type}
              onChange={e => setPairForm({ ...pairForm, dev_type: e.target.value })}
              style={inp}>
              {DEV_TYPES.map(dt => <option key={dt.value} value={dt.value}>{dt.icon} {dt.label}</option>)}
            </select>

            <label style={lbl}>{t.net_room_area}</label>
            <select value={pairForm.room}
              onChange={e => setPairForm({ ...pairForm, room: e.target.value })}
              style={inp}>
              <option value="">{t.no_room}</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {msg && <Msg {...msg} />}

            <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
              <button onClick={doPair} disabled={pairing}
                style={{ ...btn('#22c55e'), flex: 1, opacity: pairing ? 0.7 : 1 }}>
                {pairing ? t.net_pairing : meta(pairTarget).autoPair ? t.net_pair_auto_btn : t.net_add_device_btn}
              </button>
              <button onClick={() => { setPairTarget(null); setMsg(null) }}
                style={btn('#475569')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function DeviceRow({ dev, meta, onPair, auto = false, done = false, t }) {
  return (
    <div style={{
      ...card, display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8,
      border: `1px solid ${done ? '#22c55e33' : '#334155'}`,
      opacity: done ? 0.7 : 1,
    }}>
      <span style={{ fontSize: 24, flexShrink: 0 }}>{meta.icon}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 700, fontSize: 14, color: '#f1f5f9', display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          {dev.name}
          {done && <Tag color="#22c55e" bg="#14532d22">✓ {t.net_paired_tag}</Tag>}
          {!done && auto && <Tag color="#fbbf24" bg="#78350f22">{t.net_auto_tag}</Tag>}
        </div>
        <div style={{ fontSize: 11, color: '#475569' }}>
          {dev.ip}{dev.hostname !== dev.ip ? ` · ${dev.hostname}` : ''} · {meta.label}
          {dev.info?.firmware && ` · v${dev.info.firmware}`}
        </div>
        {dev.info?.mqtt_host && !dev.already_paired && (
          <div style={{ fontSize: 10, color: '#f59e0b' }}>
            MQTT: {dev.info.mqtt_host}
          </div>
        )}
      </div>
      {!done && (
        <button onClick={onPair} style={btn(auto ? '#22c55e' : '#334155', 10)}>
          {auto ? t.net_pair_btn : `+ ${t.add}`}
        </button>
      )}
    </div>
  )
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 20 }}>
      <div style={{ fontSize: 12, color: '#64748b', fontWeight: 600, marginBottom: 8 }}>{title}</div>
      {children}
    </div>
  )
}

function ProgressBar({ color = '#1d4ed8' }) {
  return (
    <div style={{ height: 3, background: '#1e293b', borderRadius: 2, marginTop: 8, overflow: 'hidden' }}>
      <div style={{
        height: '100%', width: '40%', background: color, borderRadius: 2,
        animation: 'slide 1.4s ease-in-out infinite',
      }} />
      <style>{`@keyframes slide { 0%{margin-right:100%} 100%{margin-right:-40%} }`}</style>
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════════════
   TAB 2 — Bluetooth Scanner
══════════════════════════════════════════════════════════════════════════ */
function BluetoothScanner() {
  const { t, rtl } = useLang()
  const inp = makeInp(rtl)
  const DEV_TYPES = getDevTypes(t)

  const [ready, setReady]         = useState(null)
  const [scanning, setScanning]   = useState(false)
  const [devices, setDevices]     = useState([])
  const [rooms, setRooms]         = useState([])
  const [target, setTarget]       = useState(null)
  const [form, setForm]           = useState({})
  const [saving, setSaving]       = useState(false)
  const [msg, setMsg]             = useState(null)
  const [paired, setPaired]       = useState(new Set())
  const scanTimer = useRef(null)
  const seenIds   = useRef(new Set())

  useEffect(() => {
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
    BleClient.initialize({ androidNeverForLocation: true })
      .then(() => setReady(true))
      .catch(() => setReady(false))
    return () => stopScan()
  }, [])

  const stopScan = () => {
    try { BleClient.stopLEScan() } catch {}
    clearTimeout(scanTimer.current)
  }

  const startScan = async () => {
    if (!ready) return
    setScanning(true)
    setDevices([])
    setMsg(null)
    seenIds.current = new Set()

    try {
      await BleClient.requestLEScan(
        { allowDuplicates: false },
        (result) => {
          const id   = result.device.deviceId
          const name = result.device.name || result.localName || ''
          if (!id || seenIds.current.has(id)) return
          seenIds.current.add(id)
          setDevices(prev => [...prev, {
            id,
            name:    name || `BLE ${id.slice(-5)}`,
            rssi:    result.rssi ?? -99,
            guess:   getBtTypeGuess(name, t),
            rawName: name,
          }])
        }
      )
      scanTimer.current = setTimeout(async () => {
        await BleClient.stopLEScan()
        setScanning(false)
      }, 12000)
    } catch (e) {
      setMsg({ text: `${t.bt_scan_error} ${e?.message || e}`, ok: false })
      setScanning(false)
    }
  }

  const stopScanBtn = async () => {
    clearTimeout(scanTimer.current)
    try { await BleClient.stopLEScan() } catch {}
    setScanning(false)
  }

  const openPair = (dev) => {
    setTarget(dev)
    setForm({ name: dev.name, type: dev.guess.type, room: '' })
    setMsg(null)
  }

  const savePair = async () => {
    if (!form.name.trim()) return
    setSaving(true)
    const deviceId = `bt_${target.id.replace(/[^a-zA-Z0-9]/g, '_')}`
    try {
      await api.post('/devices/', {
        id:          deviceId,
        name:        form.name.trim(),
        protocol:    'bluetooth',
        type:        form.type,
        topic_state: `devices/${deviceId}/state`,
        topic_cmd:   `devices/${deviceId}/cmd`,
        room:        form.room,
        label:       `BLE · ${target.id.slice(-8)}`,
        config:      { bt_id: target.id, rssi: target.rssi },
      })
      setPaired(prev => new Set([...prev, target.id]))
      setTarget(null)
      setMsg({ text: `✓ "${form.name}" ${t.bt_added_ok}`, ok: true })
    } catch (e) {
      setMsg({ text: e?.response?.data?.detail || t.bt_save_error, ok: false })
    }
    setSaving(false)
  }

  const rssiBar   = r => r >= -60 ? '▂▄▆█' : r >= -75 ? '▂▄▆' : r >= -85 ? '▂▄' : '▂'
  const rssiColor = r => r >= -60 ? '#22c55e' : r >= -75 ? '#f59e0b' : '#ef4444'

  if (ready === false) {
    return (
      <div style={{ textAlign: 'center', padding: '40px 20px', color: '#475569' }}>
        <div style={{ fontSize: 48, marginBottom: 12 }}>🔵</div>
        <p style={{ fontSize: 14, marginBottom: 8 }}>{t.bt_not_available}</p>
        <p style={{ fontSize: 12, color: '#334155' }}>{t.bt_install_apk}</p>
      </div>
    )
  }

  return (
    <div>
      <button
        onClick={scanning ? stopScanBtn : startScan}
        disabled={ready === null}
        style={{
          ...btn(scanning ? '#7c3aed' : '#1d4ed8'), width: '100%', marginBottom: 12,
          fontSize: 15, opacity: ready === null ? 0.6 : 1,
        }}>
        {ready === null ? t.bt_initializing : scanning ? t.bt_stop_scan : t.bt_scan_btn}
      </button>

      {scanning && (
        <div style={{ textAlign: 'center', color: '#7c3aed', fontSize: 12, marginBottom: 14 }}>
          {t.bt_scanning}
          <ProgressBar color="#7c3aed" />
        </div>
      )}

      {msg && <Msg {...msg} />}

      {devices.length > 0 && (
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 10 }}>
          {t.net_found} <b style={{ color: '#f1f5f9' }}>{devices.length}</b> {t.net_devices_word}
        </div>
      )}

      {devices.length === 0 && !scanning && (
        <div style={{ textAlign: 'center', padding: '40px 0', color: '#475569' }}>
          <div style={{ fontSize: 40 }}>🔵</div>
          <p style={{ marginTop: 10, fontSize: 13 }}>{t.bt_empty_hint}</p>
        </div>
      )}

      {[...devices].sort((a, b) => b.rssi - a.rssi).map(dev => (
        <div key={dev.id} style={{
          ...card, display: 'flex', alignItems: 'center', gap: 10,
          marginBottom: 8,
          border: `1px solid ${paired.has(dev.id) ? '#22c55e33' : '#334155'}`,
          opacity: paired.has(dev.id) ? 0.65 : 1,
        }}>
          <span style={{ fontSize: 26, flexShrink: 0 }}>{dev.guess.icon}</span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontWeight: 700, fontSize: 14, color: '#f1f5f9', display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
              {dev.name}
              {paired.has(dev.id) && <Tag color="#22c55e" bg="#14532d22">{t.bt_added_tag}</Tag>}
            </div>
            <div style={{ fontSize: 11, color: '#475569', marginTop: 2 }}>
              {dev.id.slice(-17)} · {dev.guess.label}
            </div>
            <div style={{ fontSize: 11, color: rssiColor(dev.rssi) }}>
              {rssiBar(dev.rssi)} {dev.rssi} dBm
            </div>
          </div>
          {!paired.has(dev.id) && (
            <button onClick={() => openPair(dev)} style={btn('#1d4ed8', 10)}>
              + {t.add}
            </button>
          )}
        </div>
      ))}

      {target && (
        <div style={overlay}>
          <div style={modal}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
              <span style={{ fontSize: 30 }}>{target.guess.icon}</span>
              <div>
                <div style={{ fontWeight: 700, color: '#f1f5f9', fontSize: 15 }}>{target.name}</div>
                <div style={{ fontSize: 11, color: '#64748b' }}>{target.id} · {target.rssi} dBm</div>
              </div>
            </div>

            <label style={lbl}>{t.device_name}</label>
            <input value={form.name} autoFocus
              onChange={e => setForm({ ...form, name: e.target.value })}
              onKeyDown={e => e.key === 'Enter' && savePair()}
              style={inp} />

            <label style={lbl}>{t.device_type}</label>
            <select value={form.type} onChange={e => setForm({ ...form, type: e.target.value })} style={inp}>
              {DEV_TYPES.map(dt => <option key={dt.value} value={dt.value}>{dt.icon} {dt.label}</option>)}
            </select>

            <label style={lbl}>{t.net_room_area}</label>
            <select value={form.room} onChange={e => setForm({ ...form, room: e.target.value })} style={inp}>
              <option value="">{t.no_room}</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {msg && <Msg {...msg} />}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={savePair} disabled={saving}
                style={{ ...btn('#22c55e'), flex: 1, opacity: saving ? 0.7 : 1 }}>
                {saving ? t.saving : t.bt_add_to_system}
              </button>
              <button onClick={() => { setTarget(null); setMsg(null) }}
                style={btn('#475569')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════════════
   TAB 3 — Zigbee (Zigbee2MQTT + deCONZ + Hue)
══════════════════════════════════════════════════════════════════════════ */
const BRIDGE_COLORS = {
  zigbee2mqtt: { border: '#92400e', bg: '#1c1007', accent: '#f59e0b', icon: '🔶' },
  deconz:      { border: '#5b21b6', bg: '#120b2e', accent: '#a78bfa', icon: '🟣' },
  hue:         { border: '#78350f', bg: '#1c1007', accent: '#fcd34d', icon: '🟡' },
  unknown:     { border: '#334155', bg: '#1e293b', accent: '#64748b', icon: '❓' },
}

function ZigbeeScanner() {
  const { t, rtl } = useLang()
  const inp = makeInp(rtl)
  const DEV_TYPES = getDevTypes(t)

  const [status, setStatus]           = useState(null)
  const [scanning, setScanning]       = useState(false)
  const [bridges, setBridges]         = useState([])
  const [selectedBridge, setSelected] = useState(null)
  const [loadingDevs, setLoadingDevs] = useState(false)
  const [z2mDevices, setZ2mDevices]   = useState([])
  const [rooms, setRooms]             = useState([])
  const [msg, setMsg]                 = useState(null)
  const [target, setTarget]           = useState(null)
  const [form, setForm]               = useState({})
  const [saving, setSaving]           = useState(false)
  const [imported, setImported]       = useState(new Set())

  useEffect(() => {
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
    api.get('/zigbee/status').then(r => setStatus(r.data)).catch(() => {})
  }, [])

  const scan = async () => {
    setScanning(true); setMsg(null); setBridges([]); setZ2mDevices([]); setSelected(null)
    try {
      const r = await api.get('/zigbee/scan', { timeout: 20000 })
      setBridges(r.data.bridges || [])
      if (r.data.z2m_mqtt_active) {
        const z2m = r.data.bridges?.find(b => b.type === 'zigbee2mqtt')
        if (z2m) loadDevices(z2m, true)
      }
      if (!r.data.total)
        setMsg({ text: t.z2m_no_bridges, ok: false })
    } catch {
      setMsg({ text: t.net_scan_failed, ok: false })
    }
    setScanning(false)
  }

  const loadDevices = async (bridge, silent = false) => {
    if (!silent) { setSelected(bridge); setLoadingDevs(true); setZ2mDevices([]); setMsg(null) }
    try {
      const r = await api.get(
        `/zigbee/devices?bridge_type=${bridge.type}&bridge_ip=${bridge.ip}`,
        { timeout: 10000 }
      )
      setZ2mDevices(r.data.devices || [])
      if (r.data.hint && !silent) setMsg({ text: r.data.hint, ok: false })
    } catch { if (!silent) setMsg({ text: t.z2m_load_error, ok: false }) }
    setLoadingDevs(false)
  }

  const openImport = (dev) => {
    setTarget(dev)
    setForm({ name: dev.friendly_name, type: dev.hub_type, room: '' })
    setMsg(null)
  }

  const doImport = async () => {
    if (!form.name?.trim()) return
    setSaving(true)
    try {
      await api.post('/zigbee/import', {
        ieee_addr:     target.ieee_addr,
        friendly_name: target.friendly_name,
        hub_type:      form.type,
        room:          form.room,
        custom_name:   form.name,
        bridge_ip:     selectedBridge?.ip || '',
      })
      setImported(prev => new Set([...prev, target.ieee_addr]))
      setTarget(null)
      setMsg({ text: `✅ "${form.name}" ${t.z2m_imported_ok}`, ok: true })
    } catch (e) {
      setMsg({ text: e?.response?.data?.detail || t.z2m_import_error, ok: false })
    }
    setSaving(false)
  }

  const z2mActive = status?.z2m_active

  return (
    <div>
      {z2mActive && (
        <div style={{
          background: '#1c1007', border: '1px solid #f59e0b',
          borderRadius: 12, padding: '10px 14px', marginBottom: 14,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <span style={{ fontSize: 22 }}>🔶</span>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, color: '#fcd34d' }}>
              {t.z2m_active_label}
            </div>
            <div style={{ fontSize: 11, color: '#92400e' }}>
              {status.z2m_device_count} {t.z2m_devices_connected}
            </div>
          </div>
        </div>
      )}

      <div style={{
        background: '#0f172a', border: '1px solid #1e3a5f',
        borderRadius: 10, padding: '10px 14px', marginBottom: 14,
        fontSize: 11, color: '#64748b', lineHeight: 1.7,
      }}>
        <b style={{ color: '#f59e0b' }}>🔶 Zigbee</b> — 2.4GHz low-power wireless standard.{' '}
        Supported: <span style={{ color: '#f1f5f9' }}>Zigbee2MQTT · deCONZ/Phoscon · Philips Hue</span><br/>
        Compatible: Sonoff, Aqara, IKEA Tradfri, Philips Hue, Tuya, and thousands more.
      </div>

      {msg && <Msg {...msg} />}

      <button onClick={scan} disabled={scanning} style={{
        ...btn(scanning ? '#334155' : '#92400e'), width: '100%', marginBottom: 14,
        fontSize: 15, opacity: scanning ? 0.8 : 1,
      }}>
        {scanning ? `⏳ ${t.scanning}` : t.z2m_scan_btn}
      </button>

      {scanning && <ProgressBar color="#f59e0b" />}

      {bridges.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: '#64748b', fontWeight: 600, marginBottom: 8 }}>
            {t.net_found} {bridges.length} {t.z2m_found_bridges_word}
          </div>
          {bridges.map((bridge, i) => {
            const col = BRIDGE_COLORS[bridge.type] || BRIDGE_COLORS.unknown
            const isSel = selectedBridge?.ip === bridge.ip
            return (
              <div key={i} style={{
                background: col.bg, border: `1px solid ${isSel ? col.accent : col.border}`,
                borderRadius: 12, padding: '12px 14px', marginBottom: 8,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 26 }}>{col.icon}</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 700, fontSize: 14, color: col.accent }}>
                      {bridge.name}
                    </div>
                    <div style={{ fontSize: 11, color: '#64748b' }}>
                      {bridge.ip}:{bridge.port}
                      {bridge.confirmed ? ` · ${t.z2m_verified}` : ` · ${t.z2m_unverified}`}
                    </div>
                    {bridge.hint && (
                      <div style={{ fontSize: 10, color: '#475569', marginTop: 2 }}>
                        {bridge.hint}
                      </div>
                    )}
                  </div>
                  <button
                    onClick={() => loadDevices(bridge)}
                    disabled={loadingDevs}
                    style={{ ...btn(col.accent, 10, '#000'), fontSize: 11, whiteSpace: 'nowrap' }}>
                    {loadingDevs && isSel ? '⏳' : t.z2m_devices_btn}
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {selectedBridge && (
        <div>
          <div style={{ fontSize: 11, color: '#64748b', fontWeight: 600, marginBottom: 8 }}>
            {loadingDevs
              ? t.z2m_loading_devices
              : `📋 ${selectedBridge.name} (${z2mDevices.length})`}
          </div>
          {loadingDevs && <ProgressBar color="#f59e0b" />}

          {z2mDevices.length === 0 && !loadingDevs && (
            <div style={{ textAlign: 'center', padding: '20px 0', color: '#475569', fontSize: 13 }}>
              {t.z2m_no_devices_hint}
            </div>
          )}

          {z2mDevices.map(dev => (
            <div key={dev.ieee_addr} style={{
              ...card, marginBottom: 8,
              border: `1px solid ${imported.has(dev.ieee_addr) ? '#22c55e33' : '#334155'}`,
              opacity: imported.has(dev.ieee_addr) ? 0.65 : 1,
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <span style={{ fontSize: 24, flexShrink: 0 }}>{dev.icon}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: '#f1f5f9',
                              display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                  {dev.friendly_name}
                  {imported.has(dev.ieee_addr) && <Tag color="#22c55e" bg="#052e16">{t.z2m_imported_tag}</Tag>}
                  {!dev.supported && <Tag color="#ef4444" bg="#450a0a">{t.z2m_unsupported}</Tag>}
                  {!dev.interview_completed && <Tag color="#f59e0b" bg="#451a03">{t.z2m_not_completed}</Tag>}
                </div>
                <div style={{ fontSize: 11, color: '#64748b' }}>
                  {dev.vendor && `${dev.vendor} `}{dev.model}
                  {dev.power_source && ` · ${dev.power_source}`}
                  {dev.link_quality > 0 && ` · LQI: ${dev.link_quality}`}
                </div>
                {dev.description && (
                  <div style={{ fontSize: 10, color: '#475569', marginTop: 1 }}>{dev.description}</div>
                )}
              </div>
              {!imported.has(dev.ieee_addr) && dev.supported && (
                <button onClick={() => openImport(dev)}
                  style={{ ...btn('#f59e0b', 10, '#000'), fontSize: 11 }}>
                  {t.z2m_import_btn}
                </button>
              )}
            </div>
          ))}
        </div>
      )}

      {!scanning && bridges.length === 0 && z2mActive && !selectedBridge && (
        <div>
          <div style={{ fontSize: 11, color: '#64748b', fontWeight: 600, marginBottom: 8 }}>
            📋 {t.z2m_mqtt_section} ({status.z2m_device_count})
          </div>
          <button onClick={() => loadDevices({ type: 'zigbee2mqtt', ip: 'localhost', name: 'Zigbee2MQTT (MQTT)' })}
            style={{ ...btn('#92400e'), width: '100%', marginBottom: 12 }}>
            {t.z2m_load_btn}
          </button>
        </div>
      )}

      {target && (
        <div style={overlay}>
          <div style={modal}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
              <span style={{ fontSize: 28 }}>{target.icon}</span>
              <div>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#f1f5f9' }}>{target.friendly_name}</div>
                <div style={{ fontSize: 11, color: '#64748b' }}>
                  {target.vendor} {target.model} · {target.ieee_addr}
                </div>
              </div>
            </div>

            <label style={lbl}>{t.device_name}</label>
            <input value={form.name} autoFocus
              onChange={e => setForm({ ...form, name: e.target.value })}
              style={inp} />

            <label style={lbl}>{t.device_type}</label>
            <select value={form.type} onChange={e => setForm({ ...form, type: e.target.value })} style={inp}>
              {DEV_TYPES.map(dt => <option key={dt.value} value={dt.value}>{dt.icon} {dt.label}</option>)}
            </select>

            <label style={lbl}>{t.net_room_area}</label>
            <select value={form.room} onChange={e => setForm({ ...form, room: e.target.value })} style={inp}>
              <option value="">{t.no_room}</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {msg && <Msg {...msg} />}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={doImport} disabled={saving}
                style={{ ...btn('#f59e0b', 18, '#000'), flex: 1, opacity: saving ? 0.7 : 1 }}>
                {saving ? t.z2m_importing : t.z2m_import_to_system}
              </button>
              <button onClick={() => { setTarget(null); setMsg(null) }}
                style={btn('#334155')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════════════
   TAB 4 — Matter
══════════════════════════════════════════════════════════════════════════ */
function MatterScanner() {
  const { t, rtl } = useLang()
  const inp = makeInp(rtl)
  const MATTER_TYPES = getMatterTypes(t)

  const [status, setStatus]         = useState(null)
  const [scanning, setScanning]     = useState(false)
  const [found, setFound]           = useState(null)
  const [rooms, setRooms]           = useState([])
  const [msg, setMsg]               = useState(null)

  const [showModal, setShowModal]   = useState(false)
  const [codeInput, setCodeInput]   = useState('')
  const [devName, setDevName]       = useState('')
  const [devType, setDevType]       = useState('switch')
  const [devRoom, setDevRoom]       = useState('')
  const [saving, setSaving]         = useState(false)

  useEffect(() => {
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
    api.get('/matter/status').then(r => setStatus(r.data)).catch(() => {})
  }, [])

  const scan = async () => {
    setScanning(true); setMsg(null); setFound(null)
    try {
      const r = await api.get('/matter/scan', { timeout: 8000 })
      setFound(r.data)
      if (r.data.total === 0)
        setMsg({ text: t.matter_no_devices, ok: false })
    } catch {
      setMsg({ text: t.net_scan_failed, ok: false })
    }
    setScanning(false)
  }

  const openCommission = (dev = null) => {
    setDevName(dev?.name || '')
    setDevType(dev?.hub_type || 'switch')
    setCodeInput('')
    setDevRoom('')
    setMsg(null)
    setShowModal(true)
  }

  const doCommission = async () => {
    if (!codeInput.trim()) { setMsg({ text: t.matter_enter_code, ok: false }); return }
    setSaving(true); setMsg(null)
    try {
      const r = await api.post('/matter/commission', {
        code: codeInput.trim(), name: devName, dev_type: devType, room: devRoom,
      }, { timeout: 30000 })
      setMsg({ text: `✅ "${devName || t.dev_type_switch}" ${t.matter_paired_ok} (Node ${r.data.node_id})`, ok: true })
      setShowModal(false)
      setFound(null)
      api.get('/matter/status').then(r2 => setStatus(r2.data)).catch(() => {})
    } catch (e) {
      setMsg({ text: e?.response?.data?.detail || t.matter_pair_failed, ok: false })
    }
    setSaving(false)
  }

  const removeNode = async (nodeId, name) => {
    if (!confirm(`${t.matter_remove_confirm_prefix} "${name}"?`)) return
    try {
      await api.delete(`/matter/nodes/${nodeId}`)
      api.get('/matter/status').then(r => setStatus(r.data)).catch(() => {})
      setMsg({ text: `"${name}" ${t.delete}`, ok: true })
    } catch (e) {
      setMsg({ text: e?.response?.data?.detail || t.matter_remove_error, ok: false })
    }
  }

  const serverOk = status?.server_available

  return (
    <div>
      <div style={{
        background: serverOk ? '#0c2340' : '#1c1917',
        border: `1px solid ${serverOk ? '#1d4ed8' : '#78350f'}`,
        borderRadius: 12, padding: '10px 14px', marginBottom: 14,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 22 }}>🔷</span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: serverOk ? '#38bdf8' : '#f59e0b' }}>
              Matter Server {serverOk ? t.matter_active : t.matter_inactive}
            </div>
            <div style={{ fontSize: 10, color: '#475569' }}>
              {serverOk
                ? `${status.node_count} ${t.matter_nodes_count}`
                : t.matter_server_required}
            </div>
          </div>
          {!serverOk && (
            <button onClick={() => setMsg({
              text: 'Run: pip install python-matter-server\nThen: python -m matter_server --storage-path ./matter_data',
              ok: false
            })} style={{ ...btn('#334155', 10), fontSize: 10 }}>
              {t.how_btn}
            </button>
          )}
        </div>
      </div>

      <div style={{
        background: '#0f172a', border: '1px solid #1e3a5f',
        borderRadius: 10, padding: '10px 14px', marginBottom: 14, fontSize: 11,
        color: '#64748b', lineHeight: 1.7,
      }}>
        <b style={{ color: '#38bdf8' }}>🔷 Matter</b> — smart home standard for Apple, Google, Amazon &amp; Samsung.
        {' '}WiFi, Thread, and direct connection — no cloud required.<br/>
        <span style={{ color: '#22c55e' }}>✓ Apple Home · Google Home · SmartThings · Amazon Echo</span>
      </div>

      {msg && <Msg {...msg} />}

      <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
        <button onClick={scan} disabled={scanning} style={{
          ...btn('#1d4ed8'), flex: 1, opacity: scanning ? 0.7 : 1,
        }}>
          {scanning ? t.matter_scanning : t.matter_scan_btn}
        </button>
        <button onClick={() => openCommission()} style={{ ...btn('#7c3aed'), flex: 1 }}>
          {t.matter_commission_btn}
        </button>
      </div>

      {scanning && <ProgressBar color="#7c3aed" />}

      {found?.uncommissioned?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: '#f59e0b', fontWeight: 700, marginBottom: 8 }}>
            {t.matter_ready_to_pair} ({found.uncommissioned.length})
          </div>
          {found.uncommissioned.map((d, i) => (
            <div key={i} style={{
              ...card, marginBottom: 8, border: '1px solid #92400e',
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <span style={{ fontSize: 24 }}>🔷</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: '#f1f5f9' }}>{d.name}</div>
                <div style={{ fontSize: 10, color: '#64748b' }}>
                  {d.device_type_name} · {d.ip || '...'}
                  {d.discriminator && ` · D:${d.discriminator}`}
                </div>
              </div>
              <button onClick={() => openCommission(d)}
                style={{ ...btn('#f59e0b', 10), fontSize: 11 }}>
                {t.matter_pair_btn}
              </button>
            </div>
          ))}
        </div>
      )}

      {found?.commissioned?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: '#22c55e', fontWeight: 700, marginBottom: 8 }}>
            {t.matter_already_paired} ({found.commissioned.length})
          </div>
          {found.commissioned.map((d, i) => (
            <div key={i} style={{
              ...card, marginBottom: 8, border: '1px solid #22c55e33',
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <span style={{ fontSize: 22 }}>🔷</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: '#f1f5f9' }}>{d.name}</div>
                <div style={{ fontSize: 10, color: '#64748b' }}>{d.device_type_name} · {d.ip}</div>
              </div>
              <Tag color="#22c55e" bg="#052e16">{t.net_paired_tag}</Tag>
            </div>
          ))}
        </div>
      )}

      {serverOk && status?.nodes?.length > 0 && (
        <div>
          <div style={{ fontSize: 11, color: '#64748b', fontWeight: 700, marginBottom: 8 }}>
            {t.matter_system_nodes} ({status.nodes.length})
          </div>
          {status.nodes.map(n => (
            <div key={n.node_id} style={{
              ...card, marginBottom: 8, padding: '10px 12px',
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <span style={{ fontSize: 20 }}>🔷</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 700, color: '#f1f5f9' }}>Node {n.node_id}</div>
                <div style={{ fontSize: 10, color: n.available ? '#22c55e' : '#ef4444' }}>
                  {n.available ? `● ${t.connected}` : `○ ${t.disconnected}`}
                </div>
              </div>
              <button onClick={() => removeNode(n.node_id, `Node ${n.node_id}`)}
                style={{ ...btn('#7f1d1d', 8), fontSize: 10 }}>🗑️</button>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <div style={overlay}>
          <div style={modal}>
            <h3 style={{ margin: '0 0 12px', color: '#f1f5f9', fontSize: 16 }}>
              {t.matter_modal_title}
            </h3>

            {!serverOk && (
              <div style={{
                background: '#7f1d1d', border: '1px solid #ef4444',
                borderRadius: 8, padding: '8px 12px', fontSize: 11,
                color: '#fca5a5', marginBottom: 12, lineHeight: 1.6,
              }}>
                ⚠️ python-matter-server not running.<br/>
                Run in terminal:<br/>
                <code style={{ color: '#fcd34d' }}>pip install python-matter-server</code><br/>
                <code style={{ color: '#fcd34d' }}>python -m matter_server --storage-path ./matter_data</code>
              </div>
            )}

            <div style={{
              background: '#0f172a', borderRadius: 8, padding: '8px 12px',
              fontSize: 11, color: '#64748b', marginBottom: 12, lineHeight: 1.7,
            }}>
              📲 <b style={{ color: '#f1f5f9' }}>How to get pairing code:</b><br/>
              • Scan the QR code on the device<br/>
              • Or enter the 11-digit number printed on the device
            </div>

            <label style={lbl}>{t.matter_code_label}</label>
            <input value={codeInput} autoFocus
              onChange={e => setCodeInput(e.target.value)}
              placeholder="MT:Y.K90... or 12345678901"
              style={{ ...inp, direction: 'ltr' }} />

            <label style={lbl}>{t.device_name}</label>
            <input value={devName}
              onChange={e => setDevName(e.target.value)}
              style={inp} />

            <label style={lbl}>{t.device_type}</label>
            <select value={devType} onChange={e => setDevType(e.target.value)} style={inp}>
              {MATTER_TYPES.map(mt => (
                <option key={mt.value} value={mt.value}>{mt.icon} {mt.label}</option>
              ))}
            </select>

            <label style={lbl}>{t.device_room}</label>
            <select value={devRoom} onChange={e => setDevRoom(e.target.value)} style={inp}>
              <option value="">{t.no_room}</option>
              {rooms.map(r => <option key={r.id} value={r.id}>{r.icon} {r.name}</option>)}
            </select>

            {msg && <Msg {...msg} />}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={doCommission} disabled={saving || !serverOk}
                style={{ ...btn(serverOk ? '#7c3aed' : '#334155'), flex: 1, opacity: saving ? 0.7 : 1 }}>
                {saving ? t.matter_commissioning : t.matter_pair_btn}
              </button>
              <button onClick={() => { setShowModal(false); setMsg(null) }}
                style={btn('#334155')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════════════
   TAB 5 — WiFi Scanner & Manager
══════════════════════════════════════════════════════════════════════════ */
function SigIcon({ pct, size = 22 }) {
  const c = pct >= 65 ? '#22c55e' : pct >= 35 ? '#f59e0b' : '#ef4444'
  const bars = [25, 50, 75, 100]
  return (
    <svg width={size} height={size} viewBox="0 0 22 18" style={{ flexShrink: 0 }}>
      {bars.map((threshold, i) => (
        <rect key={i}
          x={i * 5 + 1} y={18 - (i + 1) * 4}
          width={4} height={(i + 1) * 4}
          rx={1}
          fill={pct >= threshold ? c : '#334155'}
        />
      ))}
    </svg>
  )
}

function WifiManager() {
  const { t, rtl, locale } = useLang()
  const inp = makeInp(rtl)

  const [status, setStatus]         = useState(null)
  const [networks, setNetworks]     = useState([])
  const [saved, setSaved]           = useState([])
  const [rooms, setRooms]           = useState([])
  const [scanning, setScanning]     = useState(false)
  const [lastScan, setLastScan]     = useState(null)
  const [selected, setSelected]     = useState(null)
  const [password, setPassword]     = useState('')
  const [showPass, setShowPass]     = useState(false)
  const [saveConn, setSaveConn]     = useState(true)
  const [autoConn, setAutoConn]     = useState(true)
  const [selRoom, setSelRoom]       = useState('')
  const [connecting, setConnecting] = useState(false)
  const [msg, setMsg]               = useState(null)
  const [manualSsid, setManualSsid] = useState('')
  const [showManual, setShowManual] = useState(false)
  const [showSaved, setShowSaved]   = useState(false)
  const [retrying, setRetrying]     = useState(false)

  const reloadSaved  = () => api.get('/network/saved').then(r => setSaved(r.data)).catch(() => {})
  const reloadStatus = () => api.get('/network/status').then(r => setStatus(r.data)).catch(() => {})

  useEffect(() => {
    reloadStatus()
    reloadSaved()
    api.get('/rooms/').then(r => setRooms(r.data)).catch(() => {})
    scan()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const scan = async (isRetry = false) => {
    if (!isRetry) { setNetworks([]); setShowManual(false); setMsg(null) }
    setScanning(true)
    try {
      const r = await api.get('/network/scan', { timeout: 22000 })
      const nets = r.data.filter(n => n.ssid !== '__wifi_disabled__')
      const wifiDisabled = r.data.some(n => n.ssid === '__wifi_disabled__')

      if (wifiDisabled) {
        setMsg({ text: t.wifi_adapter_off, ok: false })
        setShowManual(true)
        setScanning(false)
        return
      }

      setNetworks(nets)
      setLastScan(new Date())

      if (!nets.length && !isRetry) {
        setRetrying(true)
        setTimeout(async () => {
          setRetrying(false)
          await scan(true)
        }, 2500)
        return
      }

      if (!nets.length) setShowManual(true)
    } catch {
      if (!isRetry) {
        setRetrying(true)
        setTimeout(async () => {
          setRetrying(false)
          await scan(true)
        }, 2000)
        return
      }
      setShowManual(true)
    }
    setScanning(false)
  }

  const openConnect = (net) => {
    const savedProfile = saved.find(s => s.ssid === net.ssid)
    setSelected(net)
    setPassword('')
    setShowPass(false)
    setSaveConn(true)
    setAutoConn(savedProfile?.auto_connect ?? true)
    setSelRoom(savedProfile?.room || '')
    setMsg(null)
  }

  const connect = async () => {
    if (selected?.secured && !password) { setMsg({ text: t.wifi_enter_password, ok: false }); return }
    setConnecting(true)
    try {
      await api.post('/network/connect', {
        ssid: selected.ssid, password,
        save: saveConn, auto_connect: autoConn, room: selRoom || null,
      })
      setMsg({ text: `✅ ${t.wifi_connected_ok} ${selected.ssid}`, ok: true })
      setSelected(null)
      reloadStatus()
      if (saveConn) reloadSaved()
    } catch (e) {
      setMsg({ text: e?.response?.data?.detail || t.wifi_conn_failed, ok: false })
    }
    setConnecting(false)
  }

  const removeSaved = async (ssid) => {
    if (!confirm(`${t.delete} "${ssid}" ${t.wifi_remove_confirm}`)) return
    await api.delete(`/network/saved/${encodeURIComponent(ssid)}`)
    reloadSaved()
  }

  const movePriority = async (ssid, delta) => {
    const idx   = saved.findIndex(s => s.ssid === ssid)
    const p     = saved[idx]
    const other = saved[idx + delta]
    if (!other) return
    await Promise.all([
      api.put(`/network/saved/${encodeURIComponent(ssid)}/priority`,       { priority: other.priority }),
      api.put(`/network/saved/${encodeURIComponent(other.ssid)}/priority`, { priority: p.priority }),
    ])
    reloadSaved()
  }

  const toggleAutoConnect = async (ssid, current) => {
    await api.put(`/network/saved/${encodeURIComponent(ssid)}/auto-connect`, { auto_connect: !current })
    reloadSaved()
  }

  const connectManual = () => {
    if (!manualSsid.trim()) return
    openConnect({ ssid: manualSsid.trim(), secured: true, signal: 0, band: null })
    setManualSsid(''); setShowManual(false)
  }

  const isCurrent = s => status?.ssid === s
  const savedMap  = saved.reduce((m, s) => { m[s.ssid] = s; return m }, {})
  const isSaved   = s => !!savedMap[s]

  const nets5   = networks.filter(n => n.band === '5')
  const nets24  = networks.filter(n => n.band === '2.4')
  const netsOth = networks.filter(n => !n.band || (n.band !== '5' && n.band !== '2.4'))
  const hasDual = nets5.length > 0 && nets24.length > 0

  return (
    <div>
      {/* ── Current connection card ── */}
      <div style={{
        background: status?.connected ? '#0a2016' : '#1c1007',
        border: `2px solid ${status?.connected ? '#22c55e' : '#475569'}`,
        borderRadius: 16, padding: '14px 16px', marginBottom: 16,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {status?.connected
            ? <SigIcon pct={status.signal} size={30} />
            : <span style={{ fontSize: 28 }}>📵</span>
          }
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 15, fontWeight: 800, color: status?.connected ? '#22c55e' : '#64748b' }}>
              {status == null ? '...' : status.connected ? status.ssid : t.disconnected}
            </div>
            {status?.connected && (
              <div style={{ fontSize: 12, color: '#475569', marginTop: 2 }}>
                {t.wifi_hub_connected_label} {status.signal}%
              </div>
            )}
          </div>
          {status?.connected && (
            <span style={{
              fontSize: 10, padding: '3px 9px', borderRadius: 20,
              background: '#14532d', color: '#86efac', fontWeight: 700,
            }}>● {t.connected}</span>
          )}
        </div>
      </div>

      {msg && !selected && <Msg {...msg} />}

      {/* ── Scan button ── */}
      <button onClick={scan} disabled={scanning} style={{
        width: '100%', padding: '13px 0', borderRadius: 12, border: 'none',
        background: scanning ? '#1e293b' : '#1d4ed8',
        color: scanning ? '#64748b' : '#fff',
        fontWeight: 700, fontSize: 15, cursor: scanning ? 'default' : 'pointer',
        marginBottom: 12,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        {scanning ? (
          <>
            <span style={{ display: 'inline-block', animation: 'spin 1s linear infinite' }}>🔄</span>
            {t.wifi_scanning_label}
            <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
          </>
        ) : (
          <>{t.wifi_scan_btn}</>
        )}
      </button>

      {scanning && <ProgressBar />}

      {retrying && !scanning && (
        <div style={{ textAlign: 'center', color: '#f59e0b', fontSize: 12, marginBottom: 10 }}>
          {t.wifi_retrying}
          <ProgressBar color="#f59e0b" />
        </div>
      )}

      {lastScan && !scanning && !retrying && (
        <div style={{ fontSize: 10, color: '#334155', textAlign: 'center', marginBottom: 10 }}>
          {t.wifi_last_scan} {lastScan.toLocaleTimeString(locale)} · {networks.length} {t.wifi_networks_count}
        </div>
      )}

      {/* ── Manual SSID input ── */}
      {showManual && (
        <div style={{
          background: '#1e293b', border: '1px dashed #334155',
          borderRadius: 12, padding: 14, marginBottom: 14,
        }}>
          <div style={{ fontSize: 12, color: '#64748b', marginBottom: 8 }}>
            {t.wifi_manual_hint}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <input value={manualSsid} onChange={e => setManualSsid(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && connectManual()}
              placeholder={t.wifi_ssid_placeholder}
              style={{ ...inp, marginBottom: 0, flex: 1 }} />
            <button onClick={connectManual} style={btn('#1d4ed8')}>➜</button>
          </div>
        </div>
      )}

      {/* ── Dual-band notice ── */}
      {hasDual && (
        <div style={{
          background: '#1c1007', border: '1px solid #78350f',
          borderRadius: 10, padding: '10px 13px', marginBottom: 14,
          fontSize: 12, color: '#92400e', lineHeight: 1.7,
        }}>
          <b style={{ color: '#f59e0b' }}>{t.wifi_dual_band}</b>
          {' '}{t.wifi_iot_24ghz}
        </div>
      )}

      {/* ── Networks list ── */}
      {networks.length > 0 && (
        <div style={{ marginBottom: 20 }}>
          <div style={{ fontSize: 11, color: '#64748b', fontWeight: 600, marginBottom: 10 }}>
            {t.wifi_available_networks} — {networks.length} {t.net_found?.toLowerCase() || 'found'}
          </div>

          {nets24.length > 0 && (
            <>
              {hasDual && (
                <div style={{ fontSize: 10, color: '#22c55e', fontWeight: 700, marginBottom: 6, marginTop: 4, letterSpacing: 1 }}>
                  {t.wifi_24ghz_label}
                </div>
              )}
              {nets24.map(n => <NetRow key={n.ssid} n={n} isCurrent={isCurrent} isSaved={isSaved} onConnect={openConnect} t={t} />)}
            </>
          )}

          {nets5.length > 0 && (
            <>
              {hasDual && (
                <div style={{ fontSize: 10, color: '#a78bfa', fontWeight: 700, marginBottom: 6, marginTop: 10, letterSpacing: 1 }}>
                  {t.wifi_5ghz_label}
                </div>
              )}
              {nets5.map(n => <NetRow key={n.ssid} n={n} isCurrent={isCurrent} isSaved={isSaved} onConnect={openConnect} t={t} />)}
            </>
          )}

          {netsOth.map(n => <NetRow key={n.ssid} n={n} isCurrent={isCurrent} isSaved={isSaved} onConnect={openConnect} t={t} />)}
        </div>
      )}

      {/* ── Saved profiles ── */}
      {saved.length > 0 && (
        <div>
          <button onClick={() => setShowSaved(v => !v)} style={{
            width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #334155',
            background: '#1e293b', color: '#94a3b8', cursor: 'pointer',
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            fontSize: 13, fontWeight: 600, marginBottom: showSaved ? 10 : 0,
          }}>
            <span>{t.wifi_saved_routers_label} ({saved.length})</span>
            <span>{showSaved ? '▲' : '▼'}</span>
          </button>

          {showSaved && saved.map((s, idx) => (
            <div key={s.ssid} style={{
              ...card, marginBottom: 8, padding: '10px 12px',
              border: `1px solid ${isCurrent(s.ssid) ? '#22c55e' : '#334155'}`,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <button onClick={() => movePriority(s.ssid, -1)} disabled={idx === 0}
                    style={{ ...arrowBtn, opacity: idx === 0 ? 0.2 : 1 }}>▲</button>
                  <button onClick={() => movePriority(s.ssid, 1)} disabled={idx === saved.length - 1}
                    style={{ ...arrowBtn, opacity: idx === saved.length - 1 ? 0.2 : 1 }}>▼</button>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 700, fontSize: 13, color: '#f1f5f9' }}>{s.ssid}</span>
                    {isCurrent(s.ssid) && <Tag color="#22c55e" bg="#052e16">● {t.connected}</Tag>}
                    {idx === 0 && !isCurrent(s.ssid) && <Tag color="#f59e0b" bg="#451a0322">{t.wifi_priority_tag}</Tag>}
                  </div>
                  <div style={{ fontSize: 10, color: '#475569', marginTop: 2 }}>
                    {(() => {
                      const live = networks.find(n => n.ssid === s.ssid)
                      return live
                        ? `${sigBar(live.signal)} ${live.signal}% — ${t.wifi_available_now}`
                        : t.wifi_not_in_scan
                    })()}
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <label style={{
                  display: 'flex', alignItems: 'center', gap: 5,
                  fontSize: 11, color: s.auto_connect ? '#22c55e' : '#475569',
                  cursor: 'pointer', flex: 1,
                }}>
                  <input type="checkbox" checked={!!s.auto_connect}
                    onChange={() => toggleAutoConnect(s.ssid, s.auto_connect)}
                    style={{ accentColor: '#22c55e', width: 13, height: 13 }} />
                  {t.auto_connect}
                </label>
                <button onClick={() => openConnect({ ssid: s.ssid, secured: true, signal: 0, band: null })}
                  style={{ ...btn('#1d4ed8', 8), fontSize: 11 }}>🔗</button>
                <button onClick={() => removeSaved(s.ssid)}
                  style={{ ...btn('#7f1d1d', 8), fontSize: 11 }}>🗑️</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Connect modal ── */}
      {selected && (
        <div style={overlay}>
          <div style={modal}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16,
              padding: '12px 14px', background: '#0f172a', borderRadius: 10,
            }}>
              <SigIcon pct={selected.signal || 50} size={28} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 800, fontSize: 16, color: '#f1f5f9' }}>{selected.ssid}</div>
                <div style={{ fontSize: 11, color: '#64748b', marginTop: 2, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {selected.secured ? t.wifi_secured : t.wifi_open_badge}
                  {selected.signal > 0 && ` · ${selected.signal}%`}
                  {selected.band === '5'   && <span style={{ color: '#a78bfa' }}>⚡ 5GHz</span>}
                  {selected.band === '2.4' && <span style={{ color: '#22c55e' }}>✓ 2.4GHz</span>}
                </div>
              </div>
            </div>

            {selected.band === '5' && (
              <div style={{
                background: '#1c1917', border: '1px solid #78350f',
                borderRadius: 8, padding: '8px 12px', fontSize: 12,
                color: '#fcd34d', marginBottom: 14, lineHeight: 1.6,
              }}>
                {t.wifi_5ghz_warning}
              </div>
            )}

            {selected.secured && (
              <>
                <label style={lbl}>{t.wifi_password_label}</label>
                <div style={{ position: 'relative', marginBottom: 12 }}>
                  <input type={showPass ? 'text' : 'password'} value={password}
                    onChange={e => setPassword(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && connect()}
                    placeholder={t.wifi_enter_password} autoFocus
                    style={{ ...inp, marginBottom: 0, paddingLeft: 44, direction: 'ltr' }} />
                  <button onClick={() => setShowPass(v => !v)} style={{
                    position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)',
                    background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#475569',
                  }}>{showPass ? '🙈' : '👁'}</button>
                </div>
              </>
            )}

            <label style={{ ...checkLbl, marginBottom: 8 }}>
              <input type="checkbox" checked={saveConn} onChange={e => setSaveConn(e.target.checked)}
                style={{ accentColor: '#38bdf8', width: 14, height: 14 }} />
              <span style={{ color: '#94a3b8', fontSize: 13 }}>{t.wifi_save_next}</span>
            </label>
            {saveConn && (
              <label style={{ ...checkLbl, marginBottom: 14 }}>
                <input type="checkbox" checked={autoConn} onChange={e => setAutoConn(e.target.checked)}
                  style={{ accentColor: '#22c55e', width: 14, height: 14 }} />
                <span style={{ color: autoConn ? '#22c55e' : '#94a3b8', fontSize: 13 }}>{t.wifi_auto_on_start}</span>
              </label>
            )}

            {msg && <Msg {...msg} />}

            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={connect} disabled={connecting}
                style={{ ...btn('#1d4ed8'), flex: 1, opacity: connecting ? 0.7 : 1 }}>
                {connecting ? t.wifi_connecting_btn : t.wifi_connect_btn_label}
              </button>
              <button onClick={() => { setSelected(null); setMsg(null) }} style={btn('#475569')}>{t.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/* Single network row */
function NetRow({ n, isCurrent, isSaved, onConnect, t }) {
  const cur   = isCurrent(n.ssid)
  const saved = isSaved(n.ssid)
  return (
    <div onClick={() => !cur && onConnect(n)}
      style={{
        display: 'flex', alignItems: 'center', gap: 12,
        background: cur ? '#0a2016' : '#1e293b',
        border: `1px solid ${cur ? '#22c55e' : saved ? '#1d4ed8' : '#334155'}`,
        borderRadius: 12, padding: '12px 14px', marginBottom: 8,
        cursor: cur ? 'default' : 'pointer',
        transition: 'border-color .15s',
      }}>
      <SigIcon pct={n.signal} size={22} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#f1f5f9', display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 5, marginBottom: 3 }}>
          {n.ssid}
          {cur  && <Tag color="#22c55e" bg="#052e16">● {t.connected}</Tag>}
          {saved && !cur && <Tag color="#38bdf8" bg="#0c2a4a">{t.wifi_saved_tag}</Tag>}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: '#475569' }}>
          <span>{n.secured ? t.wifi_secured : t.wifi_open_badge}</span>
          {n.band === '5'   && <span style={{ color: '#a78bfa', fontWeight: 600 }}>⚡ 5GHz</span>}
          {n.band === '2.4' && <span style={{ color: '#22c55e', fontWeight: 600 }}>✓ 2.4GHz</span>}
          <span style={{ color: n.signal >= 65 ? '#22c55e' : n.signal >= 35 ? '#f59e0b' : '#ef4444' }}>
            {n.signal}%
          </span>
        </div>
      </div>
      {!cur && (
        <span style={{ fontSize: 18, color: '#38bdf8' }}>›</span>
      )}
    </div>
  )
}

/* ── Shared ──────────────────────────────────────────────────────────────── */
function Msg({ text, ok }) {
  return (
    <div style={{
      margin: '0 0 12px', padding: '10px 14px', borderRadius: 10, fontSize: 13,
      background: ok ? '#14532d' : '#7f1d1d',
      border: `1px solid ${ok ? '#22c55e' : '#ef4444'}`, color: '#f1f5f9',
      whiteSpace: 'pre-wrap',
    }}>{text}</div>
  )
}

function Tag({ color, bg, children }) {
  return (
    <span style={{ marginRight: 6, fontSize: 10, color, background: bg, padding: '1px 7px', borderRadius: 6 }}>
      {children}
    </span>
  )
}

const card     = { background: '#1e293b', border: '1px solid #334155', borderRadius: 12, padding: '12px 14px' }
const btn      = (bg, px = 18, color = '#fff') => ({
  padding: `9px ${px}px`, borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const arrowBtn = {
  padding: '1px 5px', background: '#0f172a', border: '1px solid #334155',
  borderRadius: 4, color: '#64748b', cursor: 'pointer', fontSize: 10, lineHeight: 1.2,
}
const checkLbl = { display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 12 }
const inpBase  = {
  width: '100%', padding: '10px 12px', marginBottom: 10, borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 14, boxSizing: 'border-box',
}
const makeInp  = (rtl) => ({ ...inpBase, direction: rtl ? 'rtl' : 'ltr' })
const lbl      = { display: 'block', fontSize: 12, color: '#94a3b8', marginBottom: 5 }
const overlay  = { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }
const modal    = { background: '#1e293b', border: '1px solid #334155', borderRadius: 16, padding: 24, width: '90%', maxWidth: 380, maxHeight: '90vh', overflowY: 'auto' }
