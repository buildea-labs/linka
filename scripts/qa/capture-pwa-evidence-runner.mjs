import { chromium } from 'playwright';
import { setTimeout as wait } from 'node:timers/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const stamp = new Date().toISOString().slice(0, 10);
const out = path.join(root, 'docs/evidencias', stamp, 'pwa');
fs.mkdirSync(out, { recursive: true });

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

async function safeClick(page, roleNameRe) {
  const btn = page.getByRole('button', { name: roleNameRe }).first();
  if (await btn.count()) {
    await btn.click({ timeout: 2500 });
    await wait(900);
    return true;
  }
  return false;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 430, height: 932 } });
  const page = await context.newPage();
  await page.goto('http://127.0.0.1:4173', { waitUntil: 'domcontentloaded', timeout: 15000 });

  await page.evaluate(() => localStorage.setItem('linka.onboarding.done', '1'));
  await page.reload({ waitUntil: 'domcontentloaded' });
  await wait(1200);
  await page.screenshot({ path: path.join(out, files.home), fullPage: true });

  await safeClick(page, /Velocidade/i);
  await page.screenshot({ path: path.join(out, files.speedtest), fullPage: true });

  await safeClick(page, /Iniciar|Repetir/i);
  await wait(1500);
  await page.screenshot({ path: path.join(out, files.running), fullPage: true });

  await page.evaluate(() => {
    const now = Date.now();
    const rec = { id: `${now}-seed`, timestamp: now, dl: 210.4, ul: 98.2, latency: 18, jitter: 4, packetLoss: 0, serverName: 'Cloudflare', isp: 'ISP', deviceType: 'mobile', connectionType: 'wifi', testMode: 'complete' };
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
  await wait(1000);
  await page.screenshot({ path: path.join(out, files.fibra), fullPage: true });

  await safeClick(page, /Início/i);
  await safeClick(page, /Diagnóstico|Diagnostico|Orbit/i);
  await wait(1000);
  await page.screenshot({ path: path.join(out, files.pulse), fullPage: true });

  await page.evaluate(() => localStorage.removeItem('linka.onboarding.done'));
  await page.reload({ waitUntil: 'domcontentloaded' });
  await wait(1000);
  await page.screenshot({ path: path.join(out, files.onboarding), fullPage: true });

  await browser.close();
  console.log('done');
})();
