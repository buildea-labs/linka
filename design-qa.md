# Linka website — design QA

## Comparison target

- Source visual truth: /Users/giammattey/.codex/generated_images/01a0887b-4d61-7e70-b753-7a5e67c052f4/exec-0aad3717-4688-4c14-9cb7-ab82e3c6276c.png
- Implementation capture: /tmp/linka-site-audit.pqsnuw/04-option3-preview.png
- Implementation URL: http://127.0.0.1:4173/
- Viewport/state: desktop Safari, home route, dark theme, top of page.
- Source dimensions: 850 × 1850 px.
- Implementation dimensions: 3420 × 2224 px; browser capture at desktop scale.
- Density normalization: compared by content region and hierarchy rather than browser chrome. The source is a tall marketing composition; the implementation was checked above the fold at the same dark, desktop landing-page state.

## Full-view comparison

The implementation preserves the selected direction's core hierarchy: restrained dark surface, compact brand header, editorial iPhone-first promise, real product image, then the three-step explanation and a calm Plus section. It intentionally replaces the mock's fabricated dark phone screens with real Linka App Store captures.

## Focused comparison

The hero was checked separately for heading scale, CTA prominence, screenshot crop and dark/light contrast. The implementation uses the real measurement screenshot at a readable scale and preserves the selected option's large left-aligned message with generous whitespace.

## Required fidelity surfaces

- **Fonts and typography:** system display/body/mono tokens retain the rounded Apple-native hierarchy. The hero has the intended large, compact display scale; eyebrow and support text remain readable.
- **Spacing and layout rhythm:** the desktop two-column hero has a deliberate central gap; section dividers and the three-step grid establish the source's calm vertical cadence. The mobile breakpoint collapses the layout without hiding content.
- **Colors and visual tokens:** the existing OLED-black, off-white and warm-orange Linka tokens are used consistently. The real light screenshot is a deliberate contrast point rather than an invented graphic.
- **Image quality and asset fidelity:** all visible product imagery comes from the existing final App Store screenshots. No device bezel, illustration, logo or product screen was fabricated in CSS or SVG.
- **Copy and content:** the page is iPhone-only, makes the free test clear, presents Linka Plus as R$ 34,90 por ano, and states automatic renewal and Apple billing plainly.

## Interaction checks

- Home route rendered in Safari with its expected title, hierarchy, images and legal links.
- /termos rendered in Safari with the subscription terms, Apple EULA link and footer navigation.
- Primary App Store buttons are intentionally informational until VITE_LINKA_APP_STORE_URL is configured. They do not pretend a public App Store listing exists before approval.

## Findings

No actionable P0, P1 or P2 mismatch remains for the selected direction.

### Accepted intentional deviations

- The selected mock shows dark product screens; the implementation uses the real, light App Store imagery to avoid presenting a fake app interface.
- The selected mock has a live App Store CTA. The implementation truthfully labels the action as available after approval until the public listing URL is supplied.

## Follow-up polish

- P3: once Apple exposes the public product URL, set VITE_LINKA_APP_STORE_URL in the hosting environment so both App Store actions become live links.

## Final result

passed
