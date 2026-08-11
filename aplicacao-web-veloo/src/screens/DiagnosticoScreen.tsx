import { useEffect, useState, useCallback } from 'react';
import { TopBar } from '../components/TopBar';
import { Skeleton } from '../components/Skeleton';
import {
  postDiagnosisWorker,
  type DiagnosisWorkerPayload,
  type DiagnosisWorkerResponse,
} from '../features/diagnosis/workerClient';
import type { SpeedTestResult, ConnectionType } from '../types';

interface Props {
  result: SpeedTestResult;
  connectionType?: ConnectionType | null;
  onBack: () => void;
  onOpenChat: () => void;
}

function statusColor(status?: string): string {
  if (status === 'ok') return '#22C55E';
  if (status === 'fail') return '#EF4444';
  return '#F59E0B'; // warn or unknown
}

function statusLabel(status?: string): string {
  if (status === 'ok') return 'Conexao boa';
  if (status === 'fail') return 'Problema detectado';
  return 'Atenção';
}

export function DiagnosticoScreen({ result, connectionType, onBack, onOpenChat }: Props) {
  const [loading, setLoading] = useState(true);
  const [response, setResponse] = useState<DiagnosisWorkerResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchDiagnosis = useCallback(async () => {
    setLoading(true);
    setError(null);
    setResponse(null);

    const payload: DiagnosisWorkerPayload = {
      schemaVersion: '3',
      generatedAtEpochMs: Date.now(),
      connectionType: connectionType ?? 'unknown',
      metricasAtuais: {
        downloadMbps: result.dl,
        uploadMbps: result.ul,
        latenciaMs: result.latency,
        jitterMs: result.jitter,
        perdaPacotesPercentual: result.packetLoss,
      },
    };

    try {
      const data = await postDiagnosisWorker(payload);
      setResponse(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao buscar diagnostico');
    } finally {
      setLoading(false);
    }
  }, [result, connectionType]);

  useEffect(() => {
    void fetchDiagnosis();
  }, [fetchDiagnosis]);

  const accent = '#6C2BFF';
  const orbitBg = '#0D0D1A';
  const orbitBorder = 'rgba(124, 95, 255, 0.18)';
  const textPrimary = '#F3F4F6';
  const textSecondary = '#9CA3AF';

  return (
    <div
      style={{
        minHeight: '100dvh',
        background: 'var(--bg)',
        display: 'flex',
        flexDirection: 'column',
        paddingBottom: 24,
      }}
    >
      <TopBar
        onBack={onBack}
        title="Diagnostico IA"
        showTitle
      />

      <div
        style={{
          flex: 1,
          padding: 'calc(var(--safe-top, 0px) + 64px) 16px 0',
          display: 'flex',
          flexDirection: 'column',
          gap: 16,
        }}
      >
        {/* Estado: carregando */}
        {loading && (
          <div
            style={{
              background: orbitBg,
              borderRadius: 16,
              border: `1px solid ${orbitBorder}`,
              padding: 16,
              display: 'flex',
              flexDirection: 'column',
              gap: 12,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Skeleton width={64} height={24} variant="pill" />
            </div>
            <Skeleton width="80%" height={28} />
            <Skeleton width="100%" height={16} />
            <Skeleton width="90%" height={16} />
            <Skeleton width="70%" height={16} />
            <div style={{ marginTop: 8 }}>
              <Skeleton width="40%" height={14} />
              <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 8 }}>
                <Skeleton width="100%" height={56} />
                <Skeleton width="100%" height={56} />
              </div>
            </div>
          </div>
        )}

        {/* Estado: erro */}
        {!loading && error && (
          <div
            style={{
              background: orbitBg,
              borderRadius: 16,
              border: `1px solid ${orbitBorder}`,
              padding: 16,
              display: 'flex',
              flexDirection: 'column',
              gap: 12,
            }}
          >
            <p style={{ color: '#EF4444', fontSize: 15, margin: 0 }}>
              Nao foi possivel obter o diagnostico.
            </p>
            <p style={{ color: textSecondary, fontSize: 13, margin: 0 }}>
              {error}
            </p>
            <button
              onClick={() => void fetchDiagnosis()}
              style={{
                marginTop: 8,
                background: accent,
                color: '#FFFFFF',
                border: 'none',
                borderRadius: 24,
                padding: '12px 24px',
                fontSize: 15,
                fontWeight: 600,
                cursor: 'pointer',
                alignSelf: 'flex-start',
              }}
            >
              Tentar novamente
            </button>
          </div>
        )}

        {/* Estado: resposta recebida */}
        {!loading && response && (
          <>
            {/* Card principal Orbit */}
            <div
              style={{
                background: orbitBg,
                borderRadius: 16,
                border: `1px solid ${orbitBorder}`,
                padding: 16,
                display: 'flex',
                flexDirection: 'column',
                gap: 12,
              }}
            >
              {/* Badge de status */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span
                  style={{
                    background: `${statusColor(response.status)}22`,
                    color: statusColor(response.status),
                    borderRadius: 24,
                    padding: '4px 12px',
                    fontSize: 12,
                    fontWeight: 700,
                    letterSpacing: '0.04em',
                    textTransform: 'uppercase',
                  }}
                >
                  {statusLabel(response.status)}
                </span>
              </div>

              {/* Titulo */}
              <h1
                style={{
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: 700,
                  margin: 0,
                  lineHeight: 1.3,
                }}
              >
                {response.titulo ?? 'Diagnostico'}
              </h1>

              {/* Resumo */}
              {(response.resumo ?? response.textoLaudo) && (
                <p
                  style={{
                    color: textSecondary,
                    fontSize: 14,
                    margin: 0,
                    lineHeight: 1.6,
                  }}
                >
                  {response.resumo ?? response.textoLaudo}
                </p>
              )}

              {/* Problema principal */}
              {response.problemaPrincipal?.tipo && (
                <div
                  style={{
                    borderTop: `1px solid ${orbitBorder}`,
                    paddingTop: 12,
                    marginTop: 4,
                  }}
                >
                  <p
                    style={{
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: 700,
                      letterSpacing: '0.08em',
                      textTransform: 'uppercase',
                      margin: '0 0 4px',
                    }}
                  >
                    Problema principal
                  </p>
                  <p style={{ color: textPrimary, fontSize: 15, margin: 0, fontWeight: 500 }}>
                    {response.problemaPrincipal.tipo}
                  </p>
                </div>
              )}

              {/* Acoes recomendadas */}
              {response.acoesRecomendadas && response.acoesRecomendadas.length > 0 && (
                <div
                  style={{
                    borderTop: `1px solid ${orbitBorder}`,
                    paddingTop: 12,
                    marginTop: 4,
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 8,
                  }}
                >
                  <p
                    style={{
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: 700,
                      letterSpacing: '0.08em',
                      textTransform: 'uppercase',
                      margin: '0 0 4px',
                    }}
                  >
                    Acoes recomendadas
                  </p>
                  {response.acoesRecomendadas.map((acao, index) => (
                    <div
                      key={index}
                      style={{
                        background: 'rgba(108, 43, 255, 0.08)',
                        borderRadius: 12,
                        border: `1px solid ${orbitBorder}`,
                        padding: '10px 12px',
                      }}
                    >
                      {acao.titulo && (
                        <p
                          style={{
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: 600,
                            margin: '0 0 2px',
                          }}
                        >
                          {acao.titulo}
                        </p>
                      )}
                      {acao.descricao && (
                        <p
                          style={{
                            color: textSecondary,
                            fontSize: 13,
                            margin: 0,
                            lineHeight: 1.5,
                          }}
                        >
                          {acao.descricao}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Rodape de atribuicao */}
              {(response.modeloIa?.textoRodape ?? response.modeloIa?.nomeExibicao) && (
                <p
                  style={{
                    color: 'rgba(156, 163, 175, 0.5)',
                    fontSize: 11,
                    margin: '4px 0 0',
                    textAlign: 'right',
                  }}
                >
                  {response.modeloIa?.textoRodape ?? response.modeloIa?.nomeExibicao}
                </p>
              )}
            </div>

            {/* Botao primario */}
            <button
              onClick={onOpenChat}
              style={{
                background: accent,
                color: '#FFFFFF',
                border: 'none',
                borderRadius: 24,
                padding: '14px 24px',
                fontSize: 16,
                fontWeight: 700,
                cursor: 'pointer',
                width: '100%',
                letterSpacing: '0.01em',
              }}
            >
              Conversar com a IA
            </button>
          </>
        )}
      </div>
    </div>
  );
}
