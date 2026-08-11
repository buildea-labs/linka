Renders the Linka wordmark — the drawn "linka" logotype: uniform round-terminal strokes, the "i" as a thicker bar descending below the baseline, and the warm-orange dot as its tittle. Vector geometry traced 1:1 from the approved logo artwork (`assets/wordmark.svg`), not typed in a font — the wordmark is a fixed drawing, so it never depends on a font being installed.

```jsx
<Wordmark size="lg" />
<Wordmark size="md" color="#fff" />   {/* on the navy brand surface */}
```

Sizes: `sm` (22px tall — nav/footer), `md` (28px, default), `lg` (60px — hero/showcase). Color defaults to `--text-primary`; pass `color="#fff"` over navy. The dot stays `--color-accent-warm` unless overridden.
