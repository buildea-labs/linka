# AdSlot

The single reserved advertising space on the result screen — dashed card, notched "Publicidade"
label, mono size caption. It is a product commitment (one discreet slot, never full-screen), so it
belongs in the system rather than being redrawn per screen.

```jsx
<AdSlot />                    {/* 728×90, web result screen */}
<AdSlot format="banner" />    {/* 320×50, phone result screen */}
```

Only ever appears after the result, never during a measurement.
