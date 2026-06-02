const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Enable Flutter accessibility via JS click (bypasses viewport check)
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder[role="button"]');
    if (ph) { ph.click(); console.log('clicked placeholder'); }
  });
  await page.waitForTimeout(2000);
  
  // Check semantics
  const count = await page.evaluate(() => document.querySelectorAll('flt-semantics').length);
  console.log('Semantics count:', count);
  
  // Get clickable elements with text
  const clickables = await page.evaluate(() => {
    return [...document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"]')]
      .map(el => {
        const rect = el.getBoundingClientRect();
        return { 
          label: el.getAttribute('aria-label') || el.textContent?.trim().substring(0,40),
          x: Math.round(rect.x + rect.width/2), 
          y: Math.round(rect.y + rect.height/2),
          w: Math.round(rect.width), h: Math.round(rect.height)
        };
      })
      .filter(e => e.label);
  });
  
  console.log('Clickable elements:');
  clickables.forEach(c => console.log(JSON.stringify(c)));
  
  // Find and click register
  const regIdx = clickables.findIndex(c => c.label && (c.label.includes('הרשם') || c.label.includes('register')));
  if (regIdx >= 0) {
    console.log('Register button at:', clickables[regIdx]);
    await page.mouse.click(clickables[regIdx].x, clickables[regIdx].y);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(outDir, 'ss_register.png') });
    console.log('Register screenshot saved!');
  } else {
    console.log('Register button NOT found');
  }
  
  await browser.close();
})().catch(e => { console.error(e.message); process.exit(1); });
