import React from 'react';

export function StatDisplay({ label, value, unit, accent = false }) {
  return (
    <div style={{ textAlign: 'center', minWidth: 0, flex: 1 }}>
      <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: 'var(--tracking-wider)', textTransform: 'uppercase', color: accent ? 'var(--brand-accent)' : 'var(--text-secondary)', margin: '0 0 10px' }}>{label}</p>
      <div style={{ whiteSpace: 'nowrap' }}>
        <span style={{ fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontSize: 'clamp(32px, 8vw, 84px)', fontWeight: 'var(--weight-bold)', letterSpacing: 'var(--tracking-tight)', lineHeight: 1, color: 'var(--text-primary)' }}>{value}</span>
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'clamp(12px, 2vw, 18px)', color: 'var(--text-secondary)', marginLeft: 3, fontWeight: 'var(--weight-medium)' }}>{unit}</span>
      </div>
    </div>
  );
}
