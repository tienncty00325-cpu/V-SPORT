const puppeteer = require('puppeteer');
(async () => {
    const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--disable-setuid-sandbox"] });
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 1500 });
    await page.goto('http://localhost:8080/Backend_java/index.jsp', { waitUntil: 'networkidle0' });
    
    // Screenshot footer
    await page.screenshot({ path: 'new_part_6.png', clip: { x: 0, y: 7000, width: 1440, height: 1500 } });
    
    await browser.close();
})();
