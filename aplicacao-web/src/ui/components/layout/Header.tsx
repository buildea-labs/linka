import { Wordmark } from '../brand/Wordmark';

const NAV_ITEMS = [
  { href: '/como-medimos', label: 'Como medimos' },
  { href: '/privacidade', label: 'Privacidade' },
  { href: '/suporte', label: 'Suporte' },
];

export function Header({ maxWidth = 860, activeHref }: { maxWidth?: number; activeHref?: string }) {
  return (
    <header style={{ padding: '22px 24px', maxWidth, margin: '0 auto', width: '100%', boxSizing: 'border-box', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
      <a href="/" aria-label="Linka Home" style={{ color: 'inherit', textDecoration: 'none' }}>
        <Wordmark size="md" color={undefined} dotColor={undefined} />
      </a>
      <nav style={{ display: 'flex', gap: '20px', fontSize: '14px', fontWeight: 500 }} aria-label="Navegação Principal">
        {NAV_ITEMS.map((item) => {
          const active = item.href === activeHref;
          return (
            <a
              key={item.href}
              href={active ? undefined : item.href}
              aria-current={active ? 'page' : undefined}
              style={{ color: active ? 'var(--text-primary, #000)' : 'var(--text-secondary, #666)', textDecoration: 'none' }}
            >
              {item.label}
            </a>
          );
        })}
      </nav>
    </header>
  );
}
