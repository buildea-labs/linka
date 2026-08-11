import { useState } from 'react';
import { AppHeader, AppScaffold, Badge, StatusCard } from '../components/ui/app-ui';
import { Icon } from '../components/icons';
import { useHistory, PERIOD_LABELS, type HistoryPeriod } from '../hooks/useHistory';
import { formatRelativeTime } from '../utils/relativeTime';
import type { TestRecord } from '../types';

interface Props {
  theme: 'dark' | 'light';
  unit?: 'mbps' | 'gbps';
  initialSelectedId?: string;
  onBack?: () => void;
  onRefresh?: () => Promise<void>;
}

export function HistoryScreen({ unit = 'mbps' }: Props) {
  const { state, setPeriod, refresh } = useHistory();
  const [showReport, setShowReport] = useState(false);

  const periods: HistoryPeriod[] = ['7d', '30d', '90d', 'all'];

  function handleRefreshClick() {
    refresh();
  }

  // ── Estado vazio ──
  if (state.isEmpty) {
    return (
      <AppScaffold>
        <AppHeader
          title="Histórico"
          rightAction={
            <button type="button" onClick={handleRefreshClick} aria-label="Atualizar" style={{ background: 'transparent', border: 'none', padding: 4 }}>
              <Icon name="refresh" size={16} color="var(--text-3)" />
            </button>
          }
        />
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px 24px', textAlign: 'center', gap: 12 }}>
          <Icon name="history" size={40} color="var(--text-3)" />
          <p style={{ margin: 0, fontSize: 16, fontWeight: 600, color: 'var(--text)' }}>Nenhum teste ainda</p>
          <p style={{ margin: 0, fontSize: 13, color: 'var(--text-2)', lineHeight: 1.5 }}>
            Execute um teste de velocidade para ver seu histórico aqui.
          </p>
        </div>
      </AppScaffold>
    );
  }

  // ── Vista de relatório completo (lista detalhada) ──
  if (showReport) {
    return (
      <AppScaffold>
        <AppHeader
          title="Relatório completo"
          showBack
          onBack={() => setShowReport(false)}
        />
        <RecordList records={state.filtered} unit={unit} />
      </AppScaffold>
    );
  }

  // ── Vista principal do histórico ──
  return (
    <AppScaffold>
      <AppHeader
        title="Histórico"
        rightAction={
          <button type="button" onClick={handleRefreshClick} aria-label="Atualizar" style={{ background: 'transparent', border: 'none', padding: 4 }}>
            <Icon name="refresh" size={16} color="var(--text-3)" />
          </button>
        }
      />

      {/* Filtros de período */}
      <div style={{ display: 'flex', gap: 6, marginBottom: 10, flexWrap: 'wrap' }}>
        {periods.map((p) => (
          <Badge
            key={p}
            text={PERIOD_LABELS[p]}
            tone={state.period === p ? 'info' : 'neutral'}
            onClick={() => setPeriod(p)}
          />
        ))}
      </div>

      {/* Gráfico de velocidade */}
      <SpeedChart records={state.filtered} unit={unit} />

      {/* Resumo e acesso ao relatório */}
      <StatusCard>
        <h3 style={{ marginTop: 0, marginBottom: 10, color: 'var(--text)', fontSize: 16 }}>Resumo</h3>
        <SummaryContent records={state.filtered} period={state.period} />
        <button
          type="button"
          style={{ color: 'var(--accent)', fontWeight: 600, fontSize: 12, display: 'inline-flex', alignItems: 'center', gap: 4, marginTop: 8 }}
          onClick={() => setShowReport(true)}
        >
          Ver relatório completo
          <Icon name="chevron" size={12} color="var(--accent)" />
        </button>
      </StatusCard>
    </AppScaffold>
  );
}

/* ── Gráfico de velocidade com dados reais ── */

function SpeedChart({ records, unit }: { records: TestRecord[]; unit: 'mbps' | 'gbps' }) {
  if (records.length < 2) {
    return (
      <StatusCard>
        <p style={{ margin: 0, fontSize: 13, color: 'var(--text-2)', textAlign: 'center' }}>
          Poucos registros para exibir gráfico. Execute mais testes para ver a tendência.
        </p>
      </StatusCard>
    );
  }

  // Até 10 pontos mais recentes, ordem cronológica
  const points = records.slice(0, 10).reverse();
  const dlValues = points.map((r) => (unit === 'gbps' ? r.dl / 1000 : r.dl));
  const ulValues = points.map((r) => (unit === 'gbps' ? r.ul / 1000 : r.ul));
  const maxVal = Math.max(...dlValues, ...ulValues, 1);

  const toSvgY = (v: number) => 100 - (v / maxVal) * 90; // 10% padding top
  const toSvgX = (i: number) => points.length === 1 ? 50 : (i / (points.length - 1)) * 100;

  const dlPolyline = points
    .map((_, i) => `${toSvgX(i)},${toSvgY(dlValues[i])}`)
    .join(' ');
  const ulPolyline = points
    .map((_, i) => `${toSvgX(i)},${toSvgY(ulValues[i])}`)
    .join(' ');

  const avgDl = dlValues.reduce((s, v) => s + v, 0) / dlValues.length;
  const unitLabel = unit === 'gbps' ? 'Gbps' : 'Mbps';

  const labels = points.map((r) => {
    const d = new Date(r.timestamp);
    return `${d.getDate()}/${d.getMonth() + 1}`;
  });

  return (
    <section className="lk-ui-card" style={{ marginBottom: 12 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
        <h3 style={{ margin: 0, fontSize: 14, color: 'var(--text)' }}>Velocidade</h3>
        <span style={{ fontSize: 20, fontWeight: 700, color: 'var(--accent)', fontFamily: 'var(--font-display)' }}>
          {avgDl.toFixed(avgDl < 10 ? 1 : 0)} <span style={{ fontSize: 12, fontWeight: 400, color: 'var(--text-2)' }}>{unitLabel} média DL</span>
        </span>
      </div>

      <svg viewBox="0 0 100 100" style={{ width: '100%', height: 80, display: 'block' }} aria-hidden="true">
        {/* Linhas de grade */}
        {[25, 50, 75].map((y) => (
          <line key={y} x1="0" y1={y} x2="100" y2={y} stroke="var(--border)" strokeWidth="0.4" strokeDasharray="2,2" />
        ))}
        {/* Download */}
        <polyline fill="none" stroke="var(--accent)" strokeWidth="1.8" strokeLinejoin="round" points={dlPolyline} />
        {/* Upload */}
        <polyline fill="none" stroke="var(--error)" strokeWidth="1.4" strokeLinejoin="round" strokeDasharray="3,2" points={ulPolyline} />
      </svg>

      <div style={{ display: 'flex', gap: 12, marginTop: 6 }}>
        <LegendDot color="var(--accent)" label="Download" />
        <LegendDot color="var(--ul)" label="Upload" dashed />
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
        {labels.map((l) => (
          <small key={l} style={{ fontSize: 9, color: 'var(--text-3)' }}>{l}</small>
        ))}
      </div>
    </section>
  );
}

function LegendDot({ color, label, dashed }: { color: string; label: string; dashed?: boolean }) {
  return (
    <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-2)' }}>
      <span style={{
        width: 16,
        height: 2,
        background: dashed ? 'none' : color,
        borderTop: dashed ? `2px dashed ${color}` : 'none',
        borderRadius: 2,
        display: 'inline-block',
      }} />
      {label}
    </span>
  );
}

/* ── Conteúdo de resumo dinâmico ── */

function SummaryContent({ records, period }: { records: TestRecord[]; period: HistoryPeriod }) {
  if (records.length === 0) {
    const periodLabel = PERIOD_LABELS[period].toLowerCase();
    return (
      <p style={{ margin: 0, fontSize: 13, color: 'var(--text-2)' }}>
        Nenhum teste nos últimos {periodLabel}. Selecione um período maior ou execute um novo teste.
      </p>
    );
  }

  const avgDl = records.reduce((s, r) => s + r.dl, 0) / records.length;
  const avgLat = records.reduce((s, r) => s + r.latency, 0) / records.length;
  const minDl = Math.min(...records.map((r) => r.dl));

  const isStable = minDl >= avgDl * 0.6; // queda máxima de 40%
  const icon = isStable ? 'security' : 'shield';
  const iconColor = isStable ? 'var(--success)' : 'var(--warn)';

  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <Icon name={icon} size={18} color={iconColor} />
      <div>
        <strong style={{ color: 'var(--text)', fontSize: 14 }}>
          {isStable ? 'Sua rede está estável.' : 'Variação detectada na rede.'}
        </strong>
        <p style={{ margin: '5px 0 0', color: 'var(--text-2)', fontSize: 11, lineHeight: 1.45 }}>
          Média de download: {Math.round(avgDl)} Mbps · Latência média: {Math.round(avgLat)} ms · {records.length} teste{records.length !== 1 ? 's' : ''} no período.
        </p>
      </div>
    </div>
  );
}

/* ── Lista detalhada para relatório completo ── */

function RecordList({ records, unit }: { records: TestRecord[]; unit: 'mbps' | 'gbps' }) {
  const unitLabel = unit === 'gbps' ? 'Gbps' : 'Mbps';
  const divisor = unit === 'gbps' ? 1000 : 1;

  if (records.length === 0) {
    return (
      <div style={{ padding: '40px 16px', textAlign: 'center', color: 'var(--text-2)', fontSize: 13 }}>
        Nenhum registro no período selecionado.
      </div>
    );
  }

  return (
    <div>
      {records.map((r) => (
        <div
          key={r.id}
          style={{
            background: 'var(--surface)',
            border: '1px solid var(--border)',
            borderRadius: 12,
            padding: '12px 14px',
            marginBottom: 8,
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
            <span style={{ fontSize: 12, color: 'var(--text-3)' }}>{formatRelativeTime(r.timestamp)}</span>
            <span style={{ fontSize: 11, color: 'var(--text-3)' }}>{r.serverName}</span>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
            <Metric label="Download" value={`${(r.dl / divisor).toFixed(r.dl / divisor < 10 ? 1 : 0)}`} unit={unitLabel} color="var(--accent)" />
            <Metric label="Upload" value={`${(r.ul / divisor).toFixed(r.ul / divisor < 10 ? 1 : 0)}`} unit={unitLabel} color="var(--ul)" />
            <Metric label="Ping" value={`${Math.round(r.latency)}`} unit="ms" color="var(--text-2)" />
          </div>
        </div>
      ))}
    </div>
  );
}

function Metric({ label, value, unit, color }: { label: string; value: string; unit: string; color: string }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <p style={{ margin: '0 0 2px', fontSize: 10, color: 'var(--text-3)' }}>{label}</p>
      <strong style={{ fontSize: 14, color, fontFamily: 'var(--font-display)' }}>{value}</strong>
      <span style={{ fontSize: 10, color: 'var(--text-3)', marginLeft: 2 }}>{unit}</span>
    </div>
  );
}
