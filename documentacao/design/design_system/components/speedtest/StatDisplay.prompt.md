A labeled result number — used in pairs (Download / Upload) on the result screen. Bold tabular-nums figure with a small muted unit suffix; the label can be tinted accent-blue to lead the eye to the primary metric.

```jsx
<div style={{display:'flex', gap:56}}>
  <StatDisplay label="Download" value="184,3" unit="Mbps" accent />
  <StatDisplay label="Upload" value="41,2" unit="Mbps" />
</div>
```
