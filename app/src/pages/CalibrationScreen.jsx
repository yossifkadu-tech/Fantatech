/**
 * CalibrationScreen — first-launch screen.
 *
 * Runs ONCE after registration (before the main app loads).
 * Detects the screen dimensions, suggests the optimal display-size step
 * (for tablets / desktop), and lets the user confirm or manually adjust.
 *
 * On phones: scale is always 1:1 (handled by the auto-fit in ScaleContext),
 * so we just show a quick "all good" splash and move on automatically.
 *
 * localStorage key: 'fantatech_calibrated'  → '1' when done.
 */

import { useState, useEffect } from 'react'
import { useLang }             from '../context/LangContext'
import { DISPLAY_STEPS, DISPLAY_LABELS } from '../context/ScaleContext'

const CALIB_KEY = 'fantatech_calibrated'

export function isCalibrated() {
  return !!localStorage.getItem(CALIB_KEY)
}

/* ── Determine the best starting displayIdx for this device ───────────── */
function suggest(w) {
  if (w >= 1024) return 2          // desktop  → M  (100 %)
  if (w >= 900)  return 0          // lg tablet → XS (75 %)
  if (w >= 768)  return 1          // sm tablet → S  (85 %)
  return 2                         // phone     → M  (irrelevant, auto-fit handles it)
}

function deviceLabel(w, t) {
  if (w >= 1024) return `🖥️  ${t.calib_desktop  ?? 'Desktop'}`
  if (w >= 768)  return `📲  ${t.calib_tablet   ?? 'Tablet'}`
  return              `📱  ${t.calib_phone    ?? 'Phone'}`
}

/* ─────────────────────────────────────────────────────────────────────── */
export default function CalibrationScreen({ onComplete }) {
  const { t, rtl } = useLang()

  const w   = window.innerWidth
  const h   = window.innerHeight
  const dpr = (window.devicePixelRatio || 1).toFixed(1)
  const sc  = w >= 1024 ? 'desktop' : w >= 768 ? 'tablet' : 'phone'
  const isPhone = sc === 'phone'

  const [selIdx, setSelIdx] = useState(() => suggest(w))
  const [done,   setDone]   = useState(false)

  /* On phones: auto-accept after 2.5 s (no manual step needed) */
  useEffect(() => {
    if (!isPhone) return
    const t = setTimeout(accept, 2500)
    return () => clearTimeout(t)
  }, [])                            // eslint-disable-line

  function accept() {
    if (!isPhone) {
      localStorage.setItem('fantatech_display_scale', String(selIdx))
    }
    localStorage.setItem(CALIB_KEY, '1')
    setDone(true)
    setTimeout(onComplete, 300)
  }

  const pct = Math.round(DISPLAY_STEPS[selIdx] * 100)

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(160deg, #0f172a 0%, #1e3a5f 100%)',
      color: '#f1f5f9',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'center',
      padding: '24px 20px',
      direction: rtl ? 'rtl' : 'ltr',
      gap: 0,
      opacity: done ? 0 : 1,
      transition: 'opacity 0.3s',
      fontFamily: 'system-ui, sans-serif',
    }}>

      {/* Logo */}
      <div style={{ fontSize: 52, marginBottom: 12 }}>🏠</div>
      <div style={{ fontSize: 22, fontWeight: 900, color: '#38bdf8', letterSpacing: '-0.5px' }}>
        FantaTech
      </div>
      <div style={{ fontSize: 12, color: '#64748b', marginBottom: 28 }}>
        Smart Home & Security
      </div>

      {/* Detected info card */}
      <div style={{
        background: 'rgba(30,41,59,0.85)',
        border: '1px solid #334155',
        borderRadius: 16,
        padding: '18px 22px',
        width: '100%', maxWidth: 380,
        marginBottom: 24,
      }}>
        <div style={{ fontSize: 12, color: '#64748b', marginBottom: 10, fontWeight: 600, letterSpacing: 0.5 }}>
          {t.calib_detected ?? '🔍 DETECTED SCREEN'}
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
          {/* Device type */}
          <div>
            <div style={{ fontSize: 16, fontWeight: 800, color: '#e2e8f0' }}>
              {deviceLabel(w, t)}
            </div>
            <div style={{ fontSize: 12, color: '#94a3b8', marginTop: 4 }}>
              {w} × {h} px &nbsp;·&nbsp; ×{dpr} DPR
            </div>
          </div>

          {/* Status badge */}
          <div style={{
            background: '#022c22', border: '1px solid #16a34a',
            borderRadius: 20, padding: '5px 12px',
            fontSize: 11, fontWeight: 700, color: '#4ade80',
          }}>
            ✓ {t.calib_ok ?? 'Optimized'}
          </div>
        </div>
      </div>

      {/* ── Phone: simple auto message ─────────────────────────────────────── */}
      {isPhone && (
        <div style={{ textAlign: 'center', color: '#94a3b8', fontSize: 13, lineHeight: 1.8 }}>
          <div style={{ fontSize: 28, marginBottom: 8 }}>✅</div>
          {t.calib_phone_ready ?? 'Display auto-fitted to your phone.\nLaunching…'}
          <div style={{ marginTop: 20 }}>
            <div style={{
              width: 140, height: 3,
              background: '#1e293b', borderRadius: 2,
              overflow: 'hidden', margin: '0 auto',
            }}>
              <div style={{
                height: '100%', width: '100%', background: '#38bdf8',
                borderRadius: 2, transformOrigin: 'left',
                animation: 'calib-bar 2.5s linear forwards',
              }} />
            </div>
          </div>
        </div>
      )}

      {/* ── Tablet / Desktop: size picker ─────────────────────────────────── */}
      {!isPhone && (<>
        <div style={{ fontSize: 13, color: '#94a3b8', marginBottom: 14, textAlign: 'center', lineHeight: 1.7 }}>
          {t.calib_pick ?? 'Choose the display size that looks best on your screen:'}
        </div>

        {/* 5-step buttons */}
        <div style={{ display: 'flex', gap: 8, width: '100%', maxWidth: 380, marginBottom: 24 }}>
          {DISPLAY_LABELS.map((label, idx) => {
            const active = idx === selIdx
            const p      = Math.round(DISPLAY_STEPS[idx] * 100)
            const isRec  = idx === suggest(w)
            return (
              <button
                key={idx}
                onClick={() => setSelIdx(idx)}
                style={{
                  flex: 1, padding: '12px 4px',
                  border: `2px solid ${active ? '#38bdf8' : '#334155'}`,
                  borderRadius: 12,
                  background: active ? 'rgba(56,189,248,0.14)' : 'rgba(15,23,42,0.7)',
                  color: active ? '#38bdf8' : '#64748b',
                  cursor: 'pointer',
                  display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
                  position: 'relative',
                  WebkitTapHighlightColor: 'transparent',
                  transition: 'all 0.15s',
                }}
              >
                {/* "Recommended" star */}
                {isRec && (
                  <span style={{
                    position: 'absolute', top: -7, fontSize: 10,
                    background: '#0ea5e9', color: '#fff',
                    borderRadius: 6, padding: '1px 5px', fontWeight: 700,
                  }}>★</span>
                )}
                <span style={{ fontSize: 10 + idx * 3, fontWeight: 800, lineHeight: 1 }}>A</span>
                <span style={{ fontSize: 9,  fontWeight: 700 }}>{label}</span>
                <span style={{ fontSize: 8,  color: active ? '#7dd3fc' : '#475569' }}>{p}%</span>
              </button>
            )
          })}
        </div>

        {/* Preview sentence at selected scale */}
        <div style={{
          background: 'rgba(15,23,42,0.6)', border: '1px solid #334155',
          borderRadius: 10, padding: '10px 16px',
          width: '100%', maxWidth: 380, marginBottom: 24,
          textAlign: 'center',
        }}>
          <span style={{ fontSize: Math.round(14 * DISPLAY_STEPS[selIdx]), color: '#cbd5e1' }}>
            {t.calib_preview ?? 'Text preview at'} {pct}%
          </span>
        </div>

        {/* Confirm button */}
        <button
          onClick={accept}
          style={{
            width: '100%', maxWidth: 380,
            padding: '14px 0',
            background: 'linear-gradient(90deg, #0ea5e9, #6366f1)',
            border: 'none', borderRadius: 12,
            color: '#fff', fontSize: 15, fontWeight: 800,
            cursor: 'pointer', letterSpacing: 0.3,
            WebkitTapHighlightColor: 'transparent',
            boxShadow: '0 4px 20px rgba(14,165,233,0.35)',
          }}
        >
          {t.calib_confirm ?? '✓  Looks good — Open App'}
        </button>
      </>)}

      {/* Loading bar animation */}
      <style>{`
        @keyframes calib-bar {
          from { transform: scaleX(0); }
          to   { transform: scaleX(1); }
        }
      `}</style>
    </div>
  )
}
