import { useState } from 'react';
import { AppHeader, AppScaffold, SettingsRow } from '../components/ui/app-ui';
import type { Settings } from '../hooks/useSettings';
import './SettingsScreen.css';

interface Props {
  theme: 'dark' | 'light';
  onToggleTheme: () => void;
  settings: Settings;
  onUpdateSettings: (patch: Partial<Settings>) => void;
  onShowHistory?: () => void;
  onResetOnboarding?: () => void;
  onShowFibra?: () => void;
}

interface EditProfileState {
  userName: string;
  providerName: string;
}

const INTERVAL_OPTIONS: { value: Settings['checkInterval']; label: string }[] = [
  { value: 1, label: '1 minuto' },
  { value: 5, label: '5 minutos' },
  { value: 10, label: '10 minutos' },
  { value: 30, label: '30 minutos' },
];

export function SettingsScreen({
  theme,
  onToggleTheme,
  settings,
  onUpdateSettings,
  onShowHistory,
  onResetOnboarding,
  onShowFibra,
}: Props) {
  const [profileOpen, setProfileOpen] = useState(false);
  const [draft, setDraft] = useState<EditProfileState>({
    userName: settings.userName,
    providerName: settings.providerName,
  });

  const displayName = settings.userName || 'Seu Nome';
  const displayProvider = settings.providerName || 'Seu Provedor';
  const intervalLabel = INTERVAL_OPTIONS.find((o) => o.value === settings.checkInterval)?.label ?? '5 minutos';
  const notifLabel = settings.notificationsEnabled ? 'Ativadas' : 'Desativadas';

  function openProfile() {
    setDraft({ userName: settings.userName, providerName: settings.providerName });
    setProfileOpen(true);
  }

  function closeProfile() {
    setProfileOpen(false);
  }

  function saveProfile() {
    onUpdateSettings({
      userName: draft.userName.trim(),
      providerName: draft.providerName.trim(),
    });
    setProfileOpen(false);
  }

  function handleIntervalChange(value: Settings['checkInterval']) {
    onUpdateSettings({ checkInterval: value });
  }

  function toggleNotifications() {
    onUpdateSettings({ notificationsEnabled: !settings.notificationsEnabled });
  }

  return (
    <AppScaffold>
      <AppHeader title="Ajustes" />

      <p className="settings-section-label">Perfil</p>
      <SettingsRow
        title="Meu perfil"
        subtitle={displayName}
        icon="person"
        onClick={openProfile}
      />

      <p className="settings-section-label">Provedor</p>
      <SettingsRow
        title="Provedor de internet"
        subtitle={displayProvider}
        icon="business"
        onClick={onShowFibra}
      />

      <p className="settings-section-label">Tema</p>
      <SettingsRow
        title="Aparência"
        subtitle={theme === 'dark' ? 'Escuro' : 'Claro'}
        icon="sun"
        onClick={onToggleTheme}
      />

      <p className="settings-section-label">Monitoramento</p>
      <SettingsRow
        title="Histórico de testes"
        subtitle="Ver histórico"
        icon="history"
        onClick={onShowHistory}
      />
      <SettingsRow
        title="Intervalo de verificação"
        subtitle={intervalLabel}
        icon="refresh"
        onClick={() => {
          const idx = INTERVAL_OPTIONS.findIndex((o) => o.value === settings.checkInterval);
          const next = INTERVAL_OPTIONS[(idx + 1) % INTERVAL_OPTIONS.length];
          handleIntervalChange(next.value);
        }}
      />

      <p className="settings-section-label">Alertas</p>
      <SettingsRow
        title="Alertas de conexão (in-app)"
        subtitle={notifLabel}
        icon="notifications"
        onClick={toggleNotifications}
      />
      <SettingsRow
        title="Notificações em segundo plano"
        subtitle="Requer app nativo"
        icon="loss"
        onClick={() => {/* disabled — sem backend de push */}}
      />
      <p className="settings-push-note">
        Alertas em segundo plano requerem app nativo instalado. No browser, monitoramento funciona apenas com o app aberto.
      </p>

      <p className="settings-section-label">Avançado</p>
      <SettingsRow
        title="Resetar Onboarding"
        subtitle="Ver tutorial novamente"
        icon="refresh"
        onClick={onResetOnboarding}
      />

      {profileOpen && (
        <div className="settings-modal-backdrop" onClick={closeProfile}>
          <div
            className="settings-modal"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
            aria-label="Editar perfil"
          >
            <h2 className="settings-modal__title">Editar Perfil</h2>

            <label className="settings-modal__label" htmlFor="settings-user-name">
              Seu nome
            </label>
            <input
              id="settings-user-name"
              className="settings-modal__input"
              type="text"
              placeholder="Ex: Lucas Ferreira"
              value={draft.userName}
              onChange={(e) => setDraft((prev) => ({ ...prev, userName: e.target.value }))}
              maxLength={60}
              autoFocus
            />

            <label className="settings-modal__label" htmlFor="settings-provider-name">
              Provedor
            </label>
            <input
              id="settings-provider-name"
              className="settings-modal__input"
              type="text"
              placeholder="Ex: Vivo Fibra 500"
              value={draft.providerName}
              onChange={(e) => setDraft((prev) => ({ ...prev, providerName: e.target.value }))}
              maxLength={60}
            />

            <div className="settings-modal__actions">
              <button
                type="button"
                className="settings-modal__btn settings-modal__btn--cancel"
                onClick={closeProfile}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="settings-modal__btn settings-modal__btn--save"
                onClick={saveProfile}
              >
                Salvar
              </button>
            </div>
          </div>
        </div>
      )}
    </AppScaffold>
  );
}
