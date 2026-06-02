const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--enable-unsafe-swiftshader', '--no-sandbox']
  });
  const outDir = path.join(__dirname, '..');
  
  async function newPage() {
    const page = await browser.newPage();
    await page.setViewportSize({ width: 430, height: 900 });
    page.on('console', msg => { if (msg.type()==='error') console.log('[ERR]',msg.text().substring(0,100)); });
    return page;
  }

  // ── 1. Register screen ─────────────────────────────────────────
  console.log('=== Register screen ===');
  {
    const page = await newPage();
    await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForTimeout(6000);
    
    // "הרשם עכשיו" is at bottom center ~(230, 790)
    await page.mouse.click(230, 790);
    await page.waitForTimeout(2500);
    
    await page.screenshot({ path: path.join(outDir, 'ss_register.png') });
    console.log('Register screenshot saved');
    await page.close();
  }

  // ── 2. Dashboard (login first) ────────────────────────────────
  console.log('=== Login → Dashboard ===');
  {
    const page = await newPage();
    await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForTimeout(6000);
    
    // Email field: RTL input, roughly at y=380 center x=215
    await page.mouse.click(215, 383);
    await page.waitForTimeout(300);
    await page.keyboard.type('manager@fantatech.test');
    
    // Password field: y=451
    await page.mouse.click(215, 451);
    await page.waitForTimeout(300);
    await page.keyboard.type('test1234');
    
    // "התחבר" button: y=534
    await page.mouse.click(215, 534);
    await page.waitForTimeout(5000);
    
    await page.screenshot({ path: path.join(outDir, 'ss_dashboard.png') });
    console.log('Dashboard screenshot saved');
    
    // ── 3. Profile tab ──────────────────────────────────────────
    console.log('=== Profile tab ===');
    // Bottom nav: typically 5 items across 430px width
    // Profile (last) is around x=387
    await page.mouse.click(387, 858);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(outDir, 'ss_profile.png') });
    console.log('Profile screenshot saved');
    
    // ── 4. Scroll down on profile to see home management ────────
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(outDir, 'ss_profile_bottom.png') });
    console.log('Profile bottom screenshot saved');
    
    await page.close();
  }

  await browser.close();
  console.log('All screenshots done!');
})().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
