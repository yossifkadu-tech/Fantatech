const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 430, height: 900 });
  
  await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);
  
  // Check DOM structure
  const domInfo = await page.evaluate(() => {
    const body = document.body;
    const allEls = [...document.querySelectorAll('*')];
    const tags = [...new Set(allEls.map(e => e.tagName))].join(', ');
    
    // Look for flt-semantics (Flutter accessibility)
    const semantics = document.querySelectorAll('flt-semantics');
    const interactable = document.querySelectorAll('[role="button"], [tabindex], button, a, input');
    
    // Get all elements with click-like roles
    const clickables = [...document.querySelectorAll('[role="button"], [tabindex="0"]')]
      .map(el => ({ tag: el.tagName, role: el.getAttribute('role'), label: el.getAttribute('aria-label'), text: el.textContent?.substring(0,50) }));
    
    return {
      tags,
      semanticsCount: semantics.length,
      interactableCount: interactable.length,
      clickables: clickables.slice(0, 30)
    };
  });
  
  console.log('Tags:', domInfo.tags);
  console.log('Semantics elements:', domInfo.semanticsCount);
  console.log('Interactable:', domInfo.interactableCount);
  console.log('Clickables (first 30):');
  domInfo.clickables.forEach(c => console.log(JSON.stringify(c)));
  
  await browser.close();
})().catch(e => console.error(e.message));
