import React from 'react';

export function PhaseDots({ phases, activeKey }) {
  const order = (k) => phases.findIndex((p) => p.key === k);
  return (
    <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 'var(--space-lg)' }}>
      {phases.map((p) => {
        const done = order(p.key) < order(activeKey);
        const current = p.key === activeKey;
        const color = current ? 'var(--text-primary)' : done ? 'var(--text-secondary)' : 'var(--border-default)';
        return (
          <span key={p.key} style={{ display: 'flex', alignItems: 'center', gap: 6, fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: 'var(--tracking-wide)', textTransform: 'uppercase', color, fontWeight: current ? 'var(--weight-semibold)' : 'var(--weight-regular)', transition: 'color var(--duration-base) var(--ease-standard)' }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: color }} />
            {p.label}
          </span>
        );
      })}
    </div>
  );
}
