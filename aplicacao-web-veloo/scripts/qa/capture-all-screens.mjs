import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { setTimeout as wait } from 'node:timers/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Objetivo:
 *   Capturar screenshots "tela a tela" do Linka PWA (incluindo Resultado
 *   e IA) para evidência visual completa.
 *
 * Pré-requisitos:
 *   - Node.js instalado.
 *   - Dependências do projeto instaladas (`npm install`).
 *   - Browser do Playwright instalado (`npm exec playwright install chromium`).
 *
 * Comando:
 *   node scripts/qa/capture-all-screens.mjs
 */

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const out = path.join(root, 'docs', 'visual-audit', 'screenshots-all');
fs.mkdirSync(out, { recursive: true });

const files = {
  home: '01-home.png',
  velocidade: '02-velocidade.png',
  running: '03-running.png',
  resultado: '04-resultado.png',
  sinal: '05-sinal.png',
  dispositivos: '06-dispositivos.png',
  historico: '07-historico.png',
  ajustes: '08-ajustes.png',
  ia: '09-ia.png',
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
    localStorage.removeItem('linka.speedtest.previous.v1');
  });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await wait(1100);
}

async function clickNav(page, labelRe) {
  const btn = page.getByRole('button', { name: labelRe }).first();
  await btn.click({ timeout: 3000 });
  await wait(650);
}

async function shot(page, filename) {
  await page.screenshot({ path: path.join(out, filename), fullPage: true });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 2 });
  const page = await context.newPage();

  try {
    await waitForServer(page);

    // 01 Home
    await setupBase(page);
    await shot(page, files.home);

    // 02 Velocidade
    await clickNav(page, /Velocidade/i);
    await shot(page, files.velocidade);

    // 03 Running
    await page.getByRole('button', { name: /Iniciar teste|Iniciar/i }).first().click({ timeout: 3000 });
    await wait(1200);
    await shot(page, files.running);

    // 04 Resultado (seed e reload)
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
      };
      localStorage.setItem('linka.speedtest.history.v1', JSON.stringify([rec]));
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await wait(1200);
    await shot(page, files.resultado);

    // 05 Sinal
    await setupBase(page);
    await clickNav(page, /Sinal/i);
    await shot(page, files.sinal);

    // 06 Dispositivos (via ação rápida da Home)
    await clickNav(page, /In[ií]cio/i);
    await page.getByRole('button', { name: /Ver dispositivos/i }).first().click({ timeout: 3000 });
    await wait(850);
    await shot(page, files.dispositivos);

    // 07 Histórico
    await setupBase(page);
    await clickNav(page, /Hist[oó]rico/i);
    await shot(page, files.historico);

    // 08 Ajustes
    await clickNav(page, /Ajustes/i);
    await shot(page, files.ajustes);

    // 09 IA (Diagnóstico IA)
    await clickNav(page, /In[ií]cio/i);
    await page.getByRole('button', { name: /Diagn[oó]stico inteligente/i }).first().click({ timeout: 3000 });
    await wait(900);
    await shot(page, files.ia);

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
