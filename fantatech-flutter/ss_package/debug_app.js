const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Collect console messages and errors
  const messages = [];
  page.on('console', msg => messages.push(`[${msg.type()}] ${msg.text()}`));
  page.on('pageerror', err => messages.push(`[ERROR] ${err.message}`));
  
  await page.setViewportSize({ width: 430, height: 900 });
  console.log('Loading app...');
  
  try {
    await page.goto('http://localhost:53083', { waitUntil: 'networkidle', timeout: 30000 });
  } catch (e) {
    console.log('Goto timeout/error:', e.message);
  }
  
  await page.waitForTimeout(10000);
  
  console.log('=== Console messages ===');
  messages.forEach(m => console.log(m));
  
  // Check page title and body
  const title = await page.title();
  console.log('Title:', title);
  
  // Check if canvas element exists (Flutter renders to canvas)
  const canvas = await page.$('canvas');
  console.log('Canvas found:', canvas !== null);
  
  // Check for flutter-view div
  const flutterView = await page.$('flutter-view, flt-scene');
  console.log('Flutter view found:', flutterView !== null);
  
  // Get all elements in body
  const bodyHTML = await page.evaluate(() => document.body.innerHTML.substring(0, 500));
  console.log('Body HTML (first 500):', bodyHTML);
  
  await browser.close();
})().catch(e => { console.error('Script error:', e); process.exit(1); });
