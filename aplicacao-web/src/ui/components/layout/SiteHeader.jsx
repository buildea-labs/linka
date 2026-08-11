import React from 'react';
import { Wordmark } from '../brand/Wordmark';

export function SiteHeader({ items = [], activeHref, homeHref = '#', onNavigate, style = {} }) {
  const handleClick = (e, href) => {
    if (onNavigate) {
      e.preventDefault();
      onNavigate(href);
    }
  };

  return (
    <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--gutter)', padding: '22px var(--gutter)', paddingTop: 'calc(22px + env(safe-area-inset-top))', ...style }}>
      <a href={homeHref} onClick={(e) => handleClick(e, homeHref)} aria-label="linka" style={{ display: 'block', lineHeight: 0 }}><Wordmark size="md" /></a>
      
      <button className="mobile-only" style={{ background: 'none', border: 'none', color: 'var(--text-primary)', padding: 8, cursor: 'pointer' }} aria-label="Ajustes">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
      </button>

      <nav className="desktop-only" style={{ display: 'flex', alignItems: 'center', gap: 28 }}>
        {items.map((it) => {
          const active = it.href === activeHref;
          return (
            <a key={it.href + it.label} href={active ? '#' : it.href}
              onClick={(e) => handleClick(e, it.href)}
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
