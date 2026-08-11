import type { DeviceInfo, ServerInfo, TestRecord, ConnectionType } from '../types';
import type { Settings } from '../hooks/useSettings';
import { Icon } from '../components/icons';
import { Skeleton } from '../components/Skeleton';
import { AppScaffold, MetricCard, QuickActionCard, StatusCard } from '../components/ui/app-ui';

interface Props {
  theme: 'dark' | 'light';
  device: DeviceInfo | null;
  server: ServerInfo | null;
  loading: boolean;
  error: string | null;
  isOnline: boolean;
  settings: Settings;
  onRetry: () => void;
  lastRecord: TestRecord | null;
  onShowHistory: () => void;
  onNavigateToSpeedTest: () => void;
  onOpenOrbit?: () => void;
  onShowSinal?: () => void;
  onShowDevices?: () => void;
  onRefresh?: () => Promise<void>;
}

function humanizeConnectionType(ct: ConnectionType | undefined): string {
  switch (ct) {
    case 'wifi':    return 'Wi-Fi';
    case 'mobile':  return 'Dados móveis';
    case 'cable':   return 'Cabo';
    case 'unknown':
    default:        return 'Conexão desconhecida';
  }
}

function connectionIcon(ct: ConnectionType | undefined): string {
  switch (ct) {
    case 'wifi':   return 'wifi';
    case 'mobile': return 'cellular';
    default:       return 'network';
  }
}

function formatTime(timestamp: number): string {
  return new Date(timestamp).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
}

export function HomeScreen({
  device,
  server,
  loading,
  error,
  isOnline,
  settings,
  onRetry,
  lastRecord,
  onShowHistory,
  onNavigateToSpeedTest,
  onOpenOrbit,
  onShowSinal,
  onShowDevices,
}: Props) {
  const displayName = settings.userName.trim() || 'você';
  const avatarInitial = settings.userName.trim() ? settings.userName.trim().charAt(0).toUpperCase() : 'V';

  return (
    <AppScaffold>
      {/* Cabeçalho: avatar + saudação */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
        <div
          aria-hidden="true"
          style={{
            width: 36,
            height: 36,
            borderRadius: '50%',
            background: 'var(--accent)',
            fontWeight: 700,
            fontSize: 14,
            display: 'grid',
            placeItems: 'center',
            color: '#fff',
            flexShrink: 0,
          }}
        >
          {avatarInitial}
        </div>
        <div style={{ flex: 1 }}>
          <strong style={{ color: 'var(--text)', fontSize: 22, lineHeight: 1.15 }}>
            Olá, {displayName}
          </strong>
          <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 12 }}>
            {isOnline ? 'Tudo funcionando bem!' : 'Verifique sua conexão'}
          </p>
        </div>
      </div>

      {/* Card: estado de erro */}
      {error && !loading && (
        <StatusCard>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-start' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Icon name="info" size={18} color="var(--error)" />
              <strong style={{ color: 'var(--error)', fontSize: 14 }}>Erro ao carregar dados</strong>
            </div>
            <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 13 }}>{error}</p>
            <button
              type="button"
              onClick={onRetry}
              style={{
                marginTop: 4,
                background: 'var(--accent)',
                color: '#fff',
                border: 'none',
                borderRadius: 8,
                padding: '8px 16px',
                fontSize: 13,
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              Tentar novamente
            </button>
          </div>
        </StatusCard>
      )}

      {/* Card: status da conexão */}
      <StatusCard>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
          <strong style={{ color: 'var(--text)', fontSize: 16 }}>Status da conexão</strong>
          {loading ? (
            <Skeleton width={60} height={18} variant="pill" />
          ) : (
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 5,
                color: isOnline ? 'var(--success)' : 'var(--error)',
                fontWeight: 600,
                fontSize: 12,
              }}
            >
              <span
                style={{
                  width: 7,
                  height: 7,
                  borderRadius: '50%',
                  background: isOnline ? 'var(--success)' : 'var(--error)',
                  flexShrink: 0,
                }}
              />
              {isOnline ? 'Online' : 'Sem conexão'}
            </span>
          )}
        </div>

        {loading ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <Skeleton width="60%" height={20} variant="pill" />
            <Skeleton width="40%" height={14} variant="pill" />
          </div>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              {isOnline ? (
                <>
                  <h3 style={{ margin: 0, color: 'var(--text)', fontSize: 18, lineHeight: 1.1 }}>
                    {humanizeConnectionType(device?.connectionType)}
                  </h3>
                  <p style={{ margin: '2px 0 8px', color: 'var(--text-2)', fontSize: 12 }}>
                    {server?.isp ?? 'Operadora desconhecida'}
                  </p>
                </>
              ) : (
                <>
                  <h3 style={{ margin: 0, color: 'var(--error)', fontSize: 18, lineHeight: 1.1 }}>
                    Sem conexão
                  </h3>
                  <p style={{ margin: '2px 0 8px', color: 'var(--text-2)', fontSize: 12 }}>
                    Verifique seu Wi-Fi ou dados móveis
                  </p>
                </>
              )}
            </div>
            <Icon
              name={isOnline ? connectionIcon(device?.connectionType) : 'close'}
              size={34}
              color={isOnline ? 'var(--accent)' : 'var(--error)'}
            />
          </div>
        )}
      </StatusCard>

      {/* Card: último teste */}
      <StatusCard>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
          <strong style={{ color: 'var(--text)', fontSize: 16 }}>Último teste de velocidade</strong>
          {lastRecord && (
            <small style={{ color: 'var(--text-2)', fontSize: 11 }}>
              {formatTime(lastRecord.timestamp)}
            </small>
          )}
        </div>

        {loading ? (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
            <Skeleton height={60} />
            <Skeleton height={60} />
            <Skeleton height={60} />
          </div>
        ) : lastRecord ? (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
              <MetricCard
                label="Download"
                value={`${Math.round(lastRecord.dl)}`}
                unit="Mbps"
              />
              <MetricCard
                label="Upload"
                value={lastRecord.ulFailed ? '--' : `${lastRecord.ul.toFixed(1).replace('.', ',')}`}
                unit={lastRecord.ulFailed ? '' : 'Mbps'}
              />
              <MetricCard
                label="Ping"
                value={`${Math.round(lastRecord.latency)}`}
                unit="ms"
              />
            </div>
            <button
              type="button"
              onClick={onShowHistory}
              style={{
                marginTop: 8,
                background: 'none',
                border: 'none',
                padding: 0,
                color: 'var(--accent)',
                fontWeight: 600,
                fontSize: 12,
                display: 'inline-flex',
                alignItems: 'center',
                gap: 4,
                cursor: 'pointer',
              }}
            >
              Ver histórico
              <Icon name="chevron" size={12} color="var(--accent)" />
            </button>
          </>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, alignItems: 'flex-start' }}>
            <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 13 }}>
              Nenhum teste realizado. Faça seu primeiro teste!
            </p>
            <button
              type="button"
              onClick={onNavigateToSpeedTest}
              style={{
                background: 'var(--accent)',
                color: '#fff',
                border: 'none',
                borderRadius: 8,
                padding: '8px 16px',
                fontSize: 13,
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              Testar agora
            </button>
          </div>
        )}
      </StatusCard>

      {/* Card: ações rápidas */}
      <StatusCard>
        <strong style={{ color: 'var(--text)', fontSize: 16, display: 'block', marginBottom: 10 }}>
          Ações rápidas
        </strong>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,minmax(0,1fr))', gap: 8 }}>
          <QuickActionCard icon="analytics" label="Testar velocidade" onClick={onNavigateToSpeedTest} />
          <QuickActionCard icon="wifi" label="Analisar Wi-Fi" onClick={onShowSinal} />
          <QuickActionCard icon="network" label="Ver dispositivos" onClick={onShowDevices} />
          <QuickActionCard icon="shield" label="Diagnóstico inteligente" onClick={onOpenOrbit} />
        </div>
      </StatusCard>

      {/* Espaço pro BottomNavBar */}
      <div style={{ height: 80 }} aria-hidden="true" />
    </AppScaffold>
  );
}
