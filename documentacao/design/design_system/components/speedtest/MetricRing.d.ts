import * as React from 'react';
export interface MetricRingProps {
  /** Ring fill 0–1. Ignored while connecting. */
  progress?: number;
  /** The big number (or "Preparando" while connecting), pre-formatted (pt-BR decimal comma). */
  value: React.ReactNode;
  /** Unit label shown small next to the value, e.g. "Mbps". Omit while connecting. */
  unit?: string;
  /** True during the invisible ping phase — hides the ring stroke and shrinks/mutes the number. */
  connecting?: boolean;
  size?: number;
}
export declare function MetricRing(props: MetricRingProps): JSX.Element;
