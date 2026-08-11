import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { setTimeout as wait } from 'node:timers/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Objetivo:
 *   Capturar screenshots automatizadas das 6 telas principais para auditoria
 *   visual contra o mockup oficial.
 *
 * Pré-requisitos:
 *   - Node.js disponível.
 *   - Dependências instaladas (`npm install`).
 *   - Browser do Playwright instalado (`npm exec playwright install chromium`).
 *
 * Comando:
 *   - Baseline: node scripts/qa/capture-visual-audit.mjs baseline
 *   - Final:    node scripts/qa/capture-visual-audit.mjs final
 */

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const out = path.join(root, 'docs', 'visual-audit', 'screenshots');
const baselineOut = path.join(root, 'docs', 'visual-audit', 'screenshots-baseline');
const mode = (process.argv[2] ?? 'final').toLowerCase();
const target = mode === 'baseline' ? baselineOut : out;

fs.mkdirSync(target, { recursive: true });

const files = {
  home: 'home.png',
  velocidade: 'velocidade.png',
  sinal: 'sinal.png',
  dispositivos: 'dispositivos.png',
  historico: 'historico.png',
  ajustes: 'ajustes.png',
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

async function clickNav(page, labelRe) {
  const btn = page.getByRole('button', { name: labelRe }).first();
  await btn.click({ timeout: 3000 });
  await wait(600);
}

async function shot(page, name) {
  await page.screenshot({ path: path.join(target, name), fullPage: true });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 2 });
  const page = await context.newPage();

  try {
    await waitForServer(page);

    await page.evaluate(() => {
      localStorage.setItem('linka.onboarding.done', '1');
      localStorage.removeItem('linka.speedtest.previous.v1');
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await wait(1200);

    await shot(page, files.home);

    await clickNav(page, /Velocidade/i);
    await shot(page, files.velocidade);

    await clickNav(page, /Sinal/i);
    await shot(page, files.sinal);

    await clickNav(page, /In[ií]cio|Home/i);
    await page.getByRole('button', { name: /Ver dispositivos/i }).first().click({ timeout: 3000 });
    await wait(800);
    await shot(page, files.dispositivos);

    await clickNav(page, /Hist[oó]rico/i);
    await shot(page, files.historico);

    await clickNav(page, /Ajustes/i);
    await shot(page, files.ajustes);

    console.log(`captured:${target}`);
  } finally {
    await browser.close();
    vite.kill();
  }
})().catch((error) => {
  console.error(error);
  vite.kill();
  process.exit(1);
});
