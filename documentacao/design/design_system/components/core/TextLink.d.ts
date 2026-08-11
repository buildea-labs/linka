import * as React from 'react';
export interface TextLinkProps {
  children?: React.ReactNode;
  href?: string;
  /** Trailing arrow glyph. Default true. */
  arrow?: boolean;
  onClick?: React.MouseEventHandler;
  style?: React.CSSProperties;
}
export declare function TextLink(props: TextLinkProps): JSX.Element;
