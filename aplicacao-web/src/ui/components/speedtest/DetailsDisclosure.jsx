import React, { useState } from 'react';

export function DetailsDisclosure({ label = 'Ver detalhes da medição', children, defaultOpen = false }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div style={{ textAlign: 'center' }}>
      <button
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
        style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 'var(--space-xl)', fontSize: 14, color: 'var(--text-secondary)', padding: '6px 4px', borderRadius: 'var(--radius-sm)', border: 0, background: 'none', cursor: 'pointer', fontFamily: 'var(--font-body)' }}
        onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--brand-accent)')}
        onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-secondary)')}
      >
        {label}
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" style={{ width: 13, height: 13, transition: 'transform var(--duration-base) var(--ease-spring)', transform: open ? 'rotate(180deg)' : 'none' }}><path d="M6 9l6 6 6-6" /></svg>
      </button>
      <div style={{ maxWidth: 460, width: 'min(90vw, 460px)', margin: '0 auto', overflow: 'hidden', maxHeight: open ? 160 : 0, opacity: open ? 1 : 0, marginTop: open ? 'var(--space-md)' : 0, transition: 'max-height var(--duration-slow) var(--ease-spring), opacity var(--duration-base) var(--ease-standard), margin-top var(--duration-slow) var(--ease-spring)' }}>
        <div style={{ fontSize: 12, lineHeight: 'var(--leading-relaxed)', color: 'var(--text-secondary)' }}>{children}</div>
      </div>
    </div>
  );
}
