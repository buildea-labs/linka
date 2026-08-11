import React from 'react';
import { Card } from '../core/Card';

const SIZES = { leaderboard: { w: 728, h: 90, minHeight: 180, label: '728×90' }, banner: { w: 320, h: 50, minHeight: 90, label: '320×50' } };

export function AdSlot({ format = 'leaderboard', label = 'Publicidade', note, style }) {
  const s = SIZES[format] || SIZES.leaderboard;
  return (
    <Card dashed label={label} style={{ width: '100%', maxWidth: s.w, minHeight: s.minHeight, display: 'flex', alignItems: 'center', justifyContent: 'center', ...style }}>
      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-caption1)', color: 'var(--text-secondary)' }}>{note || 'Espaço reservado para anúncio · ' + s.label}</span>
    </Card>
  );
}
