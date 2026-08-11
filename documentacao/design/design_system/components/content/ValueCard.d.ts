import * as React from 'react';
export interface ValueCardProps {
  /** Uppercase mono label, one or two words: "Privacidade", "Qualidade", "Velocidade". */
  label?: string;
  children?: React.ReactNode;
  /** Optional closing action, usually a <TextLink>. */
  action?: React.ReactNode;
  align?: 'left' | 'center';
  style?: React.CSSProperties;
}
export declare function ValueCard(props: ValueCardProps): JSX.Element;
