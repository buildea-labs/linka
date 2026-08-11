import * as React from 'react';
export interface StatusLabelProps {
  children?: React.ReactNode;
  /** active = warm dot (shipping / live), pending = hairline dot (in development). Default active. */
  tone?: 'active' | 'pending';
  align?: 'center' | 'start';
  style?: React.CSSProperties;
}
export declare function StatusLabel(props: StatusLabelProps): JSX.Element;
