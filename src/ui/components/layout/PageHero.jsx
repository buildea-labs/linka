import React from 'react';
import { Eyebrow } from '../core/Eyebrow';

export function PageHero({ eyebrow, title, lead, children, align = 'center', maxWidth = 720, style }) {
  return (
    <div style={{ maxWidth, width: '100%', textAlign: align, ...style }}>
      {eyebrow && <Eyebrow style={{ marginBottom: 16 }}>{eyebrow}</Eyebrow>}
      <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 'var(--weight-bold)', letterSpacing: 'var(--tracking-snug)', lineHeight: 1.15, margin: '0 0 24px', textWrap: 'pretty' }}>{title}</h1>
      {lead && <p style={{ fontSize: 'var(--text-md)', lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0, textWrap: 'pretty' }}>{lead}</p>}
      {children}
    </div>
  );
}
