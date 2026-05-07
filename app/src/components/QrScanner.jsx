/**
 * QrScanner — wraps @capacitor-community/barcode-scanner.
 * On web/browser shows a manual-input fallback.
 */
import { useState } from 'react'

let BarcodeScanner = null
try {
  BarcodeScanner = require('@capacitor-community/barcode-scanner').BarcodeScanner
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

  // WiFi QR
  const wifiMatch = raw.match(/WIFI:.*?S:([^;]+).*?P:([^;]*)/)
  if (wifiMatch) {
    return { _type: 'wifi', ssid: wifiMatch[1], password: wifiMatch[2] }
  }

  // JSON object
  if (raw.startsWith('{')) {
    try {
      const obj = JSON.parse(raw)
      return { _type: 'device', ...obj }
    } catch {}
  }

  // URL → extract IP
  const urlMatch = raw.match(/https?:\/\/([\d.]+)/)
  if (urlMatch) {
    return { _type: 'device', ip: urlMatch[1], name: urlMatch[1] }
  }

  // Plain IP
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(raw)) {
    return { _type: 'device', ip: raw, name: raw }
  }

  return { _type: 'unknown', raw }
}

export default function QrScanner({ onResult, onClose }) {
  const [scanning, setScanning] = useState(false)
  const [manual, setManual]     = useState('')
  const [error, setError]       = useState('')
  const isNative = !!BarcodeScanner

  const startScan = async () => {
    if (!isNative) return
    setError(''); setScanning(true)
    try {
      const perm = await BarcodeScanner.checkPermission({ force: true })
      if (!perm.granted) { setError('נדרשת הרשאת מצלמה'); setScanning(false); return }
      BarcodeScanner.hideBackground()
      document.body.style.background = 'transparent'
      const result = await BarcodeScanner.startScan()
      BarcodeScanner.showBackground()
      document.body.style.background = ''
      if (result.hasContent) onResult(parseQrPayload(result.content))
    } catch (e) {
      setError(e?.message || 'סריקה נכשלה')
      try { BarcodeScanner.showBackground() } catch {}
      document.body.style.background = ''
    }
    setScanning(false)
  }

  const submitManual = () => {
    if (!manual.trim()) return
    onResult(parseQrPayload(manual.trim()))
  }

  return (
    <div style={{ padding: '16px 0' }}>
      {isNative ? (
        <>
          <button onClick={startScan} disabled={scanning} style={{
            ...btnStyle('#1d4ed8'), width: '100%', marginBottom: 12,
            opacity: scanning ? 0.7 : 1,
          }}>
            {scanning ? '📷 סורק...' : '📷 פתח מצלמה לסריקת QR'}
          </button>
          {scanning && (
            <div style={{ textAlign: 'center', color: '#64748b', fontSize: 12, marginBottom: 8 }}>
              כוון את המצלמה אל קוד QR של המכשיר
            </div>
          )}
        </>
      ) : (
        <div style={{ background: '#1e3a5f', border: '1px solid #3b82f6', borderRadius: 10, padding: 12, marginBottom: 12, fontSize: 12, color: '#93c5fd' }}>
          📷 סריקת מצלמה זמינה ב-APK בלבד
        </div>
      )}

      <div style={{ fontSize: 12, color: '#64748b', marginBottom: 6, textAlign: 'center' }}>— או הדבק תוכן QR ידנית —</div>
      <input
        value={manual}
        onChange={e => setManual(e.target.value)}
        onKeyDown={e => e.key === 'Enter' && submitManual()}
        placeholder={'{"ip":"192.168.1.55"} או WIFI:S:MyNet;P:pass;;'}
        style={inputStyle}
      />
      <div style={{ display: 'flex', gap: 8 }}>
        <button onClick={submitManual} style={{ ...btnStyle('#22c55e'), flex: 1 }}>✅ אשר</button>
        <button onClick={onClose} style={btnStyle('#475569')}>ביטול</button>
      </div>

      {error && (
        <div style={{ marginTop: 10, background: '#7f1d1d', border: '1px solid #ef4444', borderRadius: 8, padding: '8px 12px', fontSize: 12, color: '#fca5a5' }}>
          {error}
        </div>
      )}
    </div>
  )
}

const btnStyle = bg => ({
  padding: '10px 18px', borderRadius: 8, border: 'none',
  background: bg, color: '#fff', cursor: 'pointer', fontWeight: 600, fontSize: 13,
})
const inputStyle = {
  width: '100%', padding: '10px 12px', marginBottom: 10, borderRadius: 8,
  border: '1px solid #334155', background: '#0f172a', color: '#f1f5f9',
  fontSize: 13, boxSizing: 'border-box', direction: 'ltr',
}
