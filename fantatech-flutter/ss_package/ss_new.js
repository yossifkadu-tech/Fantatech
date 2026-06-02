const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir  = path.join(__dirname, '..');
  const page    = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  await page.goto('http://localhost:9292/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(10000);
  await page.screenshot({ path: path.join(outDir, 'ss_new_icon.png') });
  console.log('Saved');
  await browser.close();
})().catch(e => { console.error(e.message); process.exit(1); });
