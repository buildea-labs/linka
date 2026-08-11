import * as React from 'react';
export interface StatDisplayProps {
  /** Small uppercase mono label above the number, e.g. "Download". */
  label: string;
  value: React.ReactNode;
  unit?: string;
  /** Tints the label accent-blue — used for the download stat on the result screen. */
  accent?: boolean;
}
export declare function StatDisplay(props: StatDisplayProps): JSX.Element;
