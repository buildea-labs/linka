import React from 'react';

const VARIANTS = {
  plain: { bg: 'transparent', fg: 'var(--text-primary)', fgHover: 'var(--brand-accent)' },
  subtle: { bg: 'transparent', fg: 'var(--text-secondary)', fgHover: 'var(--brand-accent)' },
  tinted: { bg: 'var(--color-accent-soft)', fg: 'var(--brand-accent)', fgHover: 'var(--brand-accent)' },
  filled: { bg: 'var(--brand-accent)', fg: 'var(--text-on-accent)', fgHover: 'var(--text-on-accent)' },
};

export function Button({ children, icon, variant = 'plain', onClick, style }) {
  const v = VARIANTS[variant] || VARIANTS.plain;
  const raised = variant === 'filled' || variant === 'tinted';
  const base = {
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 7,
    fontFamily: 'var(--font-body)', fontSize: 'var(--text-headline)', fontWeight: 'var(--weight-semibold)',
    padding: raised ? '10px 18px' : '10px 4px',
    minHeight: raised ? 'var(--touch-target)' : undefined,
    borderRadius: raised ? 'var(--radius)' : 'var(--radius-sm)',
    border: 0, background: v.bg, color: v.fg, cursor: 'pointer',
    transition: 'transform var(--duration-fast) var(--ease-spring), opacity var(--duration-fast) var(--ease-standard), color var(--duration-fast) var(--ease-standard)'
  };
  return (
    <button
      onClick={onClick}
      style={{ ...base, ...style }}
      onMouseEnter={(e) => { if (!raised) e.currentTarget.style.color = v.fgHover; }}
      onMouseLeave={(e) => { e.currentTarget.style.color = v.fg; e.currentTarget.style.transform = 'none'; e.currentTarget.style.opacity = 1; }}
      onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(var(--press-scale))'; e.currentTarget.style.opacity = 0.75; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.opacity = 1; }}
    >
      {icon}
      {children}
    </button>
  );
}
