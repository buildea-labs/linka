import * as React from 'react';
export interface WordmarkProps {
  /** Size preset controlling the rendered height (sm 22px, md 28px, lg 60px). Default 'md'. */
  size?: 'sm' | 'md' | 'lg';
  /** Override the letterform color; defaults to --text-primary (use #fff on navy). */
  color?: string;
  /** Override the accent dot color; defaults to --color-accent-warm. */
  dotColor?: string;
}
export declare function Wordmark(props: WordmarkProps): JSX.Element;
