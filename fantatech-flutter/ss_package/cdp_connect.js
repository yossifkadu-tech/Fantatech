const http = require('http');
const { chromium } = require('playwright');

// Connect to system Chrome via CDP (not spawn a new one)
async function connectToChrome() {
  return new Promise((resolve, reject) => {
    const req = http.get('http://localhost:9222/json/version', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    });
    req.on('error', reject);
    req.setTimeout(3000, () => reject(new Error('timeout')));
  });
}

(async () => {
  try {
    const version = await connectToChrome();
    console.log('Chrome version:', version.Browser);
    
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    const pages = browser.contexts()[0]?.pages() || [];
    console.log('Pages:', pages.length);
    
    if (pages.length > 0) {
      const page = pages[0];
      await page.waitForTimeout(3000);
      await page.screenshot({ path: '../ss_login.png' });
      console.log('Screenshot taken via CDP');
    }
    
    await browser.close();
  } catch (e) {
    console.log('CDP connect failed:', e.message);
  }
})();
