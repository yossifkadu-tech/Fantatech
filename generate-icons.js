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

const BG    = '#0f172a';
const BLUE  = '#38bdf8';
const WHITE = '#f1f5f9';

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
function makeSvg(sz, fullBg = true) {
  const s = sz / 192;
  const r = v => +(v * s).toFixed(2);

  /* ── House geometry (base 192px) ── */
  // Roof
  const roofApexX  = 96,   roofApexY  = 30;
  const roofLeftX  = 18,   roofRightX = 174;
  const roofBaseY  = 94;

  // Body
  const bodyL   = 28,  bodyR  = 164;
  const bodyTop = 90,  bodyBt = 150;

  // Door (rounded top)
  const dW = 30, dH = 44;
  const dX = 96 - dW / 2;
  const dY = bodyBt - dH;

  // Windows (square, symmetrical)
  const wW = 24, wH = 22, wY = 100;
  const wLX = 40;
  const wRX = 128;

  // Text (only for icons ≥ 72px)
  const showText = sz >= 72;
  const ftSize   = r(20);
  const ftY      = r(173);

  return `<svg width="${sz}" height="${sz}" viewBox="0 0 ${sz} ${sz}" xmlns="http://www.w3.org/2000/svg">
  ${fullBg ? `<rect width="${sz}" height="${sz}" fill="${BG}" rx="${r(24)}"/>` : ''}

  <!-- Roof triangle — matches simple emoji shape -->
  <polygon
    points="${r(roofApexX)},${r(roofApexY)} ${r(roofRightX)},${r(roofBaseY)} ${r(roofLeftX)},${r(roofBaseY)}"
    fill="${BLUE}"
  />

  <!-- Roof overhang cap -->
  <rect x="${r(roofLeftX)}" y="${r(roofBaseY - 4)}" width="${r(roofRightX - roofLeftX)}" height="${r(8)}" fill="${BLUE}" rx="${r(2)}"/>

  <!-- House body -->
  <rect x="${r(bodyL)}" y="${r(bodyTop)}" width="${r(bodyR - bodyL)}" height="${r(bodyBt - bodyTop)}" fill="${BLUE}" rx="${r(4)}"/>

  <!-- Left window -->
  <rect x="${r(wLX)}" y="${r(wY)}" width="${r(wW)}" height="${r(wH)}" fill="${BG}" rx="${r(3)}"/>
  <!-- Left window inner highlight -->
  <rect x="${r(wLX + 2)}" y="${r(wY + 2)}" width="${r(wW / 2 - 3)}" height="${r(wH / 2 - 3)}" fill="${BLUE}" opacity="0.4" rx="1"/>

  <!-- Right window -->
  <rect x="${r(wRX)}" y="${r(wY)}" width="${r(wW)}" height="${r(wH)}" fill="${BG}" rx="${r(3)}"/>
  <!-- Right window inner highlight -->
  <rect x="${r(wRX + 2)}" y="${r(wY + 2)}" width="${r(wW / 2 - 3)}" height="${r(wH / 2 - 3)}" fill="${BLUE}" opacity="0.4" rx="1"/>

  <!-- Door — rounded top arch -->
  <rect x="${r(dX)}" y="${r(dY + dW / 2)}" width="${r(dW)}" height="${r(dH - dW / 2)}" fill="${BG}"/>
  <ellipse cx="${r(dX + dW / 2)}" cy="${r(dY + dW / 2)}" rx="${r(dW / 2)}" ry="${r(dW / 2)}" fill="${BG}"/>
  <!-- Door knob -->
  <circle cx="${r(dX + dW - 6)}" cy="${r(dY + dH * 0.55)}" r="${r(2.5)}" fill="${BLUE}" opacity="0.8"/>

  ${showText ? `
  <!-- "FantaTech" — same font/weight/colour as the app header -->
  <text
    x="${r(96)}" y="${ftY}"
    font-family="Arial Black, Arial, Helvetica, sans-serif"
    font-size="${ftSize}"
    font-weight="900"
    fill="${BLUE}"
    text-anchor="middle"
    letter-spacing="-0.3"
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
