import React from 'react';
import { Wordmark } from '../brand/Wordmark';

export function SiteFooter({ copyright = '© 2026 Linka Speedtest', tagline = 'Meça sua internet em segundos.', style }) {
  return (
    <footer style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '20px var(--gutter)', borderTop: 'var(--hairline) solid var(--border-default)', fontSize: 'var(--text-caption1)', color: 'var(--text-secondary)', ...style }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <Wordmark size="sm" />
        <span>{copyright}</span>
      </div>
      <span>{tagline}</span>
    </footer>
  );
}
