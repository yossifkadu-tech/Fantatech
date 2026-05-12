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

const BG      = '#0f172a';   // deep navy background
const ORANGE  = '#f97316';   // roof, chimney, door, window frames
const ORANGE2 = '#ea580c';   // roof shadow / chimney shade
const WALL    = '#ffffff';   // white walls
const WIN_BG  = '#bae6fd';   // window glass — light sky blue
const WIN_FR  = '#f97316';   // window frame — orange
const BLUE    = '#38bdf8';   // "FantaTech" text colour

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
 * FantaTech icon
 *  - Dark navy background
 *  - Orange roof + chimney (like the in-app 🏠 emoji)
 *  - White walls
 *  - Orange-framed windows with sky-blue glass
 *  - Orange door (arch top)
 *  - "FantaTech" in sky-blue bold text
 * Designed at 192×192 base; everything scales via s = sz/192.
 */
function makeSvg(sz, fullBg = true) {
  const s = sz / 192;
  const r = v => +(v * s).toFixed(2);

  return `<svg width="${sz}" height="${sz}" viewBox="0 0 ${sz} ${sz}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="roofG${sz}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#fb923c"/>
      <stop offset="100%" stop-color="${ORANGE2}"/>
    </linearGradient>
  </defs>

  ${fullBg ? `<rect width="${sz}" height="${sz}" fill="${BG}" rx="${r(28)}"/>` : ''}

  <!-- ═══ CHIMNEY (behind roof so roof overlaps base) ═══ -->
  <rect x="${r(126)}" y="${r(22)}" width="${r(18)}" height="${r(46)}"
        fill="${ORANGE2}" rx="${r(3)}"/>
  <!-- chimney top cap -->
  <rect x="${r(122)}" y="${r(20)}" width="${r(26)}" height="${r(7)}"
        fill="${ORANGE}" rx="${r(3)}"/>
  <!-- chimney smoke holes -->
  <circle cx="${r(131)}" cy="${r(15)}" r="${r(3)}" fill="${BG}" opacity="0.4"/>
  <circle cx="${r(140)}" cy="${r(11)}" r="${r(2.5)}" fill="${BG}" opacity="0.3"/>

  <!-- ═══ ROOF (orange triangle + overhang) ═══ -->
  <polygon
    points="${r(96)},${r(26)} ${r(176)},${r(90)} ${r(16)},${r(90)}"
    fill="url(#roofG${sz})"
  />
  <!-- roof overhang ledge -->
  <rect x="${r(14)}" y="${r(86)}" width="${r(164)}" height="${r(10)}"
        fill="${ORANGE2}" rx="${r(2)}"/>

  <!-- ═══ WALLS (white body) ═══ -->
  <rect x="${r(22)}" y="${r(90)}" width="${r(148)}" height="${r(66)}"
        fill="${WALL}" rx="${r(4)}"/>

  <!-- ═══ LEFT WINDOW ═══ -->
  <!-- frame -->
  <rect x="${r(32)}" y="${r(100)}" width="${r(34)}" height="${r(28)}"
        fill="${WIN_FR}" rx="${r(4)}"/>
  <!-- glass -->
  <rect x="${r(35)}" y="${r(103)}" width="${r(28)}" height="${r(22)}"
        fill="${WIN_BG}" rx="${r(2)}"/>
  <!-- cross divider -->
  <line x1="${r(49)}" y1="${r(103)}" x2="${r(49)}" y2="${r(125)}"
        stroke="${WIN_FR}" stroke-width="${r(2)}"/>
  <line x1="${r(35)}" y1="${r(114)}" x2="${r(63)}" y2="${r(114)}"
        stroke="${WIN_FR}" stroke-width="${r(2)}"/>

  <!-- ═══ RIGHT WINDOW ═══ -->
  <rect x="${r(126)}" y="${r(100)}" width="${r(34)}" height="${r(28)}"
        fill="${WIN_FR}" rx="${r(4)}"/>
  <rect x="${r(129)}" y="${r(103)}" width="${r(28)}" height="${r(22)}"
        fill="${WIN_BG}" rx="${r(2)}"/>
  <line x1="${r(143)}" y1="${r(103)}" x2="${r(143)}" y2="${r(125)}"
        stroke="${WIN_FR}" stroke-width="${r(2)}"/>
  <line x1="${r(129)}" y1="${r(114)}" x2="${r(157)}" y2="${r(114)}"
        stroke="${WIN_FR}" stroke-width="${r(2)}"/>

  <!-- ═══ DOOR (orange, arch top, centered) ═══ -->
  <!-- door frame -->
  <rect x="${r(78)}" y="${r(112)}" width="${r(36)}" height="${r(44)}"
        fill="${ORANGE}" rx="${r(3)}"/>
  <ellipse cx="${r(96)}" cy="${r(112)}" rx="${r(18)}" ry="${r(14)}"
           fill="${ORANGE}"/>
  <!-- door panel (slightly darker) -->
  <rect x="${r(81)}" y="${r(116)}" width="${r(30)}" height="${r(40)}"
        fill="${ORANGE2}" rx="${r(2)}"/>
  <ellipse cx="${r(96)}" cy="${r(116)}" rx="${r(15)}" ry="${r(11)}"
           fill="${ORANGE2}"/>
  <!-- door knob -->
  <circle cx="${r(88)}" cy="${r(136)}" r="${r(3)}" fill="${ORANGE}" opacity="0.9"/>

  ${sz >= 72 ? `
  <!-- ═══ "FantaTech" text ═══ -->
  <text
    x="${r(96)}" y="${r(174)}"
    font-family="Arial Black, Arial, Helvetica, sans-serif"
    font-size="${r(19)}" font-weight="900"
    fill="${BLUE}" text-anchor="middle" letter-spacing="${r(-0.5)}"
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

// iOS icon sizes required by App Store + Xcode
const IOS_SIZES = [
  20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
];
const IOS_DIR = 'app/ios/App/App/Assets.xcassets/AppIcon.appiconset';

(async () => {
  console.log('🎨 Generating FantaTech icons...\n');

  // ── Android ──
  console.log('📱 Android icons:');
  for (const { dir, size } of DENSITIES) {
    const outDir = path.join(RES, dir);
    if (!fs.existsSync(outDir)) { console.warn('⚠️  Missing dir:', outDir); continue; }
    await writePng(makeSvg(size, true),  path.join(outDir, 'ic_launcher.png'));
    await writePng(makeSvg(size, true),  path.join(outDir, 'ic_launcher_round.png'));
    await writePng(makeSvg(size, false), path.join(outDir, 'ic_launcher_foreground.png'));
  }

  // ── iOS ──
  if (fs.existsSync(IOS_DIR)) {
    console.log('\n🍎 iOS icons:');
    for (const size of IOS_SIZES) {
      await writePng(makeSvg(size, true), path.join(IOS_DIR, `AppIcon-${size}.png`));
    }

    // Write Contents.json for Xcode
    const contents = {
      images: IOS_SIZES.map(sz => ({
        filename: `AppIcon-${sz}.png`,
        idiom:    sz >= 167 ? 'ipad' : sz === 1024 ? 'ios-marketing' : 'iphone',
        scale:    sz === 1024 ? '1x' : '2x',
        size:     `${Math.round(sz / 2)}x${Math.round(sz / 2)}`,
      })),
      info: { author: 'xcode', version: 1 },
    };
    fs.writeFileSync(path.join(IOS_DIR, 'Contents.json'), JSON.stringify(contents, null, 2));
    console.log('✅  iOS Contents.json written');
  } else {
    console.log('\n⚠️  iOS dir not found — skipping iOS icons');
    console.log('   Run: npx cap add ios  (then re-run this script)');
  }

  console.log('\n✅  All icons generated!\n');
})();
