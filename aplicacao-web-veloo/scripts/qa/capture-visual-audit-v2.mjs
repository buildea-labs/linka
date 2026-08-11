import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { setTimeout as wait } from 'node:timers/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const out = path.join(root, 'docs', 'visual-audit', 'screenshots-v2');
fs.mkdirSync(out, { recursive: true });

const files = {
  home: 'home-v2.png',
  velocidade: 'velocidade-v2.png',
  running: 'teste-andamento-v2.png',
  resultado: 'resultado-v2.png',
  sinal: 'sinal-v2.png',
  dispositivos: 'dispositivos-v2.png',
  historico: 'historico-v2.png',
  ajustes: 'ajustes-v2.png',
  ia: 'ia-v2.png',
};

const vite = spawn(process.platform === 'win32' ? 'cmd.exe' : 'npm', process.platform === 'win32'
  ? ['/c', 'npm', 'run', 'dev', '--', '--host', '127.0.0.1', '--port', '4173']
  : ['run', 'dev', '--', '--host', '127.0.0.1', '--port', '4173'], {
  cwd: root,
  stdio: 'ignore',
  windowsHide: true,
  env: {
    ...process.env,
    PATH: process.platform === 'win32'
      ? `C:\\Program Files\\nodejs;${process.env.PATH ?? ''}`
      : process.env.PATH,
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
  throw new Error('Server not ready on http://127.0.0.1:4173');
}

async function setupBase(page) {
  await page.evaluate(() => {
    localStorage.setItem('linka.onboarding.done', '1');
    localStorage.removeItem('linka.speedtest.history.v1');
  });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await wait(900);
}

async function seedResult(page) {
  await page.evaluate(() => {
    const now = Date.now();
    const rec = {
      id: `${now}-seed`,
      timestamp: now,
      dl: 524,
      ul: 98.4,
      latency: 12,
      jitter: 4,
      packetLoss: 0,
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
  await wait(1200);
}

async function clickNav(page, labelRe) {
  const btn = page.getByRole('button', { name: labelRe }).first();
  await btn.click({ timeout: 3000 });
  await wait(700);
}

async function shot(page, filename, fullPage = true) {
  await page.screenshot({ path: path.join(out, filename), fullPage });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 2 });
  const page = await context.newPage();

  try {
    await waitForServer(page);

    await setupBase(page);

    await shot(page, files.home);

    await clickNav(page, /Velocidade/i);
    await shot(page, files.velocidade);

    await page.getByRole('button', { name: /Iniciar novo teste/i }).first().click({ timeout: 3000 });
    await wait(1200);
    await shot(page, files.running);

    await seedResult(page);
    await shot(page, files.resultado);

    await setupBase(page);
    await clickNav(page, /Sinal/i);
    await shot(page, files.sinal);

    await clickNav(page, /In[ií]cio/i);
    await page.getByRole('button', { name: /Ver dispositivos/i }).first().click({ timeout: 3000 });
    await wait(900);
    await shot(page, files.dispositivos);

    await clickNav(page, /Hist[oó]rico/i);
    await shot(page, files.historico);

    await clickNav(page, /Ajustes/i);
    await shot(page, files.ajustes);

    await clickNav(page, /In[ií]cio/i);
    await page.getByRole('button', { name: /Diagn[oó]stico inteligente/i }).first().click({ timeout: 3000 });
    await wait(900);
    await page.evaluate(() => {
      const glow = document.querySelector('.app-border-glow');
      if (glow) glow.style.display = 'none';
    });
    await shot(page, files.ia, false);

    console.log(`captured:${out}`);
  } finally {
    await browser.close();
    vite.kill();
  }
})().catch((error) => {
  console.error(error);
  vite.kill();
  process.exit(1);
});
