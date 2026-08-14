# Linka Design System

## Company / product context
Linka SpeedTest is a minimalist internet speed test app (Portuguese/pt-BR), inspired by Fast.com: the test starts automatically on load — no click needed — and a single giant number drives the whole experience through ping (invisible), download, and upload phases, ending on a result screen with download+upload side by side, an optional details disclosure (carrier, provider, duration, ping), a retest action, and a reserved ad slot ("Publicidade"). The product ships **exclusively for the Apple ecosystem** (iPhone, iPad, Mac) — there is no Web version and no Android version. The Web presence is an **institutional/marketing site** that shares the same visual tokens and components documented here; it presents the product and links to the App Store, and does not run the speed-test engine. See `AGENTS.md` at the repo root for the full governance.

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

## Visual foundations — Apple HIG native, cross-platform (current direction)
The brand direction (navy ink + one warm-orange accent) is unchanged, but the system's *conventions* — type, motion, radii, controls — have been rebuilt on Apple's Human Interface Guidelines so the product feels genuinely native on iPhone, iPad and Mac, while the exact same tokens/components render correctly on desktop web and any other OS.
- **Color:** navy "ink" primary (`oklch(26% 0.07 262)`), every neutral derived from it via `color-mix`, plus the one warm-orange accent (`oklch(72% 0.16 50)`) reserved for the wordmark's "i"-dot and tiny status dots. Added HIG-style semantic layer: `--color-bg-grouped` (grouped-list background), `--color-separator` (hairline), `--color-fill` (control track tint) — same naming spirit as `systemGroupedBackground`/`separator`/`systemFill`, values kept in-brand.
- **Type — native system font, not a webfont:** `--font-display` is `ui-rounded` (resolves to **San Francisco Rounded** on iPhone/iPad/Mac; Segoe UI/Roboto elsewhere), `--font-body` is `-apple-system`/`SF Pro Text` (falls to each OS's own UI font), `--font-mono` is `ui-monospace` (**SF Mono** on Apple, Cascadia/Consolas on Windows, Roboto Mono on Android/Linux). Zero CDN font, zero file upload needed — this is the actual mechanism for "same design regardless of iOS/Windows/Android": each OS substitutes its own native system face for the same generic keyword, so the type always looks correct and installed, never boxy fallback serif/sans. Added the full HIG text-style ladder as tokens: `--text-large-title`(34) → `--text-caption2`(11).
- **Motion — spring, not ease-out:** `--ease-spring: cubic-bezier(0.32,0.72,0,1)` (Apple's UIKit/sheet spring curve) drives button press (`scale(var(--press-scale))`, 0.96) and the details-disclosure chevron/reveal; `--ease-standard` handles plain fades/color. Progress fill on the metric ring stays linear (matches native `UIProgressView`).
- **Corner radii — continuous-corner scale:** `--radius-sm`10 / `--radius`14 / `--radius-lg`20 / `--radius-xl`28, approximating Apple's squircle continuous curvature (true squircle clip-path not applied — CSS `border-radius` is the practical cross-browser approximation).
- **Borders:** hairline `0.5px` on solid cards/separators (matches native 1px-at-2x hairlines), `1px` dashed kept for the reserved ad slot.
- **Shadows:** still none — flat, hairline-separated surfaces (also matches iOS/macOS's flat, tonal-elevation-over-shadow direction).
- **Controls:** `Button` now exposes Apple's real button styles — `plain`, `subtle`, `tinted` (soft accent fill), `filled` (solid accent, primary action) — instead of only borderless text actions, since native surfaces need a prominent action.
- **Touch targets:** `--touch-target: 44px`, Apple's minimum hit area, applied to raised (`tinted`/`filled`) buttons.
- **Backgrounds:** flat, no gradients/imagery/illustration.
- **Dois modos, claro e escuro:** `tokens/colors.css` declara os dois temas. No escuro a página é `#000000` puro (OLED) e o card sobe para uma superfície tonal quase-preta; a tinta inverte para quase-branco e o laranja clareia para `#FF9552`. **Só as primitivas mudam** — os nomes semânticos (`--surface-page`, `--surface-card`, `--text-primary`, `--text-secondary`, `--border-default`, `--brand-accent`) são iguais nos dois temas, então nenhum componente sabe que o tema existe. Ativação: sem atributo segue `prefers-color-scheme`; `data-theme="dark"` / `data-theme="light"` forçam — as três opções que a tela de Ajustes do app já oferece. `color-scheme` acompanha (scrollbars e controles nativos). Aplique o atributo em `<html>` ou em qualquer contêiner: cada escopo remapeia a camada semântica inteira, então um bloco de tema invertido dentro de uma página funciona.
- **Contraste (WCAG 2.2 AA) verificado nos dois temas:** texto principal, secundário e sobre acento ≥ 4.5:1; laranja gráfico e borda de controle ≥ 3:1. Três correções vieram daí: `--text-secondary` no claro passou a `#5F6C88` (a mistura anterior dava ~4.0:1, reprovada), o laranja de marca escureceu para `#E0701F` (3.1:1, passa como elemento gráfico) e ganhou o par `--brand-accent-warm-ink` `#A34A00` para quando o laranja é **texto**. Também entraram `--border-strong` (limite de controle a 3:1, já que a hairline padrão é decorativa), `--text-on-accent`, um `:focus-visible` global de 2px com offset — foco nunca só por cor — e suporte a `prefers-contrast: more`, que promove hairlines a bordas legíveis e o secundário a tinta cheia. O card **Guidelines → Modo claro e escuro** mede todos esses pares ao vivo e mostra a razão de contraste real de cada um.
- **Layout:** single centered column (`max-width: 1120px`) on web/desktop; the same component tree drops into `IOSDevice`/`MacWindow`/`ChromeWindow` frames unchanged — see the **Platforms** card.
- **Transparency/blur:** none yet — Apple's Liquid Glass materials are a natural next step for sheets/nav bars if the product grows overlays; flagging rather than inventing it unasked.

## Iconography
Only two inline SVG line icons exist in the source: a chevron (details-toggle) and a circular-arrow retry icon, both `stroke="currentColor"`, `stroke-width="2"`, no fill — a thin outlined-icon style, no icon font, no icon library reference, no emoji, no unicode-as-icon. These two are recreated as inline SVGs inside `Button` usage (not a general icon set — there is no larger icon system to draw from). If more icons are needed later, match this exact stroke style (2px, round caps, 24×24 viewBox) or substitute from a stroke-style CDN set like Lucide/Feather and flag it.

## Fonts — now 100% native, no upload needed
- **Display (`--font-display`):** `ui-rounded` → **SF Pro Rounded** on Apple devices, nearest rounded system face elsewhere. Quicksand (CDN webfont) has been dropped entirely in favor of this native stack.
- **Body (`--font-body`):** `-apple-system` / **SF Pro Text**, falls to each OS's UI font.
- **Mono (`--font-mono`):** `ui-monospace` → **SF Mono** on Apple, native mono elsewhere. JetBrains Mono reference removed — no font file to chase anymore.
- The sidebar font-upload prompts you may still see for "SF Pro Rounded"/"SF Pro Text" are expected and harmless: these are Apple's own system fonts, already installed on every Apple device — nothing to upload for native/Apple use. If you want pixel-identical SF Pro rendering in the *browser preview* on non-Apple machines too, you can upload the `.ttf`/`.woff2` and we'll add local `@font-face` rules, but it's optional.

## Intentional additions
- **Wordmark** — "linka" in the native rounded system font, navy ink, warm-orange dot standing in for the "i" tittle — the one deliberate color accent. `assets/logo.svg` (favicon) is a matching navy circle carrying the same orange dot, abstracted for small sizes.
- **Button** — extended beyond the original two borderless text actions to the full Apple HIG set: `plain`/`subtle` (borderless text, original behavior, unchanged in existing usage) plus `tinted`/`filled` (soft-fill and solid-fill, 44px touch target) — added because native iOS/iPad/Mac surfaces expect at least one prominent action; nothing in the existing SpeedTest flow was changed to use them, they're available for what's built next.
- **Card** — bordered-surface pattern generalized into one component with `dashed`/`label` variants; solid cards now use a hairline (0.5px) border to match native list separators.
- **MetricRing, PhaseDots, StatDisplay, DetailsDisclosure** — direct extractions of the four distinct UI pieces the speed-test flow actually uses; motion updated to the spring easing token, radii to the continuous-corner scale.

No form inputs, no navigation, no modal/toast — none exist in the source, so none were invented.

## Platform matrix
One component tree, four native frames — see the **Platforms** card (`guidelines/platforms.card.html`):
- **iPhone** — `IOSDevice` frame (`guidelines/frames/ios-frame.jsx`)
- **iPad** — same `IOSDevice` frame at iPad proportions (no separate bezel asset; same bezel, wider canvas)
- **MacBook** — `MacWindow` frame (`guidelines/frames/macos-window.jsx`), traffic-light chrome
- **Desktop web / any OS** — `ChromeWindow` frame (`guidelines/frames/browser-window.jsx`) — same tokens/components, no Apple-only styling leaks in since every native touch (font, radius, motion) degrades gracefully via CSS generic keywords (`ui-rounded`, `ui-monospace`) rather than hard-coded Apple values.

## Index
- `styles.css` — root stylesheet, imports everything under `tokens/`
- `tokens/colors.css`, `tokens/typography.css`, `tokens/spacing.css` — design tokens
- `assets/logo.svg` — favicon glyph (not a standalone logo — see Brand cards)
- `guidelines/` — foundation specimen cards (Colors, Type, Spacing, Brand)
- `components/brand/Wordmark`
- `components/core/Button`, `components/core/Card`, `Eyebrow`, `Icon`, `TextLink`, `StatusLabel`
- `components/layout/SiteHeader`, `SiteFooter`, `PageHero`
- `components/content/ValueCard`, `StepItem`, `ComparisonTable`, `LegalSection`
- `components/speedtest/MetricRing`, `PhaseDots`, `StatDisplay`, `DetailsDisclosure`, `AdSlot`

## Extraído do protótipo (2026-08-11)
Levantamento sobre os arquivos do protótipo Linka SpeedTest (web + iOS + iPad) atrás de padrões
repetidos à mão que o sistema ainda não cobria. Ver o card **Guidelines → Extraído do protótipo**.

**Componentizado agora:** `Eyebrow` (15+ cópias inline), `Icon` (chevron/retry redeclarados por tela),
`TextLink`, `StatusLabel`, `SiteHeader` e `SiteFooter` (idênticos nas 5 páginas), `PageHero` (4 páginas),
`ValueCard` (6 cópias), `StepItem`, `ComparisonTable`, `LegalSection`, `AdSlot`.

**Lacunas ainda abertas (precisam de decisão antes de implementar):** superfícies iOS (lista de ajustes, list row, nav bar,
bottom sheet, switch, segmented control) que hoje vêm do frame de protótipo; tokens/utilitário de
animação de entrada (`linkaRise`/`linkaFadeIn` com stagger 0/150/280/410/540ms); prop `size` em
`StatDisplay` (hoje sobrescrita por CSS `!important` no mobile) e o divisor vertical entre métricas;
regra escrita para as ilustrações de linha (traço 2px, rótulos mono, pulso animado).
- `SKILL.md` — Claude Code-compatible skill wrapper for this design system
