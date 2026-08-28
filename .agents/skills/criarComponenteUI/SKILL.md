---
name: criar-componente-ui
description: Diretrizes do papel de implementação para construir componentes SwiftUI do Linka (e componentes do site institucional em aplicacao-web/) com fidelidade ao minimalismo Apple-only.
---

# Skill: criarComponenteUI

Procedimento do **Tiago** para construir componentes de UI.

Pressupõe o plano do Giammattey ([`.agents/WORKFLOW.md`](../../WORKFLOW.md) Passo 0) já escrito, **incluindo especificação de UX e UI**. Sem isso, não comece — devolva para o Giammattey.

Tiago constrói o que foi desenhado. Se durante a implementação aparecer decisão visual que a spec não cobre, isso volta para o Giammattey. Não se resolve no componente tentando inventar padrão.

## 0. Não é um dashboard, é uma medição

A interface do Linka é **deliberadamente mínima**. Antes de criar componente novo, pergunte: isso ajuda a mostrar a velocidade ou é firula que incha a tela?

Três coisas que não se quebram (ver [`AGENTS.md`](../../../AGENTS.md) §6):

1. O resultado é o protagonista — tamanho, tipografia, destaque.
2. Nenhuma ação exige navegação profunda durante o teste.
3. A interface transmite calma e precisão, nunca urgência.

## 1. Direção visual (Apple HIG-native)

O Design System atual é [`documentacao/design/design_system/readme.md`](../../../documentacao/design/design_system/readme.md). Direção resumida:

- fonte `ui-rounded` (San Francisco Rounded no Apple, fallback nativo em outros OS);
- cor: navy ink primary + um único warm-orange accent;
- radii contínuos (10/14/20/28);
- borders hairline `0.5px`;
- shadows: **nenhuma** (superfícies tonais + hairline em vez de elevação);
- motion: `--ease-spring` (curva UIKit) para press/reveal, `--ease-standard` para fades;
- alvo de toque `44px` mínimo em botões raised (`tinted`/`filled`);
- suporte completo a light + dark theme, contraste WCAG AA verificado.

**Não use:** glassmorphism gratuito, gradientes decorativos, sombras pesadas, velocímetro de carro, cards com sombra, MD3.

## 2. Escolha o arquivo certo

- **App iOS/iPad/Mac** (SwiftUI): componentes vivem em `aplicativo-ios/LinkaApp/Sources/UI/`. Contrato: `View` é apresentação, não conhece `URLSession` nem cálculo de bytes. O motor entrega dado pronto via `LinkaEngine` ou `Network*` packages; a `View` desenha.
- **Site institucional** (`aplicacao-web/`): componentes React vivem em `aplicacao-web/src/components/landing/` (mockups, cards) ou `aplicacao-web/src/ui/components/` (Wordmark e utilitários). A landing NÃO mede — se você está tentando importar uma função de medição no site, algo está errado.

## 3. Design tokens

Antes de inventar valor ou colar `px`/`pt` fixo:

- procure o token equivalente no design system;
- se não existir, o desenho está fugindo do sistema — volta pro Giammattey para decidir se cria token ou reformula;
- não crie segunda paleta para uma "tela de detalhes".

Tokens do site vivem em `aplicacao-web/src/styles/tokens/{colors,typography,spacing,motion}.css`. Tokens iOS ficam em Swift no `LinkaApp/Sources/Design/` (nomes semânticos correspondentes).

## 4. Hierarquia

Componente respeita a hierarquia definida no UX:

- O NÚMERO (medição em curso ou resultado) domina.
- Progresso é secundário e não pisca.
- Detalhes técnicos (latência, jitter, servidor, operadora) ficam atrás de "Detalhes" — divulgação progressiva ([`AGENTS.md`](../../../AGENTS.md) §6).

## 5. Motion

Movimento no Linka transmite **precisão**, não espetáculo.

- Ring de progresso é linear (matches `UIProgressView` nativo).
- Trocas de fase (`Preparando → Download → Upload → Finalizando`) não piscam.
- Botão press usa `scale(--press-scale)` com curva spring.
- **`prefers-reduced-motion` respeitado sempre** — informação continua completa, movimento cortado.

## 6. Acessibilidade

- Métrica em curso e resultado precisam de `aria-live`/`AccessibilityValue` para leitor de tela.
- Foco visível (`:focus-visible` no web; `.focused()` no SwiftUI).
- Contraste WCAG AA nos dois temas — os pares críticos estão medidos no design system.
- Cores nunca são único canal de informação.

## 7. Copy

Se um componente precisar de mais que um rótulo curto, revise a copy com [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md). Se estiver explicando conceito técnico ("bufferbloat", "jitter"), a explicação vai em "Como medimos" ou em detalhes — não no meio da tela de medição.

Você é filtro anti-tecnês: se a UI precisar de 3 parágrafos para explicar algo, chama o Giammattey e simplifica.

## 8. Antes de considerar pronto

- [ ] Renderiza igual em light e dark theme;
- [ ] Roda em iPhone real (não só simulador) — ver [`garantirIphoneReal`](../garantirIphoneReal/SKILL.md);
- [ ] Nenhum valor de token novo criado sem alinhamento;
- [ ] Não há cálculo de medição dentro da `View`;
- [ ] `prefers-reduced-motion` testado;
- [ ] VoiceOver lê o resultado.

## Relacionados

- **Design System:** [`documentacao/design/design_system/readme.md`](../../../documentacao/design/design_system/readme.md)
- **Fluxo de UX:** [`desenharExperiencia`](../desenharExperiencia/SKILL.md)
- **Especificação visual:** [`desenharInterface`](../desenharInterface/SKILL.md)
- **iPhone real:** [`garantirIphoneReal`](../garantirIphoneReal/SKILL.md)
