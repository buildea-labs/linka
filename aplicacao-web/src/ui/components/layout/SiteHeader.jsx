import React from 'react';
import { Wordmark } from '../brand/Wordmark';

export function SiteHeader({ items = [], activeHref, homeHref = '#', onNavigate, onOpenSettings, style = {} }) {
  const handleClick = (e, href) => {
    if (onNavigate) {
      e.preventDefault();
      onNavigate(href);
    }
  };

  return (
    <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--gutter)', padding: '22px var(--gutter)', paddingTop: 'calc(22px + env(safe-area-inset-top))', ...style }}>
      <a href={homeHref} onClick={(e) => handleClick(e, homeHref)} aria-label="linka" style={{ display: 'block', lineHeight: 0 }}><Wordmark size="md" /></a>
      
      <button className="mobile-only" onClick={onOpenSettings} style={{ background: 'none', border: 'none', color: 'var(--text-primary)', padding: 8, cursor: 'pointer' }} aria-label="Ajustes">
        <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <line x1="4" y1="6" x2="20" y2="6"></line><circle cx="9" cy="6" r="2" fill="var(--surface-page)"></circle>
          <line x1="4" y1="12" x2="20" y2="12"></line><circle cx="15" cy="12" r="2" fill="var(--surface-page)"></circle>
          <line x1="4" y1="18" x2="20" y2="18"></line><circle cx="9" cy="18" r="2" fill="var(--surface-page)"></circle>
        </svg>
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
