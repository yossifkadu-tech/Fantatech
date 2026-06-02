const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Enable Flutter accessibility semantics
  const placeholder = await page.$('flt-semantics-placeholder[role="button"]');
  if (placeholder) {
    await placeholder.click();
    console.log('Accessibility enabled');
    await page.waitForTimeout(1500);
  }
  
  // Check semantic elements now
  const semanticsInfo = await page.evaluate(() => {
    const els = [...document.querySelectorAll('flt-semantics')];
    return els.map(el => ({
      role: el.getAttribute('role'),
      label: el.getAttribute('aria-label'),
      tag: el.getAttribute('aria-roledescription'),
      text: el.textContent?.substring(0, 60).trim()
    })).filter(e => e.label || e.text);
  });
  
  console.log(`Found ${semanticsInfo.length} semantic elements:`);
  semanticsInfo.forEach((e, i) => console.log(`${i}: role=${e.role} label="${e.label}" text="${e.text}"`));
  
  // Find register link
  const registerEl = await page.evaluate(() => {
    const els = [...document.querySelectorAll('flt-semantics')];
    return els.findIndex(el => 
      (el.getAttribute('aria-label') || '').includes('הרשם') || 
      el.textContent?.includes('הרשם')
    );
  });
  console.log('Register element index:', registerEl);
  
  await browser.close();
})().catch(e => console.error(e.message));
