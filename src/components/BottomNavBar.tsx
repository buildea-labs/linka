import './BottomNavBar.css';

export type NavTab = 'home' | 'velocidade' | 'sinal' | 'historico' | 'ajustes';

interface Props {
  active: NavTab;
  onNavigate: (tab: NavTab) => void;
}

export function BottomNavBar({ active, onNavigate }: Props) {
  return (
    <nav className="lk-navbar" role="navigation" aria-label="Navegação principal">
      <NavItem
        tab="home"
        active={active === 'home'}
        label="Início"
        icon={<HomeIcon />}
        onNavigate={onNavigate}
      />
      <NavItem
        tab="velocidade"
        active={active === 'velocidade'}
        label="Velocidade"
        icon={<VelocidadeIcon />}
        onNavigate={onNavigate}
      />
      <NavItem
        tab="sinal"
        active={active === 'sinal'}
        label="Sinal"
        icon={<SinalIcon />}
        onNavigate={onNavigate}
      />
      <NavItem
        tab="historico"
        active={active === 'historico'}
        label="Histórico"
        icon={<HistoricoIcon />}
        onNavigate={onNavigate}
      />
      <NavItem
        tab="ajustes"
        active={active === 'ajustes'}
        label="Ajustes"
        icon={<AjustesIcon />}
        onNavigate={onNavigate}
      />
    </nav>
  );
}

interface NavItemProps {
  tab: NavTab;
  active: boolean;
  label: string;
  icon: React.ReactNode;
  onNavigate: (tab: NavTab) => void;
}

function NavItem({ tab, active, label, icon, onNavigate }: NavItemProps) {
  return (
    <button
      className={`lk-navbar__item${active ? ' lk-navbar__item--active' : ''}`}
      onClick={() => onNavigate(tab)}
      aria-current={active ? 'page' : undefined}
      aria-label={label}
      type="button"
    >
      <span className="lk-navbar__icon">{icon}</span>
      <span className="lk-navbar__label">{label}</span>
    </button>
  );
}

/* ── Ícones inline (SVG) ────────────────────────────────────────────────── */

function HomeIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
      <path
        d="M3 12L12 3L21 12V20C21 20.55 20.55 21 20 21H15V16H9V21H4C3.45 21 3 20.55 3 20V12Z"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function VelocidadeIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
      {/* Arco do velocímetro */}
      <path
        d="M5 16A8 8 0 0 1 12 4a8 8 0 0 1 7 12"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
      {/* Ponteiro */}
      <line
        x1="12"
        y1="16"
        x2="16"
        y2="11"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
      {/* Centro */}
      <circle cx="12" cy="16" r="1.5" fill="currentColor" />
    </svg>
  );
}

function SinalIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
      <path d="M4 9a12 12 0 0 1 16 0" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <path d="M7 12a8 8 0 0 1 10 0" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <path d="M10 15a4 4 0 0 1 4 0" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <circle cx="12" cy="18" r="1.5" fill="currentColor" />
    </svg>
  );
}

function HistoricoIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="8" stroke="currentColor" strokeWidth="1.7" />
      <path d="M12 8v4l3 2" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function AjustesIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.7" />
      <path
        d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
