const WORKER_URL = 'https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev/api/ai/diagnostico-conexao';
const WORKER_TIMEOUT_MS = 15000;

export interface DiagnosisWorkerPayload {
  schemaVersion: '3';
  generatedAtEpochMs: number;
  connectionType: string;
  metricasAtuais?: {
    downloadMbps?: number;
    uploadMbps?: number;
    latenciaMs?: number;
    jitterMs?: number;
    perdaPacotesPercentual?: number;
  };
  dispositivos?: {
    modelo?: string | null;
    sistema?: string | null;
  };
  feedbackUsuario?: string;
  evidencias?: Array<{ label: string; valor: string }>;
}

export interface DiagnosisWorkerResponse {
  status?: string;
  titulo?: string;
  resumo?: string;
  textoLaudo?: string;
  problemaPrincipal?: { tipo?: string };
  modeloIa?: {
    nomeExibicao?: string;
    textoRodape?: string;
  };
  acoesRecomendadas?: Array<{
    titulo?: string;
    descricao?: string;
    prioridade?: string;
    tipo?: string;
  }>;
}

export async function postDiagnosisWorker(payload: DiagnosisWorkerPayload): Promise<DiagnosisWorkerResponse> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), WORKER_TIMEOUT_MS);

  try {
    const response = await fetch(WORKER_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Worker API error: ${response.status} - ${error}`);
    }

    return (await response.json()) as DiagnosisWorkerResponse;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error(`Worker API timeout (${WORKER_TIMEOUT_MS}ms)`, { cause: error });
    }
    throw new Error('Falha ao chamar Worker API', { cause: error });
  }
}

export async function checkDiagnosisWorkerAvailability(): Promise<boolean> {
  try {
    const response = await fetch(WORKER_URL, { method: 'HEAD' });
    return response.ok || response.status === 405;
  } catch {
    return false;
  }
}

