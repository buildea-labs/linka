import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { setTimeout as wait } from 'node:timers/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const outDir = path.join(root, 'docs', 'visual-audit', 'screenshots-v4');
const outFile = path.join(outDir, 'resultado-v4.png');
fs.mkdirSync(outDir, { recursive: true });

const vite = spawn(process.platform === 'win32' ? 'cmd.exe' : 'npm', process.platform === 'win32'
  ? ['/c', 'npm', 'run', 'dev', '--', '--host', '127.0.0.1', '--port', '4173']
  : ['run', 'dev', '--', '--host', '127.0.0.1', '--port', '4173'], {
  cwd: root,
  stdio: 'ignore',
  windowsHide: true,
  env: {
    ...process.env,
    PATH: process.platform === 'win32' ? `C:\\Program Files\\nodejs;${process.env.PATH ?? ''}` : process.env.PATH,
  },
});

async function waitForServer(page) {
  for (let i = 0; i < 50; i += 1) {
    try {
      await page.goto('http://127.0.0.1:4173', { waitUntil: 'domcontentloaded', timeout: 2000 });
      return;
    } catch {
      await wait(1000);
    }
  }
  throw new Error('Server not ready');
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 2 });
  const page = await context.newPage();

  try {
    await waitForServer(page);
    await page.evaluate(() => {
      localStorage.setItem('linka.onboarding.done', '1');
      const now = Date.now();
      const rec = {
        id: `${now}-seed`,
        timestamp: now,
        dl: 524,
        ul: 98.4,
        latency: 12,
        jitter: 4,
        packetLoss: 0,
        packetLossSource: 'native',
        serverName: 'São Paulo',
        isp: 'Vivo Fibra',
        deviceType: 'mobile',
        connectionType: 'wifi',
        testMode: 'complete',
        dnsLatencyMs: 21,
        dnsProvider: 'Cloudflare DNS',
      };
      localStorage.setItem('linka.speedtest.history.v1', JSON.stringify([rec]));
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await wait(1300);

    await page.screenshot({ path: outFile, fullPage: true });
    console.log(`captured:${outFile}`);
  } finally {
    await browser.close();
    vite.kill();
  }
})().catch((e) => {
  console.error(e);
  vite.kill();
  process.exit(1);
});
