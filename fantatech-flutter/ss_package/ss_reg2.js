const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader','--no-sandbox'] });
  const outDir = path.join(__dirname, '..');
  
  // Try all y values near the register link, take screenshot after each click
  for (const [x, y] of [[185,745],[160,745],[130,745],[185,760],[160,760],[130,760],[185,750],[185,755]]) {
    const page = await browser.newPage();
    await page.setViewportSize({ width: 430, height: 900 });
    await page.goto('http://localhost:8091/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForTimeout(5000);
    
    await page.mouse.click(x, y);
    await page.waitForTimeout(2500);
    
    // Check if screen changed by looking at body hash (different screen = different body)
    const bodyLen = await page.evaluate(() => document.body.innerHTML.length);
    // Take small crop at top to check screen title
    await page.screenshot({ path: path.join(outDir, `reg_try_${x}_${y}.png`), clip: {x:0,y:0,width:430,height:120} });
    console.log(`(${x},${y}) bodyLen=${bodyLen}`);
    await page.close();
  }
  
  await browser.close();
})().catch(e => { console.error(e.message); process.exit(1); });
