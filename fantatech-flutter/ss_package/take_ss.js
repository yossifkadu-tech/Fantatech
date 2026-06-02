const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  console.log('Loading Flutter app...');
  await page.goto('http://localhost:53083', { waitUntil: 'networkidle', timeout: 60000 });
  console.log('Page loaded, waiting for Flutter render...');
  await page.waitForTimeout(6000);
  
  const outDir = path.join(__dirname, '..');
  await page.screenshot({ path: path.join(outDir, 'ss_login.png') });
  console.log('Login screenshot saved');
  
  await browser.close();
  console.log('Done!');
})().catch(e => { console.error(e); process.exit(1); });
