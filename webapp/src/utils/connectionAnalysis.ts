/**
 * connectionAnalysis — Análise local de conexão baseada em regras
 *
 * Não usa LLM, não faz chamadas de rede. Processa apenas dados do
 * localStorage (TestRecord[]) para gerar métricas e diagnósticos textuais.
 *
 * Validado por Vera: localStorage suficiente, sem APIs externas necessárias.
 */

import type { TestRecord } from '../types';

export const MIN_RECORDS_FOR_ANALYSIS = 5;

export interface ConnectionMetrics {
  /** Média de download (Mbps) */
  avgDownload: number;
  /** Desvio padrão de download — indica instabilidade */
  stdDevDownload: number;
  /** Média de latência (ms) */
  avgLatency: number;
  /** Média de jitter (ms) */
  avgJitter: number;
  /** Percentual de testes com perda de pacotes > 1% */
  lossRatePct: number;
  /** Melhor horário do dia (bucket com maior download médio) */
  bestHour: string | null;
  /** Pior horário do dia (bucket com menor download médio) */
  worstHour: string | null;
  /** Tendência de download: 'improving' | 'degrading' | 'stable' */
  trend: 'improving' | 'degrading' | 'stable';
  /** Índice de estabilidade 0–100 (maior = mais estável) */
  stabilityScore: number;
}

type HourBucket = 'madrugada (0h–5h)' | 'manhã (6h–11h)' | 'tarde (12h–17h)' | 'noite (18h–23h)';

function mean(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

function stdDev(values: number[]): number {
  if (values.length < 2) return 0;
  const m = mean(values);
  const variance = values.reduce((s, v) => s + (v - m) ** 2, 0) / values.length;
  return Math.sqrt(variance);
}

function hourBucket(timestamp: number): HourBucket {
  const h = new Date(timestamp).getHours();
  if (h < 6) return 'madrugada (0h–5h)';
  if (h < 12) return 'manhã (6h–11h)';
  if (h < 18) return 'tarde (12h–17h)';
  return 'noite (18h–23h)';
}

export function computeConnectionMetrics(records: TestRecord[]): ConnectionMetrics | null {
  if (records.length < MIN_RECORDS_FOR_ANALYSIS) return null;

  const dlValues = records.map((r) => r.dl);
  const latValues = records.map((r) => r.latency);
  const jitterValues = records.map((r) => r.jitter);
  const lossRecords = records.filter((r) => r.packetLoss > 1);

  const avgDownload = mean(dlValues);
  const stdDevDownload = stdDev(dlValues);
  const avgLatency = mean(latValues);
  const avgJitter = mean(jitterValues);
  const lossRatePct = (lossRecords.length / records.length) * 100;

  // Análise por hora do dia
  const buckets: Record<HourBucket, number[]> = {
    'madrugada (0h–5h)': [],
    'manhã (6h–11h)': [],
    'tarde (12h–17h)': [],
    'noite (18h–23h)': [],
  };
  for (const r of records) {
    buckets[hourBucket(r.timestamp)].push(r.dl);
  }
  const populatedBuckets = (Object.keys(buckets) as HourBucket[])
    .filter((b) => buckets[b].length >= 2)
    .map((b) => ({ label: b, avg: mean(buckets[b]) }));

  let bestHour: string | null = null;
  let worstHour: string | null = null;
  if (populatedBuckets.length >= 2) {
    bestHour = populatedBuckets.reduce((a, c) => (c.avg > a.avg ? c : a)).label;
    worstHour = populatedBuckets.reduce((a, c) => (c.avg < a.avg ? c : a)).label;
    // Só reporta melhor/pior se houver diferença significativa (>15%)
    const bestAvg = populatedBuckets.find((b) => b.label === bestHour)?.avg ?? 0;
    const worstAvg = populatedBuckets.find((b) => b.label === worstHour)?.avg ?? 0;
    if (bestAvg === 0 || (worstAvg / bestAvg) > 0.85) {
      bestHour = null;
      worstHour = null;
    }
  }

  // Tendência: compara primeira metade vs segunda (records já ordenados do mais recente)
  const half = Math.floor(records.length / 2);
  const newer = records.slice(0, half);
  const older = records.slice(half);
  const newerAvg = mean(newer.map((r) => r.dl));
  const olderAvg = mean(older.map((r) => r.dl));
  const trendPct = olderAvg > 0 ? ((newerAvg - olderAvg) / olderAvg) * 100 : 0;
  const trend: ConnectionMetrics['trend'] =
    trendPct > 15 ? 'improving' :
    trendPct < -15 ? 'degrading' : 'stable';

  // Índice de estabilidade: penaliza stdDev alto, jitter alto e perda
  // Normalizado 0–100
  const cvDownload = avgDownload > 0 ? (stdDevDownload / avgDownload) : 1;
  const jitterPenalty = Math.min(avgJitter / 50, 1);
  const lossPenalty = Math.min(lossRatePct / 100, 1);
  const rawScore = 1 - (cvDownload * 0.5 + jitterPenalty * 0.3 + lossPenalty * 0.2);
  const stabilityScore = Math.round(Math.max(0, Math.min(100, rawScore * 100)));

  return {
    avgDownload: Math.round(avgDownload * 10) / 10,
    stdDevDownload: Math.round(stdDevDownload * 10) / 10,
    avgLatency: Math.round(avgLatency),
    avgJitter: Math.round(avgJitter),
    lossRatePct: Math.round(lossRatePct),
    bestHour,
    worstHour,
    trend,
    stabilityScore,
  };
}
