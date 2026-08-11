import * as React from 'react';
export interface LegalSectionProps {
  title: React.ReactNode;
  children?: React.ReactNode;
  /** Bottom margin. 28 between sections, 44 before a new document part. Default 28. */
  spacing?: number;
  style?: React.CSSProperties;
}
export declare function LegalSection(props: LegalSectionProps): JSX.Element;
