# ComparisonTable

Hairline comparison grid ("Menos tela, mais medição") — in the prototype this was a raw CSS class
plus five hand-written grid rows.

```jsx
<ComparisonTable
  columns={['Linka Speedtest', 'Outros serviços']}
  rows={[
    { label: 'Início da medição', values: ['Automático, sem clique', 'Requer clique em "Iniciar"'] },
    { label: 'Anúncios', values: ['Um espaço reservado, discreto', 'Banners e pop-ups em tela cheia'] },
  ]} />
```

Never uses check/cross icons or color-coded cells — the contrast is carried by ink weight alone.
