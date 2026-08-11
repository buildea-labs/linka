import * as React from 'react';
export interface CardProps {
  children?: React.ReactNode;
  /** Dashed border + tighter radius — used for reserved/placeholder slots (e.g. the ad slot). Default false (solid border, larger radius). */
  dashed?: boolean;
  /** Small uppercase mono label notched into the top border, e.g. "Publicidade". */
  label?: string;
  padding?: string;
  style?: React.CSSProperties;
}
export declare function Card(props: CardProps): JSX.Element;
