# Icon

The system's whole icon set: 2px stroke, round caps, 24×24 viewBox, `currentColor`, no fill.
In the prototype these SVGs were re-declared inline (via `React.createElement`) on every screen —
the chevron and the retry arrow appear on the web app, the iOS screen and the iPad screen.

```jsx
<Button variant="subtle" icon={null} onClick={toggle}>Ver detalhes <Icon name="chevron-down" size={13} rotate={open ? 180 : 0} /></Button>
<Button icon={<Icon name="retry" size={14} />}>Testar novamente</Button>
```

Names: chevron-down / chevron-right / chevron-left / retry / arrow-right / close / menu.
Need another icon? Draw it in the same stroke style and add it to `PATHS` — do not import an icon font.
