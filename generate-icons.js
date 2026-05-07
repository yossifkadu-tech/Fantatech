/**
 * FantaTech App Icon Generator
 * Generates Android launcher icons (all mipmap densities)
 * Design: dark navy background + sky-blue house + "FantaTech" text
 * Run: node generate-icons.js
 */
const sharp = require('C:/Projects/smart-home-app/node_modules/sharp');
const fs    = require('fs');
const path  = require('path');

const RES = 'app/android/app/src/main/res';

// ── Icon sizes per density ────────────────────────────────────────────────────
const DENSITIES = [
  { dir: 'mipmap-mdpi',    size: 48  },
  { dir: 'mipmap-hdpi',    size: 72  },
  { dir: 'mipmap-xhdpi',   size: 96  },
  { dir: 'mipmap-xxhdpi',  size: 144 },
  { dir: 'mipmap-xxxhdpi', size: 192 },
];

// ── SVG icon builder ──────────────────────────────────────────────────────────
// fullBg=true  → opaque #0f172a background (for ic_launcher, ic_launcher_round)
// fullBg=false → transparent bg (for ic_launcher_foreground)
function makeSvg(sz, fullBg = true) {
  const W = sz;
  const H = sz;

  // Proportional values (designed at 192×192)
  const s = sz / 192;
  const round = (v) => Math.round(v * s * 100) / 100;

  // House geometry (at 192px base)
  const houseLeft  = 28;
  const houseRight = 164;
  const roofTop    = 34;
  const roofMid    = 95;   // eave level
  const bodyBot    = 154;
  const midX       = 96;

  // Door
  const doorW = 28, doorH = 40;
  const doorX = midX - doorW / 2;
  const doorY = bodyBot - doorH;

  // Windows
  const winW = 22, winH = 22, winY = 102;
  const winLeftX  = 42;
  const winRightX = 128;

  // Chimney
  const chimX = 116, chimY = 45, chimW = 14, chimH = 28;

  const bg    = '#0f172a';
  const blue  = '#38bdf8';
  const white = '#f1f5f9';

  const r = round;

  // Text at bottom: "FantaTech" (only for sizes ≥ 72)
  const fontSize = Math.max(r(18), 8);
  const showText = sz >= 72;

  return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg">
  ${fullBg ? `<rect width="${W}" height="${H}" fill="${bg}"/>` : ''}

  <!-- Chimney -->
  <rect x="${r(chimX)}" y="${r(chimY)}" width="${r(chimW)}" height="${r(chimH)}" fill="${blue}" rx="${r(2)}"/>

  <!-- Roof (triangle) -->
  <polygon points="${r(midX)},${r(roofTop)} ${r(houseRight)},${r(roofMid)} ${r(houseLeft)},${r(roofMid)}" fill="${blue}"/>

  <!-- House body -->
  <rect x="${r(houseLeft)}" y="${r(roofMid - 4)}" width="${r(houseRight - houseLeft)}" height="${r(bodyBot - roofMid + 4)}" fill="${blue}" rx="${r(3)}"/>

  <!-- Left window -->
  <rect x="${r(winLeftX)}" y="${r(winY)}" width="${r(winW)}" height="${r(winH)}" fill="${bg}" rx="${r(3)}"/>
  <rect x="${r(winLeftX + 1)}" y="${r(winY + 1)}" width="${r(winW / 2 - 2)}" height="${r(winH / 2 - 2)}" fill="${blue}" opacity="0.35" rx="1"/>

  <!-- Right window -->
  <rect x="${r(winRightX)}" y="${r(winY)}" width="${r(winW)}" height="${r(winH)}" fill="${bg}" rx="${r(3)}"/>
  <rect x="${r(winRightX + 1)}" y="${r(winY + 1)}" width="${r(winW / 2 - 2)}" height="${r(winH / 2 - 2)}" fill="${blue}" opacity="0.35" rx="1"/>

  <!-- Door -->
  <rect x="${r(doorX)}" y="${r(doorY)}" width="${r(doorW)}" height="${r(doorH)}" fill="${bg}" rx="${r(4)}"/>
  <!-- Door knob -->
  <circle cx="${r(doorX + doorW - 6)}" cy="${r(doorY + doorH / 2)}" r="${r(2.5)}" fill="${blue}" opacity="0.7"/>

  <!-- Roof ridge highlight -->
  <line x1="${r(midX)}" y1="${r(roofTop + 2)}" x2="${r(midX)}" y2="${r(roofMid - 2)}" stroke="${white}" stroke-width="${r(1.5)}" opacity="0.25"/>

  ${showText ? `
  <!-- "FantaTech" branding -->
  <text
    x="${r(midX)}" y="${r(175)}"
    font-family="Arial, Helvetica, sans-serif"
    font-size="${r(22)}"
    font-weight="900"
    fill="${white}"
    text-anchor="middle"
    letter-spacing="${r(-0.5)}"
  >FantaTech</text>` : ''}
</svg>`;
}

// ── Generate foreground SVG (for adaptive icon — transparent bg, content in safe zone 18–90dp/192px scale) ──
function makeForegroundSvg(sz) {
  // For foreground, same design but no background, content scaled to safe zone
  // Safe zone: 18dp–90dp on 108dp canvas → scale: 18/108 to 90/108
  // We keep it simple: just draw the house at center within safe zone
  return makeSvg(sz, false);
}

// ── Write PNG ─────────────────────────────────────────────────────────────────
async function writePng(svgStr, outPath) {
  const buf = Buffer.from(svgStr, 'utf-8');
  await sharp(buf, { density: 300 }).png({ compressionLevel: 9 }).toFile(outPath);
  console.log('✅', path.relative(process.cwd(), outPath));
}

// ── Main ──────────────────────────────────────────────────────────────────────
(async () => {
  console.log('🎨 Generating FantaTech icons...\n');

  for (const { dir, size } of DENSITIES) {
    const outDir = path.join(RES, dir);
    if (!fs.existsSync(outDir)) { console.warn('⚠️ Missing:', outDir); continue; }

    // ic_launcher.png (regular square)
    await writePng(makeSvg(size, true),  path.join(outDir, 'ic_launcher.png'));

    // ic_launcher_round.png (round — same design, Android clips it)
    await writePng(makeSvg(size, true),  path.join(outDir, 'ic_launcher_round.png'));

    // ic_launcher_foreground.png (adaptive icon foreground layer)
    await writePng(makeForegroundSvg(size), path.join(outDir, 'ic_launcher_foreground.png'));
  }

  console.log('\n✅ All icons generated!');
})();
