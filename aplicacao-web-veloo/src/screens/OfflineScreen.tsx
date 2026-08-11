import { Icon } from '../components/icons';
import './OfflineScreen.css';

interface OfflineScreenProps {
  onRetry: () => void;
  onOpenHistory: () => void;
}

export function OfflineScreen({ onRetry, onOpenHistory }: OfflineScreenProps) {
  return (
    <main className="lk-offline" role="main" aria-labelledby="offline-title">
      <div className="lk-offline__card">
        <div className="lk-offline__icon" aria-hidden="true">
          <Icon name="wifi" size={28} />
        </div>
        <h1 id="offline-title" className="lk-offline__title">Sem conexão com a internet</h1>
        <p className="lk-offline__text">
          O app continua funcionando, mas você está offline agora. Verifique sua rede e tente novamente.
        </p>
        <div className="lk-offline__actions">
          <button type="button" className="btn-primary" onClick={onRetry}>Tentar novamente</button>
          <button type="button" className="btn-text" onClick={onOpenHistory}>Abrir histórico offline</button>
        </div>
      </div>
    </main>
  );
}

