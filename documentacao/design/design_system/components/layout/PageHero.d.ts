import * as React from 'react';
export interface PageHeroProps {
  /** Uppercase mono label — usually the page name. */
  eyebrow?: string;
  title: React.ReactNode;
  /** 17px secondary paragraph under the title. */
  lead?: React.ReactNode;
  children?: React.ReactNode;
  align?: 'center' | 'left';
  maxWidth?: number;
  style?: React.CSSProperties;
}
export declare function PageHero(props: PageHeroProps): JSX.Element;
