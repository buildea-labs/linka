import React from 'react';
import { Card } from '../core/Card';
import { Eyebrow } from '../core/Eyebrow';

export function StepItem({ number, label, children, style }) {
  return (
    <Card style={style}>
      <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-footnote)', color: 'var(--text-secondary)', minWidth: 20 }}>{number}</span>
        <div>
          {label && <Eyebrow size="sm" style={{ marginBottom: 8 }}>{label}</Eyebrow>}
          <p style={{ fontSize: 'var(--text-subheadline)', lineHeight: 1.55, color: 'var(--text-primary)', margin: 0, textWrap: 'pretty' }}>{children}</p>
        </div>
      </div>
    </Card>
  );
}
