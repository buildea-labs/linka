import React from 'react';
import { Icon } from './Icon';

export function TextLink({ children, href = '#', arrow = true, onClick, style }) {
  return (
    <a href={href} onClick={onClick}
      style={{ display: 'inline-flex', alignItems: 'center', gap: 5, fontFamily: 'var(--font-mono)', fontSize: 'var(--text-footnote)', color: 'var(--text-primary)', textDecoration: 'none', transition: 'color var(--duration-fast, .15s) var(--ease-standard)', ...style }}
      onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--color-accent-warm)')}
      onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-primary)')}>
      {children}
      {arrow && <Icon name="arrow-right" size={13} />}
    </a>
  );
}
