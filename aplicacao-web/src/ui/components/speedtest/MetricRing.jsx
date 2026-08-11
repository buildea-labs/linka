import React from 'react';

export function MetricRing({ progress = 0, value, unit, connecting = false, hideRing = false, size = 220 }) {
  const circ = 339.3;
  const offset = circ * (1 - progress);
  return (
    <div style={{ position: 'relative', width: size, aspectRatio: '1', display: 'grid', placeItems: 'center', margin: '0 auto' }}>
      {!hideRing && (
        <svg viewBox="0 0 120 120" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', transform: 'rotate(-90deg)', animation: 'linkaFadeIn 0.3s ease' }}>
          <circle cx="60" cy="60" r="54" fill="none" stroke="var(--border-default)" strokeWidth="3" />
          <circle cx="60" cy="60" r="54" fill="none" stroke="var(--brand-accent)" strokeWidth="3" strokeLinecap="round"
            strokeDasharray={circ} strokeDashoffset={offset} opacity={connecting ? 0 : 1}
            style={{ transition: 'stroke-dashoffset 0.12s linear' }} />
        </svg>
      )}
      <div style={{ textAlign: 'center', padding: '0 12%', maxWidth: '100%', zIndex: 1 }}>
        {connecting ? (
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: Math.round(size * 0.1), fontWeight: 'var(--weight-medium)', color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>{value}</div>
        ) : (
          <div style={{ fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontSize: Math.round(size * 0.24), fontWeight: 'var(--weight-semibold)', letterSpacing: 'var(--tracking-tight)', lineHeight: 1, color: 'var(--text-primary)', whiteSpace: 'nowrap' }}>
            {value}<span style={{ fontSize: '0.22em', color: 'var(--text-secondary)', marginLeft: 4 }}>{unit}</span>
          </div>
        )}
      </div>
    </div>
  );
}
