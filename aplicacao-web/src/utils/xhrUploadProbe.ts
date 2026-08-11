import type { SpeedTestSample } from '../types';
import type { UploadProbeConfig, UploadProbeResult } from './uploadProbe';

function mean(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

function stddev(values: number[]): number {
  if (values.length < 2) return 0;
  const avg = mean(values);
  return Math.sqrt(values.reduce((s, v) => s + (v - avg) ** 2, 0) / values.length);
}

function uploadBlob(bytes: number): Blob {
  const chunks: Uint8Array[] = [];
  for (let remaining = bytes; remaining > 0; remaining -= 65_536) {
    const chunk = new Uint8Array(Math.min(65_536, remaining));
    crypto.getRandomValues(chunk);
    chunks.push(chunk);
  }
  // @ts-expect-error - Blob does accept Uint8Array chunks in some environments
  return new Blob(chunks);
}

function xhrRequest(
  method: 'GET' | 'POST',
  url: string,
  body: Blob | null,
  signal: AbortSignal,
  onProgress?: (loaded: number) => void,
): Promise<{ bytes: number; duration: number }> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open(method, url, true);
    // Timeout of 20s as safeguard
    xhr.timeout = 20_000;
    if (method === 'GET') xhr.responseType = 'arraybuffer';
    const startedAt = performance.now();
    
    const target = method === 'POST' ? xhr.upload : xhr;
    target.onprogress = (event) => onProgress?.(event.loaded);
    
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve({
          bytes: body?.size ?? (xhr.response as ArrayBuffer | null)?.byteLength ?? 0,
          duration: performance.now() - startedAt,
        });
      } else {
        reject(new Error(`HTTP ${xhr.status}`));
      }
    };
    
    xhr.onerror = () => reject(new Error(navigator.onLine ? 'endpoint_unavailable' : 'network_offline'));
    xhr.ontimeout = () => reject(new Error('timeout'));
    xhr.onabort = () => reject(new DOMException('Aborted', 'AbortError'));
    
    signal.addEventListener('abort', () => xhr.abort(), { once: true });
    
    xhr.send(body);
  });
}

/**
 * Motor de upload adaptado do SignallQ. Usa XHR com onprogress para
 * stream contínuo real e escalabilidade paralela.
 */
export async function runXhrUploadProbe(
  config: UploadProbeConfig,
  signal: AbortSignal,
  onInstant: (mbps: number) => void,
): Promise<UploadProbeResult> {
  const payloadBytes = 25 * 1024 * 1024; // 25 MB max payload por XHR pra sobrar banda e tempo
  const startedAt = performance.now();
  const samples: SpeedTestSample[] = [];
  
  let bytesTick = 0;
  let targetStreams = config.initialStreams;
  let lastScaleAt = 0;
  let previousAverage = 0;
  
  const stopAt = startedAt + config.durationMs;
  let smoothed = 0;

  const worker = async (index: number) => {
    // Stagger initialization to avoid sudden congestion spike
    if (index) await new Promise((resolve) => setTimeout(resolve, index * 200));
    
    while (!signal.aborted && performance.now() < stopAt) {
      if (index >= targetStreams) {
        await new Promise((resolve) => setTimeout(resolve, 120));
        continue;
      }
      
      try {
        let previousLoaded = 0;
        const onProgress = (loaded: number) => {
          const chunk = Math.max(0, loaded - previousLoaded);
          bytesTick += chunk;
          previousLoaded = loaded;
        };
        
        const url = `https://speed.cloudflare.com/__up?_cb=${Date.now()}_${Math.random()}`;
        const response = await xhrRequest('POST', url, uploadBlob(payloadBytes), signal, onProgress);
        
        // Em navegadores restritivos que não emitem onprogress de fato para payloads pequenos
        if (previousLoaded === 0) {
          bytesTick += response.bytes;
        }
      } catch (error) {
        if (error instanceof DOMException && error.name === 'AbortError') return;
        if (!navigator.onLine) {
          return;
        }
        // Retries if normal network error but not aborted
      }
    }
  };

  const SAMPLE_INTERVAL = 300;
  let lastSampleTs = startedAt;

  const sampleInterval = window.setInterval(() => {
    const now = performance.now();
    const elapsedTick = (now - lastSampleTs) / 1000;
    lastSampleTs = now;
    
    if (elapsedTick > 0 && bytesTick > 0) {
      const instant = (bytesTick * 8) / elapsedTick / 1_000_000;
      smoothed = smoothed === 0 ? instant : 0.3 * instant + 0.7 * smoothed;
      bytesTick = 0;
      
      const elapsed = now - startedAt;
      samples.push({ tMs: elapsed, mbps: instant, phase: 'upload' });
      onInstant(smoothed);
      
      if (elapsed - lastScaleAt >= 4000 && targetStreams < config.maxStreams) {
        const recentSamples = samples
          .filter((s) => s.tMs >= Math.max(0, elapsed - 4000))
          .map((s) => s.mbps);
        const average = mean(recentSamples);
        
        // If we improved by at least 10% since last check, scale up
        if (!previousAverage || average >= previousAverage * 1.1) {
          targetStreams = Math.min(config.maxStreams, targetStreams + 2);
        }
        previousAverage = average;
        lastScaleAt = elapsed;
      }
    } else {
      bytesTick = 0;
    }
  }, SAMPLE_INTERVAL);

  // Iniciar todos os maxStreams alocados em stand-by (eles respeitam `targetStreams`)
  await Promise.all(Array.from({ length: config.maxStreams }, (_, index) => worker(index)));
  
  window.clearInterval(sampleInterval);

  const valid = samples.filter((s) => s.tMs >= config.warmupMs && s.mbps > 0);
  const stableStart = Math.ceil(valid.length * 0.35);
  const stable = valid.slice(stableStart);
  
  const measured = stable.length ? stable : valid;
  const throughputMbps = measured.length ? mean(measured.map((s) => s.mbps)) : 0;
  const peakMbps = valid.length ? Math.max(...valid.map((s) => s.mbps)) : 0;
  
  const mbpsValues = measured.map((s) => s.mbps);
  const cv = throughputMbps > 0 ? stddev(mbpsValues) / throughputMbps : 1;
  const stabilityScore = Math.round(Math.max(0, Math.min(100, 100 - cv * 150)));

  if (throughputMbps === 0 && valid.length === 0) {
    throw Object.assign(new Error('upload_failed'), { code: 'upload_failed' as const });
  }

  return { throughputMbps, peakMbps, stabilityScore, samples };
}
