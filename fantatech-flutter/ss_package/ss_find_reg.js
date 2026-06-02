const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Crop the bottom 150px to see exact position of "הרשם עכשיו"
  await page.screenshot({ path: path.join(outDir, 'ss_login_bottom.png'), clip: { x: 0, y: 730, width: 430, height: 170 } });
  console.log('Login bottom crop saved');

  // Try various y coords for the register link
  for (const y of [755, 770, 785, 800]) {
    await page.mouse.click(230, y);
    await page.waitForTimeout(1500);
    const url = page.url();
    const bodyLen = await page.evaluate(() => document.body.innerHTML.length);
    console.log(`click y=${y} -> bodyLen=${bodyLen}`);
    // Go back
    await page.goBack();
    await page.waitForTimeout(2000);
  }
  
  await browser.close();
})().catch(e => { console.error(e.message); process.exit(1); });
