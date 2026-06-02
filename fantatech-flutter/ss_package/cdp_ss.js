const { chromium } = require('playwright');

(async () => {
  // Launch with a real viewport (non-headless) using Playwright - this forces Flutter to render
  const browser = await chromium.launch({ 
    headless: false,
    args: ['--window-size=430,900', '--window-position=100,50', '--disable-infobars', '--no-first-run']
  });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  const errors = [];
  page.on('console', msg => {
    if (['error', 'warning'].includes(msg.type())) {
      errors.push(`[${msg.type()}] ${msg.text()}`);
    }
  });
  page.on('pageerror', err => errors.push(`[ERR] ${err.toString()}`));

  console.log('Loading app (non-headless)...');
  try {
    await page.goto('http://localhost:53083', { waitUntil: 'domcontentloaded', timeout: 15000 });
  } catch(e) {
    console.log('Nav:', e.message);
  }
  
  console.log('Waiting 15s for Flutter to render...');
  await page.waitForTimeout(15000);
  
  const canvasCount = await page.evaluate(() => document.querySelectorAll('canvas').length);
  const bodyLen = await page.evaluate(() => document.body.innerHTML.length);
  console.log(`Canvas: ${canvasCount}, Body length: ${bodyLen}`);
  
  if (errors.length) {
    console.log('Errors:');
    errors.slice(0, 20).forEach(e => console.log(e));
  }
  
  // Take screenshot via CDP - captures GPU rendered content
  await page.screenshot({ path: '../ss_login.png' });
  console.log('Screenshot saved');
  
  await browser.close();
})().catch(e => { console.error('Fatal:', e); process.exit(1); });
