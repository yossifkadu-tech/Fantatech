const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  
  for (const n of [9, 10, 11, 12, 13, 14]) {
    const page = await browser.newPage();
    await page.setViewportSize({ width: 430, height: 900 });
    await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForTimeout(5000);
    
    await page.mouse.click(215, 450);
    await page.waitForTimeout(300);
    for (let i = 0; i < n; i++) { await page.keyboard.press('Tab'); await page.waitForTimeout(150); }
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2500);
    
    // Take top-100px crop to see screen title
    await page.screenshot({ path: path.join(outDir, `tab_test_${n}.png`), clip: {x:0,y:0,width:430,height:120} });
    await page.close();
    console.log(`n=${n} done`);
  }
  
  await browser.close();
})().catch(e => console.error(e.message));
