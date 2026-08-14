import React from 'react';

export function StepItem({ number, label, children }: { number: string; label: string; children: React.ReactNode }) {
  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      padding: '24px',
      borderRadius: 'var(--radius-lg, 16px)',
      background: 'var(--surface-card, #fff)',
      border: '1px solid var(--border-default, #e5e5e5)',
      height: '100%',
      boxSizing: 'border-box',
    }}>
      <div style={{
        fontFamily: 'var(--font-mono, monospace)',
        fontSize: '13px',
        letterSpacing: '0.08em',
        textTransform: 'uppercase',
        color: 'var(--text-secondary, #666)',
        marginBottom: '12px',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
      }}>
        <span style={{ fontWeight: 600, color: 'var(--text-primary, #000)' }}>{number}</span>
        <span>—</span>
        <span>{label}</span>
      </div>
      <div style={{
        fontSize: '15px',
        lineHeight: 1.5,
        color: 'var(--text-secondary, #666)',
      }}>
        {children}
      </div>
    </div>
  );
}
