# LegalSection

Prose block for policy/terms pages: 20px display subhead + 15px/1.65 secondary body, 28px rhythm.
Group parts with an accent `<Eyebrow tone="accent">`, and close the last section of a part with
`spacing={44}`.

```jsx
<Eyebrow tone="accent" style={{marginBottom:20}}>Privacidade</Eyebrow>
<LegalSection title="Dados coletados">Cada teste registra apenas o necessário…</LegalSection>
<LegalSection title="Cookies" spacing={44}>Usamos apenas um cookie técnico…</LegalSection>
<Eyebrow tone="accent" style={{marginBottom:20}}>Termos de uso</Eyebrow>
```

Measure stays at 720px. Emphasis inside body copy is `<b>` in primary ink, never a link color.
