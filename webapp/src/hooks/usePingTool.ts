import { useState, useCallback, useRef } from 'react';
import { cfPing } from '../utils/cloudflareSpeedTest';

export type PingQuality = 'excellent' | 'good' | 'acceptable' | 'poor' | 'timeout';

export interface PingResult {
  medianMs: number;
  minMs: number;
  maxMs: number;
  jitterMs: number;
  quality: PingQuality;
  samples: (number | null)[];
}

export type PingToolState =
  | { status: 'idle' }
  | { status: 'loading'; progress: number; total: number }
  | { status: 'result'; data: PingResult }
  | { status: 'error'; message: string };

const PING_COUNT = 5;

function median(values: number[]): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const m = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[m - 1] + sorted[m]) / 2 : sorted[m];
}

function jitterOf(samples: number[]): number {
  if (samples.length < 2) return 0;
  let acc = 0;
  for (let i = 1; i < samples.length; i++) acc += Math.abs(samples[i] - samples[i - 1]);
  return acc / (samples.length - 1);
}

/**
 * Classifica a latência HTTP em categorias de qualidade.
 * Thresholds definidos por Fábio com base em padrões Anatel.
 * Atenção: este é RTT HTTP (DNS + TCP + TLS + HTTP), não ICMP ping.
 */
export function classifyPingQuality(medianMs: number): PingQuality {
  if (medianMs < 20) return 'excellent';
  if (medianMs < 80) return 'good';
  if (medianMs < 150) return 'acceptable';
  return 'poor';
}

export function usePingTool() {
  const [state, setState] = useState<PingToolState>({ status: 'idle' });
  const abortRef = useRef<AbortController | null>(null);

  const run = useCallback(async () => {
    abortRef.current?.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    setState({ status: 'loading', progress: 0, total: PING_COUNT });

    const samples: (number | null)[] = [];

    try {
      for (let i = 0; i < PING_COUNT; i++) {
        if (ctrl.signal.aborted) return;
        const rtt = await cfPing(ctrl.signal);
        samples.push(rtt);
        setState({ status: 'loading', progress: i + 1, total: PING_COUNT });
      }

      // Descarta o 1º sample (TCP warm-up), mesmo padrão do latencyProbe.ts
      const effective = samples.slice(1);
      const valid = effective.filter((v): v is number => v !== null);

      if (valid.length === 0) {
        setState({ status: 'result', data: {
          medianMs: 0,
          minMs: 0,
          maxMs: 0,
          jitterMs: 0,
          quality: 'timeout',
          samples,
        }});
        return;
      }

      const med = median(valid);
      const result: PingResult = {
        medianMs: Math.round(med),
        minMs: Math.round(Math.min(...valid)),
        maxMs: Math.round(Math.max(...valid)),
        jitterMs: Math.round(jitterOf(valid)),
        quality: classifyPingQuality(med),
        samples,
      };

      setState({ status: 'result', data: result });
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') return;
      setState({ status: 'error', message: 'Falha ao medir latência. Verifique sua conexão.' });
    }
  }, []);

  const reset = useCallback(() => {
    abortRef.current?.abort();
    setState({ status: 'idle' });
  }, []);

  return { state, run, reset };
}
