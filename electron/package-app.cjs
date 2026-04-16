'use strict';
/**
 * Packages the Electron app using @electron/packager.
 * Produces:  release/FantaTech-win32-x64/FantaTech.exe
 * Then zips it to: release/FantaTech-Windows-x64.zip
 */

const { packager } = require('@electron/packager');
const path     = require('path');
const fs       = require('fs');
const zlib     = require('zlib');

const ROOT = path.join(__dirname, '..');

async function main() {
  console.log('📦 Packaging with @electron/packager…');

  const appPaths = await packager({
    dir:          ROOT,
    out:          path.join(ROOT, 'release'),
    name:         'FantaTech',
    platform:     'win32',
    arch:         'x64',
    icon:         path.join(__dirname, 'icon.ico'),
    overwrite:    true,
    prune:        true,
    asar:         true,
    // Only include what Electron needs — exclude heavy dev deps and source
    ignore: [
      /^\/src/,
      /^\/public/,
      /^\/node_modules\/.cache/,
      /^\/\.git/,
      /^\/release/,
      /^\/electron\/package-app\.cjs/,
    ],
    appVersion:   '1.0.0',
    win32metadata: {
      CompanyName:      'FantaTech',
      FileDescription:  'Smart Home & Security Dashboard',
      ProductName:      'FantaTech',
      InternalName:     'fantatech',
    },
  });

  const outDir = appPaths[0];
  console.log(`✓ App packaged → ${outDir}`);

  // Zip the output folder
  const zipPath = path.join(ROOT, 'release', 'FantaTech-Windows-x64.zip');
  console.log(`🗜  Creating zip → ${zipPath}`);
  await zipDir(outDir, zipPath);
  console.log(`✓ ZIP created → ${zipPath}`);
}

// ── Minimal recursive zip using Node built-ins ──
async function zipDir(srcDir, destZip) {
  // We'll collect all files then write a valid ZIP
  const entries = [];
  collectFiles(srcDir, srcDir, entries);

  const parts = [];
  const centralDir = [];
  let offset = 0;

  for (const { rel, abs } of entries) {
    const data      = fs.readFileSync(abs);
    const compressed= zlib.deflateRawSync(data);
    const crc       = crc32(data);
    const nameBytes = Buffer.from(rel.replace(/\\/g, '/'), 'utf8');

    // Local file header
    const lf = Buffer.alloc(30 + nameBytes.length);
    lf.writeUInt32LE(0x04034b50, 0);  // signature
    lf.writeUInt16LE(20, 4);          // version needed
    lf.writeUInt16LE(0, 6);           // flags
    lf.writeUInt16LE(8, 8);           // deflate
    lf.writeUInt16LE(0, 10);          // mod time
    lf.writeUInt16LE(0, 12);          // mod date
    lf.writeUInt32LE(crc, 14);
    lf.writeUInt32LE(compressed.length, 18);
    lf.writeUInt32LE(data.length, 22);
    lf.writeUInt16LE(nameBytes.length, 26);
    lf.writeUInt16LE(0, 28);          // extra length
    nameBytes.copy(lf, 30);

    parts.push(lf, compressed);

    // Central directory record
    const cd = Buffer.alloc(46 + nameBytes.length);
    cd.writeUInt32LE(0x02014b50, 0);  // signature
    cd.writeUInt16LE(20, 4);          // version made by
    cd.writeUInt16LE(20, 6);          // version needed
    cd.writeUInt16LE(0, 8);           // flags
    cd.writeUInt16LE(8, 10);          // deflate
    cd.writeUInt16LE(0, 12);          // mod time
    cd.writeUInt16LE(0, 14);          // mod date
    cd.writeUInt32LE(crc, 16);
    cd.writeUInt32LE(compressed.length, 20);
    cd.writeUInt32LE(data.length, 24);
    cd.writeUInt16LE(nameBytes.length, 28);
    cd.writeUInt16LE(0, 30);          // extra
    cd.writeUInt16LE(0, 32);          // comment
    cd.writeUInt16LE(0, 34);          // disk start
    cd.writeUInt16LE(0, 36);          // int attribs
    cd.writeUInt32LE(0, 38);          // ext attribs
    cd.writeUInt32LE(offset, 42);     // local header offset
    nameBytes.copy(cd, 46);
    centralDir.push(cd);

    offset += lf.length + compressed.length;
  }

  const cdBuf  = Buffer.concat(centralDir);
  const eocd   = Buffer.alloc(22);
  eocd.writeUInt32LE(0x06054b50, 0);
  eocd.writeUInt16LE(0, 4);
  eocd.writeUInt16LE(0, 6);
  eocd.writeUInt16LE(entries.length, 8);
  eocd.writeUInt16LE(entries.length, 10);
  eocd.writeUInt32LE(cdBuf.length, 12);
  eocd.writeUInt32LE(offset, 16);
  eocd.writeUInt16LE(0, 20);

  fs.writeFileSync(destZip, Buffer.concat([...parts, cdBuf, eocd]));
}

function collectFiles(base, dir, out) {
  for (const name of fs.readdirSync(dir)) {
    const abs = path.join(dir, name);
    const rel = path.relative(base, abs);
    if (fs.statSync(abs).isDirectory()) {
      collectFiles(base, abs, out);
    } else {
      out.push({ rel, abs });
    }
  }
}

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  if (!crc32.table) {
    crc32.table = Array.from({ length: 256 }, (_, n) => {
      let c = n;
      for (let k = 0; k < 8; k++) c = (c & 1) ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
      return c;
    });
  }
  for (const byte of buf) crc = crc32.table[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

main().catch(e => { console.error(e); process.exit(1); });
