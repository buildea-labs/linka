import type { SpeedTestResult } from '../types';

export type MeasurementConfidenceLevel = 'high' | 'medium' | 'low';

export interface MeasurementConfidence {
  level: MeasurementConfidenceLevel;
  label: 'Alta' | 'Média' | 'Baixa';
  reason: string;
  shouldRetest: boolean;
}

const SCORE_BY_LEVEL: Record<MeasurementConfidenceLevel, number> = {
  high: 2,
  medium: 1,
  low: 0,
};

function lowerLevel(level: MeasurementConfidenceLevel): MeasurementConfidenceLevel {
  if (level === 'high') return 'medium';
  if (level === 'medium') return 'low';
  return 'low';
}

function maxLevel(a: MeasurementConfidenceLevel, b: MeasurementConfidenceLevel): MeasurementConfidenceLevel {
  return SCORE_BY_LEVEL[a] >= SCORE_BY_LEVEL[b] ? a : b;
}

function minLevel(a: MeasurementConfidenceLevel, b: MeasurementConfidenceLevel): MeasurementConfidenceLevel {
  return SCORE_BY_LEVEL[a] <= SCORE_BY_LEVEL[b] ? a : b;
}

export function evaluateMeasurementConfidence(result: SpeedTestResult): MeasurementConfidence {
  const totalSamples = (result.dlSamples?.length ?? 0) + (result.ulSamples?.length ?? 0);
  let level: MeasurementConfidenceLevel = 'high';
  let mainReason = 'A amostra está estável e consistente para orientar decisão.';

  if (result.ulFailed) {
    level = 'low';
    mainReason = 'A etapa de upload não foi concluída, então o resultado está parcial.';
  } else if (totalSamples > 0 && totalSamples < 16) {
    level = 'low';
    mainReason = 'Foram coletadas poucas amostras; vale repetir para confirmar.';
  } else {
    const stability = result.stabilityScore ?? 0;
    if (stability < 55) {
      level = 'low';
      mainReason = 'A medição ficou muito instável durante o teste.';
    } else if (stability < 75) {
      level = 'medium';
      mainReason = 'Houve variação perceptível durante a medição.';
    }
  }

  if (result.jitter > 30 || result.packetLoss > 2.5) {
    level = lowerLevel(level);
    mainReason = 'Oscilação ou falhas de conexão podem ter influenciado o número final.';
  }

  if (result.packetLossSource === 'estimated') {
    level = minLevel(level, 'medium');
    mainReason = maxLevel(level, 'medium') === level
      ? mainReason
      : 'Parte dos sinais é estimada no navegador, então a precisão é moderada.';
  }

  const label = level === 'high' ? 'Alta' : level === 'medium' ? 'Média' : 'Baixa';
  return {
    level,
    label,
    reason: mainReason,
    shouldRetest: level !== 'high',
  };
}
