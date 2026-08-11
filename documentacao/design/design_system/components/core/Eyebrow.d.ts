import * as React from 'react';
export interface EyebrowProps {
  children?: React.ReactNode;
  /** sm = 11px/0.06em (in-card labels), md = 12px/0.1em (page + section markers). Default md. */
  size?: 'sm' | 'md';
  /** accent (warm orange) marks a document part change, e.g. "PRIVACIDADE" / "TERMOS DE USO". Default secondary. */
  tone?: 'secondary' | 'primary' | 'accent';
  as?: keyof JSX.IntrinsicElements;
  style?: React.CSSProperties;
}
export declare function Eyebrow(props: EyebrowProps): JSX.Element;
