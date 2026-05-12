import { useState, useEffect, useRef } from 'react'
import { api, getHubUrl } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

const STORAGE_KEY = 'fantatech_cameras'
const HUB_PROXY   = () => `${getHubUrl()}/api/camera`

function loadCameras() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || [] } catch { return [] }
}
function saveCameras(cams) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(cams))
}

/* proxy URL so browser can load RTSP / cross-origin snapshots */
function proxySnap(url, user, pass) {
  if (!url) return null
  const q = new URLSearchParams({ url })
  if (user) q.set('username', user)
  if (pass) q.set('password', pass)
  return `${HUB_PROXY()}/snapshot/proxy?${q}`
}

function mjpegProxy(rtspUrl) {
  if (!rtspUrl) return null
  return `${HUB_PROXY()}/stream/mjpeg?url=${encodeURIComponent(rtspUrl)}`
}

/* ── Snapshot tile that auto-refreshes ── */
function SnapshotTile({ src, name, height = 160 }) {
  const [ts, setTs] = useState(Date.now())
  const [err, setErr] = useState(false)
  useEffect(() => {
    if (!src) return
    setErr(false)
    const id = setInterval(() => setTs(Date.now()), 5000)
    return () => clearInterval(id)
  }, [src])
  if (!src || err) return (
    <div style={{ height, background: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 8, borderRadius: 10 }}>
      <span style={{ fontSize: 36 }}>📷</span>
      <span style={{ fontSize: 11, color: '#475569' }}>{err ? 'No signal' : 'No URL'}</span>
    </div>
  )
  return (
    <div style={{ height, borderRadius: 10, overflow: 'hidden', background: '#000' }}>
      <img src={`${src}&_t=${ts}`} alt={name}
        onError={() => setErr(true)}
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
    </div>
  )
}

/* ── MJPEG stream tile ── */
function MJPEGTile({ src, name, height = 160 }) {
  const [err, setErr] = useState(false)
  if (!src || err) return (
    <div style={{ height, background: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 8, borderRadius: 10 }}>
      <span style={{ fontSize: 36 }}>📡</span>
      <span style={{ fontSize: 11, color: '#475569' }}>{err ? 'Stream error' : 'No stream'}</span>
    </div>
  )
  return (
    <div style={{ height, borderRadius: 10, overflow: 'hidden', background: '#000' }}>
      <img src={src} alt={name} onError={() => setErr(true)}
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
    </div>
  )
}

/* ── Full-screen modal ── */
function FullscreenModal({ cam, onClose }) {
  const h = Math.floor(window.innerHeight * 0.6)
  const snap = cam.snapshotUrl ? proxySnap(cam.snapshotUrl, cam.username, cam.password) : null
  const mjpeg = cam.mjpegProxyUrl || (cam.rtspUrl ? mjpegProxy(cam.rtspUrl) : null)
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,.92)', zIndex: 999, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div onClick={e => e.stopPropagation()} style={{ width: '100%', maxWidth: 600 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <span style={{ color: '#e2e8f0', fontWeight: 700, fontSize: 16 }}>📷 {cam.name}</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#94a3b8', fontSize: 24, cursor: 'pointer' }}>✕</button>
        </div>
        {mjpeg
          ? <MJPEGTile src={mjpeg} name={cam.name} height={h} />
          : <SnapshotTile src={snap} name={cam.name} height={h} />
        }
        {cam.rtspUrl && (
          <div style={{ fontSize: 10, color: '#334155', marginTop: 8, direction: 'ltr', wordBreak: 'break-all' }}>
            🎞 {cam.rtspUrl}
          </div>
        )}
      </div>
    </div>
  )
}

/* ── Add / Edit form ── */
const BLANK = {
  id: null, name: '', driver: 'hikvision',
  ip: '', port: 80, rtspPort: 554,
  username: 'admin', password: '',
  channel: 1, subtype: 0,
  customPath: '', customUrl: '',
}

function CameraForm({ cam, drivers, hasMjpeg, onSave, onCancel, t }) {
  const [form, setForm] = useState({ ...BLANK, ...cam })
  const [testing, setTesting] = useState(false)
  const [testResult, setTestResult] = useState(null)
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const driverMeta = drivers.find(d => d.id === form.driver) || {}

  const runTest = async () => {
    setTesting(true); setTestResult(null)
    try {
      const r = await api.post('/camera/test', {
        driver: form.driver,
        ip: form.ip,
        port: Number(form.port),
        username: form.username,
        password: form.password,
        rtsp_port: Number(form.rtspPort),
        channel: Number(form.channel),
        subtype: Number(form.subtype),
        custom_path: form.customPath,
        custom_url: form.customUrl,
      })
      setTestResult(r.data)
      if (r.data.rtsp_url) set('rtspUrl', r.data.rtsp_url)
      if (r.data.snapshot_url) set('snapshotUrl', r.data.snapshot_url)
      if (r.data.mjpeg_proxy_url) set('mjpegProxyUrl', r.data.mjpeg_proxy_url)
    } catch (e) {
      setTestResult({ error: String(e) })
    }
    setTesting(false)
  }

  const doSave = () => {
    if (!form.name || !form.ip) return
    onSave({ ...form, id: form.id ?? Date.now().toString() })
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,.75)', zIndex: 200, display: 'flex', alignItems: 'flex-end' }}>
      <div style={{ background: '#1e293b', borderRadius: '16px 16px 0 0', padding: 20, width: '100%', maxHeight: '88vh', overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <h3 style={{ margin: 0, color: '#f1f5f9', fontSize: 16 }}>
            {form.id ? t.camera_edit_title : t.camera_add_title}
          </h3>
          <button onClick={onCancel} style={{ background: 'none', border: 'none', color: '#64748b', fontSize: 22, cursor: 'pointer' }}>✕</button>
        </div>

        {/* Driver picker */}
        <label style={lbl}>{t.camera_stream_type}</label>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 6, marginBottom: 12 }}>
          {drivers.map(d => (
            <button key={d.id} onClick={() => { set('driver', d.id); set('port', d.default_port || 80); set('rtspPort', d.default_rtsp_port || 554) }}
              style={{ padding: '8px 6px', borderRadius: 10, cursor: 'pointer', textAlign: 'left',
                background: form.driver === d.id ? '#1e3a5f' : '#0f172a',
                border: `2px solid ${form.driver === d.id ? '#1d4ed8' : 'transparent'}`,
              }}>
              <div style={{ fontSize: 13 }}>{d.icon} {d.label}</div>
              {d.id === form.driver && d.rtsp_example && (
                <div style={{ fontSize: 9, color: '#475569', marginTop: 2, direction: 'ltr', wordBreak: 'break-all' }}>
                  {d.rtsp_example}
                </div>
              )}
            </button>
          ))}
        </div>

        {/* Camera Name */}
        <label style={lbl}>{t.camera_name}</label>
        <input value={form.name} onChange={e => set('name', e.target.value)}
          placeholder="Front door, Living room..." style={inp} autoFocus />

        {/* IP / Port */}
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 8 }}>
          <div>
            <label style={lbl}>IP Address</label>
            <input value={form.ip} onChange={e => set('ip', e.target.value)}
              placeholder="192.168.1.x" style={{ ...inp, direction: 'ltr' }} />
          </div>
          <div>
            <label style={lbl}>HTTP Port</label>
            <input value={form.port} type="number" onChange={e => set('port', e.target.value)}
              style={{ ...inp, direction: 'ltr' }} />
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <div>
            <label style={lbl}>Username</label>
            <input value={form.username} onChange={e => set('username', e.target.value)}
              style={{ ...inp, direction: 'ltr' }} />
          </div>
          <div>
            <label style={lbl}>Password</label>
            <input value={form.password} type="password" onChange={e => set('password', e.target.value)}
              style={{ ...inp, direction: 'ltr' }} />
          </div>
        </div>

        {form.driver !== 'http_snapshot' && form.driver !== 'http_mjpeg' && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
            <div>
              <label style={lbl}>RTSP Port</label>
              <input value={form.rtspPort} type="number" onChange={e => set('rtspPort', e.target.value)}
                style={{ ...inp, direction: 'ltr' }} />
            </div>
            <div>
              <label style={lbl}>Channel</label>
              <input value={form.channel} type="number" min={1} onChange={e => set('channel', e.target.value)}
                style={{ ...inp, direction: 'ltr' }} />
            </div>
            <div>
              <label style={lbl}>Stream</label>
              <select value={form.subtype} onChange={e => set('subtype', Number(e.target.value))} style={inp}>
                <option value={0}>Main</option>
                <option value={1}>Sub</option>
              </select>
            </div>
          </div>
        )}

        {(form.driver === 'http_snapshot' || form.driver === 'http_mjpeg') && (
          <>
            <label style={lbl}>{t.camera_stream_url}</label>
            <input value={form.customUrl} onChange={e => set('customUrl', e.target.value)}
              placeholder={t.camera_stream_placeholder} style={{ ...inp, direction: 'ltr' }} />
          </>
        )}

        {form.driver === 'rtsp' && (
          <>
            <label style={lbl}>Custom RTSP path (optional)</label>
            <input value={form.customPath} onChange={e => set('customPath', e.target.value)}
              placeholder="/Streaming/Channels/101" style={{ ...inp, direction: 'ltr' }} />
          </>
        )}

        {/* Test button */}
        <button onClick={runTest} disabled={testing || !form.ip}
          style={{ ...btnStyle('#334155'), width: '100%', marginBottom: 8 }}>
          {testing ? '🔄 Testing...' : '🔍 Test Connection'}
        </button>

        {testResult && (
          <div style={{ background: '#0f172a', borderRadius: 8, padding: 10, marginBottom: 10, fontSize: 11 }}>
            <div style={{ color: testResult.reachable ? '#22c55e' : '#ef4444', marginBottom: 4 }}>
              {testResult.reachable ? '✅ Reachable' : '❌ Unreachable'}
              {testResult.snapshot_ok ? '  |  📸 Snapshot OK' : ''}
              {testResult.mjpeg_proxy_url ? '  |  🎥 MJPEG ready' : ''}
            </div>
            {testResult.rtsp_url && (
              <div style={{ color: '#38bdf8', wordBreak: 'break-all', direction: 'ltr' }}>
                🎞 {testResult.rtsp_url}
              </div>
            )}
            {testResult.error && (
              <div style={{ color: '#f87171', marginTop: 4 }}>{testResult.error}</div>
            )}
          </div>
        )}

        <button onClick={doSave} disabled={!form.name || !form.ip}
          style={{ ...btnStyle('#1d4ed8'), width: '100%' }}>
          💾 {t.save}
        </button>
      </div>
    </div>
  )
}

/* ── Camera card ── */
function CameraCard({ cam, hasMjpeg, onEdit, onDelete, onFullscreen }) {
  const snap = cam.snapshotUrl ? proxySnap(cam.snapshotUrl, cam.username, cam.password) : null
  const mjpeg = cam.mjpegProxyUrl || (cam.rtspUrl && hasMjpeg ? mjpegProxy(cam.rtspUrl) : null)

  return (
    <div style={card}>
      {/* Live feed */}
      <div style={{ position: 'relative' }}>
        {mjpeg
          ? <MJPEGTile src={mjpeg} name={cam.name} height={150} />
          : <SnapshotTile src={snap} name={cam.name} height={150} />
        }
        <div style={{ position: 'absolute', top: 7, left: 8, display: 'flex', gap: 5 }}>
          <span style={{ background: 'rgba(0,0,0,.6)', borderRadius: 5, padding: '2px 7px', fontSize: 10, color: mjpeg ? '#22c55e' : snap ? '#f59e0b' : '#475569' }}>
            {mjpeg ? '● Live' : snap ? '● Snapshot' : '○ No stream'}
          </span>
          {cam.driver && (
            <span style={{ background: 'rgba(0,0,0,.55)', borderRadius: 5, padding: '2px 7px', fontSize: 10, color: '#94a3b8' }}>
              {cam.driver.toUpperCase()}
            </span>
          )}
        </div>
      </div>

      {/* Info row */}
      <div style={{ padding: '10px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontWeight: 700, fontSize: 14, color: '#e2e8f0' }}>📷 {cam.name}</div>
          <div style={{ fontSize: 11, color: '#475569', marginTop: 1, direction: 'ltr' }}>
            {cam.ip || cam.customUrl || '—'}
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <button onClick={() => onFullscreen(cam)} style={iconBtn('#0f172a')} title="Fullscreen">⛶</button>
          <button onClick={() => onEdit(cam)} style={iconBtn('#334155')} title="Edit">✏️</button>
          <button onClick={() => onDelete(cam.id)} style={iconBtn('#7f1d1d')} title="Delete">🗑️</button>
        </div>
      </div>
    </div>
  )
}

/* ── Discover modal ── */
function DiscoverModal({ onSelect, onClose, t }) {
  const [running, setRunning] = useState(false)
  const [found, setFound] = useState([])
  const [done, setDone] = useState(false)

  const run = async () => {
    setRunning(true); setFound([]); setDone(false)
    try {
      const r = await api.post('/camera/discover')
      setFound(r.data.cameras || [])
    } catch (e) {
      setFound([])
    }
    setRunning(false); setDone(true)
  }

  useEffect(() => { run() }, [])

  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,.75)', zIndex: 300, display: 'flex', alignItems: 'flex-end' }}>
      <div onClick={e => e.stopPropagation()} style={{ background: '#1e293b', borderRadius: '16px 16px 0 0', padding: 20, width: '100%', maxHeight: '70vh', overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <h3 style={{ margin: 0, color: '#f1f5f9', fontSize: 16 }}>🔍 {t.cam_discover_title ?? 'Discover Cameras'}</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#64748b', fontSize: 22, cursor: 'pointer' }}>✕</button>
        </div>

        {running && (
          <div style={{ textAlign: 'center', padding: 24, color: '#38bdf8', fontSize: 13 }}>
            🔄 {t.cam_scanning ?? 'Scanning network...'}
          </div>
        )}

        {done && found.length === 0 && (
          <div style={{ textAlign: 'center', padding: 24, color: '#475569' }}>
            {t.cam_no_found ?? 'No cameras found. Make sure cameras are on the same network.'}
          </div>
        )}

        {found.map((cam, i) => (
          <div key={i} onClick={() => onSelect(cam)} style={{
            ...card, cursor: 'pointer', padding: '12px 14px', marginBottom: 8,
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <div>
              <div style={{ fontWeight: 600, color: '#e2e8f0', fontSize: 14 }}>
                {cam.ip}:{cam.port}
              </div>
              <div style={{ fontSize: 12, color: '#38bdf8', marginTop: 2 }}>
                {cam.driver?.toUpperCase()} {t.cam_detected ?? 'detected'}
              </div>
            </div>
            <span style={{ fontSize: 20 }}>+</span>
          </div>
        ))}

        {done && (
          <button onClick={run} style={{ ...btnStyle('#334155'), width: '100%', marginTop: 8 }}>
            🔄 {t.cam_scan_again ?? 'Scan Again'}
          </button>
        )}
      </div>
    </div>
  )
}

/* ── Main page ── */
export default function CamerasPage({ devices = [] }) {
  const { t, rtl } = useLang()
  const [cameras, setCameras] = useState(loadCameras)
  const [drivers, setDrivers] = useState([])
  const [hasMjpeg, setHasMjpeg] = useState(false)
  const [editing, setEditing] = useState(null)
  const [fullscreen, setFullscreen] = useState(null)
  const [discovering, setDiscovering] = useState(false)

  useEffect(() => {
    api.get('/camera/drivers')
      .then(r => { setDrivers(r.data.drivers); setHasMjpeg(r.data.mjpeg_proxy_available) })
      .catch(() => {})
  }, [])

  /* include hub camera-type devices not yet manually added */
  const hubCams = devices
    .filter(d => d.type === 'camera')
    .filter(d => !cameras.find(c => c.deviceId === d.id))
    .map(d => ({
      id: `dev_${d.id}`, name: d.name, deviceId: d.id,
      driver: d.state?.driver || 'rtsp',
      ip: d.state?.ip || '',
      rtspUrl: d.state?.stream_url || '',
      snapshotUrl: d.state?.snapshot_url || '',
      username: d.state?.username || '',
      password: d.state?.password || '',
    }))

  const allCams = [...cameras, ...hubCams]

  const saveAndClose = (cam) => {
    const updated = cam.id && cameras.find(c => c.id === cam.id)
      ? cameras.map(c => c.id === cam.id ? cam : c)
      : [...cameras, cam]
    setCameras(updated)
    saveCameras(updated)
    setEditing(null)
  }

  const remove = (id) => {
    const updated = cameras.filter(c => c.id !== id)
    setCameras(updated)
    saveCameras(updated)
  }

  const onDiscoverSelect = (found) => {
    const driverMeta = drivers.find(d => d.id === found.driver)
    setEditing({
      ...BLANK,
      driver: found.driver || 'onvif',
      ip: found.ip,
      port: found.port || driverMeta?.default_port || 80,
      rtspPort: driverMeta?.default_rtsp_port || 554,
      name: `Camera ${found.ip}`,
    })
    setDiscovering(false)
  }

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <h2 style={{ margin: 0, color: '#e2e8f0', fontSize: 18 }}>📷 {t.cameras_title}</h2>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={() => setDiscovering(true)} style={btnStyle('#334155')}>🔍</button>
          <button onClick={() => setEditing({ ...BLANK })} style={btnStyle('#1d4ed8')}>
            {t.add_camera}
          </button>
        </div>
      </div>

      {hasMjpeg === false && allCams.length > 0 && (
        <div style={{ background: '#1c1700', border: '1px solid #78350f', borderRadius: 10, padding: '10px 14px', fontSize: 12, color: '#fcd34d', marginBottom: 14 }}>
          💡 Install <strong>opencv-python-headless</strong> on the hub for live RTSP streaming:
          <div style={{ fontFamily: 'monospace', marginTop: 4, color: '#fbbf24', direction: 'ltr' }}>
            pip install opencv-python-headless
          </div>
        </div>
      )}

      {allCams.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '60px 20px', color: '#475569' }}>
          <div style={{ fontSize: 56 }}>📷</div>
          <p style={{ margin: '12px 0 4px', fontSize: 15, color: '#94a3b8' }}>{t.no_cameras}</p>
          <p style={{ fontSize: 12 }}>{t.no_cameras_hint}</p>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center', marginTop: 16 }}>
            <button onClick={() => setDiscovering(true)} style={btnStyle('#334155')}>🔍 {t.cam_discover_btn ?? 'Discover'}</button>
            <button onClick={() => setEditing({ ...BLANK })} style={btnStyle('#1d4ed8')}>{t.add_camera}</button>
          </div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(290px, 1fr))', gap: 14 }}>
          {allCams.map(cam => (
            <CameraCard key={cam.id} cam={cam} hasMjpeg={hasMjpeg}
              onEdit={c => setEditing(c)}
              onDelete={remove}
              onFullscreen={c => setFullscreen(c)}
            />
          ))}
        </div>
      )}

      {editing !== null && (
        <CameraForm
          cam={editing}
          drivers={drivers.length ? drivers : DEFAULT_DRIVERS}
          hasMjpeg={hasMjpeg}
          onSave={saveAndClose}
          onCancel={() => setEditing(null)}
          t={t}
        />
      )}

      {fullscreen && <FullscreenModal cam={fullscreen} onClose={() => setFullscreen(null)} />}
      {discovering && <DiscoverModal onSelect={onDiscoverSelect} onClose={() => setDiscovering(false)} t={t} />}
    </div>
  )
}

/* fallback driver list if hub is unreachable */
const DEFAULT_DRIVERS = [
  { id: 'rtsp',          label: 'RTSP (Generic)',       icon: '📡', default_port: 80,  default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/' },
  { id: 'hikvision',     label: 'Hikvision / ISAPI',    icon: '🎥', default_port: 80,  default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/Streaming/Channels/101' },
  { id: 'dahua',         label: 'Dahua',                icon: '🎥', default_port: 80,  default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0' },
  { id: 'reolink',       label: 'Reolink',              icon: '🎥', default_port: 80,  default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/h264Preview_01_main' },
  { id: 'tapo',          label: 'TP-Link Tapo',         icon: '🎥', default_port: 554, default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/stream1' },
  { id: 'amcrest',       label: 'Amcrest',              icon: '🎥', default_port: 80,  default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0' },
  { id: 'foscam',        label: 'Foscam',               icon: '🎥', default_port: 88,  default_rtsp_port: 88,  rtsp_example: 'rtsp://user:pass@ip:88/videoMain' },
  { id: 'onvif',         label: 'ONVIF (any brand)',    icon: '🔍', default_port: 80,  default_rtsp_port: 554, rtsp_example: 'rtsp://user:pass@ip:554/stream1' },
  { id: 'http_mjpeg',    label: 'HTTP MJPEG Stream',    icon: '🌐', default_port: 80,  default_rtsp_port: 554, rtsp_example: '' },
  { id: 'http_snapshot', label: 'HTTP Snapshot',        icon: '📸', default_port: 80,  default_rtsp_port: 554, rtsp_example: '' },
]

const card = {
  background: '#1e293b', border: '1px solid #334155', borderRadius: 12, overflow: 'hidden',
}
const btnStyle = (bg, color = '#fff') => ({
  padding: '6px 14px', borderRadius: 8, border: 'none',
  background: bg, color, cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const iconBtn = (bg) => ({
  padding: '6px 10px', borderRadius: 8, border: 'none',
  background: bg, color: '#fff', cursor: 'pointer', fontSize: 14,
})
const inp = {
  width: '100%', padding: '9px 12px', borderRadius: 10,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 13, marginBottom: 10, boxSizing: 'border-box', outline: 'none',
}
const lbl = { fontSize: 12, color: '#64748b', display: 'block', marginBottom: 4 }
