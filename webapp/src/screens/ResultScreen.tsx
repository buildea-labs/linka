import { lazy, Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { CSSProperties } from 'react';
import { IOSList } from '../components/IOSList';
import { Icon, ConnectionIcon } from '../components/icons';
import { TopBar } from '../components/TopBar';
import { PageHeader } from '../components/PageHeader';
import { useScrollHeader } from '../hooks/useScrollHeader';
import { generateShareCard } from '../utils/shareCard';
import { buildShareText, shareResultText } from '../utils/share';
import type { Quality, ServerInfo, SpeedTestResult, TestRecord } from '../types';
import { interpretSpeedTestResult, resolveCopy } from '../core';
import { useDiagnosisItems } from '../features/diagnosis';
import { InfoTooltip } from '../components/InfoTooltip';
import type { UseCaseId } from '../core';
import { loadHistory } from '../utils/history';
import { formatMbps, formatMs } from '../utils/format';
import { formatRelativeTime } from '../utils/relativeTime';
import { useCountUp } from '../hooks/useCountUp';
import type { ConnectionType, GamingProfile } from '../types';
import './ResultScreen.css';
import { combineDiagnostics } from '../utils/combinedDiagnosis';
import { toConnectionProfile } from '../utils/connectionProfile';
import { classifyDnsLatency } from '../utils/dnsTiming';
import { aggregateDiagnosisSeverity, type DiagnosisAggregate, type DiagnosisItem } from '../utils/diagnosisItems';
import { evaluateMeasurementConfidence } from '../utils/measurementConfidence';
import { WifiSignalSection } from '../features/local-wifi/WifiSignalSection';
import { WifiContextCard } from '../features/ios-wifi-context/WifiContextCard';

// Code splitting (2026-05): as 3 sheets de "Mais detalhes" são pesadas e
// só são vistas quando o usuário toca em uma das rows. Lazy + montagem
// condicional faz cada chunk baixar apenas no primeiro acesso.
// Importante: o mount agora é feito dentro do bloco `{activeSheet === 'x'
// && (<Suspense><X .../></Suspense>)}` — caso contrário o React.lazy
// dispararia o download no mount da ResultScreen, sem ganho real.
const DNSGuideSheet = lazy(() =>
  import('../features/dns/DNSGuideSheet').then((m) => ({ default: m.DNSGuideSheet })),
);
const AdvancedSheet = lazy(() =>
  import('../features/result-detail/AdvancedSheet').then((m) => ({ default: m.AdvancedSheet })),
);
const GamerSheet = lazy(() =>
  import('../features/result-detail/GamerSheet').then((m) => ({ default: m.GamerSheet })),
);

interface Props {
  theme: 'dark' | 'light';
  onToggleTheme: () => void;
  result: SpeedTestResult;
  server: ServerInfo | null;
  previous: TestRecord | null;
  onRetry: () => void;
  /**
   * Handler do back da TopBar — vai para a tela inicial de medição.
   * Antes (Bloco 5) o back ia para o Histórico; movemos o Histórico para
   * a tela "Explorar" e o back voltou ao papel natural de "voltar para
   * a entrada do app", deixando a header do resultado mais limpa.
   */
  onBack: () => void;
  unit?: 'mbps' | 'gbps';
  hideIpOnShare?: boolean;
  gamingProfile?: GamingProfile;
  connectionType?: ConnectionType | null;
  onShowDiagnostico?: () => void;
}

type ShareStatus = 'idle' | 'copied';
type FocusUseCase = UseCaseId | 'all';

/** Sheets de "Mais detalhes" — só uma aberta por vez (refator drag-to-resize 2026-05). */
type ActiveSheet = 'advanced' | 'gamer' | 'dns' | null;
type ComplementaryTest = 'dns' | 'wifi' | 'advanced';

function inferComplementaryTest(items: DiagnosisItem[], connectionType: ConnectionType | null | undefined): ComplementaryTest {
  const text = items.map((i) => `${i.problem} ${i.action}`.toLowerCase()).join(' ');
  if (text.includes('dns') || text.includes('serviços de internet')) return 'dns';
  if (text.includes('wi-fi') || text.includes('wifi') || text.includes('roteador') || connectionType === 'wifi') return 'wifi';
  return 'advanced';
}

function ucIcon(id: UseCaseId): string {
  if (id === 'gaming')       return 'game';
  if (id === 'streaming_4k') return 'stream';
  if (id === 'home_office')  return 'work';
  return 'videoCall';
}

function ucLabel(id: UseCaseId): string {
  // Versão curta — cabe abaixo do ícone do use case.
  return resolveCopy(`useCase.${id}.label.short`);
}

function connectionTypeLabel(connectionType: ConnectionType | null | undefined): string {
  if (connectionType === 'wifi') return 'Wi-Fi';
  if (connectionType === 'mobile') return 'Rede móvel';
  if (connectionType === 'cable') return 'Cabo';
  return 'Conexão não identificada';
}

function periodOfDay(timestamp: number): 'morning' | 'afternoon' | 'night' {
  const hour = new Date(timestamp).getHours();
  if (hour >= 6 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 19) return 'afternoon';
  return 'night';
}

function periodLabel(period: 'morning' | 'afternoon' | 'night'): string {
  if (period === 'morning') return 'manhã';
  if (period === 'afternoon') return 'tarde';
  return 'noite';
}

function getUseCaseAlertReason(id: UseCaseId, factors: Array<'dl' | 'ul' | 'latency' | 'jitter' | 'packetLoss' | 'unknown'>): string {
  if (id === 'gaming') {
    if (factors.includes('packetLoss')) return 'Falhas na conexão podem causar quedas durante a partida.';
    if (factors.includes('jitter')) return 'A oscilação pode causar lag mesmo com boa velocidade.';
    if (factors.includes('latency')) return 'O ping está alto para comandos em tempo real.';
    return resolveCopy('useCase.gaming.acceptable_reason');
  }

  if (factors.includes('packetLoss')) return 'Falhas na conexão podem causar travamentos.';
  if (factors.includes('jitter')) return 'Oscilação alta pode deixar a experiência instável.';
  if (factors.includes('latency')) return 'A resposta está demorando mais que o ideal.';
  if (factors.includes('ul')) return 'O envio de dados está abaixo do ideal.';
  if (factors.includes('dl')) return 'A velocidade está abaixo do ideal para este uso.';
  return 'Pode funcionar com limitações.';
}

// =============================================================================
// Verdict label (pacote premium 2026-05, refatorado 2026-05) — mapping de
// Quality → texto curto. Texto continua sendo necessário para `aria-label`
// e `sr-only` do card unificado (chip flutuante foi removido — verdict
// virou ribbon visual de 3px). Mantemos mapa local enxuto porque
// `copyDictionary.ts` é zona "não tocar" e não expõe `quality.<X>.adj`.
// =============================================================================

function verdictLabel(q: Quality): string {
  return resolveCopy(`quality.${q}.headline`);
}

// =============================================================================
// Ribbon do card unificado de teste (refactor 2026-05).
// =============================================================================
// Substitui o chip flutuante "Aceitável/Boa/Lenta" por uma faixa colorida de
// 3px no topo do `.lk-result__test-card`. Decisão de cor: tokens cheios
// (`--success / --warn / --error`) e não os `--color-*-bg` (alpha 0.08-0.10
// é invisível numa faixa de 3px). Mesma semântica de quality que o antigo
// `verdictStyle()` usava para tingir o chip.
function qualityRibbonColor(q: Quality): string {
  if (q === 'excellent' || q === 'good') return 'var(--success)';
  if (q === 'fair')                       return 'var(--warn)';
  // slow / unavailable
  return 'var(--error)';
}

function diagnosticTitle(q: Quality): string {
  if (q === 'excellent' || q === 'good') return 'Conexão excelente';
  if (q === 'fair') return 'Conexão adequada';
  return 'Conexão com instabilidade';
}

function diagnosticSummary(q: Quality): string {
  if (q === 'excellent' || q === 'good') {
    return 'Sua conexão está adequada para jogos, streaming, videochamadas e home office.';
  }
  if (q === 'fair') {
    return 'Sua conexão atende tarefas do dia a dia, mas pode oscilar em usos intensivos.';
  }
  return 'Sua conexão apresentou limitações para usos mais sensíveis.';
}

// =============================================================================
// DiagnosticActionList — estado "com ação" do card de Diagnóstico (2026-05).
// =============================================================================
// Render auxiliar isolado para manter o JSX da ResultScreen legível. Recebe
// itens já priorizados por `buildDiagnosisItems()` e mostra no máximo 3
// visíveis; um botão "Ver mais N" alterna a exibição dos restantes inline.
//
// Quando a lista de items vier vazia (combined diagnostico ≠ healthy mas
// nenhuma métrica individual disparou) caímos no `fallbackTitle`/`fallbackAction`
// — preserva a antiga UX de "kicker + título + ação primária" para causas
// em que a lista por métrica não tem o que dizer (ex.: combined.cause =
// 'mobile_signal_risk' com métricas todas verdes).

const SEVERITY_COLOR: Record<DiagnosisItem['severity'], string> = {
  fail: 'var(--error)',
  warn: 'var(--warn)',
};

const SEVERITY_BG: Record<DiagnosisItem['severity'], string> = {
  fail: 'var(--color-bad-bg)',
  warn: 'var(--color-warn-bg)',
};

// =============================================================================
// Glow do card de Diagnóstico (refator 2026-05).
// =============================================================================
// Mapping da severidade agregada (`aggregateDiagnosisSeverity`) para o token
// de glow que será aplicado como `--diag-glow-color` inline no contêiner
// `.lk-result__combined`. A animação `lk-result-diag-glow` (CSS) lê essa
// var e pulsa entre 24px e 32px de blur — a cor é o único delta entre os
// 3 estados visuais.
const SEVERITY_GLOW: Record<DiagnosisAggregate, string> = {
  healthy: 'var(--success-glow)',
  warn:    'var(--warn-glow)',
  fail:    'var(--error-glow)',
};

function DiagnosticActionList({
  items,
  dnsHint,
  fallbackTitle,
  fallbackAction,
  style,
}: {
  items: DiagnosisItem[];
  dnsHint: boolean;
  fallbackTitle: string;
  fallbackAction: string;
  /** Custom properties inline (ex.: `--diag-glow-color`). */
  style?: CSSProperties;
}) {
  const [expanded, setExpanded] = useState(false);
  const secondaryLimit = 2;
  const primary = items[0] ?? null;
  const secondaryItems = expanded ? items.slice(1) : items.slice(1, 1 + secondaryLimit);
  const remaining = Math.max(0, items.length - (1 + secondaryLimit));

  const showFallback = items.length === 0;

  return (
    <div className="lk-result__combined" style={style}>
      <p className="lk-result__combined-kicker">Diagnóstico da conexão</p>

      {showFallback && (
        <>
          <p className="lk-result__combined-title">{fallbackTitle}</p>
          <div className="lk-result__combined-action">
            <span>O que fazer agora:</span>
            <strong>{fallbackAction}</strong>
          </div>
        </>
      )}

      {!showFallback && (
        <>
          {primary && (
            <div className="lk-result__combined-primary" aria-label="Recomendação principal">
              <p className="lk-result__combined-primary-kicker">Prioridade agora</p>
              <div className="lk-result__combined-primary-row">
                <div
                  className="lk-result__combined-item-icon"
                  style={{ background: SEVERITY_BG[primary.severity], color: SEVERITY_COLOR[primary.severity] }}
                >
                  <Icon name={primary.icon} size={14} />
                </div>
                <div className="lk-result__combined-primary-copy">
                  <p className="lk-result__combined-primary-problem">Motivo: {primary.problem}</p>
                  <p className="lk-result__combined-primary-action">Próximo passo: {primary.action}</p>
                </div>
              </div>
            </div>
          )}

          {secondaryItems.length > 0 && (
            <ul className="lk-result__combined-list" aria-label="Próximos passos sugeridos">
              {secondaryItems.map((item) => (
                <li key={item.id} className={`lk-result__combined-item lk-result__combined-item--${item.severity}`}>
                  <div
                    className="lk-result__combined-item-icon"
                    style={{ background: SEVERITY_BG[item.severity], color: SEVERITY_COLOR[item.severity] }}
                  >
                    <Icon name={item.icon} size={14} />
                  </div>
                  <div className="lk-result__combined-item-text">
                    <span className="lk-result__combined-item-problem">{item.problem}</span>
                    <span className="lk-result__combined-item-arrow" aria-hidden="true">→</span>
                    <span className="lk-result__combined-item-action">{item.action}</span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </>
      )}

      {!showFallback && !expanded && remaining > 0 && (
        <button
          type="button"
          className="lk-result__combined-more"
          onClick={() => setExpanded(true)}
        >
          Ver mais {remaining}
        </button>
      )}

      {dnsHint && (
        <div className="lk-result__combined-action lk-result__combined-action--secondary">
          <span>Otimização adicional:</span>
          <strong>
            Trocar para Cloudflare ou Google pode reduzir o tempo de resposta dos Serviços de Internet (DNS).
            Veja como em Mais detalhes &gt; Serviços de Internet &gt; Como alterar.
          </strong>
        </div>
      )}
    </div>
  );
}

export function ResultScreen({
  theme, onToggleTheme,
  result,
  server,
  onRetry, onBack,
  unit = 'mbps',
  connectionType,
  onShowDiagnostico,
}: Props) {
  void theme;
  void onToggleTheme;
  const history = useMemo(() => loadHistory(), []);
  const profile = useMemo(
    () => toConnectionProfile(connectionType ?? undefined),
    [connectionType],
  );
  const interpreted = useMemo(
    () => interpretSpeedTestResult(
      result,
      profile,
      history,
    ),
    [result, profile, history],
  );

  const combined = useMemo(
    () =>
      combineDiagnostics({
        speed: result,
        connectionType: connectionType ?? 'unknown',
        wifi: undefined,
        mobile: undefined,
      }),
    [result, connectionType],
  );

  const diagnosisItems = useDiagnosisItems(result, connectionType);
  const measurementConfidence = useMemo(() => evaluateMeasurementConfidence(result), [result]);
  const contextInsight = useMemo(() => {
    const sameConnection = history.filter((h) => h.connectionType === (connectionType ?? 'unknown'));
    const avgDl = sameConnection.length > 0
      ? sameConnection.reduce((acc, h) => acc + h.dl, 0) / sameConnection.length
      : null;
    const delta = avgDl != null ? result.dl - avgDl : null;
    const avgBase = avgDl ?? 0;
    const trendText = delta == null
      ? 'Ainda não há histórico suficiente para comparar este cenário.'
      : Math.abs(delta) <= Math.max(5, avgBase * 0.1)
        ? 'Seu resultado ficou parecido com os testes anteriores nesta conexão.'
        : delta > 0
          ? 'Seu resultado ficou melhor que sua média recente nesta conexão.'
          : 'Seu resultado ficou abaixo da sua média recente nesta conexão.';
    const period = periodOfDay(result.timestamp);
    return {
      connection: connectionTypeLabel(connectionType),
      period: periodLabel(period),
      trendText,
    };
  }, [connectionType, history, result.dl, result.timestamp]);
  const complementaryTest = useMemo(
    () => inferComplementaryTest(diagnosisItems.items, connectionType),
    [connectionType, diagnosisItems.items],
  );

  const unitLabel = unit === 'gbps' ? 'Gbps' : 'Mbps';

  // Animação count-up dos números das duas faixas (Bloco Motion).
  const animDl     = useCountUp(result.dl,         700, 1);
  const animUl     = useCountUp(result.ul,         700, 1);
  const animLat    = useCountUp(result.latency,    700, 0);
  const animJitter = useCountUp(result.jitter,     700, 0);
  const animLoss   = useCountUp(result.packetLoss, 700, 0);
  // DNS feature (2026-05): count-up só anima quando há valor — quando
  // dnsLatencyMs é null/undefined a cell mostra "—" em vez do número.
  const animDns    = useCountUp(result.dnsLatencyMs ?? 0, 700, 0);

  const [shareStatus, setShareStatus] = useState<ShareStatus>('idle');
  const [focusUseCase, setFocusUseCase] = useState<FocusUseCase>('all');
  const [includeContextInShare, setIncludeContextInShare] = useState(false);
  const [includeSensitiveInTechnical, setIncludeSensitiveInTechnical] = useState(false);
  const [waGenerating, setWaGenerating] = useState(false);
  const [imgGenerating, setImgGenerating] = useState(false);
  const shareResetRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => {
    if (shareResetRef.current) clearTimeout(shareResetRef.current);
  }, []);

  // Opcionais passados ao share card — headline qualitativa do motor +
  // ISP detectado pelo serverRegistry (rodapé do PNG). A headline continua
  // sendo gerada pelo motor (`interpret.ts`) — só não é mais renderizada
  // como hero na tela de resultado (refactor visual 2026-05).
  const shareCardHeadline = resolveCopy(interpreted.copyKeys.headlineKey);
  const shareCardIsp = includeContextInShare ? (server?.isp ?? null) : null;

  const buildQuickShareText = useCallback(() => {
    const lines = [
      'Resultado Veloo',
      `Download: ${formatMbps(result.dl)} Mbps`,
      `Upload: ${result.ulFailed ? 'parcial/indisponível' : `${formatMbps(result.ul)} Mbps`}`,
      `Latência: ${formatMs(result.latency)} ms`,
      `Oscilação: ${formatMs(result.jitter)} ms`,
      `Falhas: ${Math.round(result.packetLoss)}%`,
    ];
    if (includeContextInShare) {
      lines.push(`Conexão: ${connectionTypeLabel(connectionType)}`);
      if (server?.name) lines.push(`Servidor: ${server.name}`);
    }
    return lines.join('\n');
  }, [connectionType, includeContextInShare, result.dl, result.jitter, result.latency, result.packetLoss, result.ul, result.ulFailed, server]);

  const handleShare = async () => {
    const text = includeContextInShare
      ? buildShareText(result, interpreted.primary, unit)
      : buildQuickShareText();
    const outcome = await shareResultText(text);
    if (outcome === 'copied') {
      setShareStatus('copied');
      if (shareResetRef.current) clearTimeout(shareResetRef.current);
      shareResetRef.current = setTimeout(() => {
        setShareStatus('idle');
        shareResetRef.current = null;
      }, 2000);
    }
  };

  const handleWhatsApp = async () => {
    if (waGenerating) return;
    setWaGenerating(true);
    try {
      const blob = await generateShareCard(result, interpreted.primary, unit, {
        headline: shareCardHeadline,
        isp: shareCardIsp,
      });
      const file = new File([blob], 'veloo-speedtest.png', { type: 'image/png' });
      if (navigator.canShare?.({ files: [file] })) {
        await navigator.share({ files: [file], title: 'Veloo' });
      } else {
        const text = includeContextInShare
          ? buildShareText(result, interpreted.primary, unit)
          : buildQuickShareText();
        window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank', 'noopener');
      }
    } catch { /* cancelado */ }
    finally { setWaGenerating(false); }
  };

  // Botão "Compartilhar imagem" do footer (Bloco 3 — Polimento, 2026-05).
  // Tenta Web Share API com `files`; se indisponível, dispara download
  // direto do PNG via objeto URL (fallback funcional sem perder a imagem).
  const handleShareImage = useCallback(async () => {
    if (imgGenerating) return;
    setImgGenerating(true);
    try {
      const blob = await generateShareCard(result, interpreted.primary, unit, {
        headline: shareCardHeadline,
        isp: shareCardIsp,
      });
      const file = new File([blob], 'veloo-speedtest.png', { type: 'image/png' });
      if (navigator.canShare?.({ files: [file] })) {
        await navigator.share({ files: [file], title: 'Veloo' });
      } else {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'veloo-speedtest.png';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    } catch { /* cancelado */ }
    finally { setImgGenerating(false); }
  }, [result, interpreted.primary, unit, shareCardHeadline, shareCardIsp, imgGenerating]);

  const downloadEvidenceFile = useCallback((filename: string, content: string, contentType: string) => {
    const blob = new Blob([content], { type: contentType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, []);

  const handleDownloadSupportSummary = useCallback(() => {
    const when = new Date(result.timestamp).toLocaleString('pt-BR');
    const summary = [
      'Veloo - Evidência resumida para suporte',
      '',
      `Data/hora: ${when}`,
      `Download: ${formatMbps(result.dl)} Mbps`,
      `Upload: ${result.ulFailed ? 'parcial/indisponível' : `${formatMbps(result.ul)} Mbps`}`,
      `Latência: ${formatMs(result.latency)} ms`,
      `Oscilação: ${formatMs(result.jitter)} ms`,
      `Falhas: ${Math.round(result.packetLoss)}%${result.packetLossSource === 'estimated' ? ' (estimado)' : ''}`,
      `Servidor: ${server?.name ?? 'não identificado'}`,
      '',
      'Observação: evidência circunstancial de medição no dispositivo do usuário.',
      'Não constitui laudo técnico oficial.',
    ].join('\n');
    downloadEvidenceFile(`veloo-evidencia-resumo-${result.timestamp}.txt`, summary, 'text/plain;charset=utf-8');
  }, [downloadEvidenceFile, result, server?.name]);

  const handleDownloadTechnicalRecord = useCallback(() => {
    const payload = {
      generatedAt: new Date().toISOString(),
      source: 'Veloo Web PWA',
      disclaimer: 'Evidência circunstancial. Não constitui laudo técnico oficial.',
      result: {
        timestamp: result.timestamp,
        dlMbps: result.dl,
        ulMbps: result.ul,
        ulFailed: !!result.ulFailed,
        latencyMs: result.latency,
        jitterMs: result.jitter,
        packetLossPct: result.packetLoss,
        packetLossSource: result.packetLossSource ?? 'unknown',
      },
      context: includeSensitiveInTechnical
        ? {
            connectionType: connectionType ?? 'unknown',
            server: server ? { id: server.id, name: server.name, loc: server.loc, isp: server.isp } : null,
          }
        : {
            connectionType: connectionType ?? 'unknown',
            server: null,
          },
    };
    downloadEvidenceFile(
      `veloo-evidencia-tecnica-${result.timestamp}.json`,
      JSON.stringify(payload, null, 2),
      'application/json;charset=utf-8',
    );
  }, [connectionType, downloadEvidenceFile, includeSensitiveInTechnical, result, server]);

  const handleExportTechnicalPdf = useCallback(() => {
    const popup = window.open('', '_blank', 'noopener,noreferrer');
    if (!popup) return;
    const when = new Date(result.timestamp).toLocaleString('pt-BR');
    const contextLine = includeSensitiveInTechnical
      ? `${connectionTypeLabel(connectionType)} · ${server?.name ?? 'Servidor não identificado'}`
      : `${connectionTypeLabel(connectionType)} · dados sensíveis ocultos`;
    popup.document.write(`
      <html><head><title>Evid�ncia Veloo</title>
      <style>
        body{font-family:Arial,sans-serif;padding:24px;color:#111}
        h1{font-size:20px;margin:0 0 4px}.muted{color:#555;font-size:12px}
        .card{border:1px solid #ddd;border-radius:10px;padding:12px;margin-top:10px}
        .row{margin:4px 0}
      </style></head><body>
      <h1>Pacote de evidência Veloo</h1>
      <p class="muted">Evidência circunstancial, não é laudo técnico oficial.</p>
      <div class="card">
        <div class="row"><strong>Data/hora:</strong> ${when}</div>
        <div class="row"><strong>Download:</strong> ${formatMbps(result.dl)} Mbps</div>
        <div class="row"><strong>Upload:</strong> ${result.ulFailed ? 'parcial/indisponível' : `${formatMbps(result.ul)} Mbps`}</div>
        <div class="row"><strong>Latência:</strong> ${formatMs(result.latency)} ms</div>
        <div class="row"><strong>Oscilação:</strong> ${formatMs(result.jitter)} ms</div>
        <div class="row"><strong>Falhas:</strong> ${Math.round(result.packetLoss)}%</div>
      </div>
      <div class="card"><div class="row"><strong>Contexto:</strong> ${contextLine}</div></div>
      </body></html>
    `);
    popup.document.close();
    popup.focus();
    popup.print();
  }, [connectionType, includeSensitiveInTechnical, result, server?.name]);

  // Bloco 5 — TopBar System (2026-05): scroll listener para alternar
  // glass effect + título "Resultado do teste" no TopBar quando o usuário rola.
  // Padronização Large Title (2026-05, frente B): o sentinel agora é o
  // próprio <PageHeader> "Resultado do teste" no topo do scroll content — mesmo
  // padrão de Explore/History/Diagnostic. Substitui o div invisível que
  // existia no slot anterior.
  const { scrolled, topBarOpacity, scrollContainerRef, sentinelRef } = useScrollHeader();

  // Refator 2026-05 (drag-to-resize): a seção "Mais detalhes" virou 3
  // rows clicáveis (Avançado / Modo Gamer / DNS). Cada uma abre um
  // bottom sheet dedicado (AdvancedSheet, GamerSheet, DNSGuideSheet).
  // `activeSheet` unifica os 3 estados — só uma sheet aberta por vez.
  const [activeSheet, setActiveSheet] = useState<ActiveSheet>(null);
  const closeActiveSheet = useCallback(() => setActiveSheet(null), []);

  const focusedUseCaseEntry = useMemo(() => {
    if (focusUseCase === 'all') return null;
    return interpreted.useCases.find((u) => u.id === focusUseCase) ?? null;
  }, [focusUseCase, interpreted.useCases]);

  return (
    <div className="lk-result fade-in">
      <TopBar
        onBack={onBack}
        scrolled={scrolled}
        opacity={topBarOpacity}
        title="Resultado do teste"
        showTitle={scrolled}
      />

      <div className="lk-result__scroll" ref={scrollContainerRef}>
        {/* Large Title pattern (2026-05, frente B): título grande "Resultado do
            teste" no início do scroll, idêntico a Explore/History/
            Diagnostic. Funciona como sentinel do `useScrollHeader` — ao
            sair da viewport, TopBar ganha glass + título pequeno. */}
        <PageHeader ref={sentinelRef} size="md" title="Resultado do teste" />

        {/* ── Banner de contexto (pacote premium 2026-05, refeito 2026-05) ─
            Linha única discreta logo após o Large Title: server · loc ·
            isp · DNS · tempo relativo. Cada pedaço some individualmente
            quando o dado falta — a linha inteira some se todos os campos
            forem nulos.

            Refactor 2026-05 (card unificado): o "chip flutuante" de
            verdict que vivia aqui foi removido — o verdict agora é
            comunicado pela cor do ribbon de 3px no topo do
            `.lk-result__test-card` (ver `qualityRibbonColor`). Texto do
            verdict permanece acessível via `aria-label` + `<span class=
            "sr-only">` no card. */}
        {(() => {
          const parts: string[] = [];
          if (server?.name) parts.push(server.name);
          if (server?.isp && server.isp !== '—') parts.push(server.isp);
          const rel = formatRelativeTime(result.timestamp);
          if (rel) parts.push(rel);
          // Sem peças, sem banner. Verdict não é mais chip aqui — é ribbon
          // do card abaixo, então não há motivo para manter linha vazia.
          // Bug-fix 2026-05 (rede móvel): se não há peças textuais MAS temos
          // connectionType conhecido, ainda renderizamos a barra apenas com
          // o ícone — manter a referência visual da rede no card.
          if (parts.length === 0 && !connectionType) return null;
          // Ícone discreto Wi-Fi / Móvel / Cabo no canto direito (top do
          // card unificado, abaixo do TopBar). Usa `connectionType` resolvido
          // pelo `useDeviceInfo` (override manual aplicado em `App.tsx`).
          // `unknown` não renderiza — preferível ausente que ícone errado.
          const showConnIcon = connectionType === 'wifi'
            || connectionType === 'mobile'
            || connectionType === 'cable';
          const connLabel =
            connectionType === 'wifi'   ? 'Wi-Fi' :
            connectionType === 'mobile' ? 'Rede móvel' :
            connectionType === 'cable'  ? 'Cabo' : '';
          return (
            <div className="lk-result__context-bar" role="contentinfo">
              <span className="lk-result__context-bar-meta">
                {parts.map((p, i) => (
                  <span key={`${i}-${p}`} className="lk-result__context-bar-item">
                    {i > 0 && <span className="lk-result__context-bar-sep" aria-hidden="true">·</span>}
                    {p}
                  </span>
                ))}
              </span>
              {showConnIcon && (
                <span
                  className="lk-result__context-bar-conn"
                  aria-label={`Conexão: ${connLabel}`}
                  title={connLabel}
                  style={{ color: 'var(--text-2)', display: 'inline-flex', marginLeft: 'auto' }}
                >
                  <ConnectionIcon kind={connectionType!} size={16} />
                </span>
              )}
            </div>
          );
        })()}

        {/* Bug-fix 2026-05 (upload mobile): aviso de resultado parcial.
            Aparece quando `ulFailed=true` (DL/latência mediram OK mas
            upload não completou — típico em uplink celular saturado).
            Estilo discreto, sem alarme — o resto do resultado é válido. */}
        {result.ulFailed && (
          <div
            className="lk-result__context-bar"
            role="status"
            aria-live="polite"
            style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}
          >
            <span className="lk-result__context-bar-meta">
              Upload não pôde ser medido. Resultado parcial.
            </span>
          </div>
        )}

        {/* ── Card unificado de teste (refactor 2026-05) ──────────────────
            Os 4 blocos (PRIMARY, SECONDARY, USE CASES, WI-FI) viviam como
            cards separados, e o "verdict" da medição era um chip
            flutuante que pairava acima deles. Agora tudo está dentro de
            UM `.lk-result__test-card`, separado por hairlines internos,
            com um ribbon colorido de 3px no topo (cor derivada de
            `interpreted.primary`) substituindo o chip flutuante. O
            verdict continua acessível via `aria-label` + texto
            `sr-only`. */}
        <section
          className="lk-result__test-card"
          style={{ ['--ribbon-color' as never]: qualityRibbonColor(interpreted.primary) } as CSSProperties}
          aria-label={`Resultado: ${verdictLabel(interpreted.primary)}`}
        >
          <span className="sr-only">Verdict: {verdictLabel(interpreted.primary)}</span>

        <div className="lk-result__diag-summary">
          <div className="lk-result__diag-summary-icon" aria-hidden="true">
            <Icon name="check-circle" size={16} color="var(--success)" />
          </div>
          <div className="lk-result__diag-summary-copy">
            <p className="lk-result__diag-summary-title">{diagnosticTitle(interpreted.primary)}</p>
            <p className="lk-result__diag-summary-text">{diagnosticSummary(interpreted.primary)}</p>
          </div>
        </div>
        <div className="lk-result__diag-tags">
          <span className="lk-result__diag-tag">Download alto</span>
          <span className="lk-result__diag-tag">Upload bom</span>
          <span className="lk-result__diag-tag">Baixa latência</span>
          <span className="lk-result__diag-tag">
            {result.packetLoss <= 0 ? 'Sem perda detectada' : 'Falhas detectadas'}
          </span>
        </div>

        {/* ── Bloco PRIMARY — Download e Upload em fonte enorme ───────────
            Hierarquia visual nova (refactor 2026-05): as duas métricas
            "principais" (banda) ganham peso máximo. Sem badge de grade
            por métrica — as grades agora vivem no chip de cada use case
            abaixo, refletindo o pior caso por cenário.

            Plano vs entregue (pacote premium 2026-05): quando o usuário
            cadastrou velocidade contratada (`contractedDown`/`Up`), cada
            cell exibe `entregue / contratado · %`. O número grande é o
            entregue (animado pelo count-up); a fração `/ Y` e o `· Z%`
            ficam em fonte menor logo abaixo, sem animar (% é contexto,
            usuário lê o absoluto primeiro). Sem cap em 100%.

            Cores semânticas Anatel (2026-05): quando o plano está
            cadastrado, o número grande deixa o azul/verde de marca e
            passa a refletir % de entrega via `anatelGrade()`. As regras
            mudam por perfil (fixa: 80/40 · móvel: 60/20 — Resolução
            Anatel 717/2019). Sem plano: comportamento original
            preservado (`var(--dl)` / `var(--ul)`). O `text-shadow` (glow)
            também muda de família para casar com a nova cor — sem isso o
            número verde teria aura azul. O `· 97%` da linha plan ganha
            a mesma cor (sutilmente — só o número, nunca a fração). */}
        <div className="lk-result__primary-block">
          <div className="lk-result__primary-cell">
            <div className="lk-result__primary-cell-label">Download</div>
            <div className="lk-result__primary-cell-value">
              {formatMbps(animDl, unit)}
            </div>
            <div className="lk-result__primary-cell-unit">{unitLabel}</div>
          </div>
          <div className="lk-result__primary-cell">
            <div className="lk-result__primary-cell-label">Upload</div>
            {result.ulFailed ? (
              <>
                <div className="lk-result__primary-cell-value" style={{ color: 'var(--text-muted)' }}>
                  —
                </div>
                <div className="lk-result__primary-cell-unit" style={{ color: 'var(--text-muted)' }}>
                  não medido
                </div>
              </>
            ) : (
              <>
                <div className="lk-result__primary-cell-value">
                  {formatMbps(animUl, unit)}
                </div>
                <div className="lk-result__primary-cell-unit">{unitLabel}</div>
              </>
            )}
          </div>
        </div>

        {/* ── Bloco SECONDARY — diagnóstico em fonte média ──────────────
            Resposta (latency), Oscilação (jitter) e Falhas (packet loss).
            Padronização Polimento UX: packet loss = "Falhas" (curto).
            DNS (2026-05, refatorado para Safari): 4ª cell renderizada
            apenas quando há latência OU provider — quando ambos forem
            null (probe DoH falhou E Resource Timing zerada), o bloco
            colapsa para 3 colunas em vez de mostrar "—". */}
        {(() => {
          const showDnsCell = result.dnsLatencyMs != null || result.dnsProvider != null;
          const gridStyle = showDnsCell
            ? undefined
            : { gridTemplateColumns: 'repeat(3, 1fr)' };
          return (
            <div className="lk-result__secondary-block" style={gridStyle}>
              <div className="lk-result__secondary-cell">
                <div className="lk-result__secondary-cell-label">
                  Ping
                  <InfoTooltip
                    label="Tempo até a primeira resposta do servidor. Quanto menor, melhor pra jogos e videochamadas."
                    ariaLabel="O que é Ping"
                  />
                </div>
                <div className="lk-result__secondary-cell-value">
                  {formatMs(result.latency > 0 ? Math.max(0.1, animLat) : animLat)}
                  <span className="lk-result__secondary-cell-unit"> ms</span>
                </div>
              </div>
              <div className="lk-result__secondary-cell">
                <div className="lk-result__secondary-cell-label">
                  Oscilação
                  <InfoTooltip
                    label="Variação no tempo de resposta. Alta oscilação causa lag mesmo com latência baixa."
                    ariaLabel="O que é Oscilação"
                  />
                </div>
                <div className="lk-result__secondary-cell-value">
                  {formatMs(result.jitter > 0 ? Math.max(0.1, animJitter) : animJitter)}
                  <span className="lk-result__secondary-cell-unit"> ms</span>
                </div>
              </div>
              <div className="lk-result__secondary-cell">
                <div className="lk-result__secondary-cell-label">
                  Falhas
                  <InfoTooltip
                    label="% de pacotes que não chegaram ao destino. Mais que 1% afeta jogos e chamadas."
                    ariaLabel="O que é Falhas na conexão"
                  />
                  {result.packetLossSource !== 'native' && (
                    /* Label "estimado" (2026-05) — transparência: o
                       valor de packet loss no PWA web é heurístico
                       (timeouts de ping HTTP). */
                    <span className="lk-result__secondary-cell-tag" aria-label="valor estimado">
                      {' '}estimado
                    </span>
                  )}
                </div>
                <div className="lk-result__secondary-cell-value">
                  {Math.round(animLoss)}
                  <span className="lk-result__secondary-cell-unit"> %</span>
                </div>
              </div>
              {showDnsCell && (
                /* Atalho (2026-05): clique na cell DNS abre o DNSGuideSheet.
                   A11y refator (2026-05): substituímos `<div role="button">`
                   por `<button>` real — keyboard activation (Enter/Space) e
                   focus ring vêm de graça do navegador, sem onKeyDown
                   manual. `lk-result__secondary-cell--btn` reseta o estilo
                   default de button para casar com as demais cells. */
                <button
                  type="button"
                  className="lk-result__secondary-cell lk-result__secondary-cell--clickable lk-result__secondary-cell--btn"
                  aria-label="Abrir guia de Serviços de Internet (DNS)"
                  onClick={() => setActiveSheet('dns')}
                >
                  <div className="lk-result__secondary-cell-label">DNS</div>
                  <div className="lk-result__secondary-cell-value">
                    {result.dnsLatencyMs == null ? (
                      <>—</>
                    ) : (
                      <>
                        {Math.round(animDns)}
                        <span className="lk-result__secondary-cell-unit"> ms</span>
                      </>
                    )}
                  </div>
                </button>
              )}
            </div>
          );
        })()}

        <div className={`lk-result__confidence lk-result__confidence--${measurementConfidence.level}`}>
          <div className="lk-result__confidence-top">
            <span className="lk-result__confidence-kicker">Confiabilidade da medição</span>
            <span className="lk-result__confidence-badge">{measurementConfidence.label}</span>
          </div>
          <p className="lk-result__confidence-reason">{measurementConfidence.reason}</p>
          {measurementConfidence.shouldRetest && (
            <p className="lk-result__confidence-next">
              Próximo passo: repita o teste para confirmar este resultado.
            </p>
          )}
        </div>

        <div className="lk-result__next-test">
          <p className="lk-result__next-test-kicker">Teste complementar recomendado</p>
          {complementaryTest === 'dns' && (
            <>
              <p className="lk-result__next-test-text">Seu próximo passo mais útil agora é validar Serviços de Internet (DNS).</p>
              <button type="button" className="btn-text lk-result__next-test-btn" onClick={() => setActiveSheet('advanced')}>
                Abrir avançado
              </button>
            </>
          )}
          {complementaryTest === 'wifi' && (
            <>
              <p className="lk-result__next-test-text">Vale conferir sinais de Wi-Fi e histórico para confirmar se o problema é local.</p>
              <button type="button" className="btn-text lk-result__next-test-btn" onClick={() => setActiveSheet('advanced')}>
                Abrir avançado
              </button>
            </>
          )}
          {complementaryTest === 'advanced' && (
            <>
              <p className="lk-result__next-test-text">Faça uma checagem avançada para confirmar estabilidade e variações da conexão.</p>
              <button type="button" className="btn-text lk-result__next-test-btn" onClick={() => setActiveSheet('advanced')}>
                Abrir avançado
              </button>
            </>
          )}
        </div>

        {/* ── Use cases row — agora com grade A-F por cenário ──────────
            A grade vem de `useCaseGrade()` (src/core/useCaseGrade.ts):
            pior das métricas relevantes para cada use case avaliada
            contra os thresholds de qualidade do profile ativo.
            W5-B: estado aprovado (A/B) mostra check verde + "Velocidade
            adequada para este uso"; reprovado mantém badge de grade. */}
        {interpreted.useCases.length > 0 && (
          <div className="lk-result__use-list">
            <p className="lk-result__use-header">EXPERIÊNCIA DE USO</p>
            <div className="lk-result__use-focus">
              <button
                type="button"
                className={`lk-result__use-focus-chip ${focusUseCase === 'all' ? 'is-active' : ''}`}
                onClick={() => setFocusUseCase('all')}
              >
                Todos
              </button>
              {interpreted.useCases.map(({ id }) => (
                <button
                  key={`focus-${id}`}
                  type="button"
                  className={`lk-result__use-focus-chip ${focusUseCase === id ? 'is-active' : ''}`}
                  onClick={() => setFocusUseCase(id)}
                >
                  {ucLabel(id)}
                </button>
              ))}
            </div>
            {focusedUseCaseEntry && (
              <p className="lk-result__use-focus-summary">
                Perfil selecionado: <strong>{ucLabel(focusedUseCaseEntry.id)}</strong>.
                {focusedUseCaseEntry.status === 'good'
                  ? ' Sua conexão está adequada para este uso.'
                  : ' Este uso pode sofrer com limitações na conexão atual.'}
              </p>
            )}
            <div className="lk-result__use-divider" />
            {interpreted.useCases.map(({ id, status, blockingFactors }) => {
              const isPositive = status === 'good';
              return (
                <div key={id}>
                  <div className="lk-result__use-item">
                    <div className="lk-result__use-icon-wrap">
                      <Icon name={ucIcon(id)} size={20} color="var(--accent)" />
                    </div>
                    <span className="lk-result__use-lbl">
                      {ucLabel(id)}
                      {!isPositive && (
                        <span className="lk-result__use-reason">
                          {getUseCaseAlertReason(id, blockingFactors)}
                        </span>
                      )}
                    </span>
                    {isPositive ? (
                      <span className="lk-result__use-ok">
                        <Icon name="check-circle" size={14} color="var(--success)" />
                        <span style={{ color: 'var(--success)', fontSize: 12, marginLeft: 4 }}>Adequada</span>
                      </span>
                    ) : (
                      <span className="lk-result__use-badge" style={{ background: 'var(--color-warn-bg)', color: 'var(--warn)' }}>
                        Atenção
                      </span>
                    )}
                  </div>
                  <div className="lk-result__use-divider" />
                </div>
              );
            })}
            {/* W5-B — Nota sobre jitter ao final da seção de uso */}
            <p className="lk-result__use-jitter-note">
              Oscilação é quando o tempo de resposta varia — valores altos causam lag em jogos e travamentos em videochamadas.
            </p>
          </div>
        )}

        {/* ── Wi-Fi signal section ──────────────────────────────────────
            Inserida entre a use-row e o "Diagnóstico da conexão" quando
            a conexão atual é Wi-Fi. No PWA puro, dados locais de Wi-Fi
            ficam indisponíveis e a seção mostra a mensagem
            "Wi-Fi: detalhes disponíveis somente no app instalado.".

            Refator 2026-05 (barra horizontal): a representação INLINE no
            card unificado virou uma barra horizontal de qualidade do
            sinal (`<WifiSignalBar>`) — header "WI-FI" + SSID/canal +
            barra colorida (verde/amarelo/vermelho) + %. A `WifiDetailsSheet`
            ao clicar continua mostrando os 4 dados completos. */}
        {connectionType === 'wifi' && <WifiSignalSection connectionType={connectionType} />}

        <div className="lk-result__context-insight">
          <p className="lk-result__context-insight-kicker">Contexto do teste</p>
          <p className="lk-result__context-insight-line">
            Conexão usada: <strong>{contextInsight.connection}</strong> · horário: <strong>{contextInsight.period}</strong>.
          </p>
          <p className="lk-result__context-insight-line">{contextInsight.trendText}</p>
        </div>
        </section>

        {/* ── Diagnóstico da conexão (refator 2026-05) ────────────────────
            Antes era um bloco fixo: kicker + título + 1 ação imperativa
            (com card adicional opcional para DNS lento). Agora é um card
            com DOIS estados:

            (a) HEALTHY — quando não há items de diagnóstico. Layout centralizado:
                ícone check verde + título grande "Tudo certo com sua rede".
                Sem subcards.

            (b) COM AÇÃO — lista compacta `[problema] → [ação]` derivada
                do Rules Engine v1 (Phase 2b). Limita a 3 visíveis;
                "ver mais N" expande inline. Priorizado por severidade
                (fail > warn). Mantém a recomendação extra de DNS lento
                como item adicional.

            Glow por severidade (refator 2026-05): a cor do box-shadow do
            card reflete a severidade agregada — healthy → verde, warn →
            amarelo, fail → vermelho. A escolha vem de
            `aggregateDiagnosisSeverity(items)` mapeada via
            `SEVERITY_GLOW`; a cor é injetada como custom property
            `--diag-glow-color` lida pela animação CSS
            `lk-result-diag-glow`. */}
        {(() => {
          const items = diagnosisItems.items;
          const dnsGrade = classifyDnsLatency(result.dnsLatencyMs ?? null);
          const isSlowDns = dnsGrade === 'slow' || dnsGrade === 'poor';
          const isIspDns = result.dnsProvider === 'DNS do provedor';
          const hasDnsHint = isSlowDns && isIspDns;
          const isHealthy = items.length === 0;

          // Severidade agregada → cor do glow do card. A animação CSS
          // `lk-result-diag-glow` lê `--diag-glow-color` e pulsa em todos
          // os estados — só a cor diferencia healthy/warn/fail.
          const severity = aggregateDiagnosisSeverity(items);
          const glowStyle = {
            ['--diag-glow-color' as never]: SEVERITY_GLOW[severity],
          } as CSSProperties;

          if (isHealthy && !hasDnsHint) {
            return (
              <div
                className="lk-result__combined lk-result__combined--healthy"
                style={glowStyle}
              >
                <div className="lk-result__combined-check-icon" aria-hidden="true">
                  <Icon name="check-circle" size={48} color="var(--success)" />
                </div>
                <p className="lk-result__combined-healthy-title">
                  Tudo certo com sua rede
                </p>
              </div>
            );
          }

          return (
            <DiagnosticActionList
              items={items}
              dnsHint={hasDnsHint}
              fallbackTitle={combined.title}
              fallbackAction={combined.primaryAction}
              style={glowStyle}
            />
          );
        })()}

        {/* Contexto Wi-Fi via Atalho iOS (2026-05): exibe quando o teste
            foi precedido pelo Atalho Veloo WiFi Context. Fica entre o
            bloco de diagnóstico e a seção "Mais detalhes". */}
        {result.wifiContext && (
          <WifiContextCard ctx={result.wifiContext} />
        )}

        {/* ── Mais detalhes (refator drag-to-resize 2026-05) ─────────────
            Os 3 accordions inline (Avançado, Modo Gamer, DNS) viraram 3
            rows clicáveis no estilo "Ferramentas". Cada click abre uma
            bottom sheet dedicada (AdvancedSheet / GamerSheet /
            DNSGuideSheet) montada sobre `DraggableSheet` — drag-to-resize
            com snap entre 60vh e 88vh, pull-down threshold de 30% fecha. */}
        <section className="lk-result__more">
          <h2 className="lk-result__more-label">Mais detalhes</h2>
          <IOSList
            items={[
              {
                icon: <Icon name="cog" size={14} color="var(--text-2)" />,
                iconBg: 'var(--surface-3)',
                title: 'Avançado',
                subtitle: 'Métricas detalhadas, telemetria e histórico',
                showChevron: true,
                onClick: () => setActiveSheet('advanced'),
              },
              {
                icon: <Icon name="game" size={14} color="var(--text-2)" />,
                iconBg: 'var(--surface-3)',
                title: 'Modo Gamer',
                subtitle: 'Avaliação para FPS, MOBA, MMO e cloud gaming',
                showChevron: true,
                onClick: () => setActiveSheet('gamer'),
              },
              {
                icon: <Icon name="ping" size={14} color="var(--text-2)" />,
                iconBg: 'var(--surface-3)',
                title: 'Serviços de Internet',
                subtitle: 'DNS: provedor, resposta e como alterar',
                showChevron: true,
                onClick: () => setActiveSheet('dns'),
              },
              ...(onShowDiagnostico ? [{
                icon: <Icon name="shield" size={14} color="var(--accent)" />,
                iconBg: 'var(--accent-tint)',
                title: 'Diagnóstico com IA',
                subtitle: 'Análise detalhada por inteligência artificial',
                showChevron: true,
                onClick: onShowDiagnostico,
              }] : []),
            ]}
          />
        </section>

        <div className="lk-result__footer">
          <button className="btn-primary lk-result__retry" onClick={onRetry}>
            <Icon name="refresh" size={16} />Testar novamente
          </button>
          <div className="lk-result__share-card">
            <p className="lk-result__share-card-title">Compartilhamento rápido</p>
            <p className="lk-result__share-card-sub">
              Versão curta para celular e conversa de suporte.
            </p>
            <label className="lk-result__share-card-check">
              <input
                type="checkbox"
                checked={includeContextInShare}
                onChange={(e) => setIncludeContextInShare(e.target.checked)}
              />
              Incluir contexto adicional (conexão e servidor)
            </label>
            <div className="lk-result__footer-row">
              <button className="btn-text" onClick={handleWhatsApp} disabled={waGenerating}>
                {waGenerating ? 'Gerando…' : 'WhatsApp'}
              </button>
              <button className="btn-text" onClick={handleShareImage} disabled={imgGenerating}>
                {imgGenerating ? 'Gerando…' : 'Compartilhar imagem'}
              </button>
              <button className="btn-text" onClick={handleShare}>
                {shareStatus === 'copied' ? 'Copiado!' : 'Compartilhar texto'}
              </button>
            </div>
          </div>
          <div className="lk-result__share-card lk-result__share-card--technical">
            <p className="lk-result__share-card-title">Exportação técnica</p>
            <p className="lk-result__share-card-sub">
              Material para registro com aviso de evidência circunstancial.
            </p>
            <label className="lk-result__share-card-check">
              <input
                type="checkbox"
                checked={includeSensitiveInTechnical}
                onChange={(e) => setIncludeSensitiveInTechnical(e.target.checked)}
              />
              Incluir dados sensíveis (servidor/ISP)
            </label>
            <div className="lk-result__footer-row">
              <button className="btn-text" onClick={handleDownloadSupportSummary}>
                Baixar resumo suporte
              </button>
              <button className="btn-text" onClick={handleDownloadTechnicalRecord}>
                Baixar JSON técnico
              </button>
              <button className="btn-text" onClick={handleExportTechnicalPdf}>
                Exportar PDF
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Sheets de "Mais detalhes" (refator drag-to-resize 2026-05; lazy
          2026-05). As 3 são montadas fora do scroll-container porque são
          fixed/full-screen e precisam cobrir o TopBar. Cada uma é
          envolvida em Suspense + render condicional pra que o chunk só
          desça quando o usuário abrir a row correspondente. O cleanup
          interno do DraggableSheet (body scroll lock, Esc) acontece
          normalmente no unmount. */}
      {activeSheet === 'advanced' && (
        <Suspense fallback={null}>
          <AdvancedSheet
            open
            onClose={closeActiveSheet}
            result={result}
            server={server}
            unit={unit}
            history={history}
          />
        </Suspense>
      )}
      {activeSheet === 'gamer' && (
        <Suspense fallback={null}>
          <GamerSheet open onClose={closeActiveSheet} result={result} />
        </Suspense>
      )}
      {activeSheet === 'dns' && (
        <Suspense fallback={null}>
          <DNSGuideSheet open onClose={closeActiveSheet} result={result} />
        </Suspense>
      )}
    </div>
  );
}

// =============================================================================
// As bodies dos antigos 3 accordions (Avançado, Modo Gamer, DNS) foram
// migradas para sheets dedicadas (refator drag-to-resize 2026-05):
//   - Avançado  → src/features/result-detail/AdvancedSheet.tsx
//   - Modo Gamer → src/features/result-detail/GamerSheet.tsx
//   - DNS        → src/features/dns/DNSGuideSheet.tsx (já existia)
// =============================================================================





