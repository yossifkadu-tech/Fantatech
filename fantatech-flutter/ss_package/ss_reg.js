const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);

  // "הרשם עכשיו" is at approx y=745 in full screenshot (730+15)
  await page.mouse.click(185, 745);  // "הרשם" text is to the right side (RTL)
  await page.waitForTimeout(3000);
  
  await page.screenshot({ path: path.join(outDir, 'ss_register.png') });
  console.log('Register screenshot saved');
  
  await browser.close();
})().catch(e => { console.error(e.message); process.exit(1); });
