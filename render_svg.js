const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
    const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox", "--disable-setuid-sandbox"] });
    const page = await browser.newPage();
    const filePath = `file://${path.join(__dirname, 'chowdeck.com.svg')}`;
    
    await page.setViewport({ width: 1440, height: 1500 });
    await page.goto(filePath, { waitUntil: 'networkidle0' });
    
    // Get total height of SVG
    const svgHeight = await page.evaluate(() => {
        const svg = document.querySelector('svg');
        return svg ? svg.getBoundingClientRect().height : 10813;
    });
    
    console.log(`SVG total height: ${svgHeight}`);
    
    const numScreenshots = Math.ceil(svgHeight / 1500);
    
    for (let i = 0; i < numScreenshots; i++) {
        await page.setViewport({ width: 1440, height: 1500 });
        await page.evaluate((y) => {
            window.scrollTo(0, y);
        }, i * 1500);
        
        // Wait a bit for scroll
        await new Promise(r => setTimeout(r, 200));
        
        await page.screenshot({ path: `svg_part_${i+1}.png` });
        console.log(`Saved svg_part_${i+1}.png`);
    }
    
    await browser.close();
})();
