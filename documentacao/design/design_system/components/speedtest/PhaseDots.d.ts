import * as React from 'react';
export interface PhaseDotsProps {
  /** Ordered phase list, e.g. [{key:'download',label:'Download'},{key:'upload',label:'Upload'}]. */
  phases: { key: string; label: string }[];
  /** Key of the currently active phase; earlier phases render as "done". */
  activeKey: string;
}
export declare function PhaseDots(props: PhaseDotsProps): JSX.Element;
