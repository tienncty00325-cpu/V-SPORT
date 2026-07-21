const puppeteer = require('puppeteer');
(async () => {
    const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--disable-setuid-sandbox"] });
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 1500 });
    await page.goto('http://localhost:8080/Backend_java/index.jsp', { waitUntil: 'networkidle0' });
    
    // Take a full page screenshot or just 2 parts
    await page.screenshot({ path: 'new_part_1.png', clip: { x: 0, y: 0, width: 1440, height: 1500 } });
    await page.screenshot({ path: 'new_part_2.png', clip: { x: 0, y: 1500, width: 1440, height: 1500 } });
    await page.screenshot({ path: 'new_part_3.png', clip: { x: 0, y: 3000, width: 1440, height: 1500 } });
    await page.screenshot({ path: 'new_part_4.png', clip: { x: 0, y: 4500, width: 1440, height: 1500 } });
    await page.screenshot({ path: 'new_part_5.png', clip: { x: 0, y: 6000, width: 1440, height: 1500 } });
    
    await browser.close();
})();
