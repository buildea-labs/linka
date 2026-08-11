import React from 'react';

export function StatusLabel({ children, tone = 'active', align = 'center', style }) {
  const dot = tone === 'active' ? 'var(--color-accent-warm)' : 'var(--border-default)';
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: align === 'center' ? 'center' : 'flex-start', gap: 8, ...style }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: dot, flexShrink: 0 }} />
      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-caption2)', letterSpacing: 'var(--tracking-wide)', textTransform: 'uppercase', color: 'var(--text-secondary)' }}>{children}</span>
    </div>
  );
}
