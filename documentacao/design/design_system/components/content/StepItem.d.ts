import * as React from 'react';
export interface StepItemProps {
  /** Zero-padded mono ordinal: "01", "02", "03". */
  number: string;
  /** Phase name: "Conexão (ping)", "Download", "Upload". */
  label?: string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export declare function StepItem(props: StepItemProps): JSX.Element;
