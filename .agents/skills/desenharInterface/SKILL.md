---
name: desenharInterface
description: Procedimento do Giam para especificar a UI do Linka a partir do protótipo canônico e do Design System, antes do Guinho implementar.
---

# Skill: desenharInterface

Procedimento do **Giam** para transformar a experiência desenhada em **especificação visual** — a coisa que o Guinho recebe e constrói.

Giam desenha. Guinho implementa. Quem constrói o componente usa a [`criarComponenteUI`](../criarComponenteUI/SKILL.md).

> ## AS DUAS FONTES
>
> 1. **O protótipo** — [`documentacao/design/prototipo/`](../../../documentacao/design/prototipo/). Referência de fluxo, geometria e comportamento.
> 2. **O Design System** — [`documentacao/design/design_system/readme.md`](../../../documentacao/design/design_system/readme.md), com os tokens e componentes.
>
> **Divergiu? O protótipo vence** (per [`AGENTS.md`](../../../AGENTS.md) §3 e §7). O Design System existe para documentar o protótipo, não para competir com ele.
>
> Se a divergência for material e não puder ser conciliada, o Giam decide antes de implementar.

## 1. Token existente ou o desenho está errado

Cor, espaço, raio, duração e curva **já existem** no Design System. A lista está em `readme.md`, com valores concretos.

Se o desenho precisa de um valor que não existe, a resposta padrão **não** é criar token. É perguntar por que o desenho fugiu do sistema. Token novo é decisão consciente e vai escrita no plano, com motivo.

## 2. O que checar em toda especificação

Esta lista diz o que conferir. **Os valores ficam no `readme.md` do Design System** — copiar número para cá cria uma segunda fonte que envelhece.

| Conferir | Onde ler |
|---|---|
| Cor (semantic tokens: `--surface-page`, `--surface-card`, `--text-primary`, `--text-secondary`, `--border-default`, `--brand-accent`) | `readme.md` seção "Color" |
| Contraste WCAG AA nos dois temas | `readme.md` seção "Contraste" |
| Tipografia (`ui-rounded` display, `-apple-system` body, `ui-monospace`, `tabular-nums`) | `readme.md` seção "Type" |
| Escala tipográfica (`--text-large-title` → `--text-caption2`) | `readme.md` |
| Corner radii contínuos (`--radius-sm/-lg/-xl`) | `readme.md` |
| Borders hairline `0.5px` | `readme.md` |
| Sombras: **nenhuma** — usar hairline + tom | `readme.md` |
| Motion (`--ease-spring` para press/reveal, `--ease-standard` para fades) | `readme.md` seção "Motion" |
| Alvo de toque `--touch-target: 44px` em botões raised | `readme.md` |
| Botões: `plain`, `subtle`, `tinted`, `filled` | `readme.md` seção "Controls" |
| Componentes speedtest: MetricRing, PhaseDots, StatDisplay, DetailsDisclosure, AdSlot | `documentacao/design/design_system/components/speedtest/` |
| Componentes de conteúdo: ComparisonTable, LegalSection, StepItem, ValueCard | `documentacao/design/design_system/components/content/` |
| Layout: PageHero, SiteHeader, SiteFooter | `documentacao/design/design_system/components/layout/` |
| Brand: Wordmark | `documentacao/design/design_system/components/brand/` |
| Light + dark theme | `readme.md` seção "Dois modos" |
| `prefers-color-scheme` + `data-theme` attribute | `readme.md` |
| `prefers-reduced-motion` | `readme.md` |
| Acessibilidade | `readme.md` seção "Acessibilidade" |

## 3. Regras da máquina (recap)

- **O NÚMERO domina** — nunca é competido por elemento decorativo na tela de medição.
- **Ad slot é reservado, não integrado.** A publicidade nunca cobre resultado, atrasa teste ou parece controle do produto ([`AGENTS.md`](../../../AGENTS.md) §10).
- **Nada de card no fluxo de medição.** Card é padrão de dashboard, não de single-purpose measurement.
- **Componentes iOS/iPad/Mac** compartilham a mesma linguagem visual. O produto se adapta às frames (iPhone/iPad/Mac window) sem mudar identidade.

## 4. A saída

A especificação que o Guinho recebe:

```text
ESTADO: qual estado do fluxo, e qual região muda
FORMA:  componente usado (existente ou novo — se novo, justificar)
TOKENS: cor, espaço, raio, tipo, duração — pelos nomes semânticos
MEDIDA: alvo de toque, largura, altura, limites
MOVIMENTO: o que anima, quanto tempo, qual curva
REDUCED MOTION: o que vira
A11Y: foco, live region, rótulo, contraste
PROTÓTIPO: qual arquivo/estado mostra isso funcionando
NÃO FAZ: o que não pode aparecer
```

Se você não conseguiu apontar o protótipo, ou o desenho é novo de verdade (e aí vai escrito e justificado no plano) — ou você não procurou direito.

## Relacionados

- **Design System:** [`documentacao/design/design_system/readme.md`](../../../documentacao/design/design_system/readme.md)
- **Protótipo:** [`documentacao/design/prototipo/`](../../../documentacao/design/prototipo/)
- **O fluxo antes da forma:** [`desenharExperiencia`](../desenharExperiencia/SKILL.md)
- **Voz e copy:** [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md)
- **Quem constrói:** [`criarComponenteUI`](../criarComponenteUI/SKILL.md)
