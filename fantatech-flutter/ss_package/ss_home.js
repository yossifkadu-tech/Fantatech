const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--enable-unsafe-swiftshader', '--no-sandbox']
  });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  // Load + login
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  await page.mouse.click(215, 383);
  await page.waitForTimeout(300);
  await page.keyboard.type('manager@fantatech.test');
  await page.mouse.click(215, 451);
  await page.waitForTimeout(300);
  await page.keyboard.type('test1234');
  await page.mouse.click(215, 534);
  await page.waitForTimeout(4000);
  
  // Go to profile tab (leftmost nav item)
  await page.mouse.click(27, 858);
  await page.waitForTimeout(2000);
  
  // Click "הבית שלי" row (y ≈ 297 based on profile screenshot)
  await page.mouse.click(215, 297);
  await page.waitForTimeout(3000);
  
  await page.screenshot({ path: path.join(outDir, 'ss_home_mgmt.png') });
  console.log('Home management screenshot saved');
  
  // Scroll down in the sheet to see house type and color pickers
  await page.mouse.wheel(0, 400);
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(outDir, 'ss_home_mgmt2.png') });
  console.log('Home management scroll 2 saved');
  
  // Also take register screen properly
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Since user is already logged in, need fresh session for register screen
  // Actually let's just navigate directly - click register link at y~790
  // First check what screen loads
  await page.screenshot({ path: path.join(outDir, 'ss_after_reload.png') });
  console.log('After reload screenshot saved');
  
  await browser.close();
})().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
