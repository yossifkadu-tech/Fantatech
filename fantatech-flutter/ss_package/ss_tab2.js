const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Try 16 Tabs (one more than previous 15 which landed on household button)
  await page.mouse.click(215, 450);
  await page.waitForTimeout(500);
  for (let i = 0; i < 16; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
  }
  await page.keyboard.press('Enter');
  await page.waitForTimeout(3000);
  
  await page.screenshot({ path: path.join(outDir, 'ss_register.png') });
  console.log('Saved');
  await browser.close();
})().catch(e => console.error(e.message));
