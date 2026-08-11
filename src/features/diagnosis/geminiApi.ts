/**
 * Gemini API Integration para Diagnóstico IA
 *
 * Phase 2d: Integra Gemini 1.5 Flash com timeout de 3 segundos.
 * Fallback automático para Rules Engine em caso de erro ou timeout.
 *
 * Baseado em: docs/CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md
 */

import type { DiagnosisRecommendation } from './types';
import type { DiagnosisEngineInput } from './types';
import { rulesEngine } from './rulesEngine';

const API_TIMEOUT_MS = 3000;
const MODEL = 'gemini-flash-latest';

function buildPrompt(input: DiagnosisEngineInput): string {
  const { testResult, contractInfo } = input;
  const { dl, ul, ping, jitter, packetLoss, connectionType } = testResult;

  return `Você é um especialista em diagnóstico de internet. Analise este teste de velocidade e retorne um diagnóstico estruturado como JSON válido.

RESULTADO DO TESTE:
- Download: ${dl.toFixed(2)} Mbps
- Upload: ${ul.toFixed(2)} Mbps
- Latência (Resposta): ${ping.toFixed(1)} ms
- Oscilação (Jitter): ${jitter.toFixed(1)} ms
- Perda de Pacotes: ${packetLoss.toFixed(2)}%
- Tipo de Conexão: ${connectionType}
${contractInfo?.contractedDl ? `- Download Contratado: ${contractInfo.contractedDl} Mbps` : ''}
${contractInfo?.contractedUl ? `- Upload Contratado: ${contractInfo.contractedUl} Mbps` : ''}

RETORNE UM JSON VÁLIDO COM ESTA ESTRUTURA EXATA:
{
  "cause": "healthy|congestion|wifi|dns|wan_issue|isp_limit|device|unknown",
  "severity": "healthy|warn|fail",
  "title": "Título curto do diagnóstico",
  "summary": "1-2 linhas descrevendo o problema",
  "problems": [
    {
      "id": "prob-1",
      "metric": "dl|ul|ping|jitter|packetLoss|mixed",
      "description": "Descrição do problema",
      "severity": "warn|fail|critical"
    }
  ],
  "recommendations": [
    {
      "id": "rec-1",
      "action": "Ação curta imperativa",
      "description": "Por que fazer esta ação",
      "priority": "high|medium|low",
      "category": "wifi|router|device|isp|dns|general",
      "icon": "nome_icone",
      "color": "hex_color"
    }
  ],
  "confidence": 0.85
}

INSTRUÇÕES:
1. Analise rigorosamente os valores contra thresholds típicos
2. Identifique apenas problemas REAIS (não especule)
3. Máximo 3 problemas, máximo 5 recomendações
4. Retorne APENAS o JSON, sem markdown ou explicação
5. Use português brasileiro para títulos e descrições
`;
}

async function callGeminiApi(prompt: string): Promise<string> {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY;

  if (!apiKey) {
    throw new Error('VITE_GEMINI_API_KEY não configurada');
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT_MS);

  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: 'application/json',
        }
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Gemini API error: ${response.status} - ${error}`);
    }

    const data = await response.json();
    const textContent = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!textContent) {
      throw new Error('Nenhum texto na resposta da Gemini API');
    }

    return textContent;
  } catch (error) {
    clearTimeout(timeoutId);

    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error(`Gemini API timeout (${API_TIMEOUT_MS}ms)`, { cause: error });
    }

    throw new Error('Falha ao chamar Gemini API', { cause: error });
  }
}

function parseResponse(text: string): Partial<DiagnosisRecommendation> {
  let json = text.trim();
  if (json.startsWith('```json')) {
    json = json.slice(7);
  }
  if (json.startsWith('```')) {
    json = json.slice(3);
  }
  if (json.endsWith('```')) {
    json = json.slice(0, -3);
  }

  return JSON.parse(json.trim());
}

export async function geminiDiagnosis(
  input: DiagnosisEngineInput,
): Promise<DiagnosisRecommendation> {
  const startTime = Date.now();

  try {
    const prompt = buildPrompt(input);
    const response = await callGeminiApi(prompt);
    const parsed = parseResponse(response);

    const diagnosis: DiagnosisRecommendation = {
      id: `diag-gemini-${Date.now()}`,
      timestamp: Date.now(),
      cause: parsed.cause ?? 'unknown',
      severity: parsed.severity ?? 'warn',
      title: parsed.title ?? 'Diagnóstico de conexão',
      summary: parsed.summary ?? 'Análise completa da sua conexão',
      problems: parsed.problems ?? [],
      recommendations: parsed.recommendations ?? [],
      confidence: parsed.confidence ?? 0.8,
      source: 'gemini-api',
      processingTimeMs: Date.now() - startTime,
    };

    return diagnosis;
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : 'Erro desconhecido';
    console.warn('[geminiDiagnosis] Erro ao chamar Gemini API:', errorMsg);

    // Fallback para Rules Engine
    return rulesEngine(input);
  }
}

export async function combinedDiagnosis(
  input: DiagnosisEngineInput,
): Promise<DiagnosisRecommendation> {
  // Tenta Gemini API primeiro (3s timeout incluído em geminiDiagnosis)
  // Se falhar por qualquer motivo, fallback automático para Rules Engine
  return geminiDiagnosis(input);
}
