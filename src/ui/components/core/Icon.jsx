import React from 'react';

const PATHS = {
  'chevron-down': ['M6 9l6 6 6-6'],
  'chevron-right': ['M9 6l6 6-6 6'],
  'chevron-left': ['M15 6l-6 6 6 6'],
  retry: ['M3 12a9 9 0 1 1 3 6.7', 'M3 21v-6h6'],
  'arrow-right': ['M5 12h14', 'M13 5l7 7-7 7'],
  close: ['M6 6l12 12', 'M18 6L6 18'],
  menu: ['M4 7h16', 'M4 12h16', 'M4 17h16'],
};

export function Icon({ name, size = 16, rotate = 0, style }) {
  const d = PATHS[name] || [];
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
      style={{ width: size, height: size, flexShrink: 0, transform: rotate ? 'rotate(' + rotate + 'deg)' : undefined, transition: 'transform var(--duration-fast, .2s) var(--ease-spring)', ...style }}>
      {d.map((p, i) => <path key={i} d={p} />)}
    </svg>
  );
}
