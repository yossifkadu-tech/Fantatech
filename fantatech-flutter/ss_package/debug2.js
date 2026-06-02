const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--enable-logging', '--v=1']
  });
  const page = await browser.newPage();
  
  // Capture ALL console output including warnings
  const messages = [];
  page.on('console', msg => {
    if (msg.type() === 'error' || msg.type() === 'warning') {
      messages.push(`[${msg.type().toUpperCase()}] ${msg.text()}`);
    }
  });
  page.on('pageerror', err => messages.push(`[EXCEPTION] ${err.message}\n${err.stack}`));
  page.on('requestfailed', req => messages.push(`[FAILED REQUEST] ${req.url()} - ${req.failure()?.errorText}`));
  
  await page.setViewportSize({ width: 430, height: 900 });
  
  try {
    await page.goto('http://localhost:53083', { timeout: 15000 });
  } catch (e) {
    console.log('Goto error:', e.message);
  }
  
  // Wait and check body periodically
  for (let i = 0; i < 5; i++) {
    await page.waitForTimeout(3000);
    const bodyLen = await page.evaluate(() => document.body.innerHTML.length);
    const canvasCount = await page.evaluate(() => document.querySelectorAll('canvas').length);
    console.log(`[T+${(i+1)*3}s] Body length: ${bodyLen}, Canvas count: ${canvasCount}`);
  }
  
  // Check for errors
  if (messages.length > 0) {
    console.log('=== Errors/Warnings ===');
    messages.forEach(m => console.log(m));
  } else {
    console.log('No errors captured');
  }
  
  // Try evaluating $dartLoader state
  const dartState = await page.evaluate(() => {
    try {
      return JSON.stringify({
        loader: typeof window.$dartLoader,
        loaded: window.$dartLoader?.moduleIdToUrl?.size,
      });
    } catch(e) { return 'error: ' + e.message; }
  });
  console.log('Dart loader state:', dartState);

  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
