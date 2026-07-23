import { describe, expect, it } from 'vitest';
import type { SpeedTestResult } from '../types';
import { evaluateMeasurementConfidence } from '../utils/measurementConfidence';

function baseResult(overrides: Partial<SpeedTestResult> = {}): SpeedTestResult {
  return {
    dl: 220,
    ul: 120,
    latency: 14,
    jitter: 3,
    packetLoss: 0,
    packetLossSource: 'native',
    stabilityScore: 86,
    dlSamples: Array.from({ length: 18 }, (_, i) => ({ tMs: i * 300, mbps: 200, phase: 'download' as const })),
    ulSamples: Array.from({ length: 12 }, (_, i) => ({ tMs: i * 300, mbps: 110, phase: 'upload' as const })),
    timestamp: Date.now(),
    ...overrides,
  };
}

describe('evaluateMeasurementConfidence', () => {
  it('retorna alta para amostra estavel e completa', () => {
    const result = evaluateMeasurementConfidence(baseResult());
    expect(result.level).toBe('high');
    expect(result.shouldRetest).toBe(false);
  });

  it('retorna baixa quando upload falha', () => {
    const result = evaluateMeasurementConfidence(baseResult({ ulFailed: true, ul: 0 }));
    expect(result.level).toBe('low');
    expect(result.shouldRetest).toBe(true);
  });

  it('rebaixa para media quando packet loss e estimado', () => {
    const result = evaluateMeasurementConfidence(baseResult({ packetLossSource: 'estimated' }));
    expect(result.level).toBe('medium');
  });
});
