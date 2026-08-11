import * as React from 'react';
export interface SiteNavItem { label: string; href: string }
export interface SiteHeaderProps {
  items?: SiteNavItem[];
  /** href of the current page — that item renders in primary ink and is not linked. */
  activeHref?: string;
  homeHref?: string;
  style?: React.CSSProperties;
}
export declare function SiteHeader(props: SiteHeaderProps): JSX.Element;
