const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  const errors = [];
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('Error') || text.includes('error') || text.includes('Exception')) {
      errors.push(`[${msg.type()}] ${text}`);
    }
  });
  page.on('pageerror', err => errors.push(`[PAGEERROR] ${err.toString()}`));

  await page.setViewportSize({ width: 430, height: 900 });
  
  // Add error catching script before page loads
  await page.addInitScript(() => {
    window.addEventListener('error', (e) => {
      console.error('Global error: ' + e.message + ' at ' + e.filename + ':' + e.lineno);
    });
    window.addEventListener('unhandledrejection', (e) => {
      console.error('Unhandled promise rejection: ' + e.reason);
    });
  });
  
  try {
    await page.goto('http://localhost:53083', { waitUntil: 'domcontentloaded', timeout: 30000 });
  } catch(e) {
    console.log('Nav error:', e.message);
  }
  
  console.log('DOM loaded, waiting 20s for Flutter...');
  await page.waitForTimeout(20000);
  
  const bodyLen = await page.evaluate(() => document.body.innerHTML.length);
  const canvasCount = await page.evaluate(() => document.querySelectorAll('canvas').length);
  const allTags = await page.evaluate(() => Array.from(new Set([...document.querySelectorAll('*')].map(e => e.tagName))).join(', '));
  
  console.log(`Body length: ${bodyLen}, Canvas: ${canvasCount}`);
  console.log('Tags on page:', allTags);
  
  if (errors.length) {
    console.log('ERRORS:');
    errors.forEach(e => console.log(e));
  }
  
  // Check for dart-app-ready event
  const dartReady = await page.evaluate(() => window._dartAppReady || false);
  console.log('Dart app ready:', dartReady);
  
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
