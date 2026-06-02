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
  
  // Load app
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Login
  await page.mouse.click(215, 383);
  await page.waitForTimeout(300);
  await page.keyboard.type('manager@fantatech.test');
  await page.mouse.click(215, 451);
  await page.waitForTimeout(300);
  await page.keyboard.type('test1234');
  await page.mouse.click(215, 534);
  await page.waitForTimeout(5000);
  
  // Screenshot current nav bar position
  await page.screenshot({ path: path.join(outDir, 'ss_nav_check.png') });
  console.log('Nav check saved');
  
  // Bottom nav has 8 items from left to right: פרופיל, חנות, סייבר, אבטחה, AI, צלמות, מכשירים, בית
  // Profile (פרופיל) is leftmost: x ≈ 430/8 * 0.5 = 27px, y ≈ 858
  // Let's try clicking at the leftmost nav item
  await page.mouse.click(27, 858);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(outDir, 'ss_profile.png') });
  console.log('Profile screenshot saved');
  
  // Also try zoom to see bottom nav clearly
  await page.screenshot({ path: path.join(outDir, 'ss_profile_full.png'), clip: { x: 0, y: 820, width: 430, height: 80 } });
  console.log('Nav bar crop saved');
  
  await browser.close();
})().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
