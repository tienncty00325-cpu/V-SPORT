const puppeteer = require('puppeteer');
(async () => {
    const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--disable-setuid-sandbox"] });
    
    // Desktop screenshot
    const pageDesktop = await browser.newPage();
    await pageDesktop.setViewport({ width: 1440, height: 900 });
    await pageDesktop.goto('http://localhost:8080/Backend_java/index.jsp', { waitUntil: 'networkidle0' });
    await pageDesktop.screenshot({ path: 'slider_desktop.png', clip: { x: 0, y: 0, width: 1440, height: 900 } });
    await pageDesktop.close();

    // Mobile screenshot
    const pageMobile = await browser.newPage();
    await pageMobile.setViewport({ width: 390, height: 844, isMobile: true, hasTouch: true });
    await pageMobile.goto('http://localhost:8080/Backend_java/index.jsp', { waitUntil: 'networkidle0' });
    await pageMobile.screenshot({ path: 'slider_mobile.png', clip: { x: 0, y: 0, width: 390, height: 844 } });
    await pageMobile.close();

    await browser.close();
})();
