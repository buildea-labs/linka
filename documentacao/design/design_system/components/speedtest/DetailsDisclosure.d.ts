import * as React from 'react';
export interface DetailsDisclosureProps {
  label?: string;
  /** Content of the collapsible panel — typically a row of muted key/value pairs. */
  children?: React.ReactNode;
  defaultOpen?: boolean;
}
export declare function DetailsDisclosure(props: DetailsDisclosureProps): JSX.Element;
