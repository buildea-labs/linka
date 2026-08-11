/**
 * AiScreen — Análise de Conexão baseada em histórico local
 *
 * Não usa LLM nem APIs externas. Análise 100% local via regras sobre
 * TestRecord[] armazenados em localStorage.
 *
 * Vera confirmou: localStorage suficiente, sem APIs externas necessárias.
 * Requer mínimo 5 testes para exibir análise (MIN_RECORDS_FOR_ANALYSIS).
 */
import { useMemo } from 'react';
import { AppHeader, AppScaffold } from '../components/ui/app-ui';
import { Icon } from '../components/icons';
import { loadHistory } from '../utils/history';
import { buildHistoryInsights } from '../utils/historyInsights';
import { computeConnectionMetrics, MIN_RECORDS_FOR_ANALYSIS } from '../utils/connectionAnalysis';
import type { HistoryInsight } from '../utils/historyInsights';
import './AiScreen.css';

interface Props {
  onOpenSpeed?: () => void;
}

const SEVERITY_ICON: Record<HistoryInsight['severity'], string> = {
  info: 'shield',
  warning: 'loss',
  critical: 'loss',
};

const TREND_LABEL = {
  improving: 'Melhorando',
  degrading: 'Degradando',
  stable: 'Estável',
} as const;

const TREND_TONE = {
  improving: 'success',
  degrading: 'warn',
  stable: 'info',
} as const;

export function AiScreen({ onOpenSpeed }: Props) {
  const { records, insights, metrics } = useMemo(() => {
    const recs = loadHistory();
    const ins = buildHistoryInsights(recs);
    const met = computeConnectionMetrics(recs);
    return { records: recs, insights: ins, metrics: met };
  }, []);

  const hasEnoughData = records.length >= MIN_RECORDS_FOR_ANALYSIS;

  return (
    <AppScaffold>
      <AppHeader title="Análise de Conexão" />

      {!hasEnoughData ? (
        <EmptyState
          testCount={records.length}
          needed={MIN_RECORDS_FOR_ANALYSIS}
          onOpenSpeed={onOpenSpeed}
        />
      ) : (
        <>
          {metrics && <MetricsSummary metrics={metrics} />}
          <InsightsList insights={insights} />
          {insights.length === 0 && (
            <div className="ai-no-issues">
              <Icon name="shield" size={20} color="var(--accent)" />
              <p>Nenhum problema detectado nos dados recentes.</p>
            </div>
          )}
          <p className="ai-disclaimer">
            Análise baseada em {records.length} testes armazenados localmente. Os dados nunca saem do seu dispositivo.
          </p>
        </>
      )}
    </AppScaffold>
  );
}

/* ---------- Sub-componentes ---------- */

function EmptyState({
  testCount,
  needed,
  onOpenSpeed,
}: {
  testCount: number;
  needed: number;
  onOpenSpeed?: () => void;
}) {
  const remaining = needed - testCount;
  return (
    <div className="ai-empty">
      <div className="ai-empty__icon">
        <Icon name="sensors" size={32} color="var(--text-3)" />
      </div>
      <h2 className="ai-empty__title">Dados insuficientes</h2>
      <p className="ai-empty__body">
        {testCount === 0
          ? 'Realize pelo menos 5 testes de velocidade para ver a análise da sua conexão.'
          : `Faltam ${remaining} teste${remaining > 1 ? 's' : ''} para ativar a análise. Você já tem ${testCount}.`}
      </p>
      <button type="button" className="ai-empty__btn" onClick={onOpenSpeed}>
        Fazer teste agora
      </button>
    </div>
  );
}

function MetricsSummary({ metrics }: { metrics: NonNullable<ReturnType<typeof computeConnectionMetrics>> }) {
  const trendTone = TREND_TONE[metrics.trend];
  return (
    <section className="ai-metrics">
      <h2 className="ai-section-title">Resumo</h2>
      <div className="ai-metrics__grid">
        <MetricCell label="Download médio" value={`${metrics.avgDownload} Mbps`} />
        <MetricCell label="Latência média" value={`${metrics.avgLatency} ms`} />
        <MetricCell label="Jitter médio" value={`${metrics.avgJitter} ms`} />
        <MetricCell label="Variação download" value={`±${metrics.stdDevDownload} Mbps`} />
        <MetricCell label="Perda de pacotes" value={`${metrics.lossRatePct}%`} />
        <MetricCell
          label="Tendência"
          value={TREND_LABEL[metrics.trend]}
          tone={trendTone}
        />
      </div>
      <StabilityBar score={metrics.stabilityScore} />
      {metrics.bestHour && metrics.worstHour && (
        <div className="ai-hours">
          <span className="ai-hours__best">
            <Icon name="shield" size={12} color="var(--success, var(--accent))" />
            Melhor horário: <strong>{metrics.bestHour}</strong>
          </span>
          <span className="ai-hours__worst">
            <Icon name="loss" size={12} color="var(--error)" />
            Pior horário: <strong>{metrics.worstHour}</strong>
          </span>
        </div>
      )}
    </section>
  );
}

function MetricCell({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div className={`ai-metric-cell${tone ? ` ai-metric-cell--${tone}` : ''}`}>
      <span className="ai-metric-cell__label">{label}</span>
      <strong className="ai-metric-cell__value">{value}</strong>
    </div>
  );
}

function StabilityBar({ score }: { score: number }) {
  const tone = score >= 70 ? 'success' : score >= 40 ? 'warn' : 'error';
  const label = score >= 70 ? 'Boa estabilidade' : score >= 40 ? 'Estabilidade moderada' : 'Baixa estabilidade';
  return (
    <div className="ai-stability">
      <div className="ai-stability__header">
        <span className="ai-stability__label">Índice de estabilidade</span>
        <span className={`ai-stability__score ai-stability__score--${tone}`}>{score}/100</span>
      </div>
      <div className="ai-stability__track">
        <div
          className={`ai-stability__bar ai-stability__bar--${tone}`}
          style={{ width: `${score}%` }}
        />
      </div>
      <span className="ai-stability__desc">{label}</span>
    </div>
  );
}

function InsightsList({ insights }: { insights: HistoryInsight[] }) {
  if (insights.length === 0) return null;
  return (
    <section className="ai-insights">
      <h2 className="ai-section-title">Insights</h2>
      {insights.map((insight) => (
        <InsightCard key={insight.id} insight={insight} />
      ))}
    </section>
  );
}

function InsightCard({ insight }: { insight: HistoryInsight }) {
  const iconName = SEVERITY_ICON[insight.severity];
  const iconColor =
    insight.severity === 'critical' ? 'var(--error)' :
    insight.severity === 'warning' ? 'var(--warn, var(--accent))' :
    'var(--accent)';

  return (
    <div className={`ai-insight-card ai-insight-card--${insight.severity}`}>
      <span className="ai-insight-card__icon">
        <Icon name={iconName} size={16} color={iconColor} />
      </span>
      <div className="ai-insight-card__body">
        <strong className="ai-insight-card__title">{insight.title}</strong>
        <p className="ai-insight-card__desc">{insight.description}</p>
      </div>
    </div>
  );
}
