import type { ReactNode } from 'react';
import { Icon } from '../icons';
import type { DeviceMock, WifiNetworkMock } from '../../mocks/linkaUiMock';
import './app-ui.css';

export function AppScaffold({ children }: { children: ReactNode }) {
  return <main className="lk-ui">{children}</main>;
}

export function AppHeader({
  title,
  subtitle,
  showBack = false,
  onBack,
  rightAction,
}: {
  title: string;
  subtitle?: string;
  showBack?: boolean;
  onBack?: () => void;
  rightAction?: ReactNode;
}) {
  return (
    <header className="lk-ui-header">
      <div className="lk-ui-header__row">
        {showBack ? (
          <button type="button" className="lk-ui-header__back" aria-label="Voltar" onClick={onBack}>
            <Icon name="chevron" size={14} color="var(--text-2)" />
          </button>
        ) : (
          <span className="lk-ui-header__slot" aria-hidden="true" />
        )}

        <div className="lk-ui-header__title-wrap">
          <h1 className="lk-ui-header__title">{title}</h1>
          {subtitle && <p className="lk-ui-header__sub">{subtitle}</p>}
        </div>

        <div className="lk-ui-header__action">
          {rightAction ?? <span className="lk-ui-header__slot" aria-hidden="true" />}
        </div>
      </div>
    </header>
  );
}

export function SectionTitle({ title, right, compact = false }: { title: string; right?: ReactNode; compact?: boolean }) {
  return (
    <div className={`lk-ui-section-title${compact ? ' lk-ui-section-title--compact' : ''}`}>
      <h2>{title}</h2>
      {right}
    </div>
  );
}

export function Badge({ text, tone = 'neutral', onClick }: { text: string; tone?: 'neutral' | 'success' | 'error' | 'warn' | 'info'; onClick?: () => void }) {
  if (onClick) {
    return (
      <button type="button" className={`lk-ui-badge lk-ui-badge--${tone}`} onClick={onClick}>
        {text}
      </button>
    );
  }
  return <span className={`lk-ui-badge lk-ui-badge--${tone}`}>{text}</span>;
}

export function MetricCard({ label, value, unit }: { label: string; value: string; unit?: string }) {
  return (
    <div className="lk-ui-metric">
      <p>{label}</p>
      <strong>{value}</strong>
      {unit && <span>{unit}</span>}
    </div>
  );
}

export function QuickActionCard({ icon, label, onClick }: { icon: string; label: string; onClick?: () => void }) {
  return (
    <button type="button" className="lk-ui-quick" onClick={onClick}>
      <span className="lk-ui-quick-icon"><Icon name={icon} size={14} color="var(--accent)" /></span>
      <span>{label}</span>
    </button>
  );
}

export function StatusCard({ children }: { children: ReactNode }) {
  return <section className="lk-ui-card">{children}</section>;
}

export function SettingsRow({ title, subtitle, icon, onClick }: { title: string; subtitle: string; icon: string; onClick?: () => void }) {
  return (
    <button className="lk-ui-row" type="button" onClick={onClick}>
      <span className="lk-ui-row-icon"><Icon name={icon} size={14} color="var(--text-2)" /></span>
      <span className="lk-ui-row-copy"><strong>{title}</strong><small>{subtitle}</small></span>
      <Icon name="chevron" size={13} color="var(--text-3)" />
    </button>
  );
}

export function DeviceRow({ device }: { device: DeviceMock }) {
  const iconMap: Record<DeviceMock['icon'], string> = {
    mobile: 'cellular', laptop: 'laptop', stream: 'stream', person: 'person', assistant: 'network', game: 'game', camera: 'sensors', printer: 'document',
  };
  return (
    <div className="lk-ui-device-row">
      <span className="lk-ui-device-icon"><Icon name={iconMap[device.icon]} size={14} color="var(--text-2)" /></span>
      <span className="lk-ui-device-copy"><strong>{device.name}</strong><small>{device.ip}</small></span>
      <span className={`lk-ui-status-dot ${device.status === 'Online' ? 'ok' : 'warn'}`} />
      <small className="lk-ui-device-status">{device.status}</small>
      <Icon name="wifi" size={13} color="var(--text-3)" />
    </div>
  );
}

export function WifiNetworkRow({ network }: { network: WifiNetworkMock }) {
  return (
    <div className="lk-ui-wifi-row">
      <span className="lk-ui-device-icon"><Icon name="wifi" size={14} color="var(--accent)" /></span>
      <span className="lk-ui-device-copy"><strong>{network.name}</strong><small>{network.details}</small></span>
      {network.connected && <Badge text="Conectado" tone="success" />}
      <Badge text={network.signalDbm} tone={network.signalDbm.includes('-4') ? 'success' : network.signalDbm.includes('-6') ? 'warn' : 'error'} />
      <Badge text={network.channel} tone="info" />
    </div>
  );
}

export function SpeedGauge({ value }: { value: number }) {
  const max = 1000;
  const pct = Math.min(value / max, 1);
  const progress = 251 * pct;
  return (
    <div className="lk-ui-gauge">
      <svg viewBox="0 0 220 130" className="lk-ui-gauge-svg" aria-hidden="true">
        <path d="M20 110 A90 90 0 0 1 200 110" className="lk-ui-gauge-track" />
        <path d="M20 110 A90 90 0 0 1 200 110" className="lk-ui-gauge-progress" style={{ strokeDasharray: `${progress} 251` }} />
      </svg>
      <div className="lk-ui-gauge-scale"><span>0</span><span>200</span><span>400</span><span>600</span><span>800</span><span>1000</span></div>
      <div className="lk-ui-gauge-copy"><strong>{value}</strong><span>Mbps</span><p>Download</p></div>
    </div>
  );
}

export function ChartCard({ percent, labels, values }: { percent: string; labels: string[]; values: number[] }) {
  const max = 100;
  const points = values
    .map((v, i) => `${(i / (values.length - 1)) * 100},${100 - ((v / max) * 100)}`)
    .join(' ');

  return (
    <section className="lk-ui-card lk-ui-chart-card">
      <h3>Tempo de atividade (uptime)</h3>
      <p className="lk-ui-big">{percent}</p>
      <small>Últimos 7 dias</small>
      <div className="lk-ui-chart-wrap">
        <div className="lk-ui-chart-y"><span>100%</span><span>75%</span><span>50%</span><span>25%</span><span>0%</span></div>
        <svg viewBox="0 0 100 100" className="lk-ui-chart" aria-hidden="true">
          <line x1="0" y1="0" x2="0" y2="100" className="lk-ui-axis" />
          <line x1="0" y1="100" x2="100" y2="100" className="lk-ui-axis" />
          <polyline fill="none" stroke="var(--accent)" strokeWidth="1.7" points={points} />
          <circle cx="83" cy="48" r="1.6" fill="var(--error)" />
        </svg>
      </div>
      <div className="lk-ui-legend"><span><i className="online" />Online</span><span><i className="offline" />Offline</span></div>
      <div className="lk-ui-labels">{labels.map((l) => <small key={l}>{l}</small>)}</div>
    </section>
  );
}
