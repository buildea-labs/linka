import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { setTimeout as wait } from 'node:timers/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const stamp = new Date().toISOString().slice(0, 10);
const out = path.join(root, 'docs/evidencias', stamp, 'pwa');
fs.mkdirSync(out, { recursive: true });

const vite = spawn('cmd', ['/c', 'npm run dev -- --host 127.0.0.1 --port 4173'], {
  cwd: root,
  stdio: 'ignore',
});

async function waitForServer(page) {
  for (let i = 0; i < 40; i++) {
    try {
      await page.goto('http://127.0.0.1:4173', { waitUntil: 'domcontentloaded', timeout: 2000 });
      return;
    } catch {}
    await wait(1000);
  }
  throw new Error('server not ready');
}

async function safeClick(page, roleNameRe) {
  const btn = page.getByRole('button', { name: roleNameRe }).first();
  if (await btn.count()) {
    await btn.click({ timeout: 2000 });
    await wait(800);
    return true;
  }
  return false;
}

const files = {
  home: '01_home_pwa.png',
  speedtest: '02_speedtest_pwa.png',
  running: '03_running_pwa.png',
  result: '04_result_pwa.png',
  history: '05_history_pwa.png',
  explore: '06_explore_pwa.png',
  localwifi: '07_localwifi_pwa.png',
  localnetwork: '08_localnetwork_pwa.png',
  fibra: '09_fibra_pwa.png',
  pulse: '10_pulse_pwa.png',
  onboarding: '11_onboarding_pwa.png',
};

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 430, height: 932 } });
  const page = await context.newPage();
  try {
    await waitForServer(page);

    await page.evaluate(() => {
      localStorage.setItem('linka.onboarding.done', '1');
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await wait(1200);

    await page.screenshot({ path: path.join(out, files.home), fullPage: true });

    await safeClick(page, /Velocidade/i);
    await page.screenshot({ path: path.join(out, files.speedtest), fullPage: true });

    await safeClick(page, /Iniciar|Repetir/i);
    await wait(1500);
    await page.screenshot({ path: path.join(out, files.running), fullPage: true });

    // Seed result screen via history and reload
    await page.evaluate(() => {
      const now = Date.now();
      const rec = {
        id: `${now}-seed`,
        timestamp: now,
        dl: 210.4,
        ul: 98.2,
        latency: 18,
        jitter: 4,
        packetLoss: 0,
        serverName: 'Cloudflare',
        isp: 'ISP',
        deviceType: 'mobile',
        connectionType: 'wifi',
        testMode: 'complete',
      };
      localStorage.setItem('linka.speedtest.history.v1', JSON.stringify([rec]));
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await wait(1200);
    await page.screenshot({ path: path.join(out, files.result), fullPage: true });

    await safeClick(page, /Histórico/i);
    await page.screenshot({ path: path.join(out, files.history), fullPage: true });

    await safeClick(page, /Ajustes/i);
    await page.screenshot({ path: path.join(out, files.explore), fullPage: true });

    await safeClick(page, /Sinal/i);
    await page.screenshot({ path: path.join(out, files.localwifi), fullPage: true });

    await safeClick(page, /Dispositivos/i);
    await page.screenshot({ path: path.join(out, files.localnetwork), fullPage: true });

    await safeClick(page, /Ajustes/i);
    await safeClick(page, /Configurações do roteador/i);
    await wait(800);
    await page.screenshot({ path: path.join(out, files.fibra), fullPage: true });

    await safeClick(page, /Início/i);
    await safeClick(page, /Diagnóstico|Orbit/i);
    await wait(1000);
    await page.screenshot({ path: path.join(out, files.pulse), fullPage: true });

    await page.evaluate(() => localStorage.removeItem('linka.onboarding.done'));
    await page.reload({ waitUntil: 'domcontentloaded' });
    await wait(1200);
    await page.screenshot({ path: path.join(out, files.onboarding), fullPage: true });

    const created = Object.values(files).filter((f) => fs.existsSync(path.join(out, f)));
    console.log(`created:${created.length}`);
  } finally {
    await browser.close();
    vite.kill();
  }
})().catch((e) => {
  console.error(e);
  vite.kill();
  process.exit(1);
});
