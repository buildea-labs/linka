import * as React from 'react';
export interface AdSlotProps {
  /** leaderboard = 728×90 (web/desktop result screen), banner = 320×50 (phone). Default leaderboard. */
  format?: 'leaderboard' | 'banner';
  label?: string;
  /** Overrides the placeholder caption. */
  note?: string;
  style?: React.CSSProperties;
}
export declare function AdSlot(props: AdSlotProps): JSX.Element;
