import React from 'react';

const SIZES = { sm: { fontSize: 11, letterSpacing: 'var(--tracking-wide)' }, md: { fontSize: 12, letterSpacing: 'var(--tracking-wider)' } };
const TONES = { secondary: 'var(--text-secondary)', primary: 'var(--text-primary)', accent: 'var(--color-accent-warm)' };

export function Eyebrow({ children, size = 'md', tone = 'secondary', as = 'p', style }) {
  const Tag = as;
  return (
    <Tag style={{ margin: 0, fontFamily: 'var(--font-mono)', fontWeight: 'var(--weight-regular)', textTransform: 'uppercase', color: TONES[tone] || TONES.secondary, ...(SIZES[size] || SIZES.md), ...style }}>
      {children}
    </Tag>
  );
}
