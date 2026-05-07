/**
 * QrScanner — Real working QR scanner.
 * Strategy:
 *   1. getUserMedia (live camera) + BarcodeDetector API  → works on Android WebView / Chrome 88+
 *   2. getUserMedia + canvas frame → fallback if no BarcodeDetector
 *   3. @capacitor-community/barcode-scanner (native plugin)
 *   4. Manual text input
 */
import { useState, useEffect, useRef, useCallback } from 'react'
import { useLang } from '../context/LangContext'

let CapBarcodeScanner = null
let SupportedFormat   = null
try {
  const mod = require('@capacitor-community/barcode-scanner')
  CapBarcodeScanner = mod.BarcodeScanner
  SupportedFormat   = mod.SupportedFormat
} catch {}

/**
 * Parse a scanned QR payload into a partial device object.
 * Supports:
 *   • plain IP:  "192.168.1.55"
 *   • URL:       "http://192.168.1.55"
 *   • JSON:      {"ip":"…","name":"…","type":"tasmota"}
 *   • WiFi cred: "WIFI:S:MySSID;T:WPA;P:mypass;;"
 */
export function parseQrPayload(raw) {
  raw = (raw || '').trim()

  const wifiMatch = raw.match(/WIFI:.*?S:([^;]+).*?P:([^;]*)/)
  if (wifiMatch) return { _type: 'wifi', ssid: wifiMatch[1], password: wifiMatch[2] }

  if (raw.startsWith('{')) {
    try { return { _type: 'device', ...JSON.parse(raw) } } catch {}
  }

  const urlMatch = raw.match(/https?:\/\/([\d.]+)/)
  if (urlMatch) return { _type: 'device', ip: urlMatch[1], name: urlMatch[1] }

  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(raw)) return { _type: 'device', ip: raw, name: raw }

  return { _type: 'unknown', raw }
}

export default function QrScanner({ onResult, onClose }) {
  const { t } = useLang()
  const [mode, setMode]         = useState('idle')   // idle | camera | cap_scanning
  const [manual, setManual]     = useState('')
  const [error, setError]       = useState('')
  const [camReady, setCamReady] = useState(false)

  const videoRef    = useRef(null)
  const canvasRef   = useRef(null)
  const streamRef   = useRef(null)
  const rafRef      = useRef(null)
  const detectorRef = useRef(null)
  const scanningRef = useRef(false)

  const hasBarcodeDetector = typeof window !== 'undefined' && 'BarcodeDetector' in window
  const hasGetUserMedia    = typeof navigator !== 'undefined' && !!navigator?.mediaDevices?.getUserMedia

  // ── Cleanup on unmount ────────────────────────────────────────────────────
  const stopCamera = useCallback(() => {
    scanningRef.current = false
    if (rafRef.current) cancelAnimationFrame(rafRef.current)
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(tr => tr.stop())
      streamRef.current = null
    }
    setCamReady(false)
    setMode('idle')
  }, [])

  useEffect(() => () => stopCamera(), [stopCamera])

  // ── Start camera scan ──────────────────────────────────────────────────────
  const startCameraScan = async () => {
    setError('')
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1280 }, height: { ideal: 720 },
        },
        audio: false,
      })
      streamRef.current = stream
      setMode('camera')

      // Init BarcodeDetector
      if (hasBarcodeDetector) {
        try {
          detectorRef.current = new window.BarcodeDetector({
            formats: ['qr_code', 'ean_13', 'code_128', 'code_39', 'data_matrix'],
          })
        } catch { detectorRef.current = null }
      }
    } catch (e) {
      const msg = e?.name === 'NotAllowedError'
        ? (t.qr_perm_denied ?? 'Camera permission denied. Allow camera in phone settings.')
        : (e?.message || (t.qr_cam_error ?? 'Camera error'))
      setError(msg)
    }
  }

  // ── Attach stream once video element mounts ────────────────────────────────
  useEffect(() => {
    if (mode !== 'camera' || !streamRef.current) return
    const video = videoRef.current
    if (!video) return
    video.srcObject = streamRef.current
    video.onloadedmetadata = () => {
      video.play().catch(() => {})
      setCamReady(true)
      scanningRef.current = true
      scanLoop()
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode])

  // ── Continuous scan loop ───────────────────────────────────────────────────
  const scanLoop = async () => {
    if (!scanningRef.current) return
    const video  = videoRef.current
    const canvas = canvasRef.current
    if (!video || !canvas) return

    if (video.readyState >= video.HAVE_ENOUGH_DATA && video.videoWidth > 0) {
      canvas.width  = video.videoWidth
      canvas.height = video.videoHeight
      const ctx = canvas.getContext('2d', { willReadFrequently: true })
      ctx.drawImage(video, 0, 0)

      // 1) Try BarcodeDetector
      if (detectorRef.current) {
        try {
          const codes = await detectorRef.current.detect(canvas)
          if (codes.length > 0) {
            stopCamera()
            onResult(parseQrPayload(codes[0].rawValue))
            return
          }
        } catch { /* non-fatal */ }
      }
    }

    rafRef.current = requestAnimationFrame(() => scanLoop())
  }

  // ── Capacitor native scan (fallback) ───────────────────────────────────────
  const startCapScan = async () => {
    if (!CapBarcodeScanner) return
    setError(''); setMode('cap_scanning')
    try {
      const perm = await CapBarcodeScanner.checkPermission({ force: true })
      if (!perm.granted) {
        setError(t.qr_perm_denied ?? 'Camera permission required')
        setMode('idle'); return
      }
      await CapBarcodeScanner.prepare?.()
      CapBarcodeScanner.hideBackground()
      document.body.style.background = 'transparent'
      const result = await CapBarcodeScanner.startScan({
        targetedFormats: [SupportedFormat?.QR_CODE ?? 'QR_CODE'],
      })
      CapBarcodeScanner.showBackground()
      document.body.style.background = ''
      if (result.hasContent) {
        onResult(parseQrPayload(result.content))
      } else {
        setError(t.qr_no_content ?? 'No QR code found')
        setMode('idle')
      }
    } catch (e) {
      setError(e?.message || (t.qr_fail ?? 'Scan failed'))
      try { CapBarcodeScanner.showBackground() } catch {}
      document.body.style.background = ''
      setMode('idle')
    }
  }

  const submitManual = () => {
    if (!manual.trim()) return
    onResult(parseQrPayload(manual.trim()))
  }

  return (
    <div style={{ padding: '8px 0' }}>

      {/* ── Live camera view ── */}
      {mode === 'camera' && (
        <div style={{ position: 'relative', marginBottom: 12, borderRadius: 12, overflow: 'hidden', border: '2px solid #38bdf8', background: '#000' }}>
          <video
            ref={videoRef}
            playsInline muted autoPlay
            style={{ width: '100%', display: 'block', maxHeight: 260, objectFit: 'cover' }}
          />
          <canvas ref={canvasRef} style={{ display: 'none' }} />

          {/* Aim overlay */}
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            pointerEvents: 'none',
          }}>
            <div style={{
              width: 170, height: 170,
              border: '3px solid #38bdf8',
              borderRadius: 16,
              boxShadow: '0 0 0 4000px rgba(0,0,0,0.50)',
            }} />
          </div>

          {/* Close */}
          <button onClick={stopCamera} style={{
            position: 'absolute', top: 8, right: 8,
            background: 'rgba(0,0,0,0.75)', border: 'none', color: '#fff',
            borderRadius: 8, padding: '4px 10px', cursor: 'pointer', fontSize: 13, fontWeight: 700,
          }}>✕</button>

          <div style={{
            position: 'absolute', bottom: 8, left: 0, right: 0,
            textAlign: 'center', color: '#38bdf8', fontSize: 11, fontWeight: 700,
            textShadow: '0 1px 4px #000',
          }}>
            {camReady ? (t.qr_aim ?? 'Aim at QR code') : (t.qr_loading_cam ?? 'Starting camera...')}
          </div>
        </div>
      )}

      {/* ── Buttons ── */}
      {mode !== 'camera' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 14 }}>

          {/* Primary: browser camera + BarcodeDetector */}
          {hasGetUserMedia && (
            <button onClick={startCameraScan} style={{ ...bs('#1d4ed8'), width: '100%', fontSize: 14 }}>
              📷 {t.qr_open_cam ?? 'Open Camera — Scan QR'}
            </button>
          )}

          {/* Secondary: Capacitor native plugin */}
          {CapBarcodeScanner && (
            <button
              onClick={startCapScan}
              disabled={mode === 'cap_scanning'}
              style={{ ...bs('#0e7490'), width: '100%', opacity: mode === 'cap_scanning' ? 0.7 : 1 }}
            >
              {mode === 'cap_scanning'
                ? `⏳ ${t.qr_scanning ?? 'Scanning...'}`
                : `📱 ${t.qr_native_scan ?? 'Native Camera Scan'}`}
            </button>
          )}
        </div>
      )}

      {/* ── Manual fallback ── */}
      <div style={{ fontSize: 12, color: '#64748b', marginBottom: 6, textAlign: 'center' }}>
        — {t.qr_or_manual ?? 'or paste QR content manually'} —
      </div>
      <input
        value={manual}
        onChange={e => setManual(e.target.value)}
        onKeyDown={e => e.key === 'Enter' && submitManual()}
        placeholder={'{"ip":"192.168.1.55"} / WIFI:S:MyNet;P:pass;;'}
        style={iStyle}
      />
      <div style={{ display: 'flex', gap: 8 }}>
        <button onClick={submitManual} style={{ ...bs('#22c55e'), flex: 1 }}>✅ {t.confirm ?? 'Confirm'}</button>
        <button onClick={onClose} style={bs('#475569')}>{t.cancel ?? 'Cancel'}</button>
      </div>

      {error && (
        <div style={{ marginTop: 10, background: '#7f1d1d', border: '1px solid #ef4444', borderRadius: 8, padding: '8px 12px', fontSize: 12, color: '#fca5a5' }}>
          ⚠️ {error}
        </div>
      )}
    </div>
  )
}

const bs = bg => ({ padding: '10px 18px', borderRadius: 8, border: 'none', background: bg, color: '#fff', cursor: 'pointer', fontWeight: 700, fontSize: 13 })
const iStyle = { width: '100%', padding: '10px 12px', marginBottom: 10, borderRadius: 8, border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9', fontSize: 13, boxSizing: 'border-box', direction: 'ltr' }
