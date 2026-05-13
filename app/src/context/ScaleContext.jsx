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
const MIN_S    = 0.78  // never shrink below 78% (very small phones)
const MAX_S    = 1.00  // phones cap at 1.0 — never upscale (prevents "looks like tablet")

function calcInfo() {
  const w  = window.innerWidth
  const h  = window.innerHeight
  const sc = w >= 1024 ? 'desktop' : w >= 600 ? 'tablet' : 'phone'
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
})

export function ScaleProvider({ children }) {
  const [info, setInfo] = useState(calcInfo)

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

  const { scale } = info

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
    <ScaleContext.Provider value={{ ...info, scale, sp, spx, spc }}>
      {children}
    </ScaleContext.Provider>
  )
}

export const useScale = () => useContext(ScaleContext)
export default ScaleContext
