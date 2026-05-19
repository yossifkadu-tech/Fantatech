/**
 * ScaleContext — automatic viewport-aware scaling template
 *
 * Design baseline: 390 px wide (iPhone 14 Pro / Pixel 7a).
 * On smaller phones every sp() / spx() value shrinks proportionally.
 * On tablets and desktops scale is always 1.0 — no change needed.
 *
 * ─────────────────────────────────────────────
 *  Quick-start
 * ─────────────────────────────────────────────
 *  1. Wrap your app:
 *       <ScaleProvider><App /></ScaleProvider>
 *
 *  2. In any component:
 *       const { sp, spx, phone, scale } = useScale()
 *
 *  3. Use in styles:
 *       style={{ padding: spx(14), fontSize: spx(13), gap: sp(10) }}
 *       style={{ borderRadius: sp(12), marginBottom: sp(20) }}
 *
 * ─────────────────────────────────────────────
 *  Scale ranges (phone only)
 * ─────────────────────────────────────────────
 *  320 px → 0.82   (smallest real Android)
 *  360 px → 0.92   (common mid-range)
 *  390 px → 1.00   (baseline)
 *  414 px → 1.06   (iPhone Plus)
 *  ≥600 px → 1.00  (tablet — no scaling)
 * ─────────────────────────────────────────────
 */
import { createContext, useContext, useState, useEffect } from 'react'

const DESIGN_W = 390   // px — every value in the app is designed for this width
const MIN_S    = 0.70  // never shrink below 70% (very small / rugged phones)
const MAX_S    = 1.00  // phones cap at 1.0 — never upscale

// ── User-adjustable display size ─────────────────────────────────────────────
// 5 steps the user can pick in Settings.  Index 2 = 1.0 (default / 100 %).
export const DISPLAY_STEPS  = [0.75, 0.85, 1.00, 1.15, 1.30]
export const DISPLAY_LABELS = ['XS', 'S', 'M', 'L', 'XL']
const USER_SCALE_KEY = 'fantatech_display_scale'

function calcInfo() {
  const w  = window.innerWidth
  const h  = window.innerHeight
  // Raised tablet threshold to 768 px: devices < 768 px (phones, small tablets)
  // get the auto-zoom phone layout; 768–1023 px = tablet; ≥1024 px = desktop.
  const sc = w >= 1024 ? 'desktop' : w >= 768 ? 'tablet' : 'phone'
  const scale = sc === 'phone'
    ? Math.min(MAX_S, Math.max(MIN_S, w / DESIGN_W))
    : 1
  return {
    w, h, sc, scale,
    landscape: w > h,
    phone:   sc === 'phone',
    tablet:  sc === 'tablet',
    desktop: sc === 'desktop',
  }
}

const ScaleContext = createContext({
  scale: 1, sp: n => n, spx: n => `${n}px`, spc: (n, lo, hi) => `${n}px`,
  phone: false, tablet: false, desktop: false, landscape: false,
  w: 390, h: 844, sc: 'phone',
  displayScale: 1, displayIdx: 2, setDisplayIdx: () => {},
})

export function ScaleProvider({ children }) {
  const [info, setInfo] = useState(calcInfo)

  // User-controlled display size preference
  // On tablets: if no stored preference yet, auto-pick a sensible default:
  //   768–899 px  → S  (idx 1, 85 %) — small/medium tablet
  //   900–1023 px → XS (idx 0, 75 %) — large tablet / landscape
  // Phones and desktops still default to M (idx 2, 100 %).
  const [displayIdx, setDisplayIdxState] = useState(() => {
    const s = localStorage.getItem(USER_SCALE_KEY)
    if (s !== null) {
      const n = parseInt(s, 10)
      return Math.max(0, Math.min(DISPLAY_STEPS.length - 1, n))
    }
    // First-run auto-default based on device type
    const w  = window.innerWidth
    const sc = w >= 1024 ? 'desktop' : w >= 768 ? 'tablet' : 'phone'
    if (sc === 'tablet') {
      return w >= 900 ? 0 : 1   // XS for large tablets, S for small tablets
    }
    return 2   // M = 1.0 for phone + desktop
  })
  const setDisplayIdx = (idx) => {
    const clamped = Math.max(0, Math.min(DISPLAY_STEPS.length - 1, idx))
    setDisplayIdxState(clamped)
    localStorage.setItem(USER_SCALE_KEY, String(clamped))
  }
  const displayScale = DISPLAY_STEPS[displayIdx]

  useEffect(() => {
    // Re-calculate once the WebView is fully laid out (Capacitor may report
    // wrong innerWidth on the very first frame)
    const timer = setTimeout(() => setInfo(calcInfo()), 50)
    return () => clearTimeout(timer)
  }, [])

  useEffect(() => {
    const upd = () => setInfo(calcInfo())
    window.addEventListener('resize',            upd)
    window.addEventListener('orientationchange', upd)
    screen.orientation?.addEventListener('change', upd)
    return () => {
      window.removeEventListener('resize',            upd)
      window.removeEventListener('orientationchange', upd)
      screen.orientation?.removeEventListener('change', upd)
    }
  }, [])

  // All scaling is now handled by CSS zoom in App.jsx.
  // sp() / spx() always return 1:1 values so nothing is double-scaled.
  const combinedScale = 1.0

  // Inject CSS custom property so non-React CSS can use the scale
  useEffect(() => {
    document.documentElement.style.setProperty('--app-scale', String(combinedScale))
  }, [combinedScale])

  // Override info.scale with the combined value
  const scale = combinedScale

  /**
   * sp(n) → scaled number
   * Use for: gap, borderRadius, lineHeight multipliers, numeric calculations.
   * @example  style={{ gap: sp(10), borderRadius: sp(12) }}
   */
  const sp = n => Math.round(n * scale)

  /**
   * spx(n) → "Npx" string
   * Use for: fontSize, padding, margin, width — anywhere a CSS length string is expected.
   * @example  style={{ fontSize: spx(13), padding: `${spx(10)} ${spx(14)}` }}
   */
  const spx = n => `${Math.round(n * scale)}px`

  /**
   * spc(n, min, max) → clamped "Npx" string
   * Like spx but with explicit floor/ceiling.
   * @example  style={{ fontSize: spc(13, 11, 16) }}
   */
  const spc = (n, lo, hi) => `${Math.min(hi, Math.max(lo, Math.round(n * scale)))}px`

  return (
    <ScaleContext.Provider value={{
      ...info, scale, sp, spx, spc,
      displayScale, displayIdx, setDisplayIdx,
    }}>
      {children}
    </ScaleContext.Provider>
  )
}

export const useScale  = () => useContext(ScaleContext)
export { DESIGN_W }
export default ScaleContext
