import React from 'react';

export function LegalSection({ title, children, spacing = 28, style }) {
  return (
    <section style={{ marginBottom: spacing, ...style }}>
      <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-title3)', fontWeight: 'var(--weight-semibold)', margin: '0 0 10px' }}>{title}</h2>
      <div style={{ fontSize: 'var(--text-subheadline)', lineHeight: 1.65, color: 'var(--text-secondary)' }}>{children}</div>
    </section>
  );
}
