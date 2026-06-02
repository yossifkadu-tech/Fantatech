const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--enable-unsafe-swiftshader', '--no-sandbox']
  });
  
  const outDir = path.join(__dirname, '..');
  
  async function screenshot(url, filename, waitMs = 8000) {
    const page = await browser.newPage();
    await page.setViewportSize({ width: 430, height: 900 });
    
    page.on('console', msg => {
      if (msg.type() === 'error') console.log(`[${filename} ERR] ${msg.text()}`);
    });
    page.on('pageerror', err => console.log(`[${filename} PAGEERR] ${err}`));
    
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
    } catch(e) { console.log(`${filename}: nav: ${e.message}`); }
    
    console.log(`Waiting ${waitMs}ms for ${filename}...`);
    await page.waitForTimeout(waitMs);
    
    // Check if anything rendered
    const bodyLen = await page.evaluate(() => document.body.innerHTML.length);
    const canvas = await page.evaluate(() => document.querySelectorAll('canvas').length);
    console.log(`${filename}: body=${bodyLen}, canvas=${canvas}`);
    
    await page.screenshot({ path: path.join(outDir, filename) });
    console.log(`${filename} saved`);
    await page.close();
  }
  
  // Login screen
  await screenshot('http://localhost:8091/', 'ss_login.png', 10000);
  
  await browser.close();
  console.log('Done!');
})().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
