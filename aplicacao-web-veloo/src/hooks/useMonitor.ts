/**
 * useMonitor — Monitoramento contínuo de latência em foreground
 *
 * Estratégia (validada por Vera):
 * - setInterval para checar latência periodicamente via cfPing
 * - Page Visibility API para pausar quando tab não está visível
 * - Background Sync e Push Notifications não implementados (sem backend)
 *
 * Thresholds (validados por Fábio):
 * - RTT > 300ms = warn (degradada)
 * - RTT > 600ms = error (crítica)
 * - Baseline: média dos últimos 3 pings para evitar falsos positivos
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { cfPing } from '../utils/cloudflareSpeedTest';
import type { Settings } from './useSettings';

/** ms para cada nível de alerta */
const THRESHOLD_WARN_MS = 300;
const THRESHOLD_ERROR_MS = 600;

/** Número de amostras para calcular média móvel */
const WINDOW_SIZE = 3;

export type MonitorStatus = 'idle' | 'ok' | 'warn' | 'error' | 'offline';

export interface MonitorAlert {
  status: MonitorStatus;
  latencyMs: number | null;
  message: string;
}

function classifyLatency(ms: number): MonitorStatus {
  if (ms >= THRESHOLD_ERROR_MS) return 'error';
  if (ms >= THRESHOLD_WARN_MS) return 'warn';
  return 'ok';
}

function average(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

const STATUS_MESSAGES: Record<MonitorStatus, string> = {
  idle: '',
  ok: 'Conexão estável',
  warn: 'Conexão degradada — latência elevada',
  error: 'Conexão crítica — latência muito alta',
  offline: 'Sem conexão com a internet',
};

interface UseMonitorOptions {
  enabled: boolean;
  checkIntervalMinutes: Settings['checkInterval'];
}

export function useMonitor({ enabled, checkIntervalMinutes }: UseMonitorOptions): MonitorAlert {
  const [alert, setAlert] = useState<MonitorAlert>({ status: 'idle', latencyMs: null, message: '' });
  const samplesRef = useRef<number[]>([]);
  const abortRef = useRef<AbortController | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const doCheck = useCallback(async () => {
    // Pausa se tab não está visível (Page Visibility API)
    if (document.visibilityState === 'hidden') return;

    abortRef.current?.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    const rtt = await cfPing(ctrl.signal);

    if (rtt === null) {
      setAlert({ status: 'offline', latencyMs: null, message: STATUS_MESSAGES.offline });
      samplesRef.current = [];
      return;
    }

    // Janela deslizante para média móvel (anti-falso-positivo)
    samplesRef.current = [...samplesRef.current.slice(-(WINDOW_SIZE - 1)), rtt];
    const avg = Math.round(average(samplesRef.current));
    const status = samplesRef.current.length >= WINDOW_SIZE
      ? classifyLatency(avg)
      : classifyLatency(rtt); // usa amostra única enquanto janela não está cheia

    setAlert({ status, latencyMs: avg, message: STATUS_MESSAGES[status] });
  }, []);

  useEffect(() => {
    if (!enabled) {
      setAlert({ status: 'idle', latencyMs: null, message: '' });
      samplesRef.current = [];
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
      return;
    }

    // Checa imediatamente ao ativar
    void doCheck();

    const intervalMs = checkIntervalMinutes * 60 * 1000;
    timerRef.current = setInterval(() => { void doCheck(); }, intervalMs);

    // Page Visibility API: retoma ao fazer tab visível novamente
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        void doCheck();
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      abortRef.current?.abort();
    };
  }, [enabled, checkIntervalMinutes, doCheck]);

  return alert;
}
