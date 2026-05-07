import { useState, useEffect, useCallback, useRef } from 'react'
import axios from 'axios'

/* ── Hub URL — reads from localStorage so the APK can point to any IP ─── */
export const getHubUrl = () => {
  // Dev mode: use env variable (e.g. http://localhost:8080)
  if (import.meta.env.VITE_HUB_URL) return import.meta.env.VITE_HUB_URL
  // APK / production: read from localStorage
  return localStorage.getItem('hub_url') || ''
}

export const setHubUrl = (url) => {
  const clean = (url || '').replace(/\/+$/, '') // strip trailing slash
  localStorage.setItem('hub_url', clean)
}

export const clearHubUrl = () => localStorage.removeItem('hub_url')

/* ── Axios API wrapper — always uses current hub URL ─────────────────── */
export const api = {
  get:    (path, config)        => axios.get(`${getHubUrl()}/api${path}`, config),
  post:   (path, data, config)  => axios.post(`${getHubUrl()}/api${path}`, data, config),
  put:    (path, data, config)  => axios.put(`${getHubUrl()}/api${path}`, data, config),
  delete: (path, config)        => axios.delete(`${getHubUrl()}/api${path}`, config),
}

/* ── Test connectivity to a specific URL ─────────────────────────────── */
export async function testHubUrl(url) {
  try {
    const clean = (url || '').replace(/\/+$/, '')
    const r = await axios.get(`${clean}/ping`, { timeout: 5000 })
    return r.data?.pong === true
  } catch {
    return false
  }
}

/* ── Get local device IP via WebRTC (works in Capacitor/Android) ─────── */
async function _getLocalIp() {
  return new Promise((resolve) => {
    try {
      const pc = new RTCPeerConnection({ iceServers: [] })
      pc.createDataChannel('')
      pc.createOffer().then(o => pc.setLocalDescription(o)).catch(() => {})
      const timer = setTimeout(() => { pc.close(); resolve(null) }, 1500)
      pc.onicecandidate = (e) => {
        if (!e.candidate) return
        const m = e.candidate.candidate.match(/(\d+\.\d+\.\d+\.\d+)/)
        if (m && !m[1].startsWith('127.')) {
          clearTimeout(timer)
          pc.close()
          resolve(m[1])
        }
      }
    } catch { resolve(null) }
  })
}

/* ── Auto-discover hub on local network ─────────────────────────────── */
export async function discoverHub(onProgress) {
  const port = 8080

  // ── Step 0: Try mDNS hostname (Hub registers this on startup) ────────────
  onProgress?.('מנסה fantatech-hub.local...')
  const mdnsFound = await _scanBatch([
    `http://fantatech-hub.local:${port}`,
    `http://fantatech-hub:${port}`,
    `http://fantatech-hub.local.:${port}`,
  ], 2500)
  if (mdnsFound) return mdnsFound

  // ── Step 0b: Use WebRTC to detect phone's own IP → scan that subnet first ─
  onProgress?.('מזהה כתובת רשת...')
  const localIp = await _getLocalIp()
  if (localIp) {
    const rtcSubnet = localIp.match(/(\d+\.\d+\.\d+)/)
    if (rtcSubnet) {
      onProgress?.(`סורק רשת הטלפון ${rtcSubnet[1]}.x...`)
      const rtcIps = []
      for (let i = 1; i <= 254; i++) rtcIps.push(`http://${rtcSubnet[1]}.${i}:${port}`)
      const rtcFound = await _scanBatch(rtcIps, 800)
      if (rtcFound) return rtcFound
    }
  }

  // ── Step 1: Try last-saved subnet first (fastest if user reconnects) ──────
  const lastUrl = localStorage.getItem('hub_url') || ''
  if (lastUrl) {
    const lastSubnet = lastUrl.match(/http:\/\/(\d+\.\d+\.\d+)/)
    if (lastSubnet) {
      onProgress?.(`מנסה רשת אחרונה ${lastSubnet[1]}.x...`)
      const lastIps = []
      for (let i = 1; i <= 254; i++) lastIps.push(`http://${lastSubnet[1]}.${i}:${port}`)
      const foundLast = await _scanBatch(lastIps, 800)
      if (foundLast) return foundLast
    }
  }

  // ── Step 2: Common IPs across all typical home subnets ───────────────────
  const subnets = [
    '192.168.1', '192.168.0', '192.168.2', '192.168.3',
    '192.168.4', '192.168.8', '192.168.10', '192.168.50',
    '192.168.100', '192.168.178', '10.0.0', '10.0.1',
    '10.1.1', '10.10.0', '172.16.0',
  ]
  const commonEnds = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    50, 51, 52, 100, 101, 102, 103, 104, 105, 110,
    150, 200, 201, 202, 210, 220, 250, 254,
  ]
  const round1 = []
  for (const s of subnets)
    for (const e of commonEnds) round1.push(`http://${s}.${e}:${port}`)

  onProgress?.('סורק כתובות נפוצות...')
  const found1 = await _scanBatch(round1, 900)
  if (found1) return found1

  // ── Step 3: Full sweep of all common subnets ─────────────────────────────
  onProgress?.('סורק כל הרשת (זה עשוי לקחת כ-20 שניות)...')
  const round2 = []
  for (const s of ['192.168.1', '192.168.0', '192.168.2', '192.168.3',
                   '192.168.4', '192.168.8', '192.168.10', '192.168.50',
                   '192.168.100', '192.168.178', '10.0.0', '10.0.1']) {
    for (let i = 1; i <= 254; i++) {
      if (!commonEnds.includes(i)) round2.push(`http://${s}.${i}:${port}`)
    }
  }
  const BATCH = 60
  for (let i = 0; i < round2.length; i += BATCH) {
    const pct = Math.round((i / round2.length) * 100)
    onProgress?.(`סורק... ${pct}%`)
    const found2 = await _scanBatch(round2.slice(i, i + BATCH), 700)
    if (found2) return found2
  }

  return null
}

async function _scanBatch(urls, timeout) {
  const results = await Promise.allSettled(
    urls.map(url =>
      axios.get(`${url}/ping`, { timeout })
        .then(r => r.data?.pong === true ? url : null)
        .catch(() => null)
    )
  )
  for (const r of results) {
    if (r.status === 'fulfilled' && r.value) return r.value
  }
  return null
}

/* ── React hooks ─────────────────────────────────────────────────────── */
const DEVICES_CACHE_KEY = 'fantatech_devices_cache'

function _saveCache(devices) {
  try { localStorage.setItem(DEVICES_CACHE_KEY, JSON.stringify(devices)) } catch {}
}

function _loadCache() {
  try { return JSON.parse(localStorage.getItem(DEVICES_CACHE_KEY) || '[]') } catch { return [] }
}

export function useDevices() {
  const [devices, setDevices] = useState(() => _loadCache())
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    try {
      const r = await api.get('/devices/')
      setDevices(r.data)
      _saveCache(r.data)
    } catch {
      // Hub unreachable — show cached devices with offline indicator
      const cached = _loadCache()
      if (cached.length > 0) {
        setDevices(cached.map(d => ({ ...d, online: false })))
      }
    }
    setLoading(false)
  }, [])

  useEffect(() => { load() }, [load])

  const updateDeviceState = useCallback((id, state) => {
    setDevices(prev => prev.map(d =>
      d.id === id ? { ...d, state: { ...d.state, ...state }, online: true } : d
    ))
  }, [])

  const setOnline = useCallback((id, online) => {
    setDevices(prev => prev.map(d => d.id === id ? { ...d, online } : d))
  }, [])

  return { devices, loading, reload: load, updateDeviceState, setOnline }
}

export function useWebSocket(onDeviceState, onDeviceOnline, onBridgeStatus) {
  const ws      = useRef(null)
  const [connected, setConnected] = useState(false)

  const buildWsUrl = () => {
    const base = getHubUrl()
    if (base) {
      return base.replace(/^http/, 'ws') + '/ws'
    }
    return `ws://${location.host}/ws`
  }

  const connect = useCallback(() => {
    if (ws.current?.readyState === WebSocket.OPEN) return
    const wsUrl = buildWsUrl()
    ws.current = new WebSocket(wsUrl)

    ws.current.onopen = () => {
      setConnected(true)
      const ping = setInterval(() => {
        if (ws.current?.readyState === WebSocket.OPEN) ws.current.send('ping')
        else clearInterval(ping)
      }, 20000)
    }

    ws.current.onmessage = (e) => {
      try {
        const { event, data } = JSON.parse(e.data)
        if (event === 'device_state')  onDeviceState?.(data)
        if (event === 'device_online') onDeviceOnline?.(data)
        if (event === 'bridge_status') onBridgeStatus?.(data)
      } catch {}
    }

    ws.current.onclose = () => {
      setConnected(false)
      setTimeout(connect, 3000)
    }
    ws.current.onerror = () => ws.current?.close()
  }, [onDeviceState, onDeviceOnline, onBridgeStatus])

  useEffect(() => {
    connect()
    return () => ws.current?.close()
  }, [connect])

  return connected
}
