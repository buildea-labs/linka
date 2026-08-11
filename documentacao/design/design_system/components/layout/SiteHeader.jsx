import React from 'react';
import { Wordmark } from '../brand/Wordmark';

export function SiteHeader({ items = [], activeHref, homeHref = '#', style }) {
  return (
    <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--gutter)', padding: '22px var(--gutter)', ...style }}>
      <a href={homeHref} aria-label="linka" style={{ display: 'block', lineHeight: 0 }}><Wordmark size="md" /></a>
      <nav style={{ display: 'flex', alignItems: 'center', gap: 28, flexWrap: 'wrap' }}>
        {items.map((it) => {
          const active = it.href === activeHref;
          return (
            <a key={it.href + it.label} href={active ? '#' : it.href}
              aria-current={active ? 'page' : undefined}
              style={{ fontSize: 'var(--text-sm)', color: active ? 'var(--text-primary)' : 'var(--text-secondary)', textDecoration: 'none', transition: 'color var(--duration-fast, .15s) var(--ease-standard)' }}
              onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--text-primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.color = active ? 'var(--text-primary)' : 'var(--text-secondary)')}>
              {it.label}
            </a>
          );
        })}
      </nav>
    </header>
  );
}
