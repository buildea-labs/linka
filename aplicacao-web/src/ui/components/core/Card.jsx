import React from 'react';

export function Card({ children, dashed = false, label = undefined, padding = 'var(--space-md)', style = {} }) {
  return (
    <div style={{
      position: 'relative', border: `${dashed ? 'var(--border-width)' : 'var(--hairline)'} ${dashed ? 'dashed' : 'solid'} var(--border-default)`,
      borderRadius: dashed ? 'var(--radius)' : 'var(--radius-lg)', background: 'var(--surface-card)',
      padding, ...style
    }}>
      {label && (
        <span style={{ position: 'absolute', top: -9, left: 14, background: 'var(--surface-page)', padding: '0 8px', fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: 'var(--tracking-wide)', textTransform: 'uppercase', color: 'var(--text-secondary)' }}>{label}</span>
      )}
      {children}
    </div>
  );
}
