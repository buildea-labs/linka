import * as React from 'react';
export interface ButtonProps {
  children?: React.ReactNode;
  /** Optional leading/trailing icon node (a small inline SVG, ~1.75px stroke to match SF Symbols regular weight). */
  icon?: React.ReactNode;
  /** Apple HIG button styles: 'plain' (text-only, default), 'subtle' (muted text-only), 'tinted' (soft accent fill), 'filled' (solid accent, primary action). */
  variant?: 'plain' | 'subtle' | 'tinted' | 'filled';
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function Button(props: ButtonProps): JSX.Element;
