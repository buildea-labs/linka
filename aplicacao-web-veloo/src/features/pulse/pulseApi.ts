import type { AiAnalysisEntry } from './types';
import type { SpeedTestResult } from '../../types';
import { localAnalysisText, severityFromResult } from './rulesAdapter';
import { withLocalDiagnosisFooter } from '../diagnosis/fallback';
import { postDiagnosisWorker } from '../diagnosis/workerClient';

async function callWorker(trigger: string, context: string, result?: SpeedTestResult): Promise<string> {
  try {
    const data = await postDiagnosisWorker({
      schemaVersion: '3',
      generatedAtEpochMs: Date.now(),
      connectionType: 'unknown',
      metricasAtuais: result ? {
        downloadMbps: result.dl,
        uploadMbps: result.ul,
        latenciaMs: result.latency,
        jitterMs: result.jitter,
        perdaPacotesPercentual: result.packetLoss,
      } : undefined,
      feedbackUsuario: context,
      evidencias: [
        { label: 'trigger', valor: trigger },
      ],
    });
    const mainText = (data.textoLaudo || data.resumo || '').trim();
    const footer = data.modeloIa?.textoRodape?.trim();
    return footer ? `${mainText}\n\n${footer}` : mainText;
  } catch {
    throw new Error('Worker unavailable');
  }
}

export async function generateInitialAnalysis(
  result: SpeedTestResult,
  contextAccumulated: string,
  trigger: string,
): Promise<AiAnalysisEntry> {
  try {
    const text = await callWorker(trigger, contextAccumulated, result);
    if (text) {
      return { trigger, content: text, isFallback: false, timestamp: Date.now() };
    }
  } catch { /* fall through */ }

  const severity = severityFromResult(result);
  const fallbackText = withLocalDiagnosisFooter(localAnalysisText(result, severity));
  return { trigger, content: fallbackText, isFallback: true, timestamp: Date.now() };
}

export async function generateFollowUpAnalysis(
  result: SpeedTestResult,
  contextAccumulated: string,
  trigger: string,
): Promise<AiAnalysisEntry> {
  return generateInitialAnalysis(result, contextAccumulated, trigger);
}

export function localFallback(result: SpeedTestResult): AiAnalysisEntry {
  const severity = severityFromResult(result);
  return {
    trigger: 'fallback',
    content: withLocalDiagnosisFooter(localAnalysisText(result, severity)),
    isFallback: true,
    timestamp: Date.now(),
  };
}
