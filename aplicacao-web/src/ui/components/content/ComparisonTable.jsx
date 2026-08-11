import React from 'react';

export function ComparisonTable({ columns = [], rows = [], highlight = 0, style }) {
  const grid = { display: 'grid', gridTemplateColumns: '1.4fr ' + columns.map(() => '1fr').join(' ') };
  const cell = { padding: '14px 16px', fontSize: 'var(--text-sm)' };
  return (
    <div style={{ border: 'var(--border-width) solid var(--border-default)', borderRadius: 'var(--radius-lg)', overflow: 'hidden', textAlign: 'left', ...style }}>
      <div style={{ ...grid, background: 'var(--color-fg-soft)' }}>
        <div style={cell} />
        {columns.map((c, i) => (
          <div key={c} style={{ ...cell, fontFamily: 'var(--font-mono)', fontSize: 'var(--text-caption2)', letterSpacing: 'var(--tracking-wide)', textTransform: 'uppercase', color: i === highlight ? 'var(--text-primary)' : 'var(--text-secondary)', fontWeight: i === highlight ? 'var(--weight-semibold)' : 'var(--weight-regular)' }}>{c}</div>
        ))}
      </div>
      {rows.map((r) => (
        <div key={r.label} style={{ ...grid, borderTop: 'var(--border-width) solid var(--border-default)' }}>
          <div style={{ ...cell, color: 'var(--text-secondary)' }}>{r.label}</div>
          {r.values.map((v, i) => (
            <div key={i} style={{ ...cell, color: i === highlight ? 'var(--text-primary)' : 'var(--text-secondary)' }}>{v}</div>
          ))}
        </div>
      ))}
    </div>
  );
}
