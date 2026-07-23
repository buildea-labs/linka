import { useState } from 'react';
import type { DeviceInfo, ServerInfo, TestRecord } from '../types';
import type { Settings } from '../hooks/useSettings';
import { Icon } from '../components/icons';
import { AppHeader, Badge, QuickActionCard, SectionTitle, StatusCard, AppScaffold } from '../components/ui/app-ui';
import { usePingTool, type PingQuality } from '../hooks/usePingTool';
import { useDnsLookupTool } from '../hooks/useDnsLookupTool';

interface Props {
  theme: 'dark' | 'light';
  onStart: (mode: 'fast' | 'complete') => void;
  onOpenDiagnostico: () => void;
  lastRecord: TestRecord | null;
  device: DeviceInfo | null;
  server: ServerInfo | null;
  settings: Settings;
  onUpdateSettings: (patch: Partial<Settings>) => void;
  cancelledNotice?: boolean;
  onDismissCancelledNotice?: () => void;
}

type ActiveTool = 'ping' | 'dns' | 'traceroute' | 'portscan' | null;

/* ── Helpers de classificação de ping ── */

const PING_QUALITY_LABEL: Record<PingQuality, string> = {
  excellent: 'Excelente',
  good: 'Bom',
  acceptable: 'Aceitável',
  poor: 'Ruim',
  timeout: 'Sem resposta',
};

const PING_QUALITY_TONE: Record<PingQuality, 'success' | 'info' | 'warn' | 'error' | 'neutral'> = {
  excellent: 'success',
  good: 'success',
  acceptable: 'warn',
  poor: 'error',
  timeout: 'neutral',
};

/* ── Componente principal ── */

function formatTime(timestamp: number): string {
  return new Date(timestamp).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
}

function MetricCard({ label, value, unit }: { label: string; value: string; unit: string }) {
  return (
    <div style={{
      background: 'var(--surface-2, var(--surface))',
      border: '1px solid var(--border)',
      borderRadius: 10,
      padding: '10px 8px',
      textAlign: 'center',
    }}>
      <p style={{ margin: '0 0 2px', fontSize: 11, color: 'var(--text-3)' }}>{label}</p>
      <strong style={{ fontSize: 18, color: 'var(--text)', fontFamily: 'var(--font-display)', display: 'block' }}>{value}</strong>
      {unit ? <span style={{ fontSize: 10, color: 'var(--text-3)' }}>{unit}</span> : null}
    </div>
  );
}

export function SpeedTestScreen({ onStart, lastRecord, cancelledNotice, onDismissCancelledNotice }: Props) {
  const [activeTool, setActiveTool] = useState<ActiveTool>(null);

  const ping = usePingTool();
  const dns = useDnsLookupTool();
  const [dnsInput, setDnsInput] = useState('');

  function openTool(tool: ActiveTool) {
    setActiveTool(tool);
    if (tool === 'ping') ping.reset();
    if (tool === 'dns') dns.reset();
  }

  function closeTool() {
    setActiveTool(null);
  }

  return (
    <AppScaffold>
      <AppHeader
        title="Teste de velocidade"
        rightAction={
          <button type="button" onClick={() => alert('Em breve: Informações sobre o teste')} aria-label="Informações" style={{ background: 'transparent', border: 'none', padding: 4 }}>
            <Icon name="info" size={16} color="#475569" />
          </button>
        }
      />

      {cancelledNotice && (
        <StatusCard>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--warn)', fontSize: 13 }}>Teste cancelado.</span>
            <button type="button" onClick={onDismissCancelledNotice} style={{ color: 'var(--text-3)', fontSize: 12, background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}>
              Fechar
            </button>
          </div>
        </StatusCard>
      )}

      <StatusCard>
        <button
          type="button"
          onClick={() => onStart('complete')}
          className="btn-primary"
          style={{ width: '100%', height: 52, fontSize: 16 }}
        >
          Testar velocidade
        </button>
        <button
          type="button"
          onClick={() => onStart('fast')}
          className="btn-text"
          style={{ width: '100%', marginTop: 8, fontSize: 13 }}
        >
          Modo rápido
        </button>
      </StatusCard>

      {lastRecord && (
        <StatusCard>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <strong style={{ fontSize: 15, color: 'var(--text)' }}>Último teste</strong>
            <small style={{ color: 'var(--text-3)', fontSize: 11 }}>
              {formatTime(lastRecord.timestamp)}
              {lastRecord.serverName ? ` · ${lastRecord.serverName}` : ''}
            </small>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
            <MetricCard label="Download" value={`${Math.round(lastRecord.dl)}`} unit="Mbps" />
            <MetricCard label="Upload" value={lastRecord.ulFailed ? '--' : `${lastRecord.ul.toFixed(1).replace('.', ',')}`} unit={lastRecord.ulFailed ? '' : 'Mbps'} />
            <MetricCard label="Ping" value={`${Math.round(lastRecord.latency)}`} unit="ms" />
          </div>
        </StatusCard>
      )}

      <SectionTitle title="Ferramentas" compact />
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 8, marginBottom: 12 }}>
        <QuickActionCard icon="ping" label="Ping" onClick={() => openTool('ping')} />
        <QuickActionCard icon="cmp" label="Traceroute" onClick={() => openTool('traceroute')} />
        <QuickActionCard icon="globe" label="DNS Lookup" onClick={() => openTool('dns')} />
        <QuickActionCard icon="network" label="Port Scan" onClick={() => openTool('portscan')} />
      </div>

      {/* ── Modais de ferramentas ── */}

      {activeTool !== null && (
        <>
          <div className="st-sheet-overlay" onClick={closeTool} role="presentation" />
          <div className="st-sheet" role="dialog" aria-modal="true">
            <div className="st-sheet-handle" />

            {activeTool === 'ping' && (
              <PingSheet
                state={ping.state}
                onRun={ping.run}
                onClose={closeTool}
              />
            )}

            {activeTool === 'dns' && (
              <DnsSheet
                state={dns.state}
                input={dnsInput}
                onInputChange={setDnsInput}
                onLookup={() => dns.lookup(dnsInput)}
                onClose={closeTool}
              />
            )}

            {activeTool === 'traceroute' && (
              <PwaLimitationSheet
                title="Traceroute"
                reason="O Traceroute requer controle de TTL em pacotes ICMP, que não está disponível no browser por razões de segurança."
                onClose={closeTool}
              />
            )}

            {activeTool === 'portscan' && (
              <PwaLimitationSheet
                title="Port Scan"
                reason="A varredura de portas requer abertura de raw sockets TCP, que o browser bloqueia por design de segurança."
                onClose={closeTool}
              />
            )}

            <div className="st-sheet-safe" />
          </div>
        </>
      )}
    </AppScaffold>
  );
}

/* ── Sheet: Ping ── */

import type { PingToolState } from '../hooks/usePingTool';

function PingSheet({
  state,
  onRun,
  onClose,
}: {
  state: PingToolState;
  onRun: () => void;
  onClose: () => void;
}) {
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
        <p className="st-sheet-title" style={{ margin: 0 }}>Ping (Latência HTTP)</p>
        <button type="button" onClick={onClose} aria-label="Fechar" className="st-icon-btn">
          <Icon name="close" size={16} color="var(--text-3)" />
        </button>
      </div>

      <p className="st-sheet-body">
        Mede o tempo de resposta até o servidor Cloudflare via requisição HTTP.
        Inclui DNS + TCP + TLS — é uma aproximação da latência percebida pelo navegador, não um ICMP ping nativo.
      </p>

      {state.status === 'idle' && (
        <button
          type="button"
          className="st-mode-btn st-mode-btn--active"
          style={{ width: '100%', borderRadius: 12, padding: '12px 0', marginBottom: 12 }}
          onClick={onRun}
        >
          Executar
        </button>
      )}

      {state.status === 'loading' && (
        <div style={{ textAlign: 'center', padding: '16px 0', color: 'var(--text-2)', fontSize: 14 }}>
          Medindo... {state.progress}/{state.total}
        </div>
      )}

      {state.status === 'result' && (
        <>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <span style={{ fontSize: 36, fontWeight: 700, color: 'var(--text)', fontFamily: 'var(--font-display)' }}>
              {state.data.quality === 'timeout' ? '--' : `${state.data.medianMs}`}
            </span>
            <span style={{ color: 'var(--text-2)', fontSize: 14 }}>ms</span>
            <Badge
              text={PING_QUALITY_LABEL[state.data.quality]}
              tone={PING_QUALITY_TONE[state.data.quality]}
            />
          </div>

          {state.data.quality !== 'timeout' && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8, marginBottom: 16 }}>
              <MetricCell label="Min" value={`${state.data.minMs} ms`} />
              <MetricCell label="Max" value={`${state.data.maxMs} ms`} />
              <MetricCell label="Jitter" value={`${state.data.jitterMs} ms`} />
            </div>
          )}

          <button
            type="button"
            className="st-mode-btn st-mode-btn--active"
            style={{ width: '100%', borderRadius: 12, padding: '12px 0', marginBottom: 12 }}
            onClick={onRun}
          >
            Repetir
          </button>
        </>
      )}

      {state.status === 'error' && (
        <>
          <p style={{ color: 'var(--error)', fontSize: 13, marginBottom: 12 }}>{state.message}</p>
          <button
            type="button"
            className="st-mode-btn st-mode-btn--active"
            style={{ width: '100%', borderRadius: 12, padding: '12px 0', marginBottom: 12 }}
            onClick={onRun}
          >
            Tentar novamente
          </button>
        </>
      )}
    </>
  );
}

/* ── Sheet: DNS Lookup ── */

import type { DnsLookupToolState } from '../hooks/useDnsLookupTool';

function DnsSheet({
  state,
  input,
  onInputChange,
  onLookup,
  onClose,
}: {
  state: DnsLookupToolState;
  input: string;
  onInputChange: (v: string) => void;
  onLookup: () => void;
  onClose: () => void;
}) {
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
        <p className="st-sheet-title" style={{ margin: 0 }}>DNS Lookup</p>
        <button type="button" onClick={onClose} aria-label="Fechar" className="st-icon-btn">
          <Icon name="close" size={16} color="var(--text-3)" />
        </button>
      </div>

      <p className="st-sheet-body">
        Resolve endereços IP de um domínio via DNS-over-HTTPS (Cloudflare). Os IPs são retornados pelo resolver Cloudflare — podem diferir dos IPs que seu resolver local retornaria.
      </p>

      <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        <input
          type="text"
          value={input}
          onChange={(e) => onInputChange(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') onLookup(); }}
          placeholder="ex: google.com"
          style={{
            flex: 1,
            padding: '10px 12px',
            borderRadius: 10,
            border: '1px solid var(--border)',
            background: 'var(--surface-2, var(--surface))',
            color: 'var(--text)',
            fontSize: 14,
            fontFamily: 'var(--font-body)',
            outline: 'none',
          }}
          aria-label="Domínio para consulta DNS"
          disabled={state.status === 'loading'}
        />
        <button
          type="button"
          className="st-mode-btn st-mode-btn--active"
          style={{ borderRadius: 10, padding: '10px 16px', whiteSpace: 'nowrap' }}
          onClick={onLookup}
          disabled={state.status === 'loading' || !input.trim()}
        >
          {state.status === 'loading' ? 'Consultando...' : 'Resolver'}
        </button>
      </div>

      {state.status === 'result' && (
        <>
          <p style={{ fontSize: 12, color: 'var(--text-3)', marginBottom: 8 }}>
            {state.data.records.length} registro{state.data.records.length !== 1 ? 's' : ''} A · {state.data.latencyMs} ms via DoH
          </p>
          {state.data.records.map((r) => (
            <div
              key={r.ip}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '8px 12px',
                background: 'var(--surface-2, var(--surface))',
                borderRadius: 8,
                marginBottom: 6,
                border: '1px solid var(--border)',
              }}
            >
              <span style={{ fontFamily: 'monospace', fontSize: 14, color: 'var(--text)' }}>{r.ip}</span>
              <span style={{ fontSize: 11, color: 'var(--text-3)' }}>TTL {r.ttl}s</span>
            </div>
          ))}
        </>
      )}

      {state.status === 'error' && (
        <p style={{ color: 'var(--error)', fontSize: 13 }}>{state.message}</p>
      )}
    </>
  );
}

/* ── Sheet: Limitação PWA ── */

function PwaLimitationSheet({ title, reason, onClose }: { title: string; reason: string; onClose: () => void }) {
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
        <p className="st-sheet-title" style={{ margin: 0 }}>{title}</p>
        <button type="button" onClick={onClose} aria-label="Fechar" className="st-icon-btn">
          <Icon name="close" size={16} color="var(--text-3)" />
        </button>
      </div>

      <div style={{ display: 'flex', gap: 12, padding: '12px 0', alignItems: 'flex-start' }}>
        <Icon name="info" size={20} color="var(--warn, #FBBF24)" />
        <div>
          <p style={{ margin: '0 0 6px', fontSize: 14, fontWeight: 600, color: 'var(--text)' }}>
            Não disponível no browser
          </p>
          <p style={{ margin: 0, fontSize: 13, color: 'var(--text-2)', lineHeight: 1.5 }}>
            {reason}
          </p>
          <p style={{ margin: '8px 0 0', fontSize: 12, color: 'var(--text-3)', lineHeight: 1.4 }}>
            Esta funcionalidade estará disponível no aplicativo nativo Veloo, que tem acesso direto às interfaces de rede do dispositivo.
          </p>
        </div>
      </div>
    </>
  );
}

/* ── Componente auxiliar ── */

function MetricCell({ label, value }: { label: string; value: string }) {
  return (
    <div style={{
      background: 'var(--surface-2, var(--surface))',
      border: '1px solid var(--border)',
      borderRadius: 10,
      padding: '8px 10px',
      textAlign: 'center',
    }}>
      <p style={{ margin: '0 0 2px', fontSize: 11, color: 'var(--text-3)' }}>{label}</p>
      <strong style={{ fontSize: 13, color: 'var(--text)', fontFamily: 'var(--font-display)' }}>{value}</strong>
    </div>
  );
}
