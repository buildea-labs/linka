import React from 'react';
import { Card } from '../core/Card';
import { Eyebrow } from '../core/Eyebrow';

export function ValueCard({ label, children, action, align = 'left', style }) {
  return (
    <Card style={{ display: 'flex', flexDirection: 'column', textAlign: align, ...style }}>
      {label && <Eyebrow size="sm" style={{ marginBottom: 10 }}>{label}</Eyebrow>}
      <p style={{ fontSize: 'var(--text-subheadline)', lineHeight: 1.55, color: 'var(--text-primary)', margin: 0, textWrap: 'pretty' }}>{children}</p>
      {action && <div style={{ marginTop: 14 }}>{action}</div>}
    </Card>
  );
}
