'use strict';
/**
 * Generates electron/icon.ico — a 256×256 ICO with an embedded PNG.
 * Uses only Node.js built-ins (zlib + Buffer). No external packages needed.
 */

const fs   = require('fs');
const path = require('path');
const zlib = require('zlib');

const outIco = path.join(__dirname, 'icon.ico');

const W = 256, H = 256;

// ── Draw a FantaTech icon on a raw RGBA pixel grid ──
const pixels = Buffer.alloc(W * H * 4, 0); // default transparent

function setPixel(x, y, r, g, b, a = 255) {
  if (x < 0 || x >= W || y < 0 || y >= H) return;
  const i = (y * W + x) * 4;
  pixels[i]     = r;
  pixels[i + 1] = g;
  pixels[i + 2] = b;
  pixels[i + 3] = a;
}

function fillRect(x0, y0, x1, y1, r, g, b, a = 255) {
  for (let y = y0; y <= y1; y++)
    for (let x = x0; x <= x1; x++)
      setPixel(x, y, r, g, b, a);
}

function circle(cx, cy, radius, r, g, b, a = 255) {
  for (let y = -radius; y <= radius; y++)
    for (let x = -radius; x <= radius; x++)
      if (x * x + y * y <= radius * radius)
        setPixel(cx + x, cy + y, r, g, b, a);
}

// Background: dark navy
fillRect(0, 0, W - 1, H - 1, 8, 15, 31);

// Rounded corner mask (simple 20px radius)
for (let y = 0; y < 20; y++) {
  for (let x = 0; x < 20; x++) {
    const dx = 20 - x, dy = 20 - y;
    if (dx * dx + dy * dy > 20 * 20) {
      setPixel(x, y, 0, 0, 0, 0);
      setPixel(W - 1 - x, y, 0, 0, 0, 0);
      setPixel(x, H - 1 - y, 0, 0, 0, 0);
      setPixel(W - 1 - x, H - 1 - y, 0, 0, 0, 0);
    }
  }
}

// House outline (white/blue glow)
const houseColor = [59, 130, 246];
// Roof triangle
for (let y = 55; y <= 115; y++) {
  const spread = Math.round((y - 55) * 0.85);
  const x0 = 128 - spread, x1 = 128 + spread;
  // only draw border
  setPixel(x0, y, ...houseColor);
  setPixel(x1, y, ...houseColor);
}
// Left/right walls (below roof peak)
for (let y = 115; y <= 165; y++) {
  setPixel(55, y, ...houseColor);
  setPixel(200, y, ...houseColor);
}
// Floor
for (let x = 55; x <= 200; x++) setPixel(x, 165, ...houseColor);

// Door (accent blue)
fillRect(106, 135, 149, 165, 59, 130, 246);

// Wifi arc dots
circle(128, 195, 5, 59, 130, 246);
for (let x = 100; x <= 156; x++) {
  const dy = Math.round(8 * Math.sin(Math.PI * (x - 100) / 56));
  setPixel(x, 185 - dy, 59, 130, 246);
}
for (let x = 84; x <= 172; x++) {
  const dy = Math.round(8 * Math.sin(Math.PI * (x - 84) / 88));
  setPixel(x, 175 - dy, 59, 130, 246, 160);
}

// "FT" letters — F in white, T in orange
// F
fillRect(30, 210, 37, 245, 241, 245, 249);   // F vertical bar
fillRect(30, 210, 55, 217, 241, 245, 249);   // F top
fillRect(30, 225, 50, 232, 241, 245, 249);   // F mid

// T
fillRect(65, 210, 100, 217, 255, 140, 0);    // T top bar
fillRect(79, 210, 86, 245, 255, 140, 0);     // T stem

// ── Encode as PNG ──
function encodePNG(width, height, rgbaPixels) {
  const IHDR = Buffer.alloc(13);
  IHDR.writeUInt32BE(width,  0);
  IHDR.writeUInt32BE(height, 4);
  IHDR[8] = 8;  // bit depth
  IHDR[9] = 6;  // RGBA color type
  IHDR[10] = 0; IHDR[11] = 0; IHDR[12] = 0;

  // Raw pixel data with filter byte (0) per row
  const raw = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    raw[y * (1 + width * 4)] = 0; // filter type: None
    rgbaPixels.copy(raw, y * (1 + width * 4) + 1, y * width * 4, (y + 1) * width * 4);
  }
  const compressed = zlib.deflateSync(raw, { level: 6 });

  function crc32(buf) {
    let crc = 0xFFFFFFFF;
    const table = crc32.table || (crc32.table = (() => {
      const t = [];
      for (let n = 0; n < 256; n++) {
        let c = n;
        for (let k = 0; k < 8; k++) c = (c & 1) ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
        t[n] = c;
      }
      return t;
    })());
    for (let i = 0; i < buf.length; i++) crc = table[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
    return (crc ^ 0xFFFFFFFF) >>> 0;
  }

  function chunk(type, data) {
    const t = Buffer.from(type, 'ascii');
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc32(Buffer.concat([t, data])));
    return Buffer.concat([len, t, data, crcBuf]);
  }

  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), // PNG signature
    chunk('IHDR', IHDR),
    chunk('IDAT', compressed),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const pngData = encodePNG(W, H, pixels);

// ── Wrap PNG in ICO format ──
const icoHeader = Buffer.alloc(6);
icoHeader.writeUInt16LE(0, 0); // reserved
icoHeader.writeUInt16LE(1, 2); // type: ICO
icoHeader.writeUInt16LE(1, 4); // 1 image

const icoEntry = Buffer.alloc(16);
icoEntry.writeUInt8(0, 0);   // width  (0 = 256)
icoEntry.writeUInt8(0, 1);   // height (0 = 256)
icoEntry.writeUInt8(0, 2);   // color count
icoEntry.writeUInt8(0, 3);   // reserved
icoEntry.writeUInt16LE(1,  4); // planes
icoEntry.writeUInt16LE(32, 6); // bpp
icoEntry.writeUInt32LE(pngData.length, 8);     // data size
icoEntry.writeUInt32LE(6 + 16,         12);    // data offset

fs.writeFileSync(outIco, Buffer.concat([icoHeader, icoEntry, pngData]));
console.log(`icon.ico created — ${W}×${H} PNG (${pngData.length} bytes) ✓`);
