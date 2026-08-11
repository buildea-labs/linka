import React from 'react';
import { Wordmark } from '../brand/Wordmark';

export function SiteFooter({ copyright = '© 2026 Linka Speedtest', tagline = 'Meça sua internet em segundos.', isMainRoute = false, style = {} }) {
  return (
    <footer className={isMainRoute ? 'hide-on-mobile-main is-main-route' : ''} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '20px var(--gutter)', paddingBottom: 'calc(20px + env(safe-area-inset-bottom))', borderTop: 'var(--hairline) solid var(--border-default)', fontSize: 'var(--text-caption1)', color: 'var(--text-secondary)', ...style }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <Wordmark size="sm" />
        <span>{copyright}</span>
      </div>
      <span>{tagline}</span>
    </footer>
  );
}
