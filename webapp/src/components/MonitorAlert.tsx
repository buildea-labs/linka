/**
 * MonitorAlert — Banner de alerta in-app para monitoramento contínuo
 *
 * Exibido apenas quando status é 'warn' ou 'error'.
 * Usa tokens CSS do design system — sem hexcodes.
 */
import type { MonitorAlert as MonitorAlertData } from '../hooks/useMonitor';
import { Icon } from './icons';
import './MonitorAlert.css';

interface Props {
  alert: MonitorAlertData;
  onDismiss: () => void;
}

export function MonitorAlert({ alert, onDismiss }: Props) {
  if (alert.status !== 'warn' && alert.status !== 'error' && alert.status !== 'offline') {
    return null;
  }

  const tone = alert.status === 'error' || alert.status === 'offline' ? 'error' : 'warn';
  const icon = alert.status === 'offline' ? 'loss' : 'sensors';

  return (
    <div className={`monitor-alert monitor-alert--${tone}`} role="alert" aria-live="polite">
      <span className="monitor-alert__icon">
        <Icon name={icon} size={14} color={tone === 'error' ? 'var(--error)' : 'var(--warn)'} />
      </span>
      <span className="monitor-alert__message">
        {alert.message}
        {alert.latencyMs !== null && alert.status !== 'offline' && (
          <span className="monitor-alert__latency"> ({alert.latencyMs} ms)</span>
        )}
      </span>
      <button
        type="button"
        className="monitor-alert__dismiss"
        aria-label="Fechar alerta"
        onClick={onDismiss}
      >
        <Icon name="close" size={12} color="var(--text-2)" />
      </button>
    </div>
  );
}
