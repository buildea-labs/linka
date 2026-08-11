# SiteHeader

Wordmark + text nav, no background, no border, no shadow. Was duplicated verbatim on all five
prototype pages, with only the active item differing.

```jsx
const NAV = [
  { label: 'Sobre Nós', href: 'sobre.html' },
  { label: 'Como medimos', href: 'como-medimos.html' },
  { label: 'Privacidade & Termos de Uso', href: 'privacidade.html' },
  { label: 'App’s', href: 'apps.html' },
];
<SiteHeader items={NAV} activeHref="apps.html" homeHref="index.html" />
```

Only the active item is primary ink; everything else is secondary until hover.
