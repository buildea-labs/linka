import * as React from 'react';
export interface ComparisonRow { label: string; values: React.ReactNode[] }
export interface ComparisonTableProps {
  /** Column headers, rendered uppercase mono. Row label column is implicit. */
  columns?: string[];
  rows?: ComparisonRow[];
  /** Index of the column rendered in primary ink (our column). Default 0. */
  highlight?: number;
  style?: React.CSSProperties;
}
export declare function ComparisonTable(props: ComparisonTableProps): JSX.Element;
