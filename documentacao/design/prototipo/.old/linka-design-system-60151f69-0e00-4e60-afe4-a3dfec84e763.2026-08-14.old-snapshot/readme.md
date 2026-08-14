# Linka Design System

## Company / product context
Linka SpeedTest is a minimalist internet speed test web app (Portuguese/pt-BR), inspired by Fast.com: the test starts automatically on load — no click needed — and a single giant number drives the whole experience through ping (invisible), download, and upload phases, ending on a result screen with download+upload side by side, an optional details disclosure (carrier, provider, duration, ping), a retest action, and a reserved ad slot ("Publicidade"). There is one product/surface: the SpeedTest web app itself.

**Sources provided:** a local codebase mount (`db5b91e7-6948-40c9-bc38-df08147ed21d/`) containing:
- `index.html` — a documentation/overview page describing the prototype and its flow
- `linka-speedtest.html` — the actual interactive speed-test prototype (full CSS + vanilla JS)
- `logo.svg` — a small favicon-sized "l" glyph

No Figma file, no other codebase, no slide decks were attached. This design system was built by reading those two HTML files directly (styles, markup, and the test-flow JS), not from screenshots.

## Content fundamentals
- **Language:** Brazilian Portuguese (pt-BR) throughout, including locale-formatted decimals (comma, e.g. "184,3").
- **Tone:** quiet, technical-minimal, zero marketing fluff. Copy states what is happening, nothing more — "Medindo velocidade de download…", "Sua conexão está pronta." No exclamation points, no hype adjectives.
- **Address:** impersonal/descriptive rather than "you"-directed — the UI narrates its own state ("Conectando ao servidor mais próximo…") rather than instructing the user.
- **Casing:** sentence case everywhere; short mono-caps eyebrows/labels are the only uppercase text ("LINKA SPEEDTEST", "DOWNLOAD", "PUBLICIDADE").
- **Numbers:** always pt-BR formatted with one decimal place, unit suffix in the same mono type ("41,2 Mbps", "18 ms", "7,4s").
- **No emoji, no icons-as-decoration** — the only inline glyphs are two functional line icons (chevron, retry arrow).
- **Brand name:** always lowercase "linka" in the wordmark; "Linka SpeedTest" / "Linka Network Labs" in running copy.

## Visual foundations (redesigned direction)
The original prototype's blue accent has been replaced with an original brand direction, built from scratch and only *inspired* by reference logos the user shared (never copied — no layout, color-pair, or letterform was reproduced 1:1).
- **Color:** a navy "ink" primary (`oklch(26% 0.07 262)`), with every neutral (text, muted, border, ink-deep) a lightness step of that same hue via `color-mix`, plus one restrained warm-orange accent (`oklch(72% 0.16 50)`) used ONLY for the wordmark's "i"-dot and equivalent tiny highlight/status dots — never as a fill, background, or button color. This navy + single orange pop, used sparingly, is the loose inspiration taken from the references; the exact circular-badge layout and color pairing were not copied.
- **Type:** Quicksand (rounded geometric, friendly) for the wordmark/display; system SF Pro Text stack for body copy (kept, not overused, not Inter/Roboto/Arial); SF Mono/ui-monospace for every number and uppercase label — this mono-for-numbers rule carries over from the original product and still contrasts nicely against the rounder display face.
- **Backgrounds:** flat, no gradients, no imagery, no illustration, no patterns/textures. Pure flat color + hairline borders.
- **Animation:** ease-out cubic on the metric ring/number count-up (~2–2.6s); CSS transitions (`ease`, 0.15–0.3s) for hover/disclosure/chevron-rotate. No bounce, no spring, no parallax.
- **Hover states:** text/icon color shifts to the accent blue; no background fill change, no shadow.
- **Press states:** none defined in source (no `:active` rules) — treat as same as hover.
- **Borders:** 1px hairline, `--color-border`, solid on content cards, dashed on the reserved ad slot.
- **Shadows:** none — flat design, borders do all the separation work.
- **Corner radii:** 10px (default/dashed cards), 16px (content cards, logo showcase, iframe frame).
- **Cards:** border + radius + white surface, no shadow, no colored left-border accent.
- **Layout:** single centered column (`max-width: 1120px`), generous vertical whitespace, sticky/fixed top nav bar only in the documentation shell (not in the app itself).
- **Transparency/blur:** none — only `color-mix()` used to derive `--color-accent-soft` and `--color-fg-soft`, not for glass/blur effects.
- **Imagery:** none provided — no photography, no illustration in the source.

## Iconography
Only two inline SVG line icons exist in the source: a chevron (details-toggle) and a circular-arrow retry icon, both `stroke="currentColor"`, `stroke-width="2"`, no fill — a thin outlined-icon style, no icon font, no icon library reference, no emoji, no unicode-as-icon. These two are recreated as inline SVGs inside `Button` usage (not a general icon set — there is no larger icon system to draw from). If more icons are needed later, match this exact stroke style (2px, round caps, 24×24 viewBox) or substitute from a stroke-style CDN set like Lucide/Feather and flag it.

## Fonts — flag for the user
- **Display (`--font-display`):** now **Quicksand**, loaded from Google Fonts via `tokens/fonts.css` (`@import url(...)`) — chosen for the "geométrica arredondada" direction. This is a CDN webfont, not a bundled file; if you'd like it self-hosted, upload the `.woff2` and we'll swap in a local `@font-face`.
- **Body (`--font-body`):** unchanged system stack (`SF Pro Text` / `system-ui`) — kept for readability, no file needed.
- **Mono (`--font-mono`):** unchanged (`SF Mono` / `JetBrains Mono` / `ui-monospace`) — still no bundled file; falls back to the OS monospace until a `JetBrains Mono` file is uploaded.

## Intentional additions
No component inventory (Figma/codebase library) was provided beyond the single prototype screen, so the standard-set rule applies, sized down to what this brand actually needs:
- **Wordmark** — redesigned per the user's direction: "linka" in Quicksand, navy ink, with a warm-orange dot standing in for the "i" tittle — the one deliberate color accent. `assets/logo.svg` (favicon) is a matching navy circle carrying the same orange dot, abstracted (no letterform) for small sizes. Inspired loosely by a reference logo's navy + orange-dot pairing, but the composition (dot-on-i vs. wordmark-inside-a-badge), exact hues, and layout are original — not a copy.
- **Button** — the two borderless text actions (retest, details-toggle) generalized into one component with `ghost`/`subtle` variants.
- **Card** — the bordered-surface pattern (content cards + dashed ad-slot) generalized into one component with a `dashed`/`label` variant, rather than a separate AdSlot.
- **MetricRing, PhaseDots, StatDisplay, DetailsDisclosure** — direct extractions of the four distinct UI pieces the speed-test flow actually uses.

No primary/filled button, no form inputs, no navigation, no modal/toast — none exist in the source, so none were invented.

## Index
- `styles.css` — root stylesheet, imports everything under `tokens/`
- `tokens/colors.css`, `tokens/typography.css`, `tokens/spacing.css` — design tokens
- `assets/logo.svg` — favicon glyph (not a standalone logo — see Brand cards)
- `guidelines/` — foundation specimen cards (Colors, Type, Spacing, Brand)
- `components/brand/Wordmark`
- `components/core/Button`, `components/core/Card`
- `components/speedtest/MetricRing`, `PhaseDots`, `StatDisplay`, `DetailsDisclosure`
- `ui_kits/speedtest-app/` — full click-through recreation of the Linka SpeedTest app
- `SKILL.md` — Claude Code-compatible skill wrapper for this design system
