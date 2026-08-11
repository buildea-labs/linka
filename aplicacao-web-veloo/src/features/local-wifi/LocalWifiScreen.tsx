import { Icon } from '../../components/icons';
import { AppHeader, AppScaffold, Badge, SectionTitle, StatusCard, WifiNetworkRow } from '../../components/ui/app-ui';
import { wifiNetworks } from '../../mocks/linkaUiMock';

interface Props { onBack: () => void; onOpenDevices?: () => void; }

export function LocalWifiScreen({ onOpenDevices }: Props) {
  return (
    <AppScaffold>
      <AppHeader title="Sinal" rightAction={onOpenDevices ? (
        <button type="button" aria-label="Ver dispositivos" onClick={onOpenDevices} style={{ background: 'none', border: 'none', padding: 4, cursor: 'pointer', display: 'grid', placeItems: 'center' }}>
          <Icon name="devices" size={16} color="var(--text-2)" />
        </button>
      ) : undefined} />
      <StatusCard>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '9px 10px', borderRadius: 10, background: 'var(--error-tint)' }}>
          <Icon name="wifi" size={14} color="var(--error)" />
          <div style={{ flex: 1 }}><strong style={{ color: 'var(--error)', fontSize: 13 }}>Você está offline</strong><p style={{ margin: 0, color: 'var(--error)', fontSize: 11 }}>Sem conexão com a internet</p></div>
          <button type="button" aria-label="Tentar reconectar" onClick={() => window.location.reload()} style={{ background: 'none', border: 'none', padding: 4, cursor: 'pointer', display: 'grid', placeItems: 'center' }}>
            <Icon name="refresh" size={14} color="var(--error)" />
          </button>
        </div>
      </StatusCard>
      <SectionTitle title="Redes Wi-Fi próximas" compact right={
        <button type="button" aria-label="Atualizar lista de redes" onClick={() => alert('Atualizando redes...')} style={{ background: 'none', border: 'none', padding: 4, cursor: 'pointer', display: 'grid', placeItems: 'center' }}>
          <Icon name="refresh" size={14} color="var(--text-3)" />
        </button>
      } />
      {wifiNetworks.map((network) => <WifiNetworkRow key={network.name} network={network} />)}
      <StatusCard>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div><strong style={{ color: 'var(--text)', fontSize: 14 }}>Análise de canal</strong><p style={{ margin: '2px 0', color: 'var(--text-3)', fontSize: 11 }}>Melhor canal em 5 GHz</p></div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><Badge text="Canal 36" tone="info" /><Icon name="chevron" size={12} color="var(--text-3)" /></div>
        </div>
      </StatusCard>
    </AppScaffold>
  );
}
