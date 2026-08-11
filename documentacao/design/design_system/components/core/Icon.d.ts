import * as React from 'react';
export type IconName = 'chevron-down' | 'chevron-right' | 'chevron-left' | 'retry' | 'arrow-right' | 'close' | 'menu';
export interface IconProps {
  name: IconName;
  /** px. 14–16 inline with text, 18–20 as a standalone control. Default 16. */
  size?: number;
  /** Degrees — used for the details chevron flip (rotate={open ? 180 : 0}). */
  rotate?: number;
  style?: React.CSSProperties;
}
export declare function Icon(props: IconProps): JSX.Element;
