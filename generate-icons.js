/**
 * FantaTech App Icon Generator
 * Design: matches the in-app header exactly
 *   - Dark navy  #0f172a background
 *   - Sky-blue   #38bdf8 house (clean emoji-style, no chimney)
 *   - "FantaTech" bold white text below
 *
 * Run: node generate-icons.js
 */
const sharp = require('C:/Projects/smart-home-app/node_modules/sharp');
const fs    = require('fs');
const path  = require('path');

const RES = 'app/android/app/src/main/res';

const DENSITIES = [
  { dir: 'mipmap-mdpi',    size: 48  },
  { dir: 'mipmap-hdpi',    size: 72  },
  { dir: 'mipmap-xhdpi',   size: 96  },
  { dir: 'mipmap-xxhdpi',  size: 144 },
  { dir: 'mipmap-xxxhdpi', size: 192 },
];

const BG      = '#0a1020';   // deep navy background
const GREEN1  = '#4ade80';   // roof top — bright green (eco)
const GREEN2  = '#16a34a';   // roof bottom / overhang
const BLUE    = '#38bdf8';   // body — sky blue (smart home)
const INDIGO  = '#6366f1';   // shield / door — security
const WHITE   = '#f1f5f9';

/**
 * SVG that replicates the in-app header look:
 *  ┌──────────────────────────────────┐
 *  │              🏠                  │   ← clean house, emoji-style
 *  │           FantaTech              │   ← sky-blue bold text
 *  └──────────────────────────────────┘
 *
 * Designed at 192×192; everything scales via `s = sz/192`.
 * fullBg=false → transparent background (adaptive foreground layer)
 */
/**
 * Classic Trio icon — green roof (eco) + sky-blue body (smart) + indigo shield door (security)
 * Designed at 192×192; scaled via s = sz/192
 */
function makeSvg(sz, fullBg = true) {
  const s = sz / 192;
  const r = v => +(v * s).toFixed(2);

  /* ── Geometry (base 192px) ── */
  // Roof
  const apex = { x: 96, y: 24 };
  const roofL = 14, roofR = 178, roofBase = 94;

  // Body
  const bodyL = 22, bodyR = 170, bodyTop = 90, bodyBt = 156;

  // Windows
  const wW = 26, wH = 22, wY = 103;
  const wLX = 34, wRX = 130;

  // Shield door (centered)
  const shieldCX = 96, shieldTY = 108;
  const shieldW  = 32, shieldH  = 42;
  const shieldX  = shieldCX - shieldW / 2;

  // Text
  const showText = sz >= 72;
  const ftSize   = r(18);
  const ftY      = r(178);

  return `<svg width="${sz}" height="${sz}" viewBox="0 0 ${sz} ${sz}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="roofGrad${sz}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${GREEN1}"/>
      <stop offset="100%" stop-color="${GREEN2}"/>
    </linearGradient>
  </defs>

  ${fullBg ? `<rect width="${sz}" height="${sz}" fill="${BG}" rx="${r(30)}"/>` : ''}

  <!-- ── Roof (green = eco) ── -->
  <polygon
    points="${r(apex.x)},${r(apex.y)} ${r(roofR)},${r(roofBase)} ${r(roofL)},${r(roofBase)}"
    fill="url(#roofGrad${sz})"
  />
  <rect x="${r(roofL)}" y="${r(roofBase - 4)}" width="${r(roofR - roofL)}" height="${r(8)}"
        fill="${GREEN2}" rx="${r(2)}"/>

  <!-- ── Body (sky-blue = smart home) ── -->
  <rect x="${r(bodyL)}" y="${r(bodyTop)}" width="${r(bodyR - bodyL)}" height="${r(bodyBt - bodyTop)}"
        fill="${BLUE}" rx="${r(5)}"/>

  <!-- ── Left window ── -->
  <rect x="${r(wLX)}" y="${r(wY)}" width="${r(wW)}" height="${r(wH)}" fill="${BG}" rx="${r(3)}"/>
  <rect x="${r(wLX + 2)}" y="${r(wY + 2)}" width="${r(wW / 2 - 3)}" height="${r(wH / 2 - 3)}"
        fill="${BLUE}" opacity="0.3" rx="1"/>

  <!-- ── Right window ── -->
  <rect x="${r(wRX)}" y="${r(wY)}" width="${r(wW)}" height="${r(wH)}" fill="${BG}" rx="${r(3)}"/>
  <rect x="${r(wRX + 2)}" y="${r(wY + 2)}" width="${r(wW / 2 - 3)}" height="${r(wH / 2 - 3)}"
        fill="${BLUE}" opacity="0.3" rx="1"/>

  <!-- ── Shield door (indigo = security) ── -->
  <!-- Shield outer dark recess -->
  <rect x="${r(shieldX - 2)}" y="${r(shieldTY - 2)}" width="${r(shieldW + 4)}" height="${r(shieldH + 4)}"
        fill="${BG}" rx="${r(4)}"/>
  <!-- Shield shape -->
  <path d="
    M ${r(shieldCX)},${r(shieldTY + 2)}
    L ${r(shieldX)},${r(shieldTY + 7)}
    L ${r(shieldX)},${r(shieldTY + 22)}
    Q ${r(shieldX)},${r(shieldTY + shieldH)} ${r(shieldCX)},${r(shieldTY + shieldH + 4)}
    Q ${r(shieldX + shieldW)},${r(shieldTY + shieldH)} ${r(shieldX + shieldW)},${r(shieldTY + 22)}
    L ${r(shieldX + shieldW)},${r(shieldTY + 7)}
    Z
  " fill="${INDIGO}" opacity="0.95"/>
  <!-- Check mark inside shield -->
  <path
    d="M ${r(shieldCX - 7)},${r(shieldTY + 22)} L ${r(shieldCX - 2)},${r(shieldTY + 27)} L ${r(shieldCX + 9)},${r(shieldTY + 16)}"
    stroke="${WHITE}" stroke-width="${r(3)}" fill="none"
    stroke-linecap="round" stroke-linejoin="round"
  />

  ${showText ? `
  <!-- "FantaTech" -->
  <text
    x="${r(96)}" y="${ftY}"
    font-family="Arial Black, Arial, Helvetica, sans-serif"
    font-size="${ftSize}" font-weight="900"
    fill="${WHITE}" text-anchor="middle" opacity="0.92"
  >FantaTech</text>` : ''}
</svg>`;
}

async function writePng(svgStr, outPath) {
  const buf = Buffer.from(svgStr, 'utf-8');
  await sharp(buf, { density: 300 })
    .png({ compressionLevel: 9 })
    .toFile(outPath);
  console.log('✅', path.relative(process.cwd(), outPath));
}

(async () => {
  console.log('🎨 Generating FantaTech icons (in-app style)...\n');

  for (const { dir, size } of DENSITIES) {
    const outDir = path.join(RES, dir);
    if (!fs.existsSync(outDir)) { console.warn('⚠️  Missing dir:', outDir); continue; }

    await writePng(makeSvg(size, true),  path.join(outDir, 'ic_launcher.png'));
    await writePng(makeSvg(size, true),  path.join(outDir, 'ic_launcher_round.png'));
    await writePng(makeSvg(size, false), path.join(outDir, 'ic_launcher_foreground.png'));
  }

  console.log('\n✅  All icons generated!\n');
})();
