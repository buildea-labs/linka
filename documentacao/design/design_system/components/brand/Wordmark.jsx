import React from 'react';

const HEIGHTS = { sm: 22, md: 28, lg: 60 };

export function Wordmark({ size = 'md', color, dotColor }) {
  const h = HEIGHTS[size] || HEIGHTS.md;
  const fg = color || 'var(--text-primary)';
  return (
    <svg role="img" aria-label="linka" viewBox="48 53 170 71" height={h} width={h * (170 / 71)} style={{ display: 'block', overflow: 'visible' }}>
      <g fill="none" stroke={fg} strokeWidth="9.6" strokeLinecap="round" strokeLinejoin="round">
        <path d="M53.5 59V108" />
        <path d="M92.5 75V108" />
        <path d="M92.5 87c0-8 8-12.5 17.5-12.5 6.5 0 9.5 5.5 9.5 12v21" />
        <path d="M139 59.5V107.5" />
        <path d="M163.5 75.5 142.5 96.5" />
        <path d="m149 91 16.5 16.5" />
        <ellipse cx="195.5" cy="91.5" rx="16.25" ry="17.8" />
        <path d="M211.5 75v32.5" />
      </g>
      <path d="M72.5 86.75v30.25" fill="none" stroke={fg} strokeWidth="11.4" strokeLinecap="round" />
      <circle cx="72.5" cy="67.5" r="10" fill={dotColor || 'var(--color-accent-warm)'} />
    </svg>
  );
}
