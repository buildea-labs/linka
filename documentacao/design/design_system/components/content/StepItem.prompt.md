# StepItem

Numbered explanation row — the three measurement phases on Como medimos.

```jsx
<div style={{display:'flex',flexDirection:'column',gap:16}}>
  <StepItem number="01" label="Conexão (ping)">Conecta ao servidor mais próximo e mede o tempo de ida e volta.</StepItem>
  <StepItem number="02" label="Download">Abre múltiplas conexões simultâneas e baixa dados por alguns segundos.</StepItem>
  <StepItem number="03" label="Upload">Repete o processo em sentido inverso até estabilizar a taxa.</StepItem>
</div>
```

Ordinals are always zero-padded and mono — they read as data, not as decoration.
