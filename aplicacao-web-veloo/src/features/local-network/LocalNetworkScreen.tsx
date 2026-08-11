import { AppHeader, AppScaffold, DeviceRow } from '../../components/ui/app-ui';
import { connectedDevices } from '../../mocks/linkaUiMock';
import { Icon } from '../../components/icons';

interface Props { onBack: () => void; }

export function LocalNetworkScreen({ onBack }: Props) {
  return (
    <AppScaffold>
      <AppHeader
        title="Dispositivos conectados"
        subtitle="8 dispositivos no total"
        showBack
        onBack={onBack}
        rightAction={
          <button type="button" aria-label="Comparar dispositivos" onClick={() => alert('Comparar dispositivos — em breve')} style={{ background: 'none', border: 'none', padding: 4, cursor: 'pointer', display: 'grid', placeItems: 'center' }}>
            <Icon name="cmp" size={14} color="var(--text-3)" />
          </button>
        }
      />
      {connectedDevices.map((device) => <DeviceRow key={device.ip} device={device} />)}
    </AppScaffold>
  );
}
