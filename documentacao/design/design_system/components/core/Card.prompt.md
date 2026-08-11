A bordered surface container. Solid border + 16px radius for content cards (steps, field lists); dashed border + 10px radius + a notched label for reserved/placeholder slots like the ad unit.

```jsx
<Card>
  <p className="step">01 · Transparente</p>
  <h3>Conexão &amp; ping</h3>
</Card>

<Card dashed label="Publicidade" style={{ minHeight: 90 }} />
```
