#!/usr/bin/env node
/**
 * Generate KaTeX reference PNGs for golden test comparison.
 * Reads test_cases.txt, renders each formula with KaTeX in a headless browser,
 * and saves screenshots to the fixtures directory.
 */
import { readFileSync, writeFileSync, unlinkSync, mkdirSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import puppeteer from 'puppeteer';

const __dirname = dirname(fileURLToPath(import.meta.url));
const KATEX_DIST = join(__dirname, 'node_modules', 'katex', 'dist');

async function main() {
    const testCasesPath = process.argv[2] || join(__dirname, '..', '..', 'tests', 'golden', 'test_cases.txt');
    const outputDir = process.argv[3] || join(__dirname, '..', '..', 'tests', 'golden', 'fixtures');

    if (!existsSync(outputDir)) {
        mkdirSync(outputDir, { recursive: true });
    }

    const lines = readFileSync(testCasesPath, 'utf8')
        .split('\n')
        .filter(l => l.trim() && !l.trim().startsWith('#'));

    console.log(`Generating ${lines.length} reference PNGs...`);

    // Write temp HTML in KaTeX dist dir so relative font paths resolve correctly
    const tempHtml = join(KATEX_DIST, '_golden_render.html');
    const html = `<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="katex.min.css">
<style>
body { margin: 0; padding: 0; background: white; }
#formula {
    display: inline-block;
    padding: 10px;
    font-size: 20px;
}
</style>
<script src="katex.min.js"></script>
</head>
<body>
<div id="formula"></div>
</body>
</html>`;
    writeFileSync(tempHtml, html);

    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--allow-file-access-from-files'],
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 800, height: 600, deviceScaleFactor: 2 });

    // Navigate to file URL — CSS relative paths (fonts/...) resolve from KaTeX dist dir
    await page.goto(pathToFileURL(tempHtml).href, { waitUntil: 'networkidle0' });

    let ok = 0;
    let errors = 0;
    let fontsChecked = false;
    for (let i = 0; i < lines.length; i++) {
        const expr = lines[i].trim();
        const idx = String(i + 1).padStart(4, '0');

        try {
            await page.evaluate(async (expr) => {
                const el = document.getElementById('formula');
                el.innerHTML = '';
                katex.render(expr, el, {
                    displayMode: true,
                    throwOnError: false,
                    trust: true,
                });
                await document.fonts.ready;
            }, expr);

            await page.waitForSelector('#formula .katex', { timeout: 2000 });

            // Verify fonts loaded after first render
            if (!fontsChecked) {
                const fontsLoaded = await page.evaluate(async () => {
                    await document.fonts.ready;
                    const loaded = [];
                    for (const font of document.fonts) {
                        if (font.status === 'loaded') loaded.push(font.family);
                    }
                    return [...new Set(loaded)];
                });
                console.log(`KaTeX fonts loaded: ${fontsLoaded.length} families`);
                if (fontsLoaded.length > 0) {
                    console.log(`  ${fontsLoaded.join(', ')}`);
                } else {
                    console.error('WARNING: No KaTeX fonts loaded! References use system fallback fonts.');
                }
                fontsChecked = true;
            }

            const element = await page.$('#formula');
            const box = await element.boundingBox();
            if (box && box.width > 0 && box.height > 0) {
                await element.screenshot({
                    path: join(outputDir, `${idx}.png`),
                    omitBackground: false,
                });
                ok++;
                if ((i + 1) % 50 === 0) {
                    console.log(`  ${i + 1}/${lines.length} done...`);
                }
            } else {
                console.error(`SKIP ${idx}: empty bounding box for "${expr}"`);
                errors++;
            }
        } catch (err) {
            console.error(`ERR  ${idx}: ${expr} — ${err.message}`);
            errors++;
        }
    }

    await browser.close();

    // Clean up temp file
    try { unlinkSync(tempHtml); } catch (_) {}

    console.log(`\nDone: ${ok} OK, ${errors} errors out of ${lines.length} formulas`);
    console.log(`Reference PNGs saved to ${outputDir}/`);
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
