A borderless, text-forward action — the only button style in the Linka UI (no filled/primary button exists in the source). Hover and focus turn the label accent-blue; there is no background change or shadow.

```jsx
<Button icon={<RetryIcon />} onClick={runTest}>Testar novamente</Button>
```

Use `variant="subtle"` for lower-emphasis actions (e.g. a disclosure toggle); default `ghost` for primary text actions.
