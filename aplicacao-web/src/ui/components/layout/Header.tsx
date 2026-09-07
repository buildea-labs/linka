import { Wordmark } from '../brand/Wordmark';

export function Header({ maxWidth = 860 }: { maxWidth?: number }) {
  return (
    <header style={{ padding: '22px 24px', maxWidth, margin: '0 auto', width: '100%', boxSizing: 'border-box', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
      <a href="/" aria-label="Linka Home" style={{ color: 'inherit', textDecoration: 'none' }}>
        <Wordmark size="md" color={undefined} dotColor={undefined} />
      </a>
      <nav style={{ display: 'flex', gap: '20px', fontSize: '14px', fontWeight: 500 }} aria-label="Navegação Principal">
        <a href="/como-medimos" style={{ color: 'var(--text-secondary, #666)', textDecoration: 'none' }}>Como medimos</a>
        <a href="/privacidade" style={{ color: 'var(--text-secondary, #666)', textDecoration: 'none' }}>Privacidade</a>
        <a href="/suporte" style={{ color: 'var(--text-secondary, #666)', textDecoration: 'none' }}>Suporte</a>
      </nav>
    </header>
  );
}
