const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Use Tab key to navigate to "הרשם עכשיו" and Enter to click
  // Flutter web uses semantic overlay for a11y
  // First click on the canvas to focus it
  await page.mouse.click(215, 450);
  await page.waitForTimeout(500);
  
  // Tab through all interactive elements
  for (let i = 0; i < 15; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
  }
  await page.keyboard.press('Enter');
  await page.waitForTimeout(3000);
  
  await page.screenshot({ path: path.join(outDir, 'ss_register.png') });
  console.log('Register attempt via Tab+Enter saved');
  
  await browser.close();
})().catch(e => { console.error(e.message); process.exit(1); });
